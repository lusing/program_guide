------------------------------------------------------------------------
-- ex06 —— 自然变换、函子范畴与 Godement 积
-- 三书对位：贺伟《范畴论》1.3 /《高级范畴论》4.5–4.6 / Simmons 3.4–3.5
------------------------------------------------------------------------

open import Level using (Level; _⊔_; 0ℓ) renaming (suc to lsuc)
open import Data.List using (List; map; reverse; []; _∷_)
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
-- 自然变换

record NT {o ℓ o′ ℓ′} {C : Category o ℓ} {D : Category o′ ℓ′}
         (F G : Functor C D) : Set (o ⊔ ℓ ⊔ o′ ⊔ ℓ′) where
  field
    ncomp : ∀ a → Hom D (FObj F a) (FObj G a)
    nlaw : ∀ {a b} (f : Hom C a b)
         → comp D (FHom F f) (ncomp b) ≡ comp D (ncomp a) (FHom G f)

open NT

-- 自然性方块的读法：F f;η_b ≡ η_a;G f

------------------------------------------------------------------------
-- 垂直复合与恒等

vcomp : ∀ {o ℓ o′ ℓ′} {C : Category o ℓ} {D : Category o′ ℓ′}
          {F G H : Functor C D} → NT F G → NT G H → NT F H
vcomp {D = D} {F = F} {G = G} {H = H} α β = record
  { ncomp = λ a → comp D (ncomp α a) (ncomp β a)
  ; nlaw = λ f → begin
      comp D (FHom F f) (comp D (ncomp α _) (ncomp β _))
        ≡⟨ sym (assoc D (FHom F f) (ncomp α _) (ncomp β _)) ⟩
      comp D (comp D (FHom F f) (ncomp α _)) (ncomp β _)
        ≡⟨ cong (λ X → comp D X (ncomp β _)) (nlaw α f) ⟩
      comp D (comp D (ncomp α _) (FHom G f)) (ncomp β _)
        ≡⟨ assoc D (ncomp α _) (FHom G f) (ncomp β _) ⟩
      comp D (ncomp α _) (comp D (FHom G f) (ncomp β _))
        ≡⟨ cong (comp D (ncomp α _)) (nlaw β f) ⟩
      comp D (ncomp α _) (comp D (ncomp β _) (FHom H f))
        ≡⟨ sym (assoc D (ncomp α _) (ncomp β _) (FHom H f)) ⟩
      comp D (comp D (ncomp α _) (ncomp β _)) (FHom H f)
      ∎
  }

vid : ∀ {o ℓ o′ ℓ′} {C : Category o ℓ} {D : Category o′ ℓ′}
        {F : Functor C D} → NT F F
vid {D = D} {F = F} = record
  { ncomp = λ a → idn D
  ; nlaw = λ f → begin
      comp D (FHom F f) (idn D) ≡⟨ idR D (FHom F f) ⟩
      FHom F f                  ≡⟨ sym (idL D (FHom F f)) ⟩
      comp D (idn D) (FHom F f) ∎
  }

------------------------------------------------------------------------
-- NT 的相等：Agda 无证明无关性——分量相等（setoid 风格）
-- 这正是 agda-categories 库用 setoid 的原因（对照：Coq 需 PI 公理 +
-- 原始投影；Lean 结构 η + 内核 PI 免费）。

_≈NT_ : ∀ {o ℓ o′ ℓ′} {C : Category o ℓ} {D : Category o′ ℓ′}
          {F G : Functor C D} (α β : NT F G) → Set (o ⊔ ℓ′)
α ≈NT β = ∀ a → ncomp α a ≡ ncomp β a

vcomp-assoc : ∀ {o ℓ o′ ℓ′} {C : Category o ℓ} {D : Category o′ ℓ′}
                {F G H K : Functor C D} (α : NT F G) (β : NT G H) (γ : NT H K)
             → vcomp (vcomp α β) γ ≈NT vcomp α (vcomp β γ)
vcomp-assoc {D = D} α β γ a = assoc D _ _ _

vcomp-idR : ∀ {o ℓ o′ ℓ′} {C : Category o ℓ} {D : Category o′ ℓ′}
              {F G : Functor C D} (α : NT F G) → vcomp α vid ≈NT α
vcomp-idR {D = D} α a = idR D (ncomp α a)

vcomp-idL : ∀ {o ℓ o′ ℓ′} {C : Category o ℓ} {D : Category o′ ℓ′}
              {F G : Functor C D} (α : NT F G) → vcomp vid α ≈NT α
vcomp-idL {D = D} α a = idL D (ncomp α a)

------------------------------------------------------------------------
-- 函子复合与 Godement 积（水平复合）

compFun : ∀ {o ℓ o′ ℓ′ o″ ℓ″} {C : Category o ℓ} {D : Category o′ ℓ′}
            {E : Category o″ ℓ″} → Functor D E → Functor C D → Functor C E
compFun {C = C} {D = D} {E = E} G F = record
  { FObj = λ a → FObj G (FObj F a)
  ; FHom = λ f → FHom G (FHom F f)
  ; Fid = λ a → begin
      FHom G (FHom F (idn C {a})) ≡⟨ cong (FHom G) (Fid F a) ⟩
      FHom G (idn D {FObj F a})   ≡⟨ Fid G (FObj F a) ⟩
      idn E                       ∎
  ; Fcomp = λ f g → begin
      FHom G (FHom F (comp C f g))   ≡⟨ cong (FHom G) (Fcomp F f g) ⟩
      FHom G (comp D (FHom F f) (FHom F g)) ≡⟨ Fcomp G (FHom F f) (FHom F g) ⟩
      comp E (FHom G (FHom F f)) (FHom G (FHom F g)) ∎
  }

-- α : F ⇒ G（C→D 内），β : H ⇒ K（D→E 内）：
-- β ⋆ α : H∘F ⇒ K∘G，分量 (β ⋆ α)_a = H(α_a);β_{G a}
hcomp : ∀ {o ℓ o′ ℓ′ o″ ℓ″} {C : Category o ℓ} {D : Category o′ ℓ′}
          {E : Category o″ ℓ″} {F G : Functor C D} {H K : Functor D E}
        → NT F G → NT H K → NT (compFun H F) (compFun K G)
hcomp {D = D} {E = E} {F = F} {G = G} {H = H} {K = K} α β = record
  { ncomp = λ a → comp E (FHom H (ncomp α a)) (ncomp β (FObj G a))
  ; nlaw = λ f → begin
      comp E (FHom H (FHom F f)) (comp E (FHom H (ncomp α _)) (ncomp β (FObj G _)))
        ≡⟨ sym (assoc E (FHom H (FHom F f)) (FHom H (ncomp α _)) (ncomp β (FObj G _))) ⟩
      comp E (comp E (FHom H (FHom F f)) (FHom H (ncomp α _))) (ncomp β (FObj G _))
        ≡⟨ cong (λ X → comp E X (ncomp β (FObj G _))) (sym (Fcomp H (FHom F f) (ncomp α _))) ⟩
      comp E (FHom H (comp D (FHom F f) (ncomp α _))) (ncomp β (FObj G _))
        ≡⟨ cong (λ X → comp E (FHom H X) (ncomp β (FObj G _))) (nlaw α f) ⟩
      comp E (FHom H (comp D (ncomp α _) (FHom G f))) (ncomp β (FObj G _))
        ≡⟨ cong (λ X → comp E X (ncomp β (FObj G _))) (Fcomp H (ncomp α _) (FHom G f)) ⟩
      comp E (comp E (FHom H (ncomp α _)) (FHom H (FHom G f))) (ncomp β (FObj G _))
        ≡⟨ assoc E (FHom H (ncomp α _)) (FHom H (FHom G f)) (ncomp β (FObj G _)) ⟩
      comp E (FHom H (ncomp α _)) (comp E (FHom H (FHom G f)) (ncomp β (FObj G _)))
        ≡⟨ cong (comp E (FHom H (ncomp α _))) (nlaw β (FHom G f)) ⟩
      comp E (FHom H (ncomp α _)) (comp E (ncomp β (FObj G _)) (FHom K (FHom G f)))
        ≡⟨ sym (assoc E (FHom H (ncomp α _)) (ncomp β (FObj G _)) (FHom K (FHom G f))) ⟩
      comp E (comp E (FHom H (ncomp α _)) (ncomp β (FObj G _))) (FHom K (FHom G f))
      ∎
  }

------------------------------------------------------------------------
-- 具体例子：reverse 是 List 函子的自变换

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

open import Data.List using ([_]; _++_; _∷ʳ_)
open import Data.List.Properties using (map-++; unfold-reverse)

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

rev-map : ∀ {A B : Set} (f : A → B) (l : List A)
        → reverse (map f l) ≡ map f (reverse l)
rev-map f [] = refl
rev-map f (x ∷ l) = begin
  reverse (f x ∷ map f l)      ≡⟨ unfold-reverse (f x) (map f l) ⟩
  reverse (map f l) ∷ʳ f x     ≡⟨ cong (λ X → X ∷ʳ f x) (rev-map f l) ⟩
  map f (reverse l) ∷ʳ f x     ≡⟨ sym (map-++ f (reverse l) [ x ]) ⟩
  map f (reverse l ∷ʳ x)       ≡⟨ cong (map f) (sym (unfold-reverse x l)) ⟩
  map f (reverse (x ∷ l))      ∎

revNT : NT ListFun ListFun
revNT = record
  { ncomp = λ A → reverse {A = A}
  ; nlaw = λ f → funext (rev-map f)
  }

------------------------------------------------------------------------
-- 坑位速记：
-- 1. Agda 无证明无关性：NT 的 nlaw 字段类型依赖 ncomp——record
--    相等拿不到。定律以「分量相等」_≈NT_ 陈述（setoid 风格；
--    agda-categories 的现实路线）。Coq 要 PI+原始投影，Lean
--    结构 η+内核 PI 免费——三家三路线。
-- 2. vcomp 的 naturality 五步链在 ≡-Reasoning 里逐行可读；
--    每步 cong 的「洞」要精确到被替换的子项。
-- 3. compFun 的 Fid/Fcomp 是两条 cong 链——函子律逐层穿透。
-- 4. rev-map 的 stdlib 引理名按 2.3 对齐：reverse-++/map-++/
--    unfold-reverse；名字漂移时点式自证更稳。
------------------------------------------------------------------------
