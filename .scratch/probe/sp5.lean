def searchPre : (Nat → Nat) → Nat → Nat → Option Nat
  | _, _, 0 => none
  | f, n, k'+1 => if f k' == n then some k' else searchPre f n k'

-- notNone 完整版：同构归纳
theorem searchPre_notNone : ∀ f y x d,
    f x = y → x < d → searchPre f y d ≠ none := by
  intro f y x d hfx
  induction d with
  | zero => intro _ hlt; omega
  | succ d' ih =>
    intro hd hlt
    have h2 : (if f d' == y then some d' else searchPre f y d') = none := hd
    split at h2
    · exact Option.noConfusion h2
    · cases Nat.eq_dec d' x with
      | inl he =>
        subst d'
        rw [show (f x == y) = decide (f x = y) from rfl, decide_eq_true hfx] at h2
        exact Option.noConfusion h2
      | inr hne' =>
        exact ih h2 (by omega)
