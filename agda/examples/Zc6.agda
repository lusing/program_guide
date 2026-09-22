{-# OPTIONS --cubical --safe #-}
module Zc6 where
open import Agda.Builtin.Cubical.Path using (_≡_)
open import Agda.Primitive.Cubical renaming (primINeg to ~_)
open import Agda.Builtin.Nat using (Nat; _+_)
refl : {A : Set} {x : A} → x ≡ x
refl {x = x} = λ i → x
sym : {A : Set} {x y : A} → x ≡ y → y ≡ x
sym p = λ i → p (~ i)
p : 2 + 3 ≡ 5
p = refl
q : 5 ≡ 2 + 3
q = sym p
