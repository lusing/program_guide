/-
文件: 10_mathlib_number_theory/gcd.lean
描述: 最大公约数 GCD，贝祖定理
编译: lake build Lean4Tutorial.Examples.MathlibNumberTheory.Gcd
依赖: Mathlib.Algebra.GCDMonoid.Basic
-/

import Mathlib.Algebra.GCDMonoid.Basic
import Mathlib.Data.Nat.GCD.Basic

namespace Lean4Tutorial.Examples.MathlibNumberTheory.Gcd

/-! # 最大公约数（GCD） -/

-- gcd(a, b) 是同时整除 a 和 b 的最大自然数
-- 在 Mathlib 中，Nat.gcd a b 表示 a 和 b 的最大公约数

/-! ## GCD 的定义与基本性质 -/

-- gcd 是对称的
theorem gcd_comm (a b : ℕ) : Nat.gcd a b = Nat.gcd b a := by
  exact Nat.gcd_comm a b

-- gcd(a, 0) = a
theorem gcd_zero_right (a : ℕ) : Nat.gcd a 0 = a := by
  exact Nat.gcd_zero_right a

-- gcd(0, a) = a
theorem gcd_zero_left (a : ℕ) : Nat.gcd 0 a = a := by
  exact Nat.gcd_zero_left a

-- gcd(a, a) = a
theorem gcd_self (a : ℕ) : Nat.gcd a a = a := by
  exact Nat.gcd_self a

-- gcd(1, a) = 1
theorem gcd_one_left (a : ℕ) : Nat.gcd 1 a = 1 := by
  exact Nat.gcd_one_left a

/-! ## GCD 的整除性质 -/

-- gcd(a, b) ∣ a
theorem gcd_dvd_left (a b : ℕ) : Nat.gcd a b ∣ a := by
  exact Nat.gcd_dvd_left a b

-- gcd(a, b) ∣ b
theorem gcd_dvd_right (a b : ℕ) : Nat.gcd a b ∣ b := by
  exact Nat.gcd_dvd_right a b

-- gcd(a, b) 是 a 和 b 的最大公约数
-- 如果 d ∣ a 且 d ∣ b，则 d ∣ gcd(a, b)
theorem dvd_gcd (d a b : ℕ) (h1 : d ∣ a) (h2 : d ∣ b) : d ∣ Nat.gcd a b := by
  exact Nat.dvd_gcd h1 h2

/-! ## 欧几里得算法 -/

-- 欧几里得算法：gcd(a, b) = gcd(b, a mod b)
theorem gcd_rec (a b : ℕ) : Nat.gcd a b = Nat.gcd b (a % b) := by
  exact?

-- 计算 GCD 的例子
#eval Nat.gcd 48 18  -- 6
#eval Nat.gcd 1071 462  -- 21
#eval Nat.gcd 100 25  -- 25
#eval Nat.gcd 7 13  -- 1（互素）

/-! ## 互素（Coprime） -/

-- 两个数互素是指它们的最大公约数为 1
-- Nat.Coprime a b 即 Nat.gcd a b = 1

-- 互素的例子
example : Nat.Coprime 7 13 := by
  norm_num [Nat.Coprime]

example : Nat.Coprime 15 28 := by
  norm_num [Nat.Coprime]

-- 相邻自然数互素
theorem coprime_succ_self (n : ℕ) : Nat.Coprime (n + 1) n := by
  exact Nat.Coprime.succ_self n

-- 1 与任何数互素
theorem coprime_one_left (n : ℕ) : Nat.Coprime 1 n := by
  exact Nat.coprime_one_left n

/-! ## 互素的性质 -/

-- 如果 a ∣ b * c 且 gcd(a, b) = 1，则 a ∣ c
-- 这是欧几里得引理
theorem euclid_lemma (a b c : ℕ) (h : Nat.Coprime a b) (h2 : a ∣ b * c) : a ∣ c := by
  exact Nat.Coprime.dvd_of_dvd_mul_left h h2

-- 如果 gcd(a, b) = 1 且 gcd(a, c) = 1，则 gcd(a, b * c) = 1
theorem coprime_mul (a b c : ℕ) (h1 : Nat.Coprime a b) (h2 : Nat.Coprime a c) :
    Nat.Coprime a (b * c) := by
  exact Nat.Coprime.mul_right h1 h2

/-! ## 贝祖定理（Bézout's Identity） -/

-- 贝祖定理：对于任意自然数 a 和 b，存在整数 x 和 y 使得
--   a * x + b * y = gcd(a, b)

-- Mathlib 中有贝祖定理的形式化表述
#check Nat.gcd_eq_gcd_ab

-- gcd_a a b 和 gcd_b a b 给出贝祖系数
-- 即：a * gcd_a a b + b * gcd_b a b = gcd(a, b)

theorem bezout_identity (a b : ℕ) :
    (a : ℤ) * Nat.gcdA a b + (b : ℤ) * Nat.gcdB a b = (Nat.gcd a b : ℤ) := by
  exact Nat.gcd_eq_gcd_ab a b

-- 贝祖定理的例子
#eval Nat.gcdA 48 18  -- 贝祖系数 x
#eval Nat.gcdB 48 18  -- 贝祖系数 y
-- 验证：48 * (-1) + 18 * 3 = -48 + 54 = 6 = gcd(48, 18)

-- 互素的贝祖定理
-- 如果 gcd(a, b) = 1，则存在整数 x, y 使得 a * x + b * y = 1
theorem bezout_coprime (a b : ℕ) (h : Nat.Coprime a b) :
    ∃ (x y : ℤ), (a : ℤ) * x + (b : ℤ) * y = 1 := by
  refine' ⟨Nat.gcdA a b, Nat.gcdB a b, _⟩
  rw [Nat.gcd_eq_gcd_ab a b]
  rw [Nat.coprime_iff_gcd_eq_one] at h
  rw [h]
  <;> norm_num

/-! ## 扩展欧几里得算法 -/

-- 扩展欧几里得算法不仅计算 gcd，还计算贝祖系数
-- Nat.gcdA a b 和 Nat.gcdB a b 就是扩展欧几里得算法的结果

/-! ## GCD 的更多性质 -/

-- gcd(k * a, k * b) = k * gcd(a, b)
theorem gcd_mul_left (k a b : ℕ) : Nat.gcd (k * a) (k * b) = k * Nat.gcd a b := by
  exact Nat.gcd_mul_left k a b

-- gcd(a + b, b) = gcd(a, b)
theorem gcd_add_self_right (a b : ℕ) : Nat.gcd (a + b) b = Nat.gcd a b := by
  exact Nat.gcd_add_self_right a b

-- gcd(a - b, b) = gcd(a, b)（当 b ≤ a 时）
theorem gcd_sub_self_right (a b : ℕ) (h : b ≤ a) :
    Nat.gcd (a - b) b = Nat.gcd a b := by
  exact?

/-! ## 最小公倍数（LCM） -/

-- lcm(a, b) 是 a 和 b 的最小公倍数
-- 关系：gcd(a, b) * lcm(a, b) = a * b

theorem gcd_mul_lcm (a b : ℕ) : Nat.gcd a b * Nat.lcm a b = a * b := by
  exact Nat.gcd_mul_lcm a b

-- 计算 LCM
#eval Nat.lcm 4 6   -- 12
#eval Nat.lcm 12 18  -- 36

-- lcm 的性质
theorem dvd_lcm_left (a b : ℕ) : a ∣ Nat.lcm a b := by
  exact Nat.dvd_lcm_left a b

theorem dvd_lcm_right (a b : ℕ) : b ∣ Nat.lcm a b := by
  exact Nat.dvd_lcm_right a b

theorem lcm_dvd (a b m : ℕ) (h1 : a ∣ m) (h2 : b ∣ m) : Nat.lcm a b ∣ m := by
  exact Nat.lcm_dvd h1 h2

/-! ## 整数上的 GCD -/

-- 整数上也有 GCD，取绝对值的 GCD
theorem int_gcd (a b : ℤ) : Int.gcd a b = Nat.gcd (Int.natAbs a) (Int.natAbs b) := by
  rfl

end Lean4Tutorial.Examples.MathlibNumberTheory.Gcd
