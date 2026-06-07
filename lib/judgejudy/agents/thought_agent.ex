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
