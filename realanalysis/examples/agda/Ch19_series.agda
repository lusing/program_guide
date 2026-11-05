-- Chapter 19: the geometric partial sum 4+2+1 = 7 is still short of 8,
-- and the harmonic pieces 12+6+4+3 = 25 already pass 24.
module Ch19_series where

open import Data.Nat using (ℕ; _+_; _*_; _∸_; _<_)
open import Data.Nat.Properties using (n<1+n)
open import Relation.Binary.PropositionalEquality using (_≡_; refl)

-- 公分母 4：1 + 1/2 + 1/4 对应 4 + 2 + 1 = 7，而 2 = 8/4。
partial : 4 + 2 + 1 ≡ 7
partial = refl

seven-lt-eight : 7 < 8
seven-lt-eight = n<1+n 7

-- 公分母 12：1 + 1/2 + 1/3 + 1/4 对应 12 + 6 + 4 + 3 = 25 > 24 = 2*12。
harmonic-parts : 12 + 6 + 4 + 3 ≡ 25
harmonic-parts = refl

two-as-twelfths : 2 * 12 ≡ 24
two-as-twelfths = refl

twentyfour-lt : 24 < 25
twentyfour-lt = n<1+n 24

-- 面积 2 = 6/3，拿走 2/3 还剩 4/3。再换成第九份：12/9 拿走 4/9 还剩 8/9。
remain : 6 ∸ 2 ≡ 4
remain = refl

next-remain : 12 ∸ 4 ≡ 8
next-remain = refl
