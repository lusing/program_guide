#check @Nat.le_of_mul_le_mul_left
example (n k m : Nat) (h : 0 < n) : n * k ≤ n * m → k ≤ m :=
  Nat.le_of_mul_le_mul_left h
