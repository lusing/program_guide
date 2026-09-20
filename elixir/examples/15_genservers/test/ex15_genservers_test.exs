defmodule Ex15GenserversTest do
  use ExUnit.Case, async: true

  doctest Ex15Genservers

  alias Ex15Genservers.KeyStore

  describe "两段式 API：call / cast" do
    test "put/get 的同步往返" do
      {:ok, s} = KeyStore.start_link()
      assert KeyStore.get(s, :k) == nil
      assert KeyStore.put(s, :k, "v") == :ok
      assert KeyStore.get(s, :k) == "v"
      KeyStore.stop(s)
    end

    test "initial 选项注入初始状态" do
      {:ok, s} = KeyStore.start_link(initial: %{a: 1})
      assert KeyStore.get(s, :a) == 1
      KeyStore.stop(s)
    end

    test "cast 异步写，同发送方紧接的 call 必然可见" do
      {:ok, s} = KeyStore.start_link()
      KeyStore.put_cast(s, :a, 1)
      assert KeyStore.get(s, :a) == 1
      KeyStore.stop(s)
    end

    test "snapshot 排序输出" do
      {:ok, s} = KeyStore.start_link()
      KeyStore.put(s, :z, 1)
      KeyStore.put(s, :a, 2)
      assert KeyStore.snapshot(s) == [a: 2, z: 1]
      KeyStore.stop(s)
    end
  end

  describe "handle_info：普通消息" do
    test "send :bump 走 info 通道，stats 可见" do
      {:ok, s} = KeyStore.start_link()
      assert KeyStore.bump(s) == :bumped
      assert KeyStore.bump(s) == :bumped
      assert KeyStore.stats(s) == {2, 0}
      KeyStore.stop(s)
    end

    test "不认识的普通消息被忽略，服务存活" do
      {:ok, s} = KeyStore.start_link()
      send(s, :something_unknown)
      Process.sleep(20)
      assert KeyStore.put(s, :k, 1) == :ok
      assert KeyStore.get(s, :k) == 1
      KeyStore.stop(s)
    end

    test "info_demo 汇总：3 次 bump + cast 写入" do
      assert Ex15Genservers.info_demo() == {3, [a: 1]}
    end
  end

  describe "命名注册" do
    test "name 选项注册后可按 atom 名访问" do
      name = :"ex15_named_#{:erlang.unique_integer([:positive])}"
      {:ok, pid} = KeyStore.start_link(name: name)
      assert Process.whereis(name) == pid
      assert KeyStore.put(name, :x, 9) == :ok
      assert KeyStore.get(name, :x) == 9
      KeyStore.stop(name)
    end
  end

  describe "空闲超时" do
    test "闲置 idle_ms 后清空并计数，再写入可重新上膛" do
      {:ok, s} = KeyStore.start_link(idle_ms: 30)
      KeyStore.put(s, :k, 1)
      assert KeyStore.get(s, :k) == 1
      Process.sleep(70)
      assert KeyStore.get(s, :k) == nil
      assert KeyStore.stats(s) == {0, 1}
      KeyStore.put(s, :k2, 2)
      Process.sleep(70)
      assert KeyStore.stats(s) == {0, 2}
      KeyStore.stop(s)
    end

    test "活动会重置空闲计时器" do
      {:ok, s} = KeyStore.start_link(idle_ms: 40)
      KeyStore.put(s, :k, 1)
      # 每 20ms 活动一次，始终早于 40ms 的闲置阈值
      Process.sleep(20)
      assert KeyStore.get(s, :k) == 1
      Process.sleep(20)
      assert KeyStore.get(s, :k) == 1
      Process.sleep(70)
      assert KeyStore.get(s, :k) == nil
      KeyStore.stop(s)
    end
  end

  describe "call 超时" do
    test "调用方超时退出，服务端存活且可继续服务" do
      assert Ex15Genservers.call_timeout_demo() ==
               {{:timeout, :call}, true, {:slept, 1}}
    end
  end
end
