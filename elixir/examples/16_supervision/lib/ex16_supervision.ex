defmodule Ex16Supervision.BootLog do
  @moduledoc false

  # 记录每个 worker 启动事件的收集器：监督树里的 worker 在 init 里给它发
  # {:boot, tag}，run.exs/测试再按阶段读取事件顺序。
  use GenServer

  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, nil, opts)
  end

  @impl true
  def init(_), do: {:ok, []}

  @impl true
  def handle_call(:events, _from, events) do
    {:reply, events, events}
  end

  def handle_call(:reset, _from, _events) do
    {:reply, :ok, []}
  end

  def handle_call({:wait, n}, from, events) do
    if length(events) >= n do
      {:reply, events, events}
    else
      {:noreply, {:waiting, from, n, events}}
    end
  end

  @impl true
  def handle_info({:boot, tag}, events) when is_list(events) do
    {:noreply, events ++ [{:boot, tag}]}
  end

  def handle_info({:boot, tag}, {:waiting, from, n, events}) do
    events = events ++ [{:boot, tag}]

    if length(events) >= n do
      GenServer.reply(from, events)
      {:noreply, []}
    else
      {:noreply, {:waiting, from, n, events}}
    end
  end

  def handle_info(_other, state) do
    {:noreply, state}
  end
end

defmodule Ex16Supervision.Worker do
  @moduledoc """
  演示监督树叶子：每次 init 向收集器报告 {:boot, tag}；
  可被外部以任意 reason 停止以制造崩溃。
  """

  use GenServer

  defstruct tag: :w, sub: nil

  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts, name: opts[:name])
  end

  @impl true
  def init(opts) do
    if opts[:sub], do: send(opts[:sub], {:boot, opts[:tag]})
    {:ok, %__MODULE__{tag: opts[:tag], sub: opts[:sub]}}
  end

  def ping(server), do: GenServer.call(server, :ping)

  @impl true
  def handle_call(:ping, _from, state) do
    {:reply, {:pong, state.tag}, state}
  end

  @doc "以指定原因停止：:normal 算正常退出，:boom 之类算异常。"
  def die(server, reason \\ :boom) do
    GenServer.stop(server, reason)
  end
end

defmodule Ex16Supervision do
  @moduledoc """
  第 16 章示例：Supervisor 与 Application。

  全部演示函数都在内部起停监督树、不打印 pid，只返回确定性的
  启动事件标签与计数。worker 每次被监督者启动（包括重启）都会给
  BootLog 收集器发一条 `{:boot, tag}`，因此「谁在何时被重启」可以
  像读日志一样读出来。
  """

  alias Ex16Supervision.{Application, BootLog, Worker}

  # ------------------------------------------------------------
  # child_spec
  # ------------------------------------------------------------

  @doc """
  `use GenServer` 自动生成的 child_spec：现代 Elixir 里它**只有** `:id`
  与 `:start` 两个键——restart :permanent、type :worker、shutdown 5000
  等默认值由监督者在真正启动子进程时补入，不出现在 spec map 里。

      iex> Ex16Supervision.child_spec_summary()
      %{id: Ex16Supervision.Worker,
        start: {Ex16Supervision.Worker, :start_link, [[tag: :ignored]]}}

  """
  @spec child_spec_summary() :: %{id: module(), start: {module(), atom(), [term()]}}
  def child_spec_summary do
    Worker.child_spec(tag: :ignored)
  end

  @doc """
  用 `Supervisor.child_spec/2` 覆盖默认 spec 的 id 与 restart。

      iex> Ex16Supervision.override_spec()
      %{id: :custom_id, restart: :temporary}

  """
  @spec override_spec() :: %{id: atom(), restart: atom()}
  def override_spec do
    Worker
    |> Supervisor.child_spec(id: :custom_id, restart: :temporary)
    |> Map.take([:id, :restart])
  end

  # ------------------------------------------------------------
  # 三种监督策略
  # ------------------------------------------------------------

  @doc """
  one_for_one：崩谁重启谁，其他子进程不动。
  返回 `{初始启动顺序, 撞崩 w1 后的新启动事件}`。

      iex> Ex16Supervision.one_for_one_demo()
      {[:w1, :w2], [:w1]}

  """
  @spec one_for_one_demo() :: {[atom()], [atom()]}
  def one_for_one_demo do
    {:ok, log, sup, unique} = start_tree([:w1, :w2], :one_for_one)
    initial = wait_tags(log, 2)
    :ok = GenServer.call(log, :reset)

    Worker.die(worker_name(unique, :w1), :boom)
    restarted = wait_tags(log, 1)

    teardown(sup, log)
    {initial, restarted}
  end

  @doc """
  one_for_all：一个崩，整组子进程全部停掉并按 spec 顺序重启。

      iex> Ex16Supervision.one_for_all_demo()
      {[:w1, :w2, :w3], [:w1, :w2, :w3]}

  """
  @spec one_for_all_demo() :: {[atom()], [atom()]}
  def one_for_all_demo do
    {:ok, log, sup, unique} = start_tree([:w1, :w2, :w3], :one_for_all)
    initial = wait_tags(log, 3)
    :ok = GenServer.call(log, :reset)

    Worker.die(worker_name(unique, :w2), :boom)
    restarted = wait_tags(log, 3)

    teardown(sup, log)
    {initial, restarted}
  end

  @doc """
  rest_for_one：崩的是第 k 个，则它和它**之后**的全部重启，它之前的不动。
  返回撞 w2 与撞 w1 两次的新事件。

      iex> Ex16Supervision.rest_for_one_demo()
      {[:w2, :w3], [:w1, :w2, :w3]}

  """
  @spec rest_for_one_demo() :: {[atom()], [atom()]}
  def rest_for_one_demo do
    {:ok, log, sup, unique} = start_tree([:w1, :w2, :w3], :rest_for_one)
    _initial = wait_tags(log, 3)
    :ok = GenServer.call(log, :reset)

    Worker.die(worker_name(unique, :w2), :boom)
    after_w2 = wait_tags(log, 2)
    :ok = GenServer.call(log, :reset)

    Worker.die(worker_name(unique, :w1), :boom)
    after_w1 = wait_tags(log, 3)

    teardown(sup, log)
    {after_w2, after_w1}
  end

  @doc """
  重启强度：max_restarts 次/max_seconds 秒内重启超限，监督者**自己**以
  :shutdown 退出（本函数在独立 runner 里 trap_exit 观察，不影响调用方）。
  返回 `{监督者死前看到的启动事件总数, 监督者死因}`。

      iex> Ex16Supervision.intensity_demo()
      {3, :shutdown}

  """
  @spec intensity_demo() :: {non_neg_integer(), atom()}
  def intensity_demo do
    parent = self()
    ref_me = make_ref()

    runner =
      spawn(fn ->
        Process.flag(:trap_exit, true)
        {:ok, log} = BootLog.start_link()
        unique = :erlang.unique_integer([:positive])
        name = worker_name(unique, :w1)

        spec = %{
          id: :only,
          start: {Worker, :start_link, [[name: name, tag: :w1, sub: log]]},
          restart: :permanent
        }

        {:ok, sup} =
          Supervisor.start_link([spec],
            strategy: :one_for_one,
            max_restarts: 2,
            max_seconds: 5
          )

        mon = Process.monitor(sup)
        _ = wait_tags(log, 1)

        # 前两次：撞崩 → 等同名 worker 被拉起；第三次：超限，监督者自杀。
        Worker.die(name, :boom)
        wait_up(name)
        Worker.die(name, :boom)
        wait_up(name)
        Worker.die(name, :boom)

        reason =
          receive do
            {:DOWN, ^mon, :process, ^sup, r} -> r
          after
            1_000 -> :no_down
          end

        boots = length(GenServer.call(log, :events))
        send(parent, {ref_me, boots, reason})
      end)

    receive do
      {^ref_me, boots, reason} ->
        wait_exit(runner)
        {boots, normalize_reason(reason)}
    after
      3_000 -> :timeout
    end
  end

  @doc """
  三种 restart 策略的实测行为：
  temporary 崩了不重启；transient 正常退出不重启、异常退出重启；permanent 总是重启。

      iex> Ex16Supervision.restart_policies_demo()
      %{permanent_abnormal: :restarted, temporary_abnormal: :not_restarted,
        transient_abnormal: :restarted, transient_normal: :not_restarted}

  """
  @spec restart_policies_demo() :: %{
          permanent_abnormal: atom(),
          temporary_abnormal: atom(),
          transient_abnormal: atom(),
          transient_normal: atom()
        }
  def restart_policies_demo do
    %{
      transient_normal: observe_restart(:transient, :normal),
      transient_abnormal: observe_restart(:transient, :boom),
      temporary_abnormal: observe_restart(:temporary, :boom),
      permanent_abnormal: observe_restart(:permanent, :boom)
    }
  end

  # ------------------------------------------------------------
  # Application 回调
  # ------------------------------------------------------------

  @doc """
  应用回调模块 `Ex16Supervision.Application` 声明的监督树：
  返回 children 数量与策略标签。真实 release 里由 VM 在启动应用时调用；
  这里手动调用一次 `start/2` 验证树的内容。

      iex> Ex16Supervision.application_tree_demo()
      %{active: 3, strategy: :one_for_one}

  """
  @spec application_tree_demo() :: %{active: non_neg_integer(), strategy: atom()}
  def application_tree_demo do
    prefix = :erlang.unique_integer([:positive])
    {:ok, sup} = Application.start(:normal, prefix)

    result =
      sup
      |> Supervisor.count_children()
      |> Map.take([:active])
      |> Map.put(:strategy, Application.strategy())

    Supervisor.stop(sup)
    result
  end

  # ============================================================
  # 内部工具
  # ============================================================

  defp start_tree(tags, strategy) do
    {:ok, log} = BootLog.start_link()
    unique = :erlang.unique_integer([:positive])

    children =
      Enum.map(tags, fn tag ->
        %{
          id: tag,
          start: {Worker, :start_link, [[name: worker_name(unique, tag), tag: tag, sub: log]]},
          restart: :permanent
        }
      end)

    {:ok, sup} = Supervisor.start_link(children, strategy: strategy)
    {:ok, log, sup, unique}
  end

  defp worker_name(unique, tag), do: :"ex16_worker_#{unique}_#{tag}"

  defp observe_restart(policy, reason) do
    {:ok, log} = BootLog.start_link()
    unique = :erlang.unique_integer([:positive])
    tag = :"w_#{policy}_#{reason}"
    name = worker_name(unique, tag)

    spec = %{
      id: tag,
      start: {Worker, :start_link, [[name: name, tag: tag, sub: log]]},
      restart: policy
    }

    {:ok, sup} = Supervisor.start_link([spec], strategy: :one_for_one)
    _ = wait_tags(log, 1)
    :ok = GenServer.call(log, :reset)

    Worker.die(name, reason)
    restarted? = wait_new_boot(log, 100)

    teardown(sup, log)
    if restarted?, do: :restarted, else: :not_restarted
  end

  # 等到 n 条启动事件（阻塞式），返回 tag 列表。
  defp wait_tags(log, n) do
    log
    |> GenServer.call({:wait, n}, 1_000)
    |> Enum.map(fn {:boot, tag} -> tag end)
  end

  # 轮询等待新启动事件（非阻塞式，用于不确定是否会重启的场景）。
  defp wait_new_boot(log, attempts) do
    cond do
      length(GenServer.call(log, :events)) > 0 ->
        true

      attempts == 0 ->
        false

      true ->
        Process.sleep(10)
        wait_new_boot(log, attempts - 1)
    end
  end

  defp wait_up(name, attempts \\ 100) do
    cond do
      Process.whereis(name) != nil ->
        :ok

      attempts == 0 ->
        :timeout

      true ->
        Process.sleep(10)
        wait_up(name, attempts - 1)
    end
  end

  defp teardown(sup, log) do
    Supervisor.stop(sup)
    if Process.alive?(log), do: GenServer.stop(log)
  end

  defp wait_exit(pid) do
    ref = Process.monitor(pid)

    receive do
      {:DOWN, ^ref, :process, ^pid, _} -> :ok
    after
      1_000 -> :ok
    end
  end

  defp normalize_reason(:shutdown), do: :shutdown
  defp normalize_reason(other), do: other
end

defmodule Ex16Supervision.Application do
  @moduledoc "应用回调：声明整棵监督树的 children 与启动入口。"

  use Application

  # 注意：alias 不跨模块继承，这里必须再次别名（或写全限定名）。
  alias Ex16Supervision.{BootLog, Worker}

  @impl true
  def start(_type, prefix) do
    log_name = :"ex16_boot_log_#{prefix}"

    children = [
      {BootLog, name: log_name},
      %{
        id: :cache,
        start:
          {Worker, :start_link, [[name: :"ex16_cache_#{prefix}", tag: :cache, sub: log_name]]}
      },
      %{
        id: :worker_a,
        start:
          {Worker, :start_link,
           [[name: :"ex16_worker_a_#{prefix}", tag: :worker_a, sub: log_name]]}
      }
    ]

    opts = [strategy: strategy(), name: :"ex16_sup_#{prefix}"]
    Supervisor.start_link(children, opts)
  end

  def strategy, do: :one_for_one
end
