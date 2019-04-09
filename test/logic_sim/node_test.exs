defmodule LogicSim.NodeTest do
  use ExUnit.Case

  defmodule TestNode do
    use LogicSim.Node, outputs: [:a], inputs: [:a], additional_state: %{foo: :bar}

    def calculate_outputs(_state, %{a: a} = _input_values) do
      %{a: a * 5}
    end
  end

  test "populates use opts" do
    pid = start_supervised!({TestNode, listeners: [self()]})
    slf = self()

    assert %{outputs: [:a], inputs: [:a], listeners: [^slf], foo: :bar} = TestNode.get_state(pid)
  end

  test "sends state to listeners on input change" do
    pid = TestNode.start_link!(listeners: [self()])
    TestNode.set_node_input(pid, :a, 2)
    assert_receive {:logic_sim_node_state, ^pid, state}
    assert state == TestNode.get_state(pid)
    assert %{output_values: %{a: 10}} = state
  end

  test "sends output state to input nodes on link" do
    pid1 = TestNode.start_link!(listeners: [self()])
    TestNode.set_node_input(pid1, :a, 2)
    assert_receive {:logic_sim_node_state, ^pid1, %{output_values: %{a: 10}}}
    pid2 = TestNode.start_link!(listeners: [self()])
    TestNode.link_output_to_node(pid1, :a, pid2, :a)
    assert_receive {:logic_sim_node_state, ^pid2, %{output_values: %{a: 50}}}
  end

  test "sends output state to input nodes on input change" do
    {:ok, pid1} = TestNode.start_link(listeners: [self()])
    TestNode.set_node_input(pid1, :a, 2)
    assert_receive {:logic_sim_node_state, ^pid1, %{output_values: %{a: 10}}}
    {:ok, pid2} = TestNode.start_link(listeners: [self()])
    TestNode.link_output_to_node(pid1, :a, pid2, :a)
    assert_receive {:logic_sim_node_state, ^pid2, %{output_values: %{a: 50}}}
    TestNode.set_node_input(pid1, :a, 1)
    assert_receive {:logic_sim_node_state, ^pid1, %{output_values: %{a: 5}}}
    assert_receive {:logic_sim_node_state, ^pid2, %{output_values: %{a: 25}}}
  end
end
