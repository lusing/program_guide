import Mathlib.Data.Nat.Choose.Sum
import Mathlib.Tactic

/-!
# 第 05 章 计数基础（Lean）

Miller ch3.1 的机器侧：mathlib 的 `Nat.choose` = C(n,k)。
本章登记 Pascal 递推与求和恒等式的机器版，并用 `decide`
裁决两个标志性数值：C(52,5) = 2,598,960（第 04 章扑克的
分母）与 C(23,2) = 253（第 01 章生日问题的配对数）。
-/

/-! ## 锚点正名 -/

#check @Nat.choose_succ_succ       -- Pascal：C(n+1,k+1) = C(n,k) + C(n,k+1)
#check @Nat.sum_range_choose       -- Σ_{k≤n} C(n,k) = 2ⁿ（二项定理 x=y=1）
#check @Nat.choose_eq_zero_of_lt   -- k > n ⟹ C(n,k) = 0
-- 对称律 C(n,k) = C(n,n-k) 的引用见 Nat.choose_symm

/-! ## 实弹：两个标志性数值的机器判决 -/

/-- 第 04 章的分母：五张牌的手数 = 2,598,960。 -/
example : Nat.choose 52 5 = 2598960 := by decide

/-- 第 01 章的配对账：23 人的配对数 = 253（"为什么 23 就够"
的计数根源）。 -/
example : Nat.choose 23 2 = 253 := by decide

/-- Pascal 递推的数值实弹：C(10,4) = C(9,3) + C(9,4)
（210 = 84 + 126——三角形的机器原文）。 -/
example : Nat.choose 10 4 = Nat.choose 9 3 + Nat.choose 9 4 := by
  rw [← Nat.choose_succ_succ]

/-- 求和恒等式的数值实弹：Σ C(8,k) = 2⁸ = 256。 -/
example : ∑ k ∈ Finset.range 9, Nat.choose 8 k = 256 := by
  exact Nat.sum_range_choose 8

/-- 顺序账的实弹：3 岗位（有序）是 3 委员（无序）的
3! = 6 倍——"先算多再除重"的机器形态。 -/
example : (10 * 9 * 8) = 6 * Nat.choose 10 3 := by decide
