{-# OPTIONS --cubical #-}
module Zc4 where
open import Agda.Builtin.Cubical.Path using (_≡_)
open import Agda.Builtin.Nat using (Nat; _+_)
refl : {A : Set} {x : A} → x ≡ x
refl {x = x} = λ i → x
uip : (p : 2 + 3 ≡ 5) → p ≡ refl
uip refl = refl
