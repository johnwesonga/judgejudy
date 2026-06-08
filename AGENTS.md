# Judgejudy Agents

Multi-agent architecture for intelligent email triage, auto-response, and task handling.

## Overview

Judgejudy uses a multi-agent system built on [Jido AI](https://github.com/jidosolutions/jido), providing specialized agents for different workflows:

| Agent | Type | Model | Purpose |
|-------|------|-------|---------|
| `EmailReActAgent` | ReAct | Claude Sonnet (capable) | Main email triage and response |
| `DraftAgent` | CoD | Claude Sonnet (capable) | Draft generation with chain-of-draft |
| `ThoughtAgent` | CoT | Claude Sonnet (capable) | Complex reasoning tasks |
| `CalcAgent` | Agent | Haiku (fast) | Calculator operations |
| `WeatherAgent` | ReAct | Qwen (local) | Weather queries |

## Agents

### EmailReActAgent

The primary agent for processing inbound emails. Uses ReAct (Reasoning + Acting) to interact with tools.

```elixir
defmodule Judgejudy.Agents.EmailReActAgent do
  use Jido.AI.Agent,
    name: "email_react_agent",
    model: :capable,
    tools: [
      Judgejudy.Actions.ClassifyEmailAction,
      Judgejudy.Actions.FetchContextAction,
      Judgejudy.Actions.DraftReplyAction,
      Judgejudy.Actions.SendEmailAction
    ]
end
```

**System Prompt:**
```
You are an intelligent email-response agent.

When given an inbound email, you must:
1. Call `classify_email` to determine intent, category, urgency and confidence.
2. Call `fetch_context` with the intent, category, AND classification_confidence.
3. Check the result:
   - If `needs_escalation` is true OR confidence is below 0.4, draft a reply that:
     a) Acknowledges the email warmly
     b) Says a specialist will follow up within 1 business day
     c) Does NOT attempt to answer the question directly
   - Otherwise draft a confident, specific reply using the context snippets.
4. Call `send_email` with the recipient address, original subject, and your drafted reply.

Always complete all four steps.
For HIGH urgency emails, prepend "[URGENT] " to your draft.
```

**Tool Calling Rules:**
1. Always call `classify_email` first with subject and body
2. Pass classification results to `fetch_context`
3. Escalate low-confidence cases (< 0.4) with hold-harmless ack
4. Use retrieved context for high-confidence responses
5. Send final reply via `send_email`

---

### DraftAgent

A Chain-of-Draft (CoD) reasoning agent for generating response drafts.

```elixir
defmodule Judgejudy.Agents.DraftAgent do
  use Jido.AI.CoDAgent,
    name: "draft_agent",
    description: "Chain of Draft Reasoning Agent",
    model: :capable,
    max_iterations: 5,
    system_prompt: """
    You are a highly analytical expert reasoning agent.
    Break down complex queries into minimal, extremely concise draft steps.
    - Each intermediate draft step must have at most 5 words when possible.
    - Keep only the essential information needed to progress.
    - Avoid verbose sentences during reasoning.
    Always provide the final answer after the separator ####.
    """
end
```

**CoD Workflow:**
- Generates intermediate drafts incrementally
- Each step constrained to max 5 words
- Final answer provided after `####` separator
- Used for complex response generation

**When to use:**
- Drafting email replies
- Structuring multi-part responses
- Building responses from context snippets

---

### ThoughtAgent

A Chain-of-Thought (CoT) reasoning agent for complex analytical tasks.

```elixir
defmodule Judgejudy.Agents.ThoughtAgent do
  use Jido.AI.CoTAgent,
    name: "thought_agent",
    description: "Chain of Thought Reasoning Agent",
    model: :capable,
    system_prompt: """
    You are an expert reasoning agent using Chain-of-Thought.
    Break down complex tasks into logical, step-by-step thinking processes.
    Detail each reasoning step thoroughly before progressing.
    Always end with the final answer after the separator ####.
    """
end
```

**CoT Workflow:**
- Performs step-by-step reasoning internally
- Details each reasoning step
- Final answer provided after `####` separator
- No tool calling by default

**When to use:**
- Complex data analysis
- Multi-step calculations
- Logical deduction tasks

---

### CalcAgent

A calculator agent using simple arithmetic operations.

```elixir
defmodule Judgejudy.Agents.CalcAgent do
  use Jido.AI.Agent,
    name: "calc_agent",
    description: "Calculator Agent",
    model: :fast,
    tools: [
      Judgejudy.Tools.Calc.Multiply,
      Judgejudy.Tools.Calc.Add,
      Judgejudy.Tools.Calc.Subtraction
    ]
end
```

**Tools:**
- `Multiply` - multiply two numbers
- `Add` - add two numbers
- `Subtraction` - subtract two numbers

**Model:** Haiku (fast) - optimized for simple, deterministic computations

**When to use:**
- Basic arithmetic operations
- Price calculations
- Quantity adjustments

---

### WeatherAgent

A weather queries agent using ReAct pattern.

```elixir
defmodule Judgejudy.Agents.WeatherAgent do
  use Jido.AI.Agent,
    name: "weather_react_agent",
    description: "Weather assistant using ReAct tool-calling",
    model: :local,
    max_iterations: 10,
    tools: [
      Judgejudy.Tools.Weather.ByLocation
    ]
end
```

**System Prompt:**
```
You are a weather planning assistant.

Use tools for weather facts and keep advice practical:
- Temperature and precipitation
- Timing (morning/afternoon/evening) when possible
- Clothing, transit, and backup plans

Tool workflow requirements:
1. If location is a place name (e.g. "Seattle, WA"), call weather_by_location first.
2. Then call weather_location_to_grid using the returned coordinates (lat,lng format only).
3. Then call forecast/current tools from the returned NWS URLs.
4. Never pass a city/state string directly into weather_location_to_grid.

If location/date is ambiguous, ask a concise clarification.
```

**Tool Workflow:**
1. Receive location request
2. If city name → call `weather_by_location`
3. Get coordinates from result
4. Convert coordinates to grid with `weather_location_to_grid`
5. Fetch forecast from NWS URL
6. Synthesize practical advice

**Model:** Local Qwen (Qwen2.5-72B-Instruct)

**When to use:**
- Weather forecasts by location
- Travel planning
- Outdoor activity planning

---

## Model Aliases

Defined in `config/config.exs`:

```elixir
config :judgejudy, :models,
  capable: Anthropic.Client, # Claude Sonnet 3.5
  fast:      Anthropic.Client, # Claude Haiku
  local:   ReqLLM, # Local Qwen 2.5
```

| Alias | Provider | Use Case |
|-------|----------|----------|
| `:capable` | Anthropic | Complex reasoning, email triage, drafting |
| `:fast` | Anthropic | Simple calculations, quick responses |
| `:local` | Local (Ollama) | Weather queries, privacy-sensitive tasks |

---

## Registration

Agents are registered in `lib/judgejudy/jido.ex`:

```elixir
defmodule Judgejudy.Jido do
  use Jido.Jido,
    max_tasks: 1000,
    agent_pools: []

  def registry do
    [
      EmailReActAgent,
      DraftAgent,
      ThoughtAgent,
      CalcAgent,
      WeatherAgent
    ]
  end
end
```

---

## Agent Selection Flow

```
Inbound Email
     │
     ▼
┌─────────────────────────────────────────┐
│ EmailReActAgent (primary entry point)   │
│ 1. classify_email                       │
│ 2. fetch_context                        │
│ 3. draft_reply (via DraftAgent/CoD)     │
│ 4. send_email                           │
└─────────────────────────────────────────┘
         │
         │ Low confidence?
         ▼
    ┌────────────────┐
    │ Escalate Human │
    └────────────────┘
```

**Dispatch Rules:**
- Email triage → `EmailReActAgent` (default)
- Complex analysis → `ThoughtAgent`
- Draft generation → `DraftAgent`
- Calculations → `CalcAgent`
- Weather queries → `WeatherAgent`

---

## Tool Actions

### Classification Actions

```elixir
Judgejudy.Actions.ClassifyEmailAction
  - Intent detection (billing/support/sales/general)
  - Category classification
  - Urgency assessment
  - Confidence scoring

Judgejudy.Actions.FetchContextAction
  - KB lookup with hybrid search
  - Confidence check (threshold: 0.4)
  - Returns context or escalate flag
```

### Response Actions

```elixir
Judgejudy.Actions.DraftReplyAction
  - Generates draft based on intent/category
  - Adds [URGENT] prefix for high-priority
  - Uses context snippets from KB

Judgejudy.Actions.SendEmailAction
  - Sends reply to original sender
  - Emits Jido.Signal for coordination
  - Handles delivery errors
```

---

## Escalation Thresholds

| Confidence | Action | Reason |
|------------|--------|--------|
| ≥ 0.4      | Auto-reply | Sufficient confidence in classification |
| < 0.4      | Escalate | Ambiguous intent/category |
| ≥ 0.5      | Auto-reply | High confidence (global threshold) |
| < 0.5      | Escalate | Low confidence (global threshold) |

---

## Notes

- Agents can be invoked directly via Jido's CLI or API
- Multiple agents can process the same signal concurrently
- Jido handles load balancing and error recovery automatically
- Local model (Qwen) avoids API costs and latency for simple tasks
- Anthropic models (capable/fast) for complex reasoning
