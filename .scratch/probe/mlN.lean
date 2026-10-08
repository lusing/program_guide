example (a x : Nat) (xs : List Nat) (h : a ∈ x :: xs) : True := by
  cases h with
  | head => trivial
  | tail hrest => trivial
