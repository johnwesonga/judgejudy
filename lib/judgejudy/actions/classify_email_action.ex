defmodule Judgejudy.Actions.ClassifyEmailAction do
  use Jido.Action,
    name: "classify_email",
    description: "Classify the intent and urgency of an inbound email.",
    schema:
      Zoi.object(%{
        subject: Zoi.string(),
        body: Zoi.string()
      })

  require Logger
  @impl true
  def run(%{subject: subject, body: body}, _ctx) do
    intent =
      cond do
        subject =~ ~r/invoice|payment/i -> :billing
        subject =~ ~r/support|help|bug/i -> :support
        subject =~ ~r/demo|trial/i -> :sales
        true -> :general
      end

    urgency = if body =~ ~r/urgent|asap|immediately/i, do: :high, else: :normal
    Logger.info("[ClassifyEmailAction] intent #{intent}")
    {:ok, %{intent: intent, urgency: urgency}}
  end
end
