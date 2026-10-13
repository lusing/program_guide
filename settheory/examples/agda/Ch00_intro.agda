-- 第 00 章 导引：Agda 的立场——Set 层级与遗传有限集合 HF 一瞥
--
-- Agda 的类型层级 Set ℓ : Set (suc ℓ) 与 Lean/Coq 一样免疫 Russell
-- 悖论。本章给出 HF（遗传有限集合）的第一次亮相：它是
-- "ZFC 减去无穷公理"的标准模型，也是本书计算通道的主角。

module Ch00_intro where

open import Data.List using (List; []; _∷_)
open import Data.List.Relation.Unary.Any using (here; there)
open import Data.List.Membership.Propositional using (_∈_)
open import Relation.Binary.PropositionalEquality using (_≡_; refl)

-- ---------- 一、HF：由有限"元素列表"给出的集合 ----------

data HF : Set where
  mk : (X : List HF) -> HF

-- 隶属：x ∈h mk X 当且仅当 x 出现于列表 X。
-- 这是"证明相关"的 ∈（同一个集合可有多张成员表），
-- 外延性需要商型处理——01 章的正题。

infix 4 _∈h_

_∈h_ : HF -> HF -> Set
x ∈h mk X = x ∈ X

-- ---------- 二、von Neumann 数列的最小片段 ----------

∅ᴴ oneᴴ twoᴴ : HF
∅ᴴ   = mk []
oneᴴ = mk (∅ᴴ ∷ [])
twoᴴ = mk (∅ᴴ ∷ oneᴴ ∷ [])

-- ∅ ∈ 2 与 1 ∈ 2 的证明：列表隶属的证据
∈-ex0 : ∅ᴴ ∈h twoᴴ
∈-ex0 = here refl

∈-ex1 : oneᴴ ∈h twoᴴ
∈-ex1 = there (here refl)
