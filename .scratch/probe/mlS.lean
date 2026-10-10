set_option linter.unusedVariables false
theorem tD (n : Nat) : True := by
  induction n with
  | zero => trivial
  | succ n' ih =>
      have hn0 : 0 < n' + 1 := by omega
      trivial
theorem tE : ∀ (n : Nat) (L : List Nat),
    (∀ x, x ∈ List.range n → x ∈ L) → n ≤ L.length := by
  intro n
  induction n with
  | zero => intro L _; exact Nat.zero_le _
  | succ n' ih =>
      intro L hsub
      have hn : n' ∈ L :=
        hsub n' (by rw [List.range_succ]
                    exact List.mem_append_right _ (List.mem_singleton.mpr rfl))
      have h2 := ih (L.erase n')
        (fun x hx =>
          have hxlt : x < n' := List.mem_range.mp hx
          (List.mem_erase_of_ne (fun he => by omega)).mpr
            (hsub x (by rw [List.range_succ]
                        exact List.mem_append_left _ hx)))
      rw [List.length_erase_of_mem hn] at h2
      have h3 : 0 < L.length := List.length_pos_of_mem hn
      omega
#print axioms tD
#print axioms tE
