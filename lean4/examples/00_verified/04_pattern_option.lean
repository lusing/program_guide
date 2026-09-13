namespace Lean4Verified.PatternOption

def unwrapOr (d : Nat) : Option Nat → Nat
  | some v => v
  | none => d

def headOr (d : Nat) : List Nat → Nat
  | [] => d
  | x :: _ => x

theorem unwrap_none (d : Nat) : unwrapOr d none = d := by
  rfl

end Lean4Verified.PatternOption

