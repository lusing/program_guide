module TmpPr22g where

open import Data.Nat.Base using (ℕ)

f : ℕ
f = g
  where
  g : ℕ
  g = 1

-- top-level forward reference test
h : ℕ
h = k

k : ℕ
k = 2
