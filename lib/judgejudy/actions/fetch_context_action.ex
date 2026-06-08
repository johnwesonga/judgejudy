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

        case Judgejudy.KnowledgeBase.lookup(intent,
               limit: 3,
               category: category
             ) do
          {:ok, []} ->
            {:ok,
             %{
               context_snippets: ["No specific KB articles found. Use your best judgement."],
               retrieval_confidence: 0.0,
               needs_escalation: true
             }}

          {:ok, articles} ->
            top_retrieval_confidence =
              articles |> Enum.map(& &1.retrieval_confidence) |> Enum.max()

            snippets =
              Enum.map(articles, fn a ->
                "[#{a.intent}/#{a.category}] #{a.title}: #{a.body}"
              end)

            # Escalate if either classification or retrieval is low confidence
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

          {:error, reason} ->
            {:error, "KB lookup failed: #{inspect(reason)}"}
        end
      end
    end
  end
end
