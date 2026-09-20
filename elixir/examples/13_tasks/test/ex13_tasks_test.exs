defmodule Ex13TasksTest do
  use ExUnit.Case, async: true

  doctest Ex13Tasks

  alias Ex13Tasks

  describe "async/await 与 pmap" do
    test "结果保序，与完成先后无关" do
      assert Ex13Tasks.pmap(1..6, &Ex13Tasks.slow_square/1) == [1, 4, 9, 16, 25, 36]
    end

    test "pmap 任务异常直接杀死调用方进程（1.20：exit，非 rescue 可接）" do
      runner =
        spawn(fn ->
          Ex13Tasks.pmap([1, 2], fn
            2 -> raise RuntimeError, "boom"
            n -> n
          end)
        end)

      ref = Process.monitor(runner)

      receive do
        {:DOWN, ^ref, :process, ^runner, reason} ->
          assert Ex13Tasks.normalize_down(reason) == {:exc, RuntimeError, "boom"}
      after
        1_000 -> flunk("runner 应该被异常任务连坐杀死")
      end
    end

    test "每个任务跑在独立进程" do
      parent = self()

      Ex13Tasks.pmap([1, 2], fn _ ->
        send(parent, {:worker, self()})
        :ok
      end)

      pids =
        1..2
        |> Enum.map(fn _ ->
          receive do
            {:worker, pid} -> pid
          after
            1_000 -> flunk("没收到任务进程消息")
          end
        end)

      assert length(Enum.uniq(pids)) == 2
      refute parent in pids
    end
  end

  describe "失败传播（1.20：任务失败 = 调用方 exit）" do
    test "safe_await 成功/异常/显式退出三形态，且 trap_exit 与邮箱复位" do
      assert Ex13Tasks.safe_await(fn -> 40 + 2 end) == {:ok, 42}

      assert Ex13Tasks.safe_await(fn -> raise ArgumentError, "x" end) ==
               {:error, {ArgumentError, "x"}}

      assert Ex13Tasks.safe_await(fn -> exit(:gone) end) == {:exit, :gone}
      assert Process.info(self(), :trap_exit) == {:trap_exit, false}
      assert {:messages, []} = Process.info(self(), :messages)
    end

    test "await_exit_reason 还原 runner 被连坐杀死的原因" do
      assert Ex13Tasks.await_exit_reason(fn -> raise RuntimeError, "boom" end) ==
               {:exc, RuntimeError, "boom"}
    end
  end

  describe "超时" do
    test "yield 超时返回 nil，shutdown 收掉任务" do
      assert Ex13Tasks.try_await(fn -> :ready end, 1_000) == {:ok, :ready}
      assert Ex13Tasks.try_await(fn -> Process.sleep(60_000) end, 20) == :timeout
    end

    test "await 超时杀死调用方进程" do
      assert Ex13Tasks.await_timeout_kills_caller?() == {:timeout, :await}
    end
  end

  describe "async_stream" do
    test "默认按输入顺序产出 {:ok, value}" do
      assert Ex13Tasks.stream_squares(1..5) == [ok: 1, ok: 4, ok: 9, ok: 16, ok: 25]
    end

    test "kill_task 时坏位置给 {:exit, :timeout}，调用方存活" do
      assert Ex13Tasks.stream_timeouts([1, 2]) == [ok: 10, exit: :timeout]
    end

    test "任务异常默认杀死枚举 stream 的进程，原因可查" do
      assert Ex13Tasks.stream_failure_reason() == {:exc, RuntimeError, "boom"}
    end
  end

  describe "Task.Supervisor" do
    test "受监督任务能正常取结果" do
      assert Ex13Tasks.supervised_value() == 42
    end

    test "子任务崩溃不拖垮监督者，:temporary 任务不重启" do
      assert Ex13Tasks.supervisor_demo() == {true, 1}
    end

    test "监督者停止后，其下任务一起停止" do
      {:ok, sup} = Task.Supervisor.start_link()

      {:ok, child} =
        Task.Supervisor.start_child(sup, fn ->
          receive do
            :stop -> :ok
          end
        end)

      assert Process.alive?(child)
      DynamicSupervisor.stop(sup)
      wait_until(fn -> not Process.alive?(child) end)
    end
  end

  defp wait_until(fun, attempts \\ 100) do
    cond do
      fun.() ->
        :ok

      attempts == 0 ->
        flunk("wait_until 超时")

      true ->
        :timer.sleep(10)
        wait_until(fun, attempts - 1)
    end
  end
end
