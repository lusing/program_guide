# measuretheory 教程 · 工作计划表

Spec: `docs/superpowers/specs/2026-10-19-measuretheory-design.md`
Plan: `docs/superpowers/plans/2026-10-19-measuretheory.md`

**双支柱书源（2026-10-19 用户二次指令）**：
- 主线：严加安《测度论讲义》第二版（00-47 章骨架）。书页 N ↔ PDF 奇数页
  `2·ceil((N+15)/2)−1`（对页重复扫描）。OCR 骨架在 `build/ocr/yan_full/`（gitignore）。
- 第二支柱：袁德美–王学军《测度论基础与高等概率论》上册（338 页 PDF，
  章 1-12）+ 下册（373 页 PDF，章 13-25）。**两册均有文字层 + 内嵌书签**
  （免 OCR），取材用 `tools/extract_yuan.py`（get_text 直出，落
  `build/ocr/yuan_v1_pNNN.txt` / `yuan_v2_pNNN.txt`）。目录全文见
  `build/ocr/yuan_toc.txt`。袁上册 3-12 章与本书 01-34 章同构（作第二印证
  源）；袁下册 13-25 章为高等概率论主体，独占 48-56 章全谱。

本表为逐批工作文档，随进度勾选。

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
| 07 | `MeasurableSpace.comap`/`comap_eq_generateFrom`/`comap_generateFrom`/`measurable_generateFrom`（MeasurableSpace/Basic.lean:93-238）；`Real.borel_eq_generateFrom_Iic_rat`/`Iio_rat`（Constructions/BorelSpace/Real.lean） | MeasureTheory.MeasurableSpace.Basic 等 |
| 08 | **`MeasurableSpace.induction_on_inter`（MeasureTheory/PiSystem.lean:692，谓词式 π-λ，DynkinSystem 实现）✓（修正 B0 侦察"NONE"结论）**；`Continuous.measurable`；`fun_prop` 接管 Measurable 格/算术 | MeasureTheory.PiSystem |
| 09 | `MeasureTheory/Function/Egorov.lean`（Egorov）+ `ConvergenceInMeasure.lean` | MeasureTheory.Function.Egorov |
| 10 | `lintegral`（Integral/Lebesgue/Basic.lean:48 noncomputable irreducible_def）+ `MeasureTheory.integral`（Integral/Bochner/Basic.lean:156——**Bochner 积分即 integral**）+ 简单函数逼近 `Function/SimpleFuncDense.lean`、`SimpleFuncDenseLp.lean` | MeasureTheory.Integral.Lebesgue.Basic 等 |
| 11 | MCT=`lintegral_iSup`（Integral/Lebesgue/Add.lean:34）、Fatou=`lintegral_liminf…`（Add.lean:202 起，公开版正名时再核）、DCT=`tendsto_integral_of_dominated_convergence`（Integral/DominatedConvergence.lean:57） | 同左 |
| 12 | `SignedMeasure`、`Measure/Decomposition/Hahn.lean`、`Decomposition/RadonNikodym…`（rnDeriv 在 Covering/Differentiation 与 Decomposition/IntegralRNDeriv）、`haveLebesgueDecomposition` | MeasureTheory.Measure.Decomposition.* |
| 13 | `MeasureTheory.Lp`（Function/LpSeminorm/ 目录） | MeasureTheory.Function.LpSeminorm |
| 14 | ba：**无**（通道分工） | — |
| 15 | Daniell：**无**（通道分工） | — |
| 16 | `MeasureTheory.integral` 即 Bochner；`AEStronglyMeasurable`；`Integral/Bochner/VitaliCaratheodory.lean` 也在 | 同 10 |
| 17 | **B4 实测**：`MeasurableSpace.prod`、投影 `measurable_fst/snd`、配对 `Measurable.prodMk`、矩形 `MeasurableSet.prod`、任意族 `measurable_pi_iff`/`measurable_pi_apply`（注意：`Measurable.abs` 不存在，常值幂走 `Measurable.pow_const`；`Measurable.preimage` 应为 `MeasurableSet.preimage (ht) (hf)` 参数序） | Mathlib.MeasureTheory.Measure.Prod |
| 18 | **B4 实测**：`Measure.prod`/`prod_prod`（Measure/Prod.lean:231 矩形账，无 MeasurableSet 前提）+ Tonelli `lintegral_prod`/`lintegral_prod_swap`（同文件）+ Fubini `integral_prod`/`integral_prod_symm`（Integral/Prod.lean:444-467）+ `dirac_prod_dirac`/`prod_swap` | MeasureTheory.Measure.Prod / MeasureTheory.Integral.Prod |
| 19 | **B4 实测**：`Kernel.comp`（记号 `∘ₖ`，Composition/Comp.lean）+ 单位元 `Kernel.id`/`id_comp`/`comp_id` + dirac 型核 = **`Kernel.deterministic`**（无 Kernel.dirac！）+ 金子引理 `deterministic_comp_deterministic`（CompMap.lean:50：确定性核复合 = 映射复合）+ `Kernel.prod`（并排，需 import Composition.Prod） | Mathlib.Probability.Kernel.Composition.* |
| 20 | **B4 实测三连**：`Measure.pi`（Constructions/Pi.lean，[Fintype ι] 有限版）+ **`Probability/ProductMeasure.lean`：`Measure.infinitePi`（任意族概率的无穷乘积，柱集 AddContent→Carathéodory 路线=严书 §4.4 原文）**+ `isProjectiveLimit_infinitePi`/`infinitePi_map_restrict`/`infinitePi_eq_pi [Fintype]`+ 验收灵魂 `piContent_tendsto_zero`；`isProjectiveMeasureFamily_pi`（pi 族相容性实例） | Mathlib.Probability.ProductMeasure / MeasureTheory.Constructions.Pi |
| 21 | **`Probability/Kernel/IonescuTulcea/`（Maps/PartialTraj/Traj.lean）✓ B4 实测**：`ProbabilityTheory.traj`/`trajMeasure μ₀ κ`/`eq_traj`/`condExp_traj`（核族无穷复合的存在性=Tulcea）+ `Constructions/Projective.lean`：`IsProjectiveMeasureFamily`/`IsProjectiveLimit`（谓词+`measure_cylinder`+`unique` 唯一性）+ `ProjectiveFamilyContent.lean`：`projectiveFamilyContent`（柱集内容构造=Carathéodory 侧）——**PLAN 原"mathlib 无"结论作废**；Kolmogorov 存在性（一般相容族）仍无 → Isabelle Projective_Limit 扛 | Mathlib.Probability.Kernel.IonescuTulcea.* / MeasureTheory.Constructions.Projective |
| 22 | 投影极限：同 21（`IsProjectiveLimit` 谓词即本章主角）；随机 Daniell：无（docs+数值承载） | — |
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
| 48 | 概率不等式族：视侦察（Chebyshev/Markov 手作先例=第 10 章；Kolmogorov 最大值不等式在 `Martingale/` 有近亲 `submartingale_max_mul_le`，独立和版视侦察）→ 大概率通道分工 | — |
| 50 | 弱大数律：`Probability/Moment`? 视侦察；Khinchin 可经特征函数手作；Markov LLN 三行内核（Markov 不等式+Chebyshev）照第 10 章先例 | — |
| 51 | `Probability/StrongLaw.lean`（`strong_law_ae` 族）✓ | Mathlib.Probability.StrongLaw |
| 52 | `Probability/CentralLimitTheorem.lean`：`tendstoInDistribution_inv_sqrt_mul_sum_sub` ✓ | Mathlib.Probability.CentralLimitTheorem |
| 53-56 | 无穷可分/普遍极限/稳定分布/重对数律：mathlib **无**（通道分工；Lévy-Khinchin 表示与 LIL 均缺基础设施） | — |

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
| 44/49 | `Probability/Characteristic_Functions.thy` | 特征函数（char_distribution 族；Lévy 连续性视正名） |
| 52 | `Probability/Central_Limit_Theorem.thy` | CLT（iid 版；Lindeberg 条件版视侦察） |
| 13 | Lp：**无 LPspace** → 仅 Lean | — |
| 48 | 概率不等式族：视侦察（`Probability/Inequalities`? 多半仅 Markov 型） | — |
| 53-56 | 无穷可分/普遍极限/稳定/重对数律：**无** → 通道分工 | — |

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
| 07 | measurable-maps | 2.1 | ✓ | · | ✓ | ✓ | ✓ | B2 | ✅ |
| 08 | functional-monotone-class | 2.2 | ✓ | · | ✓ | ✓ | ✓ | B2 | ✅ |
| 09 | convergence-modes | 2.3 | ✓ | · | ✓ | ✓ | ✓ | B2 | ✅ |
| 10 | integral | 3.1 | ✓ | ✓ | ✓ | ✓ | ✓ | B3 | ✅ |
| 11 | limit-theorems | 3.2 | ✓ | ✓ | ✓ | ✓ | · | B3 | ✅ |
| 12 | signed-measures | 3.3 | ✓ | ✓ | ✓ | ✓ | · | B3 | ✅ |
| 13 | lp-spaces | 3.4 | ✓ | · | ✓ | ✓ | · | B3 | ✅ |
| 14 | linfty-dual | 3.5 | 分工 | · | ✓ | ✓ | ✓ | B3 | ✅ |
| 15 | daniell | 3.6 | 分工 | · | ✓ | ✓ | ✓ | B3 | ✅ |
| 16 | bochner-integral | 3.7 | ✓ | ✓ | ✓ | ✓ | · | B3 | ✅ |
| 17 | product-sigma | 4.1/袁10.1 | ✓ | · | ✓ | ✓ | ✓ | B4 | ✅ |
| 18 | fubini | 4.2/袁10.2-10.3 | ✓ | ✓ | ✓ | ✓ | · | B4 | ✅ |
| 19 | kernels | 4.3 | ✓ | · | ✓ | ✓ | ✓ | B4 | ✅ |
| 20 | infinite-products | 4.4/袁10.4.1 | ✓ | ✓ | ✓ | ✓ | · | B4 | ✅ |
| 21 | kolmogorov-tulcea | 4.5/袁10.4.2-10.4.3 | ✓ | ✓ | ✓ | ✓ | ✓ | B4 | ✅ |
| 22 | projective-limits | 4.6-4.7 | ✓ | ✓ | ✓ | ✓ | · | B4 | ✅ |
| 23 | topology-borel | 5.1/袁2+3.4 | ✓ | · | ✓ | ✓ | ✓ | B5 | ✅ |
| 24 | riesz | 5.2/袁11.2.3 | ✓ | · | ✓ | ✓ | · | B5 | ✅ |
| 25 | regular-measures | 5.3/袁11.2.1-11.2.2 | ✓ | · | ✓ | ✓ | · | B5 | ✅ |
| 26 | c0-dual | 5.4/袁11.2.3 | ✓ | · | ✓ | ✓ | · | B5 | ✅ |
| 27 | lusin | 5.5/袁11.3 | ✓ | · | ✓ | ✓ | · | B5 | ✅ |
| 28 | product-topological | 5.6/袁11.4 | ✓ | · | ✓ | ✓ | · | B5 | ✅ |
| 29 | polish | 5.7/袁2.4+11 | ✓ | · | ✓ | ✓ | · | B5 | ✅ |
| 30 | euclidean-convergence | 6.1/袁12.3 | ✓ | ✓ | ✓ | ✓ | · | B6 | ☐ |
| 31 | weak-convergence | 6.2/袁12.2 | ✓ | ✓ | ✓ | ✓ | · | B6 | ☐ |
| 32 | tightness-prohorov | 6.3/袁12.7 | ✓ | · | ✓ | ✓ | · | B6 | ☐ |
| 33 | metrization | 6.4/袁12.1 | ✓ | · | ✓ | ✓ | · | B6 | ☐ |
| 34 | vague-convergence | 6.5/袁12.6 | 分工 | · | ✓ | ✓ | · | B6 | ☐ |
| 35 | independence | 7.1/袁13 | ✓ | · | ✓ | ✓ | ✓ | B7 | ☐ |
| 36 | conditional-expectation | 7.2/袁15.1-15.2 | ✓ | ✓ | ✓ | ✓ | · | B7 | ☐ |
| 37 | regular-conditional | 7.3/袁15.3-15.5 | ✓ | · | ✓ | ✓ | · | B7 | ☐ |
| 38 | uniform-integrability | 7.4/袁9.3 | ✓ | · | ✓ | ✓ | · | B7 | ☐ |
| 39 | esssup | 7.5 | ✓ | · | ✓ | ✓ | ✓ | B7 | ☐ |
| 40 | analytic-sets | 7.6 | 分工 | · | ✓ | ✓ | ✓ | B7 | ☐ |
| 41 | martingale-inequalities | 8.1 | ✓ | · | ✓ | ✓ | ✓ | B8 | ☐ |
| 42 | martingale-convergence | 8.2 | ✓ | · | ✓ | ✓ | ✓ | B8 | ☐ |
| 43 | local-martingales | 8.3 | 分工 | · | ✓ | ✓ | ✓ | B8 | ☐ |
| 44 | bochner-theorem | 9.1/袁17.4 | ✓ | ✓ | ✓ | ✓ | · | B9 | ☐ |
| 45 | minlos-sazonov | 9.2 | 分工 | · | ✓ | ✓ | · | B9 | ☐ |
| 46 | minlos | 9.3 | 分工 | · | ✓ | ✓ | · | B9 | ☐ |
| 47 | gaussian-measures | 9.4/袁16 | ✓ | · | ✓ | ✓ | · | B9 | ☐ |
| 48 | prob-inequalities | 袁14 | 分工 | · | ✓ | ✓ | ✓ | B10 | ☐ |
| 49 | characteristic-functions | 袁17-18 | ✓ | ✓ | ✓ | ✓ | ✓ | B10 | ☐ |
| 50 | lln | 袁19 | ✓ | · | ✓ | ✓ | ✓ | B10 | ☐ |
| 51 | slln | 袁20 | ✓ | · | ✓ | ✓ | · | B11 | ☐ |
| 52 | clt | 袁21 | ✓ | ✓ | ✓ | ✓ | · | B11 | ☐ |
| 53 | infinitely-divisible | 袁22 | 分工 | · | ✓ | ✓ | ✓ | B11 | ☐ |
| 54 | universal-limits | 袁23 | 分工 | · | ✓ | ✓ | ✓ | B12 | ☐ |
| 55 | stable-laws | 袁24 | 分工 | · | ✓ | ✓ | ✓ | B12 | ☐ |
| 56 | lll | 袁25 | 分工 | · | ✓ | ✓ | ✓ | B12 | ☐ |
| 57 | cheatsheet | — | · | · | · | · | · | B12 | ☐ |

单元统计：Lean 45 / Isabelle 15 / Julia 58 / Python 58 / Prolog 30 ≈ 206。

袁书页码速查（PDF 页=文字层直出，无对页重复）：上册 338 页（第 1-12 章：
袁10 乘积 pdf247 / 袁11 局部紧 pdf272 / 袁12 弱收敛 pdf296）；下册 373 页
（袁13 独立 pdf11 / 袁14 不等式 pdf34 / 袁15 条件期望 pdf64 / 袁16 多维
正态 pdf96 / 袁17-18 特征函数 pdf111,145 / 袁19-21 大数律-CLT pdf159,184,216 /
袁22-25 无穷可分-重对数律 pdf247,269,308,344）。

## 3. 批次进度

- [x] B0 基建（OCR 全书 144 奇数页 ✓ / 侦察 ✓ / 骨架冒烟 2/2 ✓ / build.ps1 ✓ / README ✓ / 00 导言 209 行 ✓）
- [x] B1 01-06 集类与测度（docs 6 篇 200-237 行 / Lean 6 / Julia 6 / Python 6 / Prolog 5；23/23 全绿；docs 扩写补严书 1.3.5 概率化引理、1.4.4/1.4.5 半环验收工序、§1.5 ℝⁿ 盒半环与高维分布函数、§1.6 逼近定理全文）
- [x] B2 07-09 可测映射（docs 3 篇 200/201/232 行 / Lean 3 / Julia 3 / Python 3 / Prolog 3；12/12 全绿；π-λ 引擎 induction_on_inter 完整重放（含机器抓出"补集需总质量相等"）、垫高技巧与 f∨g 公式机器版、TendstoInMeasure 三件套 + Egorov xⁿ 实弹）
- [x] B3 10-16 积分与 Lp（**全部完成，终态 -All 64/64 全绿**——批 1：10-11 章 10/10（三步构造+Markov 手作+L⁰ 距离、MCT 对角线+Fatou+DCT 三反例机、Isabelle MT10/MT11）；批 2：12 章 4/4（Jordan-Hahn 骨架+Lebesgue 分解 H-类+RN 定理、RN_derivI 还原、位掩码 Hahn 穷举）；批 3：13-16 章 13/13——13：三不等式+Riesz-Fischer 六步账+对偶装配线+σ-有限反例（Lean Cauchy 六平方和 nlinarith）；14-15 通道分工（ba 空间/自然密度荷死亡现场、Daniell 五步流水线+非 Stone 反例）；16：强可测/Pettis 三档表+对角线反例六步骨架+ASP 注记（integral 即 Bochner、MT16 向量和））
- [x] B4 17-22 乘积空间（**25/25 全绿**——docs 6 篇 201-212 行；Lean 6 件：矩形/对角线预像、dirac 折叠+Tonelli 坍缩、deterministic 复合=映射复合+两态恒等、infinitePi 柱集账 2⁻ⁿ、唯一性实例化+traj 锚点、投影极限换算表；Isabelle 4 件（MT18/20/21/22）：矩形账、n 次全正面 inverse(2)^n、distr_restrict 相容性、塔边际账；Julia 6/Python 6/Prolog 3：闭包算法、两张罚单、CK+平稳分布、三组硬币账、相容检查器+Fréchet 反例、Cantor/高斯塔。**B4 侦察三连大发现**：mathlib 4.33.1 已有 IonescuTulcea 全形式化（traj/trajMeasure）+ Measure.infinitePi 任意族无穷乘积（柱集 AddContent→Carathéodory=严书 §4.4 同路）+ IsProjectiveLimit 谓词族——21/22 章 Lean 从"分工"升级为 ✓）
- [x] B5 23-29 拓扑测度（**22/22 全绿，终态 -All 111/111**——docs 7 篇 191-218 行：网/滤子对照表+Borel 层级图+Ba/B 有限反例、RMK 四步+mathlib 构造对照表+局部紧用量清单、三档正则+反例档案+层级表、c₀*/符号 Radon+弱*预告、Lusin 三版等价+Cauchy 传染骨架+Egorov 双胞表、截口引理解剖+无穷乘积关卡、胎紧三步+距离改造工具箱+判据表；Lean 7 件：RealRMK 主定理/Regular instance 算术/BorelSpace 三登记/紧矩形账；Julia 7/Python 7/Prolog 1：三明治构造、R-S 透视 δ₀、p=∞ 近距对论证、非紧反例 sup 恒 1/2、ρ₀ 边界爆炸。**Julia 抓出真数学错**：非 T₁ 有限空间 Ba ⊊ B（修正 docs 想当然））
- [ ] B6 30-34 测度收敛
- [ ] B7 35-40 概率选讲
- [ ] B8 41-43 鞅
- [ ] B9 44-47 无穷维
- [ ] B10 48-50 袁下册 I（概率不等式/特征函数/弱大数律）
- [ ] B11 51-53 袁下册 II（强大数律/CLT/无穷可分）
- [ ] B12 54-57 袁下册 III（普遍极限/稳定分布/重对数律/收官 CHEATSheet）

**袁书整合备忘（2026-10-19 二次指令）**：原 48-50 三章（clt/slln/cheatsheet）
扩充为 48-57 十章——袁下册 13-25 章全谱入列（13→35 章、14→48、15→36-37、
16→47、17-18→49（17.4→44）、19→50、20→51、21→52、22→53、23→54、24→55、
25→56），收官移至 57。袁上册作 01-34 章第二印证源（书节列"袁X.Y"）。
袁书取材免 OCR（文字层直出，`tools/extract_yuan.py`）。

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
11. （B2）Lean 生成族 `⋃ a, {t a}` 的成员关系必须先
    `simp only [Set.mem_iUnion, Set.mem_singleton_iff]` 剥开再
    `rintro ⟨r, rfl⟩`；对 Membership 外壳直接上 rfl 模式，报错
    形如"not an inductive datatype / invalid equality proof"且
    指向误导位置。
12. （B2）`measurable_generateFrom` 造**陪域** σ-代数：`Measurable[m]`
    方括号语法只能改值域侧，须 `@Measurable γ β _ (…generateFrom s)`；
    generateFrom 与 ℝ 环境实例不 defeq，两步换算
    `(BorelSpace.measurable_eq).trans Real.borel_eq_generateFrom_Iic_rat`
    （方向：inst = borel = generateFrom）后再 rw/exact。
13. （B2）裸 `Tendsto`/`atTop` 要 `open Filter`，`𝓝` 还要
    `open scoped Topology`——否则 autoImplicit 把未知记号静默吞成
    哑变量，错误在下游以 "Function expected at 𝓝" 出现。
14. （B2）ℝ 上 volume 双实例（MeasureSpace 派生 vs
    Real.measurableSpace）在 a.e. 陈述与测度项缝合处打架——a.e.
    定理改带自由测度参数 + 零点集假设（μ {1} = 0），调用处喂
    volume，绕开实例统一。`Real.volume` 不是常量名（volume 是
    MeasureSpace 记号）；`Real.volume_Icc` 要 import
    Measure.Lebesgue.Basic。
15. （B2）谓词式 π-λ（induction_on_inter）重放"π-系上相等 ⟹ 相等"
    时，补集一步 rw measure_compl 需要 μ Ω = ν Ω——两测度在 π-系
    上相等不自动给总质量相等，须先证（⋃ₙ Iic ↑n = ℝ 下方连续 +
    iSup_congr）。机器抓出的真数学缺口，第 06 章穷竭列的伏笔。
16. （B2）SWI `subset/2` 参数序是 (Sub, Super)：当"枚举子列表"用
    会反向枚举超集直接爆栈——自制 sublist/3，且 skip 子句必须同
    时消耗源表。另：整数 0 与浮点 0.0 的**项统一**失败（= 不是 =:=），
    结果断言统一用整数。
17. （B2）Julia 顶层 for 循环体内改全局计数器须 `global n += 1`，
    否则 soft-scope 警告后 UndefVarError。
18. （B2）精确分数版牛顿迭代分母按 c^(2^k) 双重指数增长：30 步挂死
    （天文数字位数）；且收敛比率是 1−√t（t 贴近 1 才快）。步数
    节制 + t 选近 1；"从下方单调"断言用精确 `p*p <= t`，浮点差
    符号在 1e-14 量级不可靠。
19. （B2）数值实验设计两次翻案：打字机在有限 Ω 上无法依测度收敛
    （最小原子 1/6 逼出"终归为空"退化定理）；"前 K 层光柱并集"
    的 Egorov 挖集构造错误（并集测度是 1 不是 ε）——正确载体是
    逃逸尖峰 + 尾集嵌套并。**断言前先手推测度值**的铁律再立新功。
20. （B3）mathlib 4.33 断代：`lintegral_add` 已降级为内部件
    （lintegral_add_aux），主推 `lintegral_add_left`（单边可测）；
    `Set.indicator_of_not_mem` 不存在——非成员分支 `simp [hx]`，
    成员分支 `Set.indicator_of_mem hx` 仍在；pow 单调用
    `pow_le_pow_left₀`（带 0 ≤ a）而非 pow_le_pow_left（那是
    无序 Monoid 版，ℝ 无实例）。
21. （B3）`Tendsto.congr'` 等式方向反直觉：h : f₁ =ᶠ f₂ 配
    Tendsto f₁ 产 f₂（要 .symm 垫）；`ae_of_all` 的位置参数 μ 在
    定理应用参数位上推不出，须显式喂；∫ x in s 记号与显式
    (volume).restrict 形式因 volume 双实例不能直接互换，结论侧
    用 `simpa` 归一（∫0=0 由 simp 收）。
22. （B3）Python 先 print 首标记后重包 TextIOWrapper：块缓冲管道
    下首行滞留旧 wrapper 缓冲丢失（build 判 FAIL 而输出从第二行
    开始）——全 ASCII 输出的文件干脆不换 wrapper。
23. （B3）Isabelle：`nn_integral_indicator` 本身是 simp 引理，
    自己再 add nn_integral_count_space_finite 反而把 simp 带偏
    （报 False）；text 注释里的 \<^sub> 类 antiquotation 在
    document=false 下直接炸——注释写纯文本；isabelle build -d
    路径必须 /cygdrive 形式（裸 G:/ 报 Illegal character ":"，
    且经 tail 管道时假绿——坑 3 的 Isabelle 版）。
24. （B3）心算翻车三连（机器全部如实揭发）：Isabelle 2·1+3·1=5
    写成 3；Julia humps 的 x=103 还在最后一支脊背 [100,110] 内
    （8 拍非 0）；covers 的半开边界 x=1/n 处不覆盖。**Markov 最紧
    点的比值 27/32 这类断言，先在纸上通分再写进代码。**
25. （B3）mathlib RN 族四坑：① `withDensity_rnDeriv_eq (μ ν)` 的
    结论里**基测度是第二个参数**（μ 是被还原者），`μ.rnDeriv ν`
    点记号方向极易读反；② `withDensity_absolutelyContinuous` 在
    MeasureTheory 根、`withDensity_rnDeriv_eq` 在 MeasureTheory.
    Measure——两级命名空间，裸名/限定名分开写；③
    `HaveLebesgueDecomposition` 实例引理带 Measurable 前提，TC
    不自动搜，plain `have` 供入（haveI 反被 linter 点名）；④ 具体
    dirac 项代入让 whnf 超心跳——通用陈述既快又贴本体。
26. （B3）`lake env lean` 单文件检查的输出若用 grep 过滤后再 head，
    可能漏看后续 error 行而误判"全绿"（Ch12 实录：过滤后只见
    warning，full build 才见 unknown identifier）——判定以全量
    `lake build` 退出码为准。
27. （B3）Isabelle `RN_derivI` 的真实签名只要两条（f 可测 +
    density M f = N）——SOME-选择子的良定还原，不含 σ-有限/
    绝对连续（存在性在 RN_deriv_unique_sigma_finite 族）；凭
    "RN 定理"的印象脑补签名会写出一整套展开不了的实例义务。
28. （B3）mathlib 的 Hölder 挂在 **ContinuousLinearMap** 命名空间
    （Function/Holder.lean，非 MeasureTheory）；Lp 结构在
    LpSpace/Basic、范数实例要 Fact(1≤p)。惊喜件：nlinarith 能
    从"六个交叉差平方非负"自动合成 Lagrange 恒等式路线——
    Cauchy 不等式的教科书证明压成一行提示列表。
29. （B3）有理数 p-范数：1/p 根超出 ℚ——精确账记"p 次幂和"
    （平方账），Minkowski 的 p=1 精确、p=2,4 浮点容差；Cauchy/
    对偶全部平方化后是整数不等式。"哪个量在哪个域可精确"必须
    设计实验前先想清楚。
30. （B3）Julia 三连：单行多 const 语法炸（分开写）；is_measurable
    的 setdiff(A,B) 空是 A⊆B（要的是 B⊆A，方向写反）；向量值
  mid 混标量 norm 崩（using LinearAlgebra: norm）。掩码索引
    vals[mask+1] 偏移两撞。
31. （B3）Prolog：大写 I 开头的 `Ifun` 是**变量**不是谓词
    （报"Operator expected"在调用行，定位偏移）；q(N,D) 有理数
    体系里伪 1r2 记号无效（SWI 的 r/2 只在 is 算术里有效）。
32. （B3）Isabelle 收尾三式：有限空间可积性 simp 需配
    nn_integral_count_space_finite 算出有限和；`has_bochner_
    integral_eq` 是唯一性方向（两 has_bochner ⟹ 等式），改
    积分值用 `h[simplified 引理]` 在结论内改写；∫ 绑定器已
    λ 化，body 里再写 fun 是双重 λ（Lean 同款坑）。

33. （B4）**mathlib 4.33.1 三连大发现（B0 侦察作废）**：`Probability/Kernel/
    IonescuTulcea/`（traj/trajMeasure/eq_traj——Tulcea 全形式化）、
    `Probability/ProductMeasure.lean`（`Measure.infinitePi` 任意族无穷乘积，
    柱集 AddContent→`piContent_tendsto_zero` 验收→Carathéodory——与严书
    §4.4 逐字同路）、`Constructions/Projective.lean`（IsProjectiveMeasure
    Family/IsProjectiveLimit+unique）。且 `Measure.pi` 在 4.33 是
    [Fintype ι]——只做有限族。
34. （B4）Lean：`Measurable.abs` 不存在；`Measurable.pow` 是 f^g 双函数版，
    常值指数走 `pow_const`；`MeasurableSet.preimage` 参数序 (ht) (hf)
    （不是 Measurable.preimage）；核的 dirac 型叫 `Kernel.deterministic`
    （无 Kernel.dirac），单位元是 `Kernel.id`；`Kernel.prod` 要单独
    import Composition.Prod；`/-! -/` 或 `/-- -/` 注释直接挂 `#check`
    前会报 "expected 'lemma'"——文档注释只能贴声明。
35. （B4）Isabelle 2025-2：**全局 `interpretation product_prob_space` 触发
    "Malformed global fact / Illegal fixed variable I"**（子 locale 注册
    事故）——必须证明内局部 `interpret` 且带两参（M 与指标集 I）。
36. （B4）Isabelle：`by (rule …) auto` 对 locale 谓词目标会让 auto 合成
    σ-有限见证而**挂死**（MT18 首建 40 分钟无输出）——用显式 rule+simp
    或免 interpret 的导出引理（`emeasure_pair_measure_Times` 挂 M 侧
    locale、N 是自由变量，只需 M 侧 σ-有限见证）。
37. （B4）Isabelle：卡死会话留下 MT18.db 锁（poly 9GB 常驻）+
    `SQLITE_CONSTRAINT_PRIMARYKEY`——终结进程后删 build log db 重建。
38. （B4）Isabelle：**ennreal 的 `/` 与 `inverse` 在 simp 层不可互换**
    （`inverse 2 = 1/2` 三种 simp 战术全灭）——结论说本地方言
    `inverse (2::ennreal)`；`unfolding def by (rule …)` 失效而
    `by (simp add: def 引理)` 通过（definition 展开后 rule 无法 apply）。
39. （B4）Lean：`lake build` 零 error 但有 "This simp argument is unused"
    linter warning——build.ps1 的 lean 判定把 warning: 也算 FAIL；
    simp 参数按 linter 点名删净。
40. （B4）Julia：顶层 for 循环累计变量须 `global` 或函数封装（软作用域）；
    收敛速率账 0.3^n 在 n>20 后被浮点消去污染（比值假爆炸）——20 步内
    验证显式常数 C=3/7；二维高斯 `[x y] * Σ * v` 返回向量炸 exp——用
    `dot(v, Σ*v)`。
41. （B4）Prolog：同一谓词子句分散两处被当重定义覆盖（"Clauses not
    together"）；findall 里递归子句的自由目标变量导致重数事故
    （dist(3,·) 账 >1）——改显式两态 advance；分数求和别把 N*D 乘成
    整数（用 q(N,D) 复合项）。
42. （B4）Python 相容检查器：两两边缘一致 ≠ 整体可实现——反例族
    （完美相关对+独立对）须用 Fréchet 上确界装配总质量 < 1 判死。

43. （B5）**数值通道抓出真数学错**：非 T₁ 有限拓扑（{∅,{1},{1,2},Ω}）上
    连续函数仅常值 ⟹ Ba = {∅,Ω} ⊊ B（8 元）——"有限空间自动 Ba=B"
    的想当然被 Julia/Python/Prolog 三通道一致否决（离散有限才取等）。
44. （B5）Lean：`SeparableSpace` 在 `TopologicalSpace` 命名空间内
   （`TopologicalSpace.SeparableSpace`）而 `SecondCountableTopology`
   在根——同名家族分家；`C_c` 记号 scoped[CompactlySupported]
   （`open scoped CompactlySupported`），integrable 的 μ 是 context
   变量不是参数（`integrable f` 不喂 μ）；`Real.sin` 需 Trigonometric
   import；`volume` 双实例在乘积测度上复发（只在一侧写 ascription）；
   `Measure.Regular` 无 add instance（smul/zero 有）。
45. （B5）Isabelle→Lean 转场：`rieszMeasure_integralPositiveLinearMap`
   （NNReal 版）在根命名空间、Real 版在 `RealRMK`；`integral_dirac`
   无需可测假设（[MeasurableSingletonClass]），a 显式第二参。
46. （B5）Julia：p=∞ 的 Lusin 反例不能只用"远距理/无理对"（线性函数
    可钻 0.29 的空）——须用**近距对**（连续性把两点值锁近，1_ℚ 却差 1，
    下界 (1−osc)/2）；中点法 x² 误差 h²/24·f''≈1e-9 级（容差写 1e-9
    会假阴）；拓扑乘积非紧反例的 sup 峰在 t=dx 处（网格必须扫峰位）。
47. （B5）Python：Fraction 网格上 R-S 和的跨跳中点偏差 ~h/2 级
   （2e-4 网格给 2.5e-4 偏差）；δ-带覆盖分母 ≤Q 有理数时带宽须
   2δ/q³（q² 会因 (q+1) 重数发散成 ln）。
