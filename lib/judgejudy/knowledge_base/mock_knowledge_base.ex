defmodule Judgejudy.KnowledgeBase.MockKnowledgeBase do
  @moduledoc """
  Fake in-memory knowledge base. Replace lookup/1 with a real
  Postgres full-text search, pgvector, or Typesense call later.
  """

  @articles [
    %{
      id: "billing-01",
      intent: :billing,
      title: "How to update your payment method",
      body:
        "To update your payment method, navigate to Settings → Billing → Payment Methods. Click 'Add new method' and enter your card details. Set the new card as default before removing the old one to avoid service interruption.",
      keywords: ~w(credit card payment portal update),
      confidence: 0.97
    },
    %{
      id: "billing-02",
      intent: :billing,
      title: "Understanding your invoice line items",
      body:
        "Your invoice has three sections: base subscription (fixed seat fee), usage overages (API/storage beyond plan), and tax (by billing address). Discounts apply before tax.",
      keywords: ~w(invoice charges overage tax line_items),
      confidence: 0.92
    },
    %{
      id: "billing-03",
      intent: :billing,
      title: "Requesting a refund",
      body:
        "Refunds are available within 14 days for annual plans and 7 days for monthly. Go to Settings → Billing → Transaction History and click 'Request refund'. Enterprise customers contact their account manager.",
      keywords: ~w(refund money_back charge),
      confidence: 0.88
    },
    %{
      id: "support-01",
      intent: :support,
      title: "Resetting your password",
      body:
        "Visit the login page and click 'Forgot password'. Enter your email; the reset link is valid 30 minutes. Locked accounts are unlocked via the same flow. SSO users reset through their identity provider.",
      keywords: ~w(password reset locked login),
      confidence: 0.99
    },
    %{
      id: "support-02",
      intent: :support,
      title: "API rate limits and 429 errors",
      body:
        "Limits: Free 60 req/min, Pro 300 req/min, Enterprise custom. On 429, read Retry-After and X-RateLimit-Remaining headers. Use exponential backoff with jitter — start 1s, double each retry, cap 60s.",
      keywords: ~w(rate_limit 429 backoff api too_many_requests),
      confidence: 0.95
    },
    %{
      id: "support-03",
      intent: :support,
      title: "Data export and GDPR requests",
      body:
        "Export at Settings → Privacy → Export Data (emailed within 24h). Right-to-erasure: email privacy@myapp.com with subject 'GDPR Erasure'. Processing takes up to 30 days and is irreversible.",
      keywords: ~w(gdpr ccpa privacy export erasure),
      confidence: 0.91
    },
    %{
      id: "sales-01",
      intent: :sales,
      title: "Starting a free trial",
      body:
        "New accounts get a 14-day Pro trial, no card required. All Pro features except custom SSO and advanced audit logs are enabled. One trial per email domain.",
      keywords: ~w(trial free demo pro sign_up),
      confidence: 0.96
    },
    %{
      id: "sales-02",
      intent: :sales,
      title: "Team vs Enterprise plan comparison",
      body:
        "Team: ≤50 seats, 99.9% SLA, email support, no SSO. Enterprise: unlimited seats, 99.99% SLA, dedicated CSM, SAML/OIDC SSO, custom data residency, MSA/DPA included.",
      keywords: ~w(enterprise team plan sso sla seats pricing),
      confidence: 0.93
    },
    %{
      id: "general-01",
      intent: :general,
      title: "Supported browsers and OS versions",
      body:
        "Chrome 110+, Firefox 112+, Edge 110+, Safari 16.4+. iOS app needs iOS 16+, Android app needs Android 12+. IE is not supported.",
      keywords: ~w(browser safari chrome mobile compatibility),
      confidence: 0.87
    },
    %{
      id: "general-02",
      intent: :general,
      title: "System status and incident history",
      body:
        "Live status at status.myapp.com. Subscribe to SMS/email alerts there. During incidents the on-call team posts updates every 30 minutes.",
      keywords: ~w(status outage incident downtime),
      confidence: 0.90
    }
  ]

  @doc """
  Returns KB articles for a given intent atom, sorted by confidence descending.
  Returns at most `limit` results (default 3).
  """
  @spec lookup(atom(), keyword()) :: [map()]
  def lookup(intent, opts \\ []) do
    limit = Keyword.get(opts, :limit, 3)

    @articles
    |> Enum.filter(&(&1.intent == intent))
    |> Enum.sort_by(& &1.confidence, :desc)
    |> Enum.take(limit)
    |> Enum.map(&Map.take(&1, [:id, :title, :body, :confidence]))
  end

  @doc """
  Full-text keyword search across all intents.
  Useful for the `general` fallback case.
  """
  @spec search(String.t(), keyword()) :: [map()]
  def search(query, opts \\ []) do
    limit = Keyword.get(opts, :limit, 3)
    q = String.downcase(query)

    @articles
    |> Enum.filter(fn a ->
      String.contains?(String.downcase(a.title), q) or
        String.contains?(String.downcase(a.body), q) or
        Enum.any?(a.keywords, &String.contains?(&1, q))
    end)
    |> Enum.sort_by(& &1.confidence, :desc)
    |> Enum.take(limit)
    |> Enum.map(&Map.take(&1, [:id, :title, :body, :confidence]))
  end
end
