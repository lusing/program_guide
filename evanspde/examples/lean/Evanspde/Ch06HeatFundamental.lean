import Mathlib

/-!
# Ch06 热方程 I：分离变量解满足热方程的完整机器证明

对应书 §2.3.1（热核的另一个入口是分离变量——§4.1 的主角）。
本文件完整证明**分离变量解**满足热方程：

    u(x,t) = e^{−k²t}·sin(kx)    ⟹    u_t − u_xx = 0

工程注记（Lean 4.33 实测）：组合子给出的导数值自带 `0 * t + …`、
`… * 0` 形状，**声明直接采用产出形状**，整洁形式放在最终定理里用
`ring` 收——不与 elaborator 争辩形状。
-/

open Real

namespace Evanspde.Ch06

/-- t 方向导数（产出形状：`(0*t + −k²·1)` 因子与 `… * 0` 项）。 -/
theorem heat_mode_t_raw (k x t : ℝ) :
    deriv (fun t => exp (-(k^2) * t) * sin (k * x)) t
      = (exp (-(k^2) * t) * (0 * t + -(k^2) * 1)) * sin (k * x)
          + exp (-(k^2) * t) * 0 :=
  ((hasDerivAt_const t (-(k^2))).mul (hasDerivAt_id t)).exp
    |>.mul (hasDerivAt_const t (sin (k * x))) |>.deriv

/-- x 方向二层导数（产出形状）。 -/
theorem heat_mode_xx_raw (k x t : ℝ) :
    deriv (fun y => deriv (fun z => exp (-(k^2) * t) * sin (k * z)) y) x
      = 0 * sin (k * x) + 0 * (cos (k * x) * (k * 1))
          + (0 * (cos (k * x) * (k * 1))
            + exp (-(k^2) * t) * ((-sin (k * x) * (k * 1)) * (k * 1) + cos (k * x) * 0)) := by
  have hxi : ∀ y : ℝ, HasDerivAt (fun z : ℝ => k * z) (k * 1) y :=
    fun y => (hasDerivAt_id y).const_mul k
  have h1 : ∀ y : ℝ,
      HasDerivAt (fun z : ℝ => exp (-(k^2) * t) * sin (k * z))
        (0 * sin (k * y) + exp (-(k^2) * t) * (cos (k * y) * (k * 1))) y := fun y =>
    (hasDerivAt_const y (exp (-(k^2) * t))).mul ((hasDerivAt_sin (k * y)).comp y (hxi y))
  have e1 : (fun y => deriv (fun z : ℝ => exp (-(k^2) * t) * sin (k * z)) y)
      = fun y => 0 * sin (k * y) + exp (-(k^2) * t) * (cos (k * y) * (k * 1)) :=
    funext fun y => (h1 y).deriv
  have h2 : ∀ y : ℝ,
      HasDerivAt (fun z : ℝ => 0 * sin (k * z) + exp (-(k^2) * t) * (cos (k * z) * (k * 1)))
        (0 * sin (k * y) + 0 * (cos (k * y) * (k * 1))
          + (0 * (cos (k * y) * (k * 1))
            + exp (-(k^2) * t) * ((-sin (k * y) * (k * 1)) * (k * 1) + cos (k * y) * 0))) y :=
    fun y =>
    ((hasDerivAt_const y (0:ℝ)).mul ((hasDerivAt_sin (k * y)).comp y (hxi y))).add
      ((hasDerivAt_const y (exp (-(k^2) * t))).mul
        (((hasDerivAt_cos (k * y)).comp y (hxi y)).mul (hasDerivAt_const y (k * 1))))
  rw [e1]
  exact (h2 x).deriv

/-- 整洁形式：∂ₜ[e^{−k²t}sin kx] = −k²·e^{−k²t}sin kx。 -/
theorem heat_mode_t (k x t : ℝ) :
    deriv (fun t => exp (-(k^2) * t) * sin (k * x)) t
      = -(k^2) * (exp (-(k^2) * t) * sin (k * x)) := by
  rw [heat_mode_t_raw k x t]
  ring

/-- 整洁形式：∂²ₓₓ[e^{−k²t}sin kx] = −k²·e^{−k²t}sin kx。 -/
theorem heat_mode_xx (k x t : ℝ) :
    deriv (fun y => deriv (fun z => exp (-(k^2) * t) * sin (k * z)) y) x
      = -(k^2) * (exp (-(k^2) * t) * sin (k * x)) := by
  rw [heat_mode_xx_raw k x t]
  ring

/-- **分离变量解满足热方程**：u_t − u_xx = 0，对一切波数 k。 -/
theorem heat_mode_solves (k x t : ℝ) :
    deriv (fun t => exp (-(k^2) * t) * sin (k * x)) t
      - deriv (fun y => deriv (fun z => exp (-(k^2) * t) * sin (k * z)) y) x = 0 := by
  rw [heat_mode_t k x t, heat_mode_xx k x t]
  ring

end Evanspde.Ch06
