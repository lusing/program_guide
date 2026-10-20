import Mathlib.Data.Nat.Choose.Sum
import Mathlib.Tactic

/-!
# 第 06 章 容斥原理（Lean）

Miller ch5 的机器侧：mathlib 无本科形态的三事件容斥打包
（Combinatorics/Enumerative/InclusionExclusion 是计数生成
函数侧的）——本章以**手作三事件 + 错排闭式**承载：
① 三事件恒等式在骰子空间的精确判决；② 错排数
Dₙ = n!·Σ(−1)ᵏ/k! 的 decide 验证与递推 Dₙ = n·Dₙ₋₁ + (−1)ⁿ
的数值对拍（正文 06.3 的账）。
-/

/-! ## 锚点（计数侧的可用件） -/

#check @Nat.sum_range_choose   -- Σ C(n,k) = 2ⁿ（交错和的亲戚）

/-! ## 三事件容斥的数值实弹 -/

/-- 骰子空间的精确账：A = 首骰 6、B = 次骰 6、C = 两骰同点——
P(A∪B∪C) 的 36 分母账：|A|=|B|=6、|C|=6、|A∩B|=1、
|A∩C|=|B∩C|=1、|A∩B∩C|=1：
6/36 + 6/36 + 6/36 − 1/36 − 1/36 − 1/36 + 1/36 = 16/36。 -/
example : (6 + 6 + 6 - 1 - 1 - 1 + 1 : ℚ) / 36 = 16 / 36 := by norm_num

/-! ## 错排：闭式与递推的对拍 -/

/-- 错排闭式（整数版）：Dₙ = Σₖ (−1)ᵏ·n!/k!——每项整除、
总和为正整数。 -/
def derZ (n : ℕ) : ℤ := ∑ k ∈ Finset.range (n + 1),
  (-1 : ℤ) ^ k * ((Nat.factorial n : ℤ) / Nat.factorial k)

/-- **D₄ = 9 的 decide 判决**：4 封信的错排数（闭式的
机器原文）。 -/
example : derZ 4 = 9 := by native_decide

/-- D₅ = 44、D₆ = 265、D₇ = 1854 的连判（错排序列：
9 → 44 → 265 → 1854）。 -/
example : derZ 5 = 44 ∧ derZ 6 = 265 ∧ derZ 7 = 1854 := by native_decide

/-- **递推对拍**：Dₙ = n·Dₙ₋₁ + (−1)ⁿ（闭式与递推两条路
在同一序列会师）。 -/
example : derZ 4 = 4 * derZ 3 + 1 := by native_decide
example : derZ 5 = 5 * derZ 4 - 1 := by native_decide
example : derZ 8 = 8 * derZ 7 + 1 := by native_decide
