/-
文件: 14_mathlib_combinatorics/big_operators.lean
描述: 求和 ∑ 与求积 ∏
编译: lake build Lean4Tutorial.Examples.MathlibCombinatorics.BigOperators
依赖: Mathlib.Algebra.BigOperators.Basic
-/

import Mathlib.Algebra.BigOperators.Basic
import Mathlib.Data.Finset.Basic

namespace Lean4Tutorial.Examples.MathlibCombinatorics.BigOperators

/-! # 大算子：求和 ∑ 与求积 ∏ -/

-- 在 Mathlib 中，∑ 表示有限和，∏ 表示有限积
-- 它们都是在有限集合上定义的
--
-- ∑ x ∈ s, f x 表示对 s 中的每个 x 计算 f x，然后求和
-- ∏ x ∈ s, f x 表示对 s 中的每个 x 计算 f x，然后求积

open Finset

/-! ## 求和 ∑ -/

-- 基本语法：∑ x ∈ s, f x
-- 其中 s 是 Finset，f 是函数

-- 简单求和
def sum_range_10 : ℕ := ∑ x ∈ range 10, x

#eval sum_range_10  -- 0 + 1 + 2 + ... + 9 = 45

-- 对集合中的元素求和
def sum_example : ℕ := ∑ x ∈ ({1, 2, 3, 4, 5} : Finset ℕ), x ^ 2

#eval sum_example  -- 1 + 4 + 9 + 16 + 25 = 55

-- 空集的和为 0
theorem sum_empty {α : Type*} [AddCommMonoid α] (f : ℕ → α) :
    ∑ x ∈ (∅ : Finset ℕ), f x = 0 := by
  exact sum_empty

-- 单元素集的和
theorem sum_singleton {α : Type*} [AddCommMonoid α] (f : ℕ → α) (x : ℕ) :
    ∑ i ∈ ({x} : Finset ℕ), f i = f x := by
  exact sum_singleton

-- 插入元素
theorem sum_insert {α : Type*} [AddCommMonoid α] (f : ℕ → α) (x : ℕ) (s : Finset ℕ)
    (h : x ∉ s) :
    ∑ i ∈ insert x s, f i = f x + ∑ i ∈ s, f i := by
  exact sum_insert h

/-! ## 求和的基本性质 -/

variable {M : Type*} [AddCommMonoid M]

-- 函数的加法
theorem sum_add (f g : ℕ → M) (s : Finset ℕ) :
    ∑ x ∈ s, (f x + g x) = (∑ x ∈ s, f x) + (∑ x ∈ s, g x) := by
  exact sum_add_distrib

-- 常数因子
theorem sum_const_mul (c : M) (f : ℕ → ℕ) (s : Finset ℕ) :
    ∑ x ∈ s, c = c * s.card := by
  simp [sum_const]

-- 常数函数的和
theorem sum_const (c : M) (s : Finset ℕ) :
    ∑ (_ : ℕ) ∈ s, c = s.card • c := by
  exact sum_const_nat

/-! ## 求积 ∏ -/

-- 基本语法：∏ x ∈ s, f x

-- 简单求积
def prod_range_5 : ℕ := ∏ x ∈ range 1 6, x  -- 1 * 2 * 3 * 4 * 5

#eval ∏ x ∈ Icc 1 5, x  -- 120 = 5!

-- 空集的积为 1
theorem prod_empty {α : Type*} [CommMonoid α] (f : ℕ → α) :
    ∏ x ∈ (∅ : Finset ℕ), f x = 1 := by
  exact prod_empty

-- 单元素集的积
theorem prod_singleton {α : Type*} [CommMonoid α] (f : ℕ → α) (x : ℕ) :
    ∏ i ∈ ({x} : Finset ℕ), f i = f x := by
  exact prod_singleton

/-! ## 求积的基本性质 -/

variable {N : Type*} [CommMonoid N]

-- 函数的乘法
theorem prod_mul (f g : ℕ → N) (s : Finset ℕ) :
    ∏ x ∈ s, (f x * g x) = (∏ x ∈ s, f x) * (∏ x ∈ s, g x) := by
  exact prod_mul_distrib

-- 常数函数的积
theorem prod_const (c : N) (s : Finset ℕ) :
    ∏ (_ : ℕ) ∈ s, c = c ^ s.card := by
  exact prod_const

/-! ## 常见求和公式 -/

-- 1. 自然数求和：∑_{i=0}^{n-1} i = n(n-1)/2
theorem sum_range_id (n : ℕ) : ∑ i ∈ range n, i = n * (n - 1) / 2 := by
  exact?

-- 验证
#eval ∑ i ∈ range 10, i  -- 45

-- 2. 平方和：∑_{i=0}^{n-1} i² = (n-1)n(2n-1)/6
-- 需要更多导入

-- 3. 等比数列求和：∑_{i=0}^{n-1} r^i = (r^n - 1) / (r - 1) （r ≠ 1）

/-! ## 阶乘 -/

-- n! = ∏_{i=1}^n i = n * (n-1) * ... * 1
def factorial (n : ℕ) : ℕ := ∏ i ∈ range 1 (n + 1), i

#eval factorial 0  -- 1
#eval factorial 1  -- 1
#eval factorial 5  -- 120

-- Mathlib 中已有 Nat.factorial
#eval Nat.factorial 5  -- 120

/-! ## 双重求和 -/

-- ∑ i ∈ s, ∑ j ∈ t, f i j
-- 可以交换求和顺序（富比尼定理的离散版本）

theorem sum_comm (f : ℕ → ℕ → ℕ) (s t : Finset ℕ) :
    ∑ i ∈ s, ∑ j ∈ t, f i j = ∑ j ∈ t, ∑ i ∈ s, f i j := by
  exact Finset.sum_comm

/-! ## 乘积集合上的和 -/

-- 对于两个有限集合的笛卡尔积 s × t，
-- ∑ p ∈ s × t, f p.1 p.2 = ∑ i ∈ s, ∑ j ∈ t, f i j

/-! ## 分部求和（阿贝尔变换） -/

-- 离散版本的分部积分
-- ∑_{k=0}^{n-1} a_k * (b_{k+1} - b_k) = a_n * b_n - a_0 * b_0 - ∑_{k=0}^{n-1} b_{k+1} * (a_{k+1} - a_k)

/-! ## 望远镜求和 -/

-- 如果 f(k+1) - f(k) = g(k)，则
-- ∑_{k=0}^{n-1} g(k) = f(n) - f(0)

-- 例子：∑_{k=0}^{n-1} ((k+1)² - k²) = n² - 0 = n²
theorem telescoping_sum (n : ℕ) :
    ∑ k ∈ range n, ((k + 1) ^ 2 - k ^ 2) = n ^ 2 := by
  induction n with
  | zero => simp
  | succ n ih =>
    rw [sum_range_succ, ih]
    <;> ring

/-! ## 集合划分下的和 -/

-- 如果 s 是不交集合族的并，则和等于各部分和之和
-- 这是加法的可加性

/-! ## 指标变换 -/

-- 如果 f 是从 s 到 t 的双射，则
-- ∑ x ∈ s, g (f x) = ∑ y ∈ t, g y

end Lean4Tutorial.Examples.MathlibCombinatorics.BigOperators
