-- 第 17 章 完备布尔代数：分离性条件

module Ch17_boolean where

open import Data.Bool using (Bool; true; false; not)
open import Data.Product using (_×_; _,_; ∃)
open import Relation.Binary.PropositionalEquality using (_≡_; refl)
open import Relation.Nullary using (¬_)
open import Data.Unit using (⊤; tt)

record Poset : Set₁ where
  field
    Carrier : Set
    _≤_     : Carrier → Carrier → Carrier → Set → Set → Set
-- 太复杂——直接用简单类型

infix 4 _⊥_

_⊥_ : {A : Set} → (A → A → Bool) → A → A → Bool
_⊥_ = λ f x y → f x y

-- 分离性 (17.20)：p ⊥ q 时下方有 r ≤ p 且 r ⊥ q
-- 分离性条件：p ⊥ q 时下方有 r ≤ p 且 r ⊥ q
Separative : (A : Set) → (A → A → Bool) → (A → A → Bool) → Set
Separative A _⊑_ _⊥ₚ_ =
  (p q : A) → _⊥ₚ_ p q ≡ true →
    ∃ (λ r → (_⊑_ r p ≡ true) × (_⊥ₚ_ r q ≡ true))
  where
   open import Data.Product

-- 具体例：⊥ 恒假时分离性空洞成立
bool-sep : Separative Bool (λ _ _ → true) (λ _ _ → false)
bool-sep p q ()
