# Elixir 速查表（Elixir 1.20.2/1.20.4 · OTP 29 · macOS + Windows 双轨实测版）

## 运行与工具

```bash
mix new app                       # 建工程（教程示例为手写同结构）
mix compile                       # 编译；--warnings-as-errors 零告警
mix format                        # 格式化；--check-formatted 只检查
mix test                          # ExUnit；--failed 只跑失败
mix run run.exs                   # 跑脚本；--no-compile 跳过编译
iex -S mix                        # 交互：h 查文档 / i 查 term / r 重编译 / recompile
MIX_ENV=prod mix release          # 自包含发布；bin/app eval "..." 一次性求值
mix escript.build                 # 单文件可执行（目标机需 Erlang）
./run-all.sh 24_capstone          # 本教程：单章五层验证；不带参数=全部
```

## 语法速查

```elixir
# 不可变数据；= 是模式匹配（不是赋值）
{x, y} = {1, 2}
{:ok, value} = do_something()          # tagged tuple：成功/失败的标准形状
:ok = result                           # 不匹配即 MatchError——零成本断言
^x = value                             # pin：比较 x 的已有值，而不是重新绑定

# 原子与字符串
:error            "hello" <> rest = greeting
~r/[^\p{L}\p{N}]+/u                     # 正则 sigil；\p{L} 覆盖中文
~D[2026-09-21]  ~U[2026-09-21 08:00:00Z]

# 函数
def add(a, b), do: a + b
defp secret(x), do: x                   # 私有
square = fn x -> x * x end              # 匿名函数；调用 square.(8)
inc = &(&1 + 1)                          # 捕获语法；&Mod.fun/arity
def join(a, b, sep \\ ", ")             # 默认值：先写函数头

# 多子句 + 守卫（白名单，出错只让子句落选）
def fact(0), do: 1
def fact(n) when is_integer(n) and n > 0, do: n * fact(n - 1)

# 控制流
case x do
  {:ok, v} when v > 0 -> v
  _ -> 0
end

with {:ok, a} <- step1(x), {:ok, b} <- step2(a), do: {:ok, b}  # <- 失败短路

# Enum 与管道（管道是宏：a |> f(b) 即 f(a, b)）
[1, 2, 3] |> Enum.map(&(&1 * 2)) |> Enum.reduce(0, &+/2)
Enum.frequencies(tokens)                # map 顺序不承诺——打印先 sort
for x <- 1..3, rem(x, 2) == 0, do: x    # 推导式

# 集合
kw = [timeout: 500]                     # Keyword：有序、可重复键
m = %{a: 1}; m = %{m | a: 2}            # map 更新（键必须已存在）
defmodule User do
  defstruct name: "匿名", age: 0        # struct = map + __struct__
end

# 协议
defprotocol Size do
  @doc "返回元素个数"
  def size(data)
end

defimpl Size, for: User do
  def size(%User{age: age}), do: age
end

# 进程：三支柱——spawn / send / receive
spawn(fn -> send(parent, {:reply, 42}) end)

receive do
  {:reply, n} -> n
after
  1000 -> :timeout
end

# 并发与状态（监督树组装块）
task = Task.async(fn -> heavy() end)
Task.await(task, 5000)                  # 任务崩=调用方 exit（不是 raise）
{:ok, pid} = Agent.start_link(fn -> %{} end)
Agent.get(pid, &Map.get(&1, :k))
GenServer.call(pid, {:put, :k, 1})      # cast 无回复；handle_info 必须有兜底
```

## 坑位索引（按章）

| # | 坑 | 章 |
|---|---|---|
| 1 | stdout 默认随 locale 退回 latin1，中文变 `\x{...}`；脚本首行 `:io.setopts(:standard_io, encoding: :utf8)`（`LANG=C.UTF-8`、`+fnu` 实测无效） | 02 |
| 2 | 模块名↔文件名约定 `Ex02Hello`→`lib/ex02_hello.ex`；不强制但 mix 编译追踪、release 打包都靠它 | 02 |
| 3 | `/` 恒返回浮点，整除用 `div/2`（向零截断）；精确整数幂用 `Integer.pow/2` | 03 |
| 4 | 外部输入别 `String.to_atom/1`：原子表只增不减（上限约百万）；用 `to_existing_atom` | 03 |
| 5 | 假值只有 `nil` 和 `false`：`0`、`""`、`[]` 全真，`if list` 判不了空列表 | 03/06 |
| 6 | `=` 失配直接抛 `MatchError`，没有静默 undefined；`:ok = result` 是断言惯用法 | 04 |
| 7 | 模式里裸变量永远是绑定——漏写 `^` 不报错只悄悄重绑；同名变量再现是相等约束 | 04 |
| 8 | 匿名函数调用必须带点 `f.(x)`；默认参数写函数头，且同时产生 `/2`、`/3` 两个 arity | 05 |
| 9 | 守卫是白名单、出错只让子句落选；子句顺序即优先级，兜底写最后（1.20 告警不可达） | 05 |
| 10 | 递归返回后还有运算就不是尾调用；要 TCO 把待算值放进累加器 | 05 |
| 11 | `case`/`cond` 兜不住分别抛 `CaseClauseError`/`CondClauseError`；`with` 里用 `<-` 才是短路 | 06 |
| 12 | map 遍历顺序不属于语言承诺（32 键是 flatmap/hashmap 分界）；打印断言先 sort | 07/09 |
| 13 | `dedup` 只压相邻重复、`uniq` 才全局；shuffle/random 只断言性质（是排列），不打印具体值 | 07 |
| 14 | 三个长度别混：`byte_size` 字节 / codepoints 码点 / `String.length` 字素 | 08 |
| 15 | NFC/NFD 同文本字节不同，`==` 失效——用 `String.equivalent?`；按字节截串得到非法 UTF-8；大小写转换不可逆 | 08 |
| 16 | Keyword 是线性表 O(n)、允许重复键；Struct 不实现 Access（`u[:id]` 崩），用点语法 | 09 |
| 17 | `defimpl` 必须实现协议全部函数；struct 必须先定义再 impl；struct 默认不实现 Enumerable/Chars（Inspect 永远有） | 10 |
| 18 | reason 要是数据不是字符串（`{:error, {:out_of_range, n}}`）；带 `!` 失败必 raise 是契约 | 11 |
| 19 | `catch` 有 throw/exit/error 三类，写两元素子句区分；不要在库深处 rescue——那是拆监督树的保险丝 | 11 |
| 20 | `spawn(Mod, fun, args)` 要求函数已导出，defp 会运行时报错；无 `after` 的 receive 永久挂起 | 12 |
| 21 | call 模式消息必须自带回程 pid（`from = self()` 在 spawn 外取）；多发送方收齐排序或引用配对 | 12 |
| 22 | 1.20 任务崩溃 = 调用方进程 exit，`try/rescue` 接不住；trap_exit + yield 才能同进程收口 | 13 |
| 23 | `await` 超时同样杀调用方；yield 返回 `{:exit,_}` 有前提（:normal/trap/nolink）；超时要 `Task.shutdown` 收尾 | 13 |
| 24 | Agent 回调别做重活（全客户端共用一个进程）；get 后 update 不原子，读改写用 `get_and_update`；重启状态归零 | 14 |
| 25 | `handle_call` 必须 reply、cast/info 必须 noreply；`handle_info` 必须有 `_unknown` 兜底 | 15 |
| 26 | call 超时只杀调用方、取消不了服务端的活儿，慢回复还会到达；回调必须快，慢活拆 Task | 15 |
| 27 | 生成的 child_spec 只有 `:id`/`:start`；map 写法的 `:start` 是完整 MFA，`start_link(kw)` 对应 `{Mod,:start_link,[[kw]]}` | 16 |
| 28 | doctest 里正则反斜杠要双写（heredoc 吃一层）；二进制变长字段只能在末尾，默认大端无符号 | 17 |
| 29 | Stream 不接终点操作永不执行；无限流必须有 take/take_while 短路；惰性链中间别插 Enum | 18 |
| 30 | `File.read` 是 tagged tuple；行流保留换行符（末行没有）；`File.ls` 顺序不定必须 sort | 19 |
| 31 | 四类日期结构不混用；`Date.range` 是结构体不是列表（`length` 崩，用 Enum.count）；1.20 逆序必须显式 `-1`；ISO 周一=1；零依赖唯一时区 `"Etc/UTC"` | 20 |
| 32 | `capture_io`/`capture_log` 不随 ExUnit 导入；`send/2` 返回消息，替身要显式返回 `:ok`；Logger 宏要 `require`、异步要 `flush`；ExUnit 用例顺序随机，断言别依赖跨用例累积（setup_all 共享态只放可复用资源）；escript 无 `--path`、`mix run` 无 `--quiet`；quote 里用 `unquote(__MODULE__)`；`@spec` 无运行时强制；async 任务仍 link 调用方，`:kill` 不可 trap；重启清空内存态是契约 | 21–24 |
| 33 | Windows：git `core.autocrlf=true` 检出把源文件变 CRLF，`mix format --check-formatted` 全挂——`elixir/.gitattributes` 强制 `* text=auto eol=lf`，工作区就地转回 LF | 全部 |
| 34 | Windows：raw 文件 `:file.pread` 会把顺序指针挪到读末尾（Unix 不动位置）——别依赖 pread 后的顺序位置，跨平台要显式 `:file.position` | 19 |
| 35 | Windows：escript 产物无扩展名非 PE，直接 spawn `:eacces`，须经 `System.cmd("escript", [path])` 运行；`System.cmd("mix")`/release `bin/app` 能自动解析到 `.bat` 无需处理 | 22 |
| 36 | 1.20.4 类型检查器比 1.20.2 较真：`assert is_struct(字面量构造)` 重写出的失败分支被判不可达而告警（测试层 stderr 非空）——用 `struct/2` 动态构造抹掉静态类型 | 03 |
| 37 | 结构共享实证须用运行时构建的列表（`Enum.to_list`）：字面量住在 BEAM 只读字面量区，`tl/1` 与模式匹配取出的子项指针随求值上下文漂移；`[0] ++ base` 被编译器重写为 cons 照样共享——证「++ 复制左表」必须变量作左操作数 | 25 |
| 38 | doctest 里空行切断变量作用域（两组 `iex>` 是两个独立会话，「undefined variable」）；重绑前先读一次旧值，否则首次绑定是死代码（unused variable 告警挂零告警门禁）——doctest、测试、run.exs 三处同规矩 | 25–28 |
| 39 | 闭包三坑：匿名函数必须 `.()` 调用（`flat(1000)` 找的是具名函数）；`upcase = String.upcase` 是调用零参版本不是取引用（要 `&String.upcase/1`）；`&` 造不出零参函数（`&(true)` 编译错，零参只有 `fn -> ... end`） | 26 |
| 40 | 守卫里不能调用闭包（`when cmp.(a, b)` 编译错——白名单纯函数 only），比较器分派用 if/case；列表对半切用 `div(Enum.count(l), 2)`，`/ 2` 出浮点 `Enum.split` 不收 | 27 |
| 41 | 同一模块 import 两次，后者**替换**前者（`only:` 合并成一次写全）；自定义运算符宏（如 `~>>`）在测试/doctest/iex 使用处都必须先 `import` 定义模块 | 28 |
| 42 | 多值返回按参数顺序（`Battle.fight/2` 返回 `{A 终态, B 终态, 战报}`，解构反了英雄变怪物）；`function_exported?/3` 对未加载模块恒 false（批量验契约先 `Code.ensure_loaded!`）；`Map.values/1` 顺序不保证，「全集」要输出顺序就自持 `@order` 键表 | 29 |

## 验证命令

```bash
cd elixir
./run-all.sh                  # 全部示例：五层验证
./run-all.sh 12_processes     # 单个示例
./run-all.sh --clean          # 清理 build/
pwsh ./build.ps1 -All         # PowerShell 等价入口
```

五层：`mix format --check-formatted` → `mix compile --warnings-as-errors`
→ `mix test` → `mix run run.exs`（退出码 0 / stderr 空 / stdout 非空 /
含 `==== NN 结束 ====`）→ `ERL_FLAGS="+S 1:1"` 重跑且 stdout 逐字节一致。
例外：`11_errors` 故意写 stderr（run-all.sh 的 `STDERR_ALLOW`）。
