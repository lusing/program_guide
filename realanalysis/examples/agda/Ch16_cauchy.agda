-- Chapter 16: a Cauchy tail starts at a later index,
-- and the set {1,2,3} spans two steps from 1 to 3.
module Ch16_cauchy where

open import Data.Nat using (ℕ; suc; _+_; _<_)
open import Data.Nat.Properties using (n<1+n; <-trans)
open import Relation.Binary.PropositionalEquality using (_≡_; refl)

-- 下标还能再往后走，柯西条件里的 N 可以选得更晚。
index-strict : ∀ n → n < suc n
index-strict = n<1+n

-- 书上取 ε = 1/10 时，N = 11 已经落在尾部里，12 还在它后面。
tail-start : 10 < 11
tail-start = n<1+n 10

past-twelve : 11 < 12
past-twelve = n<1+n 11

-- {1,2,3} 的两端相差 2：1+2 = 3。
span : 1 + 2 ≡ 3
span = refl

-- 从 1 走到 3 要跨过两步，中间经过 2。
span-strict : 1 < 3
span-strict = <-trans (n<1+n 1) (n<1+n 2)
