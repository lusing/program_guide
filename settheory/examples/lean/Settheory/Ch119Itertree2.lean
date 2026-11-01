/- 第 119 章：有限目标选择策略与燃料终止证书。
   这里只检查六步数字表，不构造真实模型、超幂或无限迭代策略。 -/
inductive Result where
  | done | outOfFuel | illegal
  deriving DecidableEq, Repr

open Result

def cStrategy : Nat → Nat
  | 0 => 0
  | k + 1 => k

abbrev LegalTarget (k p : Nat) : Prop := p ≤ k ∧ p = cStrategy k

def runWith (strategy : Nat → Nat) : Nat → Nat → Result
  | 0, k => if 6 ≤ k then .done else .outOfFuel
  | fuel + 1, k =>
      if 6 ≤ k then .done
      else if LegalTarget k (strategy k) then runWith strategy fuel (k + 1)
      else .illegal

def badStrategy (_ : Nat) : Nat := 6

def scheduled : List Nat := (List.range 6).map cStrategy

theorem scheduled_is_alternating_chain :
    scheduled = [0, 0, 1, 2, 3, 4] := by decide

theorem comparison_terminates : runWith cStrategy 6 0 = done := by decide

theorem short_budget_is_detected : runWith cStrategy 5 0 = outOfFuel := by decide

theorem bad_target_is_detected : runWith badStrategy 6 0 = illegal := by decide

theorem every_scheduled_target_is_legal :
    ∀ k < 6, LegalTarget k (cStrategy k) := by decide
