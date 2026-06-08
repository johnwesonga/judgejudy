defmodule Judgejudy.Actions.ClassifyEmailAction do
  use Jido.Action,
    name: "classify_email",
    description: "Classify intent, category, urgency and confidence of an inbound email.",
    schema:
      Zoi.object(%{
        subject: Zoi.string(),
        body: Zoi.string()
      })

  @intent_patterns %{
    "billing" => ~w(invoice payment charge refund billing subscription overage receipt),
    "support" => ~w(support help bug error broken issue fail crash problem),
    "sales" => ~w(demo trial pricing plan enterprise purchase upgrade),
    "general" => ~w(status browser compatibility feedback question)
  }

  @category_patterns %{
    "billing" => %{
      "payment" => ~w(payment card credit debit bank),
      "invoice" => ~w(invoice receipt line item charge),
      "refund" => ~w(refund money back return reimburse),
      "subscription" => ~w(subscription renew cancel downgrade)
    },
    "support" => %{
      "authentication" => ~w(password login locked signin sso auth),
      "api" => ~w(api rate limit 429 endpoint request),
      "bug" => ~w(bug crash error exception broken fail),
      "data_export" => ~w(export gdpr data privacy erasure),
      "performance" => ~w(slow timeout latency performance)
    },
    "sales" => %{
      "trial" => ~w(trial free test evaluate),
      "pricing" => ~w(pricing cost price plan tier),
      "enterprise" => ~w(enterprise team seats sso contract),
      "demo" => ~w(demo walkthrough meeting call)
    },
    "general" => %{
      "compatibility" => ~w(browser chrome safari mobile os),
      "status" => ~w(status outage incident down),
      "feedback" => ~w(feedback suggestion improve feature),
      "other" => []
    }
  }

  @impl true
  def run(%{subject: subject, body: body}, _ctx) do
    text = String.downcase("#{subject} #{body}")
    words = String.split(text, ~r/\W+/, trim: true)

    {intent, intent_confidence} = classify_intent(words)
    {category, category_confidence} = classify_category(words, intent)

    urgency = classify_urgency(text)

    # Overall classification confidence — weighted average
    # Intent carries more weight than category
    overall_confidence =
      Float.round(intent_confidence * 0.6 + category_confidence * 0.4, 2)

    {:ok,
     %{
       intent: intent,
       category: category,
       urgency: urgency,
       intent_confidence: Float.round(intent_confidence, 2),
       category_confidence: Float.round(category_confidence, 2),
       confidence: overall_confidence
     }}
  end

  defp classify_intent(words) do
    scores =
      Enum.map(@intent_patterns, fn {intent, keywords} ->
        hits = Enum.count(keywords, &(&1 in words))
        score = hits / length(keywords)
        {intent, score}
      end)

    {best_intent, best_score} = Enum.max_by(scores, &elem(&1, 1))

    # Normalize: if no keywords matched at all, fall back to general
    if best_score == 0.0 do
      {"general", 0.3}
    else
      # Scale so a single keyword hit = 0.5, full match = 1.0
      confidence = min(1.0, 0.5 + best_score * 5)
      {best_intent, confidence}
    end
  end

  defp classify_category(words, intent) do
    patterns = get_in(@category_patterns, [intent]) || %{}

    scores =
      Enum.map(patterns, fn {category, keywords} ->
        hits = Enum.count(keywords, &(&1 in words))
        score = if length(keywords) > 0, do: hits / length(keywords), else: 0
        {category, score}
      end)

    case Enum.max_by(scores, &elem(&1, 1), fn -> nil end) do
      nil ->
        {"general", 0.3}

      {_category, +0.0} ->
        {"general", 0.3}

      {best_category, best_score} ->
        confidence = min(1.0, 0.5 + best_score * 5)
        {best_category, confidence}
    end
  end

  defp classify_urgency(text) do
    if text =~ ~r/urgent|asap|immediately|critical|down|emergency/, do: "high", else: "normal"
  end
end
