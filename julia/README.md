# Julia 编程指南（1.13）

面向**会编程（C++/Python 背景最佳）、初学 Julia** 的读者：从零教到 1.13 现代写法——`Base.@main` 入口、`[sources]` 路径依赖、线程池并行、新前端错误读法从第 02 章就是默认姿势，旧写法只在坑位清单里教"认得"。**Julia 特色全部独立成章细讲**：多重派发（06）、类型系统（07）、数组列主序（09）、广播融合（10）、**线性代数与稀疏矩阵（13）**、元编程（14）、性能工程（16）、Pkg 环境系统（17）、**随机与统计（21）**；数值稳定性（03.7）与蒙特卡洛贯穿科学计算主线。压轴实战是**迷你 ODE 求解器**（照搬 SciML 生态的问题-算法-解三件套设计，含自适应步长与收敛阶测试）。每章"读讲解 → 跑示例 → 改代码再跑"，全部示例三层验证通过（运行 + 测试 + 工程特判）。

> ⚠️ 网上教程多为 1.9/1.10 时代写法，1.13 有实测差异（`catch_stacktrace` 已删、`@code_warntype` 脚本要显式引入、`Pkg.activate` 参数变化等）。本教程所有代码在 **1.13.0** 实测，每章末尾"坑位清单"收录 40+ 条实测坑位。

## 目录结构

```text
julia/
├── README.md       本文件
├── docs/           24 章教程（01 → 24 顺序阅读）
├── examples/       23 个示例目录（章号 = 目录号；17/24 为 Pkg 包工程，24 为迷你 ODE 求解器）
├── build.ps1       PowerShell 入口（双入口之一，须 PowerShell 7 / pwsh）
├── run-all.sh      shell 入口（双入口之一，判定与 build.ps1 逐条一致）
└── CHEATSheet.md   语法速查 + 1.13 坑位索引
```

## 章节索引

| 章 | 主题 | 示例 |
|---|---|---|
| [01 全景](docs/01-overview.md) | 设计哲学、1.13 现状、工具链一览 | — |
| [02 第一个程序](docs/02-hello.md) | REPL 四模式、println/print/show、插值、ARGS 与 `@main` | `02_hello` |
| [03 数值类型与数值稳定](docs/03-numbers.md) | 整型环绕、有理数/复数、整除家族、**抵消/Kahan/稳定求根** | `03_numbers` |
| [04 控制流](docs/04-control.md) | if 表达式、短路、循环、无 labeled break、soft scope 坑 | `04_control` |
| [05 函数](docs/05-functions.md) | 参数族、匿名、do 块、操作符即函数、管道与复合 | `05_functions` |
| [06 ⭐多重派发](docs/06-dispatch.md) | 方法表、按全部实参、歧义桥方法、扩展 Base | `06_dispatch` |
| [07 ⭐类型系统](docs/07-typesystem.md) | 类型树、Union、nothing/missing、类型是值、不变性 | `07_typesystem` |
| [08 结构体](docs/08-structs.md) | 不可变/可变、@kwdef、内外部构造器、参数化 | `08_structs` |
| [09 ⭐数组](docs/09-arrays.md) | 列主序、索引/视图、增删、LinearAlgebra | `09_arrays` |
| [10 ⭐广播](docs/10-broadcast.md) | `.` 语义、融合、`.=`、@.、broadcastable | `10_broadcast` |
| [11 集合](docs/11-collections.md) | Dict/Set/tuple、sort 家族、迭代器、推导式 | `11_collections` |
| [12 字符串](docs/12-strings.md) | UTF-8 码点/字节、插值、正则、Printf | `12_strings` |
| [13 ⭐线性代数与稀疏矩阵](docs/13-linalg.md) | 分解复用、最小二乘、SVD/条件数、SparseArrays、BLAS 线程 | `13_linalg` |
| [14 ⭐元编程](docs/14-macros.md) | Expr、宏与卫生 esc、世界年龄、@generated | `14_macros` |
| [15 参数化与接口](docs/15-generics.md) | where、Type{T}、Val、实现 AbstractVector | `15_generics` |
| [16 ⭐性能](docs/16-performance.md) | 类型稳定、全局之恶、计时计配额、@inbounds/@simd | `16_performance` |
| [17 ⭐包与环境](docs/17-pkg.md) | Pkg、Project/Manifest、环境栈、[sources] 路径依赖 | `17_pkgenv`（工程） |
| [18 测试](docs/18-testing.md) | @test 家族、@testset、随机 seed、性质测试 | `18_testing` |
| [19 文件与 IO](docs/19-files.md) | open/do、逐行、Serialization、walkdir | `19_files` |
| [20 并发与并行](docs/20-concurrency.md) | @async/Channel 流水线、线程池、@threads/@spawn、竞争三板斧 | `20_concurrency`（`-t 4`） |
| [21 ⭐随机与统计](docs/21-randomstats.md) | Random 子流、描述统计、蒙特卡洛、CLT、置信区间 | `21_randomstats` |
| [22 错误与调试](docs/22-errors-debugging.md) | 异常族、自定义异常、1.13 栈跟踪、Profiler、生态工具 | `22_errdebug` |
| [23 C 互操作](docs/23-ccall.md) | ccall/@ccall、@cfunction 回调、指针三招 | `23_ccall` |
| [24 实战：迷你 ODE 求解器](docs/24-miniode.md) | 包工程：问题-算法-解三件套 + 收敛阶/能量守恒测试 | `24_miniode`（工程） |

## 构建工具链

- Julia **1.13.0**：两个入口都**自动定位**，不硬编码路径 —— `-Julia` 参数 / 环境变量 `JULIA` → PATH 上的 `julia` → 常见安装位置（Windows: juliaup、`%LOCALAPPDATA%`；macOS: `/opt/local/bin`（MacPorts）、`/opt/homebrew/bin`、juliaup；Linux: `/usr/local/bin`）。本机 macOS 实测用 MacPorts 的 `/opt/local/bin/julia`（1.13.0）。
- 每示例含 `main.jl`（演示 + @assert 自检）与 `runtests.jl`（Test 断言套件）；17/24 为 Pkg 工程（env/ + 本地包）。
- **Pkg 一律离线**（两个入口都设 `JULIA_PKG_OFFLINE=true`），而且 Pkg 工程**默认不调 `Pkg.instantiate()`**
  —— `env/Manifest.toml` 已随仓库入库、依赖只有路径包和标准库，直接跑就行（见下文兼容性第 3 条）。
- Windows 中文控制台乱码先 `chcp 65001`（build.ps1 已设 UTF-8 输出编码）。

## 验证命令

```bash
cd julia
./run-all.sh              # shell 入口：全部 23 个示例（运行层 + 测试层）
./run-all.sh -v           # 附带每个示例的完整输出
./run-all.sh 13 23        # 只跑指定编号（或目录名，如 09_arrays）
```

```powershell
cd julia
pwsh -ExecutionPolicy Bypass -File build.ps1 -All                 # PowerShell 入口，等价
pwsh -ExecutionPolicy Bypass -File build.ps1 -Example 09_arrays   # 单个示例
pwsh -ExecutionPolicy Bypass -File build.ps1 -Clean               # 清理 build 目录
```

三层验证：**运行层**（`--check-bounds=yes` 跑 main.jl → exit 0 + `==== NN 结束 ====` 标记）→ **测试层**（runtests.jl 的 @testset → exit 0）→ **特判层**（17/24 在 `env/` 环境下跑，20 加 `-t 4`）。
两个入口共用同一套**六条判定标准**（见下），结果必须一致。

单跑某个示例（每章标准学法）——改代码后重跑：

```bash
cd julia/examples/09_arrays
julia --startup-file=no main.jl          # 改完立刻看效果
```

## 判定标准（六条，两个入口共用）

| # | 条件 | 为什么需要 |
|---|---|---|
| 1 | 退出码为 0 | 基础 |
| 2 | stderr 为空 | Julia 的警告/异常都走 stderr → 这一条等价于「零告警」 |
| 3 | stdout 非空 | 只判退出码会漏掉「进程根本没执行到业务代码」的假阳性 |
| 4 | stdout 无多余控制字符（TAB/LF/CR 除外） | 打印了原始内存字节的示例能退 0、有标记，肉眼却看不出来 |
| 5 | stdout 有 `==== NN 结束 ====` | 保证程序没在中途悄悄失败 |
| 6 | stdout 无 Julia 诊断字样（WARNING/ERROR/MethodError…） | 兜住绕开 stderr 的第三方输出 |

第 6 条有个连带约束：**示例自己打印的文案里不能出现这些字样**，否则会被自己的验证脚本判失败。

## macOS / Linux 上的兼容性（2026-09-18 实测于 macOS 12.7 + Julia 1.13.0）

教程原本按 Windows 写的，搬到 macOS 上有三个真问题，都已修掉：

1. **`ccall` 的库名写死 `"msvcrt"`** → macOS 上 `could not load library "msvcrt"`（23 章整章跑不起来）。
   现统一为 `const CLIB = Sys.iswindows() ? "msvcrt" : (Sys.isapple() ? "libSystem" : "libm")`。
   实测：macOS 上 `libSystem` / `libm` / `libc` 三个名字都能解析，`strlen/atoi/fabs/abs/malloc/qsort` 全部可用
   （macOS 的 libm、libc 都只是 libSystem 的别名）。`ccall` 的库名**必须是顶层常量**，
   局部变量会报 `cannot reference local variables`。
2. **`isabspath("G:\\x")` 式断言**（19 章）→ macOS 上直接 `AssertionError: isabspath("G:\\x")`（退出码 1）。
   绝对路径的「长相」是平台相关的：Windows 认盘符、Unix 认开头斜杠。示例改为
   `isabspath(Sys.iswindows() ? "G:\\x" : "/x")`。**分隔符和绝对路径是两个维度**，只把分隔符用 `joinpath`
   包起来还不够。
3. **`Pkg.instantiate()` 卡死十几分钟**（17/24 两个 Pkg 工程）。
   卡点不是网络：Pkg 要读/解压 General registry（7.5MB → 240MB、约 4 万个小文件）——
   在没有可用 registry 的 depot 上，这一步在本机慢到像死锁（实测十几分钟不返回，进程仍在跑）。
   解法（已落到两个入口）：**入口不再主动 instantiate**。`env/Manifest.toml` 随仓库入库、依赖只有
   `[sources]` 路径包和 stdlib，`julia --project=env main.jl` 直接就能跑（实测 3 秒）；
   只有 Manifest 真缺了（首次从零解析）才调 `Pkg.instantiate()`，那时入口带 `JULIA_PKG_OFFLINE=true`。
   手工执行 `Pkg.instantiate()` 时也要留意这一点。

另外 14 章的世界年龄演示会**故意**触发一条 `Detected access to binding ... in a world prior to its
definition world` 警告（Julia 1.12+ 行为，不受 `--depwarn=no` 控制）：示例用 `redirect_stderr(devnull)`
把那次调用圈起来，好让「stderr 为空」这条判定对其它示例仍然严格。

**受限环境（非教程缺陷，但会让人误判）**：如果 `~/.julia` 所在目录**不允许删除文件**
（只读挂载、受限沙箱），那么 `Pkg.status()` / `Pkg.instantiate()` 会**无限挂起** ——
它写 `logs/manifest_usage.toml` 的动作是「先删旧文件再改名」（`atomic_toml_write`），
删除被拒时不是报错而是卡住，症状和上面的 registry 坑一模一样。把 depot 指到可写目录即可：

```bash
JULIA_DEPOT_PATH=/tmp/julia-depot: ./run-all.sh      # 末尾的冒号保留默认系统 depot
```

**定位这类"挂起"的通用手法**（比猜快得多）：`sample <julia pid> 2 -file out.txt` 采一次调用栈，
看主线程卡在哪一帧 —— 本次就是靠它把「registry 解压慢」和「`rm` 被拒」两个不同原因区分开的。

其余部分（路径/线程/浮点/编码）跨平台一致：示例一律用 `joinpath`、`mktempdir`，
不硬编码分隔符；20 章的 `-t 4` 由入口自动加，本机 4 核默认池也是 4。

## 当前状态（2026-09-18）

- **23 个示例 × 2 层（运行 / 测试）在两个入口下全绿**：`./run-all.sh` → `通过 46   失败 0`；
  `pwsh ./build.ps1 -All` → 同上（均在 macOS 12.7 + Julia 1.13.0 实跑）。
- **判定标准反向验证过**：故意造 6 个违规样例（退出码非 0 / stderr 非空 / stdout 为空 /
  混控制字符 / 缺结束标记 / stdout 含诊断字样），逐条确认能报出对应理由且脚本退出码 1；
  另加 1 个合法样例作对照组，确认「全绿」不是永远返回通过。
- 本仓库的验证环境对 `~/.julia` 的删除有限制，故实跑时带了
  `JULIA_DEPOT_PATH=/tmp/julia-depot:`（原因见上文）；普通终端环境不需要。

## 相关教程

动态语言对照：[dart](../dart/README.md)；系统语言主线：[cpp20](../cpp20/README.md)、[zig](../zig/README.md)、[go](../go/README.md)；速查见 [CHEATSheet.md](CHEATSheet.md)。
