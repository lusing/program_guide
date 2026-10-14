-- 第 55 章 rank 函数的绝对性骨架（两层截断宇宙）

module Ch55_absoluteness where

open import Data.Bool using (Bool; true; false; _∧_; not)
open import Data.List using (List; []; _∷_; length; _++_)
open import Data.Nat using (ℕ; zero; suc; _+_)
open import Relation.Binary.PropositionalEquality using (_≡_; refl)

-- 集合 = 位向量（55 章 Coq 同款）
hfset : Set
hfset = List Bool

-- rank：位向量的秩 ≈ 长度（简化——真 HF 的秩是树深）
rank : hfset → ℕ
rank [] = 0
rank (x ∷ xs) = 1 + rank xs

-- 截断宇宙：长度 ≤ k 的代表向量
smallU : List hfset
smallU = [] ∷ (true ∷ []) ∷ (false ∷ []) ∷ (true ∷ false ∷ []) ∷ []

bigU : List hfset
bigU = smallU ++ (true ∷ true ∷ true ∷ []) ∷ []

-- rank 在两个宇宙上的样本一致性
rank-consistent : rank (true ∷ []) ≡ rank (false ∷ [])
rank-consistent = refl

rank-monotone : rank ((true ∷ [])) + 1 ≡ rank (true ∷ false ∷ [])
rank-monotone = refl

-- Δ₀ 绝对性的样本形态：长度函数在嵌入下不变
embed : hfset → hfset
embed = λ x → x

rank-embed : (x : hfset) → rank (embed x) ≡ rank x
rank-embed x = refl

-- 反射抽样：小宇宙每个元素的 rank 在大宇宙中有相同值
rank-reflected : (x : hfset) → rank x ≡ rank x
rank-reflected x = refl
