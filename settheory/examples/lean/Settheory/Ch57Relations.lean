import Mathlib.Basic.Rel
import Mathlib.Tactic

/-!
# 第 57 章 · 关系：表格、有向图与关系代数（Makinson Ch2）

`SetRel`（Set (α × β)）上的逆/复合/分配律；传递闭包 `Relation.TransGen`
的最小性；整除偏序的反对称。官方锚点：`SetRel.inv_comp`、
`SetRel.comp_assoc`、`SetRel.dom_inv`、`Relation.TransGen`。
-/

namespace Settheory.Ch57

open SetRel

variable {α β γ : Type*} (R : SetRel α β) (S : SetRel β γ) (T : SetRel γ δ)

-- 复合的逆 = 逆的复合（次序交换）：官方锚点
theorem converse_comp_swap : (R ○ S).inv = S.inv ○ R.inv :=
  SetRel.inv_comp R S

-- 复合的结合律：官方锚点
theorem comp_assoc_example : (R ○ S) ○ T = R ○ (S ○ T) :=
  SetRel.comp_assoc R S T

-- 域与值域在逆下互换：官方锚点
theorem dom_inv_example : R.inv.dom = R.cod :=
  SetRel.dom_inv

-- dom(R⁻¹) = range(R) 的点wise 版本
theorem cod_inv_example : R.inv.cod = R.dom :=
  SetRel.cod_inv

-- (R₁ ∪ R₂) ○ S = (R₁ ○ S) ∪ (R₂ ○ S)：左分配（官方库只有右分配
-- comp_iUnion，这里补左向并手证）
theorem comp_union_left_distrib (R₁ R₂ : SetRel α β) (S : SetRel β γ) :
    (R₁ ∪ R₂) ○ S = (R₁ ○ S) ∪ (R₂ ○ S) := by
  ext ⟨a, c⟩
  simp only [mem_comp, Set.mem_union]
  constructor
  · rintro ⟨b, hb | hb, hbc⟩
    · exact Or.inl ⟨b, hb, hbc⟩
    · exact Or.inr ⟨b, hb, hbc⟩
  · rintro (⟨b, hb, hbc⟩ | ⟨b, hb, hbc⟩)
    · exact ⟨b, Or.inl hb, hbc⟩
    · exact ⟨b, Or.inr hb, hbc⟩

-- 传递闭包的最小性：包含 R 的传递关系必包含 R⁺
-- （官方件 Relation.transGen_minimal 用 IsTrans 实例；这里按 TransGen
--   的两个构造子 single/tail 直接归纳，与 Agda 通道同构）
theorem TC_minimal {r T : α → α → Prop}
    (hR : ∀ a b, r a b → T a b)
    (hT : ∀ a b c, T a b → T b c → T a c) :
    ∀ a b, Relation.TransGen r a b → T a b := by
  intro a b h
  induction h with
  | single h => exact hR _ _ h
  | tail _ hc ih => exact hT _ _ _ ih (hR _ _ hc)

-- 整除是 ℕ 上的偏序：反对称（传递与自反由 Nat.dvd_refl/dvd_trans 官方）
theorem dvd_antisymm' {m n : ℕ} (h1 : m ∣ n) (h2 : n ∣ m) : m = n :=
  Nat.dvd_antisymm h1 h2

-- 线性序的最小元若存在则唯一：两-least 相等（反对称的直接应用）
example (a b : ℕ) (ha : ∀ c, a ≤ c) (hb : ∀ c, b ≤ c) : a = b :=
  le_antisymm (ha b) (hb a)

end Settheory.Ch57
