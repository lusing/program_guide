def dmrF (a b : Nat) : Nat := 3
example (a b' f' : Nat)
    (Hf : a + 2 * (b'+1) + 1 ≤ f'+1)
    (hr : dmrF a (b'+1) < b'+1) (hb : b'+1 ≤ a) :
    (b'+1) + 2 * dmrF a (b'+1) + 1 ≤ f' := by omega
