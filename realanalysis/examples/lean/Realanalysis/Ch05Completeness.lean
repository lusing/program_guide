import Mathlib.Basic.Real.Basic
import Mathlib.Algebra.Order.Archimedean.Basic
import Mathlib.NumberTheory.Real.Irrational
import Mathlib.Tactic

/-!
# 第 05 章 实数域（下）：完备性的三大推论

对应原书第 5 章后半：Archimedean 性质（定理 5.5，从最小上界性反证）、
有理数稠密（定理 5.6）、无理数稠密（推论 5.7）、根的存在性（定理 5.8
的平方根版），以及把第 03 章的“洞”正式填上：
集合 {0 ≤ x, x² < 2} 在 ℝ 中的上确界恰好是 √2。
-/

namespace Realanalysis.Ch05

open Set

/-- 定理 5.5 的原书证明：用最小上界性做反证。
    若所有 n·x ≤ y，则 A = {n·x | n ∈ ℕ} 有上界 y，取 α = sSup A；
    α − x < α 不是上界，故有 m 使 α − x < m·x，即 α < (m+1)·x，
    与 α 是上界矛盾。 -/
theorem archimedean_from_lub (x y : ℝ) (hx : 0 < x) :
    ∃ n : ℕ, y < (n : ℝ) * x := by
  by_contra! h
  let A : Set ℝ := range fun n : ℕ => (n : ℝ) * x
  have hne : A.Nonempty := ⟨0, ⟨0, by simp⟩⟩
  have hbdd : BddAbove A := ⟨y, by
    rintro _ ⟨n, rfl⟩
    exact h n⟩
  set α := sSup A
  have hα : IsLUB A α := Real.isLUB_sSup hne hbdd
  have hlt : α - x < α := sub_lt_self α hx
  have : ¬ α - x ∈ upperBounds A := fun hub =>
    (not_lt_of_ge (hα.2 hub)) hlt
  obtain ⟨z, hzA, hzt⟩ : ∃ z ∈ A, α - x < z := by
    contrapose! this
    exact this
  obtain ⟨m, rfl⟩ := hzA
  have : α < ((m + 1 : ℕ) : ℝ) * x := by
    calc
      α < (m : ℝ) * x + x := by linarith
      _ = ((m + 1 : ℕ) : ℝ) * x := by push_cast; ring
  have hmem : ((m + 1 : ℕ) : ℝ) * x ∈ A := mem_range_self (m + 1)
  exact (not_lt_of_ge (hα.1 hmem)) this

/-- 库定理形式：对 y/x 应用 exists_nat_gt 再乘回 x。
    与原书证明等价；ℚ 上也可以直接用分子分母写出倍数。 -/
theorem archimedean_mul (x y : ℝ) (hx : 0 < x) : ∃ n : ℕ, y < (n : ℝ) * x := by
  obtain ⟨n, hn⟩ := exists_nat_gt (y / x)
  use n
  rwa [div_lt_iff₀ hx] at hn

/-- 常用推论：任意实数都被某个自然数超过。 -/
example (y : ℝ) : ∃ n : ℕ, y < (n : ℝ) := exists_nat_gt y

/-- 定理 5.6（有理数在实数中稠密）：任何两个实数之间都有有理数。
    mathlib 的证明正是原书的思路：Archimedean 性质 + 取整。 -/
example (a b : ℝ) (h : a < b) : ∃ q : ℚ, a < q ∧ (q : ℝ) < b :=
  exists_rat_btwn h

/-- 推论 5.7（无理数稠密）。
    库定理构造：在 a−√2 与 b−√2 之间取有理数 q，则 q+√2 夹在 a、b 之间且无理。
    原书等价构造是先在 a/√2 与 b/√2 之间取 q，再乘回 √2。 -/
example (a b : ℝ) (h : a < b) : ∃ p : ℝ, Irrational p ∧ a < p ∧ p < b :=
  exists_irrational_btwn h

/-- 定理 5.8（根的存在性，平方根版）：存在正实数 y 使 y² = 2。
    在 mathlib 里 √2 由完备性构造，sq_sqrt 给出平方回原数。 -/
example : ∃ y : ℝ, 0 < y ∧ y ^ 2 = 2 :=
  ⟨Real.sqrt 2, Real.sqrt_pos.mpr (by norm_num), Real.sq_sqrt (by norm_num)⟩

/-- 正平方根唯一：两个正根不能一个严格小于另一个。 -/
theorem pos_sqrt_unique (y₁ y₂ : ℝ) (hy₁ : 0 < y₁) (hy₂ : 0 < y₂)
    (h₁ : y₁ ^ 2 = 2) (h₂ : y₂ ^ 2 = 2) : y₁ = y₂ := by
  apply le_antisymm
  · by_contra! hlt
    -- hlt : y₂ < y₁
    have : y₂ ^ 2 < y₁ ^ 2 :=
      pow_lt_pow_left₀ hlt hy₂.le (by norm_num : (2 : ℕ) ≠ 0)
    linarith
  · by_contra! hlt
    -- hlt : y₁ < y₂
    have : y₁ ^ 2 < y₂ ^ 2 :=
      pow_lt_pow_left₀ hlt hy₁.le (by norm_num : (2 : ℕ) ≠ 0)
    linarith

/-- 本章核心定理：{0 ≤ x, x² < 2} 在 ℝ 中的上确界恰好是 √2。
    与第 03 章的 q_trick 合起来，就是“ℚ 的洞被 ℝ 填上”的完整故事：
    同一个集合在 ℚ 里没有上确界（任何有理上界都可再缩小），
    在 ℝ 里有 √2。 -/
theorem sqrt2_is_lub : IsLUB {x : ℝ | 0 ≤ x ∧ x ^ 2 < 2} (Real.sqrt 2) := by
  have h2 : (Real.sqrt 2) ^ 2 = 2 := Real.sq_sqrt (by norm_num)
  refine ⟨?_, ?_⟩
  · -- √2 是上界：x ≥ 0 时 x ≤ √2 ⟺ x² ≤ 2（Real.le_sqrt）
    rintro x ⟨h0, hx2⟩
    rw [Real.le_sqrt h0 (by norm_num : (0 : ℝ) ≤ 2)]
    linarith
  · -- 最小性：反证。设上界 b < √2，分两种情形找集合中超过 b 的元素：
    --   b < 0：取元素 0；0 ≤ b：取中点 m = (b+√2)/2。
    intro b hb
    by_contra hlt
    push Not at hlt
    have h0mem : (0 : ℝ) ∈ {x : ℝ | 0 ≤ x ∧ x ^ 2 < 2} := ⟨le_refl 0, by norm_num⟩
    by_cases hb0 : b < 0
    · have := hb h0mem
      linarith
    · push Not at hb0
      set m := (b + Real.sqrt 2) / 2 with hm
      have hbm : b < m := by linarith
      have hmm : m < Real.sqrt 2 := by linarith
      have hm0 : 0 ≤ m := by linarith [Real.sqrt_nonneg 2]
      have hm2 : m ^ 2 < 2 := by
        have h := pow_lt_pow_left₀ hmm hm0 (by norm_num : (2 : ℕ) ≠ 0)
        linarith
      have := hb ⟨hm0, hm2⟩
      linarith

end Realanalysis.Ch05
