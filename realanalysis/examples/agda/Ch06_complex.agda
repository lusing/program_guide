-- Chapter 6: ℤ×ℤ as a discrete stand-in for ℂ, sample Cauchy–Schwarz gap.
module Ch06_complex where

open import Data.Product using (_×_; _,_; proj₁; proj₂)
open import Data.Integer as ℤ using (ℤ; +_; -_; _*_)
open import Data.Nat as ℕ using (ℕ; zero; suc)
open import Data.Nat.Properties using (m≤m+n)
open import Relation.Binary.PropositionalEquality using (_≡_; refl)

C : Set
C = ℤ × ℤ

cmul : C → C → C
cmul (a , b) (c , d) =
  ( a ℤ.* c ℤ.+ ℤ.- (b ℤ.* d)
  , a ℤ.* d ℤ.+ b ℤ.* c )

i : C
i = (+ 0 , + 1)

i-squared : cmul i i ≡ (+ 0 ℤ.+ ℤ.- (+ 1) , + 0 ℤ.+ + 0)
i-squared = refl

-- (1+2i)(3+4i) = −5 + 10i
mul-example :
  cmul (+ 1 , + 2) (+ 3 , + 4) ≡
    (+ 3 ℤ.+ ℤ.- (+ 8) , + 4 ℤ.+ + 6)
mul-example = refl

-- Sample vectors (3,4) and (1,2): ⟨u,v⟩² = 121, ‖u‖²‖v‖² = 125.
sample-inner : ℕ
sample-inner = 3 ℕ.* 1 ℕ.+ 4 ℕ.* 2

sample-nx : ℕ
sample-nx = 3 ℕ.* 3 ℕ.+ 4 ℕ.* 4

sample-ny : ℕ
sample-ny = 1 ℕ.* 1 ℕ.+ 2 ℕ.* 2

sample-gap : ℕ
sample-gap = sample-nx ℕ.* sample-ny ℕ.∸ sample-inner ℕ.* sample-inner

cs-sample : sample-inner ℕ.* sample-inner ℕ.≤ sample-nx ℕ.* sample-ny
cs-sample = m≤m+n (sample-inner ℕ.* sample-inner) sample-gap
