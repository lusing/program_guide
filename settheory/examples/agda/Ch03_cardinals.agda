-- 第 03 章 基数：对角线的命题核心与列表域实例
--
-- Cantor/Schröder-Bernstein 一章的 Agda 侧聚焦两点：
-- 1. 对角线的命题核心：P ↔ ¬P 自爆（类型论零公理版）；
-- 2. 列表域上的具体对角构造：给定"名单"F，造出与每个 F x
--    在 x 处分歧的 D——分歧是构造出来的，不是反证出来的。

module Ch03_cardinals where

open import Data.Empty using (⊥)
open import Data.Sum using (_⊎_; inj₁; inj₂)
open import Relation.Binary.PropositionalEquality using (_≡_; refl)

open import Data.List using (List; []; _∷_)

infix 4 _∈ℓ_

_∈ℓ_ : {A : Set} → A → List A → Set
x ∈ℓ [] = ⊥
x ∈ℓ (y ∷ ys) = (x ≡ y) ⊎ (x ∈ℓ ys)

_∉ℓ_ : {A : Set} → A → List A → Set
x ∉ℓ xs = x ∈ℓ xs → ⊥

-- ---------- 一、命题核心：¬P ≡ P 自爆 ----------
-- Russell 悖论 / Cantor 对角线共享的命题引擎。
-- 注意：需要的是**相等**（提供 transport 通道）而非双向函数
-- ——纯函数版 P ↔ ¬P → ⊥ 直觉主义不可证（无递归自指造不出）。
-- 与 Coq 通道 Ch00_intro.v 的 transport 版是同一模式的两种语法。

open import Relation.Binary.PropositionalEquality using (sym; subst)

clash : {P : Set} → ((P → ⊥) ≡ P) → ⊥
clash {P} E = fix (castF fix)
  where
   castF : (P → ⊥) → P
   castF = subst (λ X → X) E
   castB : P → (P → ⊥)
   castB = subst (λ X → X) (sym E)
   fix : P → ⊥
   fix p = castB p p

-- 用法：对角集 D 的成员条件若恰为 "x ∉ℓ F x"，
-- 外延化后 P := (x ∈ℓ F x x) 满足 ¬P ≡ P——clash 立即矛盾。

-- ---------- 二、列表域的具体对角构造 ----------

-- 名单：两点域 X = ⊤+⊤ 的极简版。F 给每个点配一个 A-列表。
data Two : Set where
  t0 : Two
  t1 : Two

-- 对角集构造器：D(x) = 全域去掉 x（x ∉ D x 但 y ≠ x 时 y ∈ D y）
-- 配 F(x) = {x}：则 D 与 F 在两处都分歧
F : Two → Two → List Two
F t0 t0 = t0 ∷ []          -- F(t0) = {t0}
F t0 t1 = t0 ∷ []
F t1 t0 = t1 ∷ []
F t1 t1 = t1 ∷ []          -- F(t1) = {t1}

D : Two → List Two
D t0 = t1 ∷ []             -- D(t0) = {t1}
D t1 = t0 ∷ []             -- D(t1) = {t0}

-- 点态分歧的证据：x ∈ F x 恒成立，x ∈ D x 恒不成立
t0-in-F : t0 ∈ℓ F t0 t0
t0-in-F = inj₁ refl

t1-in-F : t1 ∈ℓ F t1 t1
t1-in-F = inj₁ refl

t0-notin-D : t0 ∉ℓ D t0
t0-notin-D (inj₁ ())
t0-notin-D (inj₂ ())

t1-notin-D : t1 ∉ℓ D t1
t1-notin-D (inj₁ ())
t1-notin-D (inj₂ ())

-- 因此 D ≠ F t0 且 D ≠ F t1（在各自的"对角点"上成员相反）。
-- Cantor 对角线的一般原理：无论名单多长，都能这样逐点翻牌。
