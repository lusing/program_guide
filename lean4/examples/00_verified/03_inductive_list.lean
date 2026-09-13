namespace Lean4Verified.InductiveList

inductive Color where
  | red
  | green
  | blue
deriving Repr, DecidableEq

def isWarm : Color → Bool
  | .red => true
  | _ => false

def lengthNat : List Nat → Nat
  | [] => 0
  | _ :: xs => lengthNat xs + 1

theorem len_cons (x : Nat) (xs : List Nat) : lengthNat (x :: xs) = lengthNat xs + 1 := by
  rfl

end Lean4Verified.InductiveList

