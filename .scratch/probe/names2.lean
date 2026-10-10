-- 自证 a*(k1−k2) = a*k1 − a*k2 的干净途径：j 概括
example (a k1 k2 : Nat) (h : k2 ≤ k1) : a * k1 - a * k2 = a * (k1 - k2) := by
  have hj : k1 = k2 + (k1 - k2) := by omega
  have e : a * k1 = a * k2 + a * (k1 - k2) := by
    rw [hj, Nat.mul_add]
  have e2 : a * (k1 - k2) = a * k1 - a * k2 := by omega
  exact (e2).symm
