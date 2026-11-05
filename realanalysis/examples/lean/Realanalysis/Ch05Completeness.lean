import Mathlib.Basic.Real.Basic
import Mathlib.Algebra.Order.Archimedean.Basic
import Mathlib.Tactic

/-!
# 第 05 章 实数域（下）：完备性的三大推论

对应原书第 5 章后半：Archimedean 性质（定理 5.5）、有理数稠密性
（定理 5.6）、根的存在性（定理 5.8），以及把第 03 章的“洞”正式填上：
集合 {0 ≤ x, x² < 2} 在 ℝ 中的上确界恰好是 √2。
-/

namespace Realanalysis.Ch05

/-- 定理 5.5（Archimedean 性质）：任意正实数的自然数倍可以超过任何实数。
    证明只需对 y/x 应用 exists_nat_gt 再乘回 x。 -/
theorem archimedean_mul (x y : ℝ) (hx : 0 < x) : ∃ n : ℕ, y < (n : ℝ) * x := by
  obtain ⟨n, hn⟩ := exists_nat_gt (y / x)
  use n
  rwa [div_lt_iff₀ hx] at hn

/-- 定理 5.6（有理数在实数中稠密）：任何两个实数之间都有有理数。
    mathlib 的证明正是原书的思路：Archimedean 性质 + 取整。 -/
example (a b : ℝ) (h : a < b) : ∃ q : ℚ, a < q ∧ (q : ℝ) < b :=
  exists_rat_btwn h

/-- 定理 5.8（根的存在性，平方根版）：存在正实数 y 使 y² = 2。
    在 mathlib 里 √2 由完备性构造，sq_sqrt 给出平方回原数。 -/
example : ∃ y : ℝ, 0 < y ∧ y ^ 2 = 2 :=
  ⟨Real.sqrt 2, Real.sqrt_pos.mpr (by norm_num), Real.sq_sqrt (by norm_num)⟩

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
