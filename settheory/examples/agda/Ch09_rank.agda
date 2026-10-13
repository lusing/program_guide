-- 第 09 章 正则公理：HF 的秩函数
--
-- V = ⋃ V_α 的有限层：V₀ = ∅，V_{n+1} = P(V_n)。
-- 在 HF 上秩是可计算函数：rank(x) = sup{rank(y)+1 : y ∈ x}。

module Ch09_rank where

open import Data.Nat using (ℕ; zero; suc; _⊔_; _<_; _≤_; z≤n; s≤s)
open import Data.List using (List; []; _∷_)
open import Data.List.Relation.Unary.Any using (here; there)
open import Data.List.Membership.Propositional using (_∈_)
open import Relation.Binary.PropositionalEquality using (_≡_; refl; cong; sym)
open import Relation.Nullary using (¬_)

-- HF 与隶属（第 01 章的形态）
data HF : Set where
  mk : (X : List HF) -> HF

infix 4 _∈h_

_∈h_ : HF -> HF -> Set
x ∈h mk X = x ∈ X

-- ---------- 一、秩函数（引理 9.2 的可计算形态） ----------

rank : HF -> ℕ
rank (mk []) = zero
rank (mk (x ∷ xs)) = suc (rank x) ⊔ rank (mk xs)

-- ---------- 二、秩的基本性质 ----------

open import Data.Nat.Properties using (m≤m⊔n)

-- 成员的秩严格更小（rank 的构造性"正则性"）
rank-mem< : (x : HF) (X : List HF) -> rank x < rank (mk (x ∷ X))
rank-mem< x X = m≤m⊔n (suc (rank x)) (rank (mk X))

-- 具体例子：∅ 的秩是 0；{∅} 的秩是 1；{∅,{∅}} 的秩是 2
∅ᴴ oneᴴ twoᴴ : HF
∅ᴴ   = mk []
oneᴴ = mk (∅ᴴ ∷ [])
twoᴴ = mk (∅ᴴ ∷ oneᴴ ∷ [])

rank-∅ : rank ∅ᴴ ≡ zero
rank-∅ = refl

rank-one : rank oneᴴ ≡ suc zero
rank-one = refl

rank-two : rank twoᴴ ≡ suc (suc zero)
rank-two = refl

-- ---------- 三、x ∈ x 不可能（正则公理的构造性形态） ----------
-- 若 x ∈ x 则 rank x < rank x——矛盾由序的不可自反给出。
-- （完整论证见 Lean 通道 Ch09Foundation 的 rank_lt_of_mem。）
