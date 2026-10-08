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

theorem congN_eqrel : ∀ n, eqrel (congN n) := by
  intro n
  constructor
  · intro x; exact ⟨0, Or.inl (by omega)⟩
  constructor
  · intro x y h
    match h with
    | ⟨k, Or.inl h'⟩ => exact ⟨k, Or.inr h'⟩
    | ⟨k, Or.inr h'⟩ => exact ⟨k, Or.inl h'⟩
  · -- 传递：同向直接拼、混合走正规形（match 保留 ∃ 原假设——omega 前必须 clear）
    intro x y z hy hz
    match hy with
    | ⟨k, Or.inl h1⟩ =>
      match hz with
      | ⟨j, Or.inl h2⟩ =>
        clear hy hz
        refine ⟨k + j, Or.inl ?_⟩
        have e0 : (k + j) * n = k * n + j * n := Nat.add_mul k j n
        omega
      | ⟨j, Or.inr h2⟩ =>
        clear hy hz
        apply (congN_normal n x z).mpr
        match Nat.lt_trichotomy k j with
        | .inl _ =>
          refine ⟨0, j - k, ?_⟩
          have e0 : (k + (j - k)) * n = k * n + (j - k) * n :=
            Nat.add_mul k (j - k) n
          have hj : k + (j - k) = j := by omega
          rw [hj] at e0
          omega
        | .inr (Or.inl heq) =>
          refine ⟨0, 0, ?_⟩
          rw [heq] at h1
          omega
        | .inr (Or.inr _) =>
          refine ⟨k - j, 0, ?_⟩
          have e0 : (j + (k - j)) * n = j * n + (k - j) * n :=
            Nat.add_mul j (k - j) n
          have hj : j + (k - j) = k := by omega
          rw [hj] at e0
          omega
    | ⟨k, Or.inr h1⟩ =>
      match hz with
      | ⟨j, Or.inl h2⟩ =>
        clear hy hz
        apply (congN_normal n x z).mpr
        refine ⟨j, k, ?_⟩
        omega
      | ⟨j, Or.inr h2⟩ =>
        clear hy hz
        refine ⟨k + j, Or.inr ?_⟩
        have e0 : (k + j) * n = k * n + j * n := Nat.add_mul k j n
        omega


#print axioms congN_eqrel
#print axioms congN_normal
