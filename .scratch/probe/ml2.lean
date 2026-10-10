example (a k1 k2 : Nat) : 2 * 2 <= (k1+1)*(k2+1) :=
  Nat.mul_le_mul
    (Nat.succ_le_succ (Nat.zero_le _))
    (Nat.succ_le_succ (Nat.zero_le _))
