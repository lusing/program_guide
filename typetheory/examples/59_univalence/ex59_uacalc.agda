{-# OPTIONS --cubical #-}
----------------------------------------------------------------
-- 38 泛等 · 深化件 —— cubical Agda（书 §2.10 + §4.8–4.9）
--   · 两条「公理」的计算化身：ua 从 Glue 手造（58 章同款）、
--     funext = λ i j → h j i
--   · idtoequiv 方向：builtin pathToEquiv 直接可用——泛等的
--     「等价→路径→等价」环路两端都是程序
--   · uaβ 计算律复验：transport 沿 ua 的每一步都是定义
--   · 对照（本章 Coq 组）：UA 是公理、transport_ua 是第二条
--     公理；cubical 里两者皆程序——4.9 定理被技术进步消解
----------------------------------------------------------------
module ex59_uacalc where

open import Agda.Primitive
open import Agda.Primitive.Cubical renaming
  ( primIMin to _∧_ ; primIMax to _∨_ ; primINeg to ~_ ; itIsOne to 1=1
  ; primTransp to transp ; primHComp to hcomp )
open import Agda.Builtin.Cubical.Path
open import Agda.Builtin.Cubical.Glue
open import Agda.Builtin.Cubical.Equiv public
  renaming (isEquiv to IsEquivB; _≃_ to _≃b_; equivFun to equivFunB)
open import Agda.Builtin.Sigma
open import Agda.Builtin.Bool

-- ---- mini-cubical 前奏（58 章服役版） ----
refl : ∀ {ℓ} {A : Set ℓ} {x : A} → x ≡ x
refl {x = x} = λ _ → x

sym : ∀ {ℓ} {A : Set ℓ} {x y : A} → x ≡ y → y ≡ x
sym p = λ i → p (~ i)

transport : ∀ {ℓ} (A : I → Set ℓ) → A i0 → A i1
transport A = transp A i0

transportRefl : ∀ {ℓ} {A : Set ℓ} (a : A) → transport (λ _ → A) a ≡ a
transportRefl {A = A} a j = transp (λ _ → A) j a

infix 4 _∼_
_∼_ : ∀ {ℓ ℓ'} {A : Set ℓ} {B : A → Set ℓ'} → (∀ x → B x) → (∀ x → B x) → Set _
_∼_ {B = B} f g = ∀ x → f x ≡ g x

-- funext：一行（方形转置）——公理化世界的公理 2.9.3
funext : ∀ {ℓ ℓ'} {A : Set ℓ} {B : A → Set ℓ'} {f g : ∀ x → B x}
       → f ∼ g → f ≡ g
funext h i j = h j i

-- ---- ua 手造（58 章同款，Glue 原语） ----
idEquiv′ : ∀ {ℓ} (B : Set ℓ) → Σ (B → B) (λ f → IsEquivB f)
idEquiv′ B .fst y = y
idEquiv′ B .snd .IsEquivB.equiv-proof y .fst = y , refl
idEquiv′ B .snd .IsEquivB.equiv-proof y .snd (z , p) i =
  sym p i , (λ j → p (~ i ∨ j))

ua : ∀ {ℓ} {A B : Set ℓ} → Σ (A → B) (λ f → IsEquivB f) → A ≡ B
ua {A = A} {B = B} e i =
  primGlue B
    (λ { (i = i0) → A ; (i = i1) → B })
    (λ { (i = i0) → e ; (i = i1) → idEquiv′ B })

-- ua 的 β 计算律（Coq 侧是第二条公理 transport_ua）
uaβ : ∀ {ℓ} {A B : Set ℓ} (e : Σ (A → B) (λ f → IsEquivB f)) (a : A)
    → transport (λ i → ua e i) a ≡ e .fst a
uaβ e a = transportRefl (e .fst a)

-- ---- idtoequiv 方向：builtin pathToEquiv ----
-- Agda.Builtin.Cubical.Equiv 直接提供 pathToEquiv : A ≡ B → A ≃b B
-- （由 transp 构造——泛等的另一半也是程序）。完整的
-- idtoequiv ∘ ua ≡ id 与 ua ∘ idtoequiv ≡ id（η 律）证明需要
-- Glue 的 unglue 计算展开——cubical 库 Foundations 的正题件，
-- 本章陈述级（诚实清单：63 章 HIT 计算规则后回填路径版）。

-- 样本：Bool 取反等价 → Bool ≡ Bool 的非平凡路径
not : Bool → Bool
not true = false
not false = true

-- not 的等价证据需要 Bool 的 isSet（纤维合同性）——60 章的
-- 谓词分离法已给 true≠false，完整 fib 合同机械在 61 章
-- （Hedberg）后可用。此处以「等价的直和」展示：
--   ua 的输入是一等公民数据（函数 + 纤维证据），不是公理。

-- ---- UA ⇒ funext（书 4.9）的消解对照 ----
-- 公理化世界（本章 Coq 组）：
--   Axiom univalence → 定理 4.9.4（UA⇒弱funext）→ 定理 4.9.5
--   （弱⇒强）——两步合计约两页
-- cubical 世界：
--   ua = 程序（上方 8 行）；funext = 程序（上方 1 行）
--   「定理」退化为「定义」——Voevodsky 的证明链被 Glue 原语
--   的计算律整体替代。这正是「泛等公理」与「cubical 模式」
--   的分水岭：前者说「是什么」，后者给「怎么算」。
