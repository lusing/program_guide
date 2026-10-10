#check @List.contains_iff
#check @List.elem_iff
example (L : List Nat) (c : Nat) (h : !L.contains c = true) : c ∉ L := by
  simp [List.contains] at h; exact h
