/-
  第 121 章：原博弈与带隐藏坐标的有限辅助博弈。
  张三选 a，李四选 b，张三再选隐藏坐标 h；原收益是存在 h 使辅助收益为真。
  这里只验证有限策略提升、投影与保赢等式，不形式化 Martin--Steel。
-/

def auxiliaryPayoff (a b h : Bool) : Bool :=
  (a || !b) && (h == b)

def projectedPayoff (a b : Bool) : Bool :=
  auxiliaryPayoff a b false || auxiliaryPayoff a b true

def baseStrategyWins (a : Bool) : Bool :=
  projectedPayoff a false && projectedPayoff a true

def baseValue : Bool :=
  baseStrategyWins false || baseStrategyWins true

def auxiliaryValueFor (a : Bool) : Bool :=
  (auxiliaryPayoff a false false || auxiliaryPayoff a false true) &&
  (auxiliaryPayoff a true false || auxiliaryPayoff a true true)

def auxiliaryValue : Bool :=
  auxiliaryValueFor false || auxiliaryValueFor true

def liftedHiddenMove (b : Bool) : Bool := b

def liftedStrategyWins (b : Bool) : Bool :=
  auxiliaryPayoff true b (liftedHiddenMove b)

def pulledBackStrategyWins (b : Bool) : Bool :=
  projectedPayoff true b

theorem projection_rule (a b : Bool) :
    projectedPayoff a b =
      (auxiliaryPayoff a b false || auxiliaryPayoff a b true) := by
  rfl

theorem base_value_is_true : baseValue = true := by decide

theorem auxiliary_value_is_true : auxiliaryValue = true := by decide

theorem values_agree : baseValue = auxiliaryValue := by decide

theorem winning_first_move_lifts (b : Bool) :
    liftedStrategyWins b = true := by
  cases b <;> decide

theorem winning_auxiliary_strategy_pulls_back (b : Bool) :
    pulledBackStrategyWins b = true := by
  cases b <;> decide

theorem losing_first_move_has_no_hidden_rescue (h : Bool) :
    auxiliaryPayoff false true h = false := by
  cases h <;> decide

theorem projected_payoff_is_not_uniformly_won :
    baseStrategyWins false = false := by decide
