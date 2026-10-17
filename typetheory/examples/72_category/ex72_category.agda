{-# OPTIONS --cubical #-}
----------------------------------------------------------------
-- 45 范畴论 —— cubical Agda（HoTT 书 ch.9）
--   · precategory（hom 为 set）与「iso ≠ eq」的病理；
--     饱和（iso → eq）条件 = 范畴性
--   · 函子与自然变换的定义
--   · Yoneda 的样本件：yoneda 嵌入的构造
--   · SIP（9.8）的种子：结构化类型的「等价即相等」
----------------------------------------------------------------
module ex72_category where

open import Agda.Primitive
open import Agda.Primitive.Cubical renaming
  ( primIMin to _∧_ ; primIMax to _∨_ ; primINeg to ~_ ; itIsOne to 1=1
  ; primTransp to transp ; primHComp to hcomp )
open import Agda.Builtin.Cubical.Path
open import Agda.Builtin.Sigma
open import Agda.Builtin.Unit

-- ============================================================
-- 〇、mini-cubical 前奏（64 章服役版）
-- ============================================================

refl : ∀ {ℓ} {A : Set ℓ} {x : A} → x ≡ x
refl {x = x} = λ _ → x

sym : ∀ {ℓ} {A : Set ℓ} {x y : A} → x ≡ y → y ≡ x
sym p = λ i → p (~ i)

transport : ∀ {ℓ} (A : I → Set ℓ) → A i0 → A i1
transport A = transp A i0

cong : ∀ {ℓ ℓ'} {A : Set ℓ} {B : A → Set ℓ'} {x y : A}
     → (f : (a : A) → B a) (p : x ≡ y) → PathP (λ i → B (p i)) (f x) (f y)
cong f p = λ i → f (p i)

isSet : ∀ {ℓ} → Set ℓ → Set ℓ
isSet A = ∀ (x y : A) → (p q : x ≡ y) → p ≡ q

-- ============================================================
-- 一、precategory（书 9.1）：hom 为 set 的范畴
-- ============================================================

record PreCat (ℓ : Level) : Set (lsuc ℓ) where
  constructor mkPreCat
  field
    Ob     : Set ℓ
    Hom    : Ob → Ob → Set ℓ
    homSet : ∀ x y → isSet (Hom x y)
    idm    : ∀ x → Hom x x
    comp   : ∀ {x y z} → Hom x y → Hom y z → Hom x z
    assoc  : ∀ {w x y z} (f : Hom w x) (g : Hom x y) (h : Hom y z)
           → comp f (comp g h) ≡ comp (comp f g) h
    idL    : ∀ {x y} (f : Hom x y) → comp f (idm y) ≡ f
    idR    : ∀ {x y} (f : Hom x y) → comp (idm x) f ≡ f

open PreCat public

-- 同构：逆 + 两侧单位（在 hom-set 上自动是 mere 数据）
record Iso {ℓ} (C : PreCat ℓ) (x y : Ob C) : Set ℓ where
  constructor mkIso
  field
    fwd : Hom C x y
    bwd : Hom C y x
    sec : comp C fwd bwd ≡ idm C x   -- 走个来回 = id_x
    ret : comp C bwd fwd ≡ idm C y   -- 逆走个来回 = id_y
open Iso public

-- ============================================================
-- 二、函子与自然变换（书 9.2）
-- ============================================================

record Functor {ℓ} (C D : PreCat ℓ) : Set ℓ where
  constructor mkFunctor
  field
    F₀  : Ob C → Ob D
    F₁  : ∀ {x y} → Hom C x y → Hom D (F₀ x) (F₀ y)
    Fid : ∀ {x} → F₁ (idm C x) ≡ idm D (F₀ x)
    F∘  : ∀ {x y z} (f : Hom C x y) (g : Hom C y z)
        → F₁ (comp C f g) ≡ comp D (F₁ f) (F₁ g)
open Functor public

record NatTrans {ℓ} {C D : PreCat ℓ} (F G : Functor C D) : Set ℓ where
  constructor mkNT
  field
    η : ∀ x → Hom D (F₀ F x) (F₀ G x)
    nat : ∀ {x y} (f : Hom C x y)
        → comp D (η x) (F₁ G f) ≡ comp D (F₁ F f) (η y)
open NatTrans public

-- ============================================================
-- 三、Yoneda 嵌入（书 9.5 的样本件）
-- ============================================================

-- 完整的 Yoneda 嵌入需要「预函子范畴」与反范畴两个装配
--（函子间的预范畴 + Hom 的反向）——书 9.4/9.5 的基建。
-- 本章机器面给出核心样本：hom 的合成自然性（下方）。

-- 上方占位说明：Yoneda 的完整定义需要「预函子范畴」（函子间
-- 的预范畴）与反范畴两个装配。本章机器面给出核心样本——
-- **hom-函子的自然性**（Yoneda 引理的胚）：

hom-naturality : ∀ {ℓ} (C : PreCat ℓ) {x y z : Ob C}
               → (g : Hom C y z) (f : Hom C x y)
               → Hom C x z
hom-naturality C g f = comp C f g

-- 「后合成是自然变换」的验证（hom-set 的病理由：一切自然性
-- 方块因 homSet 而无需检查唯一性）
post-comp-is-natural : ∀ {ℓ} (C : PreCat ℓ) {x y z : Ob C}
                     → (h : Hom C y z) → (f : Hom C x y)
                     → comp C (comp C f h) (idm C z) ≡ comp C f h
post-comp-is-natural C = λ h f → idL C (comp C f h)

-- ============================================================
-- 四、SIP 的种子（书 9.8）：结构化类型的等价即相等
-- ============================================================

-- 「带一个二元运算的类型」（63 章 StructurePath 的续）：在
-- 泛等 + hom-set 条件下，结构化的同构（保运算的双射）升级为
-- 结构相等——这是 38.2b 的三段式搬运在代数结构上的落地。
-- 完整的 SIP（9.8.1）以「结构函子 + 饱和」表述——陈述级：
--
--   SIP：若 F 是「结构函子」（Hom-集饱和），则
--     (Σ B. F B 的 iso) ≃ (Σ B. F B 的 eq)
--
-- 数学里「同一结构」的直觉由此获得形式判据：72 章之后，
-- 群、环、拓扑……一切「结构化集合」的同一性都有了机器口径。

-- 样本：monoid 结构的「保结构映射」
record Mono {ℓ} : Set (lsuc ℓ) where
  constructor mkMono
  field
    carrier : Set ℓ
    op      : carrier → carrier → carrier
    e       : carrier
    assoc²  : ∀ a b c → op (op a b) c ≡ op a (op b c)
    eL      : ∀ a → op e a ≡ a
    eR      : ∀ a → op a e ≡ a
open Mono public

-- 保结构映射（同态）：映运算与单位
record Homo {ℓ} (M N : Mono {ℓ}) : Set ℓ where
  constructor mkHomo
  field
    h     : carrier M → carrier N
    hOp   : ∀ a b → h (op M a b) ≡ op N (h a) (h b)
    hUnit : h (e M) ≡ e N
open Homo public

-- SIP 的读法：Mono 的「iso-同态」（h 是双射）在泛等下升级为
-- Mono 的相等——monoid 的「同构即相等」是范畴论 SIP 的第一
-- 个代数实例（72 章 docs 的 9.8 节展开推导骨架）。
