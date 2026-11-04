import Mathlib.Analysis.Calculus.Deriv.Basic
import Mathlib.Analysis.SpecialFunctions.Trigonometric.Deriv

/-!
# 第 15 章（Lean 通道）：Du Fort–Frankel 特征值的模

DFF 格式化为二层组后增长矩阵特征值为
`μ± = (αcosφ ± √(1 − α²sin²φ))/(1 + α)`（α = 2r）。本章证明
**|μ|² ≤ 1**（无条件稳定的 von Neumann 内核）：

    (αc)² + (1 − α²s²) = 1 + α²(c² − s²) ≤ 1 + α² ≤ (1 + α)²，

对 α ≥ 0、c² + s² = 1 成立——纯代数。
-/

namespace Pdenum.Ch15

/-- **DFF 特征值的模方 ≤ 1**：`α ≥ 0`、`c² + s² = 1` 时
`(αc)² + (1 − α²s²) ≤ (1 + α)²`（分子是 |μ±|² 的公共值，分母展开
后多出 2α）。 -/
theorem dff_mu_modsq (α c s : ℝ) (hα : 0 ≤ α) (h : c * c + s * s = 1) :
    (α * c) ^ 2 + (1 - α ^ 2 * s ^ 2) ≤ (1 + α) ^ 2 := by
  have h1 : (α * c) ^ 2 + (1 - α ^ 2 * s ^ 2) = 1 + α ^ 2 * (c * c - s * s) := by
    nlinarith [h]
  have h2 : c * c - s * s ≤ 1 := by nlinarith [h]
  have h3 : (α:ℝ) ^ 2 * (c * c - s * s) ≤ (α:ℝ) ^ 2 := by
    nlinarith [h2, sq_nonneg α]
  nlinarith

end Pdenum.Ch15
