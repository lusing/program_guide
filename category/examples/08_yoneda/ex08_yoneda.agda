------------------------------------------------------------------------
-- ex08 —— Yoneda 引理与可表函子
-- 三书对位：贺伟《范畴论》1.6 /《高级范畴论》4.3 / Simmons 3.5
--
-- Nat(Hom(a,-), F) ≅ F a：
--   φ(X)  := X_a(id_a)         （在 id 处取样）
--   ψ(x)_b(g) := F g(x)        （沿 g 搬运取样）
-- 一个方向用 Fid 白送；另一个方向恰是自然性在 id 处的特例。
------------------------------------------------------------------------

open import Level using (Level; _⊔_; 0ℓ) renaming (suc to lsuc)
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

record NT {o ℓ o′ ℓ′} {C : Category o ℓ} {D : Category o′ ℓ′}
         (F G : Functor C D) : Set (o ⊔ ℓ ⊔ o′ ⊔ ℓ′) where
  field
    ncomp : ∀ a → Hom D (FObj F a) (FObj G a)
    nlaw : ∀ {a b} (f : Hom C a b)
         → comp D (FHom F f) (ncomp b) ≡ comp D (ncomp a) (FHom G f)

open NT

_≈NT_ : ∀ {o ℓ o′ ℓ′} {C : Category o ℓ} {D : Category o′ ℓ′}
          {F G : Functor C D} (α β : NT F G) → Set (o ⊔ ℓ′)
α ≈NT β = ∀ a → ncomp α a ≡ ncomp β a

------------------------------------------------------------------------
-- 舞台：TyCat 与 hom-函子

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

homFun : (C : Category 0ℓ 0ℓ) (a : Obj C) → Functor C TyCat
homFun C a = record
  { FObj = λ b → Hom C a b
  ; FHom = λ f g → comp C g f
  ; Fid = λ b → funext (idR C)
  ; Fcomp = λ f g → funext (λ h → sym (assoc C h f g))
  }

------------------------------------------------------------------------
-- Yoneda 的两个映射

yonedaTo : ∀ {C : Category 0ℓ 0ℓ} {F : Functor C TyCat} {a : Obj C}
           → FObj F a → NT (homFun C a) F
yonedaTo {C = C} {F = F} {a = a} x = record
  { ncomp = λ b g → FHom F g x
  ; nlaw = λ f → funext (λ (g : Hom C a _) → begin
      FHom F (comp C g f) x            ≡⟨ cong (λ k → k x) (Fcomp F g f) ⟩
      FHom F f (FHom F g x)            ∎)
  }

yonedaFrom : ∀ {C : Category 0ℓ 0ℓ} {F : Functor C TyCat} {a : Obj C}
             → NT (homFun C a) F → FObj F a
yonedaFrom {C = C} {a = a} X = ncomp X a (idn C {a})

-- 往返 1：φ(ψ(x)) = x —— Fid 白送
yoneda-round1 : ∀ {C : Category 0ℓ 0ℓ} {F : Functor C TyCat} {a : Obj C}
                (x : FObj F a)
                → yonedaFrom {F = F} {a = a} (yonedaTo {F = F} {a = a} x) ≡ x
yoneda-round1 {C = C} {F = F} {a = a} x =
  cong (λ k → k x) (Fid F a)   -- LHS 展开 = FHom F (idn) x；RHS β→ x

-- 往返 2：ψ(φ(X)) ≈NT X —— 自然性在 id 处的特例
yoneda-round2 : ∀ {C : Category 0ℓ 0ℓ} {F : Functor C TyCat} {a : Obj C}
                (X : NT (homFun C a) F) → yonedaTo (yonedaFrom X) ≈NT X
yoneda-round2 {C = C} {F = F} {a = a} X b = funext (λ g → begin
  FHom F g (ncomp X a (idn C {a}))     ≡⟨ sym (natpoint g) ⟩
  ncomp X b g                          ∎)
  where
    -- X 的自然性方程作用到 id_a 上取样
    natpoint : (g : Hom C a b) → ncomp X b g ≡ FHom F g (ncomp X a (idn C {a}))
    natpoint g = begin
      ncomp X b g                          ≡⟨ cong (ncomp X b) (sym (idL C g)) ⟩
      ncomp X b (comp C (idn C {a}) g)    ≡⟨ cong (λ k → k (idn C {a})) (nlaw X g) ⟩
      FHom F g (ncomp X a (idn C {a}))    ∎

------------------------------------------------------------------------
-- 可表函子（贺伟 1.6）：F 可表 ⟺ F ≅ Hom(a, -)。
-- 取 F := homFun C a 本身：Nat(Hom a, Hom a) ≅ Hom C a a——
-- hom-函子的自变换 = 中对象的自态射，「对象由泛态射决定」。

------------------------------------------------------------------------
-- 坑位速记：
-- 1. yonedaTo 的 naturality：Fcomp 的反方向（采样点被函子搬运）。
-- 2. yoneda-round2 的 natpoint：把自然性方程（函数相等）用
--    cong (λ k → k id) 取样 + idL 换向——教科书「拆 g = id;g」。
-- 3. record 级往返 2 用 ≈NT（setoid）；Lean 版给出完整 record 相等。
-- 4. yonedaFrom X = ncomp X _ (idn _)：下划线让 Agda 从 NT 类型推 a。
------------------------------------------------------------------------
