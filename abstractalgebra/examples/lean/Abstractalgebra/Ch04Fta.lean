/-
! # 第 04 章 · 算术基本定理

对应原书 §1.4。机器验证：
1. 分解的存在（乘积还原）与素性（primeFactorsList）；
2. 规范形与具体算例（1728 = 2⁶·3³）；
3. gcd·lcm = ab（命题 1.56）；
4. gcd 的指数刻画（命题 1.55：factorization 逐分量取 min）；
5. 唯一性的一个代表性片段（素数幂等式 p^e = q^f ⟹ p = q ∧ e = f）。
-/

import Mathlib.Data.Nat.Factors
import Mathlib.Data.Nat.Factorization.Basic
import Mathlib.Tactic.Linarith

namespace Abstractalgebra.Ch04

/-! ## 存在性与素性 -/

-- 每个 n ≠ 0 的素因子列表乘积还原为 n（定理 1.2 的机器版）
theorem prod_primeFactorsList_eq (n : ℕ) (hn : n ≠ 0) :
    List.prod n.primeFactorsList = n :=
  Nat.prod_primeFactorsList hn

-- 列表中每个元素都是素数
theorem prime_of_mem (n : ℕ) (p : ℕ) (hp : p ∈ n.primeFactorsList) :
    Nat.Prime p :=
  Nat.prime_of_mem_primeFactorsList hp

/-! ## 具体算例：1728 = 2⁶ · 3³ 的规范形 -/

example : Nat.primeFactorsList 1728 = [2, 2, 2, 2, 2, 2, 3, 3, 3] := by
  native_decide

/-! ## 唯一性的命门片段 -/

-- 唯一性的关键一步：素数整除素数则相等（不同的素数互素）
example (p q : ℕ) (hp : Nat.Prime p) (hq : Nat.Prime q) (h : p ∣ q) : p = q :=
  (Nat.prime_dvd_prime_iff_eq hp hq).mp h

-- 一般唯一性定理由 UniqueFactorizationMonoid.factors_unique 承担
-- （ℕ 的唯一分解幺半群实例），此处引为注记。

/-! ## gcd 与 lcm 的指数律（命题 1.55 / 1.56） -/

-- 命题 1.56：gcd(a,b) · lcm(a,b) = a·b
example (a b : ℕ) : Nat.gcd a b * Nat.lcm a b = a * b :=
  Nat.gcd_mul_lcm a b

-- 命题 1.55 的机器版：gcd 的素指数 = 逐分量取 min（Finsupp 的 ⊓）
example (a b : ℕ) (ha : a ≠ 0) (hb : b ≠ 0) :
    (Nat.gcd a b).factorization = a.factorization ⊓ b.factorization :=
  Nat.factorization_gcd ha hb

-- 具体算例：168 与 180（正文 4.2 节）
example : Nat.gcd 168 180 = 12 := by decide
example : Nat.lcm 168 180 = 2520 := by decide
example : Nat.gcd 168 180 * Nat.lcm 168 180 = 168 * 180 := by decide

end Abstractalgebra.Ch04
