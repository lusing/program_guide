defmodule Ex15Genservers.KeyStore do
  @moduledoc """
  一个带「闲置自动清空」的键值存储 GenServer，演示第 15 章全部要素：

  - **两段式结构**：客户端 API（在调用方进程执行，只负责发消息）与
    服务端回调（handle_call/cast/info，在服务进程串行执行）；
  - 三类消息：`GenServer.call`（同步等回复）、`GenServer.cast`（火并忘）、
    普通 `send/2` 进来的消息由 `handle_info` 接（如 `:bump`、`:timeout`）；
  - 空闲超时：回调返回值第四项给毫秒数，服务进程闲置该时长后给自己发
    `:timeout`，由 handle_info 清空数据。
  """

  use GenServer

  # 状态只存在服务进程里；armed? 表示「下一次空闲超时是否已上膛」。
  defstruct data: %{},
            bumps: 0,
            clears: 0,
            idle_ms: :infinity,
            armed?: false

  # ============================================================
  # 客户端 API（执行在调用方进程）
  # ============================================================

  @doc "启动；opts: name（注册名）、idle_ms（空闲清空毫秒，默认 :infinity）、initial（初始 map）。"
  def start_link(opts \\ []) do
    name = Keyword.get(opts, :name)
    idle_ms = Keyword.get(opts, :idle_ms, :infinity)
    initial = Keyword.get(opts, :initial, %{})
    args = %{idle_ms: idle_ms, initial: initial}

    if name,
      do: GenServer.start_link(__MODULE__, args, name: name),
      else: GenServer.start_link(__MODULE__, args)
  end

  @doc "同步取值（call）。"
  def get(server, key) do
    GenServer.call(server, {:get, key})
  end

  @doc "同步写入，回 :ok。"
  def put(server, key, value) do
    GenServer.call(server, {:put, key, value})
  end

  @doc "异步写入（cast），立即返回 :ok。"
  def put_cast(server, key, value) do
    GenServer.cast(server, {:put, key, value})
  end

  @doc "同步取排序后的全部键值（map 顺序不确定，对外排序）。"
  def snapshot(server) do
    GenServer.call(server, :snapshot)
  end

  @doc "读计数器 {外部 :bump 次数, 空闲清空次数}。"
  def stats(server) do
    GenServer.call(server, :stats)
  end

  @doc "故意发一条**普通消息**（不经 GenServer.call/cast），由 handle_info 处理。"
  def bump(server) do
    send(server, :bump)
    :bumped
  end

  @doc "让服务端睡眠 ms 毫秒再回复——演示调用方 call 超时（服务端不死）。"
  def slow_call(server, ms, timeout \\ 5000) do
    GenServer.call(server, {:slow, ms}, timeout)
  end

  def stop(server) do
    GenServer.stop(server)
  end

  # ============================================================
  # 服务端回调（执行在 KeyStore 服务进程，全部串行）
  # ============================================================

  @impl true
  def init(%{idle_ms: idle_ms, initial: initial}) do
    {:ok, %__MODULE__{data: initial, idle_ms: idle_ms}}
  end

  # call 必须回 {:reply, 答案, 新状态}；第四项控制空闲超时计时器。
  @impl true
  def handle_call({:get, key}, _from, state = %__MODULE__{}) do
    {:reply, Map.get(state.data, key), state, idle_after(state)}
  end

  def handle_call({:put, key, value}, _from, state = %__MODULE__{}) do
    state = %__MODULE__{state | data: Map.put(state.data, key, value), armed?: true}
    {:reply, :ok, state, state.idle_ms}
  end

  def handle_call(:snapshot, _from, state = %__MODULE__{}) do
    {:reply, state.data |> Map.to_list() |> Enum.sort(), state, idle_after(state)}
  end

  def handle_call(:stats, _from, state = %__MODULE__{}) do
    {:reply, {state.bumps, state.clears}, state, idle_after(state)}
  end

  def handle_call({:slow, ms}, _from, state = %__MODULE__{}) do
    Process.sleep(ms)
    {:reply, {:slept, ms}, state, idle_after(state)}
  end

  # cast 没有调用方在等，回 {:noreply, 新状态}；同样给空闲超时上膛。
  @impl true
  def handle_cast({:put, key, value}, state = %__MODULE__{}) do
    state = %__MODULE__{state | data: Map.put(state.data, key, value), armed?: true}
    {:noreply, state, state.idle_ms}
  end

  # 普通消息入口：外部 send/2 的 :bump 和空闲超时的 :timeout 都在这里。
  @impl true
  def handle_info(:bump, state = %__MODULE__{}) do
    {:noreply, %__MODULE__{state | bumps: state.bumps + 1}, idle_after(state)}
  end

  def handle_info(:timeout, state = %__MODULE__{}) do
    # 闲置超时触发：清空数据，计数 +1，之后不再上膛（等下一次 put 重新武装）。
    {:noreply, %__MODULE__{state | data: %{}, clears: state.clears + 1, armed?: false}, :infinity}
  end

  def handle_info(_unknown, state = %__MODULE__{}) do
    # 未知普通消息不能让进程崩：忽略并维持现状。
    {:noreply, state, idle_after(state)}
  end

  # 已上膛时返回闲置时长（每次活动都重置计时器），否则 :infinity。
  defp idle_after(%{armed?: true, idle_ms: ms}), do: ms
  defp idle_after(_state), do: :infinity
end

defmodule Ex15Genservers do
  @moduledoc """
  第 15 章示例：GenServer 通用服务器。

  核心演示都在 `Ex15Genservers.KeyStore`；本模块提供两个不打印 pid 的
  确定性观察函数，供 doctest 与 run.exs 使用。

      iex> {:ok, s} = Ex15Genservers.KeyStore.start_link()
      iex> Ex15Genservers.KeyStore.put(s, :a, 1)
      :ok
      iex> Ex15Genservers.KeyStore.get(s, :a)
      1
      iex> Ex15Genservers.KeyStore.stop(s)
      :ok

  """

  alias Ex15Genservers.KeyStore

  @doc """
  空闲清空的完整生命周期：写入 → 立即读得到 → 睡过闲置时长 → 数据清空、
  clears 计数为 1 → 再次写入 → 又一次清空，计数为 2。

      iex> Ex15Genservers.idle_clear_demo()
      {{1, {0, 0}}, {nil, {0, 1}}, {nil, {0, 2}}}

  """
  @spec idle_clear_demo() ::
          {{term(), {integer(), integer()}}, {term(), {integer(), integer()}},
           {term(), {integer(), integer()}}}
  def idle_clear_demo do
    {:ok, s} = KeyStore.start_link(idle_ms: 40)

    KeyStore.put(s, :k, 1)
    first = {KeyStore.get(s, :k), KeyStore.stats(s)}

    Process.sleep(90)
    second = {KeyStore.get(s, :k), KeyStore.stats(s)}

    KeyStore.put(s, :j, 2)
    _ = KeyStore.get(s, :j)
    Process.sleep(90)
    third = {KeyStore.get(s, :j), KeyStore.stats(s)}

    KeyStore.stop(s)
    {first, second, third}
  end

  @doc """
  GenServer.call 超时只杀**调用方**，服务端照常存活：拉起一个 runner 去
  做 30ms 超时的 200ms 慢调用，主进程 monitor runner 的死因，
  然后直接向服务端验证它还能服务。返回 `{runner 死因标签, 服务端存活?, 后续调用结果}`。

      iex> Ex15Genservers.call_timeout_demo()
      {{:timeout, :call}, true, {:slept, 1}}

  """
  @spec call_timeout_demo() :: {{:timeout, :call}, boolean(), {:slept, integer()}}
  def call_timeout_demo do
    {:ok, server} = KeyStore.start_link()

    runner =
      spawn(fn ->
        KeyStore.slow_call(server, 200, 30)
      end)

    ref = Process.monitor(runner)

    cause =
      receive do
        {:DOWN, ^ref, :process, ^runner, reason} -> normalize(reason)
      after
        1_000 -> :no_down
      end

    alive? = Process.alive?(server)
    later = KeyStore.slow_call(server, 1, 1_000)
    KeyStore.stop(server)
    {cause, alive?, later}
  end

  @doc """
  普通 send/2 消息由 handle_info 接：bump 三次后 stats 的第一个计数是 3；
  cast 写入也正常可见（同发送方消息有序）。

      iex> Ex15Genservers.info_demo()
      {3, [a: 1]}

  """
  @spec info_demo() :: {integer(), [{atom(), integer()}]}
  def info_demo do
    {:ok, s} = KeyStore.start_link()
    KeyStore.bump(s)
    KeyStore.bump(s)
    KeyStore.bump(s)
    KeyStore.put_cast(s, :a, 1)
    {bumps, _clears} = KeyStore.stats(s)
    snap = KeyStore.snapshot(s)
    KeyStore.stop(s)
    {bumps, snap}
  end

  @spec normalize(term()) :: term()
  defp normalize({:timeout, {GenServer, :call, _}}), do: {:timeout, :call}

  defp normalize({exception, stacktrace})
       when is_exception(exception) and is_list(stacktrace) do
    {:exc, exception.__struct__, Exception.message(exception)}
  end

  defp normalize(other), do: other
end
