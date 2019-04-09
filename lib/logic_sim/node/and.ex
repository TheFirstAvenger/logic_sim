defmodule LogicSim.Node.And do
  @moduledoc """
  Simple `and` logic gate. Two inputs, output is true if both inputs are true, false otherwise.
  """
  use LogicSim.Node, inputs: [:a, :b], outputs: [:a]

  def calculate_outputs(_state, %{a: a, b: b} = _input_values) do
    %{a: a and b}
  end
end
