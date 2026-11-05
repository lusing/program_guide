-- Chapter 11: a finite bound is never the last index,
-- and two points are covered by two neighborhoods.
module Ch11_compact where

open import Data.Empty using (⊥)
open import Data.Nat using (ℕ; _<_; _≤_; suc)
open import Data.Nat.Properties using (n<1+n; 1+n≰n)
open import Data.Bool using (Bool; true; false)
open import Data.Product using (_×_; _,_)
open import Relation.Binary.PropositionalEquality using (_≡_; refl)
open import Relation.Nullary.Negation using (contradiction)

-- 定理 11.5：任何有限的 N 外面还有更大的下标。
-- a + 1/(2N) 就落在第 N 个区间的左边。
past-bound : ∀ (n : ℕ) → n < suc n
past-bound = n<1+n

not-inside-last : ∀ (n : ℕ) → suc n ≤ n → n < suc n → ⊥
not-inside-last n h _ = contradiction h (1+n≰n)

-- 两点集的开覆盖：每个点用自己的邻域。两个邻域就是有限子覆盖。
data Pt : Set where
  p q : Pt

holds : Pt → Pt → Bool
holds p p = true
holds q q = true
holds p q = false
holds q p = false

p-covered : holds p p ≡ true
p-covered = refl

q-covered : holds q q ≡ true
q-covered = refl

-- 两个邻域都用上，两点就都被盖住。有限集的子覆盖至多这么长。
both : holds p p ≡ true × holds q q ≡ true
both = p-covered , q-covered
