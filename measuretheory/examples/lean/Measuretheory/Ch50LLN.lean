import Mathlib.Probability.StrongLaw

/-!
# 第 50 章 大数定律（Lean）

袁下册第 19 章。mathlib 锚点（`Probability/StrongLaw.lean`）：
**`ProbabilityTheory.strong_law_ae`**（iid + 一阶矩 ⟹
a.s. 收敛——Khinchin/SLLN 的完全体机器版）与
`strong_law_Lp`（Lᵖ 版）；**截断术（truncation）零件族**
（`abs_truncation_le_bound` 等——Khinchin 截尾的机器件，
48 章工具的发动机）。本章（弱大数律）是强大数定律的
前奏：弱版（依概率）由截尾 + Markov/Chebyshev（48 章）
在 docs 承载；**机器侧以强版的锚点正名 + 截断零件
实弹**为主（分工如实：依概率版无独立主定理——
被强版蕴含）。

实弹：截断的三件恒等/界（截断术的机器内核）。
-/

open MeasureTheory ProbabilityTheory

/-! ## 锚点正名 -/

#check @ProbabilityTheory.strong_law_ae
#check @ProbabilityTheory.strong_law_Lp
#check @ProbabilityTheory.abs_truncation_le_bound
#check @ProbabilityTheory.truncation_zero
#check @ProbabilityTheory.abs_truncation_le_abs_self
#check @ProbabilityTheory.truncation_eq_self

/-! ## 截断术的机器内核 -/

/-- 截断幅度有界：|truncation f A x| ≤ |A|（截尾术的定义性
账——48.2 截尾-中心化的机器内核）。 -/
example (f : ℕ → ℝ) (A : ℝ) (n : ℕ) :
    |ProbabilityTheory.truncation f A n| ≤ |A| :=
  ProbabilityTheory.abs_truncation_le_bound f A n

/-- 截断的零界：A = 0 时截断恒 0（残尾极限的退化锚点）。 -/
example (f : ℕ → ℝ) :
    ProbabilityTheory.truncation f 0 = fun _ => 0 :=
  ProbabilityTheory.truncation_zero f
