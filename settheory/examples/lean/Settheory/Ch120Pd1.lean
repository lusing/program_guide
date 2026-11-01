/- 第 120 章：四步有限开博弈、逆向归纳与显式稳赢策略。
   这里只证明有限前缀博弈，不声称证明无限投影决定性。 -/

def payoff (h : List Bool) : Bool :=
  match h with
  | _ :: b :: c :: _ => b == c
  | _ => false

def value : Nat → List Bool → Bool
  | 0, h => payoff h
  | fuel + 1, h =>
      if h.length % 2 = 0 then
        value fuel (h ++ [false]) || value fuel (h ++ [true])
      else
        value fuel (h ++ [false]) && value fuel (h ++ [true])

def certifiedMove (h : List Bool) : Bool :=
  match h with
  | [] => false
  | [_, b] => b
  | _ => false

def play (b d : Bool) : List Bool :=
  [certifiedMove [], b, certifiedMove [false, b], d]

theorem root_has_winning_value : value 4 [] = true := by decide

theorem every_second_round_position_is_winning :
    ∀ b : Bool, value 2 [false, b] = true := by decide

theorem open_strategy_wins (b d : Bool) : payoff (play b d) = true := by
  cases b <;> cases d <;> decide

theorem losing_reply_is_visible : payoff [false, true, false, false] = false := by
  decide
