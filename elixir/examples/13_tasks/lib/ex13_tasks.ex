defmodule Ex13Tasks do
  @moduledoc """
  第 13 章示例：Task 并发。

  Task 是对第 12 章裸原语的封装：`Task.async/1` = spawn + 监控 + 把回复约定
  成消息；`Task.await/2` = receive 配对的回复，超时/失败自动传播。
  它适合「分叉—汇合」（fork/join）型并发：每个元素一个任务、稍后收结果。

  本章所有对外输出同样不含 pid/reference：退出原因统一由 `normalize_down/1`
  压成 `{:exc, 异常模块, 消息}` / `{:timeout, :await}` 这样的确定性标签。

      iex> Ex13Tasks.pmap(1..4, &Ex13Tasks.slow_square/1)
      [1, 4, 9, 16]

  """

  # ============================================================
  # 1. fork/join：async / await 与保序的并行 map
  # ============================================================

  @doc """
  模拟耗时但确定的工作（睡 20ms 再平方），用来观察并发效果。
  """
  @spec slow_square(integer()) :: integer()
  def slow_square(n) do
    Process.sleep(20)
    n * n
  end

  @doc """
  保序并行 map：先把所有任务分叉出去，再按**任务顺序**逐个 await。
  结果顺序等于输入顺序（await 逐个配对），与完成先后无关。

      iex> Ex13Tasks.pmap(1..4, &Ex13Tasks.slow_square/1)
      [1, 4, 9, 16]

  """
  @spec pmap(Enumerable.t(a), (a -> b)) :: [b] when a: term(), b: term()
  def pmap(enumerable, fun) do
    enumerable
    |> Enum.map(&Task.async(fn -> fun.(&1) end))
    |> Enum.map(&Task.await(&1, 5_000))
  end

  # ============================================================
  # 2. 失败传播：任务异常 = 调用方进程 exit（1.20 语义，不是 raise！）
  # ============================================================

  @doc """
  **1.20 关键事实**：任务进程异常死亡时，`Task.await/2` 不会抛异常给你
  rescue，而是让**调用方进程以同样原因 exit**（async 任务与调用方 link）。
  想在边界安全收口，三件套：`trap_exit`（退出信号变邮箱消息）+ `yield`
  （返回 `{:exit, reason}` 而不是杀进程）+ 排空 link 信号并复位标志。

      iex> Ex13Tasks.safe_await(fn -> 7 * 6 end)
      {:ok, 42}

      iex> Ex13Tasks.safe_await(fn -> raise RuntimeError, "boom" end)
      {:error, {RuntimeError, "boom"}}

      iex> Ex13Tasks.safe_await(fn -> exit(:gone) end)
      {:exit, :gone}

  """
  @spec safe_await((-> a)) ::
          {:ok, a}
          | {:error, {module(), binary()}}
          | {:exit, term()}
          | :timeout
        when a: term()
  def safe_await(fun) do
    task = Task.async(fun)
    Process.flag(:trap_exit, true)

    result =
      case Task.yield(task, 1_000) do
        {:ok, value} ->
          {:ok, value}

        {:exit, {exception, stacktrace}}
        when is_exception(exception) and is_list(stacktrace) ->
          {:error, {exception.__struct__, Exception.message(exception)}}

        {:exit, reason} ->
          {:exit, reason}

        nil ->
          # 不想要结果了：brutal_kill 立即收掉任务，避免任务泄漏。
          Task.shutdown(task, :brutal_kill)
          :timeout
      end

    drain_exit(task.pid)
    Process.flag(:trap_exit, false)
    result
  end

  @doc """
  不做任何防护时，任务异常如何抵达 await 的调用方：本函数拉起一个 runner
  进程去 `Task.await`，主进程 monitor runner，返回 runner 的规范化死因。

      iex> Ex13Tasks.await_exit_reason(fn -> raise RuntimeError, "boom" end)
      {:exc, RuntimeError, "boom"}

  """
  @spec await_exit_reason((-> any())) :: {:exc, module(), binary()} | :no_down | term()
  def await_exit_reason(fun) do
    runner =
      spawn(fn ->
        fun |> Task.async() |> Task.await(1_000)
      end)

    ref = Process.monitor(runner)

    receive do
      {:DOWN, ^ref, :process, ^runner, reason} -> normalize_down(reason)
    after
      2_000 -> :no_down
    end
  end

  # 排空 trap_exit 期间 link 投递的 {:EXIT, pid, reason}（正常/异常各至多一条）。
  @spec drain_exit(pid()) :: :drained
  defp drain_exit(pid) do
    receive do
      {:EXIT, ^pid, _reason} -> :drained
    after
      0 -> :drained
    end
  end

  # ============================================================
  # 3. 超时：yield 不杀调用方；await 超时杀调用方
  # ============================================================

  @doc """
  `Task.yield/2` 是非致命等待：到期返回 `nil`（任务还在跑），可以决定
  `Task.shutdown/2` 收掉它。注意未 trap_exit 时，任务**异常**死亡的 link
  信号仍会杀死本进程，yield 兜不住——那是 `safe_await/1` 的场景。

      iex> Ex13Tasks.try_await(fn -> :done end, 1_000)
      {:ok, :done}

      iex> Ex13Tasks.try_await(fn -> Process.sleep(60_000) end, 30)
      :timeout

  """
  @spec try_await((-> a), timeout()) :: {:ok, a} | :timeout | {:exit, term()} when a: term()
  def try_await(fun, timeout_ms) do
    task = Task.async(fun)

    case Task.yield(task, timeout_ms) do
      {:ok, value} ->
        {:ok, value}

      {:exit, reason} ->
        {:exit, reason}

      nil ->
        # 不想要结果了：brutal_kill 立即收掉任务，避免任务泄漏。
        Task.shutdown(task, :brutal_kill)
        :timeout
    end
  end

  @doc """
  `Task.await/2` 超时不是返回 nil，而是**让调用方进程退出**，退出原因形如
  `{:timeout, {Task, :await, [task, 超时毫秒]}}`（同时杀掉超时任务）。
  本函数拉起一个 runner 进程去 await 慢任务，主进程 monitor runner，
  返回规范化的退出原因。

      iex> Ex13Tasks.await_timeout_kills_caller?()
      {:timeout, :await}

  """
  @spec await_timeout_kills_caller?() :: {:timeout, :await} | :no_down | term()
  def await_timeout_kills_caller? do
    runner =
      spawn(fn ->
        task = Task.async(fn -> Process.sleep(60_000) end)
        Task.await(task, 30)
      end)

    ref = Process.monitor(runner)

    receive do
      {:DOWN, ^ref, :process, ^runner, reason} -> normalize_down(reason)
    after
      2_000 -> :no_down
    end
  end

  # ============================================================
  # 4/5. async_stream：把并发塞进流式管线
  # ============================================================

  @doc """
  `Task.async_stream/2` 对可枚举对象的每个元素起一个任务，产出一个
  **默认按输入顺序**的结果流；每个元素包成 `{:ok, value}`。

      iex> Ex13Tasks.stream_squares(1..3)
      [ok: 1, ok: 4, ok: 9]

  """
  @spec stream_squares(Enumerable.t(integer())) :: [keyword(integer())]
  def stream_squares(range) do
    range
    |> Task.async_stream(fn n -> slow_square(n) end, max_concurrency: 4)
    |> Enum.to_list()
  end

  @doc """
  超时项用 `on_timeout: :kill_task`：只杀那一个任务、该位置产出
  `{:exit, :timeout}`，stream 调用方存活。第二个元素故意睡过头。

      iex> Ex13Tasks.stream_timeouts([1, 2])
      [ok: 10, exit: :timeout]

  """
  @spec stream_timeouts(Enumerable.t(integer())) :: [keyword(term())]
  def stream_timeouts(values) do
    values
    |> Task.async_stream(
      fn
        1 -> 10
        _ -> Process.sleep(60_000)
      end,
      timeout: 40,
      on_timeout: :kill_task
    )
    |> Enum.to_list()
  end

  @doc """
  默认语义下，任务异常退出会**直接杀死正在枚举 stream 的进程**，
  错误原因沿 monitor 传播（1.20 没有「逐元素继续」选项）。
  本函数返回规范化后的死因。

      iex> Ex13Tasks.stream_failure_reason()
      {:exc, RuntimeError, "boom"}

  """
  @spec stream_failure_reason() :: {:exc, module(), binary()} | :no_down | term()
  def stream_failure_reason do
    runner =
      spawn(fn ->
        [1, 2, 3]
        |> Task.async_stream(fn
          2 -> raise RuntimeError, "boom"
          n -> n
        end)
        |> Enum.to_list()
      end)

    ref = Process.monitor(runner)

    receive do
      {:DOWN, ^ref, :process, ^runner, reason} -> normalize_down(reason)
    after
      2_000 -> :no_down
    end
  end

  # ============================================================
  # 6. Task.Supervisor：受监督的临时任务
  # ============================================================

  @doc """
  在 `Task.Supervisor` 下起一个受监督任务并取结果。

      iex> Ex13Tasks.supervised_value()
      42

  """
  @spec supervised_value() :: term()
  def supervised_value do
    {:ok, sup} = Task.Supervisor.start_link()

    result =
      sup
      |> Task.Supervisor.async(fn -> 6 * 7 end)
      |> Task.await(1_000)

    DynamicSupervisor.stop(sup)
    result
  end

  @doc """
  Task 子进程默认是 `:temporary` 重启策略：崩了**不重启**，但监督者本身
  不受影响。起一个常驻任务和一个必崩任务，等崩溃通知后数存活子进程：
  返回 `{监督者存活?, 剩余活跃子任务数}` = `{true, 1}`。

      iex> Ex13Tasks.supervisor_demo()
      {true, 1}

  """
  @spec supervisor_demo() :: {boolean(), non_neg_integer()}
  def supervisor_demo do
    {:ok, sup} = Task.Supervisor.start_link()

    {:ok, linger} =
      Task.Supervisor.start_child(sup, fn ->
        receive do
          :stop -> :ok
        end
      end)

    {:ok, bad} =
      Task.Supervisor.start_child(sup, fn -> raise RuntimeError, "child boom" end)

    crash_ref = Process.monitor(bad)

    receive do
      {:DOWN, ^crash_ref, :process, ^bad, _} -> :crashed
    after
      1_000 -> :no_down
    end

    # DOWN 到达时监督者可能尚未完成子进程摘除，轮询到稳定计数。
    active = wait_for_active(sup, 1)
    alive? = Process.alive?(sup)
    send(linger, :stop)
    DynamicSupervisor.stop(sup)
    {alive?, active}
  end

  @spec wait_for_active(pid(), non_neg_integer()) :: non_neg_integer()
  defp wait_for_active(sup, expected, attempts \\ 100) do
    count = DynamicSupervisor.count_children(sup).active

    cond do
      count == expected ->
        count

      attempts == 0 ->
        count

      true ->
        Process.sleep(10)
        wait_for_active(sup, expected, attempts - 1)
    end
  end

  # 退出原因规范化：把 task/ref/栈迹替换成确定性标签（测试也要用，故导出）。
  @doc false
  @spec normalize_down(term()) :: term()
  def normalize_down({:timeout, {Task, :await, _}}) do
    {:timeout, :await}
  end

  def normalize_down({:timeout, ref}) when is_reference(ref) do
    {:timeout, :ref}
  end

  def normalize_down({exception, stacktrace})
      when is_exception(exception) and is_list(stacktrace) do
    {:exc, exception.__struct__, Exception.message(exception)}
  end

  def normalize_down(other), do: other
end
