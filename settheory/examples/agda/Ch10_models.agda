-- 第 10 章 模型：受限公式的绝对性骨架
--
-- Δ₀（受限）公式的量词都是 ∃u∈x / ∀u∈x 形态。
-- 引理 10.1：传递类对 Δ₀ 公式绝对。这里给出公式的
-- 构造性骨架与受限量词的语义形态。

module Ch10_models where

open import Data.Nat using (ℕ; zero; suc)
open import Data.List using (List; []; _∷_)
open import Data.Product using (_×_; _,_)
open import Data.Sum using (_⊎_; inj₁; inj₂)
open import Relation.Binary.PropositionalEquality using (_≡_; refl)
open import Relation.Nullary using (¬_)

-- ---------- 一、受限公式的数据类型 ----------

-- 语义域的接口：载体与 ∈ 解释
-- 自造 lookup（stdlib 的 lookup 需要 Fin 索引）
natLookup : {A : Set} → List A → ℕ → A → A
natLookup [] _ d = d
natLookup (x ∷ _) zero _ = x
natLookup (_ ∷ e) (suc i) d = natLookup e i d

record Semantics : Set₁ where
  field
    Carrier : Set
    Elem    : Carrier → Carrier → Set

open Semantics

-- 变元编号 n；环境是列表（0 号槽给受限量词的新变元）
data Δ₀ : Set where
  atom∈ : ℕ → ℕ → Δ₀                    -- x_i ∈ x_j
  atom≡ : ℕ → ℕ → Δ₀                    -- x_i = x_j
  nandₒ : Δ₀ → Δ₀ → Δ₀                  -- ¬(p ∧ q)
  rallₒ : ℕ → Δ₀ → Δ₀                   -- ∀u ∈ x_i : φ（u 占 0 号槽）

-- ---------- 二、受限语义（默认值作参数） ----------

sat : (S : Semantics) → Carrier S → Δ₀ → List (Carrier S) → Set
sat S d (atom∈ i j) env =
  Semantics.Elem S (natLookup env i d) (natLookup env j d)
sat S d (atom≡ i j) env =
  natLookup env i d ≡ natLookup env j d
sat S d (nandₒ p q) env =
  ¬ (sat S d p env × sat S d q env)
sat S d (rallₒ i p) env =
  (u : Carrier S) → Semantics.Elem S (natLookup env i d) u
    → sat S d p (u ∷ env)

-- ---------- 三、绝对性的语义要点（讲义骨架） ----------
-- 量词域 = "x_i 的成员"。若 M ⊆ V 传递，则 x ∈ M 的成员
-- 全在 M 中——受限量词在 M 与 V 中跑遍**同一个集合**，
-- 真值必然一致。完整的 absoluteness 框架（Isabelle/ZF 的
-- Relative.thy）把"传递"形式化为 M 满足的闭包条件。
