import Mathlib.Analysis.SpecialFunctions.ExpDeriv
import Mathlib.Analysis.SpecialFunctions.Sqrt
import Mathlib.Analysis.Calculus.Deriv.Pow
import Mathlib.Analysis.Calculus.Deriv.Mul
import Mathlib.Analysis.Calculus.Deriv.Add
import Mathlib.Analysis.Calculus.Deriv.Inv

/-!
# 第 09 章 降阶法（Lean）

例 A：y = √x（y² = C₁x + C₂ 的 C₁ = 1, C₂ = 0 支）满足
yy″ + (y′)² = 0；例 E：y = x⁻⁴ 满足 x²y″ + 4xy′ − 4y = 0。
二阶解核对 = 两层导数事实 + 代数恒等式。
-/

open Real

namespace Ch09

/-- 例 A 一阶：y = √x 的导数是 1/(2√x)。 -/
example (x : ℝ) (hx : x ≠ 0) :
    HasDerivAt (fun x => Real.sqrt x) (1 / (2 * Real.sqrt x)) x :=
  hasDerivAt_sqrt hx

/-- 例 A 二阶：y′ = 1/(2√x) 的导数是 −1/(4x√x)。 -/
example (x : ℝ) (hx : 0 < x) :
    HasDerivAt (fun x => 1 / (2 * Real.sqrt x)) (-1 / (4 * x * Real.sqrt x)) x := by
  have hd : HasDerivAt (fun x : ℝ => 2 * Real.sqrt x) (2 * (1 / (2 * Real.sqrt x))) x :=
    HasDerivAt.const_mul (2 : ℝ) (hasDerivAt_sqrt (ne_of_gt hx))
  have hnum : HasDerivAt (fun _ : ℝ => (1 : ℝ)) 0 x :=
    hasDerivAt_const (c := (1 : ℝ)) (x := x)
  have := HasDerivAt.div hnum hd (by positivity)
  refine this.congr_deriv ?_
  field_simp
  rw [Real.sq_sqrt hx.le]
  ring

/-- 例 A 恒等式：√x·(−1/(4x√x)) + (1/(2√x))² = 0——三件套拼出
yy″ + (y′)² = 0 的左端。 -/
example (x : ℝ) (hx : 0 < x) :
    Real.sqrt x * (-1 / (4 * x * Real.sqrt x)) + (1 / (2 * Real.sqrt x)) ^ 2 = 0 := by
  have h2 : (Real.sqrt x) ^ 2 = x := Real.sq_sqrt hx.le
  field_simp
  linarith

/-- 例 E 一阶：y = x⁻⁴（写成 1/x⁴）的导数是 −4/x⁵。 -/
example (x : ℝ) (hx : x ≠ 0) :
    HasDerivAt (fun x => 1 / x ^ 4) (-(4 / x ^ 5)) x := by
  have hp : HasDerivAt (fun x : ℝ => x ^ 4) (4 * x ^ 3) x := by
    simpa using hasDerivAt_pow 4 x
  have hnum : HasDerivAt (fun _ : ℝ => (1 : ℝ)) 0 x :=
    hasDerivAt_const (c := (1 : ℝ)) (x := x)
  have := HasDerivAt.div hnum hp (by positivity)
  refine this.congr_deriv ?_
  field_simp
  ring

/-- 例 E 二阶：y′ = −4/x⁵ 的导数是 20/x⁶。 -/
example (x : ℝ) (hx : x ≠ 0) :
    HasDerivAt (fun x => -(4 / x ^ 5)) (20 / x ^ 6) x := by
  have hp : HasDerivAt (fun x : ℝ => x ^ 5) (5 * x ^ 4) x := by
    simpa using hasDerivAt_pow 5 x
  have hnum : HasDerivAt (fun _ : ℝ => (4 : ℝ)) 0 x :=
    hasDerivAt_const (c := (4 : ℝ)) (x := x)
  have hdiv := HasDerivAt.div hnum hp (by positivity)
  have h4 : HasDerivAt (fun x : ℝ => 4 / x ^ 5) (-(20 / x ^ 6)) x := by
    refine hdiv.congr_deriv ?_
    field_simp
    ring
  exact (HasDerivAt.neg h4).congr_deriv (by ring)

/-- 例 E 恒等式：x²·(20/x⁶) + 4x·(−4/x⁵) − 4·(1/x⁴) = 0。 -/
example (x : ℝ) (hx : x ≠ 0) :
    x ^ 2 * (20 / x ^ 6) + 4 * x * (-(4 / x ^ 5)) - 4 * (1 / x ^ 4) = 0 := by
  field_simp
  ring

end Ch09
