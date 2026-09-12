/-
文件: 09_mathlib_algebra/rings.lean
描述: 环 Ring - 加法群与乘法幺半群的结合，ring 战术
编译: lake build Lean4Tutorial.Examples.MathlibAlgebra.Rings
依赖: Mathlib.Algebra.Ring.Basic
-/

import Mathlib.Algebra.Ring.Basic

namespace Lean4Tutorial.Examples.MathlibAlgebra.Rings

/-! # 环（Ring） -/

-- 环是同时具有加法和乘法两种运算的代数结构
-- 加法构成交换群，乘法构成幺半群，乘法对加法满足分配律
--
-- class Ring R extends AddCommGroup R, Monoid R, Distrib R where
--   ...
--
-- Distrib 包含分配律：
--   left_distrib : a * (b + c) = a * b + a * c
--   right_distrib : (a + b) * c = a * c + b * c

/-! ## 环的基本性质 -/

-- 整数环 ℤ
theorem int_left_distrib (a b c : ℤ) : a * (b + c) = a * b + a * c := by
  exact left_distrib a b c

theorem int_right_distrib (a b c : ℤ) : (a + b) * c = a * c + b * c := by
  exact right_distrib a b c

-- 零乘任何数等于零
theorem zero_mul {R : Type*} [Ring R] (a : R) : 0 * a = 0 := by
  exact zero_mul a

theorem mul_zero {R : Type*} [Ring R] (a : R) : a * 0 = 0 := by
  exact mul_zero a

-- 负数乘法
theorem neg_mul {R : Type*} [Ring R] (a b : R) : (-a) * b = -(a * b) := by
  exact neg_mul a b

theorem mul_neg {R : Type*} [Ring R] (a b : R) : a * (-b) = -(a * b) := by
  exact mul_neg a b

theorem neg_mul_neg {R : Type*} [Ring R] (a b : R) : (-a) * (-b) = a * b := by
  exact neg_mul_neg a b

/-! ## 交换环 CommRing -/

-- 交换环：乘法满足交换律的环
-- class CommRing R extends Ring R, MulCommMonoid R

-- 整数是交换环
theorem int_mul_comm (a b : ℤ) : a * b = b * a := by
  exact mul_comm a b

-- 有理数是交换环
theorem rat_mul_comm (a b : ℚ) : a * b = b * a := by
  exact mul_comm a b

/-! ## ring 战术 -/

-- ring 战术可以自动证明环中的等式
-- 它使用结合律、交换律、分配律等环的公理

section RingTacticExamples
  variable (a b c d : ℤ)

  -- 基本的环等式
  example : (a + b) * c = a * c + b * c := by ring
  example : a * (b + c) = a * b + a * c := by ring

  -- 平方公式
  example : (a + b) ^ 2 = a ^ 2 + 2 * a * b + b ^ 2 := by ring
  example : (a - b) ^ 2 = a ^ 2 - 2 * a * b + b ^ 2 := by ring

  -- 平方差
  example : (a + b) * (a - b) = a ^ 2 - b ^ 2 := by ring

  -- 立方公式
  example : (a + b) ^ 3 = a ^ 3 + 3 * a ^ 2 * b + 3 * a * b ^ 2 + b ^ 3 := by ring

  -- 更复杂的展开
  example : (a + b) * (c + d) = a * c + a * d + b * c + b * d := by ring
  example : (a - b) * (c + d) = a * c + a * d - b * c - b * d := by ring

  -- 因式分解验证
  example : a ^ 3 - b ^ 3 = (a - b) * (a ^ 2 + a * b + b ^ 2) := by ring
  example : a ^ 3 + b ^ 3 = (a + b) * (a ^ 2 - a * b + b ^ 2) := by ring

  -- 多个变量的复杂等式
  example : (a + b + c) ^ 2 = a ^ 2 + b ^ 2 + c ^ 2 + 2 * a * b + 2 * a * c + 2 * b * c := by ring

end RingTacticExamples

/-! ## 半环 Semiring -/

-- 半环比环弱：加法只是交换幺半群（没有逆元）
-- 自然数 ℕ 是半环但不是环

-- 自然数是半环
theorem nat_left_distrib (a b c : ℕ) : a * (b + c) = a * b + a * c := by
  exact left_distrib a b c

theorem nat_right_distrib (a b c : ℕ) : (a + b) * c = a * c + b * c := by
  exact right_distrib a b c

-- nat 上也可以用 ring 战术
section NatRingExamples
  variable (a b c : ℕ)

  example : (a + b) ^ 2 = a ^ 2 + 2 * a * b + b ^ 2 := by
    ring

  example : (a + b) * (a + c) = a ^ 2 + a * b + a * c + b * c := by
    ring

end NatRingExamples

/-! ## 环同态 -/

-- 环同态是同时保持加法和乘法的函数
-- f : R → S 是环同态，如果：
--   f(a + b) = f(a) + f(b)
--   f(a * b) = f(a) * f(b)
--   f(1) = 1

-- 整数到有理数的嵌入是环同态
theorem int_cast_rat_add (a b : ℤ) : (↑(a + b) : ℚ) = (↑a : ℚ) + (↑b : ℚ) := by
  exact?

theorem int_cast_rat_mul (a b : ℤ) : (↑(a * b) : ℚ) = (↑a : ℚ) * (↑b : ℚ) := by
  exact?

theorem int_cast_rat_one : (↑(1 : ℤ) : ℚ) = 1 := by
  norm_num

/-! ## 子环 -/

-- 子环是环的子集，包含 0 和 1，对加法、乘法、取负封闭
-- Mathlib 中有 Subring 类型

#check Subring ℤ

/-! ## 理想 -/

-- 理想是环的特殊子结构，对加法封闭，且对环中任意元素的乘法封闭
-- 理想在环论中的地位类似于正规子群在群论中的地位

/-! # 更多环的例子 -/

-- 多项式环
-- 矩阵环
-- 函数环

-- 整数模 n 环 ℤ/nℤ
-- Mathlib 中有 ZMod n

end Lean4Tutorial.Examples.MathlibAlgebra.Rings
