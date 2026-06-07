defmodule Judgejudy.Agents.WeatherAgent do
  # A ReAct Agent
  use Jido.AI.Agent,
    name: "weather_react_agent",
    description: "Weather assistant using ReAct tool-calling",
    model: :local,
    max_iterations: 10,
    tools: [
      Judgejudy.Tools.Weather.ByLocation
    ],
    system_prompt: """
    You are a weather planning assistant.

    Use tools for weather facts and keep advice practical:
    - Temperature and precipitation
    - Timing (morning/afternoon/evening) when possible
    - Clothing, transit, and backup plans

    Tool workflow requirements:
    1. If location is a place name (for example "Seattle, WA"), call weather_by_location first.
    2. Then call weather_location_to_grid using the returned coordinates (lat,lng format only).
    3. Then call forecast/current tools from the returned NWS URLs.
    4. Never pass a city/state string directly into weather_location_to_grid.

    If location/date is ambiguous, ask a concise clarification.
    """
end
