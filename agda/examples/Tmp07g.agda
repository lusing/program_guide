{-# OPTIONS --partial-definitions #-}

module Tmp07g where

open import Data.Nat using (ℕ; zero; suc)

f : ℕ → ℕ
f zero = zero
f (suc n) = f n
