example (a b' f' : Nat)
    (Hf : a + 2 * (b'+1) + 1 ≤ f'+1)
    (hab : a ≤ b'+1) :
    (b'+1) + 2 * a + 1 ≤ f' := by omega
