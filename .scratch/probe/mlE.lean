set_option linter.unusedVariables false
set_option linter.unusedSimpArgs false

-- E: 纯线性场景复刻 hT（无任何 ∃/match）
theorem tE (k1' k2' : Nat) (hLin : 1 = k1' * (k2'+1) + (k2'+1)) :
    k1' * (k2'+1) = 0 ∧ k2' = 0 := by omega
#print axioms tE
