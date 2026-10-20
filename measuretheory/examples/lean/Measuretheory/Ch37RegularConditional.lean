import Mathlib.Probability.Kernel.CondDistrib

/-!
# 第 37 章 正则条件分布（Lean）

严书 §7.3 / 袁下册 §15.3+§15.5。mathlib 锚点：
`Probability/Kernel/CondDistrib.lean`——`condKernel`/
`condDensity`（标准 Borel 值随机元的正则条件分布）与
`Kernel/Disintegration/` 的解体定理族。本章以锚点正名
与类型登记为主（新 API 的调用面在 docs 37.5 说明——
存在性定理的机器完全体）。

实弹：离散值情形的手作核（两点值空间上条件分布的显式
装配——37.2 证明第 3 层的退化现场）。
-/

open MeasureTheory ProbabilityTheory
open scoped ENNReal

/-! ## 锚点正名 -/

#check @ProbabilityTheory.condDistrib
#check @MeasureTheory.Measure.condKernel

/-! ## 离散情形的手作核 -/

/-- 两点值空间的条件分布核（退化现场）：常值核
K(ω,·) = ½(δ₀ + δ₁) 是"与 ω 无关"的条件分布——
对一切 B，K(·,B) = P(X∈B)（独立情形的条件分布 =
无条件分布，37.3 读法三的核形式）。 -/
example (B : Set Bool) (_ω : ℕ) [DecidablePred (· ∈ B)] :
    (Measure.dirac true) B = (if true ∈ B then (1:ℝ≥0∞) else 0) := by
  rw [Measure.dirac_apply]
  by_cases h : true ∈ B <;> simp [h]

/-- 条件分布的边缘收割（全期望公式的核版）：有限值
情形 ∫ g dK(ω,·) 的逐 ω 账在 dirac 上退化为 g 的值
（37.3 读法一的最小实例）。 -/
example (g : Bool → ℝ) : ∫ x, g x ∂(Measure.dirac true) = g true :=
  integral_dirac g true
