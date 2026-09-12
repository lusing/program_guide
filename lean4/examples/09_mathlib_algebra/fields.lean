/-
文件: 09_mathlib_algebra/fields.lean
描述: 域 Field - 每个非零元都有乘法逆元，field_simp 战术
编译: lake build Lean4Tutorial.Examples.MathlibAlgebra.Fields
依赖: Mathlib.Algebra.Field.Basic
-/

import Mathlib.Algebra.Field.Basic

namespace Lean4Tutorial.Examples.MathlibAlgebra.Fields

/-! # 域（Field） -/

-- 域是交换环，且每个非零元素都有乘法逆元
-- class Field K extends CommRing K, Div K, Inv K where
--   add_comm : ∀ a b, a + b = b + a
--   mul_comm : ∀ a b, a * b = b * a
--   div_eq_mul_inv : ∀ a b, a / b = a * b⁻¹
--   inv_zero : 0⁻¹ = 0
--   mul_inv_cancel : ∀ {a}, a ≠ 0 → a * a⁻¹ = 1

/-! ## 域的基本性质 -/

-- 有理数域 ℚ
theorem rat_mul_inv_cancel (a : ℚ) (h : a ≠ 0) : a * a⁻¹ = 1 := by
  exact mul_inv_cancel h

theorem rat_inv_mul_cancel (a : ℚ) (h : a ≠ 0) : a⁻¹ * a = 1 := by
  exact inv_mul_cancel h

-- 实数域 ℝ
-- 需要导入更多模块才能使用实数

/-! ## 除法 -/

-- 在域中，除法 a / b 定义为 a * b⁻¹
theorem div_eq_mul_inv {K : Type*} [Field K] (a b : K) : a / b = a * b⁻¹ := by
  exact div_eq_mul_inv a b

-- 除数非零时的性质
theorem div_self {K : Type*} [Field K] (a : K) (h : a ≠ 0) : a / a = 1 := by
  exact div_self h

theorem one_div {K : Type*} [Field K] (a : K) : 1 / a = a⁻¹ := by
  exact one_div a

theorem div_one {K : Type*} [Field K] (a : K) : a / 1 = a := by
  exact div_one a

theorem zero_div {K : Type*} [Field K] (a : K) : 0 / a = 0 := by
  exact zero_div a

-- 注意：在 Mathlib 中，除以 0 被定义为 0
theorem div_zero {K : Type*} [Field K] (a : K) : a / 0 = 0 := by
  exact div_zero a

/-! ## 逆元的性质 -/

theorem inv_inv {K : Type*} [Field K] (a : K) : (a⁻¹)⁻¹ = a := by
  exact inv_inv a

theorem mul_inv {K : Type*} [Field K] (a b : K) : (a * b)⁻¹ = b⁻¹ * a⁻¹ := by
  exact mul_inv a b

theorem inv_mul {K : Type*} [Field K] (a b : K) : (a * b)⁻¹ = a⁻¹ * b⁻¹ := by
  rw [mul_inv, mul_comm]

theorem add_div {K : Type*} [Field K] (a b c : K) : (a + b) / c = a / c + b / c := by
  exact add_div a b c

theorem div_add_div_same {K : Type*} [Field K] (a b c : K) : a / c + b / c = (a + b) / c := by
  exact div_add_div_same a b c

/-! ## 分数运算 -/

section FractionExamples
  variable (a b c d : ℚ)

  -- 分数加法
  example (hc : c ≠ 0) (hd : d ≠ 0) :
      a / c + b / d = (a * d + b * c) / (c * d) := by
    field_simp [hc, hd] <;> ring

  -- 分数乘法
  example (hc : c ≠ 0) (hd : d ≠ 0) :
      (a / c) * (b / d) = (a * b) / (c * d) := by
    field_simp [hc, hd] <;> ring

  -- 分数除法
  example (hb : b ≠ 0) (hc : c ≠ 0) (hd : d ≠ 0) :
      (a / b) / (c / d) = (a * d) / (b * c) := by
    field_simp [hb, hc, hd] <;> ring

end FractionExamples

/-! ## field_simp 战术 -/

-- field_simp 战术用于化简域中的分式表达式
-- 它会将除法转化为乘法逆元，并进行化简

section FieldSimpExamples
  variable (a b c d : ℚ)

  -- 基本化简
  example (h : a ≠ 0) : a / a = 1 := by
    field_simp [h]

  example (h : a ≠ 0) : a * (b / a) = b := by
    field_simp [h] <;> ring

  -- 复杂分式化简
  example (ha : a ≠ 0) (hb : b ≠ 0) (hc : c ≠ 0) :
      (a / b) / (c / b) = a / c := by
    field_simp [ha, hb, hc] <;> ring

  example (ha : a ≠ 0) (hb : b ≠ 0) :
      1 / (a / b) = b / a := by
    field_simp [ha, hb] <;> ring

  -- 合并分数
  example (ha : a ≠ 0) (hb : b ≠ 0) :
      1 / a + 1 / b = (a + b) / (a * b) := by
    field_simp [ha, hb] <;> ring

  example (ha : a ≠ 0) (hb : b ≠ 0) :
      1 / a - 1 / b = (b - a) / (a * b) := by
    field_simp [ha, hb] <;> ring

  -- 更复杂的例子
  example (ha : a ≠ 0) (hb : b ≠ 0) (hc : c ≠ 0) (hd : d ≠ 0) :
      (a / b + c / d) / (a / b - c / d) = (a * d + b * c) / (a * d - b * c) := by
    field_simp [ha, hb, hc, hd] <;> ring

end FieldSimpExamples

/-! ## 域的特征 -/

-- 域的特征是使得 1 + 1 + ... + 1 (n个) = 0 的最小正整数 n
-- 如果不存在这样的 n，则特征为 0

-- 有理数域的特征为 0
-- 实数域的特征为 0
-- 有限域 GF(p) 的特征为 p（素数）

/-! ## 域同态 -/

-- 域同态是保持域运算的函数
-- 由于域中每个非零元都有逆元，域同态一定是单射

/-! # 常见的域 -/

-- 有理数域 ℚ
-- 实数域 ℝ
-- 复数域 ℂ
-- 有限域 GF(p)（p 是素数）

/-! ## 有序域 -/

-- 有序域是同时具有域结构和全序结构的域
-- 且序关系与运算相容：
--   a ≤ b → a + c ≤ b + c
--   0 ≤ a → 0 ≤ b → 0 ≤ a * b

-- 有理数和实数都是有序域

theorem rat_add_le_add_left (a b c : ℚ) (h : a ≤ b) : c + a ≤ c + b := by
  exact add_le_add_left h c

theorem rat_mul_nonneg (a b : ℚ) (ha : 0 ≤ a) (hb : 0 ≤ b) : 0 ≤ a * b := by
  exact mul_nonneg ha hb

end Lean4Tutorial.Examples.MathlibAlgebra.Fields
