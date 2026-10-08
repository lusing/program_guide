def GcdX (d a b : Nat) : Prop :=
  d ≤ a ∧ ∃ k, b = d * k
theorem t3 (hg : GcdX 1 2 3) (x y : Nat) (h : y < x + 2) : y < x + 3 := by omega
#print axioms t3
theorem t6 (a b : Nat) (h : a < b) (hor : a = 0 ∨ a = 1) : a ≤ 1 := by omega
#print axioms t6
theorem t7 (a b : Nat) (hor : (0 = 0 ∧ a = b) ∨ (0 = 1 ∧ a = b)) : a ≤ b := by omega
#print axioms t7
