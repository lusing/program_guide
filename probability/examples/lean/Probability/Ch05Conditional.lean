import Mathlib.Probability.ConditionalProbability
import Mathlib.Tactic

/-!
# 第 05 章 条件概率、独立与 Bayes（Lean）

Miller ch4 的机器侧：mathlib 的 `MeasureTheory.cond`（条件
测度）与 `cond_apply`（条件概率的定义式）、`cond_mul_eq_inter`
（乘法链）。实弹：医学检验 Bayes 账的 ℚ 精确收割——正文
05.2 的 1.9% 在 norm_num 下零误差。
-/

open MeasureTheory

/-! ## 锚点正名 -/

#check @ProbabilityTheory.cond                     -- 条件测度 μ[·|s]
#check @ProbabilityTheory.cond_apply               -- 定义式：μ[t|s] = (μ s)⁻¹ * μ (s ∩ t)
#check @ProbabilityTheory.cond_mul_eq_inter        -- 乘法链：μ s * μ[t|s] = μ (s ∩ t)
#check @ProbabilityTheory.cond_eq_inv_mul_cond_mul -- Bayes：μ[t|s] = (μ s)⁻¹ * μ[s|t] * μ t

/-! ## 实弹：医学检验的 Bayes 账 -/

/-- **医学检验账（ℚ 上精确）**：病率 1/1000、灵敏度 95%、
假阳率 5%——阳性后真病的概率 = 真阳 / 总阳 =
(95/100 · 1/1000) / (95/100 · 1/1000 + 5/100 · 999/1000)
= 19/1018。 -/
example : ((95 : ℚ) / 100000) / ((95 : ℚ) / 100000 + 4995 / 100000) = 19 / 1018 := by
  norm_num

/-- 阳性中真病的百分比 ≈ 1.87%（基率忽视的解毒剂）。 -/
example : (19 : ℚ) / 1018 < 1 / 50 := by norm_num

/-! ## 实弹：Monty Hall 的账（条件结构的三情况） -/

/-- 三情况的条件账：车在 i 门（先验 1/3）；主持人开 3 门
的条件概率 P(H|C₁) = 1/2（随便开）、P(H|C₂) = 1（必须开
3）、P(H|C₃) = 0。Bayes 后验：
P(C₂|H) = (1·1/3)/(1/2·1/3 + 1·1/3 + 0) = 2/3。 -/
example : ((1 : ℚ) / 3) / (1 / 6 + 1 / 3) = 2 / 3 := by norm_num

/-- 100 门版的直觉账：首选命中 1/100，换门命中 99/100。 -/
example : ((1 : ℚ) / 100) + 99 / 100 = 1 := by norm_num
