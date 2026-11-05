-- Chapter 12: nested bounds. 0 sits in both right endpoints' meet,
-- and each left endpoint is at most the next one.
module Ch12_heineborel where

open import Data.Nat using (ℕ; _≤_; _⊓_; suc; z≤n)
open import Data.Nat.Properties using (n≤1+n; m⊓n≤m; m⊓n≤n)
open import Data.Product using (_×_; _,_)

-- 定理 12.1 的有限版本：0 不超过两个右端点的较小者，
-- 所以 0 同时落在 [0,m] 和 [0,n] 里。
zero-in-inter : ∀ m n → 0 ≤ m ⊓ n
zero-in-inter m n = z≤n

-- 左端点可以逐项变大。上确界还在这些数的后面。
left-grows : ∀ n → n ≤ suc n
left-grows = n≤1+n

-- 交的右端点同时是原来两个右端点的下界。
inter-right : ∀ m n → m ⊓ n ≤ m × m ⊓ n ≤ n
inter-right m n = m⊓n≤m m n , m⊓n≤n m n
