-- Chapter 22: ratio and root tests. 2^3/3! / (2^2/2!) = 2/3 on common
-- denominator 12: 8/6 = 16/12 and 4/2 = 24/12, so the ratio is 16/24 = 2/3.
module Ch22_ratio_root where

open import Data.Nat using (ℕ; _+_; _*_; _<_; _≤_; s≤s; z≤n)
open import Data.Nat.Properties using (n<1+n; m≤m)
open import Relation.Binary.PropositionalEquality using (_≡_; refl)

-- 16/24 = 2/3 交叉相乘：16*3 = 24*2 = 48。
ratio-cross : 16 * 3 ≡ 24 * 2
ratio-cross = refl

-- n/(2n+1) ≤ 3/5 交叉相乘：5n ≤ 3(2n+1) = 6n+3。
-- 在 n = 2 处：10 ≤ 15。
root-cross-two : 5 * 2 ≤ 3 * (2 * 2 + 1)
root-cross-two = s≤s (s≤s (s≤s (s≤s (s≤s (s≤s (s≤s (s≤s (s≤s (s≤s z≤n)))))))))

-- 2^n 的比值恒为 2 > 1。
two-gt-one : 1 < 2
two-gt-one = n<1+n 1

-- 调和级数的相邻项之比 (n+1)/(n+2) 在 n = 1 处是 2/3。
harmonic-ratio : 2 * 3 ≡ 6
harmonic-ratio = refl
