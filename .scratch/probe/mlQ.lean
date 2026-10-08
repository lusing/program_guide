set_option linter.unusedVariables false
-- A: by_cases on Bool eq
theorem tA (L : List Nat) (c : Nat) (h : True) : True := by
  by_cases hcx : L.contains c = true
  · trivial
  · trivial
-- B: match h : expr with
theorem tB (L : List Nat) : True := by
  match h : (List.range (L.length + 1)).filter (fun c => !L.contains c) with
  | c :: _ => trivial
  | [] => trivial
-- C: ▸
theorem tC (a b : Nat) (L : List Nat) (heq : a = b) (hin : a ∈ L) : True := by
  have : b ∈ L := heq ▸ hin
  trivial
#print axioms tA
#print axioms tB
#print axioms tC
