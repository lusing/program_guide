theorem submul (a b c : Nat) (h : b ≤ a) : (a - b) * c = a * c - b * c := by
  have e1 : b * c + (a - b) * c = a * c := by
    have hj : a = b + (a - b) := by omega
    conv => lhs; rw [← hj]
    rw [Nat.add_mul]
    congr 1
    ring_nf?? .
  omega
