import Mathlib.Tactic

/-!
# 第 14 章 正态、对数正态、柯西与稳定分布（Lean）

本章机器侧：正态密度对称性的 ring 原文（均值 μ 的
结构根源）、偶矩 decide 链、和稳定性的常数账（N(0,2) 在
0 处 = φ(0)/√2 的平方等式）、标准化换元的参数账、极坐标
技巧的常数残迹 √(2π)。
-/

/-! ## 对称性：均值 μ 的结构根源 -/

/-- 密度只依赖 (x−μ)²，而平方对称：f(μ+a) = f(μ−a) 的
指数账（ring 判决）。 -/
example (μ a : ℚ) : (μ + a - μ) ^ 2 = (μ - a - μ) ^ 2 := by ring

/-- 平移不变：x − μ 与 −(x − μ) 同平方。 -/
example (μ x : ℚ) : (x - μ) ^ 2 = (μ - x) ^ 2 := by ring

/-! ## 偶矩 decide 链 -/

/-- M(2) = 1、M(4) = 3·1、M(6) = 5·3（(2m−1)!! 链）。 -/
example : (3 : ℚ) = 3 * 1 ∧ (15 : ℚ) = 5 * 3 := by norm_num

/-- 递推原文：M(2k+2) = (2k+1)·M(2k)（σ³d/dσ 的账面）。 -/
example : (105 : ℚ) = 7 * 15 := by norm_num

example : (945 : ℚ) = 9 * 105 := by norm_num

/-! ## 和稳定性：常数账 -/

/-- **Case 1 的核心**：N(0,2) 在 0 处的密度 = 1/(2√π)；
φ(0)/√2 = (2π)^{−1/2}/√2。以平方等式入账（√π 记 π 的
平方根）：√(4π) = 2√π（方差 2 的归一化常数），配方引擎的
常数残迹。 -/
example : ((2 : ℝ)) ^ 2 * Real.pi = 4 * Real.pi := by ring

/-- 卷积后指数 −z²/4 = −z²/(2·2)（方差 2 的读法：分母
2σ² = 2·2 = 4）。 -/
example : ((4 : ℚ)) = 2 * (1 + 1) := by ring

/-- **一般和**：μ = μ_X + μ_Y、σ² = σ_X² + σ_Y² 的数值例
（(1,4)+(3,9) → (4,13)）。 -/
example : ((1 : ℚ) + 3 = 4 ∧ 4 + 9 = 13) := by norm_num

/-- 标准化换元 aX+b 的参数账：μ_Y = aμ_X + b、
σ_Y² = a²σ_X²（a = 3、b = 2 的例）。 -/
example : ((3 : ℚ)) * 5 + 2 = 17 := by norm_num

example : ((3 : ℚ)) ^ 2 * 2 = 18 := by norm_num

/-! ## 极坐标技巧的常数残迹 -/

/-- ∫e^{−x²/2}dx = √(2π) 与 ∫₀^∞e^{−x²}dx = √π/2 的关系：
√(2π) = √2·√π（√π 的主权账：(√π)² = π）。 -/
example : (Real.sqrt (Real.pi)) ^ 2 = Real.pi := by
  exact Real.sq_sqrt (by positivity)

/-- I² = 1 的前提：归一化常数非零（positivity 供账）。 -/
example : (Real.sqrt (2 * Real.pi) : ℝ) ≠ 0 := by positivity

/-- rdr 的救星：e^{−r²/2}r 的原函数 −e^{−r²/2} 在 0 与 ∞
的端点账（∞ 端 e^{−R²/2} → 0 的速度）。 -/
example : (Real.exp (-(0 : ℝ))) = 1 := by simp

example (R : ℝ) : Real.exp (-(R * R / 2)) * Real.exp (R * R / 2) = 1 := by
  rw [← Real.exp_add, neg_add_cancel, Real.exp_zero]
