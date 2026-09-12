/-
文件: 09_mathlib_algebra/monoids.lean
描述: 幺半群 Monoid - 带单位元的半群
编译: lake build Lean4Tutorial.Examples.MathlibAlgebra.Monoids
依赖: Mathlib.Algebra.Group.Basic
-/

import Mathlib.Algebra.Group.Basic

namespace Lean4Tutorial.Examples.MathlibAlgebra.Monoids

/-! # 幺半群（Monoid） -/

-- 幺半群是半群加上单位元
-- 乘法幺半群 Monoid：有 * 运算和单位元 1
-- 加法幺半群 AddMonoid：有 + 运算和单位元 0

/-! ## 乘法幺半群 Monoid -/

-- Monoid G 表示类型 G 是乘法幺半群
-- class Monoid G extends MulSemigroup G, One G where
--   one_mul : ∀ a : G, 1 * a = a
--   mul_one : ∀ a : G, a * 1 = a

-- 自然数乘法幺半群（单位元是 1）
theorem nat_one_mul (a : ℕ) : 1 * a = a := by
  exact one_mul a

theorem nat_mul_one (a : ℕ) : a * 1 = a := by
  exact mul_one a

-- 整数乘法幺半群
theorem int_one_mul (a : ℤ) : 1 * a = a := by
  exact one_mul a

theorem int_mul_one (a : ℤ) : a * 1 = a := by
  exact mul_one a

/-! ## 加法幺半群 AddMonoid -/

-- AddMonoid G 表示类型 G 是加法幺半群
-- class AddMonoid G extends AddSemigroup G, Zero G where
--   zero_add : ∀ a : G, 0 + a = a
--   add_zero : ∀ a : G, a + 0 = a

-- 自然数加法幺半群（单位元是 0）
theorem nat_zero_add (a : ℕ) : 0 + a = a := by
  exact zero_add a

theorem nat_add_zero (a : ℕ) : a + 0 = a := by
  exact add_zero a

-- 整数加法幺半群
theorem int_zero_add (a : ℤ) : 0 + a = a := by
  exact zero_add a

theorem int_add_zero (a : ℤ) : a + 0 = a := by
  exact add_zero a

/-! ## 交换幺半群 -/

-- CommMonoid：交换乘法幺半群（交换律 + 幺半群）
-- AddCommMonoid：交换加法幺半群

-- 自然数加法是交换幺半群
theorem nat_add_comm_monoid (a b : ℕ) : a + b = b + a := by
  exact add_comm a b

-- 自然数乘法是交换幺半群
theorem nat_mul_comm_monoid (a b : ℕ) : a * b = b * a := by
  exact mul_comm a b

/-! ## 幺半群的性质 -/

-- 单位元唯一
theorem unique_id {M : Type*} [Monoid M] (e : M) (h : ∀ x : M, e * x = x) : e = 1 := by
  have h1 : e * 1 = 1 := h 1
  have h2 : e * 1 = e := mul_one e
  rw [h2] at h1
  exact h1.symm

-- 利用单位元和结合律的计算
theorem monoid_calc (a b : ℕ) : a * 1 * b = a * b := by
  calc
    a * 1 * b = a * b := by rw [mul_one a]

/-! ## 幂运算 -/

-- 在幺半群中，可以定义幂运算
-- a ^ n 表示 a 自乘 n 次

#check (pow_zero : ∀ {M : Type*} [Monoid M] (a : M), a ^ 0 = 1)
#check (pow_succ : ∀ {M : Type*} [Monoid M] (a : M) (n : ℕ), a ^ (n + 1) = a * a ^ n)

-- 自然数幂运算
theorem pow_two (a : ℕ) : a ^ 2 = a * a := by
  simp [pow_two]

theorem pow_add (a : ℕ) (m n : ℕ) : a ^ (m + n) = a ^ m * a ^ n := by
  exact pow_add a m n

theorem pow_mul (a : ℕ) (m n : ℕ) : a ^ (m * n) = (a ^ m) ^ n := by
  exact pow_mul a m n

/-! ## 倍数运算（加法版本的幂） -/

-- 在加法幺半群中，n • a 表示 a 相加 n 次
-- 这是乘法幺半群中幂运算的加法版本

#check (zero_nsmul : ∀ {M : Type*} [AddMonoid M] (a : M), 0 • a = 0)
#check (succ_nsmul : ∀ {M : Type*} [AddMonoid M] (n : ℕ) (a : M), (n + 1) • a = a + n • a)

-- 自然数倍数
theorem nsmul_two (a : ℕ) : 2 • a = a + a := by
  simp [two_nsmul]

theorem add_nsmul (a : ℕ) (m n : ℕ) : (m + n) • a = m • a + n • a := by
  exact add_nsmul m n a

/-! # 常用幺半群实例 -/

-- 列表是幺半群（以 ++ 为运算，[] 为单位元）
#check (@List.nil_append : ∀ {α : Type} (l : List α), [] ++ l = l)
#check (@List.append_nil : ∀ {α : Type} (l : List α), l ++ [] = l)

-- 字符串是幺半群（以 ++ 为运算，"" 为单位元）
theorem string_empty_append (s : String) : "" ++ s = s := by simp
theorem string_append_empty (s : String) : s ++ "" = s := by simp

-- 选项类型 Option M 可以构成幺半群
-- none 是单位元

/-! ## 子幺半群 -/

-- 子幺半群是幺半群的子集，包含单位元且对运算封闭
-- Mathlib 中有 Submonoid 类型

-- 自然数的偶数乘法子幺半群示例
-- （注意：偶数乘法不封闭，这里只是演示类型的存在）
#check Submonoid ℕ

end Lean4Tutorial.Examples.MathlibAlgebra.Monoids
