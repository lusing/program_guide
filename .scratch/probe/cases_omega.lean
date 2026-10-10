def fib : Nat → Nat
  | 0 => 0
  | 1 => 1
  | (k+2) => fib (k+1) + fib k

theorem g1 (k c b d : Nat)
    (hd : fib (3*k+3+1) = 2*d+1)
    (He3 : fib (3*k+3) = 2*(c+b+1)) :
    fib (3*k+3+1) + fib (3*k+3) = 2*(d+c+b+1)+1 := by omega
#print axioms g1

theorem g2 (k c b d : Nat)
    (Ho4 : ∃ d, fib (3*k+3+1) = 2*d+1)
    (He3 : fib (3*k+3) = 2*(c+b+1)) :
    ∃ e, fib (3*k+3+1) + fib (3*k+3) = 2*e+1 := by
  cases Ho4 with
  | intro d hd => exact ⟨d+c+b+1, by omega⟩
#print axioms g2
