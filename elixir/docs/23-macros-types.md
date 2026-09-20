# 23 · 宏与元编程 / 类型检查

> 对应示例：`examples/23_macros_types/`（独立 mix 工程，含 ExUnit 测试、doctest 与 `run.exs` 驱动脚本）

Lisp 系语言有句名言：「代码即数据」。Elixir 作为宏语言继承了这件武器，
但让它**隐形**——你写的几乎所有东西都已经经过宏展开：`def`、`if`、
`|>`、`use ExUnit.Case`，无一不是宏。本章先看清代码在编译器眼里的形态
（AST），再亲手写宏；最后讲 `@type`/`@spec` 与 Elixir 1.20 的**增量类型
检查器**：它不运行程序，只从代码推断类型，在编译期抓住「这段逻辑恒真/
恒失败」一类错误。

## 23.1 quote：代码的本来面目是三元素组

`quote do: ...` 把代码翻译成它的 AST（抽象语法树）。Elixir AST 的核心
形态是三元素组：

```elixir
{name, meta, args}
#  name : 调用名（原子）      例：:+
#  meta : 元数据 keyword      例：[line: 3]
#  args : 参数列表           例：[1, 2]
#         变量没有参数：args 为 nil
```

不是所有东西都变成三元组——**列表和元组保持字面量**（现代 AST 里它们
就是自身），map 变成 `{:%{}, [], [键值对]}`，字符串、数字、原子也都是
自身：

```elixir
def ast_shape(code) do
  Macro.prewalk(Code.string_to_quoted!(code), fn
    {name, meta, args} -> {name, Keyword.drop(meta, [:line]), args}
    other -> other
  end)
end
```

`ast_shape/1` 顺手用 `Macro.prewalk` 把行号从元数据里删掉，输出才可
稳定打印（行号随写法变）：

```text
-- 1. AST 三元素组 {名, 元数据, 参数}；变量参数为 nil --
  1 + 2 => {:+, [], [1, 2]}
  foo(1) => {:foo, [], [1]}
  x => {:x, [], nil}
  [1, 2] => [1, 2]
```

两个常用工具：`Code.string_to_quoted!/1`（源码 → AST）和反向的
`Macro.to_string/1`（AST → 源码字符串）。

## 23.2 unquote / unquote_splicing：往代码里注入代码

quote 默认只「描述」代码；`unquote` 把**当前作用域的值**塞进 AST：

```elixir
def run_quoted(n) do
  ast =
    quote do
      unquote(n) + 1          # 编译 quote 时 n 已绑定，值被内联进 AST
    end

  {value, _} = Code.eval_quoted(ast)
  value
end
```

`unquote_splicing` 把一个列表展开成**多个实参**（不是一个列表参数）：

```elixir
def splice_sum(xs) do
  ast =
    quote do
      unquote(__MODULE__).sum3(unquote_splicing(xs))
    end

  {value, _} = Code.eval_quoted(ast)
  value
end
```

注意两个细节：

- **`__MODULE__` 在 quote 里必须 `unquote(__MODULE__)`**。裸写
  `__MODULE__` 是给「将来展开处」的 AST 节点，eval 时没有模块上下文，
  得到 `nil.sum3` 的 UndefinedFunctionError。
- 本章的 `sum3/3` 用 `@doc false` 暴露为公开函数（eval 要解析得到），
  但不进文档。

```text
-- 2. quote 造 AST，unquote 注入运行值，eval_quoted 执行 --
  run_quoted(41) => 42
  splice_sum([1,2,3]) => 6
```

## 23.3 自定义宏：编译期展开的函数

宏和普通函数的根本区别是执行时机：**宏接收 AST、返回 AST，在编译期
展开**；普通函数在运行期被调用。两个教学宏：

```elixir
defmacro my_unless(clause, do: block) do
  quote do
    if !unquote(clause), do: unquote(block)
  end
end

defmacro debug(expr) do
  text = Macro.to_string(expr)

  quote bind_quoted: [value: expr, text: text] do
    IO.puts(text <> " => " <> inspect(value))
    value
  end
end
```

`bind_quoted` 是常用糖：自动把绑定以**卫生变量**注入并先求值，等价于
手写一串 `unquote`。调用宏的模块必须先 `require 宏模块`（否则编译器
告警「there is a macro with the same name」）。

```text
-- 3. 宏在编译期展开；下面一行是 debug 的输出 --
  unless => {:ran, nil}
1 + 2 => 3
```

宏的纪律：**能写普通函数就别写宏**。宏展开的代码不透明、栈帧更长、
测试更难；只有「需要在编译期变换调用形式」（DSL、断言、样板消除）才
动用它。

## 23.4 卫生性（hygiene）：默认隔离，var! 才能逃逸

宏展开时引入的变量，默认与调用方的同名变量**互不干扰**，这叫卫生性：

```elixir
defmacro shadow do
  quote do
    x = 999          # 这个 x 属于宏自己的作用域
    x + 1
  end
end

def hygiene_demo do
  x = 1
  a = Ex23Macros.shadow()
  {x, a}             # => {1, 1000}：调用方的 x 原封不动
end
```

要**显式改写调用方**的变量，用 `var!`：

```elixir
defmacro leak do
  quote do
    var!(x) = 999
  end
end

def escape_demo do
  x = 1
  before = x         # 先读初值（关键！见坑 4）
  Ex23Macros.leak()
  {before, x}        # => {1, 999}
end
```

```text
-- 4. 宏内变量默认与调用方隔离 --
  卫生 => {1, 1000}
  var! 逃逸 => {1, 999}
```

`var!` 是在代码里凿洞，默认锁上正是为了让宏作者「无意的重名」不污染
调用方——需要跨边界时请读它作警告信号。

## 23.5 use 与 __using__：批量注入的约定

`use SomeModule` 是一颗语法糖：它调用 `SomeModule.__using__/1`，并把
返回的 AST **内联进当前模块**。

```elixir
defmodule Ex23Macros.Greeter do
  defmacro __using__(opts) do
    greeting = Keyword.get(opts, :greeting, "你好")

    quote do
      def greet(name), do: unquote(greeting) <> "，" <> name
    end
  end
end

defmodule Ex23Macros.Greeting do
  use Ex23Macros.Greeter, greeting: "嗨"   # 编译后 Greeting 就有 greet/1
end
```

参数原样传给 `__using__/1`。`use ExUnit.Case`、`use Mix.Project`
都是同一机制——它常做的事是 `import` + `@attribute` + 注入函数的组合。

```text
-- 5. use 是「调用 __using__ 并内联其返回的 AST」的语法糖 --
  greet => 嗨，世界
```

注入进来的函数没有自己的 `@doc`，也挂不上 doctest；用普通测试覆盖
（本章正是这么做的）。

## 23.6 @type / @spec：给人和检查器的契约

`@spec` 是函数的类型签名，`@type` 定义类型名，`@typep` 定义模块私有
类型，`@typedoc` 给类型写文档：

```elixir
@typedoc "金额，整数分"
@type cents :: non_neg_integer()
@type t :: %__MODULE__{amount: cents(), currency: atom()}
@typep pair :: {t(), t()}

@spec add(t(), t()) :: {:ok, t()} | {:error, :currency_mismatch}
def add(%__MODULE__{currency: c} = a, %__MODULE__{currency: c} = b) do
  {:ok, %{a | amount: a.amount + b.amount}}
end

def add(%__MODULE__{}, %__MODULE__{}), do: {:error, :currency_mismatch}
```

关键认知：**`@spec` 不做任何运行时校验**——传错类型照样跑崩。它的
读者是人和下一节的检查器。写 spec 的回报体现在编辑器提示、文档生成，
以及「写签名时逼自己想清楚输入输出」。

```text
-- 6. @spec 不做运行时检查；跨币种返回 tag 而非静默换算 --
  同币种 => %Ex23Macros.Money{amount: 150, currency: :CNY}
```

## 23.7 1.20 类型检查器：编译期抓「恒真恒假」

Elixir 1.20 内建了增量类型检查器（沿用 Erlang 的成功类型推断思路）。
它不要求你写标注，只在**编译期**发现这类问题：

- 条件表达式永远返回某个值（`x = :a` 之后拿 `x && false` 做分支）；
- 某个 case 没有任何子句能匹配给定类型（无返回值）；
- 字面量上不可能成立的调用（`Stream.cycle([])`、`1 < :a`）。

本章的 `checker_demo/0` 在**运行时**触发一次编译，并用
`Code.with_diagnostics/2` 把告警收进数据（stderr 保持干净），再归一化
成固定标签：

```elixir
def checker_demo do
  tag = System.unique_integer([:positive])

  src = """
  defmodule Checker#{tag} do
    def f do
      x = :a
      x && false
    end
  end
  """

  {_result, diagnostics} =
    Code.with_diagnostics(fn -> Code.compile_string(src) end)

  # 每次模块名带唯一整数，避免「redefining module」告警混入。
  Enum.flat_map(diagnostics, fn d ->
    [
      warning: d.severity == :warning,
      always_a: String.contains?(d.message, "will always evaluate")
    ]
  end)
end
```

检查器对上面的代码给出告警：conditional expression `x` will always
evaluate to `:a`。

```text
-- 7. 「恒为 :a」在编译期就被告警；诊断可捕获、不污染 stderr --
  标签 => [warning: true, always_a: true]
```

与检查器共处的纪律（前 22 章已反复用到）：

- 字面量不可能模式/比较会被点名——演示这类逻辑时包进**参数为 `term()`
  的包装函数**，让检查器看到未知输入。
- 告警即信息：`mix compile --warnings-as-errors` 把它们升级成失败，
  本教程所有工程都按此跑（即第 2 层）。

## 23.8 要点小结

```text
  代码即数据：quote 得 AST（三元素组），unquote 注入，eval_quoted 执行
  宏接收/返回 AST、编译期展开；require 才能调用；优先普通函数
  bind_quoted 卫生注入；宏变量默认隔离，var! 才逃逸
  use M = 内联 M.__using__/1 的返回，适合批量 import/注入
  @type/@spec 是契约，不做运行时校验；typep 私有、typedoc 说明
  类型检查器编译期抓恒真恒假/不可达；演示用 term() 包装规避
```

## 23.9 坑位清单

1. **调用宏忘 `require`**：宏不是函数，不 require 时编译器只按函数找，
   告警「there is a macro with the same name」。
2. **quote 里裸写 `__MODULE__`**：那是展开处的 AST 节点，eval 得到
   `nil`；要当前模块就 `unquote(__MODULE__)`。
3. **AST 元数据含行号**：直接打印 quote 结果不稳定；做展示先
   `Macro.prewalk` 删 `:line`。变量调用的 args 是 `nil` 不是 `[]`。
4. **`var!` 赋值后，读变量会让初值赋值变成「unused」**：编译器把宏后
   的读归给 var! 绑定（本章踩过：`x=1; macro; x` 报 x 未用）。要两个
   值就在宏调用**之前**先把初值读进另一变量。
5. **注入函数挂不上 doctest**：`use` 产生的函数无 @doc；用普通测试
   覆盖，别试图在模块尾部补悬空 @doc（会告警 discards）。
6. **`@spec` 不做运行时检查**：传错类型照样崩；它是给人和检查器的
   契约。defp 不被使用必告警（用 @doc false 改公开，或删掉）。
7. **运行时反复 compile_string 同模块名会「redefining」**：模块名拼上
   `System.unique_integer`；并用 `Code.with_diagnostics` 收住告警，
   否则 stderr 被污染、第 4 层挂。
8. **别用宏做普通函数能做的事**：宏展开不透明、调用方编译变慢、栈深；
   只在需要编译期变换（DSL/断言/样板）时使用。
9. **卫生性是护栏不是障碍**：默认隔离避免重名污染；`var!`/`var!(x, ctx)`
   是显式凿洞，评审时每个 var! 都值得被问「为何不能走参数」。
10. **类型检查器对字面量「恒失败」零容忍**：`Stream.cycle([])`、
    `is_number(42)` 等写法全部告警；测试/演示代码同样要包 term() 包装，
    并保持 `--warnings-as-errors` 常开，别靠忽略告警过日子。

---

最后一章把全部零件装起来：[24 · 收官项目](24-capstone.md)
——容错键值缓存 + 并发文件词频统计 worker，GenServer、Supervisor、Task、
Stream 在一棵监督树里协作，并亲手杀掉 worker 看它如何自愈。
