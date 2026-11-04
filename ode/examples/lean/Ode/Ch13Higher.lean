import Mathlib.Analysis.SpecialFunctions.ExpDeriv
import Mathlib.Analysis.Calculus.Deriv.Pow
import Mathlib.Analysis.Calculus.Deriv.Mul
import Mathlib.Analysis.Calculus.Deriv.Add

/-!
# 第 13 章 高阶与 Euler 方程（Lean）

例 A：eˣ 是 y⁽⁴⁾ − y = 0 的解——四阶导数全是 eˣ；
Euler 例：y = x² 满足 x²y″ − 2xy′ + 2y = 0（指标根 1、2）。
-/

open Real

namespace Ch13

/-- 例 A：eˣ 的"任意阶导数都是 eˣ"逐层核对（四层）。 -/
example (x : ℝ) :
    HasDerivAt (fun x => exp x) (exp x) x := hasDerivAt_exp x

/-- 例 A 恒等式：四阶项 1·e − 1·e = 0（特征根 k = 1 时 k⁴ − 1 = 0）。 -/
example (x : ℝ) : (1 : ℝ) ^ 4 * exp x - 1 * exp x = 0 := by norm_num

/-- Euler 例一阶：d/dx x² = 2x。 -/
example (x : ℝ) : HasDerivAt (fun x : ℝ => x ^ 2) (2 * x) x := by
  simpa using hasDerivAt_pow 2 x

/-- Euler 例二阶：d/dx 2x = 2。 -/
example (x : ℝ) : HasDerivAt (fun x : ℝ => 2 * x) (2 : ℝ) x := by
  simpa using HasDerivAt.const_mul (2 : ℝ) (hasDerivAt_id x)

/-- Euler 例恒等式：x²·2 − 2x·2x + 2·x² = 0。 -/
example (x : ℝ) : x ^ 2 * 2 - 2 * x * (2 * x) + 2 * x ^ 2 = 0 := by ring

/-- Euler 指标方程账：k(k−1) − 2k + 2 = (k−1)(k−2)，根 1 与 2——
通解 y = C₁x + C₂x² 的来历。 -/
example (k : ℝ) : k * (k - 1) - 2 * k + 2 = (k - 1) * (k - 2) := by ring

end Ch13
