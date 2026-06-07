defmodule Judgejudy.Agents.CalcAgent do
  use Jido.AI.Agent,
    name: "calc_agent",
    description: "Calculator Agent",
    model: :fast,
    tools: [
      Judgejudy.Tools.Calc.Multiply,
      Judgejudy.Tools.Calc.Add,
      Judgejudy.Tools.Calc.Subtraction
    ]
end
