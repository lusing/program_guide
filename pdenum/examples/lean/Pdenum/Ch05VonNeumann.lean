import Mathlib.Analysis.Calculus.Deriv.Basic
import Mathlib.Analysis.SpecialFunctions.Trigonometric.Deriv
import Mathlib.Analysis.SpecialFunctions.Sqrt

/-!
# 第 05 章（Lean 通道）：增长因子的代数内核

von Neumann 分析落到每个具体格式上都是两件事：算出增长因子 G(θ)、
验证 |G| ≤ 1 的充要条件。本章把三个核心格式的判定内核做成 Lean 定理：

1. 迎风格式：`|G|² = 1 − 2μ(1−μ)(1−C)`（C = cosθ，S = sinθ）——
   恒等式 `C² + S² = 1` 的纯代数推论（`linear_combination` 一步）；
2. FTCS 热传导：`G = 1 − 2r(1−C)`，r ≤ 1/2 时 |G| ≤ 1（对一切 C），
   r > 1/2 时在 C = −1（θ = π）处 |G| = 4r − 1 > 1；
3. Richardson 增长矩阵的出界特征值：`−4s − √(16s²+1) < −1`（s > 0），
   分情况讨论 + 平方比较。

mathlib 4.33.1 签名账：`Real.sqrt_lt_sqrt : 0 ≤ x → x < y → √x < √y`；
`Real.sqrt_sq : 0 ≤ x → √(x²) = x`；`abs_le : |a| ≤ b ↔ −b ≤ a ∧ a ≤ b`。
-/

open Real

namespace Pdenum.Ch05

/-! ## 迎风格式：|G|² 恒等式 -/

/-- 迎风格式的增长因子 `G = 1 − μ + μ·cosθ − i·μ·sinθ` 满足
`|G|² = 1 − 2μ(1−μ)(1−cosθ)`。这是书例 3.2 的全部代数内容：
两式之差恰为 `μ²·(C² + S² − 1)`，`linear_combination` 一步闭核。 -/
theorem upwind_G_sq_identity (μ C S : ℝ) (h : C * C + S * S = 1) :
    (1 - μ + μ * C) ^ 2 + (μ * S) ^ 2 = 1 - 2 * μ * (1 - μ) * (1 - C) := by
  linear_combination μ ^ 2 * h

/-- 稳定方向：`0 ≤ μ ≤ 1` 且 `|C| ≤ 1` 时 `|G|² ≤ 1`。 -/
theorem upwind_stable (μ C S : ℝ) (hμ : 0 ≤ μ) (hμ2 : μ ≤ 1)
    (_hC : -1 ≤ C) (hC2 : C ≤ 1) (h : C * C + S * S = 1) :
    (1 - μ + μ * C) ^ 2 + (μ * S) ^ 2 ≤ 1 := by
  have hid := upwind_G_sq_identity μ C S h
  have h1C : 0 ≤ 1 - C := by linarith
  have h1μ : 0 ≤ 1 - μ := by linarith
  have hp1 : 0 ≤ μ * (1 - μ) := mul_nonneg hμ h1μ
  have hprod : 0 ≤ μ * (1 - μ) * (1 - C) := mul_nonneg hp1 h1C
  linarith

/-! ## FTCS 热传导：r ≤ 1/2 ⟺ 稳定 -/

/-- FTCS 热传导的增长因子 `G = 1 − 2r(1−C)`（C = cosθ）。
`r ≤ 1/2` 时对一切 `C ∈ [−1, 1]` 都有 `|G| ≤ 1`。 -/
theorem ftcs_heat_stable (r C : ℝ) (hr : 0 ≤ r) (hr2 : r ≤ 1 / 2)
    (hC : -1 ≤ C) (hC2 : C ≤ 1) :
    |1 - 2 * r * (1 - C)| ≤ 1 := by
  have h1C : 0 ≤ 1 - C := by linarith
  have h1C2 : 1 - C ≤ 2 := by linarith
  have hstep1 : r * (1 - C) ≤ r * 2 := mul_le_mul_of_nonneg_left h1C2 hr
  have hstep2 : r * 2 ≤ 1 := by linarith
  have key : r * (1 - C) ≤ 1 := by linarith
  have hpos : 0 ≤ r * (1 - C) := mul_nonneg hr h1C
  rw [abs_le]
  constructor <;> linarith

/-- 不稳定方向：`r > 1/2` 时取 `C = −1`（即 θ = π 的最高波型）得
`|G| = 4r − 1 > 1`——条件不可省。 -/
theorem ftcs_heat_unstable (r : ℝ) (hr : 1 / 2 < r) :
    1 < |1 - 2 * r * (1 - (-1))| := by
  have h4 : 2 < 4 * r := by linarith
  have hG : 1 - 2 * r * (1 - (-1)) = 1 - 4 * r := by ring
  have hn : (1 : ℝ) - 4 * r < 0 := by linarith
  rw [hG, abs_of_neg hn]
  linarith

/-! ## Richardson：出界特征值 -/

/-- Richardson 格式增长矩阵 `G = [[−8rs, 1], [1, 0]]` 的特征值
`−4rs ± √(16r²s² + 1)` 中取减号的一支满足 `μ₂ < −1`（对一切 `s > 0`，
与 r 无关——这正是"无条件不稳定"）。 -/
theorem richardson_beyond (s : ℝ) (hs : 0 < s) :
    -4 * s - Real.sqrt (16 * s ^ 2 + 1) < -1 := by
  by_cases h4 : 4 * s ≤ 1
  · -- 4s ≤ 1：sqrt(16s²+1) > 1 ≥ 1 − 4s
    have hsq : 1 < 16 * s ^ 2 + 1 := by nlinarith
    have h1 : 1 < Real.sqrt (16 * s ^ 2 + 1) := by
      simpa using Real.sqrt_lt_sqrt (by norm_num) hsq
    linarith
  · -- 4s > 1：1 − 4s < 0 < sqrt(...)，平凡
    have hp : 1 - 4 * s < 0 := by linarith
    have hnn : 0 ≤ Real.sqrt (16 * s ^ 2 + 1) := Real.sqrt_nonneg _
    linarith

end Pdenum.Ch05
