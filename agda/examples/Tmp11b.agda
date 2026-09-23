{-# OPTIONS --rewriting #-}
module Tmp11b where

open import Relation.Binary.PropositionalEquality using (_≡_; refl; sym)
open import Data.Nat using (ℕ; suc; zero; _+_)

postulate P : ℕ → Set
postulate p₀ : P 0

t₄ : (eq : 1 ≡ 0) → P 1
t₄ eq = (rewrite eq in p₀)
