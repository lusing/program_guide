module Tmp07t where

open import Data.Nat using (ℕ; zero; suc)

f : ℕ → ℕ
f zero = zero
f (suc n) with f n measured by n
... | m = m
