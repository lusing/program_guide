# 02 · 第一个程序

> 对应示例：`examples/02_hello/`（独立 mix 工程，含 ExUnit 测试与 `run.exs` 驱动脚本）

本章把「Elixir 程序是怎么跑起来的」这件事彻底讲清：四种运行形态各自适合什么场景、
`mix new` 生成的每个文件干什么、模块与 arity 的规则、文档属性怎么在 `iex` 里查、
以及 `IO.puts` 插值与 `inspect` 的区别（这个区别会在第 08 章变成一整个 Unicode 深水区）。

## 2.1 四种运行形态

Elixir 跑在 BEAM（Erlang 虚拟机）上，所以它继承了 Erlang「编译成 `.beam` 字节码、
由虚拟机加载执行」的模型，但日常几乎不直接碰 `elixirc`——`mix` 全包了。

| 形态 | 命令 | 适合 | 特点 |
|---|---|---|---|
| **REPL** | `iex` | 探索、试表达式、查文档 | 逐行求值；`h()` 查文档、`i()` 查类型、`r()` 重编译当前文件 |
| **REPL + 工程** | `iex -S mix` | 边开发边试自己的模块 | 先编译工程再进 REPL，工程里的模块直接可用 |
| **脚本** | `elixir foo.exs` | 一次性小工具、CI 脚本 | `.exs` = Elixir Script，**在内存里编译执行，不产出 `.beam`** |
| **工程** | `mix run` / `mix test` / 生成的 release | 正经项目 | 有依赖管理、编译缓存、测试、打包 |

外加一条 Erlang 遗产：`escript` 把单个文件当可执行脚本跑（首行 `#!/usr/bin/env escript`，
入口是 `main/1`）。实测三种形态的 `argv` 行为：

```bash
# 脚本形态：文件名之后的参数进 System.argv()
$ cat /tmp/s.exs
IO.puts("script mode: #{inspect(System.argv())}")
$ elixir /tmp/s.exs one two
script mode: ["one", "two"]

# 工程形态：-- 之后的参数进 System.argv()
$ mix run -e 'IO.inspect(System.argv())' -- --verbose a.txt
["--verbose", "a.txt"]

# escript 形态：main/1 直接收参数列表
$ escript /tmp/s.es hi
escript ["hi"]
```

注意脚本形态的 `--`：`mix run -e '...' -- a b` 里 `--` 之前归 `mix` 自己解析，
之后才是给你的程序的。**漏了 `--`，参数会被 mix 当成自己的开关吃掉**（2.8 坑位 4）。

### `.ex` 与 `.exs` 的区别

这不是风格问题，是**编译产物**的区别：

- `.ex` —— 编译成 `.beam` 落盘（在 `_build/` 里），下次不改动就不重编；模块定义走这里。
- `.exs` —— 每次运行都重新在内存里编译，**不落盘**。配置文件（`mix.exs`、`.formatter.exs`、
  `config/*.exs`）、测试（`test/*_test.exs`）、一次性驱动脚本走这里。

所以本教程每个示例都有 `run.exs` 作为驱动：它是「演示脚本」，不该产出字节码；而
`lib/*.ex` 是「被演示的模块」，走正常编译。

## 2.2 mix 工程解剖

```bash
mix new ex02_hello --module Ex02Hello
```

生成：

```text
ex02_hello/
├── .formatter.exs          格式化配置（mix format 读它）
├── .gitignore              忽略 _build/ deps/
├── README.md
├── mix.exs                 工程定义：app 名、版本、依赖、OTP 应用回调
├── lib/
│   └── ex02_hello.ex       业务代码，一个文件一个模块
└── test/
    ├── test_helper.exs     ExUnit.start()
    └── ex02_hello_test.exs 测试
```

`mix.exs` 是全工程唯一的真源：

```elixir
defmodule Ex02Hello.MixProject do
  use Mix.Project

  def project do
    [
      app: :ex02_hello,        # OTP 应用名（原子），也是 _build/dev/lib/ 下的目录名
      version: "0.1.0",
      elixir: "~> 1.17",       # 版本约束；~> 1.17 意为 >= 1.17 且 < 2.0
      start_permanent: Mix.env() == :prod,   # 生产模式下未匹配的函数调用直接崩，而非打日志
      deps: deps()
    ]
  end

  def application do
    [extra_applications: [:logger]]   # 16 章讲启动顺序时会展开
  end

  defp deps, do: []                   # 本教程示例零外部依赖，全程可离线
end
```

`start_permanent: true` 值得单独说一句：它让「调用了不存在的函数」这类错误在
生产模式下**直接让进程崩掉**，而不是只记一条日志继续跑。这是 BEAM 的 let-it-crash
哲学在编译配置层的体现（11 章、16 章展开）。

## 2.3 最小模块解剖

```elixir
defmodule Ex02Hello do
  @moduledoc """
  第 02 章示例：最小模块的解剖。
  """

  @doc "最简单的公开函数：无参数、返回字符串。"
  @spec hello() :: String.t()
  def hello, do: "Hello, Elixir!"

  defp internal_only(x), do: x * 2

  def doubled(x), do: internal_only(x)
end
```

拆开看：

- **`defmodule Name do ... end`** —— 模块名必须是**别名**（大写字母开头，可带 `.` 分层，
  如 `Ex02Hello.Sub`）。别名在编译期被展开成原子：`Ex02Hello` 就是 `:"Elixir.Ex02Hello"`。
  这点在 12 章跨进程发消息时会露出真身。
- **`def` vs `defp`** —— `def` 公开，`defp` 私有。私有的判定单位是 **模块 + 名字 + arity**；
  未被任何地方调用的 `defp` 会触发编译告警，`--warnings-as-errors` 下直接编译失败。
- **`do:` 短写法** —— `def hello, do: expr` 是 `def hello do expr end` 的语法糖，
  只能装**一个表达式**。函数体超过一行就用 `do ... end`。
- **模块属性 `@xxx`** —— 编译期常量，`@moduledoc` / `@doc` / `@spec` 是给工具和文档用的。
  自定义属性（`@max_retries 3`）也行，但**属性是「读取即快照」**：`@x 1` 之后 `@x` 的值
  被固定，后面再 `@x 2` 是重新定义而不是修改（23 章宏那里会用到这个语义）。
- **`@spec` 不在运行时检查** —— 它是给 Dialyzer 看的类型标注（23 章）。写错了类型，
  程序照样跑；只有跑 Dialyzer 才会告诉你。

### arity 是函数名的一部分

```elixir
def greet(name), do: "你好，#{name}！"
def greet(greeting, name), do: "#{greeting}，#{name}！"
```

`greet/1` 与 `greet/2` 是**两个不同的函数**，不是同一个函数的重载。Erlang/Elixir 的
函数标识是 `模块:名字/arity` 三元组。实测：

```text
greet/1 已导出         => true
greet/3 已导出         => false
```

这个设计是第 04 章的基础：**同名同 arity 的多个子句**（用模式匹配区分）才是 Elixir
表达分支的方式，而不是 `if/else` 一把梭。

### 默认参数会生成多个 arity

```elixir
def f(a, b \\ 1), do: a + b
```

编译器实际生成 `f/1` 和 `f/2` 两个函数。所以**默认参数与多子句混用是个经典陷阱**：
子句之间不能各自写默认值，得单独抽一个「函数头」声明默认值（05 章展开）。

## 2.4 文档属性：`h` 命令是 Elixir 的杀手级体验

```elixir
@moduledoc """
...
    iex> Ex02Hello.hello()
    "Hello, Elixir!"
"""

@doc """
`render/1` 的说明……

    iex> Ex02Hello.render({1, 2})
    {"(不可插值)", "{1, 2}"}
"""
```

在 `iex` 里：

```elixir
h Ex02Hello             # 打印 moduledoc
h Ex02Hello.render/1    # 打印某个函数的 doc
h Enum.map/2            # 标准库文档同样可查，无需上网
i "hello"               # inspect 一个值，列出类型、字节数、协议实现
v(1)                    # 取历史第 1 条结果
```

文档里以 `iex>` 开头的代码块可以被 **doctest** 直接当测试跑：

```elixir
defmodule Ex02HelloTest do
  use ExUnit.Case, async: true
  doctest Ex02Hello        # 就这一行，moduledoc/doc 里的 iex> 例子全变成断言
end
```

实测本示例的 2 个 doctest + 6 个 test 全绿。**文档即测试**是 Elixir 生态的强约定：
文档里的例子说谎会立刻被 CI 抓住。这也解释了一条格式细节——doctest 的输出行必须
顶格写，且比较的是 `inspect` 后的文本，所以 `{"(不可插值)", "{1, 2}"}` 里的空格
（`{1, 2}` 而非 `{1,2}`）必须与 `inspect` 的真实输出逐字符一致。

## 2.5 插值 vs inspect：两条不同的协议

`"#{x}"` 与 `inspect(x)` 看起来都是「把值变成字符串」，走的却是两套完全不同的协议：

| | `"#{x}"` / `to_string/1` | `inspect/1` |
|---|---|---|
| 协议 | `String.Chars` | `Inspect` |
| 谁实现了 | Atom、BitString、Integer、Float、List、Date/DateTime 等「能当文本看」的类型 | **所有**类型 |
| 输出取向 | 给人读的**内容** | 给程序员读的**源码形式** |
| 遇到元组/map | 抛 `Protocol.UndefinedError` | 正常输出 `{1, 2}` / `%{a: 1}` |

实测对照（摘自 `run.exs` 输出）：

```text
  inspect => "文本"        插值 => "文本"
  inspect => :ok           插值 => "ok"
  inspect => nil           插值 => (空串)
  inspect => 42            插值 => "42"
  inspect => 3.5           插值 => "3.5"
  inspect => true          插值 => "true"
  inspect => {1, 2}        插值 => (不可插值)
  inspect => %{a: 1}       插值 => (不可插值)
  inspect => [1, 2, 3]     插值 => <<1, 2, 3>>
  inspect => ~c"hi"        插值 => "hi"
```

四条必须记住的结论：

1. **`nil` 插值是空串**，不是 `"nil"`。日志里 `"value=#{x}"` 打出 `value=` 就是它。
2. **元组和 map 不能插值**，`"#{%{a: 1}}"` 当场抛异常——不是返回什么怪东西，是直接崩。
3. **列表插值按 charlist 解释**。`~c"hi"` 是 `[104, 105]`，插值得到 `"hi"`；而
   `[1, 2, 3]` 插值得到 3 个字节的二进制 `<<1, 2, 3>>`，里面是控制字符。
   测试里就是靠 `byte_size(interpolated) == 3` 把这条钉住的。
4. 所以本教程的纪律是：**打印结构一律 `inspect`**，只有在确定是文本时才用插值。

`inspect/2` 有常用选项：`inspect(x, limit: 5, printable_limit: 32, pretty: true, structs: false)`。
调试深层嵌套结构时 `pretty: true` 会换行缩进；`limit: :infinity` 让大列表不被截断成 `[...]`。

## 2.6 `{:ok, _}` / `{:error, _}`：预期内的失败不靠异常

```elixir
@spec parse_age(String.t()) :: {:ok, non_neg_integer()} | {:error, :invalid_age}
def parse_age(text) when is_binary(text) do
  case Integer.parse(String.trim(text)) do
    {age, ""} when age >= 0 -> {:ok, age}
    _ -> {:error, :invalid_age}
  end
end
```

实测：

```text
parse_age("  42 ") => {:ok, 42}
parse_age("0") => {:ok, 0}
parse_age("-1") => {:error, :invalid_age}
parse_age("12abc") => {:error, :invalid_age}
parse_age("") => {:error, :invalid_age}
```

三个知识点藏在里面：

- **`when is_binary(text)` 是卫语句**（guard），限制哪些参数能进这个子句。
  传个 `123` 进来会得到 `FunctionClauseError`——不是返回 `{:error, ...}`。
  「类型不对」是编程错误（该崩），「格式不对」是预期内失败（返回 error 元组）。
- **`Integer.parse/1` 的返回形状**是 `{整数, 剩余字符串}`，解析失败返回 `:error`。
  所以 `{age, ""}` 这个模式在说「整个字符串都被吃掉了」。`"12abc"` 会匹配到
  `{12, "abc"}`，落到 `_` 兜底子句——这正是我们想要的严格行为。
- **元组返回是这个语言的默认错误处理方式**。11 章会讲 `try/rescue`，但那是给
  「真正意外」准备的；日常代码里 `case`/`with` 配 `{:ok, _}`/`{:error, _}` 才是主线。

## 2.7 模块自省：`__info__/1`

每个模块编译后自动带一组内省函数：

```elixir
Ex02Hello.__info__(:functions)   # 导出的 {名字, arity} 列表
Ex02Hello.__info__(:macros)      # 导出的宏
Ex02Hello.__info__(:module)      # 模块名原子
Ex02Hello.__info__(:attributes)  # 模块属性（含 :vsn、behaviour 等）
Ex02Hello.module_info(:compile)  # Erlang 层的编译信息（含编译器版本）
```

实测输出：

```text
__info__(:functions) => 7 个导出函数
  doubled/1
  greet/1
  greet/2
  hello/0
  main/1
  parse_age/1
  render/1
__info__(:module)    => Ex02Hello
__info__(:macros)    => []
module_info(:compile)[:version] 存在 => true
```

排查「函数明明写了却报 `UndefinedFunctionError`」时，第一件事就是看 `:functions`——
**`defp` 的函数不在里面，从模块外调不到**；同理，拼错 arity（`greet/3`）也不在里面。

`module_info(:compile)` / `__info__(:compile)` 里装的是**编译环境**信息，实测三项：

```elixir
[
  version: ~c"10.0.2",        # 编译它的 Erlang/OTP 编译器版本（charlist，不是 Elixir 版本）
  options: [:no_spawn_compiler_process, :from_core, :no_core_prepare, :no_auto_import],
  source: ~c"/绝对路径/…/lib/ex02_hello.ex"   # 源文件的绝对路径
]
```

注意 `version` 是 **OTP 编译器**版本（`~c"10.0.2"`），跟 Elixir 版本不是一回事；
`source` 更是**本机绝对路径**。示例里刻意只断言 `has_key?(:version)` 而不打印这些值：
本教程所有示例的输出都要能在两台不同机器上**逐字节一致**（`run-all.sh` 第 5 层会把
同一份 BEAM 钉成单调度器重跑一遍做比对），把版本号或绝对路径打进去就破坏了这条纪律。
想知道 Elixir 版本请用 `System.version()`（或命令行 `elixir --version`）。

## 2.8 坑位清单

1. **`IO.puts` 把中文打成 `\x{7ED3}\x{675F}`**：BEAM 的 `:standard_io` 编码取自系统
   locale，`LANG`/`LC_ALL` 都没设时退回 `:latin1`，码点 > 255 的字符一律转义成
   `\x{...}` 字面量。**实测**：`LANG` 未设时 `:io.getopts(:standard_io)[:encoding]`
   是 `:latin1`。解法两选一：
   - 脚本首行 `:io.setopts(:standard_io, encoding: :utf8)`（本教程全部示例这么做，
     与 locale 彻底解耦）；
   - 或导出 `LC_ALL=en_US.UTF-8`。
   注意 **`LANG=C.UTF-8` 在 macOS 上无效**（实测仍然转义），`ERL_FLAGS="+fnu"` 也无效
   ——`+fnu` 只管**文件名**编码，不管 stdio。Windows 上还得让控制台用 UTF-8 码页
   （`chcp 65001`，`build.ps1` 已代做）。

2. **模块名与文件名的约定**：`Ex02Hello` → `lib/ex02_hello.ex`。语法上并不强制
   （一个文件可以定义任意多个模块，文件名也能乱起），但 `mix` 的编译追踪、
   `Code.fetch_docs/1` 的文档定位、以及 IDE 跳转都依赖这条约定。破坏它的后果是
   「文档查不到」「改了文件不重编」这类难查的怪事。

3. **未使用的 `defp` / 未使用的变量都是编译告警**：`--warnings-as-errors` 下等于
   编译失败。想在示例里演示「错误路径」时，必须让编译器看不出结果——所以本教程
   示例里的输入一律来自函数参数，不写常量。

4. **`mix run -e '...' a b` 的参数被 mix 吃掉**：必须写 `mix run -e '...' -- a b`，
   `--` 之后才归 `System.argv()`。

5. **`@spec` 写错不会报错**：运行时完全不检查，只有 Dialyzer（23 章）会抓。
   把 `@spec` 当注释看是危险的，它会被 doctest 之外的工具当真。

6. **doctest 的输出必须逐字符等于 `inspect` 的结果**：`{1, 2}` 中间那个空格不能省。
   手写 doctest 时先在 `iex` 里跑一遍把真实输出粘过来，别凭记忆写。

7. **`.exs` 不产出 `.beam`**：在 `run.exs` 里 `defmodule` 定义的模块只活在这一次运行里。
   想复用就放 `lib/*.ex`。反过来，`mix.exs` 里也不能定义业务模块——它每次都被重新求值。

8. **`start_permanent` 只在 `:prod` 生效**：开发模式下未匹配的调用只打日志，
   于是「本地好好的、上线就崩」。要提前暴露，用 `MIX_ENV=prod mix run`。

---

下一章：[03 · 基础类型与不可变性](03-types.md)
