theorem t (h : ∃ k : Nat, k + 0 = k) : k = 0 → True := by
  intro hk
  match h with
  | ⟨k', h'⟩ => omega
