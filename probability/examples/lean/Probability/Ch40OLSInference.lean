import Mathlib.Tactic

/-!
# 第 40 章：正态误差下 t 检验与 F 检验的代数锚
-/

namespace Ch40

-- 五点例的 t² 与单约束 F（同一分数的两种写法）。
example : ((4 : ℚ) / 5) ^ 2 / ((6 / 5) * (1 / 10)) = 16 / 3 := by norm_num
example : ((7 : ℚ) / 5) ^ 2 / ((6 / 5) * (3 / 5)) = 49 / 18 := by norm_num
example : ((4 : ℚ) / 5) ^ 2 / (1 / 10) / (6 / 5) = 16 / 3 := by norm_num

-- 残差自由度：n - k = 3。
example : ((5 : ℚ) - 2) = 3 := by norm_num

-- TSS = 10、ESS = 32/5、RSS = 18/5。
example : (10 : ℚ) - 18 / 5 = 32 / 5 := by norm_num

-- 联合显著性 F（仅斜率）的两种公式一致；k=2 时即单约束 F = t₂² = 16/3。
example : ((32 : ℚ) / 5 / 1) / ((18 / 5) / 3) = 16 / 3 := by norm_num
example : (((32 : ℚ) / 5 / 10) / 1) / ((1 - 32 / 5 / 10) / 3) = 16 / 3 := by
  norm_num

-- H0: β₁ = β₂ = 0（含截距）的 F：RSS_R = y'y = 55。
example : (((55 : ℚ) - 18 / 5) / 2) / ((18 / 5) / 3) = 257 / 12 := by norm_num

/-- 单约束 F 恒等于 t²：二次型除以 s² 与比值平方是同一个数。 -/
theorem f_equals_t_squared (b se : ℚ) (hse : se ≠ 0) :
    (b / se) ^ 2 = b ^ 2 / se ^ 2 := by
  field_simp

/-- F 统计量的分子（约束离距）非负：平方除以正数不小于零。 -/
theorem constraint_distance_nonneg (b r c : ℚ) (hc : 0 < c) :
    0 ≤ (b - r) ^ 2 / c :=
  div_nonneg (sq_nonneg _) (le_of_lt hc)

end Ch40
