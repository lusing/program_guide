# D 语言编程指南（DMD 2.113）

面向**会编程（C/C++ 背景最佳）、初学 D** 的读者：从零教到现代 D 写法——UFCS 管道、ranges + 惰性算法、CTFE 与 mixin 代码生成、契约式编程、消息传递并发从对应章节起就是默认姿势。**D 特色全部独立成章细讲**：UFCS（05）、scope guards（09）、契约（10）、模板两章（11/12）、ranges 两章（13/14）、GC 与逃逸术（15）、消息并发（16）、并行（17）、DUB 构建（21）、C 互操作与 BetterC（22）。每章"读讲解 → 跑示例 → 改代码再跑"，全部示例在本机**双层验证**通过（`-unittest` 全绿 + 编译产物运行 exit 0）。

> ⚠️ 网上 D 教程多为 2.07x/2.08x 时代（2017-2019）：`enum` 函数、`approxEqual`、`Task.force`、std.json 新 API 等行为都已变化。本教程所有代码在 **DMD 2.113.0（Windows x64）+ DUB 1.42** 实测，每章坑位清单收录版本差异。

## 目录结构

```text
dlang/
├── README.md       本文件
├── docs/           24 章教程（01 → 24 顺序阅读）
├── examples/       23 个示例目录（章号 = 目录号；21/24 为 DUB 工程）
├── build.ps1       统一验证脚本（须 PowerShell 7 / pwsh 运行）
└── CHEATSheet.md   语法速查 + 2.113 坑位索引
```

## 章节索引

| 章 | 主题 | 示例 |
|---|---|---|
| [01 全景](docs/01-overview.md) | 设计哲学、工具链、D vs C++/Go/Zig | — |
| [02 第一个程序](docs/02-hello.md) | writeln/writef、-run、unittest 初见 | `02_hello` |
| [03 类型](docs/03-types.md) | 整数/浮点/三种字符、const/immutable/enum | `03_types` |
| [04 控制流](docs/04-control.md) | foreach 十八般武艺、final switch | `04_control` |
| [05 函数](docs/05-functions.md) | 参数家族、@property、⭐UFCS | `05_functions` |
| [06 数组切片 AA](docs/06-arrays.md) | 共享切片、UTF-8 陷阱、内建哈希表 | `06_arrays` |
| [07 结构体](docs/07-structs.md) | 值语义、RAII、运算符重载 | `07_structs` |
| [08 类与接口](docs/08-classes.md) | 继承、Object 三件套、typeid | `08_classes` |
| [09 错误 I](docs/09-errors1.md) | 异常、enforce、⭐scope guards | `09_errors1` |
| [10 错误 II](docs/10-errors2.md) | nothrow、Nullable、契约 in/out/invariant | `10_errors2` |
| [11 模板 I](docs/11-templates1.md) | 泛型、模板约束、特化 | `11_templates1` |
| [12 模板 II](docs/12-templates2.md) | ⭐CTFE、static if、mixin、反射 | `12_templates2` |
| [13 ⭐区间](docs/13-ranges.md) | 5 级协议、手写区间、无限流 | `13_ranges` |
| [14 ⭐算法](docs/14-algorithms.md) | map/filter/reduce、惰性管道 | `14_algorithms` |
| [15 内存](docs/15-memory.md) | GC、@nogc、malloc、RefCounted/scoped | `15_memory` |
| [16 ⭐并发 I](docs/16-concurrency.md) | spawn/send/receive、immutable 通行证 | `16_concurrency` |
| [17 并发 II](docs/17-parallel.md) | parallel、taskPool、原子/CAS | `17_parallel` |
| [18 文件与 IO](docs/18-files.md) | std.file、File.byLine、路径 | `18_files` |
| [19 格式化](docs/19-format.md) | writef 全集、std.conv、字符串工具 | `19_format` |
| [20 JSON](docs/20-json.md) | std.json（2.113 实测 API）、CSV | `20_json` |
| [21 构建与 DUB](docs/21-dub.md) | 模块/包、dmd -i、DUB 工程 | `21_dub`（工程） |
| [22 ⭐C 互操作](docs/22-cinterop.md) | extern(C)、qsort、内联汇编、BetterC | `22_cinterop`（含 betterC） |
| [23 测试与工具](docs/23-testing.md) | unittest 深入、-cov、ddoc、StopWatch | `23_testing` |
| [24 实战：迷你 grep](docs/24-minigrep.md) | 递归 + 并行 + 高亮 + 单测 | `24_minigrep`（工程） |

## 构建工具链

- DMD **2.113.0**：`G:\scoop\apps\dmd\current\windows\bin64\dmd.exe`（scoop 安装；链接用本机 MSVC link.exe）。
- DUB **1.42.0**：随 DMD（`dub.exe`）。
- 中文控制台乱码先 `chcp 65001`（build.ps1 已代设 UTF-8）。

## 验证命令

```powershell
cd G:\code\guide\dlang
pwsh -ExecutionPolicy Bypass -File build.ps1 -All              # 全部 23 个示例：unittest + 编译运行
pwsh -ExecutionPolicy Bypass -File build.ps1 -Example 13_ranges  # 单个示例
pwsh -ExecutionPolicy Bypass -File build.ps1 -Clean             # 清理 build 目录与 .obj
```

单跑某个示例（每章标准学法）——改代码后重跑：

```bash
cd dlang/examples/13_ranges
G:/scoop/apps/dmd/current/windows/bin64/dmd.exe -w -run main.d        # 不带单测，跑 main
G:/scoop/apps/dmd/current/windows/bin64/dmd.exe -w -unittest -run main.d   # 只跑 unittest
```

## 相关教程

系统语言对照：[cpp20（C++20/23）](../cpp20/README.md)、[go](../go/README.md)、[zig](../zig/README.md)、[rust](../rust/README.md)；速查见 [CHEATSheet.md](CHEATSheet.md)。
