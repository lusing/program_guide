{-# OPTIONS --cubical #-}
module Zc13 where
open import Data.Nat.Base using (ℕ; _+_)
open import Relation.Binary.PropositionalEquality using (_≡_; refl; sym; trans; cong)
open import Data.List.Base using (List; _++_)
open import Data.List.Properties using (++-comm)
goal : ∀ (x y z : ℕ) → (x + y) + z ≡ x + (y + z)
goal = {!!}
