defmodule Judgejudy.Actions.RouteByConfidenceAction do
  use Jido.Action,
    name: "route_by_confidence",
    description: """
    Routes an email response based on confidence score.
    If confidence is below the threshold, escalates to a human agent.
    Otherwise sends the drafted reply.
    """,
    schema: [
      from: [type: :string, required: true],
      name: [type: :string, required: true],
      subject: [type: :string, required: true],
      body: [type: :string, required: true],
      draft: [type: :string, required: true],
      intent: [type: :string, required: true],
      category: [type: :string, required: true],
      confidence: [type: :float, required: true],
      classification_confidence: [type: :float, required: false],
      retrieval_confidence: [type: :float, required: false]
    ]

  require Logger
  import Judgejudy.Actions.ActionLogger

  @confidence_threshold Application.compile_env(:judgejudy, :confidence_threshold, 0.5)

  @impl true
  def run(params, ctx) do
    log_run("RouteByConfidenceAction", params) do
      Logger.info("""
      RouteByConfidence:
        from=#{params.from} subject=#{params.subject}
        confidence=#{params.confidence} threshold=#{@confidence_threshold}
      """)

      if params.confidence < @confidence_threshold do
        Logger.warning(
          "Confidence #{params.confidence} below #{@confidence_threshold} — escalating"
        )

        Judgejudy.Actions.EscalateToHumanAction.run(params, ctx)
      else
        Logger.info("Confidence #{params.confidence} above threshold — sending reply")
        send_reply(params)
      end
    end
  end

  defp send_reply(params) do
    email =
      Swoosh.Email.new()
      |> Swoosh.Email.to({params.name, params.from})
      |> Swoosh.Email.from({"Support", System.fetch_env!("SMTP_USERNAME")})
      |> Swoosh.Email.subject("Re: #{params.subject}")
      |> Swoosh.Email.text_body(params.draft)

    case Judgejudy.Mailer.deliver(email) do
      {:ok, _} ->
        {:ok, %{sent: true, escalated: false, confidence: params.confidence}}

      {:error, reason} ->
        {:error, "Send failed: #{inspect(reason)}"}
    end
  end
end
