/-
! # 第 12 章 · 商群

对应原书 §2.6。机器验证：
1. 商群的运算律（定理 2.111 的实例层）；
2. 威尔逊定理（定理 2.109）的数值实例；
3. A₃ 的地位（命题 2.95 的数值侧）。
-/

import Mathlib.GroupTheory.QuotientGroup.Basic
import Mathlib.GroupTheory.Perm.Sign
import Mathlib.Data.ZMod.Basic
import Mathlib.Tactic.Linarith

namespace Abstractalgebra.Ch12

/-! ## 定理 2.111：商群的运算（陪集乘法的良定义） -/

-- 乘法陪集的良定义乘法：mk (a * b) = mk a * mk b
example {G : Type*} [Group G] (K : Subgroup G) [K.Normal] (a b : G) :
    (QuotientGroup.mk (a * b) : G ⧸ K) = (QuotientGroup.mk a : G ⧸ K) * (QuotientGroup.mk b : G ⧸ K) :=
  QuotientGroup.mk_mul K a b

-- 单位元陪集是商群的单位元
example {G : Type*} [Group G] (K : Subgroup G) [K.Normal] (a : G) :
    (QuotientGroup.mk a : G ⧸ K) * (QuotientGroup.mk 1 : G ⧸ K) = (QuotientGroup.mk a : G ⧸ K) := by
  rw [← QuotientGroup.mk_mul K, mul_one]

-- 逆元陪集：mk a⁻¹ = (mk a)⁻¹
example {G : Type*} [Group G] (K : Subgroup G) [K.Normal] (a : G) :
    (QuotientGroup.mk a ⁻¹ : G ⧸ K) = (QuotientGroup.mk a : G ⧸ K) ⁻¹ :=
  QuotientGroup.mk_inv K a

/-! ## 威尔逊定理（定理 2.109）的数值实例 -/

-- p 素 ⟹ (p−1)! ≡ −1 (mod p)：p = 5, 7, 11, 13
example : (5 - 1).factorial % 5 = 5 - 1 := by decide
example : (7 - 1).factorial % 7 = 7 - 1 := by decide
example : (11 - 1).factorial % 11 = 11 - 1 := by decide
example : (13 - 1).factorial % 13 = 13 - 1 := by decide

-- 合成数失效：(8−1)! = 5040 ≡ 0 (mod 8) ≠ 7
example : (8 - 1).factorial % 8 ≠ 8 - 1 := by decide

/-! ## Aₙ 的地位（命题 2.95 的数值侧） -/

-- |A₃| = 3!/2：sign 把 S₃ 均分为两半
example : Fintype.card {p : Equiv.Perm (Fin 3) // Equiv.Perm.sign p = 1} = 3 := by
  decide

end Abstractalgebra.Ch12
