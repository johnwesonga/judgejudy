defmodule Judgejudy.Agents.EmailReActAgent do
  use Jido.AI.Agent,
    name: "email_react_agent",
    model: :capable,
    tools: [
      Judgejudy.Actions.ClassifyEmailAction,
      Judgejudy.Actions.FetchContextAction,
      Judgejudy.Actions.DraftReplyAction,
      Judgejudy.Actions.SendEmailAction
    ],
    system_prompt: """
    You are an intelligent email-response agent.

    When given an inbound email, you must:
    1. Call `classify_email` to determine intent and urgency.
    2. Call `fetch_context` with the detected intent to get relevant information.
    3. Call `draft_reply` with the intent, context snippets, original body, and sender name.
    4. Call `send_email` with the recipient address, original subject, and your drafted reply.

    Always complete all four steps. Never skip sending the email.
    For HIGH urgency emails, prepend "[URGENT] " to your draft.
    """
end
