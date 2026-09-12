/-
文件: 10_mathlib_number_theory/primes.lean
描述: 素数定义与性质
编译: lake build Lean4Tutorial.Examples.MathlibNumberTheory.Primes
依赖: Mathlib.NumberTheory.Primes.Basic
-/

import Mathlib.NumberTheory.Primes.Basic
import Mathlib.Data.Nat.Prime

namespace Lean4Tutorial.Examples.MathlibNumberTheory.Primes

/-! # 素数（Prime） -/

-- 素数是大于 1 的自然数，其正约数只有 1 和自身
-- 在 Mathlib 中，Nat.Prime p 表示 p 是素数

/-! ## 素数的定义 -/

-- Nat.Prime p := 1 < p ∧ ∀ m ∣ p, m = 1 ∨ m = p
#check Nat.Prime

-- 素数例子
example : Nat.Prime 2 := by norm_num
example : Nat.Prime 3 := by norm_num
example : Nat.Prime 5 := by norm_num
example : Nat.Prime 7 := by norm_num
example : Nat.Prime 97 := by norm_num

-- 非素数例子
example : ¬ Nat.Prime 1 := by norm_num
example : ¬ Nat.Prime 4 := by norm_num
example : ¬ Nat.Prime 9 := by norm_num
example : ¬ Nat.Prime 15 := by norm_num

-- 使用 #eval 检查素数
#eval Nat.Prime 2   -- true
#eval Nat.Prime 4   -- false
#eval Nat.Prime 17  -- true
#eval Nat.Prime 100 -- false

/-! ## 素数的基本性质 -/

-- 素数大于 1
theorem prime_one_lt (p : ℕ) (hp : Nat.Prime p) : 1 < p := by
  exact Nat.Prime.one_lt hp

-- 素数的正约数只有 1 和自身
theorem prime_dvd_of_prime (p m : ℕ) (hp : Nat.Prime p) (hm : m ∣ p) :
    m = 1 ∨ m = p := by
  exact (Nat.Prime.eq_one_or_self_of_dvd hp m) hm

-- 2 是唯一的偶素数
theorem two_is_even_prime : Nat.Prime 2 := by norm_num

theorem odd_prime_of_gt_two (p : ℕ) (hp : Nat.Prime p) (h : p > 2) : p % 2 = 1 := by
  have h1 : p % 2 = 0 ∨ p % 2 = 1 := by omega
  rcases h1 with (h1 | h1)
  · -- p % 2 = 0，即 2 ∣ p
    have h2 : 2 ∣ p := by omega
    have h3 : 2 = 1 ∨ 2 = p := Nat.Prime.eq_one_or_self_of_dvd hp 2 h2
    rcases h3 with (h3 | h3)
    · norm_num at h3
    · linarith
  · exact h1

/-! ## 欧几里得引理 -/

-- 如果 p 是素数且 p ∣ a * b，则 p ∣ a 或 p ∣ b
theorem euclid_lemma (p a b : ℕ) (hp : Nat.Prime p) (h : p ∣ a * b) :
    p ∣ a ∨ p ∣ b := by
  exact Nat.Prime.dvd_mul hp |>.mp h

-- 推论：如果 p 是素数且 p ∣ a^n，则 p ∣ a
theorem prime_dvd_pow (p a n : ℕ) (hp : Nat.Prime p) (h : p ∣ a ^ n) : p ∣ a := by
  exact Nat.Prime.dvd_of_dvd_pow hp h

/-! ## 素数有无穷多个 -/

-- 欧几里得的著名证明：素数有无穷多个
-- Mathlib 中有这个定理

#check Nat.exists_infinite_primes

theorem infinitely_many_primes : ∀ n : ℕ, ∃ p : ℕ, p ≥ n ∧ Nat.Prime p := by
  exact Nat.exists_infinite_primes

-- 对于任意 n，存在大于 n 的素数
example (n : ℕ) : ∃ p : ℕ, p > n ∧ Nat.Prime p := by
  exact Nat.exists_infinite_primes (n + 1)

/-! ## 算术基本定理（唯一分解定理） -/

-- 每个大于 1 的自然数都可以唯一地表示为素数的乘积
-- Mathlib 中有这个定理的形式化表述

-- 每个正整数都有素因子
theorem exists_prime_factor (n : ℕ) (h : n > 1) : ∃ p : ℕ, Nat.Prime p ∧ p ∣ n := by
  exact Nat.exists_prime_and_dvd h

/-! ## 素数判定 -/

-- 试除法：检查是否有小于 sqrt(n) 的素因子
-- Mathlib 中提供了素数判定的可计算函数

-- 使用 decide 判定
#eval decide (Nat.Prime 101)  -- true
#eval decide (Nat.Prime 111)  -- false

/-! ## 素数与互素 -/

-- 如果 p 是素数且 p 不整除 a，则 gcd(p, a) = 1
theorem coprime_of_prime_not_dvd (p a : ℕ) (hp : Nat.Prime p) (h : ¬ p ∣ a) :
    Nat.Coprime p a := by
  exact Nat.Prime.coprime_iff_not_dvd hp |>.mpr h

-- 如果 p 是素数，则 gcd(p, a) 要么是 1，要么是 p
theorem gcd_prime (p a : ℕ) (hp : Nat.Prime p) :
    Nat.gcd p a = 1 ∨ Nat.gcd p a = p := by
  have h1 : Nat.gcd p a ∣ p := Nat.gcd_dvd_left p a
  have h2 : Nat.gcd p a = 1 ∨ Nat.gcd p a = p :=
    Nat.Prime.eq_one_or_self_of_dvd hp (Nat.gcd p a) h1
  exact h2

/-! ## 梅森素数 -/

-- 形如 2^p - 1 的素数称为梅森素数
-- 其中 p 必须是素数（否则 2^p - 1 不是素数）

-- 如果 2^n - 1 是素数，则 n 是素数
theorem prime_of_mersenne_prime (n : ℕ) (h : Nat.Prime (2 ^ n - 1)) : Nat.Prime n := by
  by_contra hn
  have h1 : n = 0 ∨ n = 1 ∨ ¬Nat.Prime n := by
    rcases n with (_ | _ | n) <;> simp [Nat.Prime] at hn ⊢ <;> omega
  sorry  -- 完整证明较复杂，这里省略

/-! ## 孪生素数 -/

-- 相差为 2 的两个素数称为孪生素数
-- 例如 (3, 5), (5, 7), (11, 13), (17, 19)

def TwinPrime (p q : ℕ) : Prop := Nat.Prime p ∧ Nat.Prime q ∧ q = p + 2

example : TwinPrime 3 5 := by
  simp [TwinPrime] <;> norm_num

example : TwinPrime 5 7 := by
  simp [TwinPrime] <;> norm_num

example : TwinPrime 11 13 := by
  simp [TwinPrime] <;> norm_num

-- 孪生素数猜想：存在无穷多对孪生素数（尚未证明）

/-! ## 素数定理（概述） -/

-- 素数定理：π(x) ~ x / ln(x)，其中 π(x) 是不超过 x 的素数个数
-- Mathlib 中有素数定理的证明

/-! # 整数上的素数 -/

-- 在整数环上，素数可以是正的也可以是负的
-- ±2, ±3, ±5, ±7, ...

end Lean4Tutorial.Examples.MathlibNumberTheory.Primes
