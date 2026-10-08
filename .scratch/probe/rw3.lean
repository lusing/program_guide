def fib : Nat → Nat
  | 0 => 0
  | 1 => 1
  | (k+2) => fib (k+1) + fib k
theorem f1 (n : Nat) : fib (n+3) = fib (n+2) + fib (n+1) := rfl

theorem j1 (k c b d : Nat)
    (key : fib (3*k+3+2) = fib (3*k+3+1) + fib (3*k+3))
    (hd : fib (3*k+3+1) = 2*d+1)
    (He3 : fib (3*k+3) = 2*(c+b+1)) :
    ∃ d, fib (3*k+3+2) = 2 * d + 1 := by
  rw [key]
  exact ⟨d + c + b + 1, by omega⟩
#print axioms j1

theorem j2 (k c b : Nat)
    (key : fib (3*k+3+2) = fib (3*k+3+1) + fib (3*k+3))
    (Ho4 : ∃ d, fib (3*k+3+1) = 2*d+1)
    (He3 : fib (3*k+3) = 2*(c+b+1)) :
    ∃ d, fib (3*k+3+2) = 2 * d + 1 := by
  rw [key]
  cases Ho4 with
  | intro d hd => exact ⟨d + c + b + 1, by omega⟩
#print axioms j2
