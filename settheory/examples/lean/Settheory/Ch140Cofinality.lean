import Mathlib.Tactic
import Mathlib.SetTheory.Cardinal.Cofinality.Ordinal
import Mathlib.SetTheory.Cardinal.Regular

/-!
# 第 140 章 共尾与无穷和积（Lean）

共尾 cf、正则/奇异、后继基数正则（书 5.3.6）与 König 引理
（书 5.3.7）的 mathlib 形态。
-/

/-! ## 共尾的基本账（书 5.3.1-5.3.2） -/

#check @Ordinal.cof

/-- 后继序数的共尾是 1（书 5.3.2(3)）。 -/
example (o : Ordinal) : Ordinal.cof (o + 1) = 1 :=
  Ordinal.cof_add_one o

/-- 右加不改变共尾（书 5.3.2 的推论形态）。 -/
example (a : Ordinal) (b : Ordinal) (hb : b ≠ 0) :
    Ordinal.cof (a + b) = Ordinal.cof b :=
  Ordinal.cof_add a hb

/-! ## 正则与奇异（书 5.3.3-5.3.6） -/

#check @Cardinal.IsRegular
#check @Cardinal.IsSingular

/- 后继基数正则（书 5.3.6）：ℵ₁ 正则——一般 κ⁺ 正则在
4.33 的 Regular.lean 中以 IsRegular (succ κ) 形态出现。 -/
#check @Cardinal.isRegular_aleph_one
#check @Cardinal.isRegular_succ

/- cf(cf(α)) = cf(α)（推论 5.3.4）：共尾总是正则的。 -/
#check @Ordinal.cof_ord_cof

/-! ## König 引理（书 5.3.7）：κ < κ^{cf κ} -/

/- 推论 5.3.8 的形态：cf(2^a) > a——连续统函数的唯一硬约束。 -/
#check @Cardinal.lt_cof_ord_power

example (a b : Cardinal) (ha : Cardinal.aleph0 ≤ a) (hb : 1 < b) :
    a < (b ^ a).ord.cof :=
  Cardinal.lt_cof_ord_power ha hb

/-- ℵ₀ 是正则的（书 5.3.6 前注：ω 正则）。 -/
example : Cardinal.aleph0.IsRegular := Cardinal.isRegular_aleph0
