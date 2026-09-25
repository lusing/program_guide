# 附录 · Erlang ↔ Elixir 双语言对照

> 取材《Erlang and Elixir for Imperative Programmers》（Wolfgang Loder）
> 第 2 章「From Erlang to Elixir」与附录 D 的速查精神。
> 本仓库的双教程互为镜像：Erlang 篇（本目录）32 章、
> [Elixir 篇](../../elixir)29 章——同一台 VM（BEAM）、同一套 OTP、
> 两种表层语法。

两种语言**字节码互通**：Erlang 的模块 Elixir 直接调用、反之亦然。
选语言选的是语法品味与生态（Phoenix vs 纯 Erlang 的电信库），不是
选运行时——进程、消息、监督树、let it crash 在两边一字不差。

## A.1 表层语法逐点对照

| 概念 | Erlang | Elixir |
|---|---|---|
| 注释 | `%% 注释` | `# 注释` |
| 变量绑定 | `X = 1.`（大写开头；一次绑定） | `x = 1`（小写开头；可重绑） |
| 原子 | `ok`、`'带空格的'` | `:ok`、`:"带空格的"` |
| 模块 | `-module(m).` + 语句以 `.` 结尾 | `defmodule M do` ... `end` |
| 函数 | `f(X) -> X.`（按参数个数分派） | `def f(x), do: x`（按参数个数分派） |
| 匿名函数 | `fun (X) -> X end`，调用 `F(1)` | `fn x -> x end`，调用 `f.(1)` |
| 捕获语法 | `fun lists:sum/1` | `&List.sum/1`、`&(&1 + 1)` |
| 多子句 | 函数头并列 + `;` | `def f(0), do: ...` 多个 def |
| 守卫 | `f(X) when X > 0 -> ...` | `def f(x) when x > 0` |
| 模式匹配 | `{:ok, V} = R`（tuple 固定元数） | `{:ok, v} = r` |
| 列表 | `[1, 2 | Tail]` | `[1, 2 | tail]` |
| 映射 | `#{k => 1}`、更新 `M#{k := 2}` | `%{k: 1}`、更新 `%{m | k: 2}` |
| 字符串 | 二进制 `<<"utf8">>` / 码点列表 `"list"` | 二进制 `"utf8"`；charlist `'list'` |
| 字符 | `$a`（整数） | `?a`（整数） |
| 推导式 | `[X * 2 || X <- L]` | `for x <- l, do: x * 2` |
| case | `case X of P -> ... end` | `case x do p -> ... end` |
| 管道 | 无（嵌套调用） | `x |> f(y)`（宏） |
| 记录 | `-record(name, {f}).` 预处理为元组 | 无（struct 是带 `__struct__` 的 map） |
| 宏 | 少用（parse_transform 黑魔法） | 一等公民（`defmacro`） |
| doctest | 注释里手写 | ExUnit 一等公民 |

## A.2 互不相同的心智点

**变量**：Erlang 变量一次绑定后不可重绑（`X = 1, X = 2` 报错，要
`X1 = 2`）；Elixir 允许重绑（`x = 1; x = 2` 合法），但数据同样不可变
——重绑只是换个名字指新值。Erlang 派觉得重绑藏 bug，Elixir 派觉得
`X1 X2 X3` 丑——BEAM 不管这场架，两边都是单赋值语义在数据层。

**默认参数/多子句**：Erlang 的多子句是**函数头**级的（最后一个 `;`
收尾）；Elixir 每个子句一个完整 `def`，且支持 `\\` 默认参数。

**import 与作用域**：Erlang 的 `import` 是模块级编译期指令；Elixir
的 `import` 可进任意作用域块、且**第二次 import 替换第一次**（Elixir
教程 28 章实测坑）。

**字符串默认**：Erlang 的 `"..."` 是码点列表（性能陷阱，日常用
二进制）；Elixir 的 `"..."` 就是二进制、charlist 要单引号。跨语言
调用时这是头号坑：Erlang 函数期望列表字符串时，Elixir 侧要传
`'charlist'`。

**协议 vs 行为**：Elixir 的 `defprotocol` 是**数据侧**多态（按值的
类型运行时分派）；behaviour 两侧通用、是**模块侧**契约
（`@callback`/`@behaviour`，与 Erlang 的 `-callback`/`-behaviour`
同源）。

## A.3 OTP 对照

| OTP 概念 | Erlang | Elixir |
|---|---|---|
| 通用服务器 | `gen_server` + `handle_call/3` | `GenServer` + `handle_call/3` |
| 状态机 | `gen_statem`（29 章） | 无官方封装（社区库） |
| 事件管理器 | `gen_event`（29 章） | 无官方封装（`:gen_event` 直接用） |
| 监督者 | `supervisor` + child_spec | `Supervisor`、`use GenServer` 自动 child_spec |
| 应用 | `.app` 文件 + `application` | `mix` 生成 `application.ex` |
| 任务 | `rpc`/裸 spawn | `Task`（async/await 一等公民） |
| 测试 | EUnit / Common Test（21 章） | ExUnit（doctest 内建） |
| 构建 | `erlc` + `make`（本教程）/ rebar3 | `mix`（事实标准） |

## A.4 互通调用

```erlang
%% Erlang 调 Elixir：模块名是原子 'Elixir.模块名'
'Elixir.Enum':sum([1, 2, 3]).
```

```elixir
# Elixir 调 Erlang：:模块名
:lists.sum([1, 2, 3])
```

规则只有一条：**对方模块名加/去 `Elixir.` 前缀**。字节码层面无摩擦；
坑集中在字符串类型（列表 vs 二进制）与字符字面量（`$a` vs `?a`）。

## A.5 选型与学习路径

- 先学哪个都行——**OTP 概念是主体，语法是皮**。本仓库的两份教程
  刻意同构（同验证标准、同章型、同坑位清单格式），交叉读对照最快。
- 现实生态：并发/电信/嵌入式倾向 Erlang；Web/创业栈倾向 Elixir
  （Phoenix、Ecto）。
- 一条经验：能在 Erlang 里读懂 Elixir 的模块名（`Elixir.` 前缀）、
  能在 Elixir 里调 `:lists`，就拿到了整个 BEAM 的库——两边加起来
  才是全部家当。

---

[← 32 章·文本侦探](32-sherlock.md) · [返回 README](../README.md)
