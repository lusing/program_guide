theorem cp : ¬ ∃ e : Nat → Nat → Prop,
    ∀ P : Nat → Prop, ∃ n : Nat, ∀ x : Nat, e n x ↔ P x := by
  intro he
  match he with
  | ⟨e, h⟩ =>
    match h (fun x => ¬ e x x) with
    | ⟨n, hn⟩ =>
      specialize hn n
      cases hn
