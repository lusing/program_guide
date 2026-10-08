def dle (x y : Nat) : Prop :=
  x = y ∨ (x = 0 ∧ y ≠ 0) ∨ (y = 4 ∧ x ≠ 4)

example (x y z : Nat) (p : x = 0 ∧ y ≠ 0) (q : y = 0 ∧ z ≠ 0) : dle x z := by omega
example (h1 : 1 = 2) (P : Prop) : P := by omega
theorem djn_12 : (match 1, 2 with
  | 0, w => w
  | w, 0 => w
  | 4, _ => 4
  | _, 4 => 4
  | w1, w2 => if w1 == w2 then w1 else 4) = 4 := rfl
#print axioms djn_12
