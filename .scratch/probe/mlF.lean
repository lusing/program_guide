theorem tF1 (k1' k2' : Nat) (hLin : 1 = k1' * (k2'+1) + (k2'+1)) :
    k2' = 0 := by omega
theorem tF2 (k1' k2' : Nat) (hLin : 1 = k1' * (k2'+1) + (k2'+1)) :
    k1' * (k2'+1) = 0 := by omega
theorem tF3 (k1' k2' : Nat) (hLin : 1 = k1' * (k2'+1) + (k2'+1)) :
    k1' * (k2'+1) = 0 ∧ k2' = 0 := by
  constructor <;> omega
theorem tF4 (a b : Nat) (h : a + b = 0) : a = 0 ∧ b = 0 := by omega
theorem tF5 (a b : Nat) (h : a + b = 0) : a = 0 := by omega
#print axioms tF1
#print axioms tF2
#print axioms tF3
#print axioms tF4
#print axioms tF5
