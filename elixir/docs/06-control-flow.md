# 06 · 控制流

> 对应示例：`examples/06_control_flow/`（独立 mix 工程，含 ExUnit 测试、doctest 与 `run.exs` 驱动脚本）

第 04 章的 `=` 和第 05 章的多子句函数已经承担了大部分「分支」工作。本章补齐剩下的四件
控制流工具，并讲清它们的分工：

| 工具 | 用于 |
|---|---|
| 多子句函数 / `case` | 对**一个值**按「模式 + 守卫」分派 |
| `cond` | 一组互不相干的布尔条件 |
| `if` / `unless` | 单条件的便捷宏 |
| `with` | 多步 `{:ok, _}` 链式调用，失败短路 |

最后讲一条 Elixir 与许多语言不同的规则：**所有 `do` 块都是词法作用域，块内赋值不外泄**。

## 6.1 `case`：内联的多子句函数

`case` 把第 05 章的多子句分派搬到表达式内部：对一个值自上而下试分支，先比模式、再比守卫，
第一个匹配的胜出：

```elixir
case value do
  {:ok, _} -> :ok_tuple
  {:error, _} -> :error_tuple
  n when is_integer(n) -> {:integer, n}
  [_ | _] -> :non_empty_list
  [] -> :empty_list
  other -> {:other, other}
end
```

```text
describe({:ok, 1}) => :ok_tuple
describe(42)       => {:integer, 42}
describe([])       => :empty_list
```

规则与函数子句完全相同：**具体分支在前，兜底在后**；守卫可以叠加（`is_number(n) and
n >= 90`）；兜底用 `_`（不要值）或具名变量（`other`，要拿到值）。

一个分支都不匹配时，不是返回 `nil`，而是抛 `CaseClauseError`：

```text
case :unmatched do :other -> ... end => CaseClauseError
```

> 既然 `case` 与多子句函数等价，什么时候用哪个？逻辑属于一个公开操作、需要文档和类型标注
> 时写函数子句；只是函数内部一次性的分派时写 `case`。

## 6.2 `cond`：互不相干的布尔条件

`case` 的每个分支都在匹配**同一个值**。当各分支的判定条件彼此无关时，用 `cond`：

```elixir
def fizzbuzz(n) do
  cond do
    rem(n, 15) == 0 -> "fizzbuzz"
    rem(n, 3) == 0 -> "fizz"
    rem(n, 5) == 0 -> "buzz"
    true -> n
  end
end
```

```text
fizzbuzz 1..15 =>
[1, 2, "fizz", 4, "buzz", "fizz", 7, 8, "fizz", "buzz", 11, "fizz", 13, 14, "fizzbuzz"]
```

要点：

1. 第一个求值为**真**的条件胜出（真值规则不变：只有 `false`/`nil` 为假）；
2. 最后写 `true ->` 作为兜底——没有任何条件为真时抛 `CondClauseError`，而不是静默返回 nil；
3. 条件按**从窄到宽**排序（`< 0` 必须排在 `< 28` 前面）。

## 6.3 `if` / `unless`：有返回值的宏

`if` 在 Elixir 里不是关键字，是宏。这意味着它和一切表达式一样**返回值**，可以直接整个
赋值：

```elixir
def greeting(name) do
  if is_binary(name) and name != "" do
    "hello #{name}"
  else
    "hello stranger"
  end
end

def positive_only(n), do: if(is_integer(n) and n > 0, do: n, else: nil)
```

```text
greeting("Ada") => "hello Ada"
greeting("")    => "hello stranger"
positive_only(5) / (-1) / (:x) => 5 / nil / nil
```

短分支用关键字列表形式 `do: ..., else: ...`；长分支用 `do/end` 块。`unless` 是语义反过来
的 `if`，两者都遵守 03 章的真值规则——`0`、`""`、`[]` 都走真分支：

```text
truthy_label(0)     => :truthy
truthy_label(nil)   => :falsy
truthy_label(false) => :falsy
```

经验法则：条件超过两三个分支时，别再嵌套 `if`，改用 `cond` 或多子句。

## 6.4 `with`：`{:ok, _}` 流水线与短路

真实程序常常是一串「每步都可能失败」的操作：校验 → 规范化 → 存储。用嵌套 `case` 写会形成
灾难三角。`with` 用 `<-` 把成功形状串成一条直线：

```elixir
with {:ok, params} <- validate(params),
     {:ok, user} <- normalize(params),
     {:ok, saved} <- save(user) do
  {:ok, saved}
else
  {:error, reason} -> {:error, reason}
  other -> {:error, {:unexpected, other}}
end
```

语义：

- 每个 `<-` 都是一次模式匹配，成功则变量可用于后续子句和 `do` 块；
- **任何一步对不上，立刻短路**，后面的步骤不执行；
- 有 `else` 时，失败值在 `else` 的分支里做模式匹配（写法同 `case`）；
- 没有 `else` 时，**失败的值直接成为整个 `with` 表达式的返回值**。

```text
register(%{name: "  Ada  "}) => {:ok, %{id: :deterministic_id, name: "Ada"}}
register(%{name: ""})        => {:error, :invalid_name}
register(%{name: "   "})     => {:error, {:unexpected, :blank_after_trim}}
register(%{name: 超长})      => {:error, :name_too_long}
```

第三个例子值得停一下：`normalize/1` 在 trim 后发现是空串，返回的失败形状是**裸原子**
`:blank_after_trim` 而不是 `{:error, _}`。正因为各步失败形状可能不同，`else` 里除了
`{:error, reason}` 还需要 `other` 兜底——这不是多余的防御。

> 1.20 类型检查器会帮你检查 else 分支的完备性：如果所有步骤的失败类型都被前一分支覆盖，
> 再写 `other ->` 会被告警为 redundant。本章最初的版本就被它抓过——那是一个真实信号：
> 要么兜底确实没用（删掉），要么某一步真的可能返回别的形状（补上对应步骤）。

不带 `else` 的最简形式：

```text
chain({:ok, 1}, {:ok, 2})     => 3
chain({:error, :x}, {:ok,2})  => {:error, :x}   # 第一步的失败值直接返回
chain({:ok, 1}, :oops)        => :oops          # 第二步失败，:oops 直接返回
```

`<-` 与 `=` 的区别也在这里：`=` 对不上会抛 `MatchError`；`<-` 对不上是「短路退出 with」，
是正常业务路径。

## 6.5 作用域：块内赋值不外泄

`if`/`unless`/`case`/`cond`/`with` 的 `do` 块都是**词法作用域**：

1. **块内首次绑定的变量，块外不可见**——在块外引用直接是编译期错误，不是 `nil`：

   ```elixir
   if true do
     y = 1
   end

   y + 1
   # ** (CompileError) undefined variable "y"
   ```

2. **块内对外层同名变量的重绑定只在块内有效**，出了块外层绑定原封不动：

   ```elixir
   def rebind_inside(x) do
     if true do
       x = x + 1     # 块内 x 是 11
       x
     else
       :never
     end

     x               # 外层 x 还是传入的 10
   end
   ```

   ```text
   rebind_inside(10) => 10
   ```

想把块里的计算结果带出来，靠的是**表达式返回值**（`chosen = if cond, do: ...`），而不是
依赖块内变量外泄。这与 Ruby/JavaScript 的块语义不同，初学时需要刻意适应；换来的好处是：
阅读任意一段块外代码，都不必担心某个分支在里面偷改了外部变量。

## 6.6 坑位清单

1. **`case`/`cond` 兜不住就崩**：分别抛 `CaseClauseError`/`CondClauseError`，不是返回 nil。
   非崩溃式兜底要写 `other ->` / `true ->`。

2. **`if`/`cond` 的真值规则只有 false 和 nil**：`0`、`""`、`[]` 全真，
   `if list` 判不了空列表（用 `if list == []` 或直接 `case list do [] -> ...`）。

3. **`with` 里用 `<-` 不是 `=`**：`=` 失配抛 MatchError（异常路径），`<-` 失配是短路退出
   （业务路径）。没有 `else` 时，失败值原样成为整个 with 的返回值。

4. **`else` 分支要覆盖各步真实的失败形状**：步骤间失败值未必统一（裸原子、错误元组、
   不同 reason 都可能）。反过来，1.20 会告警「redundant 分支」——它是在帮你核对完备性，
   不要为了消警把真正的兜底删掉，而要检查步骤返回类型。

5. **块内赋值不外泄**：块内新建的变量块外是 CompileError；块内重绑定不影响块外。要带出
   结果就 `x = if ..., do: ...` 接返回值。

6. **选择顺序**：单值多形状 → 函数子句或 `case`；多个无关布尔条件 → `cond`；单条件 →
   `if`；多步成败链 → `with`；遍历 → 递归（05 章）或 `Enum`（下一章）。嵌套超过两层
   `if/case` 通常是选错了工具。

7. **演示「必崩分支」要避开静态检查器**：测试和脚本里字面量写死的必败 `cond`/必失匹配会被
   1.20 判为编译告警。把代码放进 `Code.eval_string/1` 在运行时编译；测试里再用
   `ExUnit.CaptureIO.capture_io(:stderr, ...)` 收走编译诊断，保持 `mix test` 的 stderr 干净。

---

下一章：[07 · Enum 与管道](07-enum.md)
