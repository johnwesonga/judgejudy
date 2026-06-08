IO.puts("=== Agent Registry Check ===")
IO.inspect(Judgejudy.Jido.list_agents(), label: "Registered agents:")

# Check if email-agent-1 exists in registry
IO.puts("\n=== Registry lookup ===")
case Application.get_env(:jido_ai, :registry) do
  nil ->
    IO.puts("No registry config found")
  _ ->
    IO.puts("Registry exists")
    # Try to look up via Jido directly
    registry = Jido.Jido.get_registry(Judgejudy.Jido)
    case registry do
      nil -> IO.puts("Registry is nil")
      %GenStage.SourceHandler{} = reg ->
        IO.puts("Registry is a GenStage handler")
        # Query for agent-1 partition
        {:ok, refs} = GenStage.call(reg, {:find_agents, ["email-agent-1"]})
        IO.inspect(refs, label: "Found refs for email-agent-1")
    end
end

# Check agent server for email-agent-1
IO.puts("\n=== Agent Server check ===")
case Supervisor.which_children(Judgejudy.Jido) do
  [{:email_agent_1, _, _, _}] -> IO.puts("Email agent child found under Jido")
  [] -> IO.puts("Email agent child NOT found under Jido")
  _ -> IO.inspect(self(), label: "Supervisor PID")
end
