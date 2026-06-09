defmodule Judgejudy.Actions.EscalateToHumanAction do
  use Jido.Action,
    name: "escalate_to_human",
    description: "Escalates a low-confidence email to a human agent via a notification email.",
    schema: [
      from: [type: :string, required: true],
      name: [type: :string, required: true],
      subject: [type: :string, required: true],
      body: [type: :string, required: true],
      intent: [type: :string, required: true],
      category: [type: :string, required: true],
      confidence: [type: :float, required: true],
      classification_confidence: [type: :float, required: false],
      retrieval_confidence: [type: :float, required: false]
    ]

  require Logger
  import Judgejudy.Actions.ActionLogger

  # Who gets the escalation notification
  #@escalation_email System.get_env("ESCALATION_EMAIL", "support-team@myapp.com")
  @escalation_email "projozangu+support-team@gmail.com"

  @impl true
  def run(params, _ctx) do
    log_run("EscalateToHumanAction", params) do
      Logger.warning("""
      Escalating email to human:
        from=#{params.from}
        subject=#{params.subject}
        intent=#{params.intent}/#{params.category}
        confidence=#{params.confidence}
      """)

      with {:ok, _} <- send_acknowledgement(params),
           {:ok, _} <- notify_human_agent(params) do
        {:ok,
         %{
           escalated: true,
           escalated_to: @escalation_email,
           reason: "confidence_below_threshold",
           confidence: params.confidence
         }}
      end
    end
  end

  # Reply to the sender acknowledging receipt without committing to an answer
  defp send_acknowledgement(params) do
    body = """
    Hi #{params.name},

    Thank you for reaching out. We've received your email and a member of
    our team will get back to you within 1 business day.

    We appreciate your patience.

    Best regards,
    Support Team
    """

    email =
      Swoosh.Email.new()
      |> Swoosh.Email.to({params.name, params.from})
      |> Swoosh.Email.from({"Support", System.fetch_env!("SMTP_USERNAME")})
      |> Swoosh.Email.subject("Re: #{params.subject}")
      |> Swoosh.Email.text_body(body)

    case Judgejudy.Mailer.deliver(email) do
      {:ok, _} -> {:ok, :acknowledged}
      {:error, reason} -> {:error, "Acknowledgement failed: #{inspect(reason)}"}
    end
  end

  # Notify the human agent with full context for triage
  defp notify_human_agent(params) do
    body = """
    ⚠️  Low-confidence email requires human review

    ─── Classification ───────────────────────────
    Intent:    #{params.intent} (#{params.classification_confidence || "n/a"})
    Category:  #{params.category}
    Retrieval: #{params.retrieval_confidence || "n/a"}
    Overall:   #{params.confidence}

    ─── Original Email ───────────────────────────
    From:      #{params.name} <#{params.from}>
    Subject:   #{params.subject}

    #{params.body}
    ──────────────────────────────────────────────

    Please reply directly to #{params.from} to resolve this.
    """

    email =
      Swoosh.Email.new()
      |> Swoosh.Email.to(@escalation_email)
      |> Swoosh.Email.from({"Judgejudy Agent", System.fetch_env!("SMTP_USERNAME")})
      |> Swoosh.Email.subject("[ESCALATION] #{params.subject} (confidence: #{params.confidence})")
      |> Swoosh.Email.text_body(body)

    case Judgejudy.Mailer.deliver(email) do
      {:ok, _} -> {:ok, :notified}
      {:error, reason} -> {:error, "Escalation notify failed: #{inspect(reason)}"}
    end
  end
end
