------------------------------------------------------------------------
-- ex05 —— 函子
-- 三书对位：贺伟《范畴论》1.2 /《高级范畴论》4.1–4.3 / Simmons 3.1–3.3
------------------------------------------------------------------------

open import Level using (Level; _⊔_; 0ℓ) renaming (suc to lsuc)
open import Data.Unit using (⊤; tt)
open import Data.Nat using (ℕ)
open import Data.Fin using (Fin)
open import Data.List using (List; map; []; _∷_)
open import Relation.Binary.PropositionalEquality as Eq using (_≡_; refl; cong; sym)
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

------------------------------------------------------------------------
-- 函子

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
-- 例 1：恒等函子与常值函子

idFun : ∀ {o ℓ} (C : Category o ℓ) → Functor C C
idFun C = record
  { FObj = λ a → a
  ; FHom = λ f → f
  ; Fid = λ a → refl
  ; Fcomp = λ f g → refl
  }

OneCat : Category 0ℓ 0ℓ
OneCat = record
  { Obj = ⊤
  ; Hom = λ _ _ → ⊤
  ; idn = tt
  ; comp = λ _ _ → tt
  ; idL = λ _ → refl
  ; idR = λ _ → refl
  ; assoc = λ _ _ _ → refl
  }

constFun : ∀ {o ℓ} (C : Category o ℓ) → Functor C OneCat
constFun C = record
  { FObj = λ _ → tt
  ; FHom = λ _ → tt
  ; Fid = λ a → refl
  ; Fcomp = λ f g → refl
  }

------------------------------------------------------------------------
-- 例 2：List 函子（TyCat 上的自函子）

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

-- 函子定律按点式包装（直接给出点式归纳版；函数级相等留在字段里做）
listFun : Functor TyCat TyCat
listFun = record
  { FObj = List
  ; FHom = map
  ; Fid = λ a → funext (λ l → map-id-pointwise l)
  ; Fcomp = λ f g → funext (λ l → mc-pointwise f g l)
  }

------------------------------------------------------------------------
-- 例 3：hom-函子 Hom(a, -) : C → TyCat
-- 函子定律逐条就是范畴定律的点式版

homFun : (C : Category 0ℓ 0ℓ) (a : Obj C) → Functor C TyCat
homFun C a = record
  { FObj = λ b → Hom C a b
  ; FHom = λ f g → comp C g f
  ; Fid = λ b → funext (idR C)                -- g;id ≡ g 点式
  ; Fcomp = λ f g → funext (λ h → sym (assoc C h f g))
  }

-- 逆变 = 反范畴上的协变
opposite : ∀ {o ℓ} → Category o ℓ → Category o ℓ
opposite C = record
  { Obj = Obj C; Hom = λ a b → Hom C b a
  ; idn = idn C; comp = λ f g → comp C g f
  ; idL = λ f → idR C f; idR = λ f → idL C f
  ; assoc = λ f g h → sym (assoc C h g f)
  }

homFunContra : (C : Category 0ℓ 0ℓ) (b : Obj C)
             → Functor (opposite C) TyCat
homFunContra C b = homFun (opposite C) b

------------------------------------------------------------------------
-- 函子保交换图

F-preserves-square :
  ∀ {o ℓ o′ ℓ′} {C : Category o ℓ} {D : Category o′ ℓ′} (F : Functor C D)
    {a b c e : Obj C} (f : Hom C a b) (h : Hom C b e) (g : Hom C a c) (k : Hom C c e)
  → comp C f h ≡ comp C g k
  → comp D (FHom F f) (FHom F h) ≡ comp D (FHom F g) (FHom F k)
F-preserves-square {C = C} {D = D} F f h g k sq =
  begin
    comp D (FHom F f) (FHom F h)   ≡⟨ sym (Fcomp F f h) ⟩
    FHom F (comp C f h)            ≡⟨ cong (FHom F) sq ⟩
    FHom F (comp C g k)            ≡⟨ Fcomp F g k ⟩
    comp D (FHom F g) (FHom F k)
  ∎

------------------------------------------------------------------------
-- 坑位速记：
-- 1. map 律的点式版自证（归纳）比翻 stdlib 引理名稳——名字/方向
--    随版本漂（*-suc 那课）。
-- 2. homFun 的 Fid/Fcomp 用 funext 包「范畴定律的点式版」——
--    这是 Yoneda（08 章）一切免费的根源。
-- 3. TyCat 的 Obj = Set（0 层），homFun 的源范畴钉 Category 0ℓ 0ℓ
--    对齐宇宙；高一层就错位。
-- 4. Functor record 带四个 level 参数：{o ℓ o′ ℓ′}——跨范畴构造
--    的宇宙账从这一章开始要精打细算。
------------------------------------------------------------------------
