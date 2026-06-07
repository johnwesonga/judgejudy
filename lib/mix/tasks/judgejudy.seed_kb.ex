# lib/mix/tasks/judgejudy.seed_kb.ex
defmodule Mix.Tasks.Judgejudy.SeedKb do
  use Mix.Task
  alias Judgejudy.{Repo, KnowledgeBase.Article, KnowledgeBase.Embeddings}

  @articles [
    %{
      intent: "billing",
      category: "payment",
      title: "How to update your payment method",
      body: "Navigate to Settings → Billing → Payment Methods...",
      keywords: ~w(credit card payment portal update)
    },
    %{
      intent: "billing",
      category: "invoice",
      title: "Understanding your invoice line items",
      body: "Your invoice has three sections: base subscription, usage overages, and tax...",
      keywords: ~w(invoice charges overage tax line_items)
    },
    %{
      intent: "billing",
      category: "refund",
      title: "Requesting a refund",
      body: "Refunds available within 14 days for annual plans and 7 days for monthly...",
      keywords: ~w(refund money_back charge)
    },
    %{
      intent: "support",
      category: "authentication",
      title: "Resetting your password",
      body: "Visit the login page and click Forgot password. Reset link valid 30 minutes...",
      keywords: ~w(password reset locked login)
    },
    %{
      intent: "support",
      category: "api",
      title: "API rate limits and 429 errors",
      body: "Free: 60 req/min, Pro: 300 req/min. Use exponential backoff with jitter...",
      keywords: ~w(rate_limit 429 backoff api)
    },
    %{
      intent: "support",
      category: "data_export",
      title: "Data export and GDPR requests",
      body: "Export at Settings → Privacy → Export Data. Erasure requests take 30 days...",
      keywords: ~w(gdpr ccpa privacy export erasure)
    },
    %{
      intent: "sales",
      category: "trial",
      title: "Starting a free trial",
      body: "New accounts get a 14-day Pro trial, no card required...",
      keywords: ~w(trial free demo pro sign_up)
    },
    %{
      intent: "sales",
      category: "pricing",
      title: "Team vs Enterprise plan comparison",
      body: "Team: 50 seats, 99.9% SLA. Enterprise: unlimited seats, SSO, dedicated CSM...",
      keywords: ~w(enterprise team plan sso sla seats pricing)
    },
    %{
      intent: "general",
      category: "compatibility",
      title: "Supported browsers and OS versions",
      body: "Chrome 110+, Firefox 112+, Safari 16.4+. iOS 16+, Android 12+...",
      keywords: ~w(browser safari chrome mobile compatibility)
    },
    %{
      intent: "general",
      category: "status",
      title: "System status and incident history",
      body: "Live status at status.myapp.com. Updates every 30 minutes during incidents...",
      keywords: ~w(status outage incident downtime)
    }
  ]

  def run(_) do
    Mix.Task.run("app.start")

    # Embed title + category + body for richer semantic signal
    texts =
      Enum.map(@articles, fn a ->
        "#{a.title}. Category: #{a.category}. #{a.body}"
      end)

    {:ok, embeddings} = Embeddings.embed_batch(texts)

    # Clear existing articles first
    Repo.delete_all(Article)
    IO.puts("Cleared existing KB articles")

    @articles
    |> Enum.zip(embeddings)
    |> Enum.each(fn {article, embedding} ->
      %Article{}
      |> Article.changeset(Map.put(article, :embedding, embedding))
      |> Repo.insert!()

      IO.puts("Seeded: [#{article.intent}/#{article.category}] #{article.title}")
    end)

    IO.puts("\nDone — #{length(@articles)} articles seeded")
  end
end
