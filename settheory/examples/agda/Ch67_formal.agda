-- 第 67 章：传递集合与形式理论（冯琦 引言+§1.1-1.2）
-- 推导即证据：Hilbert 公理模式做成构造子，MP 做成类型构造子；
-- 五步链压缩成一个证明项 P⟶P；康托尔对角线的函数版。
module Ch67_formal where

open import Data.Nat using (ℕ)
open import Data.Bool using (Bool; not)
open import Data.Empty using (⊥)
open import Data.Product using (∃; _,_)
open import Relation.Nullary using (¬_)
open import Relation.Binary.PropositionalEquality
  using (_≡_; refl; cong)

-- ---------- 定义 1.1：表达式（命题片段，Agda 原生归纳类型） ----------

data Fml : Set where
  var : ℕ → Fml
  imp : Fml → Fml → Fml
  neg : Fml → Fml

-- ---------- 定义 1.22/1.23：推导作为证据类型 ----------
-- 公理模式即构造子（对任意 P、Q、R 都可造）；分离规则即 mp。
-- "定理"就是某个 Fml 的 Der 类型有项——检查器就是类型检查器。

data Der : Fml → Set where
  axC : ∀ {P Q} → Der (imp P (imp Q P))
  axA : ∀ {P Q R} → Der (imp (imp P (imp Q R)) (imp (imp P Q) (imp P R)))
  mp  : ∀ {P Q} → Der (imp P Q) → Der P → Der Q

-- 67.6 的五步链：axC、axA、MP、axC、MP——压缩成一个项
P⟶P : ∀ {P} → Der (imp P P)
P⟶P = mp (mp axA axC) axC

-- 展开对应：mp axA axC          ← 第 1、2 步给第 3 步
--           mp (mp axA axC) axC ← 第 4 步（axC）与第 3 步给第 5 步

-- ---------- 定理 1.4 核心：布尔版对角线 ----------

not-self : (b : Bool) → b ≢ not b
not-self true ()
not-self false ()

no-surjection : (f : ℕ → ℕ → Bool) →
  ¬ ∃ (λ i → f i ≡ (λ k → not (f k k)))
no-surjection f (i , eq) = not-self (f i i) (cong (λ g → g i) eq)
