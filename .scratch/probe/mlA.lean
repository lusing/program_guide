set_option linter.unusedVariables false
set_option linter.unusedSimpArgs false

def divides (a b : Nat) : Prop := ∃ k, b = a * k

-- A: 只有 intro 模式 + cases + rw（无 omega/match-iff）
theorem tA : ∀ a b, divides a b → divides b a → a = b := by
  intro a b ⟨k1, h1⟩ ⟨k2, h2⟩
  cases a with
  | zero => rw [h1, Nat.zero_mul]
  | succ a' => rw [h1, Nat.zero_mul]  -- 假证明：只测公理来源
#print axioms tA
