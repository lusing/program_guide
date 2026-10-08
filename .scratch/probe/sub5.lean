theorem submul (a b c : Nat) (h : b ≤ a) : (a - b) * c = a * c - b * c := by
  have e1 : b * c + (a - b) * c = a * c := by
    have hj : a = b + (a - b) := by omega
    calc b * c + (a - b) * c = (b + (a - b)) * c := (Nat.add_mul b (a - b) c).symm
      _ = a * c := by rw [hj]
  omega
