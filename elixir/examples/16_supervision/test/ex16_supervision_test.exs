defmodule Ex16SupervisionTest do
  use ExUnit.Case, async: true

  doctest Ex16Supervision

  alias Ex16Supervision

  describe "child_spec" do
    test "use GenServer 生成的默认 spec 只有 id/start" do
      assert Ex16Supervision.child_spec_summary() == %{
               id: Ex16Supervision.Worker,
               start: {Ex16Supervision.Worker, :start_link, [[tag: :ignored]]}
             }
    end

    test "Supervisor.child_spec/2 覆盖 id 与 restart" do
      assert Ex16Supervision.override_spec() == %{id: :custom_id, restart: :temporary}
    end
  end

  describe "监督策略" do
    test "one_for_one 只重启崩掉的那个" do
      assert Ex16Supervision.one_for_one_demo() == {[:w1, :w2], [:w1]}
    end

    test "one_for_all 整组按 spec 顺序重启" do
      assert Ex16Supervision.one_for_all_demo() ==
               {[:w1, :w2, :w3], [:w1, :w2, :w3]}
    end

    test "rest_for_one 重启崩点及其之后" do
      assert Ex16Supervision.rest_for_one_demo() ==
               {[:w2, :w3], [:w1, :w2, :w3]}
    end
  end

  describe "重启强度" do
    test "超过 max_restarts/max_seconds 监督者以 :shutdown 自杀" do
      assert Ex16Supervision.intensity_demo() == {3, :shutdown}
    end
  end

  describe "restart 策略" do
    test "temporary 永不重启；transient 只在异常时重启；permanent 总重启" do
      assert Ex16Supervision.restart_policies_demo() == %{
               transient_normal: :not_restarted,
               transient_abnormal: :restarted,
               temporary_abnormal: :not_restarted,
               permanent_abnormal: :restarted
             }
    end
  end

  describe "Application 回调" do
    test "start/2 拉起声明的整棵树" do
      assert Ex16Supervision.application_tree_demo() ==
               %{active: 3, strategy: :one_for_one}
    end
  end

  describe "Worker 叶子" do
    test "ping 带 tag；崩后由监督者同名拉起仍可服务" do
      {:ok, log, sup, unique} = __test_start_tree__([:a], :one_for_one)

      name = :"ex16_worker_#{unique}_a"
      assert Ex16Supervision.Worker.ping(name) == {:pong, :a}
      Ex16Supervision.Worker.die(name, :boom)
      # 重启后同名注册、状态从头开始，但服务可用
      wait_up(name)
      assert Ex16Supervision.Worker.ping(name) == {:pong, :a}

      Supervisor.stop(sup)
      stop(log)
    end
  end

  # 测试专用：复用库内部的树构造（通过公开 demo 间接覆盖不到的 ping 路径）。
  def __test_start_tree__(tags, strategy) do
    {:ok, log} = Ex16Supervision.BootLog.start_link()
    unique = :erlang.unique_integer([:positive])

    children =
      Enum.map(tags, fn tag ->
        name = :"ex16_worker_#{unique}_#{tag}"

        %{
          id: tag,
          start: {Ex16Supervision.Worker, :start_link, [[name: name, tag: tag, sub: log]]},
          restart: :permanent
        }
      end)

    {:ok, sup} = Supervisor.start_link(children, strategy: strategy)
    {:ok, log, sup, unique}
  end

  defp stop(pid) do
    if Process.alive?(pid), do: GenServer.stop(pid)
  end

  defp wait_up(name, attempts \\ 100) do
    cond do
      Process.whereis(name) != nil ->
        :ok

      attempts == 0 ->
        flunk("worker 未在监督下重启")

      true ->
        Process.sleep(10)
        wait_up(name, attempts - 1)
    end
  end
end
