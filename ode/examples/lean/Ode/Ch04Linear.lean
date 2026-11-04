import Mathlib.Analysis.SpecialFunctions.ExpDeriv
import Mathlib.Analysis.Calculus.Deriv.Pow
import Mathlib.Analysis.Calculus.Deriv.Mul
import Mathlib.Analysis.Calculus.Deriv.Add

/-!
# 第 04 章 一阶线性方程（Lean）

书 §2.4 例 2.16/2.17 的通解核对：
- y = C·e^{-5x} + eˣ/6 对任意 C 满足 y' + 5y = eˣ（参数变易/积分因子的产物）；
- y = C·x + x² 满足 y' − y/x = x（x ≠ 0）。
通解公式的"通用性"在这两个采样点上被逐字钉死。
-/

open Real

/-- 书例 2.16：y = C·e^{-5x} + e^x/6 对任意 C 解 y' + 5y = e^x，
即 y' = -(5y) + e^x。 -/
theorem ex216_general (C : ℝ) (x : ℝ) :
    HasDerivAt (fun x => C * exp (-5 * x) + exp x / 6)
      (-(5 * (C * exp (-5 * x) + exp x / 6)) + exp x) x := by
  have hE : HasDerivAt (fun x => exp (-5 * x)) (-5 * exp (-5 * x)) x := by
    have h5 : HasDerivAt (fun x : ℝ => -5 * x) (-5 : ℝ) x := by
      simpa using (hasDerivAt_id x).const_mul (-5 : ℝ)
    simpa only [Function.comp_def, mul_comm, mul_left_comm, mul_assoc] using
      HasDerivAt.comp x (hasDerivAt_exp (-5 * x)) h5
  have hC : HasDerivAt (fun x => C * exp (-5 * x)) (C * (-5 * exp (-5 * x))) x :=
    HasDerivAt.const_mul C hE
  have hQ : HasDerivAt (fun x => exp x / 6) (exp x / 6) x := by
    refine (HasDerivAt.div_const (hasDerivAt_exp x) (6 : ℝ)).congr_deriv ?_
    field_simp
  have hsum := HasDerivAt.add hC hQ
  refine hsum.congr_deriv ?_
  field_simp
  ring

/-- 书例 2.17：y = C·x + x² 满足 y' − y/x = x（x ≠ 0），即 y' = y/x + x。 -/
theorem ex217_general (C : ℝ) (x : ℝ) (hx : x ≠ 0) :
    HasDerivAt (fun x => C * x + x ^ 2) ((C * x + x ^ 2) / x + x) x := by
  have h1 : HasDerivAt (fun x : ℝ => C * x) C x := by
    simpa using (hasDerivAt_id x).const_mul C
  have h2 : HasDerivAt (fun x : ℝ => x ^ 2) (2 * x) x := by
    simpa using hasDerivAt_pow 2 x
  have hsum := HasDerivAt.add h1 h2
  refine hsum.congr_deriv ?_
  field_simp
  ring

/-- 初值核对：y' + 5y = e^x、y(0) = 1/6 的特解取 C = 0；
y(0) = e^0/6 = 1/6 ✓（解从初值出发）。 -/
example : (fun x => (0 : ℝ) * exp (-5 * x) + exp x / 6) 0 = 1 / 6 := by norm_num
