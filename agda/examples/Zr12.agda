module Zr12 where
open import Data.Nat.Base using (ℕ; _+_)
open import Data.Nat.Tactic.RingSolver using (solve-∀)
open import Relation.Binary.PropositionalEquality using (_≡_; refl)
goal2 : (a b : ℕ) → a + b ≡ b + a
goal2 a b = solve-∀
