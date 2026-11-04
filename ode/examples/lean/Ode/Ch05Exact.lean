import Mathlib.Analysis.Calculus.Deriv.Pow
import Mathlib.Analysis.Calculus.Deriv.Mul
import Mathlib.Analysis.Calculus.Deriv.Add

/-!
# 第 05 章 恰当方程（Lean）

书 §2.5 例 2.22：(3x²y² + 7) dx + 2x³y dy = 0 是恰当方程，
势函数 F(x, y) = x³y² + 7x。三份机器核对：
- ∂F/∂x = 3x²y² + 7（= P）；
- ∂F/∂y = 2x³y（= Q）；
- 判据的必要性现场版：∂/∂y (∂F/∂x) = 6x²y = ∂/∂x (∂F/∂y)。
偏导用"冻结另一变量"的单变量 HasDerivAt 表述。
-/

open Real

/-- ∂F/∂x = 3x²y² + 7（P 侧）。 -/
theorem dF_dx (x y : ℝ) :
    HasDerivAt (fun x => x ^ 3 * y ^ 2 + 7 * x) (3 * x ^ 2 * y ^ 2 + 7) x := by
  have h1 : HasDerivAt (fun x => x ^ 3) (3 * x ^ 2) x := by
    simpa using hasDerivAt_pow 3 x
  have h2 : HasDerivAt (fun x => y ^ 2 * x ^ 3) (y ^ 2 * (3 * x ^ 2)) x :=
    HasDerivAt.const_mul (y ^ 2) h1
  have h3 : HasDerivAt (fun x => 7 * x) (7 * 1) x :=
    HasDerivAt.const_mul (7 : ℝ) (hasDerivAt_id x)
  have h4 : HasDerivAt (fun x => y ^ 2 * x ^ 3 + 7 * x) (y ^ 2 * (3 * x ^ 2) + 7 * 1) x :=
    HasDerivAt.add h2 h3
  have hfun : (fun x => x ^ 3 * y ^ 2 + 7 * x) = (fun x => y ^ 2 * x ^ 3 + 7 * x) := by
    funext (z : ℝ); ring
  rw [hfun]
  exact h4.congr_deriv (by ring)

/-- ∂F/∂y = 2x³y（Q 侧）。 -/
theorem dF_dy (x y : ℝ) :
    HasDerivAt (fun y => x ^ 3 * y ^ 2 + 7 * x) (2 * x ^ 3 * y) y := by
  have h1 : HasDerivAt (fun y => y ^ 2) (2 * y) y := by
    simpa using hasDerivAt_pow 2 y
  have h2 : HasDerivAt (fun y => x ^ 3 * y ^ 2) (x ^ 3 * (2 * y)) y :=
    HasDerivAt.const_mul (x ^ 3) h1
  have h3 : HasDerivAt (fun y => 7 * x) 0 y :=
    hasDerivAt_const (c := (7 * x : ℝ)) (x := y)
  have h4 : HasDerivAt (fun y => x ^ 3 * y ^ 2 + 7 * x) (x ^ 3 * (2 * y) + 0) y :=
    HasDerivAt.add h2 h3
  exact h4.congr_deriv (by ring)

/-- 判据核对：∂P/∂y = ∂Q/∂x（都是 6x²y）——恰当性判据在 F 上逐字成立。 -/
theorem mixed_partials (x y : ℝ) :
    HasDerivAt (fun y => 3 * x ^ 2 * y ^ 2 + 7) (6 * x ^ 2 * y) y ∧
    HasDerivAt (fun x => 2 * x ^ 3 * y) (6 * x ^ 2 * y) x := by
  constructor
  · have h1 : HasDerivAt (fun y => y ^ 2) (2 * y) y := by
      simpa using hasDerivAt_pow 2 y
    have h2 : HasDerivAt (fun y => 3 * x ^ 2 * y ^ 2) (3 * x ^ 2 * (2 * y)) y :=
      HasDerivAt.const_mul (3 * x ^ 2) h1
    have h3 : HasDerivAt (fun y => (7 : ℝ)) 0 y := hasDerivAt_const (c := (7 : ℝ)) (x := y)
    have h4 : HasDerivAt (fun y => 3 * x ^ 2 * y ^ 2 + (7 : ℝ)) (3 * x ^ 2 * (2 * y) + 0) y :=
      HasDerivAt.add h2 h3
    exact h4.congr_deriv (by ring)
  · have h1 : HasDerivAt (fun x => x ^ 3) (3 * x ^ 2) x := by
      simpa using hasDerivAt_pow 3 x
    have h2 : HasDerivAt (fun x => 2 * y * x ^ 3) (2 * y * (3 * x ^ 2)) x :=
      HasDerivAt.const_mul (2 * y) h1
    have hfun2 : (fun x => 2 * x ^ 3 * y) = (fun x => 2 * y * x ^ 3) := by
      funext (z : ℝ); ring
    rw [hfun2]
    exact h2.congr_deriv (by ring)
