theorem t (ih : ∀ a b : Nat, a ≤ b → ∃ q r : Nat, a = b * q + r) (x y : Nat) (h : y < x + 2) :
    y < x + 3 := by omega
#print axioms t
theorem t2 (P : Nat → Prop) (ih : ∀ a b : Nat, a ≤ b → P a) (x y : Nat) (h : y < x + 2) :
    y < x + 3 := by omega
#print axioms t2
