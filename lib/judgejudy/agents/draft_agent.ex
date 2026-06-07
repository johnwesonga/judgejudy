defmodule Judgejudy.Agents.DraftAgent do
  use Jido.AI.CoDAgent,
    name: "draft_agent",
    description: "Chain of Draft Reasoning Agent",
    # Using the capable model (Claude 3.5 Sonnet) for reasoning
    model: :capable,
    # CoD system prompts encourage ultra-short draft steps (max 5 words)
    system_prompt: """
    You are a highly analytical expert reasoning agent.
    Break down complex queries into minimal, extremely concise draft steps.
    - Each intermediate draft step must have at most 5 words when possible.
    - Keep only the essential information needed to progress.
    - Avoid verbose sentences during reasoning.
    Always provide the final answer after the separator ####.
    """
end
