/-
! # 第 03 章 · 最大公因子

对应原书 §1.3。机器验证：
1. 除法算式（存在 + 唯一性）；
2. 贝祖等式：gcd(a,b) = sa + tb（mathlib 的 xgcd 就是欧几里得回代）；
3. 欧几里得引理与 √2 无理性的整数内核；
4. 欧几里得无穷素数（推论 1.30）与 991 素性（试除判别法，中译本命题 1.3）；
5. 7 进制数字（例 1.45）。
-/

import Mathlib.Data.Nat.Basic
import Mathlib.Data.Int.GCD
import Mathlib.Data.Nat.Digits.Defs
import Mathlib.Data.Nat.Prime.Defs
import Mathlib.Data.Nat.Prime.Basic
import Mathlib.Data.Nat.Prime.Infinite
import Mathlib.Tactic.Linarith
import Mathlib.Tactic.LinearCombination

namespace Abstractalgebra.Ch03

/-! ## 除法算式（定理 1.29） -/

-- 存在性：mathlib 的 a/b 与 a%b 直接给出
theorem division_alg_exists (a b : ℕ) (hb : 0 < b) :
    ∃ q r, a = b * q + r ∧ r < b := by
  refine ⟨a / b, a % b, ?_, Nat.mod_lt _ hb⟩
  rw [Nat.div_add_mod a b]

-- 唯一性（ℤ 上陈述；关键步是 (q−q')·b = r'−r 的符号分析）
theorem division_alg_unique (a b q r q' r' : ℤ) (hb : 0 < b)
    (h1 : a = q * b + r) (h2 : 0 ≤ r) (h3 : r < b)
    (h4 : a = q' * b + r') (h5 : 0 ≤ r') (h6 : r' < b) :
    q = q' ∧ r = r' := by
  have key : (q - q') * b = r' - r := by linear_combination h4 - h1
  rcases lt_trichotomy q q' with h | h | h
  · exfalso
    have hq : q - q' ≤ -1 := by omega
    have hm : (q - q') * b ≤ -1 * b := mul_le_mul_of_nonneg_right hq (by omega)
    omega
  · subst h
    simp only [sub_self, zero_mul] at key
    exact ⟨rfl, by omega⟩
  · exfalso
    have hq : 1 ≤ q - q' := by omega
    have hm : 1 * b ≤ (q - q') * b := mul_le_mul_of_nonneg_right hq (by omega)
    omega

/-! ## 贝祖等式（定理 1.32） -/

/-- gcd(a, b) 是 a 与 b 的整系数线性组合。mathlib 的 `Int.gcdA/gcdB`
由扩展欧几里得算法（xgcd）回代产生——正文手算的 46·78 − 11·326 同源。
（Int.gcd 以 ℕ 计值，故左侧带类型转换。） -/
theorem bezout (a b : ℤ) : ∃ s t : ℤ, (Int.gcd a b : ℤ) = a * s + b * t := by
  refine ⟨Int.gcdA a b, Int.gcdB a b, ?_⟩
  exact Int.gcd_eq_gcd_ab a b

-- 例 1.42 的机器复核：gcd(326, 78) = 2
example : Nat.gcd 326 78 = 2 := by decide

-- 机器算出的贝祖系数与正文手算一致：2 = 46·78 − 11·326
example : (326 : ℤ) * Int.gcdA 326 78 + (78 : ℤ) * Int.gcdB 326 78 = 2 := by
  native_decide

/-! ## 欧几里得引理（定理 1.35）与 √2 -/

-- 素数整除乘积必整除某因子
example (p : ℕ) (hp : Nat.Prime p) {a b : ℕ} (h : p ∣ a * b) :
    p ∣ a ∨ p ∣ b := (hp.dvd_mul).mp h

-- √2 无理性的整数内核：2 ∣ a² ⟹ 2 ∣ a
example (a : ℕ) (h : 2 ∣ a ^ 2) : 2 ∣ a :=
  Nat.Prime.dvd_of_dvd_pow Nat.prime_two h

/-! ## 素数无穷（推论 1.30）与试除判别（中译本命题 1.3） -/

-- 欧几里得：任意 N 之上还有素数
example (N : ℕ) : ∃ p, N ≤ p ∧ Nat.Prime p :=
  Nat.exists_infinite_primes N

-- 试除判别法的实例：991 是素数（只需试除到 √991 ≈ 31.5）
example : Nat.Prime 991 := by
  native_decide

/-! ## 进制表示（例 1.45） -/

-- 12345 = (50664)₇；Nat.digits 低位在前
example : Nat.digits 7 12345 = [4, 6, 6, 0, 5] := by
  native_decide

end Abstractalgebra.Ch03
