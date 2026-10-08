theorem cp : ¬ ∃ e : Nat → Nat → Prop,
    ∀ P, ∃ n, ∀ x, e n x ↔ P x := by
  intro he
  match he with
  | ⟨e, h⟩ =>
    match h (fun x => ¬ e x x) with
    | ⟨n, hn⟩ =>
      specialize hn n
      exact absurd (hn.mp hn) (hn.mpr fun hne => hne hn)
