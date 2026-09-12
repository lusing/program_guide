/-
文件: 16_advanced_tactics/norm_num_tactic.lean
描述: norm_num 战术：数值计算
编译: lake build Lean4Tutorial.Examples.AdvancedTactics.NormNumTactic
依赖: Mathlib.Tactic.NormNum
-/

import Mathlib.Tactic.NormNum
import Mathlib.Data.Real.Basic
import Mathlib.Data.Finset.Basic

namespace Lean4Tutorial.Examples.AdvancedTactics.NormNumTactic

/-! # norm_num 战术 -/

-- norm_num 战术用于化简具体的数值表达式
-- 它可以计算自然数、整数、有理数、实数等的具体数值
-- 也可以证明具体数值的等式和不等式

/-! ## 基本算术运算 -/

-- 自然数运算
example : 2 + 3 = 5 := by norm_num
example : 10 - 3 = 7 := by norm_num
example : 6 * 7 = 42 := by norm_num
example : 10 / 3 = 3 := by norm_num  -- 自然数除法
example : 10 % 3 = 1 := by norm_num
example : 2 ^ 10 = 1024 := by norm_num

-- 整数运算
example : (-5) + 8 = 3 := by norm_num
example : 5 - 10 = -5 := by norm_num
example : (-3) * 4 = -12 := by norm_num
example : (-7) * (-8) = 56 := by norm_num

-- 有理数运算
example : (1 / 2 : ℚ) + (1 / 3 : ℚ) = 5 / 6 := by norm_num
example : (2 / 3 : ℚ) * (3 / 4 : ℚ) = 1 / 2 := by norm_num
example : (3 / 4 : ℚ) - (1 / 2 : ℚ) = 1 / 4 := by norm_num

-- 实数运算
example : (2 : ℝ) + 3 = 5 := by norm_num
example : (2 : ℝ) ^ 10 = 1024 := by norm_num

/-! ## 比较运算 -/

example : 5 < 10 := by norm_num
example : 10 ≥ 3 := by norm_num
example : 100 ≠ 99 := by norm_num
example : 7 ≤ 7 := by norm_num

example : (-3 : ℤ) < 0 := by norm_num
example : (-5 : ℤ) > (-10 : ℤ) := by norm_num

example : (1 / 2 : ℚ) < (2 / 3 : ℚ) := by norm_num

/-! ## 阶乘 -/

example : Nat.factorial 0 = 1 := by norm_num
example : Nat.factorial 5 = 120 := by norm_num
example : Nat.factorial 10 = 3628800 := by norm_num

/-! ## 二项式系数 -/

example : Nat.choose 5 0 = 1 := by norm_num
example : Nat.choose 5 2 = 10 := by norm_num
example : Nat.choose 10 5 = 252 := by norm_num
example : Nat.choose 20 10 = 184756 := by norm_num

/-! ## 素数判定 -/

example : Nat.Prime 2 := by norm_num
example : Nat.Prime 3 := by norm_num
example : Nat.Prime 7 := by norm_num
example : Nat.Prime 97 := by norm_num
example : ¬ Nat.Prime 4 := by norm_num
example : ¬ Nat.Prime 15 := by norm_num
example : ¬ Nat.Prime 1 := by norm_num

/-! ## 整除关系 -/

example : 3 ∣ 12 := by norm_num
example : 7 ∣ 49 := by norm_num
example : ¬ (7 ∣ 50) := by norm_num
example : 5 ∣ 0 := by norm_num

-- GCD 和 LCM
example : Nat.gcd 48 18 = 6 := by norm_num
example : Nat.gcd 1071 462 = 21 := by norm_num
example : Nat.lcm 4 6 = 12 := by norm_num
example : Nat.lcm 12 18 = 36 := by norm_num

/-! ## 绝对值 -/

example : |(5 : ℤ)| = 5 := by norm_num
example : |(-5 : ℤ)| = 5 := by norm_num
example : |(0 : ℤ)| = 0 := by norm_num

example : |(3.14 : ℝ)| = 3.14 := by norm_num
example : |(-2.718 : ℝ)| = 2.718 := by norm_num

/-! ## 有限集合 -/

open Finset

example : ({1, 2, 3} : Finset ℕ).card = 3 := by norm_num
example : 2 ∈ ({1, 2, 3} : Finset ℕ) := by norm_num
example : 4 ∉ ({1, 2, 3} : Finset ℕ) := by norm_num

example : (range 10).card = 10 := by norm_num

/-! ## 求和与求积 -/

example : ∑ i ∈ range 10, i = 45 := by norm_num
example : ∑ i ∈ range 5, i ^ 2 = 30 := by norm_num

example : ∏ i ∈ range 1 6, i = 120 := by norm_num  -- 5!

/-! ## norm_num 与假设 -/

-- norm_num 可以化简假设
example (h : 2 + 2 = 5) : False := by
  norm_num at h
  -- h 变为 4 = 5，这是矛盾的
  <;> contradiction

example (h : 2 * 3 = 7) : 6 = 7 := by
  norm_num at h ⊢
  <;> exact h

/-! ## norm_num 与除法 -/

-- 注意自然数除法是截断除法
example : 7 / 2 = 3 := by norm_num  -- 不是 3.5

-- 整数除法
example : (7 : ℤ) / 2 = 3 := by norm_num
example : (-7 : ℤ) / 2 = -4 := by norm_num  -- 向下取整

-- 有理数除法是精确的
example : (7 : ℚ) / 2 = 7 / 2 := by norm_num

/-! ## #eval 与 norm_num 的区别 -/

-- #eval 是在 VM 中计算，用于快速查看结果
-- norm_num 是证明战术，生成正式的证明

-- #eval 2 + 3  -- 输出 5
-- example : 2 + 3 = 5 := by norm_num  -- 生成证明

/-! ## norm_num 的高级用法 -/

-- norm_num 可以处理相当大的数
example : 2 ^ 20 = 1048576 := by norm_num
example : 2 ^ 30 = 1073741824 := by norm_num

-- 阶乘也可以算很大
example : Nat.factorial 20 = 2432902008176640000 := by norm_num

end Lean4Tutorial.Examples.AdvancedTactics.NormNumTactic
