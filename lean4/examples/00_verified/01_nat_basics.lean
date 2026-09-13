namespace Lean4Verified.NatBasics

def addExample : Nat := 2 + 3
def mulExample : Nat := 4 * 5

theorem add_comm_demo (a b : Nat) : a + b = b + a := by
  exact Nat.add_comm a b

theorem mul_assoc_demo (a b c : Nat) : (a * b) * c = a * (b * c) := by
  exact Nat.mul_assoc a b c

end Lean4Verified.NatBasics

