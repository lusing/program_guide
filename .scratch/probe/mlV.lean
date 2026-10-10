theorem t1 (l1 l2 : List Nat) (h : l1.Sublist l2) : l1.length ≤ l2.length :=
  List.Sublist.length_le h
#print axioms t1
