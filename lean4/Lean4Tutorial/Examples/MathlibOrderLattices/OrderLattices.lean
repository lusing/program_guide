/-
文件: 19_mathlib_order_lattices/order_lattices.lean
描述: 第32章 序与格（与教程同步，Mathlib4 v4.35.0-rc3 验证）
编译: lake build Lean4Tutorial.Examples.MathlibOrderLattices.OrderLattices
-/

import Mathlib.Order.Lattice
import Mathlib.Order.CompleteLattice.Basic
import Mathlib.Order.Hom.Basic
import Mathlib.Order.GaloisConnection.Basic
import Mathlib.Data.Set.Basic
import Mathlib.Data.Set.Lattice.Order
import Mathlib.Tactic

namespace Lean4Tutorial.Examples.MathlibOrderLattices.Ch32

open OrderHom

/-! # 32.1 序结构层级 -/

#check (inferInstance : Preorder ℕ)
#check (inferInstance : PartialOrder ℕ)
#check (inferInstance : LinearOrder ℕ)

example (a : ℕ) : a ≤ a := le_refl a
example (a b c : ℕ) (h1 : a ≤ b) (h2 : b ≤ c) : a ≤ c := le_trans h1 h2
example (a b : ℕ) (h1 : a ≤ b) (h2 : b ≤ a) : a = b := le_antisymm h1 h2
-- 严格序由非严格序刻画
example (a b : ℕ) : a < b ↔ a ≤ b ∧ ¬ b ≤ a := by omega

/-! # 32.2 格：上确界 ⊔ 与下确界 ⊓ -/

#eval (5 : ℕ) ⊔ 3              -- 5（ℕ 上 ⊔ = max）
#eval (5 : ℕ) ⊓ 3              -- 3（ℕ 上 ⊓ = min）
#eval (true : Bool) ⊓ false    -- false
#eval (true : Bool) ⊔ false    -- true

example (a b : ℕ) : a ≤ a ⊔ b := le_sup_left
example (a b : ℕ) : b ≤ a ⊔ b := le_sup_right
example (a b c : ℕ) (h1 : a ≤ c) (h2 : b ≤ c) : a ⊔ b ≤ c := sup_le h1 h2
example (a b : ℕ) : a ⊓ b ≤ a := inf_le_left
example (a b : ℕ) : a ⊓ b ≤ b := inf_le_right
example (a b c : ℕ) (h1 : c ≤ a) (h2 : c ≤ b) : c ≤ a ⊓ b := le_inf h1 h2

-- 交换律、结合律
example (a b : ℕ) : a ⊔ b = b ⊔ a := sup_comm a b
example (a b : ℕ) : a ⊓ b = b ⊓ a := inf_comm a b
example (a b c : ℕ) : a ⊔ b ⊔ c = a ⊔ (b ⊔ c) := sup_assoc a b c

-- ℕ 是分配格
example (a b c : ℕ) : a ⊓ (b ⊔ c) = a ⊓ b ⊔ a ⊓ c := inf_sup_left a b c

/-! # 32.3 完备格：⊤ ⊥ 与任意上/下确界 -/

#check (inferInstance : CompleteLattice (Set ℕ))
example : (⊥ : Set ℕ) = ∅ := rfl
example : (⊤ : Set ℕ) = Set.univ := rfl
example (s : Set ℕ) : s ⊆ (⊤ : Set ℕ) := Set.subset_univ s
#check @sSup
#check @sInf

-- IsGreatest s a：a ∈ s 且是 s 的上界；IsLeast 对偶
example : IsGreatest {n : ℕ | n ≤ 5} 5 := ⟨by decide, fun _ hx => hx⟩
example : IsLeast {n : ℕ | 5 ≤ n} 5 := ⟨by decide, fun _ hx => hx⟩

/-! # 32.4 单调函数与序同态 -/

example : Monotone (fun n : ℕ => n + 1) := fun _ _ h => Nat.succ_le_succ h

-- OrderHom（记作 →o）= 单调函数 + 保序证明
def addOneHom : ℕ →o ℕ where
  toFun n := n + 1
  monotone' _ _ h := Nat.succ_le_succ h
#eval addOneHom 5   -- 6

-- OrderIso（记作 ≃o）= 双射且双向保序；OrderEmbedding（↪o）= 单射且保序反映序
#check (OrderIso.refl ℕ : ℕ ≃o ℕ)

/-! # 32.5 Galois 连接 -/

-- GaloisConnection f g 即 ∀ a b, f a ≤ b ↔ a ≤ g b（它是一个可展开的 def，不是 structure）
-- 例：ℕ 上 (· * 2) 与 (· / 2) 构成 Galois 连接
example : GaloisConnection (fun n : ℕ => n * 2) (fun n => n / 2) := by
  intro a b
  constructor
  · intro h
    have : a * 2 ≤ b := h
    show a ≤ b / 2
    omega
  · intro h
    have : a ≤ b / 2 := h
    show a * 2 ≤ b
    omega

end Lean4Tutorial.Examples.MathlibOrderLattices.Ch32
