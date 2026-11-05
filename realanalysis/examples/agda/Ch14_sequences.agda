-- Chapter 14: the index past 1/ε, and a square that has not shrunk.
module Ch14_sequences where

open import Data.Nat using (ℕ; _<_; _≤_; _*_)
open import Data.Nat.Properties using (n<1+n; m≤n*m)

-- 10 < 11。取 ε = 1/10 时，下标 11 已经落在 1/ε 的后面。
index-past : 10 < 11
index-past = n<1+n 10

-- 4 ≤ 4·4。平方从这里开始只会被更大的下标拉得更远。
square-bound : 4 ≤ 4 * 4
square-bound = m≤n*m 4 4
