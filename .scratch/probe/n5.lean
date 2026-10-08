#check @Nat.le_mul_of_pos_left
#check @Nat.le_mul_of_pos_right
example (d j : Nat) (hd : 1 ≤ d) : j ≤ d * j := Nat.le_mul_of_pos_left hd
