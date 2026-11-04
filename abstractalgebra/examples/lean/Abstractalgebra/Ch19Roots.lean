/-
! # 第 19 章 · 从数到多项式：根与因子

对应原书 §3.5。机器验证：
1. 因子定理：(x − a) ∣ f ⟺ f(a) = 0；
2. 根数 ≤ 次数（整环上）；
3. 具体算例：x³ − x 的根、有理根定理实例；`/` 4. 高斯整数 ℤ[i]：四商例、除法算式（norm_mod_lt）、二平方和（Nat.Prime.sq_add_sq）。
-/

import Mathlib.Algebra.Polynomial.Roots
import Mathlib.Algebra.Polynomial.FieldDivision
import Mathlib.Tactic.Ring
import Mathlib.Tactic.NormNum
import Mathlib.Tactic.Linarith
import Mathlib.NumberTheory.Zsqrtd.GaussianInt
import Mathlib.NumberTheory.SumTwoSquares

namespace Abstractalgebra.Ch19

/-! ## 因子定理 -/

-- 余式定理的正式化：p mod (X − C a) = C (p.eval a)——根 ⟺ 线性因子整除
example {R : Type*} [CommRing R] (p : Polynomial R) (a : R) :
    p %ₘ (Polynomial.X - Polynomial.C a) = Polynomial.C (p.eval a) :=
  Polynomial.modByMonic_X_sub_C_eq_C_eval p a

-- 实例：x = 1 是 x³ − x 的根 ⟹ (x − 1) ∣ x³ − x
example : (Polynomial.X - 1 : Polynomial ℚ) ∣ Polynomial.X ^ 3 - Polynomial.X := by
  use Polynomial.X ^ 2 + Polynomial.X
  ring

-- x = 2 不是 x² + 1 的根 ⟹ 余式非零
example : (Polynomial.X ^ 2 + 1 : Polynomial ℚ).eval 2 ≠ 0 := by norm_num

/-! ## 根数 ≤ 次数 -/

example {R : Type*} [CommRing R] [IsDomain R] (f : Polynomial R) :
    f.roots.card ≤ f.natDegree := f.card_roots'

/-! ## 具体算例 -/

-- x³ − x 的三个根：−1, 0, 1（次数 3 = 根数，完全分裂的样本）
example : (Polynomial.X ^ 3 - Polynomial.X : Polynomial ℚ).eval 0 = 0 := by norm_num

example : (Polynomial.X ^ 3 - Polynomial.X : Polynomial ℚ).eval 1 = 0 := by norm_num

example : (Polynomial.X ^ 3 - Polynomial.X : Polynomial ℚ).eval (-1) = 0 := by norm_num

-- 2x³ + x − 3 的有理根恰为 x = 1（定理 3.47 的实例）
example : (2 * Polynomial.X ^ 3 + Polynomial.X - 3 : Polynomial ℚ).eval 1 = 0 := by
  norm_num

example : (2 * Polynomial.X ^ 3 + Polynomial.X - 3 : Polynomial ℚ).eval (-1) ≠ 0 := by
  norm_num

example : (2 * Polynomial.X ^ 3 + Polynomial.X - 3 : Polynomial ℚ).eval (3 / 2) ≠ 0 := by
  norm_num


/-! ## 欧几里得环与费马二平方和（§3.5 Euclidean Rings 小节）

例 3.77 的机器面：mathlib 已内置高斯整数 ℤ[i]（记法是 local 的，须写
GaussianInt 全名）——
orm_mod_lt 正是「除法算式 ∂(r) < ∂(β)」的正式化。
定理 3.83 的机器面：Nat.Prime.sq_add_sq（SumTwoSquares 文件）即
「p % 4 ≠ 3 ⟹ p 是二平方和」。 -/

/-- 例 3.77 的商余不唯一：3+5i = 2q + r 的四个商（每个余数 ∂ = 2 < 4）。 -/
example : (⟨3, 5⟩ : GaussianInt) = (⟨2, 0⟩ : GaussianInt) * (⟨1, 2⟩ : GaussianInt)
    + (⟨1, 1⟩ : GaussianInt) := by
  decide

example : (⟨3, 5⟩ : GaussianInt) = (⟨2, 0⟩ : GaussianInt) * (⟨2, 3⟩ : GaussianInt)
    + (⟨-1, -1⟩ : GaussianInt) := by
  decide

/-- 例 3.77 的核心：高斯整数的除法算式（mathlib 正式化）。 -/
example (x : GaussianInt) {y : GaussianInt} (hy : y ≠ 0) :
    Zsqrtd.norm (x % y) < Zsqrtd.norm y :=
  GaussianInt.norm_mod_lt x hy

/-- 范数乘性 ∂(αβ) = ∂(α)∂(β) 在 (2+i)(1+2i) = 5i 上的机器核验。 -/
example : Zsqrtd.norm ((⟨2, 1⟩ : GaussianInt) * (⟨1, 2⟩ : GaussianInt))
    = Zsqrtd.norm (⟨2, 1⟩ : GaussianInt) * Zsqrtd.norm (⟨1, 2⟩ : GaussianInt) := by
  decide

/-- 定理 3.83 的正向展览：p ≡ 1 (mod 4) 的表示。 -/
example : (2 : ℤ) ^ 2 + (1 : ℤ) ^ 2 = 5 ∧ (3 : ℤ) ^ 2 + (2 : ℤ) ^ 2 = 13 ∧
    (4 : ℤ) ^ 2 + (1 : ℤ) ^ 2 = 17 ∧ (5 : ℤ) ^ 2 + (2 : ℤ) ^ 2 = 29 := by
  norm_num

/-- 引理 3.82 的见证：m² ≡ −1 (mod p)（p = 5, 13, 29）。 -/
example : (2 : ZMod 5) ^ 2 = -1 ∧ (5 : ZMod 13) ^ 2 = -1 ∧ (12 : ZMod 29) ^ 2 = -1 := by
  decide

/-- 定理 3.83（费马二平方和）的 mathlib 正式化。 -/
example (p : ℕ) [Fact p.Prime] (hp : p % 4 ≠ 3) :
    ∃ a b : ℕ, a ^ 2 + b ^ 2 = p :=
  Nat.Prime.sq_add_sq hp

end Abstractalgebra.Ch19
