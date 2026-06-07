defmodule Judgejudy.Agents.ArchAgent do
  use Jido.AI.ToTAgent,
    name: "architecture_advisor",
    branching_factor: 2,
    max_depth: 2,
    top_k: 2,
    max_nodes: 20,
    max_duration_ms: 25_000
end
