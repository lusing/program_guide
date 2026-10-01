----------------------------------------------------------------
-- 20 泛等公理 —— Agda 侧（公理化版本，账目与 Coq 版一致）
----------------------------------------------------------------

open import Data.Bool using (Bool; true; false; not)
open import Data.Product using (_×_; _,_; Σ; proj₁)
open import Function using (_∘_; id)
open import Relation.Binary.PropositionalEquality using (_≡_; refl; cong; sym; trans; subst)

-- ---- 等价：函数 + 两侧收缩 ----
record IsEquiv {A B : Set} (f : A → B) : Set where
  field
    inv : B → A
    retr : ∀ b → f (inv b) ≡ b
    sec : ∀ a → inv (f a) ≡ a
open IsEquiv public

Equiv : Set → Set → Set
Equiv A B = Σ (A → B) IsEquiv

-- ---- 公理：泛等（Agda 侧以 postulate 记账） ----
postulate
  ua : ∀ {A B : Set} → Equiv A B → A ≡ B
  transport-ua : ∀ {A B : Set} (e : Equiv A B) (u : A)
              → subst (λ X → X) (ua e) u ≡ proj₁ e u


-- id→equiv：不用公理（J 造）
id→equiv : ∀ {A B : Set} → A ≡ B → Equiv A B
id→equiv {A} refl = (id , record { inv = id ; retr = λ _ → refl ; sec = λ _ → refl })

-- ---- 实测：Bool 的非平凡自等价给出非平凡道路 ----
not-eq : Equiv Bool Bool
not-eq = (not , record { inv = not ; retr = not∘not≡id ; sec = not∘not≡id })
  where
    not∘not≡id : ∀ b → not (not b) ≡ b
    not∘not≡id true = refl
    not∘not≡id false = refl

not-path : Bool ≡ Bool
not-path = ua not-eq

-- 沿 not-path 搬运 = 逐点取反（β 公理给出）
_ : subst (λ X → X) (ua not-eq) true ≡ false
_ = transport-ua not-eq true
