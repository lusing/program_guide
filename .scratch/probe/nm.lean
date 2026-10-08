set_option linter.unusedVariables false
def congN (n a b : Nat) : Prop :=
  ∃ k, a + k * n = b ∨ b + k * n = a

theorem congN_normal : ∀ n a b,
    congN n a b ↔ ∃ k1 k2, a + k1 * n = b + k2 * n := by
  intro n a b
  constructor
  · intro h
    match h with
    | ⟨k, Or.inl h⟩ => exact ⟨k, 0, by omega⟩
    | ⟨k, Or.inr h⟩ => exact ⟨0, k, by omega⟩
  · intro h
    match h with
    | ⟨k1, k2, hk⟩ =>
      match Nat.lt_trichotomy k1 k2 with
      | .inl hlt =>
        have hle : k1 * n ≤ k2 * n := Nat.mul_le_mul_right _ (by omega)
        have e0 : k1 * n + (k2 - k1) * n = k2 * n := by
          have h1 : (k1 + (k2 - k1)) * n = k1 * n + (k2 - k1) * n :=
            Nat.add_mul k1 (k2 - k1) n
          have hj : k1 + (k2 - k1) = k2 := by omega
          rw [hj] at h1
          exact h1.symm
        exact ⟨k2 - k1, Or.inr (by omega)⟩
      | .inr (Or.inl heq) =>
        rw [heq] at hk
        exact ⟨0, Or.inl (by omega)⟩
      | .inr (Or.inr hgt) =>
        have hle : k2 * n ≤ k1 * n := Nat.mul_le_mul_right _ (by omega)
        have e0 : k2 * n + (k1 - k2) * n = k1 * n := by
          have h1 : (k2 + (k1 - k2)) * n = k2 * n + (k1 - k2) * n :=
            Nat.add_mul k2 (k1 - k2) n
          have hj : k2 + (k1 - k2) = k1 := by omega
          rw [hj] at h1
          exact h1.symm
        exact ⟨k1 - k2, Or.inl (by omega)⟩


#print axioms congN_normal
