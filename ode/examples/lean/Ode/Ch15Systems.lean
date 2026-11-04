import Mathlib.Analysis.SpecialFunctions.Trigonometric.Deriv
import Mathlib.Analysis.Calculus.Deriv.Mul
import Mathlib.Analysis.Calculus.Deriv.Add

/-!
# 第 15 章 方程组（Lean）

旋转系统 x' = y、y' = -x 的解 (x, y) = (sin t, cos t)：
x' = cos t = y ✓，y' = -sin t = -x ✓。
两份单变量导数事实逐字核对二元线性组。
-/

open Real

namespace Ch15

/-- x = sin t 的导数是 cos t。 -/
example (t : ℝ) : HasDerivAt (fun t => Real.sin t) (Real.cos t) t :=
  hasDerivAt_sin t

/-- y = cos t 的导数是 -sin t。 -/
example (t : ℝ) : HasDerivAt (fun t => Real.cos t) (-(Real.sin t)) t := by
  exact hasDerivAt_cos t

/-- 组合账：x = sin t、y = cos t 满足 x' = y（第一个方程）。 -/
example (t : ℝ) :
    HasDerivAt (fun t => Real.sin t) ((fun t => Real.cos t) t) t :=
  hasDerivAt_sin t

/-- 组合账：y = cos t 满足 y' = -x（第二个方程）。 -/
example (t : ℝ) :
    HasDerivAt (fun t => Real.cos t) (-(fun t => Real.sin t) t) t :=
  hasDerivAt_cos t

/-- 初值核对：t = 0 时 (x, y) = (0, 1)。 -/
example : ((fun t => Real.sin t) 0, (fun t => Real.cos t) 0) = (0, 1) := by
  norm_num [Real.sin_zero, Real.cos_zero]

end Ch15
