import Mathlib.Probability.BrownianMotion.Basic

/-!
# 第 60 章 布朗运动（Lean）

胡书 §8.2 的机器侧：mathlib 已收录布朗运动（`Probability/BrownianMotion/
Basic.lean`），本章锚定核心 API——定义结构（有限维分布 + 连续轨道）、
协方差 = min(s,t)、独立增量、弱马氏性（平移增量独立于过去）与三大
对称性（镜像 / 乘量 / 时间反演）。反射原理与连续 LIL 未收录：前者由
离散版（Python/Prolog 的精确双射）承载，后者第 56 章已由包络账承载。
-/

open MeasureTheory ProbabilityTheory
open scoped NNReal

#check @ProbabilityTheory.IsBrownianReal
-- 正文 60.2 定义 8.2.1 的机器化身：有限维分布正确 + 轨道 a.s. 连续

#check @ProbabilityTheory.IsPreBrownianReal.covariance_eval
-- 正文 60.2：E[B(s)·B(t)] = min(s, t)（协方差核决定一切）

#check @ProbabilityTheory.IsPreBrownianReal.hasIndepIncrements
-- 正文 60.2 条件 2：独立增量（有限维分布的推论）

#check @ProbabilityTheory.HasIndepIncrements.isPreBrownianReal_of_hasLaw
-- 反向入口：增量独立 + N(0,t) 增量分布 ⟹ pre-Brownian

#check @ProbabilityTheory.IsGaussianProcess.isPreBrownianReal_of_covariance
-- 另一入口：零均值高斯过程 + 协方差 min(s,t) ⟹ pre-Brownian
-- （正文 60.3.2 Fourier 构造走的就是这条路：Parseval 折叠协方差）

#check @ProbabilityTheory.IsPreBrownianReal.indepFun_shift
-- 正文 60.5 弱马氏性：B(t₀+·)−B(t₀) 是 pre-Brownian 且独立于过去

#check @ProbabilityTheory.IsBrownianReal.neg
-- 正文 60.2 对称性一：−B 仍是布朗运动（镜像）

#check @ProbabilityTheory.IsBrownianReal.smul
-- 对称性二（乘量）：c·B(·/c²) 仍是布朗运动 ⟹ B_t ~ t^{1/2}B_1

#check @ProbabilityTheory.IsPreBrownianReal.inv
-- 对称性三（时间反演）：t ↦ t·B(1/t) 仍是 pre-Brownian

#check @ProbabilityTheory.IsBrownianReal.tendsto_nhds_zero
-- 轨道正则性：连续路径在 t→0 处趋于 0（连续修正的入口）

/-! ## 增量分布的精确侧影

高斯增量 N(0, t) 的方差账由 `integral_eval` / `covariance_eval`
承担；此处登记其在 s = t 处的读数：E[B(t)²] = t。 -/

#check @ProbabilityTheory.IsPreBrownianReal.integral_eval
-- E[B(t)] = 0（零均值；方差账 = covariance_eval 在 s = t 处）

/-- 增量方差账：协方差核在对角线的读数。cov[B(t),B(t)] = min t t = t；
均值恒零（integral_eval），故二阶矩即方差 = t——N(0, t) 增量的核验。 -/
example {Ω : Type*} [MeasurableSpace Ω] {P : Measure Ω} {B : ℝ≥0 → Ω → ℝ}
    (hB : IsPreBrownianReal B P) (t : ℝ≥0) :
    cov[B t, B t; P] = t := by
  simpa using hB.covariance_eval t t
