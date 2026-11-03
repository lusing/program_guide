import Mathlib.Tactic

/-!
# 第 41 章：受约束 OLS、遗漏变量偏误与 GLS 的代数锚
-/

namespace Ch41

-- 受约束估计量闭式：β̃ = β̂ - (X'X)⁻¹R'[R(X'X)⁻¹R']⁻¹(Rβ̂-r) = (1,1)。
example : (7 : ℚ) / 5 - (-1 / 5) * (-1 / 5) / (1 / 10) = 1 := by norm_num
example : (4 : ℚ) / 5 - (1 / 10) * (-1 / 5) / (1 / 10) = 1 := by norm_num

-- 受约束残差：拟合 x + 1 时 RSS_R = 4，二次型公式给出同一差值。
example : (0 : ℚ) ^ 2 + 1 ^ 2 + (-1) ^ 2 + 1 ^ 2 + (-1) ^ 2 = 4 := by norm_num
example : (4 : ℚ) - 18 / 5 = 2 / 5 := by norm_num
example : ((4 : ℚ) / 5 - 1) ^ 2 / (1 / 10) = 2 / 5 := by norm_num

-- 受约束 F = ((RSS_R - RSS_U)/1)/(RSS_U/3)。
example : ((2 : ℚ) / 5 / 1) / ((18 / 5) / 3) = 1 / 3 := by norm_num

-- 遗漏变量偏误：(X₁'X₁)⁻¹X₁'z₂ 的两个分量与放大后的偏差。
example : ((30 : ℚ) * 4 - 10 * 13) / 50 = -1 / 5 := by norm_num
example : ((-10 : ℚ) * 4 + 5 * 13) / 50 = 1 / 2 := by norm_num
example : (2 : ℚ) * (-1 / 5) = -2 / 5 := by norm_num
example : (2 : ℚ) * (1 / 2) = 1 := by norm_num

-- 无关但相关的变量使方差膨胀 28/3 倍。
example : ((14 : ℚ) / 15) / (1 / 10) = 28 / 3 := by norm_num

-- GLS 解（Ω = diag(1,1,1,4,4) 的正规方程）。
example : ((45 : ℚ) / 4 * 33 / 4 - 19 / 4 * 59 / 4) /
    ((7 / 2) * (45 / 4) - (19 / 4) ^ 2) = 364 / 269 := by norm_num
example : ((7 : ℚ) / 2 * 59 / 4 - 19 / 4 * 33 / 4) /
    ((7 / 2) * (45 / 4) - (19 / 4) ^ 2) = 199 / 269 := by norm_num

-- Aitken 对照：OLS 的真实方差 1/4 大于 GLS 方差 56/269。
example : (-1 / 5) * (9 / 10 : ℚ) + (1 / 10) * (43 / 10) = 1 / 4 := by norm_num
example : ((7 : ℚ) / 2) / (269 / 16) = 56 / 269 := by norm_num
example : ((56 : ℚ) / 269) < 1 / 4 := by norm_num

/-- WLS 变换恒等式：权 v² 下的加权平方 = 缩放 v 后的普通平方。 -/
theorem weighted_square (v y xb : ℚ) : v ^ 2 * (y - xb) ^ 2 = (v * (y - xb)) ^ 2 := by
  ring

/-- GLS 目标中的加权距离非负：平方和乘正权保持非负。 -/
theorem weighted_distance_nonneg (w y xb : ℚ) (hw : 0 ≤ w) :
    0 ≤ w * (y - xb) ^ 2 :=
  mul_nonneg hw (sq_nonneg _)

end Ch41
