defmodule Ex12Processes do
  @moduledoc """
  第 12 章示例：进程与消息。

  Elixir 的并发三原语：`spawn`（拉起一个跑任意函数的轻量进程）、
  `send/2`（异步投递消息）、`receive`（从邮箱按模式挑消息）。
  进程之间不共享内存，只靠消息通信；进程崩了默认不影响别人，
  再加上 link/monitor 两类连接和命名注册，构成 OTP 的地基。

  注意：所有对外函数的返回值都**不含 pid/reference**——它们每次运行都变，
  无法写进确定性的 doctest，本章只断言性质（is_pid/1、计数、退出原因）。

      iex> Ex12Processes.parallel_work(4)
      [1, 2, 3, 4]

  """

  # ============================================================
  # 1. spawn / send / receive：最简单的 echo 进程
  # ============================================================

  @doc """
  echo 进程的主循环：收到 `{:echo, 文本, 调用方}` 就把文本原样回送，
  收到 `:stop` 才结束；其余情况继续循环（不认识的消息不会让进程崩溃）。
  """
  @spec echo_loop() :: :stopped
  def echo_loop do
    receive do
      {:echo, text, caller} ->
        send(caller, {:reply, text})
        echo_loop()

      :stop ->
        :stopped
    end
  end

  @doc "拉起一个 echo 进程，返回 pid（请勿把 pid 写进确定性输出）。"
  @spec start_echo() :: pid()
  def start_echo, do: spawn(__MODULE__, :echo_loop, [])

  @doc "同步调用：发消息后在邮箱里等自己那条回复（带超时，避免永久阻塞）。"
  @spec call_echo(pid(), term()) :: {:ok, term()} | :timeout
  def call_echo(pid, text) do
    send(pid, {:echo, text, self()})

    receive do
      {:reply, ^text} -> {:ok, text}
    after
      1_000 -> :timeout
    end
  end

  @doc "命令 echo 进程结束。"
  @spec stop(pid()) :: :stop
  def stop(pid), do: send(pid, :stop)

  # ============================================================
  # 2. 状态藏在进程里：递归 loop 的参数就是状态
  # ============================================================

  # 计数器进程：当前值 n 以递归参数的形式「持有」，外部无法直接触碰。
  @spec counter_loop(integer()) :: {:stopped, integer()}
  defp counter_loop(n) do
    receive do
      :inc ->
        counter_loop(n + 1)

      {:add, x} ->
        counter_loop(n + x)

      {:get, caller} ->
        send(caller, {:count, n})
        counter_loop(n)

      :stop ->
        {:stopped, n}
    end
  end

  @doc "从初始值 start 拉起计数器进程。"
  @spec start_counter(integer()) :: pid()
  def start_counter(start \\ 0), do: spawn(fn -> counter_loop(start) end)

  @doc "异步加一（发完即返回，不等结果）。"
  @spec increment(pid()) :: :inc
  def increment(pid), do: send(pid, :inc)

  @doc "异步加上 x。"
  @spec add(pid(), integer()) :: {:add, integer()}
  def add(pid, x), do: send(pid, {:add, x})

  @doc "同步读计数：发问询消息后等回复。"
  @spec get_count(pid()) :: integer() | :timeout
  def get_count(pid) do
    send(pid, {:get, self()})

    receive do
      {:count, n} -> n
    after
      1_000 -> :timeout
    end
  end

  @doc "停掉计数器进程。"
  @spec stop_counter(pid()) :: :stop
  def stop_counter(pid), do: send(pid, :stop)

  # ============================================================
  # 3. 邮箱与选择性 receive
  # ============================================================

  @doc """
  选择性接收：子进程依次投送 :b、:a，本函数**先等 :a**（:b 暂存邮箱），
  取到 :a 后再取 :b。receive 是按模式扫描邮箱，不是 FIFO 弹出。

      iex> Ex12Processes.selective_receive()
      {:a, :b}

  """
  @spec selective_receive() :: {:a, :b}
  def selective_receive do
    parent = self()

    spawn(fn ->
      send(parent, :b)
      send(parent, :a)
    end)

    a = receive do: (:a -> :a)
    b = receive do: (:b -> :b)
    {a, b}
  end

  @doc """
  一次性排空邮箱，按到达顺序返回；`after 0` 表示邮箱一空立刻返回，不等待。

      iex> send(self(), :x)
      :x
      iex> send(self(), :y)
      :y
      iex> Ex12Processes.flush_mailbox()
      [:x, :y]

  """
  @spec flush_mailbox() :: list(term())
  def flush_mailbox do
    receive do
      msg -> [msg | flush_mailbox()]
    after
      0 -> []
    end
  end

  @doc """
  spawn n 个工作进程，每个完成后发 `{:done, i}`，收齐后**排序**返回。
  消息到达顺序不保证（多调度器下尤其明显），要确定性结果必须自己排序。

      iex> Ex12Processes.parallel_work(5)
      [1, 2, 3, 4, 5]

  """
  @spec parallel_work(pos_integer()) :: list(pos_integer())
  def parallel_work(n) do
    parent = self()

    Enum.each(1..n, fn i ->
      spawn(fn -> send(parent, {:done, i}) end)
    end)

    1..n
    |> Enum.map(fn _ ->
      receive do
        {:done, i} -> i
      after
        1_000 -> :timeout
      end
    end)
    |> Enum.sort()
  end

  # ============================================================
  # 4. link 与 trap_exit：进程生死的通知
  # ============================================================

  # 把退出原因规范化为不含 pid/栈迹的确定性形态。
  @spec normalize_reason(term()) :: {:exit, term()} | {:error_exit, module(), binary()}
  defp normalize_reason({exception, stacktrace})
       when is_exception(exception) and is_list(stacktrace) do
    {:error_exit, exception.__struct__, Exception.message(exception)}
  end

  defp normalize_reason(other), do: {:exit, other}

  @doc """
  开启 trap_exit 后 spawn_link 一个进程并运行 fun；子进程以任意方式退出时，
  本进程不会被连带杀死，而是在邮箱里收到 `{:EXIT, pid, reason}` 并转成
  确定性的原因标签返回。结束时恢复 trap_exit 标志。

      iex> Ex12Processes.linked_exit(fn -> exit(:boom) end)
      {:exit, :boom}

      iex> Ex12Processes.linked_exit(fn -> raise RuntimeError, "kaboom" end)
      {:error_exit, RuntimeError, "kaboom"}

      iex> Ex12Processes.linked_exit(fn -> :normal_end end)
      {:exit, :normal}

  """
  @spec linked_exit((-> any())) ::
          {:exit, term()} | {:error_exit, module(), binary()}
  def linked_exit(fun) do
    Process.flag(:trap_exit, true)
    pid = spawn_link(fun)

    result =
      receive do
        {:EXIT, ^pid, reason} -> normalize_reason(reason)
      after
        1_000 -> :no_exit
      end

    Process.flag(:trap_exit, false)
    result
  end

  @doc """
  演示「不 trap_exit 时 link 连坐」：监控一个监控进程，该进程 spawn_link
  一个立即 `exit(:boom)` 的子进程且不捕获退出信号，于是它被子进程连带杀死。
  返回监控结论标签（不含任何 pid）。
  """
  @spec link_propagates?() :: :watcher_died_from_link | :watcher_survived
  def link_propagates? do
    watcher =
      spawn(fn ->
        # 不 trap_exit：子进程异常退出会把本进程一起带走。
        spawn_link(fn -> exit(:boom) end)
        # 等一个永不到来的消息，直到被连坐杀死。
        receive do
          :never -> :never
        end
      end)

    ref = Process.monitor(watcher)

    receive do
      {:DOWN, ^ref, :process, _pid, _reason} -> :watcher_died_from_link
    after
      1_000 -> :watcher_survived
    end
  end

  # ============================================================
  # 5. monitor：单向、可监控任意进程、必有一条 DOWN
  # ============================================================

  @doc """
  spawn 一个按 fun 退出的进程并 `Process.monitor/1`，等 `{:DOWN, ...}` 后
  返回规范化退出原因。monitor 是单向的：被监控者死活不受影响，
  且无论进程是否已退出，监控者保证（尽力）收到恰好一条 DOWN。

      iex> Ex12Processes.monitored_exit(fn -> exit(:gone) end)
      {:exit, :gone}

  """
  @spec monitored_exit((-> any())) ::
          {:exit, term()} | {:error_exit, module(), binary()}
  def monitored_exit(fun) do
    pid = spawn(fun)
    ref = Process.monitor(pid)

    receive do
      {:DOWN, ^ref, :process, ^pid, reason} -> normalize_reason(reason)
    after
      1_000 -> :timeout
    end
  end

  @doc """
  监控一个存活的进程：demonitor(:flush) 撤销监控并丢弃排队中的 DOWN，
  返回 `{demonitor 是否生效, 邮箱里还能否收到 DOWN}`。

      iex> Ex12Processes.demonitor_demo()
      {true, false}

  """
  @spec demonitor_demo() :: {boolean(), boolean()}
  def demonitor_demo do
    pid = start_echo()
    ref = Process.monitor(pid)
    removed = Process.demonitor(ref, [:flush])
    stop(pid)

    down? =
      receive do
        {:DOWN, ^ref, :process, ^pid, _} -> true
      after
        0 -> false
      end

    {removed, down?}
  end

  # ============================================================
  # 6. 命名进程：给 pid 起一个 atom 名字
  # ============================================================

  @doc """
  注册一个**唯一名字**的计数器进程，演示按名字发消息、whereis 查询、
  注销。返回三元组：`{whereis 查到的是不是原 pid, 计数, 注销后 whereis 是否为 nil}`。

      iex> Ex12Processes.with_named_counter()
      {true, 2, true}

  """
  @spec with_named_counter() :: {boolean(), integer(), boolean()}
  def with_named_counter do
    name = :"ex12_named_counter_#{:erlang.unique_integer([:positive])}"
    pid = start_counter(0)
    true = Process.register(pid, name)

    send(name, :inc)
    send(name, :inc)
    count = get_count(pid)
    resolves = Process.whereis(name) == pid

    Process.unregister(name)
    gone? = Process.whereis(name) == nil

    {resolves, count, gone?}
  end

  @doc """
  给一个**没有注册**的 atom 名字 send 消息会立刻抛 ArgumentError
  （名字是发送目标的一部分，无法投递就是调用方错误）。

      iex> Ex12Processes.send_to_missing_name()
      :argument_error

  """
  @spec send_to_missing_name() :: :argument_error
  def send_to_missing_name do
    try do
      send(:ex12_name_that_was_never_registered, :hello)
    rescue
      ArgumentError -> :argument_error
    end
  end
end
