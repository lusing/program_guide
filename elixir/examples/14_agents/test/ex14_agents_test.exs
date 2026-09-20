defmodule Ex14AgentsTest do
  use ExUnit.Case, async: true

  doctest Ex14Agents

  alias Ex14Agents

  describe "整数计数器" do
    test "increment/current/cast_add 的基本往返" do
      {:ok, a} = Ex14Agents.start_link(5)
      assert Ex14Agents.current(a) == 5
      Ex14Agents.increment(a)
      Ex14Agents.increment(a, 10)
      assert Ex14Agents.current(a) == 16
      # cast 是异步的，但同一发送方的消息有序，紧接的 get 必然看得到
      Ex14Agents.cast_add(a, 4)
      assert Ex14Agents.current(a) == 20
      assert Ex14Agents.stop(a) == :ok
    end

    test "add_and_get 原子读改写" do
      {:ok, a} = Ex14Agents.start_link(0)
      assert Ex14Agents.add_and_get(a, 3) == 3
      assert Ex14Agents.add_and_get(a, 9) == 12
      Ex14Agents.stop(a)
    end

    test "多个 Agent 状态互不影响" do
      {:ok, a} = Ex14Agents.start_link(0)
      {:ok, b} = Ex14Agents.start_link(100)
      Ex14Agents.increment(a, 7)
      assert Ex14Agents.current(a) == 7
      assert Ex14Agents.current(b) == 100
      Ex14Agents.stop(a)
      Ex14Agents.stop(b)
    end
  end

  describe "map 注册表" do
    test "put/get 缺省值" do
      {:ok, r} = Ex14Agents.start_registry()
      assert Ex14Agents.reg_get(r, :missing, :dflt) == :dflt
      Ex14Agents.reg_put(r, :k, "v")
      assert Ex14Agents.reg_get(r, :k, :dflt) == "v"
      Ex14Agents.stop(r)
    end

    test "reg_sorted 按 key 排序输出" do
      {:ok, r} = Ex14Agents.start_registry()
      Ex14Agents.reg_put(r, :z, 1)
      Ex14Agents.reg_put(r, :a, 2)
      Ex14Agents.reg_put(r, :m, 3)
      assert Ex14Agents.reg_sorted(r) == [a: 2, m: 3, z: 1]
      Ex14Agents.stop(r)
    end

    test "word_count 纯函数内核不需要 Agent" do
      assert Ex14Agents.word_count(%{}, ~w(a b a)) == %{"a" => 2, "b" => 1}
    end
  end

  describe "崩溃语义" do
    test "监督重启后状态归零" do
      assert Ex14Agents.crash_resets_state?() == {1, 0}
    end

    test "死掉的 Agent 让 get 调用方收到 noproc 退出信号" do
      assert Ex14Agents.dead_agent_reason() == {:exit, :noproc}
    end

    test "回调在 Agent 进程里崩溃会杀掉 Agent（无监督则不复活）" do
      # Agent 与本测试进程 link：开 trap_exit，否则 Agent 崩溃会连坐杀死测试进程。
      Process.flag(:trap_exit, true)
      {:ok, a} = Ex14Agents.start_link(0)
      assert Ex14Agents.current(a) == 0

      runner =
        spawn(fn ->
          Agent.get(a, fn _n -> raise RuntimeError, "cb boom" end)
        end)

      ref = Process.monitor(runner)

      receive do
        {:DOWN, ^ref, :process, ^runner, _reason} -> :ok
      after
        1_000 -> flunk("runner 应该退出")
      end

      wait_until(fn -> not Process.alive?(a) end)
      Process.flag(:trap_exit, false)
    end
  end

  describe "demo 生命周期" do
    test "demo 起停干净，结果确定" do
      assert Ex14Agents.demo() == {16, 18, %{a: 1, b: 2}}
    end
  end

  defp wait_until(fun, attempts \\ 100) do
    cond do
      fun.() ->
        :ok

      attempts == 0 ->
        flunk("wait_until 超时")

      true ->
        Process.sleep(10)
        wait_until(fun, attempts - 1)
    end
  end
end
