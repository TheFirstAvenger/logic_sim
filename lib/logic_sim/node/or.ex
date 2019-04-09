defmodule LogicSim.Node.Or do
  @moduledoc """
  Simple `or` logic gate. Two inputs, one output. Output is true if either (or both) inputs are true.
  """
  use LogicSim.Node, inputs: [:a, :b], outputs: [:a]

  def calculate_outputs(_state, %{a: a, b: b} = _input_values) do
    %{a: a or b}
  end
end
