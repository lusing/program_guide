import Mathlib.Analysis.SpecialFunctions.Trigonometric.InverseDeriv
import Mathlib.Analysis.SpecialFunctions.Trigonometric.Deriv

/-!
# 第 03 章 可分离方程（Lean）

书 §2.3 的解核对：
- y = 5/x 满足 y' = −y/x（x ≠ 0）——例 3（双曲族）；
- y = x·arcsin x 满足 y' = y/x + tan(y/x)——例 6（齐次方程
  sin(y/x) = Cx 取 C = 1 的特解），涉及乘积法则、arcsin 求导与
  tan(arcsin x) = x/√(1−x²) 的直角三角形代换。
-/

open Real

/-- 例 3：y = 5/x 在 x ≠ 0 处满足 y' = −y/x。 -/
example (x : ℝ) (hx : x ≠ 0) :
    HasDerivAt (fun x => 5 / x) (-(5 / x) / x) x := by
  have h : HasDerivAt (fun x => 5 / x) (-(5 / x ^ 2)) x := by
    have hnum : HasDerivAt (fun _ : ℝ => (5 : ℝ)) 0 x :=
      hasDerivAt_const (c := (5 : ℝ)) (x := x)
    have hden : HasDerivAt (fun y : ℝ => y) 1 x := hasDerivAt_id x
    have hd := HasDerivAt.div hnum hden hx
    refine hd.congr_deriv ?_
    field_simp
    ring
  refine h.congr_deriv ?_
  field_simp

/-- 例 6 的辅助：tan(arcsin x) = x / √(1 − x²)（直角三角形代换）。 -/
lemma tan_arcsin (x : ℝ) (hm1 : -1 ≤ x) (h1 : x ≤ 1) :
    Real.tan (Real.arcsin x) = x / Real.sqrt (1 - x ^ 2) := by
  rw [Real.tan_eq_sin_div_cos, Real.cos_arcsin, Real.sin_arcsin hm1 h1]

/-- 例 6：y = x·arcsin x 在 0 < x < 1 内满足 y' = y/x + tan(y/x)。
（这是齐次方程 y' = y/x + tan(y/x) 的隐式通解 sin(y/x) = Cx 取 C = 1。） -/
example (x : ℝ) (hx1 : 0 < x) (hx2 : x < 1) :
    HasDerivAt (fun x => x * Real.arcsin x)
      ((fun x => x * Real.arcsin x) x / x + Real.tan ((fun x => x * Real.arcsin x) x / x)) x := by
  have hx1' : x ≠ -1 := by linarith
  have hsq : 0 < 1 - x ^ 2 := by nlinarith
  -- y' = arcsin x + x / sqrt(1 - x^2)（乘积法则 + arcsin 求导）
  have hderiv : HasDerivAt (fun x => x * Real.arcsin x)
      (Real.arcsin x + x / Real.sqrt (1 - x ^ 2)) x := by
    have hA : HasDerivAt (fun x : ℝ => x) 1 x := hasDerivAt_id x
    have hB : HasDerivAt Real.arcsin (1 / Real.sqrt (1 - x ^ 2)) x :=
      hasDerivAt_arcsin hx1' (by linarith)
    have hprod : HasDerivAt (fun y : ℝ => y * Real.arcsin y)
        (1 * Real.arcsin x + x * (1 / Real.sqrt (1 - x ^ 2))) x :=
      HasDerivAt.mul hA hB
    refine hprod.congr_deriv ?_
    field_simp
  -- 右端：y/x + tan(y/x) = arcsin x + tan(arcsin x) = arcsin x + x/sqrt(1-x²)
  have hrhs : (fun x => x * Real.arcsin x) x / x + Real.tan ((fun x => x * Real.arcsin x) x / x)
      = Real.arcsin x + x / Real.sqrt (1 - x ^ 2) := by
    have hdiv : (fun x => x * Real.arcsin x) x / x = Real.arcsin x := by
      field_simp
    rw [hdiv, tan_arcsin x (by linarith) (by linarith)]
  rw [hrhs]
  exact hderiv

/-- Malthus 通解族核对：y = C·e^{3x} 满足 y' = 3y（任意 C）。 -/
example (C : ℝ) (x : ℝ) :
    HasDerivAt (fun x => C * exp (3 * x)) (3 * (C * exp (3 * x))) x := by
  have h3 : HasDerivAt (fun x : ℝ => 3 * x) 3 x := by
    simpa using (hasDerivAt_id x).const_mul 3
  have h : HasDerivAt (fun x => exp (3 * x)) (3 * exp (3 * x)) x := by
    simpa only [Function.comp_def, mul_comm, mul_left_comm, mul_assoc] using
      HasDerivAt.comp x (hasDerivAt_exp (3 * x)) h3
  simpa [mul_left_comm] using HasDerivAt.const_mul C h
