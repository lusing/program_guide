/-
文件: 10_mathlib_number_theory/number_theory.lean
描述: 第13章 数论（与教程同步，Mathlib4 master@2026-09 验证）
编译: lake build Lean4Tutorial.Examples.MathlibNumberTheory.NumberTheory
-/

import Mathlib.Data.Nat.GCD.Basic
import Mathlib.Data.Nat.Prime.Basic
import Mathlib.Data.Nat.Prime.Infinite
import Mathlib.Data.Nat.ModEq
import Mathlib.Data.ZMod.Basic
import Mathlib.Algebra.Field.ZMod
import Mathlib.FieldTheory.Finite.Basic
import Mathlib.Data.Nat.Factorization.Basic
import Mathlib.NumberTheory.Real.Irrational

namespace Lean4Tutorial.Examples.MathlibNumberTheory.Ch13

/-! # 13.1 整除性 -/

#check ((2 : ℕ) ∣ 6)
#eval decide ((2 : ℕ) ∣ 6)    -- true（Prop 用 decide 求值）

section Divisibility
variable {α : Type} [Monoid α] {a b c : α}

example (a : α) : a ∣ a := dvd_refl a
example (h1 : a ∣ b) (h2 : b ∣ c) : a ∣ c := dvd_trans h1 h2
end Divisibility

example {a b : ℕ} : a ∣ b ↔ ∃ c : ℕ, b = c * a := dvd_iff_exists_eq_mul_left
-- Nat.dvd_add_iff_right（Lean 核心 Init/Data/Nat/Dvd.lean）：k ∣ m → (k ∣ n ↔ k ∣ m + n)
example {a b c : ℕ} (h : a ∣ b) (h' : a ∣ b + c) : a ∣ c := (Nat.dvd_add_iff_right h).mpr h'

/-! # 13.2 最大公约数与互素 -/

#eval Nat.gcd 12 8
#eval Nat.gcd 1071 462

example (m n : ℕ) : Nat.gcd m n ∣ m := Nat.gcd_dvd_left m n
example (m n : ℕ) : Nat.gcd m n ∣ n := Nat.gcd_dvd_right m n
example {m n k : ℕ} (h1 : k ∣ m) (h2 : k ∣ n) : k ∣ Nat.gcd m n := Nat.dvd_gcd h1 h2

example : Nat.Coprime 8 15 := by decide
example {m n : ℕ} : Nat.Coprime m n ↔ Nat.gcd m n = 1 := Nat.coprime_iff_gcd_eq_one
example {p m n : ℕ} (hp : Nat.Coprime p m) (h : p ∣ m * n) : p ∣ n :=
  Nat.Coprime.dvd_of_dvd_mul_left hp h

/-! # 13.3 素数 -/

example : Nat.Prime 7 := by decide
example : ¬ Nat.Prime 10 := by decide

example {p : ℕ} : Nat.Prime p ↔ 2 ≤ p ∧ ∀ m < p, m ∣ p → m = 1 := Nat.prime_def_lt

example {p a b : ℕ} (hp : Nat.Prime p) : p ∣ a * b ↔ p ∣ a ∨ p ∣ b := hp.dvd_mul

#eval Nat.minFac 15
example {n : ℕ} (h : n ≠ 1) : Nat.Prime (Nat.minFac n) := Nat.minFac_prime h

/-! # 13.4 模运算 -/

example : 5 ≡ 2 [MOD 3] := by decide

example {a b n : ℕ} : a ≡ b [MOD n] ↔ (n : ℤ) ∣ (b : ℤ) - a := Nat.modEq_iff_dvd

example {a b c d n : ℕ} (h1 : a ≡ b [MOD n]) (h2 : c ≡ d [MOD n]) :
    a + c ≡ b + d [MOD n] := h1.add h2

example {a b c d n : ℕ} (h1 : a ≡ b [MOD n]) (h2 : c ≡ d [MOD n]) :
    a * c ≡ b * d [MOD n] := h1.mul h2

-- ZMod：类型风格的模运算
example : (5 : ZMod 3) = 2 := by decide
example (x y : ZMod 7) : (x + y)^2 = x^2 + 2*x*y + y^2 := by ring

example [Fact (Nat.Prime 7)] (x : ZMod 7) (hx : x ≠ 0) : x * x⁻¹ = 1 :=
  mul_inv_cancel₀ hx

example {a b n : ℕ} : a ≡ b [MOD n] ↔ (a : ZMod n) = (b : ZMod n) :=
  (ZMod.natCast_eq_natCast_iff a b n).symm

/-! # 13.5 费马小定理与欧拉定理 -/

open Nat in
example {x n : ℕ} (h : Nat.Coprime x n) : x ^ φ n ≡ 1 [MOD n] :=
  Nat.ModEq.pow_totient h

example {p : ℕ} [Fact p.Prime] {a : ZMod p} (ha : a ≠ 0) : a ^ (p - 1) = 1 :=
  ZMod.pow_card_sub_one_eq_one ha

example {p : ℕ} [Fact p.Prime] (a : ZMod p) : a ^ p = a :=
  ZMod.pow_card a

/-! # 13.6 素数无穷多（Euclid） -/

#check Nat.exists_infinite_primes

-- open Nat 启用阶乘后缀记法 n !
open Nat in
theorem euclid_demo (n : ℕ) : ∃ p, n ≤ p ∧ Nat.Prime p :=
  let p := Nat.minFac (n ! + 1)
  have f1 : n ! + 1 ≠ 1 := ne_of_gt <| Nat.succ_lt_succ <| Nat.factorial_pos _
  have pp : Nat.Prime p := Nat.minFac_prime f1
  have np : n ≤ p :=
    Nat.le_of_not_ge fun h =>
      have h₁ : p ∣ n ! := Nat.dvd_factorial (Nat.minFac_pos _) h
      have h₂ : p ∣ 1 := (Nat.dvd_add_iff_right h₁).2 (Nat.minFac_dvd _)
      pp.not_dvd_one h₂
  ⟨p, np, pp⟩

/-! # 13.7 √2 是无理数 -/

#check @irrational_sqrt_natCast_iff
#check @Nat.Prime.irrational_sqrt

theorem irrational_sqrt_two' : Irrational √2 := by
  simpa using Nat.prime_two.irrational_sqrt

-- Decidable 实例存在，但 Nat.sqrt.iter 是 sealed 的，需 unseal 才能计算
unseal Nat.sqrt.iter in
example : Irrational √24 := by decide

/-! # 13.8 唯一分解 -/

#eval (60 : ℕ).factorization 2
#eval (60 : ℕ).factorization 3
#eval (60 : ℕ).primeFactors

example (n : ℕ) (hn : n ≠ 0) : n.factorization.prod (· ^ ·) = n :=
  Nat.prod_factorization_pow_eq_self hn

end Lean4Tutorial.Examples.MathlibNumberTheory.Ch13
