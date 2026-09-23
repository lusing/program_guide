{-# OPTIONS --cubical #-}
module Tmp17c where

open import Agda.Builtin.Cubical.Path using (_≡_)
open import Level using (Level; _⊔_)

refl : ∀ {a : Level} {A : Set a} {x : A} → x ≡ x
refl {x = x} i = x
open import Data.Nat.Base using (ℕ; zero; suc; _+_)

funExt : ∀ {a b : Level} {A : Set a} {B : A → Set b}
         {f g : (x : A) → B x} → ((x : A) → f x ≡ g x) → f ≡ g
funExt {f = f} {g = g} h i x = h x i

cong : ∀ {a b : Level} {A : Set a} {B : Set b} (f : A → B) {x y : A} → x ≡ y → f x ≡ f y
cong f p i = f (p i)

n+0≡n : ∀ n → n + 0 ≡ n
n+0≡n zero    = refl
n+0≡n (suc n) = cong suc (n+0≡n n)

f₁ f₂ : ℕ → ℕ
f₁ = λ n → n + 0
f₂ = λ n → n

demo : f₁ ≡ f₂
demo = funExt n+0≡n
