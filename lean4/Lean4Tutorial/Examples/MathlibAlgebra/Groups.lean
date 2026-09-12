/-
文件: 09_mathlib_algebra/groups.lean
描述: 群 Group - 带逆元的幺半群，abel 战术
编译: lake build Lean4Tutorial.Examples.MathlibAlgebra.Groups
依赖: Mathlib.Algebra.Group.Basic
-/

import Mathlib.Algebra.Group.Basic

namespace Lean4Tutorial.Examples.MathlibAlgebra.Groups

/-! # 群（Group） -/

-- 群是幺半群加上逆元运算
-- 乘法群 Group：有 * 运算、单位元 1、逆元 a⁻¹
-- 加法群 AddGroup：有 + 运算、单位元 0、负元 -a

/-! ## 加法群 AddGroup -/

-- AddGroup G 表示类型 G 是加法群
-- class AddGroup G extends AddMonoid G, Neg G where
--   add_left_neg : ∀ a : G, -a + a = 0

-- 整数加法群
theorem int_add_left_neg (a : ℤ) : -a + a = 0 := by
  exact add_left_neg a

theorem int_add_right_neg (a : ℤ) : a + (-a) = 0 := by
  exact add_right_neg a

-- 有理数加法群
theorem rat_add_left_neg (a : ℚ) : -a + a = 0 := by
  exact add_left_neg a

/-! ## 乘法群 Group -/

-- Group G 表示类型 G 是乘法群
-- class Group G extends Monoid G, Inv G where
--   mul_left_inv : ∀ a : G, a⁻¹ * a = 1

-- 非零有理数乘法群
-- 注意：全体有理数不构成乘法群（因为 0 没有逆元）
-- 但非零有理数构成乘法群

/-! ## 交换群（Abel 群） -/

-- 交换群：运算满足交换律的群
-- AddCommGroup：加法交换群
-- CommGroup：乘法交换群

-- 整数加法是交换群
theorem int_add_comm (a b : ℤ) : a + b = b + a := by
  exact add_comm a b

/-! ## 群的基本性质 -/

-- 消去律
theorem add_left_cancel {G : Type*} [AddGroup G] (a b c : G) :
    a + b = a + c → b = c := by
  intro h
  have h1 : -a + (a + b) = -a + (a + c) := by rw [h]
  have h2 : (-a + a) + b = (-a + a) + c := by
    rw [←add_assoc, ←add_assoc] <;> exact h1
  have h3 : 0 + b = 0 + c := by
    rw [add_left_neg] at h2 <;> exact h2
  simpa using h3

theorem add_right_cancel {G : Type*} [AddGroup G] (a b c : G) :
    a + c = b + c → a = b := by
  intro h
  have h1 : (a + c) + (-c) = (b + c) + (-c) := by rw [h]
  have h2 : a + (c + (-c)) = b + (c + (-c)) := by
    rw [add_assoc, add_assoc] <;> exact h1
  have h3 : a + 0 = b + 0 := by
    rw [add_right_neg] at h2 <;> exact h2
  simpa using h3

/-! ## 逆元的性质 -/

-- 逆元的逆元是自身
theorem neg_neg {G : Type*} [AddGroup G] (a : G) : -(-a) = a := by
  exact neg_neg a

-- 逆元的唯一性
theorem neg_unique {G : Type*} [AddGroup G] (a b : G) (h : a + b = 0) : b = -a := by
  have h1 : a + b = 0 := h
  have h2 : -a + (a + b) = -a + 0 := by rw [h1]
  have h3 : (-a + a) + b = -a := by
    rw [add_assoc] at h2
    simpa using h2
  have h4 : 0 + b = -a := by
    rw [add_left_neg] at h3 <;> exact h3
  simpa using h4

-- 和的逆元等于逆元的逆序和
theorem neg_add {G : Type*} [AddCommGroup G] (a b : G) : -(a + b) = -a + -b := by
  exact neg_add a b

/-! ## abel 战术 -/

-- abel 战术可以自动证明交换群中的等式
-- 它使用结合律、交换律、单位元和逆元的性质

section AbelExamples
  variable (a b c d : ℤ)

  -- 简单的交换群等式
  example : a + b = b + a := by abel
  example : (a + b) + c = a + (b + c) := by abel
  example : a + 0 = a := by abel
  example : a + (-a) = 0 := by abel

  -- 更复杂的等式
  example : (a + b) + (c + d) = (a + c) + (b + d) := by abel
  example : a + b + c + d = d + c + b + a := by abel
  example : -(a + b) + (a + b) = 0 := by abel

  -- 包含减法的等式
  example : a - b = a + (-b) := by abel
  example : (a + b) - (a + c) = b - c := by abel
  example : a - b - c = a - (b + c) := by abel

end AbelExamples

/-! ## 群同态 -/

-- 群同态是保持群运算的函数
-- f : G → H 是群同态，如果 f(a + b) = f(a) + f(b)

-- 整数加倍是群同态
theorem int_double_hom (a b : ℤ) : 2 * (a + b) = 2 * a + 2 * b := by
  ring

-- Nat.cast : ℕ → ℤ 是加法群同态（从加法幺半群到加法群）
theorem nat_cast_add_hom (a b : ℕ) : (↑(a + b) : ℤ) = (↑a : ℤ) + (↑b : ℤ) := by
  exact?

/-! ## 子群 -/

-- 子群是群的子集，包含单位元、对运算封闭、对逆元封闭
-- Mathlib 中有 AddSubgroup 和 Subgroup 类型

#check AddSubgroup ℤ
#check Subgroup (ℤ × ℤ)

-- 整数的偶数子群是加法子群
-- 2ℤ = {..., -4, -2, 0, 2, 4, ...}

/-! ## 商群 -/

-- 商群是群模掉正规子群得到的群
-- Mathlib 中有商群的构造

/-! # 群的更多性质 -/

-- 方程的解
theorem equation_solution {G : Type*} [AddGroup G] (a b : G) :
    ∃! x : G, a + x = b := by
  use -a + b
  constructor
  · -- 存在性
    abel
  · -- 唯一性
    intro y hy
    have h : a + y = b := hy
    have h' : y = -a + b := by
      calc
        y = 0 + y := by rw [zero_add]
        _ = (-a + a) + y := by rw [add_left_neg]
        _ = -a + (a + y) := by rw [add_assoc]
        _ = -a + b := by rw [h]
    exact h'

end Lean4Tutorial.Examples.MathlibAlgebra.Groups
