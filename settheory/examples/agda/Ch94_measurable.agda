-- 第 94 章：有限超滤皆主的构造性证明。
module Ch94_measurable where

open import Data.Bool using (Bool; true; false; _∧_; not)
open import Data.Empty using (⊥; ⊥-elim)
open import Data.List using (List; []; _∷_)
open import Data.Product using (Σ; _×_; _,_)
open import Data.Sum using (_⊎_; inj₁; inj₂)
open import Relation.Binary.PropositionalEquality using (_≡_; refl)

module FiniteUF {A : Set} (eqb : A → A → Bool)
  (eqb-eq : ∀ {x y} → eqb x y ≡ true → x ≡ y)
  (eqb-refl : ∀ x → eqb x x ≡ true) where

  Sub : Set
  Sub = A → Bool

  empty full : Sub
  empty _ = false
  full _ = true

  inter : Sub → Sub → Sub
  comp : Sub → Sub
  inter s t x = s x ∧ t x
  comp s x = not (s x)

  single : A → Sub
  single a x = eqb a x

  record Ultrafilter (U : Sub → Set) : Set where
    field
      empty-not : U empty → ⊥
      full-in : U full
      inter-in : ∀ {s t} → U s → U t → U (inter s t)
      upward : ∀ {s t} → U s → (∀ x → s x ≡ true → t x ≡ true) → U t
      decide : ∀ s → U s ⊎ U (comp s)

  open Ultrafilter

  bool-no : false ≡ true → ⊥
  bool-no ()

  no-both : ∀ {U} → Ultrafilter U → ∀ {s} → U s → U (comp s) → ⊥
  no-both {U} H {s} Us Ucs =
    empty-not H (upward H (inter-in H Us Ucs) bad)
    where
      bad : ∀ x → inter s (comp s) x ≡ true → empty x ≡ true
      bad x hx with s x
      ... | true = ⊥-elim (bool-no hx)
      ... | false = ⊥-elim (bool-no hx)

  principal-of-single : ∀ {U} → Ultrafilter U → ∀ {a} → U (single a) →
    ∀ s → (U s → s a ≡ true) × (s a ≡ true → U s)
  principal-of-single {U} H {a} Ha s = forward , backward
    where
      forward : U s → s a ≡ true
      forward Us with s a in eq
      ... | true = refl
      ... | false = ⊥-elim (no-both H Us (upward H Ha smaller))
        where
          smaller : ∀ x → single a x ≡ true → comp s x ≡ true
          smaller x hx with eqb-eq hx
          ... | refl rewrite eq = refl
      backward : s a ≡ true → U s
      backward sa = upward H Ha (λ x hx → aux x hx)
        where
          aux : ∀ x → single a x ≡ true → s x ≡ true
          aux x hx with eqb-eq hx
          ... | refl = sa

  data In (x : A) : List A → Set where
    here : ∀ {xs} → In x (x ∷ xs)
    there : ∀ {y xs} → In x xs → In x (y ∷ xs)

  complements : List A → Sub
  complements [] = full
  complements (a ∷ xs) = inter (comp (single a)) (complements xs)

  complements-false : ∀ xs {x} → In x xs → complements xs x ≡ false
  complements-false (a ∷ xs) here rewrite eqb-refl a = refl
  complements-false (a ∷ xs) {x} (there p)
    rewrite complements-false xs {x} p with eqb a x
  ... | false = refl
  ... | true = refl

  find-singleton : ∀ {U} → Ultrafilter U → ∀ xs →
    (Σ A (λ a → In a xs × U (single a))) ⊎ U (complements xs)
  find-singleton H [] = inj₂ (full-in H)
  find-singleton {U} H (a ∷ xs) with decide H (single a)
  ... | inj₁ Ha = inj₁ (a , here , Ha)
  ... | inj₂ Hca with find-singleton H xs
  ...   | inj₁ (b , p , Hb) = inj₁ (b , there p , Hb)
  ...   | inj₂ Hrest = inj₂ (inter-in H Hca Hrest)

  theorem : ∀ {U} → Ultrafilter U → ∀ xs → (∀ x → In x xs) →
    Σ A (λ a → ∀ s → (U s → s a ≡ true) × (s a ≡ true → U s))
  theorem {U} H xs cover with find-singleton H xs
  ... | inj₁ (a , _ , Ha) = a , principal-of-single H Ha
  ... | inj₂ HC = ⊥-elim (empty-not H (upward H HC bad))
    where
      bad : ∀ x → complements xs x ≡ true → empty x ≡ true
      bad x hx rewrite complements-false xs (cover x) = ⊥-elim (bool-no hx)
