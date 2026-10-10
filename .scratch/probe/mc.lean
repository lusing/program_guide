theorem t (h : ∃ k : Nat, k + 0 = k) : True := by
  match h with
  | ⟨k, hk⟩ =>
    -- h 还在吗？
    exact trivial
theorem t2 (h : ∃ k : Nat, k + 0 = k) : True := by
  cases h with
  | intro k hk => exact trivial
