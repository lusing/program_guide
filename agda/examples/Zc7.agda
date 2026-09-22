{-# OPTIONS --cubical --safe #-}
module Zc7 where
open import Agda.Builtin.Cubical.Path using (_≡_)
open import Agda.Builtin.Cubical.Glue using (primGlue; pathToEquiv; _≃_)
open import Agda.Primitive.Cubical
  renaming (primINeg to ~_; primIMax to _∨_; primTransp to transp)
open import Agda.Builtin.Sigma using (Σ; _,_; fst; snd)
open import Agda.Builtin.Unit using (⊤; tt)
open import Agda.Builtin.Bool using (Bool; true; false)
refl : {A : Set} {x : A} → x ≡ x
refl {x = x} = λ i → x
ua : {A B : Set} → A ≃ B → A ≡ B
ua {A = A} {B = B} e i =
  primGlue B
    (λ { (i = i0) → A ; (i = i1) → B })
    (λ { (i = i0) → e ; (i = i1) → pathToEquiv (λ i → B) })
B̂ : Set
B̂ = Σ ⊤ λ _ → Bool
swap : Bool → B̂
swap b = tt , b
boolPath : Bool ≡ B̂
boolPath = ua (swap , tt)
