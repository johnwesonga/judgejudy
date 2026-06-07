defmodule Judgejudy.Tools.Calc.Subtraction do
  use Jido.Action,
    name: "subtract",
    schema: Zoi.object(%{a: Zoi.integer(), b: Zoi.integer()}),
    description: "subtraction_tool"

  @impl true
  def run(%{a: a, b: b}, _context), do: {:ok, %{result: a - b}}
end
