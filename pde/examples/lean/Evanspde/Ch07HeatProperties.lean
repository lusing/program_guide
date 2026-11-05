import Mathlib

/-!
# Ch07 热方程 II：能量恒等式的单模式完整证明

对应书 §2.3.3-§2.3.4（能量方法：d/dt ½∫u² = −∫|∇u|²、唯一性）。
对第一模式 u = e^{−π²t}·sin(πx)：

* `integral_sin_sq_pi` / `integral_cos_sq_pi`：∫₀¹ sin²/cos²(πx)dx = ½
  （和角公式 + FTC + sin²+cos²=1 显式喂给 linarith）；
* `heat_mode_energy`：能量恒等式 d/dt(½∫u²) = −∫|uₓ|² 的闭式版
  （两侧各为 −π²/2·e^{−2π²t}；raw 形状直给 + ring 收尾）。
-/

open Real intervalIntegral MeasureTheory

namespace Evanspde.Ch07

/-- ∫₀¹ cos(2πx) dx = 0（FTC：原函数 sin(2πx)/(2π)，端点 sin(2π)=0）。 -/
theorem integral_cos2pi : ∫ x in (0 : ℝ)..1, cos (2 * π * x) = 0 := by
  have h : ∀ x : ℝ,
      HasDerivAt (fun x => sin (2 * π * x) / (2 * π))
        (cos (2 * π * x) * ((2 * π) * 1) / (2 * π)) x := fun x =>
    ((hasDerivAt_sin (2 * π * x)).comp x ((hasDerivAt_id x).const_mul (2 * π))).div_const
      (2 * π)
  have e : sin (2 * π * 1) = 0 := by simp
  have hpi : (2 : ℝ) * π ≠ 0 := mul_ne_zero two_ne_zero Real.pi_pos.ne'
  have hcdiv : ∀ x : ℝ,
      cos (2 * π * x) * ((2 * π) * 1) / (2 * π) = cos (2 * π * x) := by
    intro x
    field_simp
  rw [integral_congr (f := fun x => cos (2 * π * x))
      (g := fun x => cos (2 * π * x) * ((2 * π) * 1) / (2 * π)) (fun x _ => (hcdiv x).symm),
    integral_eq_sub_of_hasDerivAt (fun x _ => h x)]
  · rw [e]
    norm_num
  · exact (by continuity : Continuous (fun x : ℝ => cos (2 * π * x) * ((2 * π) * 1) / (2 * π))).intervalIntegrable 0 1

/-- ∫₀¹ sin²(πx) dx = 1/2。 -/
theorem integral_sin_sq_pi : ∫ x in (0 : ℝ)..1, sin (π * x)^2 = 1 / 2 := by
  have key : ∀ x : ℝ, sin (π * x)^2 = 1 / 2 - cos (2 * π * x) / 2 := by
    intro x
    have h1 := sin_sq_add_cos_sq (π * x)
    rw [show (2 : ℝ) * π * x = π * x + π * x from by ring, Real.cos_add]
    linarith
  rw [integral_congr (f := fun x => sin (π * x)^2)
      (g := fun x => 1 / 2 - cos (2 * π * x) / 2) (fun x _ => key x),
    integral_sub ((by continuity : Continuous (fun _ : ℝ => (1 / 2 : ℝ))).intervalIntegrable 0 1)
      ((by continuity : Continuous (fun x : ℝ => cos (2 * π * x) / 2)).intervalIntegrable 0 1),
    intervalIntegral.integral_const, intervalIntegral.integral_div, integral_cos2pi]
  norm_num

/-- ∫₀¹ cos²(πx) dx = 1/2。 -/
theorem integral_cos_sq_pi : ∫ x in (0 : ℝ)..1, cos (π * x)^2 = 1 / 2 := by
  have key : ∀ x : ℝ, cos (π * x)^2 = 1 / 2 + cos (2 * π * x) / 2 := by
    intro x
    have h1 := sin_sq_add_cos_sq (π * x)
    rw [show (2 : ℝ) * π * x = π * x + π * x from by ring, Real.cos_add]
    linarith
  rw [integral_congr (f := fun x => cos (π * x)^2)
      (g := fun x => 1 / 2 + cos (2 * π * x) / 2) (fun x _ => key x),
    integral_add ((by continuity : Continuous (fun _ : ℝ => (1 / 2 : ℝ))).intervalIntegrable 0 1)
      ((by continuity : Continuous (fun x : ℝ => cos (2 * π * x) / 2)).intervalIntegrable 0 1),
    intervalIntegral.integral_const, intervalIntegral.integral_div, integral_cos2pi]
  norm_num

/-- **能量恒等式（第一模式，闭式版）**：e(t) = ½∫u² = e^{−2π²t}/4，
P(t) = ∫uₓ² = π²e^{−2π²t}/2，则 de/dt = −P。 -/
theorem heat_mode_energy (t : ℝ) :
    deriv (fun s => 1 / 4 * exp (-((2 * π) * π) * s)) t
      = -((π * π) * (exp (-((2 * π) * π) * t) / 2)) := by
  have hr : deriv (fun s => 1 / 4 * exp (-((2 * π) * π) * s)) t
      = 0 * exp (-((2 * π) * π) * t)
          + 1 / 4 * (exp (-((2 * π) * π) * t) * (0 * t + -((2 * π) * π) * 1)) :=
    (hasDerivAt_const t (1 / 4)).mul
      ((hasDerivAt_const t (-((2 * π) * π))).mul (hasDerivAt_id t) |>.exp) |>.deriv
  rw [hr]
  ring

end Evanspde.Ch07
