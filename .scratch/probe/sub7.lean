theorem submul (a b c : Nat) (h : b ≤ a) : (a - b) * c = a * c - b * c := by
  have e0 : (b + (a - b)) * c = b * c + (a - b) * c := Nat.add_mul b (a - b) c
  have hj : b + (a - b) = a := by omega
  rw [hj] at e0
  -- e0 : a * c = b * c + (a - b) * c
  omega
