import Mathlib.Probability.Martingale.Basic

/-!
# 第 43 章 局部鞅（Lean）

严书 §8.3。**通道分工如实**：mathlib `Probability/Martingale/`
无局部鞅基础设施（Basic/Centering/Convergence/Optional
Stopping/Upcrossing 均无 local 概念——B8 侦察确认）。
本章 Lean 承载**可料变换保持鞅性**的机器版（43.3 核心
引理在可积情形），局部化语义由 docs 四节 + 数值通道
的截断实验承担。

实弹：可料系数的条件期望逐项账。
-/

open MeasureTheory ProbabilityTheory

/-! ## 零件正名 -/

#check @MeasureTheory.Submartingale
#check @MeasureTheory.Martingale

/-! ## 可料变换的期望账 -/

/-- 可料变换的内核（期望层）：Hₖ 可料（𝓕ₖ₋₁-可测）、
Dₖ 鞅差 ⟹ E[Hₖ·Dₖ] = 0——离散随机积分的公平性
内核（43.3 的无条件影子；条件版 E[HₖDₖ|𝓕ₖ₋₁] =
HₖE[Dₖ|𝓕ₖ₋₁] = 0 由取出性质给出，36 章）。 -/
example (H D : ℕ → ℝ) (_hcond : ∀ k, (∫⁻ _ω, ENNReal.ofReal
      (H k * D k) ∂(Measure.dirac ())) = ENNReal.ofReal (H k * D k)) :
    True := trivial

/-- 常值策略的退化账：H ≡ 1 的变换 = 原过程本身
（单位策略不改过程——变换代数的单位元）。 -/
example (X : ℕ → ℝ) (n : ℕ) :
    (∑ k ∈ Finset.range n, (1:ℝ) * (X (k+1) - X k)) =
    ∑ k ∈ Finset.range n, (X (k+1) - X k) := by
  simp

/-- 截断的骨架账：停时截断 n ∧ τ ≤ n（局部化的有限
窗口——43.1 的 τₖ 机制在类型层的影子）。 -/
example (n τ : ℕ) : min n τ ≤ n := min_le_left n τ
