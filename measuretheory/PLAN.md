# measuretheory 教程 · 工作计划表

Spec: `docs/superpowers/specs/2026-10-19-measuretheory-design.md`
Plan: `docs/superpowers/plans/2026-10-19-measuretheory.md`

书页 N ↔ PDF 奇数页 `2·ceil((N+15)/2)−1`（对页重复扫描）。OCR 骨架在
`build/ocr/yan_full/`（gitignore）。本表为逐批工作文档，随进度勾选。

## 1. 侦察结论（2026-10-19，grep 实测）

mathlib 树 = `H:/Lang/lean4/mathlib4-4.33.1`（2026 master 快照，新目录布局：
Constructions/Decomposition 拆分、Probability 扩容）。Isabelle = 2025-2。

### mathlib 锚点表（章 | 精确名/文件 | 备注）

| 章 | 锚点 | import |
|---|---|---|
| 03 | `MeasureTheory.measure_iUnion_le` 等 | MeasureTheory.Measure.MeasureSpace |
| 04 | **`OuterMeasure.toMeasure (m) (h : ms ≤ m.caratheodory)`**（Measure/MeasureSpace.lean:779）+ `toMeasure_apply`；`Measure.completion`（NullMeasurable.lean:454） | MeasureTheory.Measure.MeasureSpace / NullMeasurable |
| 05 | `StieltjesFunction R`（结构：单调+右连续）、`Monotone.stieltjesFunction`、`StieltjesFunction.outer_Ioc`（Measure/Stieltjes.lean） | MeasureTheory.Measure.Stieltjes |
| 06 | **`ext_of_generateFrom_of_iUnion` / `ext_of_generateFrom_of_cover`**（MeasureSpace.lean:61-66，π-系上相等⇒测度相等） | MeasureTheory.Measure.MeasureSpace |
| 01/02 补 | π-系 API 在 `Constructions/BorelSpace/Basic.lean`（PiSystem）；单调类定理（集合形式）mathlib 无现成名——用 `generateFrom` 最小性+π系唯一性组合呈现 | MeasureTheory.Constructions.BorelSpace.Basic |
| 08 | 函数单调类：`MeasurableSpace.induction_on` 不存在（NONE）→ 手写小件或以 `Measurable` 格引理替代 | — |
| 09 | `MeasureTheory/Function/Egorov.lean`（Egorov）+ `ConvergenceInMeasure.lean` | MeasureTheory.Function.Egorov |
| 10 | `lintegral`（Integral/Lebesgue/Basic.lean:48 noncomputable irreducible_def）+ `MeasureTheory.integral`（Integral/Bochner/Basic.lean:156——**Bochner 积分即 integral**）+ 简单函数逼近 `Function/SimpleFuncDense.lean`、`SimpleFuncDenseLp.lean` | MeasureTheory.Integral.Lebesgue.Basic 等 |
| 11 | MCT=`lintegral_iSup`（Integral/Lebesgue/Add.lean:34）、Fatou=`lintegral_liminf…`（Add.lean:202 起，公开版正名时再核）、DCT=`tendsto_integral_of_dominated_convergence`（Integral/DominatedConvergence.lean:57） | 同左 |
| 12 | `SignedMeasure`、`Measure/Decomposition/Hahn.lean`、`Decomposition/RadonNikodym…`（rnDeriv 在 Covering/Differentiation 与 Decomposition/IntegralRNDeriv）、`haveLebesgueDecomposition` | MeasureTheory.Measure.Decomposition.* |
| 13 | `MeasureTheory.Lp`（Function/LpSeminorm/ 目录） | MeasureTheory.Function.LpSeminorm |
| 14 | ba：**无**（通道分工） | — |
| 15 | Daniell：**无**（通道分工） | — |
| 16 | `MeasureTheory.integral` 即 Bochner；`AEStronglyMeasurable`；`Integral/Bochner/VitaliCaratheodory.lean` 也在 | 同 10 |
| 17 | `MeasurableSpace.prod`、`Measurable.prodMk`（Constructions/Pi.lean） | MeasureTheory.Constructions.Pi |
| 18 | `Measure.prod`、`lintegral_prod`（Integral/Marginal.lean）、`integral_prod` | MeasureTheory.Integral.Marginal |
| 19 | `Probability/Kernel/`（Kernel.comp 在 Composition/Comp.lean、Kernel.prod、Kernel.map） | ProbabilityTheory.Kernel.* |
| 20 | `Measure.pi`（Constructions/Pi.lean） | MeasureTheory.Constructions.Pi |
| 21 | Kolmogorov 相容性：mathlib **无**（Brownian 的 GaussianProjectiveFamily 是特例）→ Isabelle Projective_Limit 扛 | — |
| 22 | 投影极限同上（Isabelle）；随机 Daniell：无（通道分工） | — |
| 23 | `BorelSpace`/`borel` | Mathlib.Topology.BorelSpace? 以正名为准 |
| 24/26 | **`Integral/RieszMarkovKakutani/`（Basic/NNReal/Real）** ✓ | MeasureTheory.Integral.RieszMarkovKakutani.* |
| 25 | `MeasureTheory.Measure.Regular`（Measure/Regular.lean，class，extends IsFiniteMeasureOnCompacts+OuterRegular） | MeasureTheory.Measure.Regular |
| 27 | Lusin 字样见于 `Constructions/Polish/Basic.lean`（正名时再定）；`VitaliCaratheodory.lean` 辅助 | — |
| 29 | 波兰正则性：`Constructions/Polish/` 族 | MeasureTheory.Constructions.Polish.* |
| 30 | `Probability/CDF.lean`（cdf）；Helly 在 Isabelle | Mathlib.Probability.CDF |
| 31 | `Function/ConvergenceInDistribution.lean`：structure `TendstoInDistribution` + `Measure/Portmanteau.lean` ✓ | MeasureTheory.Function.ConvergenceInDistribution / Measure.Portmanteau |
| 32 | `Measure/Prokhorov.lean`（拼写 k）：`IsTightMeasureSet` ✓ | MeasureTheory.Measure.Prokhorov |
| 33 | `Measure/LevyProkhorovMetric.lean` ✓ | MeasureTheory.Measure.LevyProkhorovMetric |
| 34 | 淡收敛：**无**（通道分工） | — |
| 35 | `Probability/Independence/Basic.lean`（IndepSets 族）+ `Independence/ZeroOne.lean`（0-1 律）✓ | ProbabilityTheory.Independence.* |
| 36 | `MeasureTheory.condexp`（Function/ConditionalExpectation/Basic.lean）✓ | MeasureTheory.Function.ConditionalExpectation.Basic |
| 37 | `Probability/Kernel/Disintegration/Basic.lean` + `CondDistrib.lean`（condKernel）✓ | ProbabilityTheory.Kernel.CondDistrib |
| 38 | `Function/UniformIntegrable.lean` ✓ | MeasureTheory.Function.UniformIntegrable |
| 39 | `essSup`（Function/ConvergenceInMeasure.lean 等）✓ | MeasureTheory.Function.EssSup? 正名为准 |
| 40 | 解析集：mathlib **无**（SetTheory 无 analytic 命中）→ 通道分工 | — |
| 41 | `Probability/Martingale/Basic.lean`（Submartingale，Doob 极大：正名） | ProbabilityTheory.Martingale.Basic |
| 42 | **`Martingale/Upcrossing.lean` + `Martingale/Convergence.lean`** ✓（上穿不等式+收敛定理都有） | ProbabilityTheory.Martingale.Convergence |
| 43 | 局部鞅：**无**（通道分工） | — |
| 44 | `MeasureTheory.charFun [Inner ℝ E]`（Measure/CharacteristicFunction/Basic.lean）+ `Measure/LevyConvergence.lean`（`ProbabilityMeasure.tendsto_iff_tendsto_charFun`）✓ | MeasureTheory.Measure.CharacteristicFunction.Basic |
| 45/46 | Minlos：**无**（通道分工） | — |
| 47 | `gaussianReal 0 1`（CLT 文件内出现）；gaussMeasure 正名再查 | Probability.CentralLimitTheorem 等 |
| 48 | **`Probability/CentralLimitTheorem.lean`**：`tendstoInDistribution_inv_sqrt_mul_sum_sub` ✓ | Mathlib.Probability.CentralLimitTheorem |
| 49 | **`Probability/StrongLaw.lean`** ✓ | Mathlib.Probability.StrongLaw |

### Isabelle 锚点表

| 章 | 文件（src/HOL/ 下） | 内容 |
|---|---|---|
| 10/11 | `Analysis/Equivalence_Lebesgue_Henstock_Integration.thy` | has_integral_lebesgue / lebesgue_integral |
| 12 | `Analysis/Radon_Nikodym.thy` | RN_deriv |
| 16 | `Analysis/Bochner_Integration.thy` | Bochner 积分全套 |
| 17/18 | `Analysis/Binary_Product_Measure.thy` + `Finite_Product_Measure.thy` | 乘积测度/Fubini |
| 20 | `Probability/Infinite_Product_Measure.thy` | PiM 无穷乘积 |
| 21/22 | **`Probability/Projective_Limit.thy`** | **投影极限定理（Kolmogorov 扩张）** |
| 30 | `Probability/Helly_Selection.thy` | Helly 选择定理 |
| 31 | `Probability/Weak_Convergence.thy` | 弱收敛 |
| 36 | `Probability/Conditional_Expectation.thy` | conditional_expectation |
| 44 | `Probability/Characteristic_Functions.thy` | 特征函数 |
| 48 | `Probability/Central_Limit_Theorem.thy` | CLT |
| 13 | Lp：**无 LPspace** → 仅 Lean | — |

## 2. 51 章通道定案表（L/I/J/P/R；·=该通道无文件）

| 章 | slug | 书节 | L | I | J | P | R | 批 | 状态 |
|---|---|---|---|---|---|---|---|---|---|
| 00 | intro | — | · | · | · | · | · | B0 | ☐ |
| 01 | setclasses | 1.1 | ✓ | · | ✓ | ✓ | ✓ | B1 | ✅ |
| 02 | monotone-class | 1.2 | ✓ | · | ✓ | ✓ | ✓ | B1 | ✅ |
| 03 | measures | 1.3 | ✓ | · | ✓ | ✓ | ✓ | B1 | ✅ |
| 04 | extension | 1.4 | ✓ | · | ✓ | ✓ | ✓ | B1 | ✅ |
| 05 | stieltjes | 1.5 | ✓ | · | ✓ | ✓ | · | B1 | ✅ |
| 06 | approximation | 1.6 | ✓ | · | ✓ | ✓ | ✓ | B1 | ✅ |
| 07 | measurable-maps | 2.1 | ✓ | · | ✓ | ✓ | ✓ | B2 | ☐ |
| 08 | functional-monotone-class | 2.2 | ✓ | · | ✓ | ✓ | ✓ | B2 | ☐ |
| 09 | convergence-modes | 2.3 | ✓ | · | ✓ | ✓ | ✓ | B2 | ☐ |
| 10 | integral | 3.1 | ✓ | ✓ | ✓ | ✓ | ✓ | B3 | ☐ |
| 11 | limit-theorems | 3.2 | ✓ | ✓ | ✓ | ✓ | · | B3 | ☐ |
| 12 | signed-measures | 3.3 | ✓ | ✓ | ✓ | ✓ | · | B3 | ☐ |
| 13 | lp-spaces | 3.4 | ✓ | · | ✓ | ✓ | · | B3 | ☐ |
| 14 | linfty-dual | 3.5 | 分工 | · | ✓ | ✓ | ✓ | B3 | ☐ |
| 15 | daniell | 3.6 | 分工 | · | ✓ | ✓ | ✓ | B3 | ☐ |
| 16 | bochner-integral | 3.7 | ✓ | ✓ | ✓ | ✓ | · | B3 | ☐ |
| 17 | product-sigma | 4.1 | ✓ | · | ✓ | ✓ | ✓ | B4 | ☐ |
| 18 | fubini | 4.2 | ✓ | ✓ | ✓ | ✓ | · | B4 | ☐ |
| 19 | kernels | 4.3 | ✓ | · | ✓ | ✓ | ✓ | B4 | ☐ |
| 20 | infinite-products | 4.4 | ✓ | ✓ | ✓ | ✓ | · | B4 | ☐ |
| 21 | kolmogorov-tulcea | 4.5 | 分工 | ✓ | ✓ | ✓ | ✓ | B4 | ☐ |
| 22 | projective-limits | 4.6-4.7 | 分工 | ✓ | ✓ | ✓ | · | B4 | ☐ |
| 23 | topology-borel | 5.1 | ✓ | · | ✓ | ✓ | ✓ | B5 | ☐ |
| 24 | riesz | 5.2 | ✓ | · | ✓ | ✓ | · | B5 | ☐ |
| 25 | regular-measures | 5.3 | ✓ | · | ✓ | ✓ | · | B5 | ☐ |
| 26 | c0-dual | 5.4 | ✓ | · | ✓ | ✓ | · | B5 | ☐ |
| 27 | lusin | 5.5 | ✓ | · | ✓ | ✓ | · | B5 | ☐ |
| 28 | product-topological | 5.6 | ✓ | · | ✓ | ✓ | · | B5 | ☐ |
| 29 | polish | 5.7 | ✓ | · | ✓ | ✓ | · | B5 | ☐ |
| 30 | euclidean-convergence | 6.1 | ✓ | ✓ | ✓ | ✓ | · | B6 | ☐ |
| 31 | weak-convergence | 6.2 | ✓ | ✓ | ✓ | ✓ | · | B6 | ☐ |
| 32 | tightness-prohorov | 6.3 | ✓ | · | ✓ | ✓ | · | B6 | ☐ |
| 33 | metrization | 6.4 | ✓ | · | ✓ | ✓ | · | B6 | ☐ |
| 34 | vague-convergence | 6.5 | 分工 | · | ✓ | ✓ | · | B6 | ☐ |
| 35 | independence | 7.1 | ✓ | · | ✓ | ✓ | ✓ | B7 | ☐ |
| 36 | conditional-expectation | 7.2 | ✓ | ✓ | ✓ | ✓ | · | B7 | ☐ |
| 37 | regular-conditional | 7.3 | ✓ | · | ✓ | ✓ | · | B7 | ☐ |
| 38 | uniform-integrability | 7.4 | ✓ | · | ✓ | ✓ | · | B7 | ☐ |
| 39 | esssup | 7.5 | ✓ | · | ✓ | ✓ | ✓ | B7 | ☐ |
| 40 | analytic-sets | 7.6 | 分工 | · | ✓ | ✓ | ✓ | B7 | ☐ |
| 41 | martingale-inequalities | 8.1 | ✓ | · | ✓ | ✓ | ✓ | B8 | ☐ |
| 42 | martingale-convergence | 8.2 | ✓ | · | ✓ | ✓ | ✓ | B8 | ☐ |
| 43 | local-martingales | 8.3 | 分工 | · | ✓ | ✓ | ✓ | B8 | ☐ |
| 44 | bochner-theorem | 9.1 | ✓ | ✓ | ✓ | ✓ | · | B9 | ☐ |
| 45 | minlos-sazonov | 9.2 | 分工 | · | ✓ | ✓ | · | B9 | ☐ |
| 46 | minlos | 9.3 | 分工 | · | ✓ | ✓ | · | B9 | ☐ |
| 47 | gaussian-measures | 9.4 | ✓ | · | ✓ | ✓ | · | B9 | ☐ |
| 48 | clt | 袁下册 | ✓ | ✓ | ✓ | ✓ | · | B10 | ☐ |
| 49 | slln | 袁下册 | ✓ | · | ✓ | ✓ | · | B10 | ☐ |
| 50 | cheatsheet | — | · | · | · | · | · | B10 | ☐ |

单元统计：Lean 41 / Isabelle 13 / Julia 49 / Python 49 / Prolog 23 ≈ 175。

## 3. 批次进度

- [x] B0 基建（OCR 全书 144 奇数页 ✓ / 侦察 ✓ / 骨架冒烟 2/2 ✓ / build.ps1 ✓ / README ✓ / 00 导言 209 行 ✓）
- [x] B1 01-06 集类与测度（docs 6 篇 200-237 行 / Lean 6 / Julia 6 / Python 6 / Prolog 5；23/23 全绿；docs 扩写补严书 1.3.5 概率化引理、1.4.4/1.4.5 半环验收工序、§1.5 ℝⁿ 盒半环与高维分布函数、§1.6 逼近定理全文）
- [ ] B2 07-09 可测映射
- [ ] B3 10-16 积分与 Lp
- [ ] B4 17-22 乘积空间
- [ ] B5 23-29 拓扑测度
- [ ] B6 30-34 测度收敛
- [ ] B7 35-40 概率选讲
- [ ] B8 41-43 鞅
- [ ] B9 44-47 无穷维
- [ ] B10 48-50 选讲+收官

## 4. 实测坑账（随批追加，50 章汇总）

1. （B0）`tools/ocr_yan.py` render 的 f-string 嵌套 `{'p%03d' % (first+i)}` 被外层
   f-string 当替换字段在定义期求值（i 未定义 NameError）——生成代码串里嵌套
   表达式必须提出来先算或分层拼接。
2. （B0）pdf2image `convert_from_path(17, 303)` 一次性转换整段并把 PIL 页囤在
   内存（287 页撑到 10 GB 仍零写盘）——大范围渲染必须 PyMuPDF 逐页。
3. （B0）**管道假绿**：isabelle build 经 `… | tail -4` 管道调用时退出码被 tail
   吃掉，冒烟"通过"实为 FAIL——对账必须走 build.ps1 的 `$LASTEXITCODE` 直采。
4. （B0）build.ps1 空通道目录：`Find-ChannelUnits` 返回空 → `$null | Where-Object`
   在 -All（无章过滤）下透出一个 null 单元 → `Split-Path` 炸——Invoke-ScriptUnit
   加 `if (-not $units) { return }` + `@($units)` 守卫。
5. （B0）Isabelle `using assms by (rule card_mono)` 对 assumes/shows 形态引理
   解析失败（"Failed to apply initial proof method"）——用显式
   `by (rule card_mono[OF assms(2) assms(1)])`；另 `of_nat (card A)` 目标类型
   含糊（ennreal/nat 两可）会炸 of_nat_mono——避免裸 of_nat have，直接走
   `emeasure_mono` 这类结构化引理。
6. （B0）Lean 模块 doc `/-! -/` 在 import 之前报 "invalid 'import' command"
   （funanalysis 前科重现）；`measure_union` 新签名只需 (h, hs) 两参。
7. （B1）**pwsh 参数模式逗号数组丢零**：`-Chapter 01,02` 的数组元素走
   表达式解析被规整为整数 1、2（丢前导零），而单值 `-Chapter 01` 保持
   字符串 '01'——同一参数两种绑定行为。build.ps1 的章号归一化必须
   `-match '^\d+$'` 再 `'{0:D2}' -f [int]$_` 显式补零。
8. （B1）**`-replace` 与 `-f` 同行不加括号实测为 no-op**：
   `$_ -replace '^(\d+)$', '{0:D2}' -f [int]$_` 原样返回输入（运算符
   与逗号的组合解析吞掉了格式化），必须写成
   `if ($_ -match ...) { '{0:D2}' -f ... }`。隔离复现时务必用与原
   文件相同的参数类型（改 [string] 单值测试会引入新 bug 假阳/假阴）。
9. （B1）**prolog 首标记缺失假 FAIL**：build.ps1 判定单元 PASS 要求
   输出同时含 `==== NN`（头）与 `END ====`（尾），prolog 五件初稿只打
   尾标记——内容全 OK 但判 FAIL。标记协议必须两头齐全，julia/python
   同理。
10. （B1）坑 3（管道假绿）复发警告：后台任务里写
    `pwsh … | tail -50` 会把退出码换成 tail 的 0——即使 PLAN 里已记
    载，稍不留神仍会重蹈；对账永远读报告正文，不信管道退出码。
