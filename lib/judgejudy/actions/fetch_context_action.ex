defmodule Judgejudy.Actions.FetchContextAction do
  use Jido.Action,
    name: "fetch_context",
    description: "Fetch relevant KB articles given an intent and category.",
    schema: [
      intent: [type: :string, required: true],
      category: [type: :string, required: false]
    ]

  @valid_intents ~w(billing support sales general)

  @impl true
  def run(%{intent: intent_str} = params, _ctx) do
    if intent_str not in @valid_intents do
      {:error, "Unknown intent: #{intent_str}"}
    else
      category = Map.get(params, :category)
      intent = String.to_existing_atom(intent_str)

      case Judgejudy.KnowledgeBase.lookup(intent, limit: 3, category: category) do
        {:ok, []} ->
          {:ok, %{context_snippets: ["No specific KB articles found. Use your best judgement."]}}

        {:ok, articles} ->
          snippets =
            Enum.map(articles, fn a ->
              "[#{a.intent}/#{a.category}] #{a.title}: #{a.body}"
            end)

          {:ok, %{context_snippets: snippets}}

        {:error, reason} ->
          {:error, "KB lookup failed: #{inspect(reason)}"}
      end
    end
  end
end
