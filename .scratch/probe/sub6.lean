theorem submul (a b c : Nat) (h : b ≤ a) : (a - b) * c = a * c - b * c := by
  have e1 : b * c + (a - b) * c = a * c := by
    have e0 : (b + (a - b)) * c = b * c + (a - b) * c := Nat.add_mul b (a - b) c
    have hj : b + (a - b) = a := by omega
    rw [hj] at e0
    exact e0.symm?? .
  omega
