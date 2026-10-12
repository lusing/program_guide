import Mathlib.Analysis.InnerProductSpace.Basic
import Mathlib.Analysis.InnerProductSpace.PiL2

open scoped RealInnerProductSpace InnerProductSpace

/-!
# 第 48 章 · Lax-Milgram 引理与变分法（Lax 6.3, 7.2）

mathlib v4.33.1 没有 Lax-Milgram 引理（也没有 Banach 极限、迹类、
半群——第二卷的通道分工见 docs/48）。本章机器化它的**引擎不等式**
（Lax 证明第二步的 (21)）：

    强制性  b‖x‖² ≤ ⟪A x, x⟫  蕴涵  b‖x‖ ≤ ‖A x‖

以及两个直接推论：强制算子单射；有限维时单射即满射——这正是
"Lax-Milgram 在 ℝⁿ 上成立"的完整陈述：强制形式的表示方程
B(x, y) = l(x) 对任何右端可解。
-/

variable {H : Type*} [NormedAddCommGroup H] [InnerProductSpace ℝ H]

/-- Lax-Milgram 证明的核心不等式（Lax 第 6 章 (21)）：
强制性给出下有界。 -/
theorem coercive_bound (A : H →L[ℝ] H) {b : ℝ} (_hb : 0 < b)
    (hcoe : ∀ x, b * ‖x‖ * ‖x‖ ≤ ⟪A x, x⟫_ℝ) : ∀ x, b * ‖x‖ ≤ ‖A x‖ := by
  intro x
  rcases eq_or_ne x 0 with rfl | hx
  · simp
  · have h2 : |⟪A x, x⟫_ℝ| ≤ ‖A x‖ * ‖x‖ := by
      simpa using norm_inner_le_norm (𝕜 := ℝ) (A x) x
    have h1 : b * ‖x‖ * ‖x‖ ≤ ‖A x‖ * ‖x‖ :=
      le_trans (hcoe x) (le_trans (le_abs_self _) h2)
    exact (mul_le_mul_iff_of_pos_right (norm_pos_iff.mpr hx)).mp h1

/-- 推论一：强制算子单射（ker A = ⊥）。 -/
theorem coercive_injective (A : H →L[ℝ] H) {b : ℝ} (hb : 0 < b)
    (hcoe : ∀ x, b * ‖x‖ * ‖x‖ ≤ ⟪A x, x⟫_ℝ) : Function.Injective A := by
  intro x y hxy
  have hb2 := coercive_bound A hb hcoe (x - y)
  rw [A.map_sub, hxy, sub_self] at hb2
  simp at hb2
  by_contra hne
  have hpos : 0 < ‖x - y‖ := by
    rcases eq_or_lt_of_le (norm_nonneg (x - y)) with h0 | hlt
    · exact absurd (sub_eq_zero.mp (norm_eq_zero.mp h0.symm)) hne
    · exact hlt
  have := mul_pos hb hpos
  linarith

/-- 推论二（有限维收尾）：ℝⁿ 上强制 ⟹ 满射，故表示方程
B(x, y) = l(x) 对一切右端 l 可解——Lax-Milgram 的有限维化身。 -/
example (A : EuclideanSpace ℝ (Fin 2) →L[ℝ] EuclideanSpace ℝ (Fin 2))
    {b : ℝ} (hb : 0 < b) (hcoe : ∀ x, b * ‖x‖ * ‖x‖ ≤ ⟪A x, x⟫_ℝ) :
    Function.Surjective A := by
  have h : Function.Injective A.toLinearMap := fun x y h =>
    coercive_injective A hb hcoe h
  exact LinearMap.injective_iff_surjective.mp h

#check @LinearMap.injective_iff_surjective
#check @norm_inner_le_norm
