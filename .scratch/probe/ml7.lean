example (x y : Nat) (h : x ≤ y) : (if x <=? y then y else x) = y := by
  simp only [Nat.ltOrGeToBool?]
