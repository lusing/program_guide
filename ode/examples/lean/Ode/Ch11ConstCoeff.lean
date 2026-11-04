import Mathlib.Analysis.SpecialFunctions.ExpDeriv
import Mathlib.Analysis.Calculus.Deriv.Pow
import Mathlib.Analysis.Calculus.Deriv.Mul
import Mathlib.Analysis.Calculus.Deriv.Add

/-!
# 第 11 章 常系数二阶（Lean）

特征根 2 与 −3：e^{2x}、e^{−3x} 都是 y″ + y′ − 6y = 0 的解；
W(e^{2x}, e^{−3x}) = −5e^{−x}——Abel 预言（p = 1）的逐字核对。
-/

open Real

namespace Ch11

/-- 导数事实：d/dx e^{2x} = 2e^{2x}。 -/
theorem deriv_exp2x (x : ℝ) :
    HasDerivAt (fun x => exp (2 * x)) (2 * exp (2 * x)) x := by
  have h2 : HasDerivAt (fun x : ℝ => 2 * x) (2 : ℝ) x := by
    simpa using (hasDerivAt_id x).const_mul (2 : ℝ)
  simpa only [Function.comp_def, mul_one, mul_comm, mul_left_comm, mul_assoc] using
    HasDerivAt.comp x (hasDerivAt_exp (2 * x)) h2

/-- 导数事实：d/dx e^{−3x} = −3e^{−3x}。 -/
theorem deriv_expm3x (x : ℝ) :
    HasDerivAt (fun x => exp (-3 * x)) (-(3 * exp (-3 * x))) x := by
  have h3 : HasDerivAt (fun x : ℝ => -3 * x) (-3 : ℝ) x := by
    simpa using (hasDerivAt_id x).const_mul (-3 : ℝ)
  have hcomp : HasDerivAt (fun x => exp (-3 * x)) (-3 * exp (-3 * x)) x := by
    have h := HasDerivAt.comp x (hasDerivAt_exp (-3 * x)) h3
    simpa only [Function.comp_def, mul_one, mul_comm, mul_left_comm, mul_assoc] using h
  exact hcomp.congr_deriv (by ring)

/-- e^{2x} 满足 y″ + y′ − 6y = 0 的左端恒等式（配导数事实用）：
(2)²·e + 2·e − 6·e = 0。 -/
example (x : ℝ) :
    (2 : ℝ) ^ 2 * exp (2 * x) + 2 * exp (2 * x) - 6 * exp (2 * x) = 0 := by ring

/-- W(e^{2x}, e^{−3x}) = e^{2x}·(−3e^{−3x}) − e^{−3x}·2e^{2x} = −5e^{−x}。 -/
example (x : ℝ) :
    exp (2 * x) * (-(3 * exp (-3 * x))) - exp (-3 * x) * (2 * exp (2 * x))
      = -5 * exp (-x) := by
  have h1 : exp (2 * x) * exp (-3 * x) = exp (-x) := by
    rw [← Real.exp_add]
    congr 1
    ring
  have e3 : exp (-3 * x) * exp (2 * x) = exp (-x) := by
    rw [← Real.exp_add]
    congr 1
    ring
  linear_combination (-3) * h1 + (-2) * e3

end Ch11
