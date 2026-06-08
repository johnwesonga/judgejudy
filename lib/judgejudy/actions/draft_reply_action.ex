defmodule Judgejudy.Actions.DraftReplyAction do
  use Jido.Action,
    name: "draft_reply",
    description: "Draft a reply email given intent, context snippets, and the original body.",
    schema:
      Zoi.object(%{
        intent: Zoi.string(),
        context_snippets: Zoi.list(Zoi.string()),
        original_body: Zoi.string(),
        sender_name: Zoi.string()
      })

  import Judgejudy.Actions.ActionLogger
  require Logger
  @impl true
  def run(params, _ctx) do
    log_run("DraftReplyAction", params) do
      # The ReAct agent's outer LLM will already compose the draft;
      # this action can format/validate it instead.
      prefix =
        if params.intent == "support" and
             String.contains?(params.original_body, "urgent"),
           do: "[URGENT] ",
           else: ""

      draft = """
      #{prefix}Hi #{params.sender_name},

      Thank you for reaching out about #{params.intent}.

      #{List.first(params.context_snippets, "We'll look into this shortly.")}

      Best regards,
      Support Team
      """

      Logger.info("[DraftReplyAction] draft: #{draft}")

      {:ok, %{draft: String.trim(draft)}}
    end
  end
end
