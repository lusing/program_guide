# 21 · 测试 ExUnit

> 对应示例：`examples/21_testing/`（独立 mix 工程，含 ExUnit 测试、doctest 与 `run.exs` 驱动脚本）

前 20 章我们每个工程都带着测试，但关注点在实现。本章反过来审视测试本身：
ExUnit 是 Elixir 自带的单元测试框架——`mix test` 即跑全部，测试就是**普通
BEAML 进程**：每个用例一个独立进程，失败只是这个进程崩了，互不干扰。
这也决定了它的断言风格：**断言就是模式匹配**，失败报告是进程崩溃报告。

测试文件放在工程的 `test/` 目录，文件名以 `_test.exs` 结尾（`.exs` 是脚本，
不进生产编译产物）。骨架三件套：

```elixir
# test/test_helper.exs —— mix test 启动时最先执行
:io.setopts(:standard_io, encoding: :utf8)
ExUnit.start()

# test/xxx_test.exs
defmodule MyTest do
  use ExUnit.Case, async: true     # 模块级并发：本模块与其他 async 模块并行
  # setup、test ...
end
```

## 21.1 组织用例：describe / setup / context

`describe` 给同主题用例分组；`setup` 在**每个用例前**运行，返回的 map
合并进用例的 context，用例函数用 `%{cart: cart}` 模式取出：

```elixir
describe "Cart（setup 注入上下文）" do
  setup do
    cart = Cart.new() |> Cart.add_item("苹果", 2, 300)
    %{cart: cart}                    # 唯一返回值即 context；也可返回 {:ok, context}
  end

  test "总价是整数分", %{cart: cart} do
    assert Cart.total(cart) == 600
  end
end
```

本章被测的 `Cart` 是纯函数式结构：每个操作返回新 cart，没有进程、没有
共享状态——**最容易测的形态**。setup 造一份，用例随便改，互不影响：

```text
-- 1. Cart 纯数据变换：setup 返回的上下文就是这种值 --
  items => [{"苹果", 2, 300}]
  total => 600
  合并后 => [{"苹果", 3, 300}]
```

要点：

- `setup` 每用例都跑一次；`setup_all` 整个模块只跑一次（状态被同模块用例
  共享，仅用于可复用的外部资源）。
- `:async` 是**模块级**选项，写在 `use ExUnit.Case` 上——`describe` 不接受
  它；需要部分同步就把那组用例放进单独的 `async: false` 模块（见 21.9 第 7 坑）。
- 清理用 `on_exit/1` 注册回调，即便用例中途崩了也会执行。

## 21.2 断言：assert 即匹配，异常与浮点有专用断言

最常用的一条心法：**在 `assert` 左侧做模式绑定**。

```elixir
assert {:ok, summary} = Order.place(cart, notifier)
```

右侧先执行，左侧不是简单相等而是模式——失败时报告同时打印两边。常见断言
清单：

| 断言 | 用途 |
|---|---|
| `assert x == y` / `refute x == y` | 普通相等 |
| `assert pattern = expr` | 模式绑定断言（最常用） |
| `assert_raise Mod, "消息", fun` | 断言抛异常及消息 |
| `assert_in_delta a, b, delta` | 浮点近似（`==` 对 float 不可靠） |
| `assert match?(pattern, expr)` | 只断言「能匹配」，不绑定 |
| `assert x =~ "子串"` / `assert x =~ ~r/正则/` | 字符串包含/正则 |

`Order` 刻意提供两种错误风格，正好对照普通断言与异常断言：

```elixir
assert Order.place(Cart.new(), notifier) == {:error, :empty}

assert_raise Ex21Testing.EmptyCartError, "购物车为空，无法下单", fn ->
  Order.place!(Cart.new(), notifier)
end
```

```text
-- 2. 空车：tuple 与异常两种表达（测试分别用 == 与 assert_raise） --
  place 空车 => {:error, :empty}
  place! 抛出 => 购物车为空，无法下单
```

## 21.3 doctest：文档即测试

第 2 章起就在用的 `doctest`，机制值得点明：写在 `@doc` 里的每个
`iex>` 代码块都会被抽出执行，**期望输出必须与 `inspect/1` 逐字符一致**
（`{1, 2}` 的空格、map 的键序都算）。一个模块一条 `doctest 模块名`：

```elixir
doctest Ex21Testing.Math
doctest Ex21Testing.Cart
```

```text
-- 3. 这些函数的 @doc 里嵌着 iex>，doctest 会逐条执行 --
  halve(10) => 5.0
  sqrt(2) => 1.4142135623730951
  clamp => 10
```

doctest 守的是「文档里写的示例真的成立」——文档过时、签名改了，测试立刻
红。代价是**只适合自包含的纯函数**：打印、读文件、依赖当前时间的示例不要
放进 doctest（第 19 章文件类 doctest 用「先绑定、再清理、最后断言」的
特殊写法，能不写就不写）。两个老坑复习：正则写进 `@doc` 要双反斜杠
（见 17 章）；map 打印顺序以实测为准。

## 21.4 capture_io：把标准输出捞成字符串

函数往 stdout 打印东西怎么测？`ExUnit.CaptureIO.capture_io/1` 临时接管
group leader，把块内所有输出收集成一个字符串返回：

```elixir
output =
  capture_io(fn ->
    Order.print_receipt(cart)
  end)

lines = String.split(output, "\n", trim: true)
assert lines == ["桃 x2 = 200", "合计 200"]
```

注意 `capture_io` **不在 `use ExUnit.Case` 的自动导入里**，必须
`import ExUnit.CaptureIO`（`capture_log` 同理）。

```text
-- 4. 下面三行是 print_receipt 的真实输出；测试用 capture_io 捞成字符串 --
桃 x2 = 200
合计 200
```

## 21.5 capture_log：把日志捞成字符串

日志同理：`ExUnit.CaptureLog.capture_log/1` 临时挂上日志处理器，返回块内
产生的日志全文，还会自动把日志级别临时调到 `:debug`：

```elixir
log =
  capture_log(fn ->
    assert {:ok, _} = Order.place(cart, Ex21Testing.ConsoleNotifier)
  end)

assert log =~ "订单已通知"
assert log =~ "total=200"
```

两个实现层面的细节：

- `Logger.info/1` 是**宏**，调用处必须 `require Logger`——普通函数模块里
  直接写会编译告警「there is a macro with the same name」。
- Elixir 1.20 默认日志句柄已走 standard_io，但模板默认带时间戳。要在
  驱动脚本里产出可比对的日志，直接改 Erlang `:logger` 的模板：

```elixir
:logger.update_formatter_config(:default, :template, [
  "[", :level, "] ", :message, "\n"
])
```

日志默认**异步投递**——不 flush，行序可能飘到下一节；脚本里发完关键日志
调用 `Logger.flush()` 强制处理完再继续：

```text
-- 5. 下一行是 Logger 输出；测试用 capture_log 捞取并断言子串 --
[info] 订单已通知 total=200
```

（`Logger.configure_backend/2` 在 1.20 已弃用，替代品在外部包
`:logger_backends` 里；零依赖直接用底层 `:logger` 即可。）

## 21.6 进程消息：assert_receive / refute_receive

Elixir 程序的异步边界是消息，ExUnit 对消息的断言是 `assert_receive`：

```elixir
Ticker.start(2)
assert_receive {:tick, 1}, 100     # 第二参数是超时毫秒，默认 100
assert_receive {:tick, 2}, 100
refute_receive {:tick, 3}, 50      # refute 等满超时确认「不会来」
```

`Ticker` 派生进程后**立即**把消息发完、不 sleep：

```elixir
def start(count) do
  parent = self()

  spawn(fn ->
    Enum.each(1..count, fn i -> send(parent, {:tick, i}) end)
  end)
end
```

```text
-- 6. Ticker 发编号消息；测试用 assert_receive/refute_receive --
  收到编号 => [1, 2]
```

对比两种错误写法：**用 `Process.sleep` 等一段时间再查邮箱**——机器一忙就
超时，是典型的脆弱测试。正确方向是让断言等消息（receive 本来就是阻塞的），
被测代码则别做无谓延迟。只断言「最终会收到」，不卡具体调度时刻。

## 21.7 不 mock：依赖注入 + 手写小替身

Elixir 社区的著名主张是 **「不要 mock」**（没有 Mock 模块、没有打桩库）。
原因和替代方案都来自语言特性：

1. **依赖作为参数注入**。`Order.place(cart, notifier)` 的通知器是参数，
   调用生产代码传 `ConsoleNotifier`，测试传别的——不需要替换任何全局东西。
2. **替身是手写的普通模块**。测试里定义一个实现同一 `@behaviour` 的小模块，
   把「被调用过、参数是什么」变成消息留证：

```elixir
defmodule MessageNotifier do
  @behaviour Ex21Testing.Notifier

  @impl true
  def deliver(summary) do
    send(self(), {:notified, summary})   # place 同步执行，self() 即测试进程
    :ok                                   # send 返回消息本身，契约要求 :ok！
  end
end

assert {:ok, summary} = Order.place(cart, MessageNotifier)
assert_received {:notified, ^summary}      # 已在邮箱里的消息用 assert_received
```

```text
-- 7. 替身是手写的小模块，不替换全局库；place 同步调用 --
  替身收到 => %{lines: 1, total_cents: 500}
```

`@behaviour` 只在编译期检查「该实现的回调都实现了」，是轻契约。需要记录
调用序列时用 `start_supervised!` 起一个 Agent；涉及时间的代码把「时钟」
作为函数参数传入——**任何「假装」都发生在参数层，不碰全局状态**，并发
测试因此天然安全。

顺带一提**标签（tag）**：用例上可打 `@tag :smoke`，然后命令行选择执行：
`mix test --only smoke`、`mix test --exclude slow`。标签也进 context，
setup 可据此改变行为。

## 21.8 要点小结

```text
  测试就是进程：每用例独立进程，断言即模式匹配，失败即崩溃报告
  describe 分组、setup 每例造上下文；setup_all 仅给可复用资源，on_exit 清理
  assert 左绑定；异常 assert_raise；浮点 assert_in_delta；字符串 =~
  doctest 守文档示例，只放自包含纯函数，输出与 inspect 逐字符一致
  capture_io / capture_log 需显式 import；日志是宏要 require Logger
  消息断言 assert_receive，不 sleep 卡时序
  不 mock：依赖走参数，手写替身；async 是模块级，共享状态单独放同步模块
```

## 21.9 坑位清单

1. **`capture_io` / `capture_log` 未定义**：它们不随 `use ExUnit.Case`
   导入，文件头要 `import ExUnit.CaptureIO` / `import ExUnit.CaptureLog`。
2. **替身回调忘了返回 `:ok`**：`send/2` 返回的是消息本身，而行为契约常要求
   `:ok`——`send(...)` 后必须显式 `:ok` 收尾，否则调用方的 `:ok = ...`
   MatchError。
3. **`Logger.info` 编译告警**：Logger 各级函数是宏，调用模块必须先
   `require Logger`。
4. **日志默认带时间戳且异步投递**。可复现的脚本用
   `:logger.update_formatter_config` 改固定模板，发完 `Logger.flush()`；
   `Logger.configure_backend` 在 1.20 已弃用（替代品是外部包）。
5. **`describe` 不支持 `async:` 选项**——并发度是模块级的。部分用例要同步
   就拆成第二个 `use ExUnit.Case, async: false` 模块。
6. **`setup_all` 的状态跨用例共享**，只适合 Agent/外部连接这类「可复用
   资源」；往里放可变业务数据会制造用例顺序依赖——**ExUnit 的用例顺序是
   随机的**（seed 打印在输出第一行，每次运行都变），断言「上一个用例已
   写入」的测试必 flaky。断言只写自己的效果，让两种顺序都成立。
7. **别用 `Process.sleep` 等异步结果**——忙时必 flaky。消息驱动的代码用
   `assert_receive`（阻塞等待 + 超时），被测方立即发消息。
8. **doctest 期望照 `inspect` 逐字符写**：空格、map 键序、sigil 外观
   （如零精度 DateTime 不打 `.000`）都要实测；正则在 `@doc` 里双反斜杠。
9. **doctest 不收纳副作用**。打印、文件、时钟类示例要么改写，要么用
   「绑定→清理→断言」的别扭写法；这类逻辑更适合普通用例。
10. **别为测试改全局配置/打桩全局模块**——async 并发下互相污染。依赖注入
    到参数层（模块、函数、pid），替身只活在用例里；时钟、随机源同理
    （生产代码接受它们作参数，测试传固定实现）。

---

下一章离开语言语义，看看工程化工具链：[22 · Mix 与 release](22-mix-release.md)
——依赖与环境、umbrella 伞形工程、`mix release` 打包自包含发布、
`runtime.exs` 运行时配置、自定义 Mix 任务与 escript。
