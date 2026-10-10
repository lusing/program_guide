theorem submul (a b c : Nat) (h : b ≤ a) : (a - b) * c = a * c - b * c := by
  have hj : a = b + (a - b) := by omega
  subst hj
  rw [Nat.add_mul]
  have : b * c + (a - b) * c - b * c = (a - b) * c := by omega
  omega
