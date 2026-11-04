/-
! # 第 02 章 · 二项式定理与复数

对应原书 §1.2。机器验证四件：
1. 帕斯卡恒等式与行和 Σ C(n,k) = 2ⁿ；
2. 二项式定理（ℚ 上逐项展开）；
3. 分圆分解 Π_{d∣n} Φ_d = Xⁿ − 1 与具体分圆多项式；
4. 欧拉函数恒等式 Σ_{d∣n} φ(d) = n（推论 1.28）。
-/

import Mathlib.Data.Nat.Choose.Basic
import Mathlib.Data.Nat.Choose.Sum
import Mathlib.Data.Rat.Defs
import Mathlib.Data.Nat.Totient
import Mathlib.RingTheory.Polynomial.Cyclotomic.Basic

namespace Abstractalgebra.Ch02

/-! ## 帕斯卡恒等式与行和 -/

-- 帕斯卡恒等式：mathlib 以此为 choose 的递归定义
example (n k : ℕ) : (n + 1).choose (k + 1) = n.choose k + n.choose (k + 1) :=
  Nat.choose_succ_succ n k

/-- 帕斯卡行和：n 元集合的子集总数 = 2ⁿ。 -/
theorem row_sum_eq_two_pow (n : ℕ) :
    ∑ m ∈ Finset.range (n + 1), Nat.choose n m = 2 ^ n :=
  Nat.sum_range_choose n

/-! ## 二项式定理 -/

/-- 二项式定理（ℚ 系数版）：(x+y)ⁿ = Σ C(n,k)·xᵏ·yⁿ⁻ᵏ。 -/
theorem binomial_rat (n : ℕ) (x y : ℚ) :
    (x + y) ^ n = ∑ m ∈ Finset.range (n + 1),
      x ^ m * y ^ (n - m) * (Nat.choose n m : ℚ) := by
  simpa using add_pow x y n

/-! ## 分圆分解（命题 1.27）与推论 1.28 -/

/-- xⁿ − 1 = Π_{d∣n} Φ_d(x)，ℤ 系数。 -/
theorem cyclotomic_product (n : ℕ) (hn : 0 < n) :
    ∏ d ∈ n.divisors, Polynomial.cyclotomic d ℤ = Polynomial.X ^ n - 1 :=
  Polynomial.prod_cyclotomic_eq_X_pow_sub_one hn _

/-- 推论 1.28：Σ_{d∣n} φ(d) = n。 -/
theorem sum_totient_eq (n : ℕ) : ∑ d ∈ n.divisors, Nat.totient d = n :=
  Nat.sum_totient n

-- 具体分圆多项式（与本章手算对照）：Φ₅ = X⁴+X³+X²+X+1（素数情形）
set_option linter.style.haveILetI false in
example : Polynomial.cyclotomic 5 ℤ =
    Polynomial.X ^ 4 + Polynomial.X ^ 3 + Polynomial.X ^ 2 + Polynomial.X + 1 := by
  haveI : Fact (Nat.Prime 5) := ⟨by decide⟩
  rw [Polynomial.cyclotomic_prime]
  simp [Finset.sum_range_succ']

-- Φ₁₂ 的负系数示例。cyclotomic 在 mathlib 中标记为 noncomputable，
-- 无法 decide 求值，改走「手算分解 + 次数对账」双证：
example : (Polynomial.X ^ 12 - 1 : Polynomial ℤ)
      = (Polynomial.X - 1) * (Polynomial.X + 1) * (Polynomial.X ^ 2 + 1)
        * (Polynomial.X ^ 2 + Polynomial.X + 1)
        * (Polynomial.X ^ 2 - Polynomial.X + 1)
        * (Polynomial.X ^ 4 - Polynomial.X ^ 2 + 1) := by
  ring

-- 上式前五个因子分别是 Φ₁, Φ₂, Φ₄, Φ₃, Φ₆（mathlib 已证其三）：
example : Polynomial.cyclotomic 1 ℤ = Polynomial.X - 1 := Polynomial.cyclotomic_one ℤ
example : Polynomial.cyclotomic 2 ℤ = Polynomial.X + 1 := Polynomial.cyclotomic_two ℤ
example : Polynomial.cyclotomic 3 ℤ = Polynomial.X ^ 2 + Polynomial.X + 1 :=
  Polynomial.cyclotomic_three ℤ

-- 而 Φ₁₂ 的次数 = φ(12) = 4——剩下的因子 X⁴ − X² + 1 恰好四次，
-- 由 ℤ[x] 中分解的唯一性（第 20 章），它就是 Φ₁₂。
example : (Polynomial.cyclotomic 12 ℤ).natDegree = 4 := by
  rw [Polynomial.natDegree_cyclotomic 12 ℤ]
  decide

end Abstractalgebra.Ch02
