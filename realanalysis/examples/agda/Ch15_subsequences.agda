-- Chapter 15: a subsequence index keeps moving forward,
-- and the even indices 2, 4 are two steps apart.
module Ch15_subsequences where

open import Data.Nat using (ℕ; suc; _<_)
open import Data.Nat.Properties using (n<1+n; <-trans)
open import Data.Product using (_×_; _,_)

-- 恒等下标就是序列自己这条子序列：n < n+1。
index-strict : ∀ n → n < suc n
index-strict = n<1+n

-- 偶数下标 2 严格小于 4。中间还隔着 3。
even-step : 2 < 4
even-step = <-trans (n<1+n 2) (n<1+n 3)
