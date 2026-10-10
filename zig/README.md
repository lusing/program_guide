# Zig 编程指南（0.17）

面向**会编程（C/C++ 背景最佳）、初学 Zig** 的读者：从零教到 0.17 现代写法。全书 **44 篇分 6 个篇章**——每篇回答一个独立问题，篇章之间是依赖关系而非时间关系；`docs/` 章号（00–43）是**稳定编号**，供引用与坑位索引定位，**实际阅读顺序以下面路线图为准**。每篇头部都有"阅读位置"一行，标明它在全书中的坐标、承接哪几篇、为谁铺路。

- Zig 特色全部独立成章细讲：分配器（11）、comptime 两章（13/14）、测试（15）、构建与包管理（16）、C 互操作（17）、交叉编译（18）。
- 每章"读讲解 → 跑示例 → 改代码再跑"，全部示例三层验证通过（fmt + test + 运行 exit 0）。
- `unmanaged` 集合、`std.Io` 新接口、`std.process.Init` 入口从第 02 章就是默认姿势；旧写法只在坑位清单里教"认得"。

> ⚠️ Zig 尚未 1.0：网上教程多为 0.13/0.14 语法，**0.16 的写法在 0.17 也大量编译不过**
> （`**` 运算符、`void{}`、`@cImport`、`@intFromEnum`、`b.args`、`std.meta` 等已移除/改名）。
> 本教程所有代码在 **0.17.0** 实测，每章坑位清单收录迁移差异。

## 学习路线图

### 序篇 · 先搞清楚状况

一句话：Zig 是什么、工具链装好了吗、第一个程序长什么样。

| 序 | 章 | 主题 | 一句话 | 示例 |
|---|---|---|---|---|
| — | [00 迁移手册](docs/00-migration-0.17.md) | 0.16→0.17 完整对照 | **随身手册**，不计入顺序；手上有旧代码时先扫 | — |
| 1 | [01 全景](docs/01-overview.md) | 设计哲学、0.17 现状 | 明白"更好的 C，不是更好的 Rust" | — |
| 2 | [02 第一个程序](docs/02-hello.md) | Init 入口、缓冲 Writer | 这一章的骨架之后每章都用 | `02_hello` |

### 第一篇 · 语言核心 —— 能读懂任何 Zig 源码

类型、控制流、函数、切片、结构体、枚举、可选与错误，一路推到指针深水区收官。

| 序 | 章 | 主题 | 一句话 | 示例 |
|---|---|---|---|---|
| 1 | [03 类型](docs/03-types.md) | 任意位宽整数、溢出运算符、转型家族 | 位宽是设计决策不是细节 | `03_types` |
| 2 | [04 控制流](docs/04-control.md) | 表达式语义、switch 穷尽 | 后面 33/40 的 token 处理地基 | `04_control` |
| 3 | [05 函数](docs/05-functions.md) | defer、anytype、没有重载怎么办 | defer/errdefer 纪律的起点 | `05_functions` |
| 4 | [06 数组切片字符串](docs/06-slices.md) | 胖指针、哨兵、指针三兄弟 | 切片是全教程的通用货币 | `06_slices` |
| 5 | [07 结构体](docs/07-structs.md) | 方法、命名空间、init/deinit | 11/25/40 章的载体 | `07_structs` |
| 6 | [08 枚举与联合](docs/08-enums.md) | tagged union、packed struct | 33 的 AST、25 的位域都在这 | `08_enums` |
| 7 | [09 可选与错误 I](docs/09-optionals-errors.md) | ?T、!T、try/catch | 全书三分之一的函数签名 | `09_errors1` |
| 8 | [10 错误 II](docs/10-errors-advanced.md) | errdefer、?!T、安全模式 | 11/12 析构纪律的前置 | `10_errors2` |
| 9 | [36 指针与内存深水区](docs/36-pointers.md) | volatile、ptrCast/alignCast、`[*c]` | 按下不表的都在这篇末讲透 | `36_pointers` |

### 第二篇 · 记忆与编译期 —— Zig 的三张名片

显式分配器、unmanaged 集合、comptime 泛型。读完才敢说"懂 Zig 的设计"。

| 序 | 章 | 主题 | 一句话 | 示例 |
|---|---|---|---|---|
| 1 | [11 分配器 ⭐](docs/11-allocators.md) | 显式分配器哲学、六种分配器 | 每个"要内存"的函数都逼你回答"从哪儿" | `11_allocators` |
| 2 | [12 集合 ⭐](docs/12-collections.md) | ArrayList unmanaged、HashMap、排序 | 24/34/37/43 的清册 | `12_collections` |
| 3 | [13 comptime ⭐](docs/13-comptime.md) | 编译期求值、配额、inline | 40 的 CRC32 表在编译期生成 | `13_comptime` |
| 4 | [14 泛型 ⭐](docs/14-generics.md) | type 参数、@typeInfo 反射 | 40 布局校验、43 WorkQueue(T) 的引擎 | `14_generics` |

### 第三篇 · 工程化 —— 从"会写"到"能交付"

测试、构建系统、C 互操作、交叉编译、进程、调试、编辑器工具链。

| 序 | 章 | 主题 | 一句话 | 示例 |
|---|---|---|---|---|
| 1 | [15 测试](docs/15-testing.md) | test 块、泄漏检测、tmpDir | 每章末尾的 test 都按这套路 | `15_testing` |
| 2 | [16 构建与包管理](docs/16-build.md) | build.zig、zon、路径依赖 | 38 章的 `-lc` 就是链接参数 | `16_build`（工程） |
| 3 | [17 C 互操作](docs/17-c-interop.md) | extern/translate-c/双向调用 | 32 直连 sqlite、38 的 std.c 都靠它 | `17_cinterop`（工程） |
| 4 | [18 交叉编译](docs/18-cross.md) | -target、wasm、zig cc | 全书 aarch64 验证的策略 | `18_cross`（多目标） |
| 5 | [22 进程](docs/22-process.md) | argv、子进程、Io 时钟 | 通向 23 调试技巧与 38 系统调用 | `22_process` |
| 6 | [23 调试与工具](docs/23-debugging.md) | panic 栈、错误跟踪、LLDB | 唯一"故意把程序弄崩"的章 | `23_debug` |
| 7 | [35 ZLS 与编辑器](docs/35-zls.md) | 版本配对铁律、zls.json | 写后面所有代码时的安全带 | `35_zls`（工程） |

### 第四篇 · 数据与网络 —— 字节是一等公民

二进制布局、编码流、socket、HTTP、SQLite：程序的"对外"一面。

| 序 | 章 | 主题 | 一句话 | 示例 |
|---|---|---|---|---|
| 1 | [25 二进制与内存布局](docs/25-binary.md) | extern/packed struct、字节序 | 26 编码与 40 ZIP 的前置 | `25_binary` |
| 2 | [26 编码与流处理](docs/26-encoding.md) | hex、base64、@Vector SIMD | 29/30/34/42 的数据管线 | `26_encoding` |
| 3 | [29 TCP 与 UDP](docs/29-networking.md) | echo 双协议、`std.Io.net` 换血 | 30/34/39/42/43 的地基 | `29_netecho` |
| 4 | [30 HTTP 服务与客户端](docs/30-http.md) | 手写报文、路由、JSON 响应 | 42 的 HTTP 往返接这里 | `30_http` |
| 5 | [32 SQLite 实战](docs/32-sqlite.md) | `extern "c"` 直连、事务、自定义函数 | 实战章要持久化时的选项 | `32_sqlite`（`-lsqlite3`） |

### 第五篇 · 与系统对话 —— 文件、进程、并发三条线

文件系统线 → 守护进程线 → 并发线（19→31→39 逐级深化），末尾汇编章独立可读。

| 序 | 章 | 主题 | 一句话 | 示例 |
|---|---|---|---|---|
| 1 | [20 文件与 IO](docs/20-files-io.md) | std.Io.Dir、缓冲 Writer、std.json | 27/28/37/42 的地基 | `20_files` |
| 2 | [27 目录遍历与文件树](docs/27-tree.md) | 递归走查、statFile、glob、du | 24/37/43 共用同一套骨架 | `27_tree` |
| 3 | [28 文件监视](docs/28-watch.md) | 轮询快照求差 | 37 把时间维监视升级成空间维台账 | `28_watch` |
| 4 | [38 守护进程与信号](docs/38-daemon.md) | sigaction、fork/waitpid、僵尸收割、zcron | 34/42/43 这类服务的部署形态 | `38_daemon`（`-lc`） |
| 5 | [19 并发](docs/19-threads.md) | Thread、Io.Mutex、原子游标 | 并发线起点；0.17 同步原语大迁移 | `19_threads` |
| 6 | [31 并发进阶](docs/31-concurrency.md) | 六种内存序、CAS、无锁队列 | 43 的终止不变量在这埋过 | `31_concurrency` |
| 7 | [39 异步 IO](docs/39-asyncio.md) | `io.async`、`Io.Group`、`Io.Select` | 0.17 结构化并发；echo 演示用 29 | `39_asyncio` |
| 8 | [21 内联汇编](docs/21-asm.md) | asm 语法、约束、时间计数器 | 硬件侧收尾，可独立读 | `21_asm`（双架构） |

### 第六篇 · 综合实战 —— 八件真工具

每章一件可交付的工具，把前五篇的知识按"项目"重新组织一遍。

| 序 | 章 | 主题 | 一句话 | 示例 |
|---|---|---|---|---|
| 1 | [24 迷你 grep](docs/24-minigrep.md) | 递归 + 多线程 + 高亮 + 测试 | 第一个完整 CLI 工程 | `24_minigrep`（工程） |
| 2 | [33 表达式解释器](docs/33-zcalc.md) | lexer、Pratt 解析、AST | 解析器套路可迁移到任何格式 | `33_zcalc` |
| 3 | [34 LRU 缓存服务器](docs/34-zcache.md) | LRU、文本协议、并发客户端 | 网络 + 集合 + 线程的首次会师 | `34_zcache` |
| 4 | [37 FileGuard](docs/37-fileguard.md) | 内容哈希、inode 移动检测、双索引 | 27/28 的台账式升级 | `37_fileguard` |
| 5 | [40 ZIP 解析](docs/40-zunzip.md) | EOCD/CD、CRC32 comptime 查表 | 二进制格式解析的收官演示 | `40_zunzip` |
| 6 | [41 zpass](docs/41-zpass.md) | PRNG/CSPRNG、模偏差、UUID v4 | 随机性的正确姿势 | `41_zpass` |
| 7 | [42 JSON 监控服务](docs/42-memsrv.md) | /proc 解析、JSON 往返、HTTP 服务 | 系统数据的全链路小服务 | `42_memsrv` |
| 8 | [43 zlocate](docs/43-zlocate.md) | WorkQueue、Scatter-Gather、并行 BFS | 并发线终点，全教程收官 | `43_zlocate` |

## 主线一览（跨篇主题带）

同一主题在多章里逐级深化，复习或专项突破时按线走：

| 主线 | 章节 progression | 一句话 |
|---|---|---|
| 内存 | 06 切片 → 11 分配器 → 12 集合 → 36 指针深水区 | 从类型到策略再到硬件语义 |
| 并发 | 19 → 31 → 39 → 43 | 线程基础 → 内存序与无锁 → 结构化并发 → WorkQueue 落地 |
| 文件 | 20 → 27 → 28 → 37 → 43 | 单文件 → 遍历 → 监视 → 台账 → 并发爬取 |
| 网络 | 29 → 30 → 34 → 42 | 报文 → HTTP → 缓存服务 → 监控服务 |
| 编译期 | 13 → 14 → 25 → 40 | comptime 求值 → 泛型反射 → 布局 → 格式校验 |
| C 互操作 | 17 → 18 → 32 → 38 | extern → 交叉编译 → sqlite3 → std.c 系统调用 |
| 数据格式 | 25 → 26 → 40 → 41 | 字节序 → 编码 → ZIP → 随机与密码 |

## 目录结构

```text
zig/
├── README.md       本文件（路线图 + 工具链 + 验证命令）
├── docs/           44 篇教程（章号是稳定编号；阅读顺序见上面路线图）
├── examples/       42 个示例目录（章号 = 目录号；16/17/24/35 为 build.zig 工程；32 链 sqlite3；38 链 libc）
├── build.ps1       统一验证脚本（须 PowerShell 7 / pwsh 运行）
├── run-all.sh      同一套验证的 bash 版（Linux/macOS；ZIG= 可指定解释器）
└── CHEATSheet.md   语法速查 + 0.17 坑位索引
```

## 构建工具链

- Zig **0.17.0**：Windows 用 `G:\scoop\apps\zig\current\zig.exe`（scoop 安装；版本不符先看 01 章的版本坑）；**macOS 实测环境**是官方 tarball `/Volumes/mac004/lang/zig-x86_64-macos-0.17.0/zig`（MacPorts 的 `/opt/local/bin/zig` 仍是 0.16.0，**不要用**）。build.ps1 找不到 scoop 路径时自动回退 PATH 里的 `zig`。
- Linux/macOS：官网 tarball 解压即用（单文件无依赖），`zig version` 须为 `0.17.0`。发行版包版本普遍偏旧（本机 MacPorts 是 0.16.0），**版本不符时以官网 tarball 为准**。
- **已实测的平台**：macOS / x86_64 / zig 0.17.0 —— `./run-all.sh` 全部 42 例三层验证通过（含 38–43 章；38 章须 `-lc`，脚本已自动加）。Windows 11 / PowerShell 7.6.6（`pwsh`）下 `build.ps1 -All` 同样全绿。Linux（Arch/WSL2）全量实测通过（32 章需 libsqlite3-dev）。**Apple Silicon（arm64 macOS）**：逐示例 `-target aarch64-macos` 交叉编译验证全部通过（21 章已补 aarch64 实现）；运行验证待 arm64 真机。
- 默认 Debug 模式（安全检查全开）；Windows 中文控制台乱码先 `chcp 65001`（build.ps1 已代设 UTF-8），Linux/macOS 终端原生 UTF-8 无此问题。

## 验证命令

```powershell
cd G:\code\guide\zig
pwsh -ExecutionPolicy Bypass -File build.ps1 -All                 # 全部 42 个示例：fmt+test+运行
pwsh -ExecutionPolicy Bypass -File build.ps1 -Example 12_collections   # 单个示例
pwsh -ExecutionPolicy Bypass -File build.ps1 -Clean               # 清理 build 目录
```

Linux/macOS 用等价的 bash 脚本（与 build.ps1 同一套三层验证）：

```bash
cd zig
ZIG=/Volumes/mac004/lang/zig-x86_64-macos-0.17.0/zig ./run-all.sh   # 全部 42 个示例：fmt+test+运行
./run-all.sh 12_collections         # 单个示例
ZIG=/path/to/zig ./run-all.sh       # 一般情况下直接 ./run-all.sh 即可
```

macOS 上想跑 PowerShell 版也行（pwsh 7.6.6 实测全绿），但本机 `pwsh -File` 起不来（报 `Call to 'procargs' failed with errno 5`），用 `-Command` 调脚本：

```bash
pwsh -NoProfile -Command '& ./build.ps1 -All'
```

单跑某个示例（每章标准学法）——改代码后重跑：

```bash
cd zig/examples/12_collections
G:/scoop/apps/zig/current/zig.exe run main.zig        # Windows
zig run main.zig                                      # macOS/Linux
```

## 由来与取材

本教程按"语言 → 工程 → 系统 → 实战"的课程骨架写作，内容来源三条线，已全部改写为 0.17.0 实测的自包含教程（不要求读者回查原书）：

- **主线**：Zig 官方文档与标准库源码逐 API 实测（01–24、25–31）。
- **《Systems Programming with Zig》**（Mihalis Tsoukalos）：补齐信号/守护进程（38）、异步 IO（39）、ZIP 解析（40）、随机数与密码（41）、JSON 监控服务（42）、并发索引器 WorkQueue（43），以及 25–34 章的对应工具线。
- **《Learning Zig》**（Ryan Swift）：补齐 ZLS 工具链（35）、指针深水区（36）、FileGuard（37）。

原书成书于 0.14–0.15 时代，所有代码在 0.17.0 上重写，差异逐条记入各章坑位清单与 [CHEATSheet.md](CHEATSheet.md)。

## 相关教程

系统语言对照：[cpp20（C++20/23）](../cpp20/README.md)、[rust](../rust/README.md)、[dlang](../dlang/README.md)；速查见 [CHEATSheet.md](CHEATSheet.md)。
