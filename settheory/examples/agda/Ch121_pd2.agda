module Ch121_pd2 where

open import Data.Bool using (Bool; false; true; not; _∧_; _∨_)
open import Relation.Binary.PropositionalEquality using (_≡_; refl)

-- 第 121 章：张三选 a、隐藏回答 h，李四选 b。
-- 只检查有限投影与策略保赢，不声称形式化无限投影决定性。

eqb : Bool → Bool → Bool
eqb b c = (b ∧ c) ∨ (not b ∧ not c)

auxiliary-payoff : Bool → Bool → Bool → Bool
auxiliary-payoff a b h = (a ∨ not b) ∧ eqb h b

projected-payoff : Bool → Bool → Bool
projected-payoff a b = auxiliary-payoff a b false ∨ auxiliary-payoff a b true

base-strategy-wins : Bool → Bool
base-strategy-wins a = projected-payoff a false ∧ projected-payoff a true

base-value : Bool
base-value = base-strategy-wins false ∨ base-strategy-wins true

auxiliary-value-for : Bool → Bool
auxiliary-value-for a =
  (auxiliary-payoff a false false ∨ auxiliary-payoff a false true) ∧
  (auxiliary-payoff a true false ∨ auxiliary-payoff a true true)

auxiliary-value : Bool
auxiliary-value = auxiliary-value-for false ∨ auxiliary-value-for true

lifted-hidden-move : Bool → Bool
lifted-hidden-move b = b

lifted-strategy-wins : Bool → Bool
lifted-strategy-wins b = auxiliary-payoff true b (lifted-hidden-move b)

pulled-back-strategy-wins : Bool → Bool
pulled-back-strategy-wins b = projected-payoff true b

projection-rule : (a b : Bool) →
  projected-payoff a b ≡
    (auxiliary-payoff a b false ∨ auxiliary-payoff a b true)
projection-rule a b = refl

base-value-is-true : base-value ≡ true
base-value-is-true = refl

auxiliary-value-is-true : auxiliary-value ≡ true
auxiliary-value-is-true = refl

values-agree : base-value ≡ auxiliary-value
values-agree = refl

winning-first-move-lifts : (b : Bool) → lifted-strategy-wins b ≡ true
winning-first-move-lifts false = refl
winning-first-move-lifts true = refl

winning-auxiliary-strategy-pulls-back :
  (b : Bool) → pulled-back-strategy-wins b ≡ true
winning-auxiliary-strategy-pulls-back false = refl
winning-auxiliary-strategy-pulls-back true = refl

losing-first-move-has-no-hidden-rescue :
  (h : Bool) → auxiliary-payoff false true h ≡ false
losing-first-move-has-no-hidden-rescue false = refl
losing-first-move-has-no-hidden-rescue true = refl

projected-payoff-is-not-uniformly-won : base-strategy-wins false ≡ false
projected-payoff-is-not-uniformly-won = refl
