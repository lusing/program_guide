import Mathlib.Analysis.Calculus.Deriv.Pow
import Mathlib.MeasureTheory.Measure.Lebesgue.Basic
import Mathlib.Tactic

/-!
# 第 08 章 随机变量、分布函数与密度（Lean）

离散质量、连续密度和混合型分布在 CDF 处会合。本文件固定归一、
区间概率、密度反导数和混合跳点的精确锚点。
-/

open MeasureTheory Set

/-! ## 离散 pmf 与 CDF -/

example : (1 : ℚ) / 8 + 3 / 8 + 3 / 8 + 1 / 8 = 1 := by norm_num
example : (1 : ℚ) / 8 + 3 / 8 + 3 / 8 = 7 / 8 := by norm_num
example : (4 : ℚ) / 8 ≤ 7 / 8 := by norm_num
example : Nat.choose 4 2 = 6 := by decide
example : ((1 : ℚ) + 4 + 6) / 16 = 11 / 16 := by norm_num
example : ((1 : ℚ) + 5 + 10) / 32 = 1 / 2 := by norm_num

/-- 两骰和的三角形 pmf 归一。 -/
example : 1 + 2 + 3 + 4 + 5 + 6 + 5 + 4 + 3 + 2 + 1 = 36 := by decide
example : ((2 : ℚ) + 3 + 4) / 36 = 1 / 4 := by norm_num

/-! ## 均匀分布与密度 2x -/

#check @Real.volume_Icc
#check @hasDerivAt_pow

example : volume (Icc (0 : ℝ) 1) = 1 := by simp [Real.volume_Icc]

example : volume (Icc (1 / 4 : ℝ) (3 / 4)) = ENNReal.ofReal (1 / 2) := by
  rw [Real.volume_Icc]
  congr 1
  norm_num

/-- CDF `F(x)=x²` 的导数正是密度 `2x`。 -/
example (x : ℝ) : HasDerivAt (fun y => y ^ 2) (2 * x) x := by
  simpa using hasDerivAt_pow 2 x

example : (3 / 4 : ℝ) ^ 2 - (1 / 4) ^ 2 = 1 / 2 := by norm_num
example : (1 / 4 : ℝ) ^ 2 = 1 / 16 := by norm_num

/-! ## 多项式密度与混合型 -/

example : (6 / 11 : ℝ) * (2 + 3 / 2 - 5 / 3) = 1 := by norm_num
example : (6 / 11 : ℝ) * (1 + 3 / 8 - 5 / 24) = 7 / 11 := by norm_num

/-- 混合型在 0 的右极限含原子 1/2；从 0 到 1/2 的左开右闭区间
只取得连续部分的 1/4。 -/
example : (1 : ℚ) / 2 + (1 / 2) / 2 = 3 / 4 := by norm_num
example : (3 : ℚ) / 4 - 1 / 2 = 1 / 4 := by norm_num
