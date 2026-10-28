-- 第 80 章：有符号整数端点的精确二分归纳。
-- 第 n 层的公共分母是 2^n，但不直接做除法：端点翻倍后，
-- 旧中点的分子恰为 lo+hi；target = 2·(2^n)^2 同步放大四倍。
module Ch80_reals where

open import Data.Bool using (Bool; true; false; if_then_else_)
open import Data.Integer using (ℤ; +_; _+_; _*_; _<?_)
open import Data.Nat using (ℕ; zero; suc)
open import Data.Product using (_×_; _,_)
open import Relation.Nullary using (yes; no)
open import Relation.Binary.PropositionalEquality using (_≡_; refl)

Ivl : Set
Ivl = ℤ × ℤ

-- positive=true 求正平方根：mid²<target 时把 lo 推到 mid；
-- positive=false 求负平方根，方向相反。target 始终为 2·scale²。
bisect : Bool → ℕ → ℤ → ℤ → ℤ → Ivl
bisect _ zero _ lo hi = (lo , hi)
bisect positive (suc n) target lo hi
  with (lo + hi) * (lo + hi) <? (+ 4) * target
... | yes _ = if positive
              then bisect positive n ((+ 4) * target) (lo + hi) ((+ 2) * hi)
              else bisect positive n ((+ 4) * target) ((+ 2) * lo) (lo + hi)
... | no _ = if positive
             then bisect positive n ((+ 4) * target) ((+ 2) * lo) (lo + hi)
             else bisect positive n ((+ 4) * target) (lo + hi) ((+ 2) * hi)

sqrt2-interval : ℕ → Ivl
sqrt2-interval n = bisect true n (+ 2) (+ 1) (+ 2)

neg-sqrt2-interval : ℕ → Ivl
neg-sqrt2-interval n = bisect false n (+ 2) (ℤ.negsuc 1) (ℤ.negsuc 0)

-- 三步后分母均为 8：√2∈[11/8,12/8]，-√2∈[-12/8,-11/8]。
sqrt2-three : sqrt2-interval 3 ≡ ((+ 11) , (+ 12))
sqrt2-three = refl

neg-sqrt2-three : neg-sqrt2-interval 3 ≡ (ℤ.negsuc 11 , ℤ.negsuc 10)
neg-sqrt2-three = refl
