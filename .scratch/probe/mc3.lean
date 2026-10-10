theorem t (h : ∃ k : Nat, k = k) (x y : Nat) (he : x = y) : y = x := by
  match h with
  | ⟨k', h'⟩ => omega
