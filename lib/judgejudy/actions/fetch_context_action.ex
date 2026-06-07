defmodule Judgejudy.Actions.FetchContextAction do
  use Jido.Action,
    name: "fetch_context",
    description: "Fetch relevant KB articles for a given intent.",
    schema: [
      intent: [type: :string, required: true]
    ]

  @valid_intents ~w(billing support sales general)

  @impl true
  def run(%{intent: intent_str}, _ctx) do
    if intent_str not in @valid_intents do
      {:error, "Unknown intent: #{intent_str}"}
    else
      intent = String.to_existing_atom(intent_str)

      case Judgejudy.KnowledgeBase.lookup(intent, limit: 3) do
        {:ok, []} ->
          {:ok,
           %{
             context_snippets: [
               "No specific KB articles found. Use your best judgement to respond helpfully."
             ]
           }}

        {:ok, articles} ->
          snippets = Enum.map(articles, & &1.body)
          {:ok, %{context_snippets: snippets}}

        {:error, reason} ->
          {:error, "KB lookup failed: #{inspect(reason)}"}
      end
    end
  end

  defp lookup(intent) do
    case intent do
      :general -> Judgejudy.KnowledgeBase.MockKnowledgeBase.search("general help", limit: 2)
      _ -> Judgejudy.KnowledgeBase.MockKnowledgeBase.lookup(intent, limit: 3)
    end
    |> Enum.map(& &1.body)
  end
end
