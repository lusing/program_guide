/-
文件: 14_mathlib_combinatorics/combinatorics.lean
描述: 第17章 组合数学（与教程同步，Mathlib4 master@2026-09 验证；注意 2026 起 ∑ 绑定符用 ∈）
编译: lake build Lean4Tutorial.Examples.MathlibCombinatorics.Combinatorics
-/

import Mathlib.Data.Finset.Basic
import Mathlib.Algebra.BigOperators.Group.Finset.Defs
import Mathlib.Algebra.BigOperators.Intervals
import Mathlib.Data.Nat.Choose.Basic
import Mathlib.Data.Nat.Choose.Sum
import Mathlib.Data.Fintype.Pigeonhole
import Mathlib.Data.Fintype.Card
import Mathlib.Basic.Real.Basic

open Finset

namespace Lean4Tutorial.Examples.MathlibCombinatorics.Ch17

/-! # 17.1 Finset -/

#eval ({1, 2, 3} : Finset ℕ).card
#eval 3 ∈ ({1, 2, 3} : Finset ℕ)
#eval (({1, 2, 3} : Finset ℕ) ∪ {3, 4}).card
#eval (({1, 2, 3} : Finset ℕ) ∩ {2, 3}).card
#eval (Finset.range 5).card

example (s t : Finset ℕ) (h : s ⊆ t) : s.card ≤ t.card := Finset.card_le_card h
example (s : Finset ℕ) : s.card = 0 ↔ s = ∅ := Finset.card_eq_zero

/-! # 17.2 大算子（∈ 绑定符） -/

#eval ∑ i ∈ range 10, i
#eval ∑ i ∈ range 5, (i : ℚ)^2    -- ℝ 不可计算（柯西商），用 ℚ 做数值演示
#eval ∏ i ∈ range 5, (i + 1 : ℕ)

example : ∑ p ∈ (range 3) ×ˢ (range 3), p.1 * p.2 = 9 := by decide

example (n : ℕ) : ∑ i ∈ range n, i = n * (n - 1) / 2 := Finset.sum_range_id n

example (s : Finset ι) (f g : ι → ℝ) :
    ∑ i ∈ s, (f i + g i) = ∑ i ∈ s, f i + ∑ i ∈ s, g i := Finset.sum_add_distrib

-- Finset.mul_sum 的方向是"提出因子"：a * ∑ f = ∑ a * f（取 .symm 得我们的写法）
example (s : Finset ι) (c : ℝ) (f : ι → ℝ) :
    ∑ i ∈ s, c * f i = c * ∑ i ∈ s, f i := (Finset.mul_sum s f c).symm

/-! # 17.3 二项式系数 -/

#eval Nat.choose 5 2
example (n : ℕ) : Nat.choose n 0 = 1 := Nat.choose_zero_right n
example (n : ℕ) : Nat.choose n n = 1 := Nat.choose_self n
example (n k : ℕ) : Nat.choose (n + 1) (k + 1) = Nat.choose n k + Nat.choose n (k + 1) :=
  Nat.choose_succ_succ n k

example (a b : ℝ) (n : ℕ) :
    (a + b) ^ n = ∑ k ∈ range (n + 1), a ^ k * b ^ (n - k) * n.choose k :=
  add_pow a b n

example (n : ℕ) : ∑ k ∈ range (n + 1), n.choose k = 2 ^ n := Nat.sum_range_choose n

/-! # 17.4 鸽笼原理 -/

example [Fintype α] [Fintype β] (f : α → β)
    (h : Fintype.card β < Fintype.card α) :
    ∃ x y : α, x ≠ y ∧ f x = f y :=
  Fintype.exists_ne_map_eq_of_card_lt f h

example {s : Finset α} {t : Finset β} {f : α → β}
    (hc : t.card < s.card) (hf : ∀ a ∈ s, f a ∈ t) :
    ∃ x ∈ s, ∃ y ∈ s, x ≠ y ∧ f x = f y :=
  Finset.exists_ne_map_eq_of_card_lt_of_maps_to hc hf

-- 实战：n+1 个 Fin n 值必有两个相同
example (n : ℕ) (a : Fin (n + 1) → Fin n) :
    ∃ i j : Fin (n + 1), i ≠ j ∧ a i = a j :=
  Fintype.exists_ne_map_eq_of_card_lt a (by simp)

end Lean4Tutorial.Examples.MathlibCombinatorics.Ch17
