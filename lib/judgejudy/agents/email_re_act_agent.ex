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
    1. Call `classify_email` to determine intent, category, urgency and confidence.
    2. Call `fetch_context` with the intent, category, AND classification_confidence from step 1.
    3. Check the result:
       - If `needs_escalation` is true OR confidence is below 0.4, draft a reply that:
         a) Acknowledges the email warmly
         b) Says a specialist will follow up within 1 business day
         c) Does NOT attempt to answer the question directly
       - Otherwise draft a confident, specific reply using the context snippets.
    4. Call `send_email` with the recipient address, original subject, and your drafted reply.

    Always complete all four steps.
    For HIGH urgency emails, prepend "[URGENT] " to your draft.
    """
end
