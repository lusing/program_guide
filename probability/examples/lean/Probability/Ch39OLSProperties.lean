import Mathlib.Tactic

/-!
# 第 39 章：拟合优度分解与 Gauss–Markov 的代数锚
-/

open Matrix

namespace Ch39

-- 第 38 章固定例的 TSS = ESS + RSS（含常数项的正交分解）。
example : ((1 - 7 / 3) ^ 2 + (2 - 7 / 3) ^ 2 + (4 - 7 / 3) ^ 2 : ℚ)
    = (5 / 6 - 7 / 3) ^ 2 + (7 / 3 - 7 / 3) ^ 2 + (23 / 6 - 7 / 3) ^ 2
      + (1 / 6) ^ 2 + (-1 / 3) ^ 2 + (1 / 6) ^ 2 := by norm_num

-- TSS = 14/3，ESS = 9/2，RSS = 1/6。
example : ((16 + 1 + 25 : ℚ) / 9) = 14 / 3 := by norm_num
example : ((81 + 81 : ℚ) / 36) = 9 / 2 := by norm_num

-- R² = ESS/TSS = 27/28；调整 R² = 13/14。
example : ((9 : ℚ) / 2) / (14 / 3) = 27 / 28 := by norm_num
example : (1 : ℚ) - ((1 / 6) / (3 - 2)) / ((14 / 3) / (3 - 1)) = 13 / 14 := by
  norm_num

-- s² = RSS/(n-k) = 1/6；(X'X)⁻¹ 的 (2,2) 元 = 1/2。
example : ((1 : ℚ) / 6) / (3 - 2) = 1 / 6 := by norm_num
example : ((3 : ℚ) / 6) = 1 / 2 := by norm_num

-- Gauss–Markov 数值对照（σ² = 1）：
-- OLS 斜率方差 σ²(X'X)⁻¹₂₂ = 1/2 严格小于线性无偏竞争者 y₂ - y₁ 的方差 2。
example : ((1 : ℚ) / 2) < 2 := by norm_num

/-- GM 方差差的形状：σ²·‖v‖²，两项均非负故整体非负。 -/
theorem gm_gap_nonneg (sigma : ℚ) (v : Fin 3 → ℚ) :
    0 ≤ sigma ^ 2 * (v ⬝ᵥ v) := by
  have h0 : 0 ≤ v ⬝ᵥ v := by
    simp only [dotProduct]
    exact Finset.sum_nonneg fun i _ => mul_self_nonneg (v i)
  exact mul_nonneg (sq_nonneg sigma) h0

/-- E[e'e] = σ²·tr(M)：迹因子 n-k = 3-2 = 1 是 s² 无偏的自由度账。 -/
example : ((3 : ℚ) - 2) = 1 := by norm_num

end Ch39
