example (b q1 q2 j' : Nat) (hji : q2 - q1 = j' + 1) (hlt : q1 < q2) :
    q2 = q1 + (j' + 1) := by omega
