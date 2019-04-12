defmodule LogicSim.Node do
  @moduledoc """
  A node is the basic building block of LogicSim. A node is a GenServer that has 0 or more
  inputs, and 0 or more outputs. Each node keeps track of which nodes are connected to each
  of its outputs. When an output changes the node sends a message to its connected nodes
  telling them what value to set on the input they are conneted to.

  Nodes are modules that `use LogicSim.Node` as demonstrated below, optionally specifying a list of inputs,
  a list of outputs, and/or a map with additional state:

  ```
  defmodule LogicSim.Node.Or do
    use LogicSim.Node, inputs: [:a, :b], outputs: [:a]

  defmodule LogicSim.Node.OnOffSwitch do
    use LogicSim.Node, outputs: [:a], additional_state: %{on: false}
  ```

  and implement the callback calculate_outputs/2 to generate all output values given the current input
  values as demonstrated here (the `Not` gate):

  ```
  def calculate_outputs(_state, %{a: a} = _input_values) do
    %{a: !a}
  end
  ```

  """

  @callback calculate_outputs(state :: map(), input_values :: map()) :: map()

  # credo:disable-for-this-file Credo.Check.Refactor.LongQuoteBlocks
  defmacro __using__(opts) do
    inputs = Keyword.get(opts, :inputs, [])
    outputs = Keyword.get(opts, :outputs, [])
    additional_state = Keyword.get(opts, :additional_state, Macro.escape(%{}))

    quote do
      use GenServer
      require Logger
      @behaviour LogicSim.Node

      @doc """
      Starts the node with the given options

      Possible Options:

      listeners: a list of process pids that should be notified whenever the state of the node
      changes. Listener will receive `{:logic_sim_node_state, this_nodes_pid, this_nodes_state}`
      """
      def start_link(opts \\ []) do
        output_nodes = Enum.reduce(unquote(outputs), %{}, &Map.put(&2, &1, %{}))
        output_values = Enum.reduce(unquote(outputs), %{}, &Map.put(&2, &1, false))
        input_values = Enum.reduce(unquote(inputs), %{}, &Map.put(&2, &1, false))
        listeners = Keyword.get(opts, :listeners, [])

        state =
          unquote(additional_state)
          |> Map.put(:inputs, unquote(inputs))
          |> Map.put(:outputs, unquote(outputs))
          |> Map.put(:output_nodes, output_nodes)
          |> Map.put(:output_values, output_values)
          |> Map.put(:input_values, input_values)
          |> Map.put(:listeners, listeners)

        GenServer.start_link(__MODULE__, state)
      end

      @doc """
      Same as `start_link/1` but raises on error.
      """
      def start_link!(opts \\ []) do
        {:ok, server} = start_link(opts)
        server
      end

      @doc false
      def child_spec(_) do
        raise "child_spec not currently supported on #{__MODULE__}"
      end

      ## GenServer Client functions

      @doc """
      Links this nodes output to the input of another node.

      Takes the output node, the output to attach from, the node to attach to, and
      the node's input to attach to.
      """
      def link_output_to_node(output_node, output, input_node, input) do
        GenServer.call(output_node, {:link_output_to_node, output, input_node, input})
      end

      @doc """
      Tells this node to set its input to the given value

      Will be called by another node when its output is changed while linked to this input.
      """
      def set_node_input(node, input, input_value) do
        GenServer.cast(node, {:set_node_input, input, input_value})
      end

      @doc """
      Returns state of server.

      Also can be called from `LogicSim.Node.get_state` if you don't know the node type.
      """
      def get_state(server) do
        GenServer.call(server, :get_state)
      end

      ## GenServer Server functions

      @doc false
      def init(state) do
        Logger.debug("Init node of type #{__MODULE__} with state #{inspect(state)}")
        {:ok, state}
      end

      defp send_state_to_listeners(%{listeners: listeners} = state) do
        listeners
        |> Enum.map(&send(&1, {:logic_sim_node_state, self(), state}))
      end

      def handle_call(:get_state, _from, state) do
        {:reply, state, state}
      end

      def handle_call(
            {:link_output_to_node, output, node, input},
            _from,
            %{output_nodes: output_nodes, output_values: output_values} = state
          ) do
        Logger.debug(
          "Linking #{inspect(__MODULE__)} #{inspect(self())} output #{inspect(output)} to #{
            inspect(node)
          } input #{inspect(input)}"
        )

        output_value = Map.fetch!(output_values, output)

        nodes_for_this_output =
          output_nodes
          |> Map.fetch!(output)
          |> Map.put(node, input)

        output_nodes = Map.put(output_nodes, output, nodes_for_this_output)

        set_node_input(node, input, Map.fetch!(output_values, output))
        state = %{state | output_nodes: output_nodes}
        send_state_to_listeners(state)
        {:reply, :ok, state}
      end

      def handle_cast(
            {:set_node_input, input, input_value},
            %{
              input_values: input_values,
              output_values: old_output_values,
              output_nodes: output_nodes
            } = state
          ) do
        if Map.get(input_values, input) != input_value do
          Logger.debug(
            "Setting input value for #{inspect(__MODULE__)} #{inspect(self())} #{inspect(input)} to #{
              inspect(input_value)
            }"
          )

          input_values = Map.put(input_values, input, input_value)
          output_values = calculate_outputs(state, input_values)

          Logger.debug(
            "New output values for #{inspect(__MODULE__)} #{inspect(self())} are #{
              inspect(output_values)
            }"
          )

          output_values
          |> Map.keys()
          |> Enum.filter(fn key -> old_output_values[key] != output_values[key] end)
          |> Enum.each(fn output ->
            output_nodes
            |> Map.get(output)
            |> Enum.map(fn {node, input} -> set_node_input(node, input, output_values[output]) end)
          end)

          state = %{state | input_values: input_values, output_values: output_values}
          send_state_to_listeners(state)
          {:noreply, state}
        else
          {:noreply, state}
        end
      end

      ## Internal functions
      defp set_output_value(
             output,
             output_value,
             %{output_nodes: output_nodes, output_values: output_values} = state
           ) do
        if Map.get(output_values, output) != output_value do
          Logger.debug(
            "Setting output value for #{inspect(__MODULE__)} #{inspect(self())} #{inspect(output)} to #{
              inspect(output_value)
            }"
          )

          output_values = Map.put(output_values, output, output_value)

          output_nodes
          |> Map.get(output)
          |> Enum.each(fn {node, input} -> set_node_input(node, input, output_value) end)

          state = %{state | output_values: output_values}
          send_state_to_listeners(state)
          state
        else
          state
        end
      end
    end
  end

  @doc """
  Generic version of function that allows linking of two nodes without having to know or
  call the specific node type's version.
  """
  def link_output_to_node(server, output, node, input) do
    GenServer.call(server, {:link_output_to_node, output, node, input})
  end

  def get_state(server) do
    GenServer.call(server, :get_state)
  end
end
