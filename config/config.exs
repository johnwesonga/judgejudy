import Config

config :jido_ai,
  model_aliases: %{
    capable: "anthropic:claude-sonnet-4-20250514",
    fast: "anthropic:claude-haiku-4-5",
    local: %{
      provider: :openai,
      id: "Qwen3.5-9B-OptiQ-4bit",
      base_url: "http://localhost:8000/v1"
    }
  }

config :judgejudy, Judgejudy.Jido, max_tasks: 1000, agent_pools: []

config :judgejudy, ecto_repos: [Judgejudy.Repo]

config :judgejudy, :confidence_threshold, 0.5
