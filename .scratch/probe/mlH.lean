def dle (x y : Nat) : Prop :=
  x = y ∨ (x = 0 ∧ y ≠ 0) ∨ (y = 4 ∧ x ≠ 4)

theorem t1 (x y z : Nat) (p : x = 0 ∧ y ≠ 0) (q : y = 0 ∧ z ≠ 0) : dle x z := by omega
theorem t2 (x y z : Nat) (p : x = 0 ∧ y ≠ 0) (q : y = 0 ∧ z ≠ 0) : False := by omega
theorem t3 (a b : Nat) (h : a + b = 0) : a = 0 := by omega
#print axioms t1
#print axioms t2
#print axioms t3
