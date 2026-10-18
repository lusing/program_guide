------------------------------------------------------------------------
-- ex09 —— 积与余积
-- 三书对位：贺伟《范畴论》2.3 /《高级范畴论》3.2 / Simmons 2.5
------------------------------------------------------------------------

open import Level using (Level; _⊔_; 0ℓ) renaming (suc to lsuc)
open import Data.Product using (Σ; _×_; _,_; proj₁; proj₂)
open import Relation.Binary.PropositionalEquality as Eq using (_≡_; refl; cong; trans; sym)
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

opposite : ∀ {o ℓ} → Category o ℓ → Category o ℓ
opposite C = record
  { Obj = Obj C; Hom = λ a b → Hom C b a
  ; idn = idn C; comp = λ f g → comp C g f
  ; idL = λ f → idR C f; idR = λ f → idL C f
  ; assoc = λ f g h → sym (assoc C h g f)
  }

------------------------------------------------------------------------
-- 泛性质（存在 + 唯一）

IsProduct : ∀ {o ℓ} (C : Category o ℓ) (a b p : Obj C)
            (p1 : Hom C p a) (p2 : Hom C p b) → Set (o ⊔ ℓ)
IsProduct C a b p p1 p2 =
  ∀ (c : Obj C) (f : Hom C c a) (g : Hom C c b) →
    Σ (Hom C c p) λ h →
      (comp C h p1 ≡ f × comp C h p2 ≡ g)
        × (∀ h' → comp C h' p1 ≡ f → comp C h' p2 ≡ g → h' ≡ h)

-- 余积 = 反范畴里的积（对象次序掉头）
IsCoproduct : ∀ {o ℓ} (C : Category o ℓ) (a b q : Obj C)
              (i1 : Hom C a q) (i2 : Hom C b q) → Set (o ⊔ ℓ)
IsCoproduct C a b q i1 i2 = IsProduct (opposite C) b a q i2 i1

------------------------------------------------------------------------
-- 同构箭头与「积唯一到同构」

record IsoArrow {o ℓ} (C : Category o ℓ) (a b : Obj C) (f : Hom C a b)
       : Set (o ⊔ ℓ) where
  field
    iinv : Hom C b a
    ilaw1 : comp C f iinv ≡ idn C {a}
    ilaw2 : comp C iinv f ≡ idn C {b}

open IsoArrow

product-unique-iso :
  ∀ {o ℓ} {C : Category o ℓ} {a b P Q : Obj C}
    {p1 : Hom C P a} {p2 : Hom C P b} {q1 : Hom C Q a} {q2 : Hom C Q b}
  → IsProduct C a b P p1 p2 → IsProduct C a b Q q1 q2
  → Σ (Hom C P Q) λ f → IsoArrow C P Q f
product-unique-iso {C = C} {P = P} {Q = Q} {p1 = p1} {p2 = p2}
                   {q1 = q1} {q2 = q2} HP HQ =
  let
    k , (k1 , k2) , kuniq = HQ P p1 p2     -- k : P→Q
    h , (h1 , h2) , huniq = HP Q q1 q2     -- h : Q→P
    n , (_ , _) , nuniq = HP P p1 p2       -- P 自身的中介
    m , (_ , _) , muniq = HQ Q q1 q2       -- Q 自身的中介
    Hkh : comp C k h ≡ n
    Hkh = nuniq (comp C k h)
            (trans (assoc C k h p1) (trans (cong (comp C k) h1) k1))
            (trans (assoc C k h p2) (trans (cong (comp C k) h2) k2))
    HidP : idn C {P} ≡ n
    HidP = nuniq (idn C) (idL C p1) (idL C p2)
    Hhk : comp C h k ≡ m
    Hhk = muniq (comp C h k)
            (trans (assoc C h k q1) (trans (cong (comp C h) k1) h1))
            (trans (assoc C h k q2) (trans (cong (comp C h) k2) h2))
    HidQ : idn C {Q} ≡ m
    HidQ = muniq (idn C) (idL C q1) (idL C q2)
  in k , record
         { iinv = h
         ; ilaw1 = begin comp C k h ≡⟨ Hkh ⟩ n ≡⟨ sym HidP ⟩ idn C ∎
         ; ilaw2 = begin comp C h k ≡⟨ Hhk ⟩ m ≡⟨ sym HidQ ⟩ idn C ∎
         }

------------------------------------------------------------------------
-- TyCat 里：积 = 笛卡尔积（Σ 的 η 让配对唯一性几乎免费）

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

tyProduct : ∀ (A B : Set) → IsProduct TyCat A B (A × B) proj₁ proj₂
tyProduct A B c f g = (λ x → f x , g x) , (refl , refl) , uniq
  where
    uniq : ∀ h' → comp TyCat h' proj₁ ≡ f → comp TyCat h' proj₂ ≡ g
         → h' ≡ (λ x → f x , g x)
    uniq h' e1 e2 = funext (λ x → begin
      h' x                              ≡⟨⟩
      (proj₁ (h' x) , proj₂ (h' x))     ≡⟨ cong (λ k → k x , proj₂ (h' x)) e1 ⟩
      (f x , proj₂ (h' x))              ≡⟨ cong (λ k → f x , k) (cong (λ k → k x) e2) ⟩
      (f x , g x)                       ∎)

------------------------------------------------------------------------
-- 坑位速记：
-- 1. where 块不能用模式绑定（k , (k1 , k2) , kuniq = ...）——
--    换 let 表达式（Agda 的 let 支持模式）。
-- 2. Σ 的 η 是定义性的：h' x 与 (proj₁ (h' x) , proj₂ (h' x))
--    defeq——配对唯一性只剩两条 cong（Coq 里要 destruct 满配对）。
-- 3. 泛性质的「唯一」子句带三参数（h' + 两个方程），trans 链按
--    assoc → cong → 投影律 的次序摆。
-- 4. IsCoproduct 的对象次序：opposite 后 Hom a b = Hom C b a，
--    (i2, i1) 对掉。
------------------------------------------------------------------------
