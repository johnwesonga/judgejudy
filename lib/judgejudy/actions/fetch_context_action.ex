defmodule Judgejudy.Actions.FetchContextAction do
  use Jido.Action,
    name: "fetch_context",
    description: "Fetch KB articles for a given intent and category, with confidence scoring.",
    schema: [
      intent: [type: :string, required: true],
      category: [type: :string, required: false],
      classification_confidence: [type: :float, required: false]
    ]

  @valid_intents ~w(billing support sales general)

  # Below this threshold, flag for human review
  @low_confidence_threshold 0.4

  import Judgejudy.Actions.ActionLogger
  require Logger

  @impl true
  def run(%{intent: intent_str} = params, _ctx) do
    log_run("FetchContextAction", params) do
      if intent_str not in @valid_intents do
        {:error, "Unknown intent: #{intent_str}"}
      else
        intent = String.to_existing_atom(intent_str)
        category = Map.get(params, :category)
        classification_confidence = Map.get(params, :classification_confidence, 1.0)

        case Judgejudy.KnowledgeBase.lookup(intent, limit: 3, category: category) do
          {:ok, articles} ->
            handle_results(articles, classification_confidence)

          {:error, :embedding_failed} ->
            # Embedding API is down — fall back to FTS-only keyword search
            Logger.warning("FetchContext: embedding failed, falling back to keyword search")
            keyword_fallback(intent, category, classification_confidence)

          {:error, :retrieval_failed} ->
            # DB is down — return degraded response, don't crash the agent
            Logger.error("FetchContext: retrieval failed, returning degraded response")

            {:ok,
             %{
               context_snippets: [
                 "KB temporarily unavailable. Respond helpfully from general knowledge."
               ],
               retrieval_confidence: 0.0,
               classification_confidence: classification_confidence,
               needs_escalation: true,
               degraded: true
             }}
        end
      end
    end
  end

  defp handle_results([], classification_confidence) do
    {:ok,
     %{
       context_snippets: ["No matching KB articles found. Use your best judgement."],
       retrieval_confidence: 0.0,
       classification_confidence: classification_confidence,
       needs_escalation: true
     }}
  end

  defp handle_results(articles, classification_confidence) do
    top_retrieval_confidence =
      articles |> Enum.map(& &1.retrieval_confidence) |> Enum.max()

    snippets =
      Enum.map(articles, fn a ->
        "[#{a.intent}/#{a.category}] #{a.title}: #{a.body}"
      end)

    needs_escalation =
      classification_confidence < @low_confidence_threshold or
        top_retrieval_confidence < @low_confidence_threshold

    {:ok,
     %{
       context_snippets: snippets,
       retrieval_confidence: Float.round(top_retrieval_confidence, 2),
       classification_confidence: Float.round(classification_confidence, 2),
       needs_escalation: needs_escalation
     }}
  end

  defp keyword_fallback(intent, _category, classification_confidence) do
    # Pure Postgres FTS, no pgvector
    import Ecto.Query

    articles =
      from(a in Judgejudy.KnowledgeBase.Article,
        where: a.intent == ^Atom.to_string(intent),
        order_by: [desc: a.inserted_at],
        limit: 3,
        select: %{title: a.title, body: a.body, intent: a.intent, category: a.category}
      )
      |> Judgejudy.Repo.all()

    snippets =
      Enum.map(articles, fn a ->
        "[#{a.intent}/#{a.category}] #{a.title}: #{a.body}"
      end)

    {:ok,
     %{
       context_snippets: snippets,
       # low but not zero — we have something
       retrieval_confidence: 0.4,
       classification_confidence: classification_confidence,
       needs_escalation: classification_confidence < @low_confidence_threshold
     }}
  end
end
