module Tmp07m where

open import Data.Nat using (ℕ; zero; suc; _+_)
open import Data.List using (List; []; _∷_; foldr; map)

data Tree : Set where
  node : List Tree → Tree

sum : List ℕ → ℕ
sum = foldr _+_ zero

mutual
  size : Tree → ℕ
  size (node ts) = suc (sum (map size ts))

sizeList : List Tree → ℕ
sizeList [] = zero
sizeList (t ∷ ts) = size t + sizeList ts
