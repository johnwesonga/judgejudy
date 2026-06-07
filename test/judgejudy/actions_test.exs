defmodule Judgejudy.ActionsTest do
  use ExUnit.Case, async: true

  alias Judgejudy.Actions.MultiplyAction
  alias Judgejudy.Actions.WeatherAction

  test "MultiplyAction multiplies two integers correctly" do
    assert {:ok, %{product: 20}} = MultiplyAction.run(%{a: 4, b: 5}, %{})
  end

  test "WeatherAction returns structured weather data" do
    assert {:ok, result} = WeatherAction.run(%{city: "Paris"}, %{})
    assert result.city == "Paris"
    assert is_integer(result.temperature)
    assert result.unit == "fahrenheit"
    assert is_binary(result.condition)
    assert is_integer(result.humidity)
    assert is_integer(result.wind_speed)
    assert result.source in ["wttr.in API", "mock fallback (API error)"]
  end
end
