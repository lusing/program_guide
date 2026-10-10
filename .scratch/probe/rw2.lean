def fib : Nat → Nat
  | 0 => 0
  | 1 => 1
  | (k+2) => fib (k+1) + fib k
theorem f1 (n : Nat) : fib (n+3) = fib (n+2) + fib (n+1) := rfl

theorem h1 (k : Nat) : fib (3*k+3+2) = fib (3*k+3+1) + fib (3*k+3) := by
  rw [show 3*k+3+2 = 3*k+2+3 from by omega, f1,
      show 3*k+2+2 = 3*k+3+1 from by omega,
      show 3*k+2+1 = 3*k+3 from by omega]
#print axioms h1

theorem h2 (k : Nat) : fib (3*k+3+2) = fib (3*k+3+1) + fib (3*k+3) := by
  have e1 : 3*k+3+2 = 3*k+2+3 := by omega
  rw [e1, f1]
  rfl
#print axioms h2
