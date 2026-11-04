/-
! # 第 13 章 · 群作用

对应原书 §2.7。机器验证：
1. 轨道-稳定子定理（定理 2.141）；
2. S₃ 传递作用在 Fin 3 上：一条轨道；稳定子成员资格 = 固定 0；
3. 凯莱定理（定理 2.130）的实例化：ZMod 6 的左正则作用传递。
-/

import Mathlib.GroupTheory.GroupAction.Quotient
import Mathlib.Data.Fintype.Perm
import Mathlib.Data.ZMod.Basic
import Mathlib.Tactic.Linarith

namespace Abstractalgebra.Ch13

/-! ## 定理 2.141：轨道-稳定子（mathlib 正式化） -/

example {G X : Type*} [Group G] [Fintype G] [MulAction G X] [Fintype X] [DecidableEq X]
    (x : X) [Fintype (MulAction.orbit G x)] [Fintype (MulAction.stabilizer G x)] :
    Fintype.card (MulAction.orbit G x) * Fintype.card (MulAction.stabilizer G x)
      = Fintype.card G :=
  MulAction.card_orbit_mul_card_stabilizer_eq_card_group G x

/-! ## S₃ 在 Fin 3 上的自然作用 -/

-- 传递：每个 y 都能被某个置换从 0 搬运过去（穷举证明）
example : ∀ y : Fin 3, ∃ p : Equiv.Perm (Fin 3), p • (0 : Fin 3) = y := by
  decide

-- 稳定子成员资格 = 固定 0：3（轨道）× 2（稳定子）= 6 = |S₃|
example (p : Equiv.Perm (Fin 3)) :
    p ∈ MulAction.stabilizer (Equiv.Perm (Fin 3)) (0 : Fin 3) ↔ p 0 = 0 := Iff.rfl

example : Fintype.card (Equiv.Perm (Fin 3)) = 6 := by decide

example : Fintype.card (MulAction.stabilizer (Equiv.Perm (Fin 3)) (0 : Fin 3)) = 2 := by
  native_decide

/-! ## 凯莱定理（定理 2.130）：左正则作用 -/

-- 群在自己上的左乘作用：g • x = g * x（mathlib 的自作用实例）
example (G : Type) [Group G] (g : G) (x : G) : g • x = g * x := rfl

-- ZMod 6 元素 1 的轨道 = 全群（正则作用传递：每个 y 都是某倍的 1）
example : ∀ y : ZMod 6, ∃ g : ZMod 6, g • (1 : ZMod 6) = y := by
  decide

end Abstractalgebra.Ch13
