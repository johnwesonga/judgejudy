defmodule Judgejudy.Tools.Calc.Add do
  use Jido.Action,
    name: "add",
    schema: Zoi.object(%{a: Zoi.integer(), b: Zoi.integer()}),
    description: "add_tool"

  @impl true
  def run(%{a: a, b: b}, _context), do: {:ok, %{sum: a + b}}
end
