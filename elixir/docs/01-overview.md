# 01 · Elixir 全景

> 对应示例：无（本章是地图；从 02 章起每章一个可编译的独立 mix 工程）

## 1.1 Elixir 是什么

Elixir 是一门跑在 **BEAM（Erlang 虚拟机）** 上的**函数式、并发优先**的语言，2012 年由
José Valim 发布。三个定语各拆一句：

- **函数式 + 不可变**：值一旦产生就不可修改，「更新」永远是「算出新值」（03 章）。没有类，
  数据与行为分开：用 struct 装数据、用 protocol 按类型分派行为（09/10 章）。分支不靠
  `if/else` 一把梭，而靠**同名函数的多个子句 + 模式匹配**（04/05 章）。
- **并发是原生能力，不是库**：BEAM 进程轻量到可以一台机器开几百万个，创建/切换是微秒级，
  每个进程内存独立、**不共享任何状态**，彼此只用消息通信（12 章）。这与操作系统线程、
  async/await 的协程都不是一个量级的抽象。
- **容错内建（let-it-crash）**：进程崩了不该被 `try/rescue` 捂着，而该让它**快速死掉、
  由监督者重启**。监督树（supervision tree）是语言级的故障隔离单元（15/16 章）。
  这套哲学来自 Erlang 在电信交换机里几十年的实战，目标是「系统永不重启，单个零件随便坏」。

与你会的语言对照：

| 你熟悉的 | Elixir 的不同 |
|---|---|
| C++/Java/Kotlin 的类与继承 | 没有类；struct（数据）+ protocol（多态）+ module（函数集合） |
| 共享内存 + 锁的多线程 | 独立内存的轻量进程 + 消息传递，默认就没有数据竞争 |
| `try/catch` 包打一切 | 预期内失败用 `{:ok, _}`/`{:error, _}`（02 章），意外才 raise（11 章） |
| `null` / `undefined` / `None` | 用原子 `nil`，且 `nil` 是真值判定里唯二的假值之一 |
| Python 的可变 list/dict | 列表是不可变链表；「改」永远返回新值 |
| Go 的 goroutine | BEAM 进程更轻（KB 级栈、按需增长），且自带监督树 |
| Node 的 async/await | 没有 async 染色——进程天然并发，`Task`/`GenServer` 是行为模板 |

## 1.2 血统与生态

Elixir 的本体价值大半来自它脚下的 **Erlang/OTP**：

- **Erlang** 1987 年由爱立信（Ericsson）内部发明，为电话交换机设计——要求全年停机时间以
  **秒**计、能在不停机的情况下升级代码、能承受单进程崩溃。1998 年开源。
- **OTP**（Open Telecom Platform）是 Erlang 的标准库与设计范式：`GenServer`、`Supervisor`、
  `Application`、监控、发布升级。名字带 Telecom，实则是通用的并发/容错框架。
- **Elixir** 复用了 Erlang 的全部运行时和标准库（两种语言可以无缝互调，`:erlang.xxx`
  直接可用），但提供了现代语法、宏（元编程）、`mix` 构建工具、`hex` 包管理器、`ex_unit`
  测试框架和一套好用的标准库。可以理解成「给 BEAM 换了一层 Ruby 气质的皮 + 一套现代工具链」。

生态关键件：

- **mix**：构建/依赖/任务一把梭（`mix new`、`mix test`、`mix deps.get`、`mix release`），22 章。
- **Hex**：包仓库；**Hex.pm**。本教程主线**零外部依赖**，全部用随 Elixir 发行的库，可离线。
- **iex**：REPL，`h/1` 查文档、`i/1` 查类型（02 章），是体验最好的内置文档系统之一。
- LiveView（服务端渲染的实时 Web）、Nerves（嵌入式）、Nx（数值计算/机器学习）是社区里
  最有代表性的方向，但都不在本教程范围。

## 1.3 本机工具链（实测）

| 项 | 本教程实测 |
|---|---|
| Elixir | 1.20.2 |
| Erlang/OTP | 29（erts-17.0.3，JIT） |
| 平台 | macOS（MacPorts 装于 `/opt/local/bin`）；Windows 用 `build.ps1`（scoop 装 Elixir） |
| 外部依赖 | **零**——所有示例 `deps: []`，全程离线可跑 |

验证环境：

```text
$ elixir --version
Erlang/OTP 29 [erts-17.0.3] [source] [64-bit] [smp:8:8] ...
Elixir 1.20.2 (compiled with Erlang/OTP 29)
```

安装（任选其一）：

```bash
brew install elixir        # macOS Homebrew
sudo port install elixir   # macOS MacPorts（本机即此）
# Windows：scoop install elixir，或用官方 installer
```

> **版本说明**：本教程在 **Elixir 1.20** 上实测。1.20 引入了渐进式**类型检查器**，会对
> 「字面量恒真判定」「跨不可比类型比较」等发出编译告警（03 章详述）。示例代码刻意写成
> 对这些告警免疫的形式，因此在 `--warnings-as-errors` 下也干净通过；用 1.17–1.19 跑同样
> 没问题，只是看不到那几条新告警。

## 1.4 四种运行方式（02 章逐一手把手）

| 方式 | 命令 | 用途 |
|---|---|---|
| REPL | `iex` | 探索表达式、`h` 查文档、`i` 看类型 |
| 工程 REPL | `iex -S mix` | 进 REPL 前先编译当前工程，自己的模块直接可用 |
| 脚本 | `elixir foo.exs` | 一次性小工具；`.exs` 在内存编译、不产字节码 |
| 工程 | `mix test` / `mix run` / `mix release` | 正经项目：依赖、测试、打包 |

本教程每章都是一个独立 mix 工程，结构固定：

```text
examples/NN_topic/
├── mix.exs          # 工程定义（app 名、版本、零依赖）
├── lib/exNN_topic.ex  # 业务模块（含 @doc 与 doctest）
├── run.exs          # 驱动脚本：mix run run.exs，打印本章全部实测
└── test/exNN_topic_test.exs  # ExUnit：doctest + 一批 test
```

## 1.5 统一验证：五层把关

每个示例都要同时过五层（`run-all.sh` / `build.ps1` 双入口，结论必须一致）：

1. `mix format --check-formatted`——2 空格风格；
2. `mix compile --warnings-as-errors`——零编译告警；
3. `mix test`——ExUnit（含 doctest）全绿；
4. `mix run run.exs`——真的跑一遍：退出码 0、stderr 空、stdout 非空、含结束标记
   `==== NN 结束 ====`；
5. `ERL_FLAGS="+S 1:1"` 单调度器重跑——stdout 与第 4 层**逐字节一致**。

第 5 层是本教程最硬的写作纪律：它逼着示例「断言性质」而不是「打印环境相关的数字」——
pid、reference、时间戳、map 迭代顺序在多调度器下都可能变，这些一律不打印。所以你看到的
每一份示例输出，在任何机器、任何调度器下都应当逐字节相同。

## 1.6 三个必须先建立的心智模型

在写第一行业务代码前，先接受三件事，后面会顺很多：

1. **「变量」是绑定，不是盒子。** `x = [1 | x]` 不是「把 x 塞进它自己」，而是让新名字
   `x` 指向「旧值前面加个头」的新列表。没有值被修改过。
2. **`=` 是模式匹配，不是赋值。** `{:ok, value} = result` 是在断言形状：右边不匹配就
   直接 `MatchError` 崩给你看。这是 Elixir 表达分支、解构、断言的核心机制（04 章）。
3. **崩溃是正常的控制流。** 当一个进程遇到「我不该处理的情况」，最健康的反应往往是
   让它崩，由监督者按策略重启，而不是层层 `rescue`、返回越来越多的特殊值。信任边界内
   靠监督，预期失败靠返回值——这是 11/16 章的主线。

## 1.7 本教程地图

| 章 | 主题 | 章 | 主题 |
|---|---|---|---|
| 02 | 第一个程序 / mix 工程解剖 | 13 | Task 并发 |
| 03 | 基础类型与不可变性 | 14 | Agent 状态 |
| 04 | 模式匹配 | 15 | GenServer |
| 05 | 函数与递归 | 16 | Supervisor 与 Application |
| 06 | 控制流（case/cond/if/with） | 17 | 正则与二进制模式 |
| 07 | Enum 与管道 | 18 | Stream 惰性流 |
| 08 | 字符串与 Unicode | 19 | 文件与 IO |
| 09 | 集合（Keyword/Map/Struct/MapSet） | 20 | 日期与时间 |
| 10 | 协议与行为 | 21 | 测试（ExUnit） |
| 11 | 错误处理与日志 | 22 | Mix 与 release |
| 12 | 进程与消息 | 23 | 宏与元编程 / 类型检查 |
| | | 24 | 收官：容错并发应用 |

读法建议：**先读正文 → 立刻 `cd examples/NN_topic && mix test && mix run run.exs` 跑一遍 →
改两行代码再跑**。每章末尾有「坑位清单」，把实测踩过的坑（编码、原子表、默认参数、
监督策略……）集中索引；全部坑位另有一份 `CHEATSheet.md` 速查。

---

下一章：[02 · 第一个程序](02-hello.md)
