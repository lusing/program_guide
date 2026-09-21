# Zig 编程指南（0.16）

面向**会编程（C/C++ 背景最佳）、初学 Zig** 的读者：从零教到 0.16 现代写法——`std.Io` 新接口、`std.process.Init` 入口、unmanaged 集合从第 02 章就是默认姿势，旧写法只在坑位清单里教"认得"。**Zig 特色全部独立成章细讲**：分配器（11）、comptime 两章（13/14）、测试（15）、构建系统与包管理（16）、C 互操作（17）、交叉编译与 zig cc（18）。每章"读讲解 → 跑示例 → 改代码再跑"，全部示例三层验证通过（fmt + test + 运行 exit 0）。

> ⚠️ Zig 尚未 1.0：网上教程多为 0.13/0.14 语法，直接照抄编译不过。本教程所有代码在 **0.16.0** 实测，每章坑位清单收录迁移差异。

## 目录结构

```text
zig/
├── README.md       本文件
├── docs/           24 章教程（01 → 24 顺序阅读）
├── examples/       23 个示例目录（章号 = 目录号；16/24 为 build.zig 工程）
├── build.ps1       统一验证脚本（须 PowerShell 7 / pwsh 运行）
├── run-all.sh      同一套验证的 bash 版（Linux/macOS；ZIG= 可指定解释器）
└── CHEATSheet.md   语法速查 + 0.16 坑位索引
```

## 章节索引

| 章 | 主题 | 示例 |
|---|---|---|
| [01 全景](docs/01-overview.md) | 设计哲学、0.16 现状、工具链一览 | — |
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
| [17 ⭐C 互操作](docs/17-c-interop.md) | extern/@cImport/translate-c | `17_cinterop`（-lc） |
| [18 ⭐交叉编译](docs/18-cross.md) | -target、wasm、zig cc | `18_cross`（多目标） |
| [19 并发](docs/19-threads.md) | Thread、Io.Mutex、原子游标 | `19_threads` |
| [20 文件与 IO](docs/20-files-io.md) | std.Io.Dir、缓冲 Writer、std.json | `20_files` |
| [21 内联汇编](docs/21-asm.md) | asm 语法、约束、rdtsc | `21_asm` |
| [22 进程](docs/22-process.md) | argv、子进程、Io 时钟 | `22_process` |
| [23 调试与工具](docs/23-debugging.md) | panic 栈跟踪、错误跟踪、LLDB | `23_debug` |
| [24 实战：迷你 grep](docs/24-minigrep.md) | 递归 + 多线程 + 高亮 + 测试 | `24_minigrep`（工程） |

## 构建工具链

- Zig **0.16.0**：`G:\scoop\apps\zig\current\zig.exe`（scoop 安装；版本不符先看 01 章的版本坑）。build.ps1 找不到该路径时自动回退 PATH 里的 `zig`。
- Linux/macOS：发行版包（Arch `pacman -S zig`）或官网 tarball 解压即用（单文件无依赖），`zig version` 须为 `0.16.0`；本指南 23 个示例已在 Linux（Arch/WSL2, zig 0.16.0）全量实测通过。
- 默认 Debug 模式（安全检查全开）；Windows 中文控制台乱码先 `chcp 65001`（build.ps1 已代设 UTF-8），Linux/macOS 终端原生 UTF-8 无此问题。

## 验证命令

```powershell
cd G:\code\guide\zig
pwsh -ExecutionPolicy Bypass -File build.ps1 -All                 # 全部 23 个示例：fmt+test+运行
pwsh -ExecutionPolicy Bypass -File build.ps1 -Example 12_collections   # 单个示例
pwsh -ExecutionPolicy Bypass -File build.ps1 -Clean               # 清理 build 目录
```

Linux/macOS 用等价的 bash 脚本（与 build.ps1 同一套三层验证）：

```bash
cd zig
./run-all.sh                        # 全部 23 个示例：fmt+test+运行
./run-all.sh 12_collections         # 单个示例
ZIG=/path/to/zig ./run-all.sh       # 指定 zig 解释器
```

单跑某个示例（每章标准学法）——改代码后重跑：

```bash
cd zig/examples/12_collections
G:/scoop/apps/zig/current/zig.exe run main.zig        # 改完立刻看效果
```

## 相关教程

系统语言对照：[cpp20（C++20/23）](../cpp20/README.md)、[rust](../rust/README.md)、[dlang](../dlang/README.md)；速查见 [CHEATSheet.md](CHEATSheet.md)。
