------------------------------------------------------------------------
-- ex03 —— 特殊态射与特殊对象
-- 三书对位：贺伟《范畴论》1.4 /《高级范畴论》第 2 章 / Simmons 2.2
------------------------------------------------------------------------

open import Level using (Level; _⊔_; 0ℓ) renaming (suc to lsuc)
open import Data.Unit using (⊤; tt)
open import Data.Nat using (ℕ)
open import Data.Fin using (Fin; zero; suc)
open import Data.Product using (Σ; _×_; _,_)
open import Relation.Binary.PropositionalEquality as Eq using (_≡_; refl; cong; sym; trans)
open Eq.≡-Reasoning

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

-- 外延公理入账（Agda 不可证；stdlib 在 Axiom.Extensionality 有同款）
postulate
  funext : ∀ {ℓ ℓ′} {A : Set ℓ} {B : Set ℓ′}
             {f g : A → B} → (∀ x → f x ≡ g x) → f ≡ g

------------------------------------------------------------------------
-- 定义

-- 单态射：左可消去
Mono : ∀ {o ℓ} (C : Category o ℓ) (a b : Obj C) → Hom C a b → Set (o ⊔ ℓ)
Mono C a b f = ∀ c (g h : Hom C c a) → comp C g f ≡ comp C h f → g ≡ h

-- 满态射：右可消去
Epi : ∀ {o ℓ} (C : Category o ℓ) (a b : Obj C) → Hom C a b → Set (o ⊔ ℓ)
Epi C a b f = ∀ c (g h : Hom C b c) → comp C f g ≡ comp C f h → g ≡ h

-- 分裂单态射：有 retraction
SplitMono : ∀ {o ℓ} (C : Category o ℓ) (a b : Obj C) → Hom C a b → Set ℓ
SplitMono C a b f = Σ (Hom C b a) λ r → comp C f r ≡ idn C {a}

-- 终对象 / 初始对象（存在 + 唯一）
Terminal : ∀ {o ℓ} (C : Category o ℓ) → Obj C → Set (o ⊔ ℓ)
Terminal C t = ∀ a → Σ (Hom C a t) λ f → ∀ g → g ≡ f

Initial : ∀ {o ℓ} (C : Category o ℓ) → Obj C → Set (o ⊔ ℓ)
Initial C i = ∀ a → Σ (Hom C i a) λ f → ∀ g → g ≡ f

------------------------------------------------------------------------
-- 旗舰：分裂单态射必单——只用三条定律的重写串，任意范畴成立

split-mono-mono : ∀ {o ℓ} (C : Category o ℓ) (a b : Obj C) (f : Hom C a b)
                → SplitMono C a b f → Mono C a b f
split-mono-mono C a b f (r , Hr) c g h H =
  begin
    g                                   ≡⟨ sym (idR C g) ⟩
    comp C g (idn C {a})                  ≡⟨ cong (comp C g) (sym Hr) ⟩
    comp C g (comp C f r)               ≡⟨ sym (assoc C g f r) ⟩
    comp C (comp C g f) r               ≡⟨ cong (λ X → comp C X r) H ⟩
    comp C (comp C h f) r               ≡⟨ assoc C h f r ⟩
    comp C h (comp C f r)               ≡⟨ cong (comp C h) Hr ⟩
    comp C h (idn C {a})                  ≡⟨ idR C h ⟩
    h
  ∎

-- 同构（双侧逆）既是 mono 又是 epi：各取一个侧逆套用同一串重写
IsIso : ∀ {o ℓ} (C : Category o ℓ) (a b : Obj C) → Hom C a b → Set ℓ
IsIso C a b f = Σ (Hom C b a) λ g → (comp C f g ≡ idn C {a}) × (comp C g f ≡ idn C {b})

iso-epi : ∀ {o ℓ} (C : Category o ℓ) (a b : Obj C) (f : Hom C a b)
        → IsIso C a b f → Epi C a b f
iso-epi C a b f (g , H1 , H2) c u v H =
  begin
    u                                   ≡⟨ sym (idL C u) ⟩
    comp C (idn C {b}) u                  ≡⟨ cong (λ X → comp C X u) (sym H2) ⟩
    comp C (comp C g f) u               ≡⟨ assoc C g f u ⟩
    comp C g (comp C f u)               ≡⟨ cong (comp C g) H ⟩
    comp C g (comp C f v)               ≡⟨ sym (assoc C g f v) ⟩
    comp C (comp C g f) v               ≡⟨ cong (λ X → comp C X v) H2 ⟩
    comp C (idn C {b}) v                  ≡⟨ idL C v ⟩
    v
  ∎

------------------------------------------------------------------------
-- 反范畴 + 对偶翻译

opposite : ∀ {o ℓ} → Category o ℓ → Category o ℓ
opposite C = record
  { Obj = Obj C; Hom = λ a b → Hom C b a
  ; idn = idn C; comp = λ f g → comp C g f
  ; idL = λ f → idR C f; idR = λ f → idL C f
  ; assoc = λ f g h → sym (assoc C h g f)
  }

terminal-opp : ∀ {o ℓ} (C : Category o ℓ) (t : Obj C)
             → Terminal C t → Initial (opposite C) t
terminal-opp C t H a = H a

------------------------------------------------------------------------
-- FinCat 里的含义

FinCat : Category 0ℓ 0ℓ
FinCat = record
  { Obj = ℕ
  ; Hom = λ m n → Fin m → Fin n
  ; idn = λ x → x
  ; comp = λ f g x → g (f x)
  ; idL = λ f → refl
  ; idR = λ f → refl
  ; assoc = λ f g h → refl
  }

-- mono ⇒ 单射（元素 x 看成 1 → m 的常值态射）
mono-inj : ∀ {m n} (f : Fin m → Fin n)
         → Mono FinCat m n f → ∀ x y → f x ≡ f y → x ≡ y
mono-inj f Hmono x y Hxy =
  cong (λ k → k zero) (Hmono 1 (λ _ → x) (λ _ → y) pointwise)
  where
    pointwise : comp FinCat (λ _ → x) f ≡ comp FinCat (λ _ → y) f
    pointwise = funext (λ _ → Hxy)

-- 单射 ⇒ mono
inj-mono : ∀ {m n} (f : Fin m → Fin n)
         → (∀ x y → f x ≡ f y → x ≡ y) → Mono FinCat m n f
inj-mono f Hinj c g h H = funext pointwise
  where
    pointwise : ∀ z → g z ≡ h z
    pointwise z = Hinj (g z) (h z) (cong (λ k → k z) H)

-- 满射 ⇒ epi（逆像处比较）。反方向要有限搜索或经典逻辑，作边界记录
surj-epi : ∀ {m n} (f : Fin m → Fin n)
         → (∀ y → Σ (Fin m) λ x → f x ≡ y) → Epi FinCat m n f
surj-epi f Hsurj c g h H = funext pointwise
  where
    pointwise : ∀ z → g z ≡ h z
    pointwise z with Hsurj z
    ... | (x , Hx) =
      begin
        g z           ≡⟨ cong g (sym Hx) ⟩
        g (f x)       ≡⟨ cong (λ k → k x) H ⟩
        h (f x)       ≡⟨ cong h Hx ⟩
        h z
      ∎

-- Fin 1 只有一个元素；Fin 0 是空类型
fin1-uniq : ∀ (u : Fin 1) → u ≡ zero
fin1-uniq zero = refl
fin1-uniq (suc ())

fin0-elim : ∀ {ℓ} {A : Set ℓ} → Fin 0 → A
fin0-elim ()

-- 终对象 = 1，初始对象 = 0：唯一性靠 funext
finOne-terminal : Terminal FinCat 1
finOne-terminal a = (λ _ → zero) , λ g → funext (λ z → fin1-uniq (g z))

finZero-initial : Initial FinCat 0
finZero-initial a = (λ x → fin0-elim x) , λ g → funext (λ z → fin0-elim z)

-- 零对象：catOne 的唯一对象既终又始
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

⊤-uniq : ∀ (u : ⊤) → u ≡ tt
⊤-uniq tt = refl

one-terminal : Terminal OneCat tt
one-terminal a = tt , λ g → ⊤-uniq g

one-initial : Initial OneCat tt
one-initial a = tt , λ g → ⊤-uniq g

------------------------------------------------------------------------
-- 坑位速记：
-- 1. mono 定义的方向：comp g f ≡ comp h f → g ≡ h——f 在复合右侧；
--    图序书写的消去律两侧要分清。
-- 2. 元素即态射：x : Fin m 变成 1 → m 的常值函数，mono 的消去律
--    立刻翻译成单射；反向从函数相等取点用 cong (λ k → k z)。
-- 3. with-模式解构 Σ 的 witness 时，`... | (x , Hx) =` 的续体里
--    局部 where 打开 ≡-Reasoning 要缩进对齐（Agda 对布局敏感）。
-- 4. funext 是本章唯一新公理（postulate 入账）；Lean 里它是核心
--    定理——三文化的分岔点。
-- 5. Fin 1 的「只有一个元素」要自证 fin1-uniq（模式 suc () 自灭）；
--    Fin 0 消去子 fin0-elim 的动机可以是任意 Set，含等式命题。
------------------------------------------------------------------------
