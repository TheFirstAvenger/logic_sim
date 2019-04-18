defmodule LogicSim.NodeTest do
  use ExUnit.Case

  defmodule TestNotNode do
    use LogicSim.Node, outputs: [:a], inputs: [:a], additional_state: %{foo: :bar}

    def calculate_outputs(_state, %{a: a} = _input_values) do
      %{a: !a}
    end
  end

  test "populates use opts" do
    pid = start_supervised!({TestNotNode, listeners: [self()]})
    slf = self()

    assert %{outputs: [:a], inputs: [:a], listeners: [^slf], foo: :bar} =
             TestNotNode.get_state(pid)
  end

  test "sends state to listeners on input change" do
    pid = TestNotNode.start_link!(listeners: [self()])
    TestNotNode.set_node_input(pid, :a, true)
    assert_receive {:logic_sim_node_state, ^pid, state}
    assert state == TestNotNode.get_state(pid)
    assert %{output_values: %{a: false}} = state
  end

  test "sends output state to input nodes on link" do
    pid1 = TestNotNode.start_link!(listeners: [self()])
    TestNotNode.set_node_input(pid1, :a, true)
    assert_receive {:logic_sim_node_state, ^pid1, %{output_values: %{a: false}}}
    pid2 = TestNotNode.start_link!(listeners: [self()])
    TestNotNode.set_node_input(pid2, :a, true)
    assert_receive {:logic_sim_node_state, ^pid2, %{output_values: %{a: false}}}
    TestNotNode.link_output_to_node(pid1, :a, pid2, :a)
    assert_receive {:logic_sim_node_state, ^pid2, %{output_values: %{a: true}}}
  end

  test "sends output state to input nodes on input change" do
    pid1 = TestNotNode.start_link!(listeners: [self()])
    TestNotNode.set_node_input(pid1, :a, true)
    assert_receive {:logic_sim_node_state, ^pid1, %{output_values: %{a: false}}}
    refute_receive _
    pid2 = TestNotNode.start_link!(listeners: [self()])
    TestNotNode.set_node_input(pid2, :a, true)
    assert_receive {:logic_sim_node_state, ^pid2, %{output_values: %{a: false}}}
    refute_receive _
    TestNotNode.link_output_to_node(pid1, :a, pid2, :a)
    assert_receive {:logic_sim_node_state, ^pid1, %{output_values: %{a: false}}}
    assert_receive {:logic_sim_node_state, ^pid2, %{output_values: %{a: true}}}
  end
end
