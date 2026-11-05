-- Chapter 13: a gap between 0 and 2, and the piece count does not shrink.
module Ch13_perfect where

open import Data.Nat using (ℕ; _<_; _≤_; _+_)
open import Data.Nat.Properties using (n<1+n; m≤m+n)
open import Data.Product using (_×_; _,_)

-- 1 严格落在 0 和 2 之间。删掉中间一段之后，它不属于左边，也不属于右边。
gap : 0 < 1 × 1 < 2
gap = n<1+n 0 , n<1+n 1

-- 每一步把每个闭区间换成两个，段数不会变少：n ≤ n + n。
pieces-grow : ∀ n → n ≤ n + n
pieces-grow n = m≤m+n n n
