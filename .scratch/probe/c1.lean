example (a b m n g : Nat) (hm : a = g * m) (hn : b = g * n) :
    a * b = (g * m) * (g * n) := by
  conv => lhs; rw [hm, hn]
