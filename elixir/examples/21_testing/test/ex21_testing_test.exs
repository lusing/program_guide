defmodule Ex21TestingTest do
  use ExUnit.Case, async: true

  # capture_* 不由 use ExUnit.Case 自动导入，必须显式 import。
  import ExUnit.CaptureIO
  import ExUnit.CaptureLog

  doctest Ex21Testing.Math
  doctest Ex21Testing.Cart

  alias Ex21Testing.{Cart, Math, Order, Ticker}

  # 手写的测试替身（不是 mock！）：place 同步执行，回调里的 self() 就是测试进程，
  # 把「被调用过、收到什么参数」变成一条可断言的消息。
  defmodule MessageNotifier do
    @behaviour Ex21Testing.Notifier

    @impl true
    def deliver(summary) do
      # send 返回的是消息本身；行为契约要求 :ok，必须显式收尾。
      send(self(), {:notified, summary})
      :ok
    end
  end

  describe "Cart（setup 注入上下文）" do
    setup do
      cart = Cart.new() |> Cart.add_item("苹果", 2, 300)
      %{cart: cart}
    end

    test "总价是整数分", %{cart: cart} do
      assert Cart.total(cart) == 600
    end

    test "同名商品合并数量，不产生新行", %{cart: cart} do
      assert Cart.add_item(cart, "苹果", 1, 300).items == [{"苹果", 3, 300}]
    end

    test "空车总价为 0" do
      assert Cart.total(Cart.new()) == 0
    end
  end

  describe "Order：两种错误风格" do
    setup do
      cart = Cart.new() |> Cart.add_item("梨", 1, 500)
      %{cart: cart}
    end

    test "空车返回 tagged tuple，且通知器不被调用", %{cart: _cart} do
      assert Order.place(Cart.new(), MessageNotifier) == {:error, :empty}
      refute_receive {:notified, _}, 50
    end

    test "成功时通知器收到同一份 summary", %{cart: cart} do
      assert {:ok, summary} = Order.place(cart, MessageNotifier)
      assert summary == %{total_cents: 500, lines: 1}
      assert_received {:notified, ^summary}
    end

    test "place! 对空车抛自定义异常" do
      assert_raise Ex21Testing.EmptyCartError, "购物车为空，无法下单", fn ->
        Order.place!(Cart.new(), MessageNotifier)
      end
    end

    @tag :smoke
    test "place! 成功返回裸 summary", %{cart: cart} do
      assert Order.place!(cart, MessageNotifier) == %{total_cents: 500, lines: 1}
    end
  end

  describe "Math：浮点与守卫" do
    test "halve 永远返回 float" do
      assert Math.halve(10) == 5.0
    end

    test "平方根用 assert_in_delta 容忍浮点误差" do
      assert_in_delta Math.sqrt(2), 1.4142, 0.0001
    end

    test "clamp 两个边界" do
      assert Math.clamp(15, 0, 10) == 10
      assert Math.clamp(-3, 0, 10) == 0
      assert Math.clamp(5, 0, 10) == 5
    end
  end

  describe "副作用捕获" do
    setup do
      cart = Cart.new() |> Cart.add_item("桃", 2, 100)
      %{cart: cart}
    end

    test "capture_io 捕获收据输出", %{cart: cart} do
      output = capture_io(fn -> Order.print_receipt(cart) end)
      lines = String.split(output, "\n", trim: true)
      assert lines == ["桃 x2 = 200", "合计 200"]
    end

    test "capture_log 捕获日志内容", %{cart: cart} do
      log =
        capture_log(fn ->
          assert {:ok, _} = Order.place(cart, Ex21Testing.ConsoleNotifier)
        end)

      assert log =~ "订单已通知"
      assert log =~ "total=200"
    end
  end

  describe "消息断言" do
    test "Ticker 按编号发消息" do
      Ticker.start(2)
      assert_receive {:tick, 1}, 100
      assert_receive {:tick, 2}, 100
      refute_receive {:tick, 3}, 50
    end
  end
end

# 共享状态必须 async: false；:async 是模块级选项，describe 不接受它，
# 所以演示 setup_all + on_exit 的用例单独放一个同步模块。
defmodule Ex21TestingSharedTest do
  use ExUnit.Case, async: false

  setup_all do
    {:ok, agent} = Agent.start_link(fn -> [] end)
    on_exit(fn -> Agent.stop(agent) end)
    %{agent: agent}
  end

  test "追加标签 a", %{agent: agent} do
    assert Agent.get_and_update(agent, fn acc -> {:ok, [:a | acc]} end) == :ok
  end

  test "追加标签 b 并读到累积内容", %{agent: agent} do
    state = Agent.get_and_update(agent, fn acc -> {[:b | acc], [:b | acc]} end)
    assert :a in state and :b in state
  end
end
