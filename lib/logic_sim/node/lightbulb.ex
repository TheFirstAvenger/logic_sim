defmodule LogicSim.Node.Lightbulb do
  @moduledoc """
  Simple lightbulb representation. Has one input and no outputs.
  """
  use LogicSim.Node, inputs: [:a], outputs: []

  def calculate_outputs(_state, _input_values) do
    %{}
  end
end
