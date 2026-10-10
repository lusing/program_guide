-- match 是否清除 scrutinee 的直接证据
theorem t (h : ∃ k : Nat, k = k) (x y : Nat) (he : x = y) : y = x := by
  match h with
  | ⟨k', h'⟩ =>
    -- 尝试引用 h：若已清除会报 unknown identifier
    exact absurd rfl (fun hx => (Nat.noConfusion hx))?? .
