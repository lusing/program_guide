------------------------------------------------------------------------
-- ex07 —— 范畴的等价与同构
-- 三书对位：《高级范畴论》4.7 / Simmons 1.2.7（Pfn ≃ Set⊥）/ 贺伟 3.3 前置
------------------------------------------------------------------------

open import Level using (Level; _⊔_; 0ℓ) renaming (suc to lsuc)
open import Data.Unit using (⊤; tt)
open import Data.List using (List; map; [_]; []; _∷_)
open import Data.Product using (Σ; _×_; _,_; proj₁; proj₂)
open import Relation.Binary.PropositionalEquality as Eq using (_≡_; refl; cong)
open Eq.≡-Reasoning

postulate
  funext : ∀ {ℓ ℓ′} {A : Set ℓ} {B : Set ℓ′}
             {f g : A → B} → (∀ x → f x ≡ g x) → f ≡ g

------------------------------------------------------------------------

record Category (o ℓ : Level) : Set (lsuc (o ⊔ ℓ)) where
  field
    Obj : Set o
    Hom : Obj → Obj → Set ℓ
    idn : ∀ {a} → Hom a a
    comp : ∀ {a b c} → Hom a b → Hom b c → Hom a c
    idL : ∀ {a b} (f : Hom a b) → comp (idn {a}) f ≡ f
    idR : ∀ {a b} (f : Hom a b) → comp f (idn {b}) ≡ f
    assoc : ∀ {a b c d} (f : Hom a b) (g : Hom b c) (h : Hom c d)
          → comp (comp f g) h ≡ comp f (comp g h)

open Category

record Functor {o ℓ o′ ℓ′} (C : Category o ℓ) (D : Category o′ ℓ′)
       : Set (o ⊔ ℓ ⊔ o′ ⊔ ℓ′) where
  field
    FObj : Obj C → Obj D
    FHom : ∀ {a b} → Hom C a b → Hom D (FObj a) (FObj b)
    Fid : ∀ a → FHom (idn C {a}) ≡ idn D {FObj a}
    Fcomp : ∀ {a b c} (f : Hom C a b) (g : Hom C b c)
          → FHom (comp C f g) ≡ comp D (FHom f) (FHom g)

open Functor

------------------------------------------------------------------------
-- 忠实 / 满 / 本质满

Faithful : ∀ {o ℓ o′ ℓ′} {C : Category o ℓ} {D : Category o′ ℓ′}
           → Functor C D → Set (o ⊔ ℓ ⊔ ℓ′)
Faithful {C = C} F = ∀ (a b : Obj C) (f g : Hom C a b) → FHom F f ≡ FHom F g → f ≡ g

Full : ∀ {o ℓ o′ ℓ′} {C : Category o ℓ} {D : Category o′ ℓ′}
       → Functor C D → Set (o ⊔ ℓ ⊔ ℓ′)
Full {C = C} {D = D} F = ∀ (a b : Obj C) (h : Hom D (FObj F a) (FObj F b))
       → Σ (Hom C a b) λ f → FHom F f ≡ h

FullyFaithful : ∀ {o ℓ o′ ℓ′} {C : Category o ℓ} {D : Category o′ ℓ′}
                → Functor C D → Set (o ⊔ ℓ ⊔ ℓ′)
FullyFaithful F = Faithful F × Full F

-- 本质满：每个 D 对象收到来自某个像的态射（完整版要求同构，
-- 这里保持可扩充的占位结构）
EssentiallySurj : ∀ {o ℓ o′ ℓ′} {C : Category o ℓ} {D : Category o′ ℓ′}
                  → Functor C D → Set (o ⊔ o′ ⊔ ℓ′)
EssentiallySurj {C = C} {D = D} F = ∀ (d : Obj D) → Σ (Obj C) λ c → Hom D (FObj F c) d

------------------------------------------------------------------------
-- 恒等函子全忠实且本质满（定义即证）

idFun : ∀ {o ℓ} (C : Category o ℓ) → Functor C C
idFun C = record
  { FObj = λ a → a
  ; FHom = λ f → f
  ; Fid = λ a → refl
  ; Fcomp = λ f g → refl
  }

id-ff : ∀ {o ℓ} (C : Category o ℓ) → FullyFaithful (idFun C)
id-ff C = (λ a b f g H → H) , (λ a b h → h , refl)

id-es : ∀ {o ℓ} (C : Category o ℓ) → EssentiallySurj (idFun C)
id-es C d = d , idn C

------------------------------------------------------------------------
-- List 函子忠实（TyCat）

TyCat : Category (lsuc 0ℓ) 0ℓ
TyCat = record
  { Obj = Set
  ; Hom = λ A B → A → B
  ; idn = λ x → x
  ; comp = λ f g x → g (f x)
  ; idL = λ f → refl
  ; idR = λ f → refl
  ; assoc = λ f g h → refl
  }

map-id-pointwise : ∀ {A : Set} (l : List A) → map (λ x → x) l ≡ l
map-id-pointwise [] = refl
map-id-pointwise (x ∷ l) = cong (x ∷_) (map-id-pointwise l)

mc-pointwise : ∀ {A B C : Set} (f : A → B) (g : B → C) (l : List A)
             → map (λ x → g (f x)) l ≡ map g (map f l)
mc-pointwise f g [] = refl
mc-pointwise f g (x ∷ l) = cong (g (f x) ∷_) (mc-pointwise f g l)

ListFun : Functor TyCat TyCat
ListFun = record
  { FObj = List
  ; FHom = map
  ; Fid = λ A → funext map-id-pointwise
  ; Fcomp = λ f g → funext (mc-pointwise f g)
  }

-- 忠实：map f ≡ map g → f ≡ g——单点列表当探针
list-faithful : Faithful ListFun
list-faithful a b f g H = funext pointwise
  where
    pointwise : ∀ x → f x ≡ g x
    pointwise x = cong first (cong (λ k → k [ x ]) H)
      where
        first : List b → b
        first [] = f x        -- 不可达分支（[f x] 必非空），任意兜底
        first (y ∷ _) = y
