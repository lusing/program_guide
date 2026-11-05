-- Chapter 21: three ones make 3, 5 is below 6, and two ones make 2.
module Ch21_wrapup where

open import Data.Nat using (_+_; _<_)
open import Data.Nat.Properties using (n<1+n)
open import Relation.Binary.PropositionalEquality using (_≡_; refl)

-- 三个 1 相加是 3，对应三个三分之一的分子。
thirds : 1 + 1 + 1 ≡ 3
thirds = refl

-- 5 的后面还有自然数。
past-five : 5 < 6
past-five = n<1+n 5

-- 两份 1 加回去是 2。
halves : 1 + 1 ≡ 2
halves = refl
