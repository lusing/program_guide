# Julia 编程指南（1.13）

面向**会编程（C++/Python 背景最佳）、初学 Julia** 的读者：从零教到 1.13 现代写法——`Base.@main` 入口、`[sources]` 路径依赖、线程池并行、新前端错误读法从第 02 章就是默认姿势，旧写法只在坑位清单里教"认得"。**Julia 特色全部独立成章细讲**：多重派发（06）、类型系统（07）、数组列主序（09）、广播融合（10）、元编程（14）、性能工程（16）、Pkg 环境系统（17）。每章"读讲解 → 跑示例 → 改代码再跑"，全部示例三层验证通过（运行 + 测试 + 工程特判）。

> ⚠️ 网上教程多为 1.9/1.10 时代写法，1.13 有实测差异（`catch_stacktrace` 已删、`@code_warntype` 脚本要显式引入、`Pkg.activate` 参数变化等）。本教程所有代码在 **1.13.0** 实测，每章末尾"坑位清单"收录 40+ 条实测坑位。

## 目录结构

```text
julia/
├── README.md       本文件
├── docs/           24 章教程（01 → 24 顺序阅读）
├── examples/       23 个示例目录（章号 = 目录号；17/24 为 Pkg 包工程）
├── build.ps1       统一验证脚本（须 PowerShell 7 / pwsh 运行）
└── CHEATSheet.md   语法速查 + 1.13 坑位索引
```

## 章节索引

| 章 | 主题 | 示例 |
|---|---|---|
| [01 全景](docs/01-overview.md) | 设计哲学、1.13 现状、工具链一览 | — |
| [02 第一个程序](docs/02-hello.md) | REPL 四模式、println/print/show、插值、ARGS 与 `@main` | `02_hello` |
| [03 数值类型](docs/03-numbers.md) | 整型环绕、BigInt、有理数/复数、整除家族、promote | `03_numbers` |
| [04 控制流](docs/04-control.md) | if 表达式、短路、循环、无 labeled break、soft scope 坑 | `04_control` |
| [05 函数](docs/05-functions.md) | 参数族、匿名、do 块、操作符即函数、管道与复合 | `05_functions` |
| [06 ⭐多重派发](docs/06-dispatch.md) | 方法表、按全部实参、歧义桥方法、扩展 Base | `06_dispatch` |
| [07 ⭐类型系统](docs/07-typesystem.md) | 类型树、Union、nothing/missing、类型是值、不变性 | `07_typesystem` |
| [08 结构体](docs/08-structs.md) | 不可变/可变、@kwdef、内外部构造器、参数化 | `08_structs` |
| [09 ⭐数组](docs/09-arrays.md) | 列主序、索引/视图、增删、LinearAlgebra | `09_arrays` |
| [10 ⭐广播](docs/10-broadcast.md) | `.` 语义、融合、`.=`、@.、broadcastable | `10_broadcast` |
| [11 集合](docs/11-collections.md) | Dict/Set/tuple、sort 家族、迭代器、推导式 | `11_collections` |
| [12 字符串](docs/12-strings.md) | UTF-8 码点/字节、插值、正则、Printf | `12_strings` |
| [13 异常](docs/13-errors.md) | 内建异常族、自定义异常、1.13 栈跟踪 | `13_errors` |
| [14 ⭐元编程](docs/14-macros.md) | Expr、宏与卫生 esc、世界年龄、@generated | `14_macros` |
| [15 参数化与接口](docs/15-generics.md) | where、Type{T}、Val、实现 AbstractVector | `15_generics` |
| [16 ⭐性能](docs/16-performance.md) | 类型稳定、全局之恶、计时计配额、@inbounds/@simd | `16_performance` |
| [17 ⭐包与环境](docs/17-pkg.md) | Pkg、Project/Manifest、环境栈、[sources] 路径依赖 | `17_pkgenv`（工程） |
| [18 测试](docs/18-testing.md) | @test 家族、@testset、随机 seed、性质测试 | `18_testing` |
| [19 文件与 IO](docs/19-files.md) | open/do、逐行、Serialization、walkdir | `19_files` |
| [20 任务与通道](docs/20-tasks.md) | @async、Channel、流水线、异常包装 | `20_tasks` |
| [21 多线程](docs/21-threads.md) | 线程池、@threads/@spawn、竞争与三板斧 | `21_threads`（`-t 4`） |
| [22 C 互操作](docs/22-ccall.md) | ccall/@ccall、@cfunction 回调、指针三招 | `22_ccall` |
| [23 调试与工具](docs/23-debugging.md) | 1.13 错误栈、Profiler、生态工具表 | `23_debug` |
| [24 实战：迷你 grep](docs/24-minigrep.md) | 包工程：递归 + 多线程 + ANSI 高亮 + 测试 | `24_minigrep`（工程） |

## 构建工具链

- Julia **1.13.0**：`G:\scoop\apps\julia\current\bin\julia.exe`（scoop 安装；版本不符先看 01 章的版本坑）。
- 每示例含 `main.jl`（演示 + @assert 自检）与 `runtests.jl`（Test 断言套件）；17/24 为 Pkg 工程（env/ + 本地包）。
- 中文控制台乱码先 `chcp 65001`（build.ps1 已设 UTF-8）。

## 验证命令

```powershell
cd G:\code\guide\julia
pwsh -ExecutionPolicy Bypass -File build.ps1 -All                 # 全部 23 个示例：运行层+测试层
pwsh -ExecutionPolicy Bypass -File build.ps1 -Example 09_arrays   # 单个示例
pwsh -ExecutionPolicy Bypass -File build.ps1 -Clean               # 清理 build 目录
```

三层验证：**运行层**（`--check-bounds=yes` 跑 main.jl → exit 0 + `==== NN 结束 ====` 标记）→ **测试层**（runtests.jl 的 @testset → exit 0）→ **特判层**（17/24 走 Pkg 工程流程，21/24 加 `-t 4`）。

单跑某个示例（每章标准学法）——改代码后重跑：

```bash
cd julia/examples/09_arrays
julia --startup-file=no main.jl          # 改完立刻看效果
```

## 相关教程

动态语言对照：[dart](../dart/README.md)；系统语言主线：[cpp20](../cpp20/README.md)、[zig](../zig/README.md)、[go](../go/README.md)；速查见 [CHEATSheet.md](CHEATSheet.md)。
