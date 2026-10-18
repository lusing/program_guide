------------------------------------------------------------------------
-- ex12 —— 子对象、商对象与射影对象（贺伟 1.5 / 1.7）
-- 四个零假设定理：终点出发皆单（1.5.13）、始对象射影（1.7.6）、
-- 射影的收缩封闭（1.7.7）、满射的核对是等价关系（1.5.15）。
------------------------------------------------------------------------

open import Level using (Level; 0ℓ; _⊔_) renaming (suc to lsuc)
open import Data.Bool using (Bool; true; false)
open import Data.Product using (Σ; _×_; _,_; proj₁; proj₂)
open import Relation.Binary.PropositionalEquality as Eq
  using (_≡_; refl; cong; sym; trans)
open Eq.≡-Reasoning

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

Epi : ∀ {o ℓ} (C : Category o ℓ) (a b : Obj C) → Hom C a b → Set (o ⊔ ℓ)
Epi C a b f = ∀ c (g h : Hom C b c) → comp C f g ≡ comp C f h → g ≡ h

Mono : ∀ {o ℓ} (C : Category o ℓ) (a b : Obj C) → Hom C a b → Set (o ⊔ ℓ)
Mono C a b f = ∀ c (g h : Hom C c a) → comp C g f ≡ comp C h f → g ≡ h

Terminal : ∀ {o ℓ} (C : Category o ℓ) (t : Obj C) → Set (o ⊔ ℓ)
Terminal C t = ∀ a → Σ (Hom C a t) (λ f → ∀ g → g ≡ f)

Initial : ∀ {o ℓ} (C : Category o ℓ) (i : Obj C) → Set (o ⊔ ℓ)
Initial C i = ∀ a → Σ (Hom C i a) (λ f → ∀ g → g ≡ f)

-- 命题 1.5.13：终对象出发的箭头都是单
terminal-arrow-mono : ∀ {o ℓ} (C : Category o ℓ) (t : Obj C) →
  Terminal C t → ∀ a (f : Hom C t a) → Mono C t a f
terminal-arrow-mono C t Ht a f c g h _ =
  let u , Hu = Ht c in
  trans (Hu g) (sym (Hu h))

-- 命题 1.7.6：始对象是射影对象（提升唯一存在，连满性都不用）
Projective : ∀ {o ℓ} (C : Category o ℓ) (p : Obj C) → Set (o ⊔ ℓ)
Projective C p = ∀ a b (e : Hom C a b) → Epi C a b e →
  (f : Hom C p b) → Σ (Hom C p a) (λ g → f ≡ comp C g e)

initial-projective : ∀ {o ℓ} (C : Category o ℓ) (i : Obj C) →
  Initial C i → Projective C i
initial-projective C i Hi a b e He f =
  let u , _   = Hi a in
  let v , Hv  = Hi b in
  u , trans (Hv f) (sym (Hv (comp C u e)))

-- 命题 1.7.7：射影对象的收缩仍是射影对象
RetractOf : ∀ {o ℓ} (C : Category o ℓ) (r p : Obj C) → Set ℓ
RetractOf C r p = Σ (Hom C r p) (λ i →
  Σ (Hom C p r) (λ rr → comp C i rr ≡ idn C {r}))

retract-projective : ∀ {o ℓ} (C : Category o ℓ) (p r : Obj C) →
  Projective C p → RetractOf C r p → Projective C r
retract-projective C p r Hp (i , rr , Hrr) a b e He f =
  comp C i g , stitched
  where
  lift : Σ (Hom C p a) (λ gg → comp C rr f ≡ comp C gg e)
  lift = Hp a b e He (comp C rr f)
  g : Hom C p a
  g = proj₁ lift
  Hg : comp C rr f ≡ comp C g e
  Hg = proj₂ lift
  stitched : f ≡ comp C (comp C i g) e
  stitched = begin
    f                        ≡⟨ sym (idL C f) ⟩
    comp C (idn C) f         ≡⟨ cong (λ w → comp C w f) (sym Hrr) ⟩
    comp C (comp C i rr) f   ≡⟨ assoc C i rr f ⟩
    comp C i (comp C rr f)   ≡⟨ cong (comp C i) Hg ⟩
    comp C i (comp C g e)    ≡⟨ sym (assoc C i g e) ⟩
    comp C (comp C i g) e    ∎

-- 例 1.5.15 的核对：e := fst 在 bool×bool 上诱导等价关系
eqb : Bool → Bool → Bool          -- stdlib 2.3 的 Data.Bool 不导 _==_，自造
eqb false false = true
eqb false true  = false
eqb true  false = false
eqb true  true  = true

kpair : Bool × Bool → Bool × Bool → Bool
kpair x y = eqb (proj₁ x) (proj₁ y)

kpair-refl : ∀ x → kpair x x ≡ true
kpair-refl (false , _) = refl
kpair-refl (true  , _) = refl

kpair-sym : ∀ x y → kpair x y ≡ true → kpair y x ≡ true
kpair-sym (false , _) (false , _) _  = refl
kpair-sym (true  , _) (true  , _) _  = refl
kpair-sym (false , _) (true  , _) ()
kpair-sym (true  , _) (false , _) ()

kpair-trans : ∀ x y z → kpair x y ≡ true → kpair y z ≡ true → kpair x z ≡ true
kpair-trans (false , _) (false , _) (false , _) _  _  = refl
kpair-trans (false , _) (false , _) (true  , _) _  ()
kpair-trans (false , _) (true  , _)  _        () _
kpair-trans (true  , _) (false , _)  _        () _
kpair-trans (true  , _) (true  , _)  (false , _) _  ()
kpair-trans (true  , _) (true  , _)  (true  , _) _  _  = refl
