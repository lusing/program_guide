-- 第 21 章 对称子模型：对称性骨架
module Ch21_symmetric where

open import Data.Bool using (Bool; true; false)
open import Data.List using (List)
open import Data.Nat using (ℕ; zero; suc)
open import Relation.Binary.PropositionalEquality using (_≡_; refl)

-- 置换的作用：群元素作用于对象
Action : Set → Set → Set
Action A G = G → A → A

-- 对称性骨架（完整理论见 docs 讲义）
-- sym(x) = {π ∈ G : π(x) = x}
-- 正规滤子 (21.5)(i)-(iv)；遗传对称类 ⊨ ZF(A)
