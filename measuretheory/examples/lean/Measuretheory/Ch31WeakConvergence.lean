import Mathlib.MeasureTheory.Function.ConvergenceInDistribution
import Mathlib.MeasureTheory.Measure.Portmanteau
import Mathlib.Analysis.SpecificLimits.Basic

/-!
# 第 31 章 弱收敛与 Portmanteau（Lean）

严书 §6.2 / 袁上册 §12.2。mathlib 锚点：
- `MeasureTheory.TendstoInDistribution`（随机元版的依分布
  收敛，Function/ConvergenceInDistribution.lean）；
- **连续映射定理** `TendstoInDistribution.continuous_comp`、
  **Slutsky 定理** `TendstoInDistribution.prodMk_of_tendstoIn
  Measure_const`——本版 mathlib 已收录两大纲领定理；
- Portmanteau 单边条款族（Measure/Portmanteau.lean）：
  `limsup_measure_closed_le_iff_liminf_measure_open_ge`
  （闭开等价）、`tendsto_measure_of_null_frontier`（连续集
  条款）。

实弹：dirac 收缩族的积分收敛（∫f dδ_{1/n} → f(0) 的核
对账）。
-/

open MeasureTheory
open scoped Topology

/-! ## 锚点正名 -/

#check @MeasureTheory.TendstoInDistribution
#check @MeasureTheory.TendstoInDistribution.continuous_comp
#check @MeasureTheory.TendstoInDistribution.prodMk_of_tendstoInMeasure_const
#check @MeasureTheory.limsup_measure_closed_le_iff_liminf_measure_open_ge
#check @MeasureTheory.tendsto_measure_of_null_frontier

/-! ## dirac 收缩族的积分对账 -/

/-- 弱收敛的最简实弹：μₙ = δ_{1/n} ⇒ δ₀ 的积分账——
一切有界连续 f 的 ∫f dμₙ = f(1/n) → f(0)（连续性直收）。
数值通道（30/31 章）以 cdf 跳点对照读同一现象。 -/
example (f : ℝ → ℝ) (hf : Continuous f) :
    Filter.Tendsto (fun r => ∫ x, f x ∂(Measure.dirac (r:ℝ)))
      (𝓝[>](0:ℝ)) (𝓝 (f 0)) := by
  have h1 : ∀ r : ℝ, ∫ x, f x ∂(Measure.dirac r) = f r := fun r => integral_dirac _ _
  simp only [h1]
  exact hf.continuousAt.tendsto.mono_left nhdsWithin_le_nhds
