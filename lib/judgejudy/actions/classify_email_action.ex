defmodule Judgejudy.Actions.ClassifyEmailAction do
  use Jido.Action,
    name: "classify_email",
    description: "Classify the intent and urgency of an inbound email.",
    schema:
      Zoi.object(%{
        subject: Zoi.string(),
        body: Zoi.string()
      })

  @categories %{
    "billing" => ~w(invoice payment refund subscription overage tax),
    "support" => ~w(authentication api bug performance data export integration),
    "sales" => ~w(trial pricing enterprise demo comparison),
    "general" => ~w(status browser compatibility feedback other)
  }
  require Logger
  @impl true
  def run(%{subject: subject, body: body}, _ctx) do
    text = String.downcase("#{subject} #{body}")

    intent = classify_intent(text)
    category = classify_category(text, intent)
    urgency = if text =~ ~r/urgent|asap|immediately|critical|down/, do: "high", else: "normal"

    {:ok, %{intent: intent, category: category, urgency: urgency}}
  end

  defp classify_intent(text) do
    cond do
      text =~ ~r/invoice|payment|charge|refund|billing|subscription/ -> "billing"
      text =~ ~r/support|help|bug|error|broken|issue|fail/ -> "support"
      text =~ ~r/demo|trial|pricing|plan|enterprise|purchase/ -> "sales"
      true -> "general"
    end
  end

  defp classify_category(text, intent) do
    keywords = Map.get(@categories, intent, [])

    # Find the first matching category keyword
    matched =
      Enum.find(keywords, fn keyword ->
        String.contains?(text, keyword)
      end)

    matched || "general"
  end
end
