# Erlang/OTP 编程指南（32）

给"会编程、初学 Erlang/OTP"的读者：从变量不可变、没有循环的语言地基，到进程/监督树/应用三件套，再到一个带 worker 池的 mini-grep；25–32 章按《Erlang 程序设计（第 2 版）》与《Erlang and Elixir for Imperative Programmers》两本书扩充进阶篇——分布式、套接字、端口、DETS/Mnesia、gen_event/gen_statem、剖析跟踪、多核并行，纯函数文本侦探收官。**读讲解 → 跑示例 → 改代码再跑**。

> ⚠️ 所有代码在 Erlang/OTP 29（erts 17.0.6）windows/amd64 实测；全部示例四层验证通过（erlc `-Wall -Werror` 零警告 → EUnit → 运行四条判定 → `+S 1:1` 单调度器双通道逐字节一致）。各章"坑位清单"收录了 90+ 条实测坑中与本章相关的部分。

## 目录结构

```text
erlang/
├── README.md            本文件
├── CHEATSheet.md        速查表（12 部分：命令/语法/坑位索引）
├── build.ps1            四层验证入口（pwsh 7）
├── docs/                01–32 章 + 双语言对照附录（01 概述，24 与 32 实战）
├── examples/            NN_topic/ 与章号对应（02–32 共 31 个）
│   ├── 02_hello/        每个示例：主模块 + *_tests.erl（EUnit）
│   ├── 17_application/  kvapp 四件套（.app + app/sup/store + 驱动）
│   ├── 21_testing/      含 ct21_SUITE.erl（示例里实跑 Common Test）
│   ├── 24_minigrep/     OTP 工程 + corpus/ 语料
├── 25_distributed/  ⚠ 需 -sname（build.ps1 已自动处理）
└── 32_sherlock/     收官：文本侦探
└── build/               编译与运行产物（不入库）
```

## 章节索引

| 章 | 主题 | 示例 |
|---|---|---|
| [01 概述](docs/01-overview.md) | 历史与工具链 | — |
| [02 第一个程序](docs/02-hello.md) | 模块、erl/erlc、格式串 | 02_hello |
| [03 数值与基本类型](docs/03-types.md) | 任意精度整数、原子、项序 | 03_types |
| [04 模式匹配与卫语句](docs/04-patterns.md) | 匹配即分派、guard 白名单 | 04_patterns |
| [05 递归与尾调用](docs/05-recursion.md) | 尾递归省 970 倍内存 | 05_recursion |
| [06 列表](docs/06-lists.md) | lists 模块与代价 | 06_lists |
| [07 fun 与推导式](docs/07-funs.md) | 一等函数、惰性序列 | 07_funs |
| [08 二进制与位语法](docs/08-binaries.md) | 变长报文解析 | 08_binaries |
| [09 字符串与 Unicode](docs/09-strings.md) | 三个"长度"、头号编码坑 | 09_strings |
| [10 映射与记录](docs/10-maps.md) | `=>` vs `:=`、迭代顺序随机 | 10_maps |
| [11 容器与配置结构](docs/11-collections.md) | proplists/sets/queue/array | 11_collections |
| [12 异常与错误哲学](docs/12-errors.md) | 三类异常、maybe、let it crash | 12_errors |
| [13 进程与消息](docs/13-processes.md) | 邮箱、ref 协议、pmap | 13_processes |
| [14 链接与监控](docs/14-links.md) | trap_exit、DOWN 形状 | 14_links |
| [15 gen_server ⭐](docs/15-gen-server.md) | 回调契约、先干活后回 | 15_gen_server |
| [16 supervisor ⭐](docs/16-supervisor.md) | 三种策略、重启强度 | 16_supervisor |
| [17 application ⭐](docs/17-application.md) | kvapp、env 快照、关闭顺序 | 17_application（工程） |
| [18 ETS](docs/18-ets.md) | 四种表、match spec、heir | 18_ets |
| [19 文件 I/O](docs/19-files.md) | 编码陷阱、二进制协议、序列化 | 19_files |
| [20 时间与定时器](docs/20-time.md) | 单调钟、timer 模块真相 | 20_time |
| [21 测试](docs/21-testing.md) | EUnit 断言/fixture、Common Test | 21_testing（含 CT suite） |
| [22 日志](docs/22-logger.md) | 四道关、过载保护 | 22_logger |
| [23 工具链](docs/23-tooling.md) | typespec/dialyzer、sys、热加载 | 23_tooling |
| [24 实战 mini-grep ⭐](docs/24-minigrep.md) | 监督树 + worker 池 | 24_minigrep（工程） |
| [25 分布式 Erlang](docs/25-distributed.md) | peer、rpc、global、cookie | 25_distributed |
| [26 套接字编程](docs/26-sockets.md) | 顺序/并行服务器、active 三态 | 26_sockets |
| [27 端口与外部接口](docs/27-ports.md) | escript 端口程序、帧协议 | 27_ports |
| [28 DETS 与 Mnesia](docs/28-dets-mnesia.md) | 磁盘表、事务、索引 | 28_dets_mnesia |
| [29 gen_event 与 gen_statem](docs/29-gen-event-statem.md) | 事件管理器、状态机 | 29_gen_event_statem |
| [30 性能剖析与跟踪](docs/30-profiling.md) | timer:tc、cprof、trace | 30_profiling |
| [31 多核并行](docs/31-multicore.md) | pmap 三变体、future | 31_multicore |
| [32 收官·文本侦探 ⭐](docs/32-sherlock.md) | 词频、重合度、bigram | 32_sherlock |
| [附录 Erlang↔Elixir 对照](docs/appendix-erlang-elixir.md) | 双语言速查、互通 | — |

## 构建工具链

- Erlang/OTP 29：scoop 的 `G:\scoop\apps\erlang\current\bin\`（erl/erlc/dialyzer/typer/ct_run 齐全；无 rebar3——教程只用标准库）
- pwsh 7（build.ps1 有中文输出，Windows PowerShell 5 读不了无 BOM 脚本）
- 编译统一 `+debug_info -Werror -Wall`（debug_info 是 dialyzer 的料，23 章实测 erlc 默认不带）
- 25_distributed 特判：EUnit 与运行层自动加 `-sname ex25_a`（peer 要求本节点是活节点）

## 验证命令

```powershell
cd erlang
pwsh ./build.ps1 -All                 # 23 个示例 × 四层验证（约 2 分钟）
pwsh ./build.ps1 -Example 15_gen_server
pwsh ./build.ps1 -Clean
```

四层：① 编译零警告 → ② `eunit:test('NN_topic_tests')` → ③ 运行四条判定（退出码 0 / stderr 空 / 无控制字符 / 有 `==== NN 结束 ====` 标记——Erlang 进程崩了退出码仍可能是 0，标记是铁证）→ ④ 同一 BEAM 用 `+S 1:1` 重跑，stdout 与通道 A **逐字节一致**（抓 map 迭代顺序、pid、环境数字）。单章学法：

```powershell
cd examples/15_gen_server
erl -noshell -pa ../../build/15_gen_server -run '15_gen_server' main -s init stop
erl -noshell -pa ../../build/15_gen_server -eval "eunit:test('15_gen_server_tests', [verbose]), halt()."
```

## 相关教程

同一标准的兄弟教程：[../cpp20](../cpp20)、[../zig](../zig)、[../go](../go)；本目录 [CHEATSheet.md](CHEATSheet.md)。
