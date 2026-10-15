module Ch66_topic where
open import Data.Nat using (ℕ)
open import Data.Bool using (Bool; true; false; not; _∧_; _∨_)
open import Relation.Binary.PropositionalEquality using (_≡_; refl)
w : not (true ∧ not true) ≡ false
w = refl
