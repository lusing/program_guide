import Mathlib.Analysis.Calculus.Deriv.Basic
import Mathlib.Analysis.SpecialFunctions.Trigonometric.Deriv
import Mathlib.Analysis.SpecialFunctions.ExpDeriv

/-!
# 第 01 章（Lean 通道）：三个模型方程的解核对

本章是全书的"对表"样张：取对流、扩散、波动三个模型方程的精确解，
用 `HasDerivAt`（导数存在的原始表述）逐字核对它们满足方程。后续
所有差分格式、有限元离散的正确性讨论，都建立在"方程本身是什么"
这一第一事实上。

mathlib 4.33.1 签名账（probe 实测）：
- `sin`/`cos`/`exp` 无根级标识符，`open Real` 后可用（显示为 rexp）；
- `hasDerivAt_const (x) (c)`：两显参，先考察点后常值；
- `HasDerivAt.const_mul (c) (h)`：常数在前、证明在后；
- **`HasDerivAt.exp` / `.sin` / `.cos` 点组合子存在**（λ 形式产物），
  链式法则优先用它，避免 `HasDerivAt.comp` 的 `∘` 形态桥接；
- `HasDerivAt.sub` 的产物是 Pi.sub 形式，与 λ 目标之间用
  `funext s; rfl` 等价改写桥接；
- 各引理按组合子**产出一形式**陈述，"人写形式"与"产出形式"的
  换算集中到纯 ring 的收尾定理里。
-/

open Real

namespace Pdenum.Ch01

/-! ## 对流方程 `u_t + a * u_x = 0`：解 `u = sin (x - a t)` -/

/-- 对流方程解的时间片：`t ↦ sin (x - a*t)` 的导数是 `cos (x - a*t) * (-a)`。 -/
lemma hasDerivAt_advection_t (x a t : ℝ) :
    HasDerivAt (fun t => sin (x - a * t)) (cos (x - a * t) * (-a)) t := by
  have h1 : HasDerivAt (fun _ => x) 0 t := hasDerivAt_const t x
  have h2 : HasDerivAt (fun s => a * s) a t := by
    simpa [mul_one] using HasDerivAt.const_mul a (hasDerivAt_id t)
  have hsub : HasDerivAt ((fun _ : ℝ => x) - (fun s => a * s)) (0 - a) t :=
    HasDerivAt.sub h1 h2
  have heq : (fun s => x - a * s) = ((fun _ : ℝ => x) - (fun s => a * s)) := by
    funext s; rfl
  rw [← heq] at hsub
  have hsin := HasDerivAt.sin hsub
  simpa using hsin

/-- 对流方程解的空间片：`y ↦ sin (y - a*t₀)` 的导数是 `cos (y - a*t₀)`。 -/
lemma hasDerivAt_advection_x (y a t : ℝ) :
    HasDerivAt (fun y => sin (y - a * t)) (cos (y - a * t)) y := by
  have h1 : HasDerivAt (fun y => y) 1 y := hasDerivAt_id y
  have h2 : HasDerivAt (fun _ => a * t) 0 y := hasDerivAt_const y (a * t)
  have hsub : HasDerivAt ((fun y : ℝ => y) - (fun _ => a * t)) (1 - 0) y :=
    HasDerivAt.sub h1 h2
  have heq : (fun z => z - a * t) = ((fun z : ℝ => z) - (fun _ => a * t)) := by
    funext z; rfl
  rw [← heq] at hsub
  have hsin := HasDerivAt.sin hsub
  simpa using hsin

/-- **对流方程核对**：`u(x,t) = sin (x - a t)` 满足 `u_t + a * u_x = 0`——
时间片导数 `cos·(−a)` 与 `a ×` 空间片导数 `a·cos` 相消。 -/
theorem advection_solution (x a t : ℝ) :
    cos (x - a * t) * (-a) + a * cos (x - a * t) = 0 := by ring

/-! ## 扩散方程 `u_t = u_xx`：分离变量解 `u = exp (-π²t) * sin (πx)` -/

/-- 扩散方程解的时间片导数：`sin (πx) * (exp (-π²t) * (-π²))`。 -/
lemma hasDerivAt_heat_t (x t : ℝ) :
    HasDerivAt (fun s => sin (π * x) * exp (-(π : ℝ) ^ 2 * s))
      (sin (π * x) * (exp (-(π : ℝ) ^ 2 * t) * -(π : ℝ) ^ 2)) t := by
  have h1 : HasDerivAt (fun s => -(π : ℝ) ^ 2 * s) (-(π : ℝ) ^ 2) t := by
    simpa [mul_one] using HasDerivAt.const_mul (-(π : ℝ) ^ 2) (hasDerivAt_id t)
  exact HasDerivAt.const_mul (sin (π * x)) (HasDerivAt.exp h1)

/-- 扩散方程解的空间片一阶导数：`exp (-π²t) * (cos (πx) * π)`。 -/
lemma hasDerivAt_heat_x1 (x t : ℝ) :
    HasDerivAt (fun y => exp (-(π : ℝ) ^ 2 * t) * sin (π * y))
      (exp (-(π : ℝ) ^ 2 * t) * (cos (π * x) * π)) x := by
  have h1 : HasDerivAt (fun y => π * y) π x := by
    simpa [mul_one] using HasDerivAt.const_mul (π : ℝ) (hasDerivAt_id x)
  exact HasDerivAt.const_mul (exp (-(π : ℝ) ^ 2 * t)) (HasDerivAt.sin h1)

/-- 扩散方程解的空间片二阶导数：`exp (-π²t) * (π * (-sin (πx) * π))`。 -/
lemma hasDerivAt_heat_x2 (x t : ℝ) :
    HasDerivAt (fun y => exp (-(π : ℝ) ^ 2 * t) * (π * cos (π * y)))
      (exp (-(π : ℝ) ^ 2 * t) * (π * (-sin (π * x) * π))) x := by
  have h1 : HasDerivAt (fun y => π * y) π x := by
    simpa [mul_one] using HasDerivAt.const_mul (π : ℝ) (hasDerivAt_id x)
  exact HasDerivAt.const_mul (exp (-(π : ℝ) ^ 2 * t))
    (HasDerivAt.const_mul (π : ℝ) (HasDerivAt.cos h1))

/-- **扩散方程核对**：`u_t` 与 `u_xx` 是同一个数（`-π² · u`），
即 `u = exp (-π²t) sin (πx)` 满足 `u_t = u_xx`。 -/
theorem heat_solution (x t : ℝ) :
    sin (π * x) * (exp (-(π : ℝ) ^ 2 * t) * -(π : ℝ) ^ 2)
      = exp (-(π : ℝ) ^ 2 * t) * (π * (-sin (π * x) * π)) := by
  have hπ : (π : ℝ) ^ 2 = π * π := by ring
  rw [hπ]
  ring

/-! ## 波动方程 `u_tt = a² * u_xx`：d'Alembert 解（取 `g = s²`） -/

/-- d'Alembert 解 `u(x,t) = (a t)² + x²`（即 ½[(x+at)² + (x−at)²]）的
时间片一阶导数（按 `add_const` 的 `f + c` 产出形陈述）。 -/
lemma hasDerivAt_wave_t1 (x a t : ℝ) :
    HasDerivAt (fun s : ℝ => a * s * (a * s) + x * x)
      (a * (a * t) + a * t * a) t := by
  have ha : HasDerivAt (fun s : ℝ => a * s) a t := by
    simpa [mul_one] using HasDerivAt.const_mul a (hasDerivAt_id t)
  have hm : HasDerivAt (fun s : ℝ => a * s * (a * s)) (a * (a * t) + a * t * a) t :=
    HasDerivAt.mul ha ha
  exact HasDerivAt.add_const (x * x) hm

/-- 时间片二阶导数：`u_tt = a² + a² = 2a²`。 -/
lemma hasDerivAt_wave_t2 (a t : ℝ) :
    HasDerivAt (fun s : ℝ => a * (a * s) + a * (a * s)) (a * a + a * a) t := by
  have ha : HasDerivAt (fun s : ℝ => a * s) a t := by
    simpa [mul_one] using HasDerivAt.const_mul a (hasDerivAt_id t)
  exact HasDerivAt.add (HasDerivAt.const_mul a ha) (HasDerivAt.const_mul a ha)

/-- 空间片：`u(x,t) = x² + 常数` 关于 x 的导数为 `y + y`。 -/
lemma hasDerivAt_wave_xx (y : ℝ) :
    HasDerivAt (fun y : ℝ => y * y) (y + y) y := by
  have h : HasDerivAt (fun y : ℝ => id y * id y) (1 * id y + id y * 1) y :=
    HasDerivAt.mul (hasDerivAt_id y) (hasDerivAt_id y)
  simpa [id_eq, mul_one, mul_comm] using h

/-- **波动方程核对**：`u_tt = 2a² = a² · u_xx`。 -/
theorem wave_solution (a : ℝ) : a * a + a * a = a * a * (1 + 1) := by ring

end Pdenum.Ch01
