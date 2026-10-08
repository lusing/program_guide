example (b q1 r1 q2 r2 j' : Nat)
    (hr1 : r1 < b) (heq : b * q1 + r1 = b * q2 + r2)
    (hm : q2 = q1 + (j' + 1))
    (e2 : b * q2 = b * q1 + b * (j' + 1))
    (e4 : b * (j' + 1) = b * j' + b) : False := by omega
