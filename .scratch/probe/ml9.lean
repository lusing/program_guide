def mmax (x y : Nat) : Nat := if Nat.decide (x ≤ y) then y else x
theorem mmax_big : ∀ x y, x ≤ y → mmax x y = y := by
  intro x y h
  show (if Nat.decide (x ≤ y) then y else x) = y
  rw [Nat.decide_eq_true h]
theorem mmax_sml : ∀ x y, y ≤ x → mmax x y = x := by
  intro x y h
  show (if Nat.decide (x ≤ y) then y else x) = x
  cases hc : Nat.decide (x ≤ y) with
  | true => rw [hc] at *; have := of_decide_eq_true hc; omega
  | false => rfl
