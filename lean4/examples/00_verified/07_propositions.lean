namespace Lean4Verified.Propositions

theorem and_swap (P Q : Prop) : P ∧ Q → Q ∧ P := by
  intro h
  exact And.intro h.right h.left

theorem imp_trans (P Q R : Prop) : (P → Q) → (Q → R) → P → R := by
  intro hpq hqr hp
  exact hqr (hpq hp)

theorem not_not_intro (P : Prop) : P → ¬¬P := by
  intro hp hnp
  exact hnp hp

end Lean4Verified.Propositions

