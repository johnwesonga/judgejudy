defmodule Judgejudy.Sensors.EmailSensor do
  use GenServer
  require Logger

  @target_subjects ~w(support invoice demo help)

  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @impl true
  def init(_opts) do
    :ok = Yugo.subscribe(:inbox)
    Logger.info("EmailSensor started, subscribed to :inbox")
    {:ok, %{target_subjects: @target_subjects}}
  end

  @impl true
  def handle_info({:email, _client, email}, state) do
    subject = (email[:subject] || "") |> String.trim()

    if relevant?(subject, state.target_subjects) do
      Logger.info("EmailSensor matched: #{subject}")
      dispatch_to_agent(email)
    end

    {:noreply, state}
  end

  def handle_info(_msg, state), do: {:noreply, state}

  defp relevant?(subject, target_subjects) do
    subject_down = String.downcase(subject)
    Enum.any?(target_subjects, &String.contains?(subject_down, &1))
  end

  # lib/judgejudy/sensors/email_sensor.ex
  defp dispatch_to_agent(email) do
    {sender_name, from_address} =
      case email[:from] do
        [{name, addr} | _] -> {name || "", addr}
        _ -> {"", ""}
      end

    body = extract_text_body(email[:body])
    subject = email[:subject] || ""

    prompt = """
    Inbound email received.

    From: #{sender_name} <#{from_address}>
    Subject: #{subject}

    Body:
    #{body}
    """

    case Judgejudy.Jido.whereis("email-agent-1") do
      nil ->
        Logger.error("EmailSensor: agent not found")

      pid ->
        Logger.info("EmailSensor: triggering agent for subject=#{subject}")

        Task.start(fn ->
          case Judgejudy.Agents.EmailReActAgent.ask_sync(pid, prompt, timeout: 120_000) do
            {:ok, result} ->
              Logger.info("EmailSensor: agent completed #{inspect(result)}")

            {:error, reason} ->
              Logger.error("EmailSensor: agent failed #{inspect(reason)}")
          end
        end)
    end
  end

  defp extract_text_body({"text/plain", _params, content}), do: content
  defp extract_text_body({"text/html", _params, content}), do: content

  defp extract_text_body(parts) when is_list(parts) do
    case Enum.find(parts, fn {mime, _, _} -> mime == "text/plain" end) do
      {_, _, content} ->
        content

      nil ->
        case List.first(parts) do
          {_, _, content} -> content
          _ -> ""
        end
    end
  end

  defp extract_text_body(_), do: ""
end
