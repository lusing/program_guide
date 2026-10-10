def inj (f : Nat → Nat) : Prop := ∀ x y, f x = f y → x = y
theorem double_inj : inj (fun n => 2 * n) := by
  intro x y h
  have h2 : 2 * x = 2 * y := h
  omega
