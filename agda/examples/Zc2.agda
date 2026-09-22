{-# OPTIONS --cubical --safe #-}
module Zc2 where
open import Agda.Builtin.Cubical.Path using (_≡_)
open import Agda.Primitive.Cubical renaming (primTransp to transp)
open import Agda.Builtin.Nat using (Nat; _+_)
refl : {A : Set} {x : A} → x ≡ x
refl {x = x} = λ i → x
p : 2 + 3 ≡ 5
p = refl
transport : {A B : Set} → A ≡ B → A → B
transport q x = transp (λ i → q i) i0 x
check : transport p 5 ≡ 5
check = refl
