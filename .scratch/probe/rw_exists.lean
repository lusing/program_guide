def fib : Nat → Nat
  | 0 => 0
  | 1 => 1
  | (k+2) => fib (k+1) + fib k
theorem f1 (n : Nat) : fib (n+3) = fib (n+2) + fib (n+1) := rfl

theorem g3 (k c b : Nat)
    (Ho4 : ∃ d, fib (3*k+3+1) = 2*d+1)
    (He3 : fib (3*k+3) = 2*(c+b+1)) :
    ∃ d, fib (3*k+3+2) = 2 * d + 1 := by
  rw [show 3*k+3+2 = 3*k+2+3 from by omega, f1,
      show 3*k+2+2 = 3*k+3+1 from by omega,
      show 3*k+2+1 = 3*k+3 from by omega]
  cases Ho4 with
  | intro d hd => exact ⟨d + c + b + 1, by omega⟩
#print axioms g3

theorem g4 (k c b : Nat)
    (Ho4 : ∃ d, fib (3*k+3+1) = 2*d+1)
    (He3 : fib (3*k+3) = 2*(c+b+1)) :
    ∃ d, fib (3*k+3+2) = 2 * d + 1 := by
  have key : fib (3*k+3+2) = fib (3*k+3+1) + fib (3*k+3) := by
    rw [show 3*k+3+2 = 3*k+2+3 from by omega, f1,
        show 3*k+2+2 = 3*k+3+1 from by omega,
        show 3*k+2+1 = 3*k+3 from by omega]
  rw [key]
  cases Ho4 with
  | intro d hd => exact ⟨d + c + b + 1, by omega⟩
#print axioms g4
