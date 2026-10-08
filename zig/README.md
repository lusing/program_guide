# Zig 编程指南（0.17）

面向**会编程（C/C++ 背景最佳）、初学 Zig** 的读者：从零教到 0.17 现代写法——`std.Io` 新接口、`std.process.Init` 入口、unmanaged 集合从第 02 章就是默认姿势，旧写法只在坑位清单里教"认得"。**Zig 特色全部独立成章细讲**：分配器（11）、comptime 两章（13/14）、测试（15）、构建系统与包管理（16）、C 互操作（17）、交叉编译与 zig cc（18）。**25–37 章为书本扩充的进阶缺口**：二进制布局、编码流处理、目录树、文件监视、网络双协议、HTTP、并发进阶、SQLite 直连、解释器、LRU 缓存服务器（取材《Systems Programming with Zig》《Learning Zig》两书，0.17 实测改写）。每章"读讲解 → 跑示例 → 改代码再跑"，全部示例三层验证通过（fmt + test + 运行 exit 0）。

> ⚠️ Zig 尚未 1.0：网上教程多为 0.13/0.14 语法，**0.16 的写法在 0.17 也大量编译不过**
> （`**` 运算符、`void{}`、`@cImport`、`@intFromEnum`、`b.args`、`std.meta` 等已移除/改名）。
> 本教程所有代码在 **0.17.0** 实测，每章坑位清单收录迁移差异。

## 目录结构

```text
zig/
├── README.md       本文件
├── docs/           38 篇文档（00 迁移手册 + 01 → 37 教程；25 起为书本扩充进阶篇）
├── examples/       36 个示例目录（章号 = 目录号；16/17/24/35 为 build.zig 工程；32 链系统 sqlite3）
├── build.ps1       统一验证脚本（须 PowerShell 7 / pwsh 运行）
├── run-all.sh      同一套验证的 bash 版（Linux/macOS；ZIG= 可指定解释器）
└── CHEATSheet.md   语法速查 + 0.17 坑位索引
```

## 章节索引

| 篇 | 主题 | 示例 |
|---|---|---|
| [00 0.16→0.17 迁移手册](docs/00-migration-0.17.md) | **被移除的语法、改名的内建函数、std.Io.net 换血、迁移清单** | — |
| [01 全景](docs/01-overview.md) | 设计哲学、0.17 现状、工具链一览 | — |
| [02 第一个程序](docs/02-hello.md) | debug.print、缓冲 Writer、Init 入口 | `02_hello` |
| [03 类型](docs/03-types.md) | 任意位宽整数、溢出运算符、转型家族 | `03_types` |
| [04 控制流](docs/04-control.md) | 表达式语义、switch 穷尽、labeled switch | `04_control` |
| [05 函数](docs/05-functions.md) | defer、anytype、没有重载怎么办 | `05_functions` |
| [06 数组切片字符串](docs/06-slices.md) | 胖指针、哨兵、指针三兄弟 | `06_slices` |
| [07 结构体](docs/07-structs.md) | 方法、命名空间、元组、init/deinit | `07_structs` |
| [08 枚举与联合](docs/08-enums.md) | tagged union、packed struct | `08_enums` |
| [09 可选与错误 I](docs/09-optionals-errors.md) | ?T、!T、try/catch | `09_errors1` |
| [10 错误 II](docs/10-errors-advanced.md) | errdefer、?!T、安全模式 | `10_errors2` |
| [11 ⭐分配器](docs/11-allocators.md) | 显式分配器哲学、六种分配器 | `11_allocators` |
| [12 ⭐集合](docs/12-collections.md) | ArrayList unmanaged、HashMap、排序 | `12_collections` |
| [13 ⭐comptime I](docs/13-comptime.md) | 编译期求值、配额、inline | `13_comptime` |
| [14 ⭐泛型](docs/14-generics.md) | type 参数、@typeInfo 反射、代码生成 | `14_generics` |
| [15 ⭐测试](docs/15-testing.md) | test 块、泄漏检测、tmpDir | `15_testing` |
| [16 ⭐构建与包管理](docs/16-build.md) | build.zig、zon、路径依赖 | `16_build`（工程） |
| [17 ⭐C 互操作](docs/17-c-interop.md) | extern/translate-c/双向调用 | `17_cinterop`（工程） |
| [18 ⭐交叉编译](docs/18-cross.md) | -target、wasm、zig cc | `18_cross`（多目标） |
| [19 并发](docs/19-threads.md) | Thread、Io.Mutex、原子游标 | `19_threads` |
| [20 文件与 IO](docs/20-files-io.md) | std.Io.Dir、缓冲 Writer、std.json | `20_files` |
| [21 内联汇编](docs/21-asm.md) | asm 语法、约束、时间计数器 | `21_asm`（x86_64 + aarch64 双实现） |
| [22 进程](docs/22-process.md) | argv、子进程、Io 时钟 | `22_process` |
| [23 调试与工具](docs/23-debugging.md) | panic 栈跟踪、错误跟踪、LLDB | `23_debug` |
| [24 实战：迷你 grep](docs/24-minigrep.md) | 递归 + 多线程 + 高亮 + 测试 | `24_minigrep`（工程） |
| [25 二进制数据与内存布局](docs/25-binary.md) | extern/packed struct、字节序、bytesToValue | `25_binary` |
| [26 编码与流处理](docs/26-encoding.md) | hex、base64、手写编码器、@Vector SIMD | `26_encoding` |
| [27 目录遍历与文件树](docs/27-tree.md) | 递归走查、statFile、glob、du、ztree | `27_tree` |
| [28 文件监视](docs/28-watch.md) | 轮询快照求差、Windows RDCW extern | `28_watch` |
| [29 TCP 与 UDP](docs/29-networking.md) | echo 双协议、`std.Io.net` 换血、行协议解析 | `29_netecho` |
| [30 HTTP 服务与客户端](docs/30-http.md) | 手写报文、路由、JSON 响应 | `30_http` |
| [31 并发进阶](docs/31-concurrency.md) | 六种内存序、CAS 重试、无锁队列、`std.Io` 并发 | `31_concurrency` |
| [32 SQLite 实战](docs/32-sqlite.md) | 手写 `extern "c"` 直连 sqlite3、事务、自定义函数 | `32_sqlite`（`-lsqlite3`） |
| [33 实战：表达式解释器](docs/33-zcalc.md) | lexer、Pratt 解析、AST、树遍求值 | `33_zcalc` |
| [34 实战：LRU 缓存服务器](docs/34-zcache.md) | LRU、文本协议、并发客户端、zcache | `34_zcache` |
| [35 ZLS 与编辑器工具链](docs/35-zls.md) | 版本配对铁律、0.17 断代、zls.json、check 步骤 | `35_zls`（build.zig 工程） |
| [36 指针与内存深水区](docs/36-pointers.md) | volatile、ptrCast/alignCast、零尺寸、peer 解析、[*c]、位对齐指针 | `36_pointers` |
| [37 实战：FileGuard 文件完整性监护](docs/37-fileguard.md) | 内容哈希、inode 移动检测、双索引、手写 glob、CLI | `37_fileguard` |

## 构建工具链

- Zig **0.17.0**：Windows 用 `G:\scoop\apps\zig\current\zig.exe`（scoop 安装；版本不符先看 01 章的版本坑）；**macOS 实测环境**是官方 tarball `/Volumes/mac004/lang/zig-x86_64-macos-0.17.0/zig`（MacPorts 的 `/opt/local/bin/zig` 仍是 0.16.0，**不要用**）。build.ps1 找不到 scoop 路径时自动回退 PATH 里的 `zig`。
- Linux/macOS：官网 tarball 解压即用（单文件无依赖），`zig version` 须为 `0.17.0`。发行版包版本普遍偏旧（本机 MacPorts 是 0.16.0），**版本不符时以官网 tarball 为准**。
- **已实测的平台**：macOS Darwin 23 / x86_64 / zig 0.16.0 —— `./run-all.sh` 全量三层验证通过；PowerShell 7.6.6（`pwsh`）下 `build.ps1` 同样全绿。Linux（Arch/WSL2, zig 0.16.0）全量实测通过。**25–34 章（2026-09-30 扩充）在 Windows 11 / 0.16.0 全量 build.ps1 -All 实测通过**（29/30/34 的 TCP 走 ws2_32 直调——std.Io.net 的 AFD 数据面缺陷见 29 章实录；Linux/macOS 复验 32 章需 libsqlite3-dev）。**Apple Silicon（arm64 macOS）**：逐示例用 `-target aarch64-macos` 交叉编译验证全部通过（21 章此前是硬失败，现已补 aarch64 实现）；运行验证待 arm64 真机。
- 默认 Debug 模式（安全检查全开）；Windows 中文控制台乱码先 `chcp 65001`（build.ps1 已代设 UTF-8），Linux/macOS 终端原生 UTF-8 无此问题。

## 验证命令

```powershell
cd G:\code\guide\zig
pwsh -ExecutionPolicy Bypass -File build.ps1 -All                 # 全部 36 个示例：fmt+test+运行
pwsh -ExecutionPolicy Bypass -File build.ps1 -Example 12_collections   # 单个示例
pwsh -ExecutionPolicy Bypass -File build.ps1 -Clean               # 清理 build 目录
```

Linux/macOS 用等价的 bash 脚本（与 build.ps1 同一套三层验证）：

```bash
cd zig
ZIG=/Volumes/mac004/lang/zig-x86_64-macos-0.17.0/zig ./run-all.sh   # 全部 36 个示例：fmt+test+运行
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

## 相关教程

系统语言对照：[cpp20（C++20/23）](../cpp20/README.md)、[rust](../rust/README.md)、[dlang](../dlang/README.md)；速查见 [CHEATSheet.md](CHEATSheet.md)。
