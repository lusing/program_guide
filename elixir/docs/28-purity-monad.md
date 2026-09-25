# 28 · 纯函数纪律与错误单子

> 对应示例：`examples/28_error_monad/`（独立 mix 工程，含 ExUnit 测试、doctest 与 `run.exs` 驱动脚本）
>
> 取材自《函数式编程入门：使用 Elixir》第 7 章「处理非纯函数」。世界不可预测：用户输入 hot dog、文件不存在、数据库连不上。可靠代码的主策略是**识别并隔离非纯函数**——本章用同一个「问数量、问单价、算总价」的场景，对比书中五种处理策略，并**从零手写**错误单子（书用 MonadEx 库，本教程零依赖）。

## 28.1 纯与非纯：一张速查表

**纯函数**：同参同果、无副作用。`net_price(100, 10)` 调一百次都是
`90.0`——调用可以被结果原样替换（引用透明，第 25 章）。

**非纯函数**：同样的参数，结果每次可能不同。判据一句话：**引用了
函数参数之外的值，并受其变化影响**。

```text
-- 1. 纯度速查：引用了参数之外的值并受其影响 => 非纯 --
  [pure] net_price/2 —— 同参同果
  [impure] IO.gets/1 —— 读用户输入
  [impure] DateTime.utc_now/0 —— 读全局时钟
  [impure] :rand.uniform/1 —— 读随机源
  [impure] File.read/1 —— 读外部世界
```

一个容易误判的案例（书 7.1.2）：闭包捕获了外部变量 `tax`——函数体
确实引用了参数之外的值，**但它仍然是纯的**：不可变性让闭包捕获的是
定值（第 26 章），输出依旧只受输入影响。所以最终判据落在**副作用**
上：有没有往函数作用域之外写东西、读会变的东西。

纪律不是「消灭非纯」——实用软件离不开输入输出；而是**最大化纯核心、
把非纯推到边界**。第 24 章收尾那句「先抽纯函数核心」就是这条纪律。

## 28.2 依赖注入：交互是数据

书的场景用 `IO.gets/1` 向用户提问；本章把「答案序列」当**数据**传
进来——`fetch(["10", "20"], 0)` 就是「问第一个问题的纯版本」：

```elixir
iex> Ex28ErrorMonad.fetch(["10", "20"], 0)
{:ok, 10}
iex> Ex28ErrorMonad.fetch(["hot dog", "20"], 0)
{:error, :not_a_number}
iex> Ex28ErrorMonad.fetch(["10"], 1)
{:error, :missing_answer}
```

这本身就是隔离非纯的第一招：**纯核心 + 边界注入**。五种策略吃同一
批输入、给出同样的结论（测试里有对照矩阵）；交互外壳（CLI、测试、
脚本）想怎么换就怎么换。

## 28.3 策略一：case 嵌套 → 函数子句

最直觉的写法：case 检查每一步。两个输入还能忍，五个输入嵌套五层
case 就是迷宫（书 7.2 的原话）。改进版把检查下放到**函数子句**——
每条子句一种情形：

```elixir
defp calculate({:ok, q}, {:ok, p}), do: {:ok, q * p}
defp calculate({:error, _}, _price), do: {:error, :quantity_not_a_number}
defp calculate(_quantity, {:error, _}), do: {:error, :price_not_a_number}
```

```text
  checkout_case(["10", "20"])      => {:ok, 200}
  checkout_case(["hot dog", "20"]) => {:error, :quantity_not_a_number}
  checkout_case(["10", "hot dog"]) => {:error, :price_not_a_number}
```

适合简单场景；复杂起来还是层叠——所以需要后面的策略。

## 28.4 策略二：try + rescue + defexception

会 raise 的函数用 `!` 结尾（社区约定）。解析失败抛**自定义异常**，
而不是让 MatchError 满天飞：

```elixir
defmodule Ex28ErrorMonad.InvalidOptionError do
  defexception message: "Invalid option"
end

def parse_answer!(answer) do
  case Integer.parse(answer) do
    :error -> raise Ex28ErrorMonad.InvalidOptionError
    {value, _rest} -> value
  end
end
```

rescue 一个太宽的 MatchError 等于瞎救——defexception 让「什么错」
说清楚。try 块里写**愉快路径**（happy path：只有成功场景的代码），
rescue 集中善后：

```elixir
try do
  quantity = parse_answer!(Enum.at(answers, 0, ""))
  price = parse_answer!(Enum.at(answers, 1, ""))
  {:ok, quantity * price}
rescue
  e in Ex28ErrorMonad.InvalidOptionError -> {:error, e.message}
end
```

这是 OO 程序员最熟悉的形态，定位是**驯服不受你控制的第三方代码**；
自家代码尽量少 raise（第 11 章的结论在这里依然成立）。

## 28.5 策略三：throw + catch

throw 抛的是**值**不是错误，catch 按模式接住——更像流程控制结构，
而非异常机制：

```elixir
def checkout_throw(answers) do
  quantity = parse_answer_throw(Enum.at(answers, 0, ""))
  price = parse_answer_throw(Enum.at(answers, 1, ""))
  {:ok, quantity * price}
catch
  {:error, message} -> {:error, message}
end
```

细节：函数体只有一个 try 块时可以省略 `try do`（**隐式 try**，函数
体直接挂 catch）。Elixir 程序员极少用它——函数直接**返回**值就好，
抛接是绕路。

## 28.6 策略四：错误单子（从零手写）

单子听起来吓人（Haskell、范畴论），实践里核心就两个零件：

**零件一：包装。** `ok/1` 装成功值、`error/1` 装失败原因——值带上
「气氛标签」，下游据此自动决策：

```elixir
iex> Ex28ErrorMonad.ok(42)
{:ok, 42}
iex> Ex28ErrorMonad.error("boom")
{:error, "boom"}
```

**零件二：bind——单子的心脏。** 成功：拆出值交给函数，函数的返回
继续是单子；失败：**跳过函数**，错误原样传递：

```elixir
def bind({:ok, value}, fun), do: fun.(value)
def bind({:error, _reason} = failure, _fun), do: failure
```

书用第三方库 MonadEx 的 `~>>` 运算符；Elixir 允许自定义这个保留
运算符，所以零依赖也能有同款语法（宏展开成 bind，第 23 章的知识）：

```elixir
defmacro left ~>> right do
  quote do: Ex28ErrorMonad.bind(unquote(left), unquote(right))
end
```

```elixir
iex> import Ex28ErrorMonad
iex> ok(3) ~>> (&ok(&1 * 2)) ~>> (&ok(&1 + 1))
{:ok, 7}
iex> error("wrong") ~>> (&ok(&1 * 2)) ~>> (&ok(&1 + 1))
{:error, "wrong"}
```

**短路是自动的**——`pipeline/1` 用标签链实证：三步流水线，第二步
失败，第三步的标签根本没进结果：

```text
  pipeline(:ok_path)   => {:ok, [:s1, :s2, :s3]}
  pipeline(:fail_at_2) => {:error, :boom}（s3 被短路，未执行）
```

结账的单子版把「问一个问题」做成可复用的单子步骤，**同一个步骤
用两次**再算乘积：

```elixir
def checkout_monad(answers) do
  ok({answers, []})
  |> bind(ask_step())     # 问数量
  |> bind(ask_step())     # 问单价（同一步骤复用）
  |> bind(product_step()) # 数量 × 单价
end
```

优点（书 7.4）：愉快路径一条线；错误处理集中在出口；所有函数返回
一致的数据结构。缺点：Elixir 没内建单子，语法与社区风格有距离。

## 28.7 策略五：with——Elixir 内建

`with` 组合多个匹配子句：全部匹配走 do 块；任何一步不匹配，停下、
把**不匹配的值**交给 else：

```elixir
def checkout_with(answers) do
  with {:ok, quantity} <- fetch(answers, 0),
       {:ok, price} <- fetch(answers, 1) do
    {:ok, quantity * price}
  else
    {:error, :not_a_number} -> {:error, :not_a_number}
    {:error, :missing_answer} -> {:error, :missing_answer}
  end
end
```

else 里**显式列出**每种失败，不用通配 `_`——有意识地决定每个错误
怎么办（书 7.5 的忠告：通配会吞掉你没预料的情况，让错误无声消失）。
不需要新数据结构、新概念、新库；缺点是不能与 `|>` 连用，链式美感
打折。**多数场景这是最实用的选择。**

## 28.8 五策略对照

```text
-- 8. 对照：成功批全部得到 200；失败批各自报错但都「返回值」而非崩溃 --
  ["10", "20"] => ["ok(200)", "ok(200)", "ok(200)", "ok(200)", "ok(200)"]
  ["hot dog", "20"] => ["error(:quantity_not_a_number)", "error(\"Invalid option\")", "error(\"Invalid option\")", "error(\"Invalid option\")", "error(:not_a_number)"]
  ["10", "hot dog"] => ["error(:price_not_a_number)", "error(\"Invalid option\")", "error(\"Invalid option\")", "error(\"Invalid option\")", "error(:not_a_number)"]
  ["10"] => ["error(:price_not_a_number)", "error(\"Invalid option\")", "error(\"Invalid option\")", "error(\"Invalid option\")", "error(:missing_answer)"]
```

选型建议（书 7.6 的小结）：

| 场景 | 首选 |
|---|---|
| 一两处简单检查 | case / 函数子句 |
| 驯服会 raise 的第三方库 | try + rescue（配 defexception） |
| 长流水线、错误要集中处理 | 错误单子或 with |
| 大多数业务代码 | **with** |

共同底线：**函数返回值，而不是抛东西**——`{:ok, _} / {:error, _}`
让调用方用模式匹配接住一切（第 11 章 tagged tuple 的进阶版）。

## 28.9 要点小结

```text
  非纯判据：引用参数之外的值并受其影响（IO/时钟/随机/文件）
  闭包捕获外部变量仍是纯的——不可变性令捕获为定值
  隔离第一招：依赖注入，交互是数据（答案序列当参数传）
  rescue 具体异常（defexception），别救 MatchError 这种「反正出错了」
  throw/catch 是抛值不是抛错；函数体可隐式 try；少用
  错误单子 = 包装 + bind 短路；~>> 宏可用保留运算符手写，零依赖
  with：模式匹配链 + else 显式收错；不与 |> 连用；多数场景最实用
  五策略殊途同归：成功值一致，失败各有语义，都返回值不崩溃
```

## 28.10 坑位清单

1. **同模块 import 两次会覆盖前一次**：`import M, only: [a: 1]` 后再
   `import M, only: [b: 2]`，a 就不可用了——需要多个函数时合并成
   一次 import（`only: [a: 1, b: 2]`）。
2. **`~>>` 这类运算符必须先 import 才能用**：自定义运算符宏定义在
   模块里，使用处（测试、doctest、iex）都要先 `import`，否则报
   undefined function `~/2` 式的错。
3. **隐式 try 只在函数体没有其他用途时省心**：`catch` 挂在函数体
   尾部时函数体就是 try 块；但函数里 try 之外还有别的表达式时必须
   显式 `try do`。
4. **缺答案与坏答案是两种失败**：`Enum.at(list, 1)` 给 `nil`，与
   `Integer.parse("hot dog")` 给 `:error` 语义不同——注入式 fetch
   把两者分开（`:missing_answer` vs `:not_a_number`），对照矩阵才
   站得住。
5. **错误标签在五策略间不必强求同名**（`:quantity_not_a_number` vs
   `"Invalid option"`）：每种策略的粒度本来就不同；对照测试断言的是
   **分类一致**（:ok/:error），不是文案一致。

---

最后一章是全书压轴的实战：把 struct、协议、行为、typespec 拼成一个
完整的回合制地下城游戏——纯函数引擎，确定性可测。
