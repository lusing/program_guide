theorem n1 (k : Nat) (Ho4 : ∃ d : Nat, d = d) : 3*k+3+2 = 3*k+2+3 := by omega
#print axioms n1
def fib : Nat → Nat
  | 0 => 0
  | 1 => 1
  | (k+2) => fib (k+1) + fib k
theorem n2 (k c b : Nat) (He3 : fib (3*k+3) = 2*(c+b+1)) :
    3*k+3+2 = 3*k+2+3 := by omega
#print axioms n2
theorem n3 (k c b : Nat) (He3 : fib (3*k+3) = 2*(c+b+1)) :
    3*k+3+2 = 3*k+2+3 := Nat.add_right_comm (3*k) 3 2
#print axioms n3
