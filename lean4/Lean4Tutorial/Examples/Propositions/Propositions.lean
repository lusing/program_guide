/-
文件: 05_propositions/propositions.lean
描述: 第7章 命题与证明（与教程同步，Lean 4.34.0 验证）
编译: lake build Lean4Tutorial.Examples.Propositions.Propositions
-/

namespace Lean4Tutorial.Examples.Propositions.Ch7

-- 显式声明变量层级（自动绑定会把 R/Q 推断为任意 Sort，theorem 要求 Prop）
section Logic
variable {P Q R : Prop}

/-! # 柯里-霍华德对应 -/

def p : Prop := 2 + 2 = 4
theorem two_plus_two_eq_four : 2 + 2 = 4 := rfl
#check two_plus_two_eq_four

theorem t_term : 1 + 1 = 2 := rfl
theorem t_tac  : 1 + 1 = 2 := by rfl

/-! # 合取与 Iff -/

theorem and_intro' (hp : P) (hq : Q) : P ∧ Q := ⟨hp, hq⟩

theorem and_swap : P ∧ Q → Q ∧ P
  | ⟨hp, hq⟩ => ⟨hq, hp⟩

theorem iff_comm : (P ↔ Q) ↔ (Q ↔ P) :=
  ⟨fun h => ⟨h.2, h.1⟩, fun h => ⟨h.2, h.1⟩⟩

theorem and_tac : 2 + 2 = 4 ∧ 3 + 3 = 6 := by
  constructor
  · rfl
  · rfl

/-! # 析取 -/

theorem or_swap : P ∨ Q → Q ∨ P
  | .inl hp => .inr hp
  | .inr hq => .inl hq

theorem or_elim' (h : P ∨ Q) (hpr : P → R) (hqr : Q → R) : R := by
  cases h with
  | inl hp => exact hpr hp
  | inr hq => exact hqr hq

/-! # 否定 -/

theorem not_not_intro (h : P) : ¬¬P := fun hn => hn h
theorem absurd' (hp : P) (hnp : ¬P) : Q := absurd hp hnp

/-! # 经典逻辑 -/

open Classical in
theorem em' (P : Prop) : P ∨ ¬P := em P

/-! # 量词 -/

theorem all_intro' : ∀ n : Nat, n ≥ 0 := fun n => Nat.zero_le n

theorem exists_intro' : ∃ n : Nat, n > 5 := ⟨6, by decide⟩

/-! # 等式与重写 -/

end Logic

section Equality
variable {α β : Type} {a b c : α} {P : α → Prop} {Q : Prop}

theorem exists_elim' (h : ∃ x, P x) (h2 : ∀ x, P x → Q) : Q := by
  rcases h with ⟨x, hx⟩
  exact h2 x hx

theorem eq_refl' (a : α) : a = a := rfl
theorem eq_ops (h1 : a = b) (h2 : b = c) : a = c := h1.trans h2
example (h : a = b) : b = a := h.symm
example (f : α → β) (h : a = b) : f a = f b := congrArg f h

theorem rewrite_example (x y : Nat) (h : x = y) : x + 0 = y := by
  rw [h, Nat.add_zero]

example (h : a = b) : P a → P b := h ▸ id

end Equality

/-! # 可判定性与 decide -/

example : 2 + 2 = 4 := by decide
example : (7 : Nat) % 3 = 1 := by decide
#check (inferInstance : Decidable (2 + 2 = 4))
example (n : Nat) : String := if n = 0 then "zero" else "nonzero"

/-! # calc -/

theorem calc_example (a b c : Nat) (h1 : a = b + 1) (h2 : b = c + 2) :
    a = c + 3 := by
  calc
    a = b + 1         := h1
    _ = (c + 2) + 1   := by rw [h2]
    _ = c + 3         := rfl

example (a b c d : Nat) (h1 : a < b) (h2 : b ≤ c) (h3 : c < d) : a < d := by
  calc
    a < b := h1
    _ ≤ c := h2
    _ < d := h3

end Lean4Tutorial.Examples.Propositions.Ch7
