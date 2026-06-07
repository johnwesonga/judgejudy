# lib/mix/tasks/judgejudy.seed_kb.ex
defmodule Mix.Tasks.Judgejudy.SeedKb do
  use Mix.Task
  alias Judgejudy.{Repo, KnowledgeBase.Article, KnowledgeBase.Embeddings}

  @articles [
    %{
      intent: "billing",
      title: "How to update your payment method",
      body: "Navigate to Settings → Billing → Payment Methods...",
      keywords: ~w(credit card payment portal)
    },
    %{
      intent: "billing",
      title: "Requesting a refund",
      body: "Refunds available within 14 days for annual plans...",
      keywords: ~w(refund charge annual)
    },
    %{
      intent: "support",
      title: "API rate limits and 429 errors",
      body: "Free: 60 req/min, Pro: 300 req/min. Use exponential backoff...",
      keywords: ~w(rate_limit 429 backoff api)
    }
    # ... rest of articles
  ]

  def run(_) do
    Mix.Task.run("app.start")

    texts = Enum.map(@articles, &"#{&1.title}. #{&1.body}")

    {:ok, embeddings} = Embeddings.embed_batch(texts)

    @articles
    |> Enum.zip(embeddings)
    |> Enum.each(fn {article, embedding} ->
      %Article{}
      |> Article.changeset(Map.put(article, :embedding, embedding))
      |> Repo.insert!(on_conflict: :nothing)

      IO.puts("Seeded: #{article.title}")
    end)
  end
end
