module Tmp07e where

open import Data.Nat using (ℕ; zero; suc)

mutual
  p : ℕ → ℕ
  p zero = zero
  p (suc n) = q (suc n)

  q : ℕ → ℕ
  q zero = suc zero
  q (suc n) = p (suc n)
