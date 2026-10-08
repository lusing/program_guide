-- 嫌疑 1：Gcd 型（含 ∃ 的定义展开）在上下文时的 omega
def Gcd (d a b : Nat) : Prop :=
  ∃ k, True
theorem t3 (hg : Gcd 1 2 3) (x y : Nat) (h : y < x + 2) : y < x + 3 := by omega
#print axioms t3
-- 嫌疑 2：goal 是 eq of products（1*a = 0*0 + a）带 Or 上下文
theorem t4 (hor : (0 = 0 ∧ True) ∨ (0 = 1 ∧ True)) (a : Nat) : 1 * a = 0 * 0 + a := by omega
#print axioms t4
-- 嫌疑 3：等式 goal 含应用 atom
def foo (a : Nat) : Nat := a
theorem t5 (Hf : foo a + 2 ≤ 5) : foo a + 1 ≤ 4 := by omega
#print axioms t5
