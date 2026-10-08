def fib : Nat → Nat
  | 0 => 0
  | 1 => 1
  | (k+2) => fib (k+1) + fib k

theorem fib_step (n : Nat) : fib (n+3) = fib (n+2) + fib (n+1) := rfl

-- 书只证 F_{3n} 偶；机器必须三合一（偶、奇、奇）一起归纳
theorem fib_triple : ∀ n,
    (∃ a, fib (3 * n) = 2 * a)
    ∧ (∃ b, fib (3 * n + 1) = 2 * b + 1)
    ∧ (∃ c, fib (3 * n + 2) = 2 * c + 1) := by
  intro n
  induction n with
  | zero => exact ⟨⟨0, rfl⟩, ⟨0, rfl⟩, ⟨0, rfl⟩⟩
  | succ k ih =>
    cases ih with
    | intro Ha hbc =>
      cases hbc with
      | intro Hb Hc =>
        cases Ha with
        | intro a hac =>
          cases Hb with
          | intro b hbc2 =>
            cases Hc with
            | intro c hcc =>
              rw [Nat.mul_succ]
              have He3 : fib (3*k+3) = 2 * (c + b + 1) := by
                rw [fib_step]; omega
              have Ho4 : ∃ d, fib (3*k+3+1) = 2 * d + 1 := by
                rw [show 3*k+3+1 = 3*k+1+3 from by omega, fib_step,
                    show 3*k+1+2 = 3*k+3 from by omega,
                    show 3*k+1+1 = 3*k+2 from by omega]
                exact ⟨c + b + 1 + c, by omega⟩
              have Ho5 : ∃ d, fib (3*k+3+2) = 2 * d + 1 := by
                refine ⟨?_, ?_⟩
                · rw [show 3*k+3+2 = 3*k+2+3 from by omega, fib_step,
                    show 3*k+2+2 = 3*k+3+1 from by omega,
                    show 3*k+2+1 = 3*k+3 from by omega]
                  cases Ho4 with
                  | intro d hd => exact ⟨d + c + b + 1, by omega⟩
              exact ⟨⟨c + b + 1, He3⟩, Ho4, Ho5⟩

theorem fib_3n : ∀ n, ∃ a, fib (3 * n) = 2 * a := fun n =>
  (fib_triple n).1


#print axioms fib_triple
