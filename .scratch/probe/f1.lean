example (a b' f' r : Nat)
    (Hf : a + 2 * (b'+1) + 1 ≤ f'+1)
    (hr : r < b'+1) (hb : b'+1 ≤ a) :
    (b'+1) + 2 * r + 1 ≤ f' := by omega
