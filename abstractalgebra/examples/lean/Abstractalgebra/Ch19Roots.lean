/-
! # 第 19 章 · 从数到多项式：根与因子

对应原书 §3.5。机器验证：
1. 因子定理：(x − a) ∣ f ⟺ f(a) = 0；
2. 根数 ≤ 次数（整环上）；
3. 具体算例：x³ − x 的根、有理根定理实例。
-/

import Mathlib.Algebra.Polynomial.Roots
import Mathlib.Algebra.Polynomial.FieldDivision
import Mathlib.Tactic.Ring
import Mathlib.Tactic.NormNum
import Mathlib.Tactic.Linarith

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

end Abstractalgebra.Ch19
