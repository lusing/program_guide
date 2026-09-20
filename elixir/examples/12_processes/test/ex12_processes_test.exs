defmodule Ex12ProcessesTest do
  use ExUnit.Case, async: true

  doctest Ex12Processes

  alias Ex12Processes

  describe "echo 进程" do
    test "spawn / send / receive 往返" do
      pid = Ex12Processes.start_echo()
      assert is_pid(pid)
      assert Ex12Processes.call_echo(pid, "hello") == {:ok, "hello"}
      assert Ex12Processes.stop(pid) == :stop
      # 进程结束后异步消失，轮询等待，避免时间依赖断言
      wait_until(fn -> not Process.alive?(pid) end)
    end

    test "不认识的消息不会弄崩循环进程" do
      pid = Ex12Processes.start_echo()
      send(pid, :garbage)
      assert Ex12Processes.call_echo(pid, 42) == {:ok, 42}
      Ex12Processes.stop(pid)
    end
  end

  describe "计数器状态 loop" do
    test "inc/add/get 的状态只在进程内部演进" do
      c = Ex12Processes.start_counter(10)
      Ex12Processes.increment(c)
      Ex12Processes.increment(c)
      Ex12Processes.add(c, 5)
      assert Ex12Processes.get_count(c) == 17
      assert Ex12Processes.stop_counter(c) == :stop
    end

    test "两个计数器互不共享状态" do
      a = Ex12Processes.start_counter(0)
      b = Ex12Processes.start_counter(100)
      Ex12Processes.increment(a)
      assert Ex12Processes.get_count(a) == 1
      assert Ex12Processes.get_count(b) == 100
      Ex12Processes.stop_counter(a)
      Ex12Processes.stop_counter(b)
    end
  end

  describe "邮箱" do
    test "selective_receive 先取 :a 再取 :b" do
      assert Ex12Processes.selective_receive() == {:a, :b}
    end

    test "parallel_work 收齐并排序，跨调度器数量稳定" do
      assert Ex12Processes.parallel_work(20) == Enum.to_list(1..20)
    end

    test "flush_mailbox 排空后为空" do
      send(self(), {:q, 1})
      send(self(), {:q, 2})
      assert Ex12Processes.flush_mailbox() == [{:q, 1}, {:q, 2}]
      assert Ex12Processes.flush_mailbox() == []
    end

    test "Process.info 能看到邮箱长度" do
      send(self(), :m1)
      send(self(), :m2)
      assert {:messages, msgs} = Process.info(self(), :messages)
      assert :m1 in msgs and :m2 in msgs
      Ex12Processes.flush_mailbox()
    end
  end

  describe "link / trap_exit" do
    test "trap_exit 把 link 退出变成消息，调用方存活" do
      assert Ex12Processes.linked_exit(fn -> exit(:boom) end) == {:exit, :boom}
      assert Process.alive?(self())
      # linked_exit 结束时恢复了 trap_exit
      assert Process.info(self(), :trap_exit) == {:trap_exit, false}
    end

    test "异常退出规范化为异常类型 + 消息，不带栈迹" do
      assert Ex12Processes.linked_exit(fn -> raise RuntimeError, "x" end) ==
               {:error_exit, RuntimeError, "x"}
    end

    test "正常结束的 link 给 :normal 原因" do
      assert Ex12Processes.linked_exit(fn -> :done end) == {:exit, :normal}
    end

    test "不 trap_exit 时 link 连坐：监控者随子进程一起死" do
      assert Ex12Processes.link_propagates?() == :watcher_died_from_link
    end
  end

  describe "monitor" do
    test "DOWN 消息带退出原因" do
      assert Ex12Processes.monitored_exit(fn -> exit(:gone) end) == {:exit, :gone}

      assert Ex12Processes.monitored_exit(fn -> raise ArgumentError, "bad" end) ==
               {:error_exit, ArgumentError, "bad"}
    end

    test "demonitor :flush 后收不到 DOWN" do
      assert Ex12Processes.demonitor_demo() == {true, false}
    end

    test "monitor 是单向的：被监控进程不受监控者退出影响" do
      target = Ex12Processes.start_echo()
      watcher = spawn(fn -> monitor_and_block(target) end)
      wait_until(fn -> Process.alive?(watcher) end)
      Process.exit(watcher, :kill)
      wait_until(fn -> not Process.alive?(watcher) end)
      # 被监控的 echo 进程仍然能服务
      assert Ex12Processes.call_echo(target, "still alive") == {:ok, "still alive"}
      Ex12Processes.stop(target)
    end
  end

  describe "命名进程" do
    test "with_named_counter 注册/按名通信/注销全流程" do
      assert Ex12Processes.with_named_counter() == {true, 2, true}
    end

    test "重名注册失败，重复 register 抛 ArgumentError" do
      name = :"ex12_dup_#{:erlang.unique_integer([:positive])}"
      pid = Ex12Processes.start_counter(0)
      assert Process.register(pid, name) == true
      assert_raise ArgumentError, fn -> Process.register(self(), name) end
      Process.unregister(name)
      Ex12Processes.stop_counter(pid)
    end

    test "给未注册名字发消息抛 ArgumentError" do
      assert Ex12Processes.send_to_missing_name() == :argument_error
    end
  end

  # 让测试里的进程在退出前一直阻塞（配合 monitor 单向性测试）。
  defp monitor_and_block(target) do
    Process.monitor(target)

    receive do
      :never -> :never
    end
  end

  defp wait_until(fun, attempts \\ 50) do
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
