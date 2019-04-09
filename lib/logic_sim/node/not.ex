defmodule LogicSim.Node.Not do
  @moduledoc """
  Simple `not` logic gate. One input and one output. Output is opposite of input.
  """
  use LogicSim.Node, inputs: [:a], outputs: [:a]

  def calculate_outputs(_state, %{a: a} = _input_values) do
    %{a: !a}
  end
end
