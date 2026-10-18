# 01 · 全景：Erlang/OTP 是什么、凭什么、用什么

## 1.1 设计哲学：让它在崩之后还能活

Erlang 出生于 1986 年爱立信的电话交换机项目，目标是**九个九的可用性**（99.9999999%——年停机 31ms）。电话交换机不能停机重启，所以 Erlang 把"出错怎么办"做进了语言而不是库：

| 别的语言里你手搓的 | Erlang 里是语言/运行时自带的 |
|---|---|
| 线程 + 锁 + 线程池 | **进程**：微秒级创建、每个几 KB、不共享内存（13 章） |
| 消息队列 / RPC 框架 | `!` 发消息 + 每进程独有邮箱，**选择性接收**（13 章） |
| try/catch 套满全代码 | **let it crash**：能崩的让它崩，错误分层处理（12 章） |
| K8s/SYSTEMD 拉起重启 | **supervisor**：粒度到单个进程的重启策略（16 章） |
| Spring/框架骨架 | **behaviour**：gen_server 等回调契约（15 章） |
| 蓝绿发布 | **热代码加载**：运行中换代码，两版本规则（23 章） |
| Prometheus/日志系统 | logger 分级过滤 + 内省内省（22 章） |

一句话：**并发是进程、容错是监督树、一切皆是消息**。WhatsApp 用几十台机器扛十亿连接、RabbitMQ、WhatsApp、Discord 的网关层都是这套模型的成绩单。

## 1.2 版本演进：近五年值得记住的节点

老教程大多停在 OTP 20 时代的写法，先对齐时间线（本教程全部在 **OTP 29.1.1（erts 17.x）** 实测）：

| 版本 | 年份 | 你会用到的 |
|---|---|---|
| 24 | 2021 | EUnit 头文件自动导出测试（21 章） |
| 25 | 2022 | `maybe ... else ... end` 作为**实验特性**引入（默认关，要显式开 feature `maybe_expr`）；map 更新 `:=` 放宽 |
| 26 | 2023 | `json` 模块进标准库；多核 GC 改进 |
| 27 | 2024 | **`maybe` 转正、默认启用**（12 章）——代价是 `maybe` 从此成了保留字，不能再当原子用（12 章）；**三引号字符串**与 **sigil**（`~b`/`~s` 等，09 章）；相邻字符串字面量之间没空白变成语法错；`erl -eval` 起的进程 `trap_exit` 默认 true（14 章实测）；`timer` 模块内部大改（20 章）；`filelib:fold_files` 废弃 |
| 28/29 | 2025–26 | `catch Expr` 裸写**编译失败**（12 章）；logger 过载保护强化（22 章） |

> ⚠️ 网上教程三大化石：`catch X`（已废弃，用 `try`）、`{ok, Fd} = file:open(...)` 后忘 raw 模式限制（19 章）、拿 `os:timestamp()` 当时间戳（20 章：单调钟才是对的）。

## 1.3 工具链一览：erl + erlc 就是全家桶

```powershell
erl -version                                 # 版本
erlc -Wall -Werror -o build/02_hello 02_hello.erl   # 编译成 .beam
erl -noshell -pa build/02_hello -run '02_hello' main -s init stop  # 跑
erl                                          # 进 REPL（Ctrl+C 两下退出）
erl -noshell -eval 'io:format("hi~n"), halt().'     # 单行求值
escript foo.erl                              # 直接跑脚本（免编译）
dialyzer --build_plt --apps erts kernel stdlib      # 静态分析（23 章）
```

没有包管理器捆绑：教程只用标准库，`erl` + `erlc` 两个命令足够；真实工程用 rebar3（本教程不依赖）。本机安装：scoop 的 `G:\scoop\apps\erlang\current\bin\`。

## 1.4 一个程序长什么样

```erlang
-module(hello).          %% 一个 .erl 文件 = 一个模块，名字必须与文件名一致
-export([main/0]).       %% 显式契约：没导出的函数外界看不见

main() ->
    io:format("你好，Erlang/OTP 29！~n").
```

编译产物 `.beam` 跑在 BEAM 虚拟机上——同一份 beam 在 Windows/Linux/macOS 都能跑。这门语言**没有循环语句、变量只绑定一次**，前三章会颠覆写字习惯，但换来的是：并发代码不需要锁、崩溃可以精确观测。

## 1.5 保留字：这 29 个词不能当原子用

Erlang 的保留字就这么多，一次背完（官方语言参考手册的完整列表）：

```text
after    and      andalso  band     begin    bnot     bor      bsl      bsr
bxor     case     catch    cond     div      else     end      fun      if
let      maybe    not      of       or       orelse   receive  rem      try
when     xor
```

三条与你直接相关的：

- 其中 **`cond` 与 `let` 是"占位"保留字**——保留下来但语言里至今没有对应语法，你既不能用它们、也不用担心哪天撞车；
- **`maybe` 自 OTP 27 起才真正生效**（12 章）：OTP 25 它是实验特性、OTP 26 还要显式开 feature，OTP 27 起默认启用——从那一刻起它就成了保留字；
- 保留字**不能再当原子**。想用就得加引号变引号原子：`'maybe'`、`'end'`、`'if'` 都是合法原子，写 `maybe` 则直接编译报 `syntax error before: 'maybe'`（12 章有实测）。

需要注意 `andalso`/`orelse` 与 `and`/`or` 是两回事（前者短路），`band`/`bor`/`bxor`/`bnot`/`bsl`/`bsr` 是位运算——别把它们当成"保留了就忘了用"（03 章讲运算符）。

## 1.6 本教程的走法

32 章（与 cpp20/zig/go 教程同一标准；25–32 为进阶篇）：

- **读讲解**——每章一个主题，全部结论在 OTP 29 上实测过；
- **跑示例**——`examples/NN_topic/` 与章号对应，`build.ps1` 四层验证（编译零警告 → EUnit → 运行四条判定 → 单调度器双通道逐字节一致）；
- **改代码再跑**——每章末尾的"坑位清单"收录了 90+ 条实测坑中与本章相关的部分。

Erlang/OTP 的灵魂全部独立成章细讲：进程与消息（13/14）、gen_server / supervisor / application 三连（15–17 ⭐）、ETS（18）、测试与 dialyzer（21/23）。第 24 章把它们组装成一个带监督树和 worker 进程池的 mini-grep；
第 25–32 章补上分布式、套接字、端口、持久化、两种行为、剖析、多核，
最后以纯函数的文本侦探收官（32 章）。

## 1.7 坑位清单

1. **老教程的 `-behaviour` 拼写**：就是英式 behaviour，写成 behavior 虽也能识别，但社区统一前者。
2. **REPL 里 `q().` 与 `halt().`**：`q().` 优雅退出；Ctrl+C 两下是硬停——挂着 ETS/进程的演示用 `q().`。
3. **Windows 控制台中文乱码**：pwsh 7 默认 UTF-8 没问题；老式 cmd 先 `chcp 65001`（本仓库 build.ps1 已代设）。
4. **版本漂移**：OTP 22 之前的教程教的 `erlang:now/0`（已废弃，用 `erlang:monotonic_time/0`，20 章）、`rebar`（换 rebar3）看到就换教程。
5. **拿 Go/Rust 的直觉硬套**：Erlang 变量不可变、没有 null、没有继承——"对象"是进程，"调用"是消息，"异常处理"是监督树。前 12 章请先忘掉类。

---

---

下一章：[02 第一个程序](02-hello.md)
