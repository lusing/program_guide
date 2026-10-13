-- 第 20 章 积力迫：Product Lemma 的骨架
module Ch20_products where

open import Data.Product using (_×_; _,_; proj₁; proj₂)
open import Relation.Binary.PropositionalEquality using (_≡_; refl)

-- 积条件
ProdCond : Set → Set → Set
ProdCond A B = A × B

-- 投影
π₁ : {A B : Set} → ProdCond A B → A
π₁ = proj₁

π₂ : {A B : Set} → ProdCond A B → B
π₂ = proj₂

-- Product Lemma 的语义声明（完整证明见 docs 讲义）
-- G 泛型于 A×B ⟺ G = G₁×G₂（G₁ 泛型于 A，G₂ 泛型于 M[G₁]）
