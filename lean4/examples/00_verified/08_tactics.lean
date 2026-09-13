namespace Lean4Verified.Tactics

theorem add_zero_right (n : Nat) : n + 0 = n := by
  simpa using Nat.add_zero n

theorem add_assoc_demo (a b c : Nat) : a + b + c = a + (b + c) := by
  simpa [Nat.add_assoc]

theorem succ_ne_zero (n : Nat) : Nat.succ n ≠ 0 := by
  exact Nat.succ_ne_zero n

end Lean4Verified.Tactics
