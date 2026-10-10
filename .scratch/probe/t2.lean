example (x y q b' r g : Nat) (hbe : x * (b'+1) = y * r + g)
    (haq : a = (b'+1) * q + r) :
    (x + y * q) * (b'+1) = y * a + g := by
  have ha' : y * a = y * ((b'+1) * q + r) := by rw [haq]
  rw [ha', Nat.add_mul, hbe]
  simp [Nat.mul_add, Nat.mul_comm, Nat.mul_assoc, Nat.mul_left_comm]
