/-
文件: 11_mathlib_analysis/real_numbers.lean
描述: 实数，域性质，序
编译: lake build Lean4Tutorial.Examples.MathlibAnalysis.RealNumbers
依赖: Mathlib.Data.Real.Basic
-/

import Mathlib.Data.Real.Basic

namespace Lean4Tutorial.Examples.MathlibAnalysis.RealNumbers

/-! # 实数（Real Numbers） -/

-- 实数集 ℝ 是一个完备的有序域
-- 在 Mathlib 中，实数类型为 ℝ（Real）

/-! ## 实数的域性质 -/

-- 实数构成一个域
-- 即有加法、乘法，满足交换律、结合律、分配律，
-- 每个非零元有乘法逆元

variable (a b c : ℝ)

-- 加法交换律
theorem real_add_comm : a + b = b + a := by
  exact add_comm a b

-- 加法结合律
theorem real_add_assoc : (a + b) + c = a + (b + c) := by
  exact add_assoc a b c

-- 加法单位元
theorem real_zero_add : 0 + a = a := by
  exact zero_add a

theorem real_add_zero : a + 0 = a := by
  exact add_zero a

-- 加法逆元
theorem real_add_left_neg : -a + a = 0 := by
  exact add_left_neg a

theorem real_add_right_neg : a + (-a) = 0 := by
  exact add_right_neg a

-- 乘法交换律
theorem real_mul_comm : a * b = b * a := by
  exact mul_comm a b

-- 乘法结合律
theorem real_mul_assoc : (a * b) * c = a * (b * c) := by
  exact mul_assoc a b c

-- 乘法单位元
theorem real_one_mul : 1 * a = a := by
  exact one_mul a

theorem real_mul_one : a * 1 = a := by
  exact mul_one a

-- 乘法逆元
theorem real_mul_inv_cancel (h : a ≠ 0) : a * a⁻¹ = 1 := by
  exact mul_inv_cancel h

-- 分配律
theorem real_left_distrib : a * (b + c) = a * b + a * c := by
  exact left_distrib a b c

theorem real_right_distrib : (a + b) * c = a * c + b * c := by
  exact right_distrib a b c

/-! ## 实数的序性质 -/

-- 实数是全序的：任意两个实数都可以比较大小

-- 序的性质
theorem real_le_refl : a ≤ a := by
  exact le_refl a

theorem real_le_trans (h1 : a ≤ b) (h2 : b ≤ c) : a ≤ c := by
  exact le_trans h1 h2

theorem real_le_antisymm (h1 : a ≤ b) (h2 : b ≤ a) : a = b := by
  exact le_antisymm h1 h2

theorem real_le_total : a ≤ b ∨ b ≤ a := by
  exact le_total a b

-- 严格序的性质
theorem real_lt_irrefl : ¬ (a < a) := by
  exact lt_irrefl a

theorem real_lt_trans (h1 : a < b) (h2 : b < c) : a < c := by
  exact lt_trans h1 h2

-- 序与运算的相容性
theorem real_add_le_add_left (h : a ≤ b) : c + a ≤ c + b := by
  exact add_le_add_left h c

theorem real_mul_nonneg (ha : 0 ≤ a) (hb : 0 ≤ b) : 0 ≤ a * b := by
  exact mul_nonneg ha hb

theorem real_mul_pos (ha : 0 < a) (hb : 0 < b) : 0 < a * b := by
  exact mul_pos ha hb

/-! ## 一些重要的实数 -/

-- 0 和 1
#check (0 : ℝ)
#check (1 : ℝ)

-- 整数和有理数都可以嵌入实数
#check (↑2 : ℝ)      -- 自然数嵌入
#check (↑(-3 : ℤ) : ℝ)  -- 整数嵌入
#check (↑(1 / 2 : ℚ) : ℝ)  -- 有理数嵌入

-- π 和 e
-- 需要导入额外的模块
-- #check Real.pi
-- #check Real.exp 1

/-! ## 实数的稠密性 -/

-- 任意两个不相等的实数之间存在另一个实数
-- 实际上存在无穷多个实数，包括有理数和无理数

theorem real_dense (a b : ℝ) (h : a < b) : ∃ x : ℝ, a < x ∧ x < b := by
  use (a + b) / 2
  constructor
  · linarith
  · linarith

-- 任意两个实数之间存在有理数
theorem exists_rat_between (a b : ℝ) (h : a < b) : ∃ (q : ℚ), a < (q : ℝ) ∧ (q : ℝ) < b := by
  exact exists_rat_btwn h

/-! ## 实数的完备性（上确界性质） -/

-- 实数的一个重要性质是完备性：
-- 任何非空有上界的实数集合都有最小上界（上确界）

-- 这是实数区别于有理数的关键性质
-- 例如：{x ∈ ℚ | x² < 2} 在有理数中没有上确界，但在实数中有（√2）

-- Mathlib 中实数的上确界
#check sSup

-- 上确界的性质：
-- 1. 上确界是上界
-- 2. 任何比上确界小的数都不是上界

/-! ## 实数的阿基米德性质 -/

-- 对于任意实数 x，存在自然数 n 使得 n > x
theorem archimedean (x : ℝ) : ∃ n : ℕ, x < (n : ℝ) := by
  exact exists_nat_gt x

-- 推论：对于任意 ε > 0，存在自然数 n 使得 1/n < ε
theorem archimedean_reciprocal (ε : ℝ) (h : 0 < ε) : ∃ n : ℕ, 1 / (n : ℝ) < ε := by
  have h1 : ∃ n : ℕ, 1 / ε < (n : ℝ) := exists_nat_gt (1 / ε)
  rcases h1 with ⟨n, hn⟩
  refine' ⟨n + 1, _⟩
  have h2 : (n : ℝ) < ((n + 1 : ℕ) : ℝ) := by simp
  have h3 : 1 / ε < ((n + 1 : ℕ) : ℝ) := by linarith
  have h4 : 0 < ((n + 1 : ℕ) : ℝ) := by positivity
  have h5 : 0 < ε := h
  calc
    1 / ((n + 1 : ℕ) : ℝ) < 1 / (1 / ε) := by
      apply one_div_lt_one_div_of_lt
      · positivity
      · exact h3
    _ = ε := by
      field_simp [h.ne'] <;> ring

/-! ## 绝对值 -/

-- 实数的绝对值（将在下一节详细讨论）
#check abs a

-- 绝对值的基本性质
theorem abs_nonneg : 0 ≤ |a| := by
  exact abs_nonneg a

theorem abs_eq_self_of_nonneg (h : 0 ≤ a) : |a| = a := by
  rw [abs_of_nonneg h]

theorem abs_eq_neg_of_nonpos (h : a ≤ 0) : |a| = -a := by
  rw [abs_of_nonpos h]

/-! ## 平方非负 -/

theorem square_nonneg : 0 ≤ a ^ 2 := by
  exact sq_nonneg a

theorem square_pos (h : a ≠ 0) : 0 < a ^ 2 := by
  exact sq_pos_of_ne_zero h

-- 均值不等式：a² + b² ≥ 2ab
theorem two_ab_le_sq_add_sq : 2 * a * b ≤ a ^ 2 + b ^ 2 := by
  nlinarith [sq_nonneg (a - b)]

-- AM ≥ GM（两数情况）
theorem am_gm_two (ha : 0 ≤ a) (hb : 0 ≤ b) : a * b ≤ ((a + b) / 2) ^ 2 := by
  nlinarith [sq_nonneg (a - b)]

end Lean4Tutorial.Examples.MathlibAnalysis.RealNumbers
