# Julia 教程重写设计（2026-09-18）

## 1. 背景与问题

`julia/` 目录现状：单个 `Julia编程指南.md`（特性手册式）+ 15 个平铺单文件示例（`examples/01_hello.jl` …）
+ `julia_demo.txt`；build.ps1 只有一层"运行 exit 0"验证；无 docs/ 分章、无章号=示例号对应、
无坑位清单、无 CHEATSheet。Julia 特色内容（多重派发、类型系统、广播融合、元编程、性能工程、
Pkg 环境系统）讲不出深度。

与 cpp20/zig/go/erlang 教程标准（docs/ 24 章分章 + 章号=示例目录号 + 递进讲解 + 坑位清单 +
多层验证）差距大。

## 2. 目标与非目标

**目标**：重写为 24 章独立文档（每章 150–250 行，特色章不压缩）、章号 = 示例目录号
（02–24 共 23 个示例）；定位"会编程（C++/Python 背景最佳）、初学 Julia，从零教到 1.13 现代写法"；
全部示例在 Julia 1.13.0 实测多层验证通过；第 24 章实战项目为**迷你 ODE 求解器**（包工程：
问题-算法-解三件套 + 自适应步长 + 收敛阶/能量守恒测试）。
> 改版记录（2026-09-18）：24 章原计划"迷你 grep"（与 cpp20/zig 对齐）；初版完成后按用户反馈
> 改为 ODE 求解器——grep 展示的是通用系统语言能力，Julia 的招牌是科学计算，压轴应对齐
> SciML 生态的"问题-算法-解"架构（多重派发 × 泛型状态 × 数值性质测试的集大成）。
>
> 改版二（2026-09-18，同日）：用户指出整份教程"通用语言味太重、缺科学计算与数值性能"。
> 结构调整（保持 24 章总量）：**新增 ⭐13 线性代数与稀疏矩阵**（分解复用/最小二乘/SVD 条件数/
> SparseArrays/BLAS 线程）与 **⭐21 随机与统计**（Random 子流/描述统计/蒙特卡洛/CLT/置信区间），
> 03 章扩为"数值类型与数值稳定"（抵消/ulp/Kahan/稳定求根）；腾位方式：13 异常并入新 22
> "错误与调试"（原 23），20 任务与 21 线程合并为 20 "并发与并行"（-t 4），原 22 ccall 顺移 23。

**非目标**：
- 不做 1.9→1.13 迁移指南（坑位清单点到即止）
- 不引第三方包作主线（16 章性能用 stdlib 计时；BenchmarkTools/JET 只作生态介绍）——本机离线可验证
- 不教 GPU/DistributedComputing 深水区（Distributed 只在 20 章一瞥）
- 不教 Plots/Makie 等绘图生态
- `@generated` 函数只给一个最小可运行示例，不展开
- SciML/DifferentialEquations 等领域库只作架构参照（24 章手写不依赖）；数值优化（JuMP）、自动微分（Enzyme/ForwardDiff）、DataFrame 不展开

## 3. 已确认决策

| 决策点 | 结论 |
|---|---|
| 章节规模 | 24 章完整版（对齐 cpp20/zig；改版二后 24 = 实战迷你 ODE 求解器，13/21 为科学计算专章） |
| 读者定位 | 会编程（C++/Python 背景最佳）、初学 Julia，1.13 现代写法为主线 |
| 实战项目 | 第 24 章迷你 ODE 求解器（包工程：问题-算法-解三件套 + RKF45 自适应 + 收敛阶测试；初版 grep 按用户反馈改版） |
| 工具链 | `G:\scoop\apps\julia\current\bin\julia.exe`（1.13.0，scoop 安装；depot 在 `C:\Users\lusin\.julia`） |
| 示例形态 | 每章一个目录 `examples/NN_topic/`（含 `main.jl` + `runtests.jl`；17/24 为包工程），章号=目录号 |
| 验证策略 | 三层：脚本运行层（`--check-bounds=yes` exit 0 + 结束标记）→ 测试层（runtests.jl @testset exit 0）→ 特判层（17/24 Pkg 工程、20 `-t 4`、23 ccall 回调实测） |
| 旧文件 | 删 `Julia编程指南.md`、`julia_demo.txt`、旧 `examples/*.jl`（15 个） |
| 新增 | `docs/` 24 章、新 `examples/` 23 目录、新 `build.ps1`、`CHEATSheet.md`、新 `README.md` |
| 目录名 | 保留 `julia`（外部引用不破坏） |

## 4. 环境实测结论（2026-09-18，Julia 1.13.0 @ G:\scoop\apps\julia\current）

| 项 | 结果 |
|---|---|
| 入口 | `Base.@main`（1.11+）：**正确形式 `function @main(args)` 或定义后独立 `@main`**；脚本执行完毕自动以 ARGS 调用；`-e 'include(...)'` 模式也会触发（args=`String[]`）⚠️ 示例必须容忍空 args |
| **坑** | `Base.@main function main(args)` 是错误形式——宏展开成"注册 + 立即调用 `main(函数对象)`"（实测打印 args=main） |
| **坑** | `@code_typed/@code_warntype` 属 InteractiveUtils，**脚本模式不自动进 Main**，须 `using InteractiveUtils`（REPL 才自动加载） |
| ccall | `ccall((:strlen,"msvcrt"),...)`、`@ccall "msvcrt".strlen(s::Cstring)::Csize_t`、kernel32 均 ✅ |
| 线程 | 默认 nthreads=1（须 `-t N`）；`-t N[,auto|M]` 双池；`@threads`（:static/:dynamic/:greedy）、`@spawn`、`Threads.Atomic{Int}`、`ReentrantLock` ✅ |
| **坑** | 顶层 `@threads` 内 `s += 1`：闭包作用域把 s 当局部 → UndefVarError（"check for an assignment to a local variable that shadows a global"）；须函数包裹或 `global` |
| Test | 顶层 @testset 失败 → 抛 TestSetException → 脚本 exit 1 ✅；1.13 会打印 "RNG of the outermost testset" 行 |
| Pkg | `[sources]` 本地路径依赖 + stdlib 依赖**离线** resolve/instantiate/precompile 全通 ✅；`Pkg.activate(path)` **无 `interactive` 关键字**（已移除） |
| **坑** | Project.toml 内 Windows 路径反斜杠是非法 TOML 转义（`\M`）——写 `/` |
| 1.13 新貌 | 新前端 flfrontend.jl（栈跟踪可见）；错误消息带 Suggestion/Hint 段 |
| 旗标 | `--check-bounds`、`-t`、`--gcthreads`、`--heap-size-hint`、`--track-allocation`、`--code-coverage`、`--warn-scope`、`--math-mode`、`--pkgimages` 均在 |
| 输出 | 中文 UTF-8 经 pwsh 管道正常；`--startup-file=no --history-file=no` 起脚本 |

其余坑位（广播自定义、构造器歧义、宏卫生、Val 分派等）实施中边写边实测累积。

## 5. 章节结构（docs/，24 章，⭐ = 特色重点细讲）

| # | 文件 | 主题 | 示例 |
|---|---|---|---|
| 01 | `01-overview.md` | 全景：定位（C 级速度 + Lisp 级元编程 + 数学记法）、设计哲学（多重派发/JIT/动态类型可注解/列主序数组）、1.13 现状与新前端、版本演进、工具链一览、学习方法 | — |
| 02 | `02-hello.md` | 第一个程序：REPL 四模式、脚本与 `julia` CLI 旗标、println/print/show 差、ARGS 与 `@main` 入口、include 加载 | `02_hello` |
| 03 | `03-numbers.md` ⭐改 | 数值类型与**数值稳定**：整型/浮点、有理数/复数、整除家族、promote/convert、**抵消/ulp/Kahan/稳定求根**（改版二扩容） | `03_numbers` |
| 04 | `04-control.md` | 控制流：if/三元/短路、while/for、range 与 step、break/continue/标签、嵌套循环与数组遍历顺序 | `04_control` |
| 05 | `05-functions.md` | 函数：定义形式、返回类型注解、位置/关键字/可选/变长参数、匿名函数、do 块、函数是值、操作符即函数、管道 | `05_functions` |
| 06 | `06-dispatch.md` ⭐ | 多重派发：方法概念、按全部实参选方法、方法表与歧义、抽象参数收窄、convert 与返回类型 | `06_dispatch` |
| 07 | `07-typesystem.md` ⭐ | 类型系统：类型树、抽象/具体、Union/Union{}/Nothing/missing、isa/supertype、类型是一等值、primitive type | `07_typesystem` |
| 08 | `08-structs.md` | 结构体：struct/mutable、@kwdef、内/外部构造器、参数化 struct、单例与不可变语义 | `08_structs` |
| 09 | `09-arrays.md` ⭐ | 数组：Array{T,N}、构造族、索引/切片/end/eachindex、@view、列主序、push!/cat、LinearAlgebra（乘/\、det、特征值） | `09_arrays` |
| 10 | `10-broadcast.md` ⭐ | 广播：`.` 语义、融合、.+=、@. 宏、自定义广播（BroadcastStyle）、标量/向量陷阱 | `10_broadcast` |
| 11 | `11-collections.md` | 集合：Dict/Set/tuple/Pair、get!/delete!、sort 家族、迭代器（enumerate/zip/Iterators.*）、comprehension/generator | `11_collections` |
| 12 | `12-strings.md` | 字符串：Char/码点、UTF-8 与不可变、插值、split/join/strip、正则 match/eachmatch、Printf 格式化 | `12_strings` |
| 13 | `13-linalg.md` ⭐新增 | **线性代数与稀疏矩阵**：分解复用（lu/qr/cholesky）、特征值/SVD/条件数、最小二乘、SparseArrays/稀疏求解、BLAS 线程（改版二新增；原异常并入 22） | `13_linalg` |
| 14 | `14-macros.md` ⭐ | 元编程：Expr、quote/:()、宏定义与卫生 esc、macroexpand、eval 与世界年龄、@generated 一瞥 | `14_macros` |
| 15 | `15-generics.md` | 参数化：where 子句、参数化方法、Type{T} 捕获、Val 值分派、自定义 AbstractVector 子类型白嫖整个生态 | `15_generics` |
| 16 | `16-performance.md` ⭐ | 性能：全局变量之恶、类型稳定性、@code_warntype（InteractiveUtils 坑）、计时/计配额、@inbounds/@simd、视图 vs 拷贝、编译时延三段论 | `16_performance` |
| 17 | `17-pkg.md` ⭐ | 包与环境：Pkg REPL 模式、add/instantiate/status、Project vs Manifest、环境栈、registry、本地路径与 [sources]、测试目标、extensions 一瞥 | `17_pkgenv`（工程） |
| 18 | `18-testing.md` | 测试：@test 家族、@testset 嵌套与自定义、随机测试与 seed、runtests.jl 惯例、CI 一瞥 | `18_testing` |
| 19 | `19-files.md` | 文件与 IO：open/do、read/write、逐行处理、Serialization、路径与 walkdir、临时目录、流缓冲 | `19_files` |
| 20 | `20-concurrency.md` | 并发与并行（原 20+21 合并）：@async/Channel 流水线、线程池、@threads/@spawn、竞争三板斧 | `20_concurrency`（`-t 4`） |
| 21 | `21-randomstats.md` ⭐新增 | **随机与统计**：Random 子流/Xoshiro、描述统计、蒙特卡洛（π/积分）、CLT、置信区间覆盖率（改版二新增） | `21_randomstats` |
| 22 | `22-errors-debugging.md` | 错误与调试（原 13+23 合并）：异常族、自定义异常、1.13 栈跟踪、即时工具、Profiler、生态表 | `22_errdebug` |
| 23 | `23-ccall.md` | C 互操作（原 22 顺移）：ccall/@ccall、类型映射、@cfunction 回调、指针三招 | `23_ccall` |
| 24 | `24-miniode.md` | 实战：迷你 ODE 求解器（包工程 MiniODE：问题-算法-解三件套、Euler/RK4/RKF45 自适应、收敛阶与能量守恒测试、SciML 同款架构） | `24_miniode`（工程） |

吸收旧内容：旧指南的安装/REPL 说明压缩进 01/02；分派/数组章节按新结构重组；
示例代码全部重写（旧的只跑不改错、无断言）。

## 6. 示例与验证

- 每个示例目录含 `main.jl`（函数定义 + 演示输出 + `@assert` 自检 + 末行 `==== NN 结束 ====` 标记）
  与 `runtests.jl`（`include("main.jl")` + @testset 断言套件）。
- `main.jl` 用 `# ═══ N.M 标题` 分节，与正文小节号一致。
- `build.ps1`（pwsh 7，UTF-8 无 BOM，参数 `-All/-Example NN_topic/-Clean`）三层验证：
  1. 运行层：`julia --startup-file=no --history-file=no --check-bounds=yes main.jl [args]` → exit 0 + stdout 含结束标记
  2. 测试层：`julia --startup-file=no runtests.jl` → exit 0
  3. 特判：17（instantiate + 演示 + Pkg.test 风格 runtests）、20（全部加 `-t 4`）、24（包工程 instantiate + CLI 运行）
- 02 运行层带固定示例参数；所有 `@main`/ARGS 入口容忍空参数（默认演示路径）。

## 7. 交付物清单

1. `julia/docs/01-overview.md` … `24-miniode.md`（24 章）
2. `julia/examples/02_hello/` … `24_miniode/`（23 个示例目录）
3. `julia/build.ps1`（重写）
4. `julia/CHEATSheet.md`（语法速查 + 1.13 坑位索引）
5. `julia/README.md`（重写：定位、目录结构、章节索引表、构建工具链、验证命令、相关教程）
6. 删除：`julia/Julia编程指南.md`、`julia/julia_demo.txt`、旧 `julia/examples/*.jl`
7. 根 `README.md` julia 条目微调（三处）
8. 记忆文件：`julia-tutorial-build.md`（1.13 实测坑位 + 结构）

## 8. 风险与对策

| 风险 | 对策 |
|---|---|
| 1.13 API 与网上资料（1.9/1.10 时代）不一致 | 所有 API 先实测再定稿；坑位即素材（InteractiveUtils、@main 形式、Pkg.activate kwargs） |
| 无官方格式化器，"lint 层"缺位 | 用 `--check-bounds=yes` 作严格运行层替代；风格自律（4 空格缩进、JuliaStyle 惯例） |
| Pkg 章节离线可验证性 | 只用 stdlib + 本地 [sources] 路径依赖（实测离线全通）；registry/add 网络操作只写文档不动手 |
| 多线程示例的不稳定性 | 竞争演示用小规模确定触发（或退化为"可能丢更新"的表述）；聚合用确定性模式 |
| 每示例双文件 ×23 ×多层验证的耗时 | 批次验证（每 4 个示例跑一次 build.ps1 -Example）；julia 启动 ~0.3s 可接受 |
| 旧文件删除不可逆 | git 历史保留；一次提交内完成删除 + 新结构 |
