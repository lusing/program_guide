# 26 · 闭包与函数组合

> 对应示例：`examples/26_closures/`（独立 mix 工程，含 ExUnit 测试、doctest 与 `run.exs` 驱动脚本）
>
> 取材自《函数式编程入门：使用 Elixir》第 2 章 2.4 节的深挖。第 05 章已经用过 `fn` 和 `adder` 工厂；本章把「函数是值」推到底：闭包到底捕获了什么、词法作用域的边界在哪、`&` 捕获的全部形态、以及小函数如何组合成大函数。

## 26.1 函数作为参数：策略注入

书的第一个例子：总价 = 价格 + 费用，而**费用怎么算**本身是一个函数——

```elixir
def total_price(price, fee), do: price + fee.(price)

def fee(:flat), do: fn _price -> 5 end
def fee(:proportional), do: fn price -> price * 0.12 end
```

```text
-- 1. 策略注入：total_price 吃价格，也吃「费用怎么算」--
  fee(:flat).(1000)          => 5
  fee(:proportional).(1000)  => 120.0
  total_price(1000, flat)        => 1005
  total_price(1000, proportional) => 1120.0
```

同一个 `total_price/2`，装上不同策略就是不同计费系统。调用注意两件事：
匿名函数用 `.()` 调（`flat(1000)` 会去找具名函数 `flat/1`）；函数可以
存进 map、列表，跟数字一样是普通值。把函数传给函数、从函数返回函数，
是函数式与命令式最直观的分水岭（第 05 章 `twice/2`、第 07 章
`Enum` 全家都靠它）。

## 26.2 闭包捕获的是「创建时刻的值」

匿名函数能引用外部变量，靠的是**闭包**：函数记住创建它时的词法作用
域。关键问题是——记住的是变量还是值？答案是值：

```elixir
iex> f = Ex26Closures.freeze(10)
iex> x = 10
iex> {f.(), x}
{11, 10}
iex> x = 999
iex> {f.(), x}
{11, 999}
```

`freeze(10)` 里的 10 在函数创建那刻就定死了。Elixir 没有「改一个变量
的值」这回事——`x = 999` 只是**重绑**（让名字指向新值），旧值 10 仍被
闭包持有。这与命令式语言的闭包（引用可变槽位、重绑会影响闭包）正好
相反。也解释了第 12 章的一个老朋友：进程的 `receive` loop 之所以能用
「参数换新值」的方式演进状态，靠的就是同一机制。

词法作用域是**单向镜**：

```elixir
answer = 42
make = fn -> other_answer = 88 + answer; other_answer end
make.()        # => 130，函数内能看见外部
other_answer   # => CompileError: undefined variable，外部看不见函数内
```

函数只能看到**自己定义之前**的外部变量（先定义后创建的也看不见）。
`Ex26Closures.inner_demo/0` 把这个行为固化成了 `{130, 42}` 一对返回值。

## 26.3 自由变量与绑定变量：遮蔽

函数体里每个变量的身份由来源决定：

- **绑定变量**：函数参数、函数体内定义的局部变量；
- **自由变量**：其余的——被闭包捕获的外部变量。

书里的经典坑例：外部有 `product_price = 200` 和 `quantity = 2`，函数
参数偏偏也叫 `quantity`：

```elixir
calculate = fn quantity -> product_price * quantity end
calculate.(4)   # => 800，不是 400
```

参数（绑定）**遮蔽**同名外部变量（自由），调用 `.(4)` 时外部那个
`quantity = 2` 根本没被看见。规则很清楚：**同名时，参数赢**。但遮蔽
是可读性毒药——读者得逐行数哪个 quantity 是哪个。社区实践（以及
Credo 的 lint）直接禁掉同名遮蔽；这里保留书例只为看清规则。

## 26.4 闭包工厂与无状态计数器

「吃配置、吐函数」的工厂是最常见的闭包形态：

```elixir
iex> hello = Ex26Closures.make_greeter("Hello")
iex> hi = Ex26Closures.make_greeter("Hi")
iex> hello.("Ada")
"Hello, Ada!"
iex> hi.("Ada")
"Hi, Ada!"
```

更进一步——没有可变状态也能「计数」：每次调用返回
`{当前值, 下一个计数器}`，状态被装进**下一个闭包**往下传：

```elixir
@spec counter(integer()) :: counter()
def counter(start) do
  fn -> {start, counter(start + 1)} end
end
```

```text
  counter 前 5 步 => [0, 1, 2, 3, 4]
```

这就是纯函数式的状态机：状态不放在任何可变的地方，而是编码在
「下一个函数」里。第 18 章 `Stream.iterate/2` 的内核、第 12 章的
状态 loop，都是这个形状的变体；第 14 章 Agent 只是把「下一个值」
换成了进程状态。

## 26.5 `&` 捕获：具名函数当值用的全部形态

第 05 章用过 `&String.upcase/1`，这里把 `&` 的形态收全：

**形态一：`&Mod.fun/arity` 取引用。** 直接写 `upcase = String.upcase`
是**调用**零参版本——报 `UndefinedFunctionError: String.upcase/0`；
要拿引用必须 `&String.upcase/1`。

**形态二：`&表达式`，`&1`/`&2` 是位置参数。** 编译器据此推断元数：

```elixir
multiply = &(&1 * &2)     # 自动成为二元函数
multiply.(10, 2)          # => 20
```

限制：**造不出零参函数**——`&(true)` 直接编译错（没有 `&N` 出现，
编译器不知道该是几元），零参只能 `fn -> ... end`。

**形态三：捕获时顺手腌进外部变量。** 管道里塞不进 `Enum.at/2`（它要
列表在前），包一层闭包就通了——书第 6 章选英雄的管道正是这么写的：

```elixir
find = Ex26Closures.find_by_index(["Knight", "Wizard", "Rogue"])
find.(1)     # => "Wizard"，列表被腌进了函数里
```

`&` 的缺点是没有参数名，`&(&1 * &2)` 尚可、`&(&3 - &1 * &2)` 就该
老老实实写 `fn` 了。

## 26.6 闭包与进程：唯一的行李箱

`spawn/1` 接收一个函数去异步执行——它**没有参数通道**。子进程要带的
值从哪来？闭包：

```elixir
parent = self()
message = "Hello from a spawned process!"

spawn(fn -> send(parent, {:msg, message}) end)

receive do
  {:msg, m} -> m
after
  1_000 -> "timeout!"
end
```

```text
-- 6. spawn 的函数没法传参——要带的值只能靠闭包捕获 --
  子进程送回 => "Hello from a spawned process!"
```

这是书里 spawn 例子的确定性版本：`message` 在 `fn` 创建时就被捕获，
跨进程也稳稳带过去。第 12 章的进程、第 13 章的 Task，函数体里引用的
一切外部值都是这么带走的。

## 26.7 函数组合：管道进数据

`|>` 是语法层的组合；数据层的组合是 `compose/2`——返回「先 f 后 g」的
新函数：

```elixir
shout = Ex26Closures.compose(&String.trim/1, &String.upcase/1)
shout.("  hi  ")     # => "HI"
```

而 `thread/2` 把一整串函数依次应用于值——管道被收进**数据**里：

```elixir
steps = [&String.trim/1, &String.upcase/1, &String.reverse/1]
Ex26Closures.thread("  hi  ", steps)    # => "IH"
```

函数列表本身是值：可以存进配置、可以按条件拼装、可以当参数传——
`|>` 做不到这些（它的每一段必须在编译期写死）。组合还满足结合律：
`(f ∘ g) ∘ h == f ∘ (g ∘ h)`，测试里用三种小函数验证过——拼装顺序
不影响语义，重构中间件链才敢放手做。

## 26.8 要点小结

```text
  函数是值：当参数传（策略注入）、当返回值收（工厂）、存进数据结构
  闭包捕获创建时刻的值：之后重绑外部变量，已创建的闭包纹丝不动
  词法作用域单向镜：内可见外、外不可见内；只看得到定义之前的变量
  绑定变量（参数）遮蔽同名自由变量——规则清楚，但别这么写
  无状态计数器：状态装进下一个闭包（Stream.iterate 的种子）
  & 三形态：&Mod.fun/arity 引用、&(&1…) 位置参数（造不了零参）、腌外部变量
  compose/thread：函数列表是数据，管道可存可传可动态拼装；组合满足结合律
```

## 26.9 坑位清单

1. **匿名函数必须 `.()` 调用**：`flat(1000)` 报 UndefinedFunctionError
   （找的是具名函数）；混用是新手高频错误。
2. **`upcase = String.upcase` 不是取引用**：它在调用零参版本。取引用
   用 `&String.upcase/1`。
3. **`&` 造不出零参函数**：`&(true)` 编译错（error: invalid args for &）；
   零参匿名函数只有 `fn -> ... end` 一种写法。
4. **重绑变量前先读一次**：`x = 10; x = 999` 里第一次绑定是死代码，
   编译器报 unused variable 告警（第 2 层门禁直接挂）；doctest 里的
   演示也一样要「绑完就用」。
5. **遮蔽要靠 `^` 才能反向匹配**：想在重绑时断言旧值，用 pin
   （`^x = 999` 报 MatchError 而不是静默重绑）——第 04 章的老朋友，
   在闭包重绑演示里最容易踩。

---

下一章回到递归：把「减治 / 分治 / 无界」三种治理术配齐。
