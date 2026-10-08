-- 自证 (a-b)*c = a*c - b*c 的 nat 版（b ≤ a 时）
example (a b c : Nat) (h : b ≤ a) : (a - b) * c = a * c - b * c := by
  have hj : a = b + (a - b) := by omega
  rw [hj] at *
  rw [Nat.add_mul]
  omega
