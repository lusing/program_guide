/-
文件: 14_mathlib_combinatorics/binomial.lean
描述: 二项式系数，二项式定理
编译: lake build Lean4Tutorial.Examples.MathlibCombinatorics.Binomial
依赖: Mathlib.Algebra.BigOperators.Binomial
-/

import Mathlib.Algebra.BigOperators.Binomial
import Mathlib.Data.Nat.Choose.Basic

namespace Lean4Tutorial.Examples.MathlibCombinatorics.Binomial

/-! # 二项式系数（Binomial Coefficients） -/

-- 二项式系数 C(n, k) = n! / (k! * (n-k)!)
-- 表示从 n 个元素中选取 k 个的方式数
--
-- 在 Mathlib 中，Nat.choose n k 表示 C(n, k)

/-! ## 二项式系数的定义 -/

-- Nat.choose n k = n! / (k! * (n - k)!)
-- 当 k > n 时，C(n, k) = 0

#check Nat.choose

-- 计算例子
#eval Nat.choose 5 0   -- 1
#eval Nat.choose 5 1   -- 5
#eval Nat.choose 5 2   -- 10
#eval Nat.choose 5 3   -- 10
#eval Nat.choose 5 4   -- 5
#eval Nat.choose 5 5   -- 1

#eval Nat.choose 10 5  -- 252

/-! ## 二项式系数的基本性质 -/

-- C(n, 0) = 1
theorem choose_zero_right (n : ℕ) : Nat.choose n 0 = 1 := by
  exact Nat.choose_zero_right n

-- C(n, n) = 1
theorem choose_self (n : ℕ) : Nat.choose n n = 1 := by
  exact Nat.choose_self n

-- C(n, 1) = n
theorem choose_one_right (n : ℕ) : Nat.choose n 1 = n := by
  exact?

-- 对称性：C(n, k) = C(n, n-k)
theorem choose_symm (n k : ℕ) : Nat.choose n k = Nat.choose n (n - k) := by
  exact Nat.choose_symm

-- 当 k > n 时，C(n, k) = 0
theorem choose_eq_zero_of_lt (n k : ℕ) (h : n < k) : Nat.choose n k = 0 := by
  exact Nat.choose_eq_zero_of_lt h

/-! ## 帕斯卡恒等式 -/

-- 帕斯卡恒等式：C(n, k) = C(n-1, k-1) + C(n-1, k)
-- 这是帕斯卡三角形的基础

theorem choose_succ_succ (n k : ℕ) :
    Nat.choose (n + 1) (k + 1) = Nat.choose n k + Nat.choose n (k + 1) := by
  exact Nat.choose_succ_succ n k

-- 帕斯卡三角形的前几行：
-- n=0:       1
-- n=1:      1 1
-- n=2:     1 2 1
-- n=3:    1 3 3 1
-- n=4:   1 4 6 4 1
-- n=5:  1 5 10 10 5 1

/-! ## 组合解释 -/

-- C(n, k) 表示：
--   1. 从 n 个元素中选 k 个的组合数
--   2. n 元集合的 k 元子集的个数
--   3. 帕斯卡三角形第 n 行第 k 列的数
--   4. (a + b)^n 展开式中 a^k * b^(n-k) 的系数

-- 子集计数
-- n 元集合的所有子集数是 2^n
-- 即 ∑_{k=0}^n C(n, k) = 2^n

theorem sum_choose (n : ℕ) : ∑ k ∈ Finset.range (n + 1), Nat.choose n k = 2 ^ n := by
  exact?

/-! ## 二项式定理 -/

-- 二项式定理：
-- (x + y)^n = ∑_{k=0}^n C(n, k) * x^k * y^(n-k)

-- 在 Mathlib 中，二项式定理表述为：
theorem add_pow {R : Type*} [CommSemiring R] (x y : R) (n : ℕ) :
    (x + y) ^ n = ∑ k ∈ Finset.range (n + 1), Nat.choose n k * x ^ k * y ^ (n - k) := by
  exact add_pow x y n

-- 验证几个特例
example (x y : ℕ) : (x + y) ^ 2 = x ^ 2 + 2 * x * y + y ^ 2 := by
  rw [add_pow]
  <;> simp [Finset.sum_range_succ, Nat.choose]
  <;> ring

example (x y : ℕ) : (x + y) ^ 3 = x ^ 3 + 3 * x ^ 2 * y + 3 * x * y ^ 2 + y ^ 3 := by
  rw [add_pow]
  <;> simp [Finset.sum_range_succ, Nat.choose]
  <;> ring

/-! ## 二项式定理的推论 -/

-- 令 x = 1, y = 1：
-- 2^n = ∑_{k=0}^n C(n, k)
-- 这就是上面的子集计数公式

-- 令 x = 1, y = -1（在环中）：
-- 0 = ∑_{k=0}^n (-1)^k * C(n, k)
-- 即：偶位置的二项式系数之和 = 奇位置的二项式系数之和 = 2^(n-1)

/-! ## 范德蒙德恒等式 -/

-- 范德蒙德恒等式：
-- C(m + n, k) = ∑_{i=0}^k C(m, i) * C(n, k-i)

-- 组合解释：
-- 从 m + n 个元素中选 k 个，
-- 等价于从前 m 个中选 i 个，从后 n 个中选 k-i 个，对所有 i 求和

/-! ## 一些有用的恒等式 -/

-- 1. k * C(n, k) = n * C(n-1, k-1)
theorem mul_choose (n k : ℕ) :
    k * Nat.choose n k = n * Nat.choose (n - 1) (k - 1) := by
  exact?

-- 2. ∑_{k=0}^n k * C(n, k) = n * 2^(n-1)

-- 3. ∑_{k=0}^n k^2 * C(n, k) = n(n+1) * 2^(n-2)

-- 4. 朱世杰恒等式（ hockey-stick identity）：
--    ∑_{i=r}^n C(i, r) = C(n+1, r+1)

/-! ## 多项式定理 -/

-- 二项式定理的推广：
-- (x₁ + x₂ + ... + x_m)^n = ∑_{k₁+...+k_m=n} (n / (k₁!k₂!...k_m!)) * x₁^k₁ * ... * x_m^k_m

/-! ## 卡特兰数 -/

-- 第 n 个卡特兰数：C_n = C(2n, n) / (n + 1)
-- C_0 = 1, C_1 = 1, C_2 = 2, C_3 = 5, C_4 = 14, C_5 = 42, ...

-- 卡特兰数出现在很多组合问题中：
--   1. 正确匹配的括号序列数
--   2. 满二叉树的个数
--   3. 凸多边形的三角划分数
--   4. 不穿过对角线的格路数

end Lean4Tutorial.Examples.MathlibCombinatorics.Binomial
