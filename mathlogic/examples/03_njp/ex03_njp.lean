/- ex03 —— 自然演绎 NJp（Lean 4 版）：规则即程序 -/

namespace Ex03

theorem andComm {p q : Prop} (h : p ∧ q) : q ∧ p := ⟨h.right, h.left⟩

theorem orComm {p q : Prop} (h : p ∨ q) : q ∨ p := h.elim Or.inr Or.inl

theorem deMorgan₁ {p q : Prop} (h : ¬(p ∨ q)) : ¬p ∧ ¬q :=
  ⟨fun hp => h (Or.inl hp), fun hq => h (Or.inr hq)⟩

theorem deMorgan₂ {p q : Prop} (h : ¬p ∧ ¬q) : ¬(p ∨ q) := by
  intro he
  exact he.elim h.left h.right

/-- 派生规则：拒取式 -/
theorem mtT {p q : Prop} (h : p → q) (hnq : ¬q) : ¬p :=
  fun hp => hnq (h hp)

theorem exFalso {p : Prop} (h : False) : p := False.elim h

theorem kAxiom {p q : Prop} (hp : p) (_ : q) : p := hp

#print axioms andComm
#print axioms deMorgan₂

/- ---------- curry/uncurry：→I/E 的代数 ---------- -/

theorem curryT {p q r : Prop} (f : p ∧ q → r) : p → q → r :=
  fun hp hq => f ⟨hp, hq⟩

theorem uncurryT {p q r : Prop} (f : p → q → r) : p ∧ q → r :=
  fun ⟨hp, hq⟩ => f hp hq

/- ---------- 派生规则第二组：nnI / pbc / lemUse（H&R §1.2.2） ---------- -/

/-- ¬¬ 引入：构造性白送（p 的证据挡住任何证伪器） -/
theorem nnI {p : Prop} (hp : p) : ¬¬p := fun hnp => hnp hp

/-- PBC（反证法）：¬p → False 即 ¬¬p，Classical.byContradiction 收；
    账本记 Classical.choice -/
theorem pbc {p : Prop} (h : ¬p → False) : p := Classical.byContradiction h

/-- LEM 作为派生规则的分情况使用 -/
theorem lemUse {p q : Prop} (hpq : p → q) (hnpq : ¬p → q) : q := by
  cases Classical.em p with
  | inl hp => exact hpq hp
  | inr hnp => exact hnpq hnp

#print axioms nnI    -- does not depend on any axioms
#print axioms pbc    -- Classical.choice 系
#print axioms lemUse -- Classical.choice 系

/- 坑位速记（Lean 侧）：
   - ⟨_, _⟩ 匿名构造子语法同时吃 ∧I 与 ∨E 的 elim 桥；
   - h.elim Or.inr Or.inl 一行做完 ∨E（两个 continuation）；
   - fun ⟨hp, hq⟩ => ... 的 λ 模式匹配在 Lean 4 完全合法。 -/

end Ex03
