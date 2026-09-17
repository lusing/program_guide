# Julia 教程重写实施计划（2026-09-18）

> **状态：已完成**（同日实施 + 全量终验通过；spec 见 `docs/superpowers/specs/2026-09-18-julia-tutorial-rewrite-design.md`）

**Goal:** 将 `julia/` 重写为对齐 cpp20/zig 标准的 24 章教程（docs/ 分章 + 章号=示例目录号 +
递进讲解 + 坑位清单 + 三层验证 + 实战迷你 grep 包工程）。

**Architecture:** 先建 build.ps1 验证骨架，再按批次写 23 个示例（每目录 main.jl + runtests.jl，
`# ═══ N.M` 分节标记），示例过验后按其结构撰写对应章节正文，最后清理旧文件、写 README/CHEATSheet、
全量终验、提交、写记忆。

**Tech Stack:** Julia 1.13.0（`G:\scoop\apps\julia\current\bin\julia.exe`）、PowerShell 7（pwsh）、git。

## Global Constraints（实施遵守）

- Julia 固定 `G:\scoop\apps\julia\current\bin\julia.exe`（1.13.0）；所有代码实测通过。
- 三层验证：运行层（`--check-bounds=yes` exit 0 + `==== NN 结束 ====` 标记）→ 测试层（runtests.jl）→
  特判层（17/24 Pkg 工程、21/24 `-t 4`）。
- 章号 = 示例目录号；正文 150–250 行（⭐ 章不压缩）；坑位清单 3–6 条/章。
- build.ps1 pwsh 7、UTF-8 无 BOM；脚本一律 `--startup-file=no --history-file=no`。
- 提交带 `Co-Authored-By: Claude Code <noreply@anthropic.com>`。

## Tasks（全部完成）

- [x] Task 1: build.ps1（运行/测试/工程三层 + `-All/-Example/-Clean` + runArgs/extraFlags 特判表）
- [x] Task 2: 批次 A——02_hello / 03_numbers / 04_control / 05_functions
- [x] Task 3: 批次 B——06_dispatch / 07_typesystem / 08_structs
- [x] Task 4: 批次 C——09_arrays / 10_broadcast / 11_collections / 12_strings
- [x] Task 5: 批次 D——13_errors / 14_macros / 15_generics / 16_performance
- [x] Task 6: 批次 E——17_pkgenv（工程）/ 18_testing / 19_files / 20_tasks
- [x] Task 7: 批次 F——21_threads（-t 4）/ 22_ccall / 23_debug / 24_minigrep（工程）
- [x] Task 8: docs/ 24 章正文（01 全景 + 02–24 按示例分节对应）
- [x] Task 9: CHEATSheet / README / 根 README 两处 / 删旧 17 文件 / 全量终验 / 提交 / 记忆

## 执行勘误（实施中实测发现，已写进对应章正文与坑位）

0. **24 章改版（用户反馈）**：初版 24 章为"迷你 grep"（与 cpp20/zig 对齐）；交付后用户指出——
   grep 展示的是通用系统语言能力，Julia 作为数学/科学计算语言应有特色压轴。已重做：
   `24_minigrep` → **`24_miniode`（迷你 ODE 求解器）**——问题-算法-解三件套（SciML 同款架构）、
   Euler/RK4/RKF45 嵌入式自适应步长、泛型状态（标量/向量同一份代码）、收敛阶（2×/16×）与
   单摆能量守恒（1e-10 vs Euler 的 6e-2）作性质测试、洛伦兹混沌的确定性断言。新增实测坑：
   `t0 .+ (0:n) .* h` 是惰性 StepRangeLen 不可 setindex!（须 collect）；混沌系统只能断言性质
   不能断言轨迹逼近；浮点末端须显式收口 `t[end] = tf`。

1. **`catch_stacktrace` 已移除，且 catch 里 `stacktrace(backtrace())` 只给"捕获点"**——抛错点栈要
   `stacktrace(Base.current_exceptions()[end][2])`（13/23 章；老资料普遍写错，1.13 实测确认）。
2. **`@assert` 不认 `≈ atol=` 语法**（@test 才认）——断言近似用 `isapprox(x, y; atol=...)`（17 章实测）。
3. **`@code_warntype` 属 InteractiveUtils，脚本模式不自动加载**（16 章；spec 已记录，正文再强调）。
4. **`Base.@main function main(args)` 错误形式会"立即调用"**（spec 已记录）；另实测 `-e include` 模式也触发入口、
   args=`String[]`——示例必须容忍空参数（02/24 章）。
5. **空集合 `sum(())` 抛 ArgumentError**——变长函数给 `init`（05 章）。
6. **`eachrow` 取出是一维 Vector 视图**（不是 1×N 矩阵）（09 章实测）。
7. **广播向量对齐"第一维"（与 NumPy 尾部对齐相反）**：`(2,3) .* [1,2,3]` DimensionMismatch（10 章实测）。
8. **自定义 struct 广播被当可迭代物**（`length(::T)` MethodError）——`Base.broadcastable(x::T) = Ref(x)`（10 章）。
9. **`@.` 连 `==` 都加点**（结果 BitVector）——比较留在括号外（10 章实测，作者本人先踩）。
10. **`@ccall` 吞整条比较表达式**；`name::T` 传变量值（须已定义）——断言先加括号、字面量写 `("x"::T)`（22 章）。
11. **fetch 失败任务抛 `TaskFailedException`**（原始异常在 `.task.exception`）——`@test_throws 原始类型` 不成立（20 章实测）。
12. **channel 自填自收死锁**：容量 4 无消费者时第 5 个 put! 永塞——消费放任务里（20 章一版卡死实测）。
13. **`open(p, append=true)` 关键字不生效**——追加必须 `open(p, "a")`（19 章实测）。
14. **数组推导里 `Threads.@spawn f(x) for ...` 会吞 for**——写 `Threads.@spawn(f(x))`（21 章实测）。
15. **`shuffle` 在 Random**（Base 不导出）；`lock` 是 Base 函数（非 `Threads.lock`）（21 章实测）。
16. **含 Vector 字段 struct 默认 `==` 按身份**——串行/多线程结果断言相等必须自定义 `==`（24 章 Hit 实测）。
17. **`SubString(s, lo, hi)` 空区间抛错**——高亮拼接要边界守卫（24 章实测）。
18. **`Pkg.activate` 无 `interactive` kwarg**（1.13）；**Project.toml 路径必须 `/`**（spec 已记录，17 章正文化）。
19. **`Test.Pass(:x)` 不能单参构造**——类型断言写 `Test.Pass <: Test.Result`（18 章实测）。
20. **重复 `@eval` 同一定义不产生新世界**——世界年龄演示在"已定义"状态下 MethodError 消失（14 章实测）。
21. **`typemax(Float64) == Inf`**、**`num/den` 不存在（是 numerator/denominator）**、**`round` ties-to-even**
    （03 章实测，均写进坑位）。
22. **`length` 有符号标注的类型误用**、**`I₂` 类下标标识符非法**等小项随修随记。
