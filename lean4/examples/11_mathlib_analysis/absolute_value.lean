/-
文件: 11_mathlib_analysis/absolute_value.lean
描述: 绝对值与三角不等式
编译: lake build Lean4Tutorial.Examples.MathlibAnalysis.AbsoluteValue
依赖: Mathlib.Data.Real.Basic
-/

import Mathlib.Data.Real.Basic

namespace Lean4Tutorial.Examples.MathlibAnalysis.AbsoluteValue

/-! # 绝对值（Absolute Value） -/

-- 实数的绝对值定义为：
--   |x| = x,  如果 x ≥ 0
--   |x| = -x, 如果 x < 0
--
-- 在 Mathlib 中，绝对值函数为 abs

/-! ## 绝对值的定义与基本性质 -/

variable (a b c : ℝ)

-- 非负性
theorem abs_nonneg : 0 ≤ |a| := by
  exact abs_nonneg a

-- |a| = 0 当且仅当 a = 0
theorem abs_eq_zero : |a| = 0 ↔ a = 0 := by
  exact abs_eq_zero

-- 正性：如果 a ≠ 0，则 |a| > 0
theorem abs_pos (h : a ≠ 0) : 0 < |a| := by
  exact abs_pos.mpr h

-- 绝对值的对称性
theorem abs_neg : |(-a)| = |a| := by
  exact abs_neg a

-- |a| ≥ a 且 |a| ≥ -a
theorem le_abs_self : a ≤ |a| := by
  exact le_abs_self a

theorem neg_le_abs_self : -a ≤ |a| := by
  exact neg_le_abs_self a

/-! ## 绝对值与乘法 -/

-- |a * b| = |a| * |b|
theorem abs_mul : |a * b| = |a| * |b| := by
  exact abs_mul a b

-- |a / b| = |a| / |b| （b ≠ 0）
theorem abs_div (h : b ≠ 0) : |a / b| = |a| / |b| := by
  exact abs_div a b

-- |a⁻¹| = |a|⁻¹ （a ≠ 0）
theorem abs_inv (h : a ≠ 0) : |a⁻¹| = |a|⁻¹ := by
  exact abs_inv a

-- |a^n| = |a|^n
theorem abs_pow (n : ℕ) : |a ^ n| = |a| ^ n := by
  exact abs_pow a n

/-! ## 三角不等式 -/

-- 三角不等式：|a + b| ≤ |a| + |b|
theorem triangle_ineq : |a + b| ≤ |a| + |b| := by
  exact abs_add a b

-- 三角不等式的另一种形式：|a - b| ≤ |a| + |b|
theorem triangle_ineq_sub : |a - b| ≤ |a| + |b| := by
  simpa [sub_eq_add_neg] using abs_add a (-b)

-- 反向三角不等式：| |a| - |b| | ≤ |a - b|
theorem reverse_triangle_ineq : ||a| - |b|| ≤ |a - b| := by
  exact abs_abs_sub_abs_le_abs_sub a b

-- 另一种形式：|a| - |b| ≤ |a - b|
theorem abs_sub_abs_le : |a| - |b| ≤ |a - b| := by
  linarith [abs_abs_sub_abs_le_abs_sub a b]

/-! ## 三角不等式的推广 -/

-- 三个数的三角不等式
theorem triangle_ineq_three : |a + b + c| ≤ |a| + |b| + |c| := by
  calc
    |a + b + c| = |(a + b) + c| := by ring_nf
    _ ≤ |a + b| + |c| := by exact abs_add (a + b) c
    _ ≤ (|a| + |b|) + |c| := by
      gcongr
      exact abs_add a b
    _ = |a| + |b| + |c| := by ring

-- n 个数的三角不等式（有限和）
-- 可以用归纳法证明

/-! ## 绝对值与序 -/

-- |a| ≤ b 当且仅当 -b ≤ a ≤ b
theorem abs_le : |a| ≤ b ↔ -b ≤ a ∧ a ≤ b := by
  exact abs_le

-- |a| < b 当且仅当 -b < a < b
theorem abs_lt : |a| < b ↔ -b < a ∧ a < b := by
  exact abs_lt

-- a ≤ |a| 和 -a ≤ |a| 已经在上面给出

-- 使用 abs_le 进行证明
example (h : |a - b| < ε) : b - ε < a ∧ a < b + ε := by
  have h1 : |a - b| < ε := h
  rw [abs_lt] at h1
  constructor
  · linarith
  · linarith

example (h1 : b - ε < a) (h2 : a < b + ε) : |a - b| < ε := by
  rw [abs_lt]
  constructor
  · linarith
  · linarith

/-! ## 绝对值的 max / min 表示 -/

-- |a| = max(a, -a)
theorem abs_eq_max : |a| = max a (-a) := by
  exact?

-- |a - b| 可以理解为 a 和 b 在数轴上的距离

/-! ## 距离的性质 -/

-- 定义 d(a, b) = |a - b|，这是实数轴上的欧氏距离

def dist (x y : ℝ) : ℝ := |x - y|

-- 距离的性质
theorem dist_nonneg : 0 ≤ dist a b := by
  simp [dist, abs_nonneg]

theorem dist_eq_zero : dist a b = 0 ↔ a = b := by
  simp [dist, abs_eq_zero]

theorem dist_comm : dist a b = dist b a := by
  simp [dist, sub_eq_neg_add] <;> rw [abs_neg]

-- 三角不等式（距离形式）
theorem dist_triangle : dist a c ≤ dist a b + dist b c := by
  simp [dist]
  have h : |a - c| = |(a - b) + (b - c)| := by ring_nf
  rw [h]
  exact abs_add (a - b) (b - c)

/-! ## 用 linarith 证明绝对值不等式 -/

-- linarith 战术可以处理线性不等式，包括绝对值
section LinarithExamples
  variable (x y ε : ℝ)

  example (h : |x - 1| < ε / 2) (h' : |y - 2| < ε / 2) (hε : 0 < ε) :
      |(x + y) - 3| < ε := by
    have h1 : |(x + y) - 3| = |(x - 1) + (y - 2)| := by ring_nf
    rw [h1]
    calc
      |(x - 1) + (y - 2)| ≤ |x - 1| + |y - 2| := abs_add (x - 1) (y - 2)
      _ < ε / 2 + ε / 2 := by linarith
      _ = ε := by linarith

  example (h : |x - a| < ε) : a - ε < x := by
    have h1 : |x - a| < ε := h
    rw [abs_lt] at h1
    linarith

end LinarithExamples

end Lean4Tutorial.Examples.MathlibAnalysis.AbsoluteValue
