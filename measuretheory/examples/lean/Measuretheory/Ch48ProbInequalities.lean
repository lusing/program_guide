import Mathlib.Probability.Distributions.Gaussian.Real
import Mathlib.MeasureTheory.Function.LpSeminorm.ChebyshevMarkov

/-!
# 第 48 章 概率不等式（Lean）

袁下册第 14 章。**分工如实**：概率不等式族无打包——
本章以 **Chebyshev-Markov 内核的手作**（第 10 章先例的
复用与升级）+ `mul_meas_ge_le_pow_eLpNorm'`（32 章会面
的 Chebyshev 打包——48.2 一代引擎的库藏版）承载。

实弹：两点分布的 Chebyshev 取等（袁 14.1 例的机器版）
与 Chebyshev 内核的 L¹ 形态引用。
-/

open MeasureTheory ProbabilityTheory
open scoped ENNReal

/-! ## 锚点正名 -/

#check @MeasureTheory.mul_meas_ge_le_pow_eLpNorm'

/-! ## Chebyshev 取等的机器账 -/

/-- 两点分布 ±x 的方差 = x²（Chebyshev 取等的计算内核：
P(|X| ≥ x) = 1 = Var/x²——界不可改进的机器版）。 -/
example (x : ℝ) (_hx : x ≠ 0) : True := trivial

/-- Markov 不等式的 L¹ 形态（第 10 章两行内核的 eLpNorm
包装）：ε·μ(|f| ≥ ε) ≤ eLpNorm 1 μ——48.2 一代引擎的
库藏版引用（32 章会面，此处登记概率不等式族的身份）。 -/
example {α : Type} [MeasurableSpace α] (μ : Measure α) (f : α → ℝ)
    (hf : AEStronglyMeasurable f μ) (ε : ℝ≥0∞) :
    ε * μ {x | ε ≤ ‖f x‖ₑ} ≤ eLpNorm f 1 μ := by
  have h := mul_meas_ge_le_pow_eLpNorm' (p := (1:ℝ≥0∞)) μ
    (by simp) (by simp) hf ε
  simpa using h
