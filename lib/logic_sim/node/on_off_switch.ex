defmodule LogicSim.Node.OnOffSwitch do
  @moduledoc """
  On/Off switch representation. No inputs, one output. Remembers current state and can
  be toggled, which inverts its output.
  """
  use LogicSim.Node, outputs: [:a], additional_state: %{on: false}

  def toggle(server) do
    GenServer.call(server, :toggle)
  end

  def handle_call(:toggle, _from, %{on: on} = state) do
    on = !on
    state = %{state | on: on}
    state = set_output_value(:a, on, state)
    {:reply, :ok, state}
  end

  def calculate_outputs(%{on: on} = _state, _input_values) do
    %{a: on}
  end
end
