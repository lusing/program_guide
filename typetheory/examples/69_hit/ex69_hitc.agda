{-# OPTIONS --cubical #-}
----------------------------------------------------------------
-- 42 高阶归纳类型 · 深化件 —— cubical Agda（书 ch.6 深水区）
--   · Suspension（6.5）：Sⁿ 的生产线；消去子与函子性
--   · Pushout（6.8）：粘合的万有构造；样本：区间 =
--     Pushout of 1 ← 1 → 1（书 6.8 例 1）
--   · 70 章主角预演：loop := sym (merid true) ∙ merid false
--     ——S¹ 的非平凡环路，两行机器定义
--   · 与 Coq 公理对照组（ex69_hit.v）的分工：那里三件套
--     （构造子+消去子+计算规则）全是公理账目；这里只有
--     data——消去子与计算规则由模式匹配自动派生
----------------------------------------------------------------
module ex69_hitc where

open import Agda.Primitive
open import Agda.Primitive.Cubical renaming
  ( primIMin to _∧_ ; primIMax to _∨_ ; primINeg to ~_ ; itIsOne to 1=1
  ; primTransp to transp ; primHComp to hcomp )
open import Agda.Builtin.Cubical.Path
open import Agda.Builtin.Sigma
open import Agda.Builtin.Unit
open import Agda.Builtin.Bool

-- ============================================================
-- 〇、mini-cubical 前奏（64 章服役版）
-- ============================================================

refl : ∀ {ℓ} {A : Set ℓ} {x : A} → x ≡ x
refl {x = x} = λ _ → x

sym : ∀ {ℓ} {A : Set ℓ} {x y : A} → x ≡ y → y ≡ x
sym p = λ i → p (~ i)

transport : ∀ {ℓ} (A : I → Set ℓ) → A i0 → A i1
transport A = transp A i0

J : ∀ {ℓ ℓ'} {A : Set ℓ} {x : A} (P : ∀ z → x ≡ z → Set ℓ')
  → P x refl → ∀ {y} (p : x ≡ y) → P y p
J P d p = transport (λ i → P (p i) (λ j → p (i ∧ j))) d

infixl 30 _∙_
_∙_ : ∀ {ℓ} {A : Set ℓ} {x y z : A} → x ≡ y → y ≡ z → x ≡ z
_∙_ {x = x} p q = J (λ z _ → x ≡ z) p q

-- ============================================================
-- 一、Suspension（书 6.5）：Sⁿ 的生产线
-- ============================================================

data Susp {ℓ} (A : Set ℓ) : Set ℓ where
  north : Susp A
  south : Susp A
  merid : (a : A) → north ≡ south

-- 消去子：两极给值、子午线给方形调整（书 6.5 的三段式）
Susp-elim : ∀ {ℓ ℓ'} {A : Set ℓ} (P : Susp A → Set ℓ')
          → (pn : P north) (ps : P south)
          → (∀ a → PathP (λ i → P (merid a i)) pn ps)
          → ∀ s → P s
Susp-elim P pn ps pm north = pn
Susp-elim P pn ps pm south = ps
Susp-elim P pn ps pm (merid a i) = pm a i

-- Susp 的函子性：极点保极点、子午线跟函数走
Susp-fun : ∀ {ℓ ℓ'} {A : Set ℓ} {B : Set ℓ'}
         → (A → B) → Susp A → Susp B
Susp-fun {B = B} f = Susp-elim (λ _ → Susp B) north south (λ a → merid (f a))

-- S⁰ = Bool，于是 S¹ = Susp Bool——圆不必手搓：
S⁰ : Set
S⁰ = Bool

S¹ : Set
S¹ = Susp S⁰

-- 球面塔：Sⁿ⁺¹ = Susp Sⁿ——「生产线」的本义
S² : Set
S² = Susp S¹

-- ============================================================
-- 二、Pushout（书 6.8）：粘合的万有构造
-- ============================================================

data Pushout {ℓ ℓ' ℓ''} {A : Set ℓ} {B : Set ℓ'} {C : Set ℓ''}
             (f : A → B) (g : A → C) : Set (ℓ ⊔ ℓ' ⊔ ℓ'') where
  inl : B → Pushout f g
  inr : C → Pushout f g
  push : (a : A) → inl (f a) ≡ inr (g a)

-- 消去子（书 6.8.1 的依赖版）

Pushout-elim : ∀ {ℓ ℓ' ℓ'' ℓ'''}
              → {A : Set ℓ} {B : Set ℓ'} {C : Set ℓ''}
              → {f : A → B} {g : A → C}
              → (P : Pushout f g → Set ℓ''')
              → (pl : ∀ b → P (inl b)) (pr : ∀ c → P (inr c))
              → (∀ a → PathP (λ i → P (push a i)) (pl (f a)) (pr (g a)))
              → ∀ u → P u
Pushout-elim P pl pr psh (inl b) = pl b
Pushout-elim P pl pr psh (inr c) = pr c
Pushout-elim P pl pr psh (push a i) = psh a i

-- 样本（书 6.8 例 1）：区间 = Pushout of 1 ← 1 → 1
Interval : Set
Interval = Pushout (λ (_ : ⊤) → tt) (λ (_ : ⊤) → tt)

i0i1 : Interval
i0i1 = inl tt

i1i0 : Interval
i1i0 = inr tt

seg : i0i1 ≡ i1i0
seg = push tt

-- 区间到任何类型的「路径双射」：Interval 的点到道路的转换
--（书 6.8 例 1 的观察：Interval ≃ 1 + 1 + I——粘合点恰成一条线）

-- ============================================================
-- 三、70 章主角预演：S¹ 的非平凡环路
-- ============================================================

base : S¹
base = north

-- 环路：沿 true 子午线下去、沿 false 子午线回来——两行
loop : base ≡ base
loop = merid false ∙ sym (merid true)

-- 直觉：merid true 与 merid false 是两条不同的「南北公路」，
-- 它们的错位差就是绕圆一圈。loop ≠ refl 是 70 章的定理
--（Coq 侧 70 章已有完整 encode-decode；cubical 侧同型件
-- 需要 S¹ 的 S¹-elim 上「方形一致性」的完整开发——彼章续）。

-- loop 的「平方」与「n 次幂」：π₁(S¹) = ℤ 的机器前身
loop² : base ≡ base
loop² = loop ∙ loop

-- 幂的归纳定义（70 章 code 的胚）
data ℕ : Set where
  zero : ℕ
  suc  : ℕ → ℕ

loop^ : ℕ → base ≡ base
loop^ zero = refl
loop^ (suc n) = loop ∙ loop^ n
