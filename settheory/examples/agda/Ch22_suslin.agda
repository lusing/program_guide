-- 第 22 章 Suslin 树：树结构骨架
module Ch22_suslin where

open import Data.Nat using (ℕ; zero; suc; _+_; _⊔_)
open import Relation.Binary.PropositionalEquality using (_≡_; refl)

-- 二叉树
data Tree : Set where
  leaf : ℕ → Tree
  node : ℕ → Tree → Tree → Tree

-- 高度
height : Tree → ℕ
height (leaf _) = 1
height (node _ l r) = suc (height l ⊔ height r)

h-leaf : height (leaf 0) ≡ 1
h-leaf = refl

h-node : height (node 0 (leaf 1) (leaf 2)) ≡ 2
h-node = refl
