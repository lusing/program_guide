import Mathlib.Analysis.Calculus.Deriv.Basic
import Mathlib.Analysis.SpecialFunctions.Trigonometric.Deriv

/-!
# 第 14 章（Lean 通道）：加权隐式格式的增长因子

加权隐式格式（θ=0 FTCS、θ=1 BTCS、θ=1/2 Crank–Nicolson）的增长因子

    G = (1 − 4(1−θ)r·s²) / (1 + 4θ·r·s²)，  s² = sin²(θ_grid/2) ∈ [0,1]。

本章证明稳定性的两个方向：

- **θ ≥ 1/2 ⟹ 无条件稳定**：分母 − 分子 = 4r·s²（θ 项） + 4(1−θ)r·s²
  = 4r·s² ≥ 0，且分母 > 0，故 |G| ≤ 1；
- **θ = 0、r > 1/2 ⟹ 不稳定**：取 s² = 1 得 |1 − 4r| = 4r − 1 > 1。
-/

namespace Pdenum.Ch14

/-- **θ ≥ 1/2 时无条件稳定**：对一切 r ≥ 0 与 s² ∈ [0,1]，
|1 − 4(1−θ)r·s²| ≤ 1 + 4θ·r·s²（分母恒正）。 -/
theorem weighted_stable (theta r s2 : ℝ) (hθ : 1 / 2 ≤ theta)
    (hr : 0 ≤ r) (hs : 0 ≤ s2) (_hs2 : s2 ≤ 1) :
    |1 - 4 * (1 - theta) * r * s2| ≤ 1 + 4 * theta * r * s2 := by
  have hnum_le : 1 - 4 * (1 - theta) * r * s2 ≤ 1 + 4 * theta * r * s2 := by
    have h1 : 4 * (1 - theta) * r * s2 + 4 * theta * r * s2 = 4 * r * s2 := by ring
    have h2 : 0 ≤ 4 * r * s2 := by nlinarith
    linarith
  have hnum_ge : -(1 + 4 * theta * r * s2) ≤ 1 - 4 * (1 - theta) * r * s2 := by
    -- 4(1−θ)rs² ≤ 2rs² ≤ 2 + 8θrs²（θ ≥ 1/2 ⟹ 8θ ≥ 4 > 2）
    have hpos : 0 ≤ r * s2 := mul_nonneg hr hs
    have hAB : (4:ℝ) * (1 - theta) ≤ 4 * (1 / 2 : ℝ) := by linarith
    have h1 : (4:ℝ) * (1 - theta) * (r * s2) ≤ (4:ℝ) * (1 / 2 : ℝ) * (r * s2) :=
      mul_le_mul_of_nonneg_right hAB hpos
    have h2 : (2:ℝ) * (r * s2) ≤ 2 + 8 * theta * r * s2 := by
      have hf : (2:ℝ) ≤ 8 * theta := by linarith
      nlinarith [hpos, hf]
    nlinarith [h1, h2]
  rw [abs_le]
  constructor <;> linarith

/-- **θ = 0、r > 1/2 时不稳定**：最高波型 s² = 1 处 |G| = 4r − 1 > 1。 -/
theorem ftcs_unstable (r : ℝ) (hr : 1 / 2 < r) :
    1 < |1 - 4 * (1 - 0:ℝ) * r * 1| := by
  have h4 : 2 < 4 * r := by linarith
  have hG : 1 - 4 * (1 - 0:ℝ) * r * 1 = 1 - 4 * r := by ring
  have hn : (1:ℝ) - 4 * r < 0 := by linarith
  rw [hG, abs_of_neg hn]
  linarith

end Pdenum.Ch14
