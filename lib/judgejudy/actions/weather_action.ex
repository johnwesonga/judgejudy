defmodule Judgejudy.Actions.WeatherAction do
  use Jido.Action,
    name: "weather",
    schema: Zoi.object(%{city: Zoi.string()}),
    description: "Weather Action"

  require Logger

  @impl true
  def run(%{city: city}, _context) do
    Logger.info("retrieve weather for city #{city}")

    case fetch_weather(city) do
      {:ok, weather_data} ->
        {:ok, weather_data}

      {:error, reason} ->
        Logger.warning("failed to retrieve weather from wttr.in for #{city}: #{inspect(reason)}. Falling back to mock data.")
        # Return fallback mock data
        {:ok, %{
          city: city,
          temperature: 72,
          unit: "fahrenheit",
          condition: "sunny",
          humidity: 40,
          wind_speed: 8,
          source: "mock fallback (API error)"
        }}
    end
  end

  defp fetch_weather(city) do
    url = "https://wttr.in/#{URI.encode(city)}?format=j1"
    # Set a reasonable timeout so we don't hang the Agent
    options = [receive_timeout: 5000]

    case Req.get(url, options) do
      {:ok, %Req.Response{status: 200, body: body}} ->
        case Jason.decode(body) do
          {:ok, decoded} -> extract_weather_info(decoded, city)
          {:error, _} = err -> err
        end

      {:ok, %Req.Response{status: status}} ->
        {:error, {:http_status, status}}

      {:error, reason} ->
        {:error, reason}
    end
  rescue
    e -> {:error, e}
  end

  defp extract_weather_info(data, city) do
    case data["current_condition"] do
      [condition | _] ->
        temp_f = condition["temp_F"] |> String.to_integer()
        temp_c = condition["temp_C"] |> String.to_integer()
        humidity = condition["humidity"] |> String.to_integer()
        wind_speed = condition["windspeedMiles"] |> String.to_integer()
        
        desc =
          case condition["weatherDesc"] do
            [%{"value" => value} | _] -> String.trim(value)
            _ -> "unknown"
          end

        {:ok, %{
          city: city,
          temperature: temp_f,
          temperature_c: temp_c,
          unit: "fahrenheit",
          condition: desc,
          humidity: humidity,
          wind_speed: wind_speed,
          source: "wttr.in API"
        }}

      _ ->
        {:error, :invalid_response_format}
    end
  rescue
    _ -> {:error, :parsing_failed}
  end
end
