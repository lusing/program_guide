import Mathlib.Tactic

/-!
# 第 11 章 概率不等式与矩的界限（Lean）

精确核对 Markov 紧度、Chebyshev 换算、Jensen 间隙、Boole 截断与
弱大数定律入口的数值锚点；一般定理证明见正文。
-/

/-- Markov 的非负性不可省：`X=±1` 的均值为零而尾概率非零。 -/
example : (1 : ℚ) * (1 / 2) + (-1) * (1 / 2) = 0 := by norm_num

/-- 两点分布在阈值处达到 Markov 等号：`mu=2,a=4,p=1/2`。 -/
example : (2 : ℚ) / 4 * 4 = 2 := by norm_num

/-- 均匀分布的正确 Chebyshev 界为 `100/243`。 -/
example : (1 : ℚ) / ((45 / 100) ^ 2 / (1 / 12)) = 100 / 243 := by norm_num

/-- 把方差当标准差所得假界低于真值，立即暴露错误。 -/
example : (1 : ℚ) / ((45 / 100) / (1 / 12)) ^ 2 = 25 / 729 := by norm_num
example : (25 : ℚ) / 729 < 5 / 100 := by norm_num

/-- Jensen 的二次间隙就是方差：`E[X²]-E[X]²=2-1=1`。 -/
example : (2 : ℚ) - 1 ^ 2 = 1 := by norm_num

/-- 四骰至少一个六的 Bonferroni 夹逼。 -/
example : (4 : ℚ) / 6 - 6 / 36 < 1 - (5 / 6) ^ 4 := by norm_num
example : 1 - (5 / 6 : ℚ) ^ 4 < 4 / 6 := by norm_num

/-- 样本均值方差与 Chebyshev 界的 `1/n` 衰减。 -/
example : (3 : ℚ) / 12 = 1 / 4 := by norm_num
example : (1 : ℚ) / (10 ^ 5 * (1 / 10) ^ 2) = 1 / 1000 := by norm_num
example (v n : ℚ) : v / (4 * n) = (v / n) / 4 := by ring
