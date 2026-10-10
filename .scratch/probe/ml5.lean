example (a' k1' k2' : Nat) (hP : 1 = (k1'+1) * (k2'+1)) :
    k1' * (k2'+1) = 0 ∧ k2' = 0 := by
  have e2 := Nat.succ_mul k1' (k2'+1)
  omega
