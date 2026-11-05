import Mathlib

/-!
# Ch02 传输方程：特征线解的完整机器证明

对应书 §2.1。书中论证：u_t + b·Du = 0 表示 u 沿方向 (b,1) 的
方向导数为零，故 u 在这些**特征线**上是常数；初值问题
u(x,0) = g 的解为 u(x,t) = g(x − tb)。

本文件把一维情形做成完整证明：

* `transport_solution`：u(x,t) = g(x − bt) 满足 ∂ₜu + b ∂ₓu = 0；
* `transport_initial`：初值条件逐点成立；
* 特征线常数论证的核（z(s) 常数）由两偏导相消直接体现。
-/

open Real

namespace Evanspde.Ch02

/-- **表示公式是解**：若 g 处处可微（导函数 g'），则
u(x,t) = g(x − bt) 满足 uₜ + b·uₓ = 0——链式法则两个方向相消。 -/
theorem transport_solution (b : ℝ) {g g' : ℝ → ℝ}
    (hg : ∀ x, HasDerivAt g (g' x) x) (x t : ℝ) :
    deriv (fun t => g (x - b * t)) t + b * deriv (fun y => g (y - b * t)) x = 0 := by
  -- ∂ₜ：内层映射 t ↦ x - b·t 导数值为 0 - b*1（ring 收账时等于 -b）
  have hxt : HasDerivAt (fun t : ℝ => x - b * t) (0 - b * 1) t :=
    (hasDerivAt_const t x).sub ((hasDerivAt_id t).const_mul b)
  have ht : HasDerivAt (fun t : ℝ => g (x - b * t)) (g' (x - b * t) * (0 - b * 1)) t :=
    (hg (x - b * t)).comp t hxt
  -- ∂ₓ：内层映射 y ↦ y - b·t 导数值为 1 - 0
  have hyt : HasDerivAt (fun y : ℝ => y - b * t) (1 - 0) x :=
    (hasDerivAt_id x).sub (hasDerivAt_const x (b * t))
  have hx : HasDerivAt (fun y : ℝ => g (y - b * t)) (g' (x - b * t) * (1 - 0)) x :=
    (hg (x - b * t)).comp x hyt
  rw [ht.deriv, hx.deriv]
  ring

/-- 初值条件：u(x, 0) = g(x − b·0) = g(x)，定义即得。 -/
theorem transport_initial (b : ℝ) (g : ℝ → ℝ) (x : ℝ) :
    (fun t => g (x - b * t)) 0 = g x := by
  simp

/-- **特征线是水平线**：b = 0 时解不随时间变化（退化为常函数核）。 -/
example (g : ℝ → ℝ) (x t : ℝ) (hg : ∀ y, HasDerivAt g (0 : ℝ) y) :
    deriv (fun t => g (x - 0 * t)) t + 0 * deriv (fun y => g (y - 0 * t)) x = 0 :=
  transport_solution 0 hg x t

end Evanspde.Ch02
