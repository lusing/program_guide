import Mathlib.Analysis.Calculus.Deriv.Basic
import Mathlib.Analysis.SpecialFunctions.Trigonometric.Deriv

/-!
# 第 07 章（Lean 通道）：Lax–Wendroff 增长因子的恒等式

Lax–Wendroff 格式 `u_j^{n+1} = u_j − (μ/2)(u_{j+1} − 2u_j + ...)` 的
增长因子

    G(θ) = 1 − 2μ²·sin²(θ/2) − i·μ·sinθ

满足 `|G|² = 1 − 4μ²(1 − μ²)·sin⁴(θ/2)`（书 (1.15) 的推导内核）。
以 C = cosθ、S = sinθ 表述（sin²(θ/2) = (1−C)/2），两式之差是
`C² + S² = 1` 的倍式——`linear_combination` 一步闭核；稳定方向
`0 ≤ μ ≤ 1 ⟹ |G|² ≤ 1` 随之是简单的非负性论证。
-/

open Real

namespace Pdenum.Ch07

/-- Lax–Wendroff 增长因子的模方恒等式：
`(1 − μ²(1−C))² + (μS)² = 1 − μ²(1−μ²)(1−C)²`，其中 `C² + S² = 1`
（即 C = cosθ、S = sinθ；`μ²(1−C) = 2μ²sin²(θ/2)`）。 -/
theorem lw_G_sq_identity (μ C S : ℝ) (h : C * C + S * S = 1) :
    (1 - μ ^ 2 * (1 - C)) ^ 2 + (μ * S) ^ 2
      = 1 - μ ^ 2 * (1 - μ ^ 2) * (1 - C) ^ 2 := by
  linear_combination μ ^ 2 * h

/-- 稳定方向：`0 ≤ μ ≤ 1` 且 `|C| ≤ 1` 时 `|G|² ≤ 1`
（耗散项 `4μ²(1−μ²)sin⁴(θ/2) ≥ 0`）。 -/
theorem lw_stable (μ C S : ℝ) (hμ1 : 0 ≤ μ) (hμ2 : μ ≤ 1)
    (_hC : -1 ≤ C) (hC2 : C ≤ 1) (h : C * C + S * S = 1) :
    (1 - μ ^ 2 * (1 - C)) ^ 2 + (μ * S) ^ 2 ≤ 1 := by
  have hid := lw_G_sq_identity μ C S h
  have h1C : 0 ≤ 1 - C := by linarith
  have h1 : 0 ≤ 1 - μ ^ 2 := by nlinarith
  have hsq : 0 ≤ μ ^ 2 * (1 - μ ^ 2) * (1 - C) ^ 2 :=
    mul_nonneg (mul_nonneg (sq_nonneg μ) h1) (sq_nonneg (1 - C))
  linarith

end Pdenum.Ch07
