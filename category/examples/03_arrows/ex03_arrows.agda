------------------------------------------------------------------------
-- ex03 —— 特殊态射与特殊对象
-- 三书对位：贺伟《范畴论》1.4 /《高级范畴论》第 2 章 / Simmons 2.2
------------------------------------------------------------------------

open import Level using (Level; _⊔_; 0ℓ) renaming (suc to lsuc)
open import Data.Unit using (⊤; tt)
open import Data.Nat using (ℕ)
open import Data.Fin using (Fin; zero; suc)
open import Data.Bool using (Bool; true; false)
open import Data.Empty using (⊥)
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
-- 分裂满态射 + 消去律封闭（Simmons 2.2.1 / 2.2.4 / 2.2.10）

SplitEpi : ∀ {o ℓ} (C : Category o ℓ) (a b : Obj C) → Hom C a b → Set ℓ
SplitEpi C a b f = Σ (Hom C b a) λ s → comp C s f ≡ idn C {b}

-- 2.2.1(a)：section 若还是 epi，自动补出另一侧逆——成 iso
section-epi-iso : ∀ {o ℓ} (C : Category o ℓ) (a b : Obj C) (s : Hom C b a)
  → Epi C b a s → (r : Hom C a b) → comp C s r ≡ idn C {b} → IsIso C b a s
section-epi-iso C a b s Hepi r Hsr = r , Hsr , other
  where
  other : comp C r s ≡ idn C {a}
  other = Hepi a (comp C r s) (idn C) step
    where
    step : comp C s (comp C r s) ≡ comp C s (idn C)
    step = begin
      comp C s (comp C r s)   ≡⟨ sym (assoc C s r s) ⟩
      comp C (comp C s r) s   ≡⟨ cong (λ w → comp C w s) Hsr ⟩
      comp C (idn C) s        ≡⟨ idL C s ⟩
      s                       ≡⟨ sym (idR C s) ⟩
      comp C s (idn C)        ∎

-- 2.2.4 封闭律（mono 两条；epi 两条对偶）
mono-comp : ∀ {o ℓ} (C : Category o ℓ) (a b c : Obj C)
  (f : Hom C a b) (g : Hom C b c)
  → Mono C a b f → Mono C b c g → Mono C a c (comp C f g)
mono-comp C a b c f g Hf Hg d h1 h2 H
  = Hf d h1 h2 (Hg d (comp C h1 f) (comp C h2 f)
      (begin
        comp C (comp C h1 f) g  ≡⟨ assoc C h1 f g ⟩
        comp C h1 (comp C f g)  ≡⟨ H ⟩
        comp C h2 (comp C f g)  ≡⟨ sym (assoc C h2 f g) ⟩
        comp C (comp C h2 f) g  ∎))

mono-of-comp : ∀ {o ℓ} (C : Category o ℓ) (a b c : Obj C)
  (f : Hom C a b) (g : Hom C b c)
  → Mono C a c (comp C f g) → Mono C a b f
mono-of-comp C a b c f g H d h1 h2 Hf1
  = H d h1 h2
      (begin
        comp C h1 (comp C f g)  ≡⟨ sym (assoc C h1 f g) ⟩
        comp C (comp C h1 f) g  ≡⟨ cong (λ w → comp C w g) Hf1 ⟩
        comp C (comp C h2 f) g  ≡⟨ assoc C h2 f g ⟩
        comp C h2 (comp C f g)  ∎)

epi-comp : ∀ {o ℓ} (C : Category o ℓ) (a b c : Obj C)
  (f : Hom C a b) (g : Hom C b c)
  → Epi C a b f → Epi C b c g → Epi C a c (comp C f g)
epi-comp C a b c f g Hf Hg d h1 h2 H
  = Hg d h1 h2 (Hf d (comp C g h1) (comp C g h2)
      (begin
        comp C f (comp C g h1)  ≡⟨ sym (assoc C f g h1) ⟩
        comp C (comp C f g) h1  ≡⟨ H ⟩
        comp C (comp C f g) h2  ≡⟨ assoc C f g h2 ⟩
        comp C f (comp C g h2)  ∎))

epi-of-comp : ∀ {o ℓ} (C : Category o ℓ) (a b c : Obj C)
  (f : Hom C a b) (g : Hom C b c)
  → Epi C a c (comp C f g) → Epi C b c g
epi-of-comp C a b c f g H d h1 h2 Hg1
  = H d h1 h2
      (begin
        comp C (comp C f g) h1  ≡⟨ assoc C f g h1 ⟩
        comp C f (comp C g h1)  ≡⟨ cong (λ w → comp C f w) Hg1 ⟩
        comp C f (comp C g h2)  ≡⟨ sym (assoc C f g h2) ⟩
        comp C (comp C f g) h2  ∎)

-- 2.2.10 抽象内核：e 单 + m 满（mono/epi）⇒ m;u;e = m;v;e ⟹ u = v
mono-epi-cancel : ∀ {o ℓ} (C : Category o ℓ) (A B X Y : Obj C)
  (e : Hom C A B) (u v : Hom C B X) (m : Hom C X Y)
  → Epi C A B e → Mono C X Y m
  → comp C (comp C e u) m ≡ comp C (comp C e v) m → u ≡ v
mono-epi-cancel C A B X Y e u v m He Hm H
  = Hm B u v (He Y (comp C u m) (comp C v m)
      (begin
        comp C e (comp C u m)  ≡⟨ sym (assoc C e u m) ⟩
        comp C (comp C e u) m  ≡⟨ H ⟩
        comp C (comp C e v) m  ≡⟨ assoc C e v m ⟩
        comp C e (comp C v m)  ∎))

------------------------------------------------------------------------
-- 平衡反例（Simmons 2.2.2）：瘦范畴全箭头 mono+epi，行走箭头非 iso

data TwoHom : Bool → Bool → Set where
  two-id0 : TwoHom false false
  two-arr : TwoHom false true
  two-id1 : TwoHom true true

twoComp : ∀ {a b c} → TwoHom a b → TwoHom b c → TwoHom a c
twoComp two-id0 two-id0 = two-id0
twoComp two-id0 two-arr = two-arr
twoComp two-arr two-id1 = two-arr
twoComp two-id1 two-id1 = two-id1

CatTwo : Category 0ℓ 0ℓ
CatTwo = record
  { Obj = Bool
  ; Hom = TwoHom
  ; idn = λ { {false} → two-id0 ; {true} → two-id1 }
  ; comp = twoComp
  ; idL = λ { two-id0 → refl ; two-arr → refl ; two-id1 → refl }
  ; idR = λ { two-id0 → refl ; two-arr → refl ; two-id1 → refl }
  ; assoc = λ { two-id0 two-id0 two-id0 → refl
              ; two-id0 two-id0 two-arr → refl
              ; two-id0 two-arr two-id1 → refl
              ; two-arr two-id1 two-id1 → refl
              ; two-id1 two-id1 two-id1 → refl }
  }

thin-mono : ∀ {a b} (f : TwoHom a b) → Mono CatTwo a b f
thin-mono f c g h _ with g | h
... | two-id0 | two-id0 = refl
... | two-arr | two-arr = refl
... | two-id1 | two-id1 = refl

thin-epi : ∀ {a b} (f : TwoHom a b) → Epi CatTwo a b f
thin-epi f c g h _ with g | h
... | two-id0 | two-id0 = refl
... | two-arr | two-arr = refl
... | two-id1 | two-id1 = refl

-- 行走箭头无反向箭头 ⟹ 非 iso ⟹ CatTwo 不平衡
arr-not-iso : IsIso CatTwo false true two-arr → ⊥
arr-not-iso (g , _) with g
... | ()

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
