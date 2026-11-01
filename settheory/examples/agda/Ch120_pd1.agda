module Ch120_pd1 where

open import Data.Bool using (Bool; false; true; not; if_then_else_; _∨_; _∧_)
open import Data.List using (List; []; _∷_; _++_)
open import Data.Nat using (ℕ; zero; suc)
open import Relation.Binary.PropositionalEquality using (_≡_; refl)

payoff : List Bool → Bool
payoff (_ ∷ b ∷ c ∷ _) = b ∧ c ∨ not b ∧ not c
payoff _ = false

value : ℕ → Bool → List Bool → Bool
value zero _ h = payoff h
value (suc fuel) even-turn h =
  if even-turn
  then value fuel false (h ++ false ∷ []) ∨
       value fuel false (h ++ true ∷ [])
  else value fuel true (h ++ false ∷ []) ∧
       value fuel true (h ++ true ∷ [])

certified-move : List Bool → Bool
certified-move [] = false
certified-move (_ ∷ b ∷ []) = b
certified-move _ = false

play : Bool → Bool → List Bool
play b d = certified-move [] ∷ b ∷ certified-move (false ∷ b ∷ []) ∷ d ∷ []

root-has-winning-value : value 4 true [] ≡ true
root-has-winning-value = refl

every-second-round-position-is-winning :
  (b : Bool) → value 2 true (false ∷ b ∷ []) ≡ true
every-second-round-position-is-winning false = refl
every-second-round-position-is-winning true = refl

open-strategy-wins : (b d : Bool) → payoff (play b d) ≡ true
open-strategy-wins false false = refl
open-strategy-wins false true = refl
open-strategy-wins true false = refl
open-strategy-wins true true = refl

losing-reply-is-visible : payoff (false ∷ true ∷ false ∷ false ∷ []) ≡ false
losing-reply-is-visible = refl
