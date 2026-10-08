def searchPre : (Nat → Nat) → Nat → Nat → Option Nat
  | _, _, 0 => none
  | f, n, k'+1 => if f k' == n then some k' else searchPre f n k'

example (f : Nat → Nat) (y x : Nat) (hd : searchPre f y (x+1) = none) : False := by
  have h2 : (if f x == y then some x else searchPre f y x) = none := hd
  split at h2
  · cases h2
  · exact absurd rfl rfl
