set_option linter.unusedVariables false
set_option linter.unusedSimpArgs false

def divides (a b : Nat) : Prop := ∃ k, b = a * k

-- D: hk1 的 Or.inr 分支不用 omega
theorem tD : ∀ a b, divides a b → divides b a → a = b := by
  intro a b ⟨k1, h1⟩ ⟨k2, h2⟩
  cases a with
  | zero => rw [h1, Nat.zero_mul]
  | succ a' =>
      rw [h1] at h2
      have e0 : (a'+1) = (a'+1) * (k1 * k2) :=
        h2.trans (Nat.mul_assoc (a'+1) k1 k2)
      cases k1 with
      | zero => rw [Nat.zero_mul] at e0; omega
      | succ k1' =>
          cases k2 with
          | zero => rw [Nat.mul_zero] at e0; omega
          | succ k2' =>
              have hS : (a'+1) * 1 = (a'+1) * ((k1'+1) * (k2'+1)) :=
                (Nat.mul_one (a'+1)).trans e0
              have hP : 1 = (k1'+1) * (k2'+1) :=
                Nat.mul_left_cancel (Nat.succ_pos a') hS
              have e2 : (k1'+1) * (k2'+1) = k1' * (k2'+1) + (k2'+1) :=
                Nat.succ_mul k1' (k2'+1)
              have hLin : 1 = k1' * (k2'+1) + (k2'+1) := hP.trans e2
              have hT : k1' * (k2'+1) = 0 ∧ k2' = 0 := by omega
              have hk1 : k1' = 0 := by
                match Nat.mul_eq_zero.mp hT.1 with
                | Or.inl h => exact h
                | Or.inr h => exact absurd h (Nat.succ_ne_zero k2')
              rw [hk1, Nat.zero_add, Nat.mul_one] at h1
              exact h1.symm
#print axioms tD
