-- Chapter 7: injections, surjections, bijections on finite types.
module Ch07_bijections where

open import Data.Bool using (Bool; true; false)
open import Data.Unit using (⊤; tt)
open import Data.Empty using (⊥)
open import Data.Product using (Σ; _×_; _,_)
open import Relation.Binary.PropositionalEquality using (_≡_; refl; cong)

Injective : ∀ {A B : Set} → (A → B) → Set
Injective f = ∀ {x₁ x₂} → f x₁ ≡ f x₂ → x₁ ≡ x₂

Surjective : ∀ {A B : Set} → (A → B) → Set
Surjective {A = A} f = ∀ y → Σ A (λ x → f x ≡ y)

Bijective : ∀ {A B : Set} → (A → B) → Set
Bijective f = Injective f × Surjective f

-- Identity on Bool is bijective.
idB : Bool → Bool
idB b = b

idB-bij : Bijective idB
idB-bij = (λ { refl → refl }) , (λ y → y , refl)

-- Constant Bool → ⊤: surjective, not injective (book: {1,2}→{1}).
const⊤ : Bool → ⊤
const⊤ _ = tt

const⊤-surj : Surjective const⊤
const⊤-surj tt = true , refl

const⊤-not-inj : Injective const⊤ → ⊥
const⊤-not-inj h with h {true} {false} refl
... | ()

-- ⊤ → Bool, * ↦ true: injective, not surjective (book: {1}→{1,2}).
toTrue : ⊤ → Bool
toTrue _ = true

toTrue-inj : Injective toTrue
toTrue-inj {tt} {tt} refl = refl

toTrue-not-surj : Surjective toTrue → ⊥
toTrue-not-surj h with h false
... | tt , ()

-- Boolean negation is a bijection; inverse is itself.
notB : Bool → Bool
notB true  = false
notB false = true

notB-inv : ∀ b → notB (notB b) ≡ b
notB-inv true  = refl
notB-inv false = refl

notB-bij : Bijective notB
notB-bij = inj , surj
  where
  inj : Injective notB
  inj {true}  {true}  refl = refl
  inj {false} {false} refl = refl
  inj {true}  {false} ()
  inj {false} {true}  ()
  surj : Surjective notB
  surj true  = false , refl
  surj false = true  , refl

-- Composition.
_∘′_ : ∀ {A B C : Set} → (B → C) → (A → B) → (A → C)
(g ∘′ f) x = g (f x)

-- Bijection closed under composition.
bij-comp : ∀ {A B C} {f : A → B} {g : B → C} →
           Bijective f → Bijective g → Bijective (g ∘′ f)
bij-comp {f = f} {g = g} (fi , fs) (gi , gs) = inj , surj
  where
  inj : Injective (g ∘′ f)
  inj eq = fi (gi eq)
  surj : Surjective (g ∘′ f)
  surj z with gs z
  ... | (y , ey) with fs y
  ...   | (x , ex) = x , lemma
    where
    lemma : g (f x) ≡ z
    lemma rewrite ex = ey

-- Inverse composed with itself is identity (for notB).
notB-left-id : ∀ b → (notB ∘′ notB) b ≡ b
notB-left-id = notB-inv
