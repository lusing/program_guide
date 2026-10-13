-- 第 01 章 公理：HF（遗传有限集合）模型
--
-- "公理"有两种身份：可以被假设（浅嵌入），也可以被满足（模型）。
-- Agda 通道走第二条路：把 HF 做出来，验证配对与单点的构造性成立，
-- 并用反例展示"外延性在 HF 上不是免费的"。

module Ch01_hf where

open import Data.List using (List; []; _∷_)
open import Data.List.Relation.Unary.Any using (here; there)
open import Data.List.Membership.Propositional using (_∈_)
open import Data.Product using (_×_; _,_)
open import Relation.Binary.PropositionalEquality using (_≡_; refl)

-- ---------- 一、HF 与隶属 ----------

data HF : Set where
  mk : (X : List HF) -> HF

infix 4 _∈h_ _⊆h_

_∈h_ : HF -> HF -> Set
x ∈h mk X = x ∈ X

_⊆h_ : HF -> HF -> Set
x ⊆h y = forall w -> w ∈h x -> w ∈h y

-- ---------- 二、配对与单点：构造性成立 ----------

pairh : HF -> HF -> HF
pairh a b = mk (a ∷ b ∷ [])

singletonh : HF -> HF
singletonh a = mk (a ∷ [])

-- 配对的成员刻画：w ∈ {a,b} 的两个入场券
pair-member-left : (a b w : HF) -> w ≡ a -> w ∈h pairh a b
pair-member-left a b .a refl = here refl

pair-member-right : (a b w : HF) -> w ≡ b -> w ∈h pairh a b
pair-member-right a b .b refl = there (here refl)

-- 单点的成员刻画：w ∈ {a} 只有一个入场券
singleton-member : (a w : HF) -> w ≡ a -> w ∈h singletonh a
singleton-member a .a refl = here refl

-- ---------- 三、外延性：HF 世界的裂缝 ----------

-- mk (a ∷ a ∷ []) 与 mk (a ∷ []) 的元素完全相同（都只含 a），
-- 两个方向都互相包含；但作为 List 表示不同。
-- 外延公理要求把 HF 商掉"元素互含"，或用规范化表示（排序去重）。
-- 这正是 ZFC 把外延性列为公理、而类型论必须显式做商的原因。

dup-sub-single : (a : HF) -> mk (a ∷ a ∷ []) ⊆h mk (a ∷ [])
dup-sub-single a w (here refl) = here refl
dup-sub-single a w (there (here refl)) = here refl
dup-sub-single a w (there (there ()))

single-sub-dup : (a : HF) -> mk (a ∷ []) ⊆h mk (a ∷ a ∷ [])
single-sub-dup a w (here refl) = here refl

-- 两个方向的包含都有了——"元素互含"成立，
-- 但 mk (a ∷ a ∷ []) ≡ mk (a ∷ []) 不成立（refl 会卡住）。
-- 商型外延化的完整方案在 02 章展开。
