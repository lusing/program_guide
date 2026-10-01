------------------------------------------------------------------------
-- ex01 —— 范畴的定义与首批例子
-- 三书对位：贺伟《范畴论》1.1 /《高级范畴论》1.3 / Simmons 1.1
------------------------------------------------------------------------

open import Level using (Level; suc; _⊔_; 0ℓ)
open import Data.Unit using (⊤; tt)
open import Data.Nat using (ℕ; zero; _+_)
open import Data.Nat.Properties using (+-identityˡ; +-identityʳ; +-assoc)
open import Data.Fin using (Fin)
open import Data.Bool using (Bool; not; true; false)
open import Relation.Binary.PropositionalEquality using (_≡_; refl)

------------------------------------------------------------------------
-- 定义（宇宙多态：Obj 在 o 层，Hom 在 ℓ 层）

record Category (o ℓ : Level) : Set (suc (o ⊔ ℓ)) where
  field
    Obj : Set o
    Hom : Obj → Obj → Set ℓ
    idn : ∀ {a} → Hom a a
    comp : ∀ {a b c} → Hom a b → Hom b c → Hom a c
    idL : ∀ {a b} (f : Hom a b) → comp (idn {a}) f ≡ f
    idR : ∀ {a b} (f : Hom a b) → comp f (idn {b}) ≡ f
    assoc : ∀ {a b c d} (f : Hom a b) (g : Hom b c) (h : Hom c d)
          → comp (comp f g) h ≡ comp f (comp g h)

-- 复合按「图序」书写：comp f g = 先 f 后 g（Simmons 风格）。
-- 函数式的 f ∘ g = 先 g 后 f，恰是反范畴视角（见 02 章）。

------------------------------------------------------------------------
-- 例 1：终范畴 1 —— 一个对象、一条态射

OneCat : Category 0ℓ 0ℓ
OneCat = record
  { Obj = ⊤
  ; Hom = λ _ _ → ⊤
  ; idn = tt
  ; comp = λ _ _ → tt
  ; idL = λ _ → refl          -- tt ≡ tt，β 折叠后 refl
  ; idR = λ _ → refl
  ; assoc = λ _ _ _ → refl
  }

------------------------------------------------------------------------
-- 例 2：幺半群 = 单对象范畴
-- (ℕ, +, 0)：Hom * * := ℕ，恒等 := 0，复合 := 加法。
-- 定律不再是 refl，而是货真价实的算术定理。

NatCat : Category 0ℓ 0ℓ
NatCat = record
  { Obj = ⊤
  ; Hom = λ _ _ → ℕ
  ; idn = zero
  ; comp = _+_
  ; idL = λ f → +-identityˡ f        -- 0 + f ≡ f
  ; idR = λ f → +-identityʳ f        -- f + 0 ≡ f（stdlib 里的归纳证明）
  ; assoc = λ f g h → +-assoc f g h
  }

module NatDemo where
  open Category NatCat
  -- 在 NatCat 里复合两条态射：comp 2 3 = 5，机器可算
  five : ℕ
  five = comp {a = tt} {b = tt} {c = tt} 2 3
  five-ok : five ≡ 5
  five-ok = refl

------------------------------------------------------------------------
-- 例 3：FinCat —— 有限集范畴的骨架
-- 对象 = 自然数（当作基数），Hom m n := Fin m → Fin n。
-- 「函数当态射」的最小化身，且完全避开宇宙问题。

FinCat : Category 0ℓ 0ℓ
FinCat = record
  { Obj = ℕ
  ; Hom = λ m n → Fin m → Fin n
  ; idn = λ x → x
  ; comp = λ f g x → g (f x)
  ; idL = λ f → refl          -- (λ x → f x) ≡ f：βη 折叠
  ; idR = λ f → refl
  ; assoc = λ f g h → refl
  }

------------------------------------------------------------------------
-- 例 4：TyCat —— Set₀ 的范畴（「Set 的化身」）
-- 对象 = Set₀，态射 = 函数。宇宙多态在此发挥作用：
-- Obj 落在 1 层，Hom 落在 0 层。

TyCat : Category (suc 0ℓ) 0ℓ
TyCat = record
  { Obj = Set 0ℓ
  ; Hom = λ A B → A → B
  ; idn = λ x → x
  ; comp = λ f g x → g (f x)
  ; idL = λ f → refl
  ; idR = λ f → refl
  ; assoc = λ f g h → refl
  }

module TyDemo where
  open Category TyCat
  -- 在 TyCat 里复合两条态射：not 再 not
  nn : Hom Bool Bool
  nn = comp (λ b → not b) (λ b → not b)
  -- 逐点等于 id；函数层面的相等要外延公理（见 03 章），先证逐点
  nn-pointwise : ∀ b → nn b ≡ b
  nn-pointwise true = refl
  nn-pointwise false = refl

------------------------------------------------------------------------
-- 坑位速记：
-- 1. record 字面量不能挂 where；辅助打开一律放顶部或包 module。
-- 2. 多次 open 同名字段会撞名（comp/idn）——各例子包 module 隔离。
-- 3. comp 的隐式 {a b c} 在 Obj = ⊤ 时无法从实参推出，
--    用具名隐式 {a = tt} 显式给。
-- 4. Agda 定义相等含 βη，函数族的定律全是 refl；
--    NatCat 的 idR 要 stdlib 归纳引理（+-identityʳ）。
-- 5. not (not b) ≡ b 对变量 b 卡归约——逐点证明必须 case split。
