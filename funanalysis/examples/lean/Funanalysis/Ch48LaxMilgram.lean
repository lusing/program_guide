import Mathlib.Analysis.InnerProductSpace.Basic
import Mathlib.Analysis.InnerProductSpace.PiL2
import Mathlib.Analysis.InnerProductSpace.LaxMilgram

/-!
# 第 48 章 · Lax-Milgram 引理与变分法（Lax 6.3, 7.2）

本树（2026 版）mathlib **已含 Lax-Milgram**：
`Mathlib.Analysis.InnerProductSpace.LaxMilgram` 提供
`IsCoercive`（强制性）与 `continuousLinearEquivOfBilin`——
强制双线性形式的表示算子 B♯ 是连续线性等价（定理全文）。

本章机器化三层：
1. 引擎不等式 (21)（手写版，与 IsCoercive.bounded_below 呼应）；
2. 强制算子单射；有限维收尾；
3. mathlib 官方定理的实例化锚点。
-/

open scoped RealInnerProductSpace InnerProductSpace

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

/-- 推论二（有限维收尾）：ℝⁿ 上强制 ⟹ 满射。 -/
example (A : EuclideanSpace ℝ (Fin 2) →L[ℝ] EuclideanSpace ℝ (Fin 2))
    {b : ℝ} (hb : 0 < b) (hcoe : ∀ x, b * ‖x‖ * ‖x‖ ≤ ⟪A x, x⟫_ℝ) :
    Function.Surjective A := by
  have h : Function.Injective A.toLinearMap := fun x y h =>
    coercive_injective A hb hcoe h
  exact LinearMap.injective_iff_surjective.mp h

-- mathlib 官方 Lax-Milgram 锚点：强制 ⟹ 表示算子是连续等价（定理全文）
#check @IsCoercive.continuousLinearEquivOfBilin
#check @IsCoercive.bounded_below

-- 官方定理的表示性质实例化：⟪equiv v, w⟫ = B v w
example {V : Type*} [NormedAddCommGroup V] [InnerProductSpace ℝ V] [CompleteSpace V]
    (B : V →L[ℝ] V →L[ℝ] ℝ) (hB : IsCoercive B) (v w : V) :
    ⟪hB.continuousLinearEquivOfBilin v, w⟫_ℝ = B v w :=
  hB.continuousLinearEquivOfBilin_apply v w
