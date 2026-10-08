def searchPre : (Nat → Nat) → Nat → Nat → Option Nat
  | _, _, 0 => none
  | f, n, k'+1 => if f k' == n then some k' else searchPre f n k'

example (f : Nat → Nat) (y x : Nat) (hd : searchPre f y (x+1) = none) : False := by
  simp only [searchPre] at hd
  split at hd
  · exact Bool.noConfusion hd
  · exact absurd rfl rfl

example (f : Nat → Nat) (y d' : Nat) (hd : searchPre f y (d'+1) = none) : True := by
  have h2 : (if f d' == y then some d' else searchPre f y d') = none := hd
  split at h2
  · trivial
  · trivial
