def searchPre : (Nat → Nat) → Nat → Nat → Option Nat
  | _, _, 0 => none
  | f, n, k'+1 => if f k' == n then some k' else searchPre f n k'

example (f : Nat → Nat) (y x : Nat) (hd : searchPre f y (x+1) = none) : False := by
  have h2 : (if f x == y then some x else searchPre f y x) = none := hd
  split at h2
  · exact Option.noConfusion h2
  · exact h2

example (f : Nat → Nat) (y x : Nat) (hfx : f x = y) (hd : searchPre f y (x+1) = none) : False := by
  have h2 : (if f x == y then some x else searchPre f y x) = none := hd
  rw [show (f x == y) = decide (f x = y) from rfl, decide_eq_true hfx] at h2
  exact Option.noConfusion h2
