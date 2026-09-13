defmodule Ex09AgentState do
  def start_link(initial \\ 0) do
    Agent.start_link(fn -> initial end)
  end

  def inc(pid), do: Agent.update(pid, &(&1 + 1))
  def get(pid), do: Agent.get(pid, & &1)
end

