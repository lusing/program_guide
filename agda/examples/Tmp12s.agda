{-# OPTIONS --safe #-}
module Tmp12s where

open import Data.Empty using (⊥)
open import Data.Sum using (_⊎_)
open import Relation.Nullary using (¬_)

postulate
  LEM : ∀ {A : Set} → A ⊎ ¬ A
