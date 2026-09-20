# 第 21 章驱动脚本：cd examples/21_testing && mix run --no-compile run.exs
:io.setopts(:standard_io, encoding: :utf8)

# 1.20 默认日志句柄已走 standard_io；只需把模板钉死为不含时间戳的固定格式
# （Logger 宏需 require，见 ConsoleNotifier）。
:logger.update_formatter_config(:default, :template, [
  "[",
  :level,
  "] ",
  :message,
  "\n"
])

alias Ex21Testing.{Cart, ConsoleNotifier, Math, Order, Ticker}

IO.puts("==== 21 测试 ExUnit：组织、断言、doctest、capture_io/log、消息断言、不 mock ====")

# ------------------------------------------------------------
# 1. 被测对象一：纯函数式购物车（测试用 describe + setup 注入它）
# ------------------------------------------------------------
IO.puts("\n-- 1. Cart 纯数据变换：setup 返回的上下文就是这种值 --")

cart = Cart.new() |> Cart.add_item("苹果", 2, 300)
IO.puts("  items => #{inspect(cart.items)}")
IO.puts("  total => #{Cart.total(cart)}")
IO.puts("  合并后 => #{inspect(Cart.add_item(cart, "苹果", 1, 300).items)}")

# ------------------------------------------------------------
# 2. 两种错误风格：tagged tuple 与异常（对应 assert/assert_raise）
# ------------------------------------------------------------
IO.puts("\n-- 2. 空车：tuple 与异常两种表达（测试分别用 == 与 assert_raise） --")
IO.puts("  place 空车 => #{inspect(Order.place(Cart.new(), ConsoleNotifier))}")

try do
  Order.place!(Cart.new(), ConsoleNotifier)
rescue
  e in Ex21Testing.EmptyCartError ->
    IO.puts("  place! 抛出 => #{Exception.message(e)}")
end

# ------------------------------------------------------------
# 3. doctest 的来源：文档里的 iex> 行即测试
# ------------------------------------------------------------
IO.puts("\n-- 3. 这些函数的 @doc 里嵌着 iex>，doctest 会逐条执行 --")
IO.puts("  halve(10) => #{Math.halve(10)}")
IO.puts("  sqrt(2) => #{Math.sqrt(2)}")
IO.puts("  clamp => #{Math.clamp(15, 0, 10)}")

# ------------------------------------------------------------
# 4. capture_io 的对象：直接打印收据
# ------------------------------------------------------------
IO.puts("\n-- 4. 下面三行是 print_receipt 的真实输出；测试用 capture_io 捞成字符串 --")
cart2 = Cart.new() |> Cart.add_item("桃", 2, 100)
Order.print_receipt(cart2)

# ------------------------------------------------------------
# 5. capture_log 的对象：日志（已改走 stdout、固定格式）
# ------------------------------------------------------------
IO.puts("-- 5. 下一行是 Logger 输出；测试用 capture_log 捞取并断言子串 --")
Order.place(cart2, ConsoleNotifier)
# 日志默认异步投递，不落盘不排序；flush 强制处理完再进下一节，否则
# 这行会飘到第 6 节中间，破坏逐字节比对。
Logger.flush()

# ------------------------------------------------------------
# 6. assert_receive 的对象：进程发来的消息
# ------------------------------------------------------------
IO.puts("\n-- 6. Ticker 发编号消息；测试用 assert_receive/refute_receive --")
Ticker.start(2)

ticks =
  Enum.map(1..2, fn _ ->
    receive do
      {:tick, i} -> i
    after
      1000 -> :timeout
    end
  end)

IO.puts("  收到编号 => #{inspect(ticks)}")

# ------------------------------------------------------------
# 7. 不 mock：行为 + 注入模块；替身只做「发消息留证」
# ------------------------------------------------------------
IO.puts("\n-- 7. 替身是手写的小模块，不替换全局库；place 同步调用 --")

defmodule ScriptNotifier do
  @behaviour Ex21Testing.Notifier

  @impl true
  def deliver(summary) do
    send(self(), {:notified, summary})
    :ok
  end
end

cart3 = Cart.new() |> Cart.add_item("梨", 1, 500)
{:ok, summary} = Order.place(cart3, ScriptNotifier)

receive do
  {:notified, ^summary} ->
    IO.puts("  替身收到 => #{inspect(summary)}")
after
  1000 ->
    IO.puts("  未收到通知")
end

IO.puts("""
-- ExUnit 要点 --
  describe 分组、setup 准备上下文；纯数据优先，副作用局部化
  assert 左侧可做模式绑定；异常用 assert_raise，浮点用 assert_in_delta
  doctest 把文档示例变成回归测试；输出必须与 inspect 逐字符一致
  stdout 用 capture_io，日志用 capture_log，进程消息用 assert_receive
  不 mock：依赖作为参数（模块/函数）注入，手写小替身留证
  不 sleep 等时序：消息立即发、断言等消息，避免脆弱测试
  async: true 跑纯进程内逻辑；碰共享状态显式 async: false
""")

IO.puts("==== 21 结束 ====")
