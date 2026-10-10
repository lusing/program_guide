#check @Nat.mul_sub_distrib
example (a k1 k2 : Nat) : a * k1 - a * k2 = a * (k1 - k2) := by
  rw [Nat.mul_sub_distrib]
