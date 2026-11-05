-- Chapter 20: 5 is still below 6, two halves make 2,
-- and |3 + (-1)| = 2 stays below 3 + 1 = 4.
module Ch20_summary where

open import Data.Nat using (ℕ; _+_; _<_)
open import Data.Nat.Properties using (n<1+n; <-trans)
open import Relation.Binary.PropositionalEquality using (_≡_; refl)

-- 阿基米德性质的一个见证：5 的后面还有自然数。
past-five : 5 < 6
past-five = n<1+n 5

-- 两份 1 加回去是 2，对应把误差预算拆成两半再拼上。
halves : 1 + 1 ≡ 2
halves = refl

-- |3 + (-1)| = 2，|3| + |-1| = 4，2 < 4。
two-lt-four : 2 < 4
two-lt-four = <-trans (n<1+n 2) (n<1+n 3)
