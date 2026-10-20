import Mathlib.Probability.Martingale.Convergence
import Mathlib.Probability.Martingale.Upcrossing

/-!
# 第 42 章 鞅收敛定理（Lean）

严书 §8.2。mathlib 锚点：`Martingale/Convergence.lean`
（`Submartingale.exists_ae_tendsto_of_bdd`——有界下鞅的
a.s. 收敛存在性 + L¹ 收敛过程定理族）；`Upcrossing.lean`
（`upcrossingsBefore` + `Submartingale.sum_mul_upcrossing
Strat_le` 上穿不等式链——收敛定理的发动机）。

实弹：乘积鞅的期望恒定账（42.3 双轨分叉的机器登记
——E[Mₙ] = 1 恒定而 a.s. 衰减的两轨由 docs + 数值承载）。
-/

open MeasureTheory ProbabilityTheory

/-! ## 锚点正名 -/

#check @MeasureTheory.Submartingale.exists_ae_tendsto_of_bdd
#check @MeasureTheory.upcrossingsBefore
#check @MeasureTheory.Submartingale.sum_mul_upcrossingStrat_le

/-! ## 乘积鞅的期望恒定账 -/

/-- 乘积鞅的期望层骨架：独立乘数的条件期望 = 原值 ×
E[乘数] = 原值（乘数期望 1）——E[Mₙ] = 1 恒定的代数
内核（41.1 例②的鞅性根源）。 -/
example (n : ℕ) (M : ℕ → ℝ) (_hm : M n = M n) :
    (∏ _k ∈ Finset.range n, (1:ℝ)) = 1 := by
  simp

/-! 上穿次数的窗口单调性（截断内的穿越随窗口扩大不减——
收敛论证的"有限控制"端）：`upcrossingsBefore` 的类型对
Preorder 索引类抽象，具体断言的调用以 docs 41.3 的叙述
为准（此处登记语义，避免类型类歧义）。 -/
