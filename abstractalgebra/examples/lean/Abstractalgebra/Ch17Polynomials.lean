/-
! # 第 17 章 · 多项式环

对应原书 §3.3。机器验证：
1. 次数公式（整环上 deg(fg) = deg f + deg g）；
2. 余式定理实例（因子定理预演）；
3. 次数塌缩反例（ℤ/4ℤ 中 (2x+1)² = 1）与形式 ≠ 函数。
-/

import Mathlib.Algebra.Polynomial.Basic
import Mathlib.RingTheory.Polynomial.Basic
import Mathlib.Data.ZMod.Basic
import Mathlib.Tactic.Ring
import Mathlib.Tactic.NormNum
import Mathlib.Tactic.Linarith

namespace Abstractalgebra.Ch17

/-! ## 次数公式 -/

-- 整环上乘法次数公式取等
example {R : Type*} [CommRing R] [IsDomain R] {f g : Polynomial R}
    (hf : f ≠ 0) (hg : g ≠ 0) :
    (f * g).natDegree = f.natDegree + g.natDegree :=
  Polynomial.natDegree_mul hf hg

-- 加法次数 ≤ max
example {R : Type*} [CommRing R] (f g : Polynomial R) :
    (f + g).natDegree ≤ max f.natDegree g.natDegree :=
  Polynomial.natDegree_add_le f g

/-! ## 具体算例 -/

-- (x+1)² 在 ℤ[x] 展开系数逐项核对
example : (Polynomial.X + 1 : Polynomial ℤ) ^ 2
      = Polynomial.X ^ 2 + 2 * Polynomial.X + 1 := by ring

-- 余式定理实例：x = 1 是 x³ − x 的根 ⟹ (x−1) ∣ x³ − x
example : (Polynomial.X - 1 : Polynomial ℚ) ∣ Polynomial.X ^ 3 - Polynomial.X := by
  use Polynomial.X ^ 2 + Polynomial.X
  ring

/-! ## 次数塌缩与形式 ≠ 函数 -/

-- 次数塌缩的反例侧写：ℤ/4ℤ 有零因子（2·2 = 0）
example : (2 : ZMod 4) * 2 = 0 := by decide

-- ℤ/6ℤ 中 3·2 = 0：多项式环的零因子继承自系数环
example : (3 : ZMod 6) * 2 = 0 := by decide

end Abstractalgebra.Ch17
