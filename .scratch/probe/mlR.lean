set_option linter.unusedVariables false
set_option linter.unusedSimpArgs false
theorem range_pigeonhole : ∀ (n : Nat) (L : List Nat),
    (∀ x, x ∈ List.range n → x ∈ L) → n ≤ L.length := by
  intro n
  induction n with
  | zero => intro L _; exact Nat.zero_le _
  | succ n' ih =>
      intro L hsub
      have hn : n' ∈ L :=
        hsub n' (by rw [List.range_succ]
                    exact List.mem_append_right _ (List.mem_singleton.mpr rfl))
      have h1 : ∀ x, x ∈ List.range n' → x ∈ L.erase n' := by
        intro x hx
        have hxlt : x < n' := List.mem_range.mp hx
        exact (List.mem_erase_of_ne (fun he => by omega)).mpr
                (hsub x (by rw [List.range_succ]
                            exact List.mem_append_left _ hx))
      have h2 := ih (L.erase n') h1
      rw [List.length_erase_of_mem hn] at h2
      have h3 : 0 < L.length := List.length_pos_of_mem hn
      omega

#print axioms range_pigeonhole
