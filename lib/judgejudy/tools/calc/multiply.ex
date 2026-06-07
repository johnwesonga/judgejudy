defmodule Judgejudy.Tools.Calc.Multiply do
  use Jido.Action,
    name: "multiply",
    schema: Zoi.object(%{a: Zoi.integer(), b: Zoi.integer()}),
    description: "multiply_tool"

  @impl true
  def run(%{a: a, b: b}, _context), do: {:ok, %{product: a * b}}
end
