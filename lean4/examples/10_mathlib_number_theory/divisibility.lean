/-
文件: 10_mathlib_number_theory/divisibility.lean
描述: 整除关系及基本性质
编译: lake build Lean4Tutorial.Examples.MathlibNumberTheory.Divisibility
依赖: Mathlib.NumberTheory.Divisibility.Basic
-/

import Mathlib.NumberTheory.Divisibility.Basic

namespace Lean4Tutorial.Examples.MathlibNumberTheory.Divisibility

/-! # 整除关系 -/

-- a ∣ b 表示 "a 整除 b"，即存在整数 k 使得 b = a * k
-- 在 Mathlib 中，整除关系定义在自然数 ℕ 和整数 ℤ 上

/-! ## 整除的定义 -/

-- a ∣ b 当且仅当存在 c 使得 b = a * c
#check (dvd_def : ∀ {a b : ℕ}, a ∣ b ↔ ∃ c : ℕ, b = a * c)

-- 简单的整除例子
example : 2 ∣ 6 := by
  use 3  -- 存在 3 使得 6 = 2 * 3
  <;> norm_num

example : 3 ∣ 12 := by
  use 4
  <;> norm_num

example : 5 ∣ 0 := by
  use 0
  <;> norm_num

-- 0 只能整除 0
example : (0 : ℕ) ∣ 0 := by
  simp

-- 1 整除任何数
example : ∀ n : ℕ, 1 ∣ n := by
  intro n
  use n
  <;> simp

-- 任何数整除自身
example : ∀ n : ℕ, n ∣ n := by
  intro n
  use 1
  <;> simp

/-! ## 整除的基本性质 -/

-- 自反性
theorem dvd_refl (n : ℕ) : n ∣ n := by
  exact dvd_refl n

-- 传递性
theorem dvd_trans (a b c : ℕ) (h1 : a ∣ b) (h2 : b ∣ c) : a ∣ c := by
  exact dvd_trans h1 h2

-- 反对称性（在自然数上）
theorem dvd_antisymm (a b : ℕ) (h1 : a ∣ b) (h2 : b ∣ a) : a = b := by
  exact dvd_antisymm h1 h2

-- 整除与乘法
theorem dvd_mul_right (a b : ℕ) : a ∣ a * b := by
  exact dvd_mul_right a b

theorem dvd_mul_left (a b : ℕ) : a ∣ b * a := by
  exact dvd_mul_left a b

/-! ## 整除与加法/减法 -/

-- 如果 a ∣ b 且 a ∣ c，则 a ∣ b + c
theorem dvd_add (a b c : ℕ) (h1 : a ∣ b) (h2 : a ∣ c) : a ∣ b + c := by
  exact dvd_add h1 h2

-- 如果 a ∣ b 且 a ∣ c，则 a ∣ b - c（当 b ≥ c 时）
theorem dvd_sub (a b c : ℕ) (h1 : a ∣ b) (h2 : a ∣ c) (h3 : c ≤ b) : a ∣ b - c := by
  exact dvd_sub h1 h2 h3

-- 如果 a ∣ b 且 a ∣ c，则 a ∣ m * b + n * c
theorem dvd_linear_combination (a b c m n : ℕ) (h1 : a ∣ b) (h2 : a ∣ c) :
    a ∣ m * b + n * c := by
  exact dvd_add (dvd_mul_of_dvd_right h1 m) (dvd_mul_of_dvd_right h2 n)

/-! ## 整数上的整除 -/

-- 整数上的整除关系类似
example : (3 : ℤ) ∣ 12 := by
  use 4
  <;> norm_num

example : (-2 : ℤ) ∣ 6 := by
  use (-3)
  <;> norm_num

example : (2 : ℤ) ∣ -6 := by
  use (-3)
  <;> norm_num

-- 整数上整除的性质
theorem int_dvd_add (a b c : ℤ) (h1 : a ∣ b) (h2 : a ∣ c) : a ∣ b + c := by
  exact dvd_add h1 h2

theorem int_dvd_neg (a b : ℤ) (h : a ∣ b) : a ∣ -b := by
  exact dvd_neg.mpr h

theorem int_dvd_sub (a b c : ℤ) (h1 : a ∣ b) (h2 : a ∣ c) : a ∣ b - c := by
  exact dvd_sub h1 h2

/-! ## 整除与比较 -/

-- 如果 a ∣ b 且 b > 0，则 a ≤ b
theorem dvd_le_of_pos (a b : ℕ) (h : a ∣ b) (hb : 0 < b) : a ≤ b := by
  exact Nat.le_of_dvd hb h

-- 如果 a ∣ b 且 a > b，则 b = 0
theorem eq_zero_of_dvd_of_lt (a b : ℕ) (h1 : a ∣ b) (h2 : a > b) : b = 0 := by
  exact Nat.eq_zero_of_dvd_of_lt h1 h2

/-! ## 素数与整除 -/

-- 素数 p 的性质：如果 p ∣ a * b，则 p ∣ a 或 p ∣ b
-- （这是欧几里得引理，在 primes.lean 中详细讨论）

/-! ## 整除的判定 -/

-- 使用 norm_num 可以判定具体数字的整除关系
example : 7 ∣ 42 := by norm_num
example : 7 ∣ 49 := by norm_num
example : ¬ (7 ∣ 43) := by norm_num

-- 使用 decide
#eval 6 ∣ 42  -- true
#eval 7 ∣ 43  -- false

/-! ## 倍数集合 -/

-- a 的所有倍数构成的集合是 {n | a ∣ n}
-- 这是整数加法群的子群

/-! # 最大公约数的前置知识 -/

-- 整除关系是定义最大公约数（GCD）的基础
-- gcd(a, b) 是同时整除 a 和 b 的最大正整数

-- 下一节将详细讨论 GCD

end Lean4Tutorial.Examples.MathlibNumberTheory.Divisibility
