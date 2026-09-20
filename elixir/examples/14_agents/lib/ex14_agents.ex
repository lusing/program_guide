defmodule Ex14Agents do
  @moduledoc """
  第 14 章示例：Agent 状态服务。

  Agent 把第 12 章手写的「递归参数持有状态 + 同步消息等结果」封装成
  `start_link/get/update/cast/get_and_update`。它的本质是一个**单进程**，
  所有回调都在 Agent 自己的进程里串行执行——读写天然原子，同时也意味着
  回调要尽量短小。

      iex> Ex14Agents.demo()
      {16, 18, %{a: 1, b: 2}}

  """

  # ============================================================
  # 1. start_link / get / update
  # ============================================================

  @doc "从 initial 启动一个整数计数器 Agent。"
  @spec start_link(integer()) :: Agent.on_start()
  def start_link(initial \\ 0), do: Agent.start_link(fn -> initial end)

  @doc "同步加 by（默认 1）。回调在 Agent 进程执行，新状态 = 旧状态 + by。"
  @spec increment(Agent.agent(), integer()) :: :ok
  def increment(agent, by \\ 1) do
    Agent.update(agent, fn n when is_integer(n) -> n + by end)
  end

  @doc "异步修改：cast 发完即返回 :ok，但同一发送方的消息顺序保证后续 get 看得到。"
  @spec cast_add(Agent.agent(), integer()) :: :ok
  def cast_add(agent, by) do
    Agent.cast(agent, fn n when is_integer(n) -> n + by end)
  end

  @doc "同步读当前计数。"
  @spec current(Agent.agent()) :: integer()
  def current(agent), do: Agent.get(agent, fn n when is_integer(n) -> n end)

  @doc "停掉 Agent（监督树下交给 Supervisor 管，不要手动 stop）。"
  @spec stop(Agent.agent()) :: :ok
  def stop(agent), do: Agent.stop(agent)

  # ============================================================
  # 2. get_and_update：一次往返完成读改写
  # 返回 {返回给调用方的值, 新状态}
  # ============================================================

  @doc """
  原子地读改写：回调返回 `{给调用方的值, 新状态}`。
  「读出当前值并加 by」在一次 Agent 往返内完成，中间不会插入别的请求。

      iex> {:ok, a} = Ex14Agents.start_link(10)
      iex> Ex14Agents.add_and_get(a, 8)
      18
      iex> Ex14Agents.current(a)
      18
      iex> Ex14Agents.stop(a)
      :ok

  """
  @spec add_and_get(Agent.agent(), integer()) :: integer()
  def add_and_get(agent, by) do
    Agent.get_and_update(agent, fn n when is_integer(n) -> {n + by, n + by} end)
  end

  # ============================================================
  # 3. 结构化状态：map 注册表（输出排序，杜绝 map 顺序不确定性）
  # ============================================================

  @doc "启动一个空 map 注册表 Agent。"
  @spec start_registry(map()) :: Agent.on_start()
  def start_registry(initial \\ %{}), do: Agent.start_link(fn -> initial end)

  @doc "写入键值（同步）。"
  @spec reg_put(Agent.agent(), term(), term()) :: :ok
  def reg_put(agent, key, value) do
    Agent.update(agent, fn m when is_map(m) -> Map.put(m, key, value) end)
  end

  @doc "读键，缺省 default。注意别在回调里做重活，只取数据。"
  @spec reg_get(Agent.agent(), term(), term()) :: term()
  def reg_get(agent, key, default \\ nil) do
    Agent.get(agent, fn m when is_map(m) -> Map.get(m, key, default) end)
  end

  @doc "整个状态拿出来并排序——map 迭代顺序跨调度器不稳定，输出必须排序。"
  @spec reg_sorted(Agent.agent()) :: [{term(), term()}]
  def reg_sorted(agent) do
    Agent.get(agent, fn m when is_map(m) -> m |> Map.to_list() |> Enum.sort() end)
  end

  @doc """
  纯函数内核：同一个词频统计，不引入 Agent 也能写——状态只随数据流动。
  这是「先想清楚是否真需要 Agent」的对照组。

      iex> Ex14Agents.word_count(%{"a" => 2}, ["a", "a", "b"])
      %{"a" => 4, "b" => 1}

  """
  @spec word_count(%{binary() => integer()}, [binary()]) :: %{binary() => integer()}
  def word_count(acc, words) do
    Enum.reduce(words, acc, fn w, a -> Map.update(a, w, 1, &(&1 + 1)) end)
  end

  # ============================================================
  # 4. 崩溃与监督：回调在 Agent 进程执行，回调 raise = Agent 死
  # ============================================================

  @doc """
  在一个 `restart: :permanent` 的监督者下启动命名 Agent，制造回调崩溃后
  观察状态：返回 `{崩溃前的值, 重启后的值}` = `{1, 0}`——
  **Agent 重启 = 状态从初始函数重新来一遍，旧状态丢失**（要持久化状态
  得在 init 回调里自己加载）。

      iex> Ex14Agents.crash_resets_state?()
      {1, 0}

  """
  @spec crash_resets_state?() :: {integer(), integer()}
  def crash_resets_state? do
    name = :"ex14_supervised_counter_#{:erlang.unique_integer([:positive])}"

    child = %{
      id: :counter,
      start: {Agent, :start_link, [fn -> 0 end, [name: name]]},
      restart: :permanent
    }

    {:ok, sup} = Supervisor.start_link([child], strategy: :one_for_one)

    Agent.update(name, fn n when is_integer(n) -> n + 1 end)
    before = Agent.get(name, fn n when is_integer(n) -> n end)

    # 回调里 raise：Agent 进程崩溃，监督者以同一名字重拉一个，状态归零。
    Agent.cast(name, fn _ -> raise RuntimeError, "boom" end)

    restarted = wait_restart(name)
    Supervisor.stop(sup)
    {before, restarted}
  end

  @doc """
  Agent 已死时调用 get，调用方进程会收到 `{:noproc, ...}` 退出信号。
  本函数在 runner 里发起调用、主进程 monitor runner，返回规范化死因。

      iex> Ex14Agents.dead_agent_reason()
      {:exit, :noproc}

  """
  @spec dead_agent_reason() :: {:exit, :noproc} | :no_down | term()
  def dead_agent_reason do
    {:ok, agent} = Agent.start_link(fn -> 0 end)
    :ok = Agent.stop(agent)

    runner =
      spawn(fn ->
        Agent.get(agent, fn state -> state end)
      end)

    ref = Process.monitor(runner)

    receive do
      {:DOWN, ^ref, :process, ^runner, reason} -> normalize_reason(reason)
    after
      1_000 -> :no_down
    end
  end

  # ============================================================
  # 5. 一站式演示（doctest）
  # ============================================================

  @doc """
  整数计数器 + map 注册表的完整生命周期演示，进程在函数内部起停。
  """
  @spec demo() :: {integer(), integer(), map()}
  def demo do
    {:ok, a} = start_link(10)
    increment(a, 5)
    increment(a)
    v1 = current(a)
    v2 = add_and_get(a, 2)
    stop(a)

    {:ok, r} = start_registry()
    reg_put(r, :b, 2)
    reg_put(r, :a, 1)
    sorted = reg_sorted(r)
    stop(r)

    {v1, v2, Map.new(sorted)}
  end

  # 轮询等待 :permanent Agent 被监督者重拉成功。
  @spec wait_restart(atom()) :: integer()
  defp wait_restart(name, attempts \\ 100) do
    case safe_get(name) do
      n when is_integer(n) ->
        n

      _ when attempts > 0 ->
        Process.sleep(10)
        wait_restart(name, attempts - 1)
    end
  end

  # 死掉/重启空窗期的 get 会让调用方 exit：catch 成 nil，不杀 wait_restart 调用者。
  @spec safe_get(atom()) :: integer() | nil
  defp safe_get(name) do
    Agent.get(name, fn n when is_integer(n) -> n end)
  catch
    :exit, _ -> nil
  end

  @spec normalize_reason(term()) :: term()
  defp normalize_reason({:noproc, _}), do: {:exit, :noproc}

  defp normalize_reason({exception, stacktrace})
       when is_exception(exception) and is_list(stacktrace) do
    {:exc, exception.__struct__, Exception.message(exception)}
  end

  defp normalize_reason(other), do: other
end
