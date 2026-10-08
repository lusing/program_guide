set_option linter.unusedVariables false
set_option linter.unusedSimpArgs false

def divides (a b : Nat) : Prop := ∃ k, b = a * k

-- B: 全骨架但分支全 trivially 关（omega 换 exact absurd）
theorem tB : ∀ a b, divides a b → divides b a → a = b := by
  intro a b ⟨k1, h1⟩ ⟨k2, h2⟩
  cases a with
  | zero => rw [h1, Nat.zero_mul]
  | succ a' =>
      cases k1 with
      | zero => exact absurd rfl (by omega)   -- 占位：不真，只测无 omega 主体
      | succ k1' => exact absurd rfl (by omega)
#print axioms tB
