/-
! # 第 10 章 · 子群与拉格朗日定理

对应原书 §2.4。机器验证：
1. |H| ∣ |G|（定理 2.81）；
2. 元素阶整除群阶（推论 2.83）与 a ^ |G| = 1（推论 2.84）；
3. 循环群的子群唯一性（命题 2.73）：ZMod 12 中每个元素的阶 ∈ 因子集；
4. 欧拉定理的群论读法：U(ℤ₉) 有 φ(9) = 6 个元素。
-/

import Mathlib.GroupTheory.OrderOfElement
import Mathlib.GroupTheory.Coset.Card
import Mathlib.Data.ZMod.Units
import Mathlib.Tactic.Linarith

namespace Abstractalgebra.Ch10

/-! ## 定理 2.81 与推论 2.83/2.86 -/

-- 拉格朗日：|H| ∣ |G|
example {G : Type*} [Group G] (H : Subgroup G) : Nat.card H ∣ Nat.card G :=
  H.card_subgroup_dvd_card

-- 推论 2.83：元素阶整除群阶
example {G : Type*} [Group G] [Fintype G] (a : G) :
    orderOf a ∣ Fintype.card G := orderOf_dvd_card

-- 推论 2.84：a ^ |G| = 1
example {G : Type*} [Group G] (a : G) : a ^ Nat.card G = 1 := pow_card_eq_one'

-- 欧拉定理的预演（定理 2.107）：U(ℤ₉) 有 φ(9) = 6 个元素
example : Fintype.card (ZMod 9)ˣ = 6 := by decide

/-! ## 命题 2.73：ZMod 12 中元素的阶恰取因子集（以倍数事实呈现） -/

-- 3 的阶 = 4：4·3 ≡ 0 (mod 12)，更小正倍数 ≠ 0
example : (4 : ℕ) • (3 : ZMod 12) = 0 := by decide

example : (2 : ℕ) • (3 : ZMod 12) ≠ 0 := by decide

-- 4 的阶 = 3
example : (3 : ℕ) • (4 : ZMod 12) = 0 := by decide

-- 6 的阶 = 2
example : (2 : ℕ) • (6 : ZMod 12) = 0 := by decide

example : (1 : ℕ) • (6 : ZMod 12) ≠ 0 := by decide

-- 每个元素 ×12 回零（推论 2.84 的 ℤ₁₂ 版）
example : ∀ a : ZMod 12, (12 : ℕ) • a = 0 := by decide

end Abstractalgebra.Ch10
