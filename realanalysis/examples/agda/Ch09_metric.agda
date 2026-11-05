-- Chapter 9: a two-point metric (the three axioms, by cases).
module Ch09_metric where

open import Data.Nat using (ℕ; zero; suc; _+_; _≤_; z≤n; s≤s)
open import Data.Nat.Properties using (m≤m+n; m≤n+m)
open import Relation.Binary.PropositionalEquality using (_≡_; refl)

data Pt : Set where
  a b : Pt

-- d(a,a)=d(b,b)=0, d(a,b)=d(b,a)=1.
d : Pt → Pt → ℕ
d a a = 0
d b b = 0
d a b = 1
d b a = 1

d-self : ∀ p → d p p ≡ 0
d-self a = refl
d-self b = refl

d-sym : ∀ p q → d p q ≡ d q p
d-sym a a = refl
d-sym a b = refl
d-sym b a = refl
d-sym b b = refl

d-triangle : ∀ p q r → d p q ≤ d p r + d r q
d-triangle a a a = z≤n
d-triangle a a b = z≤n
d-triangle a b a = m≤n+m 1 0
d-triangle a b b = m≤m+n 1 0
d-triangle b a a = m≤m+n 1 0
d-triangle b a b = m≤n+m 1 0
d-triangle b b a = z≤n
d-triangle b b b = z≤n

-- Neighborhood of a with radius 1 contains only a (the other point is at distance 1).
in-ball : Pt → Set
in-ball p = d a p ≤ 0

only-center : in-ball b → a ≡ b
only-center ()
