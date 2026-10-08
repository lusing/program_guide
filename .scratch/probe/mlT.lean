theorem t1 (L : List Nat) (a : Nat) (h : a ∈ L) : (L.erase a).length = L.length - 1 :=
  List.length_erase_of_mem h
theorem t2 (L : List Nat) (a b : Nat) (hne : a ≠ b) (h : a ∈ L) : a ∈ L.erase b :=
  (List.mem_erase_of_ne hne).mpr h
theorem t3 (n : Nat) : (List.range n.succ) = List.range n ++ [n] := List.range_succ
theorem t4 (a b : Nat) : a ∈ [b] ↔ a = b := List.mem_singleton
#print axioms t1
#print axioms t2
#print axioms t3
#print axioms t4
