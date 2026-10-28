-- 第 81 章：完备二叉树的内在分支及其深度。
module Ch81_regularity where

open import Data.Nat using (ℕ; zero; suc; _+_)
open import Relation.Binary.PropositionalEquality using (_≡_; refl; cong)

data Tree : Set where
  leaf : Tree
  node : Tree → Tree → Tree

-- Path t 是树 t 的一条从根到叶的分支；构造子保证不会提前停止。
data Path : Tree → Set where
  stop : Path leaf
  left : ∀ {l r} → Path l → Path (node l r)
  right : ∀ {l r} → Path r → Path (node l r)

depth : ∀ {t} → Path t → ℕ
depth stop = 0
depth (left p) = suc (depth p)
depth (right p) = suc (depth p)

perfect : ℕ → Tree
perfect zero = leaf
perfect (suc n) = node (perfect n) (perfect n)

depth-perfect : ∀ {n} (p : Path (perfect n)) → depth p ≡ n
depth-perfect {zero} stop = refl
depth-perfect {suc n} (left p) = cong suc (depth-perfect p)
depth-perfect {suc n} (right p) = cong suc (depth-perfect p)

count : Tree → ℕ
count leaf = 1
count (node l r) = count l + count r

pow2 : ℕ → ℕ
pow2 zero = 1
pow2 (suc n) = pow2 n + pow2 n

count-perfect : ∀ n → count (perfect n) ≡ pow2 n
count-perfect zero = refl
count-perfect (suc n) rewrite count-perfect n = refl

-- 第 3 层有 8 条分支，每条分支的深度都是 3。
eight-branches : count (perfect 3) ≡ 8
eight-branches = refl

sample-path : Path (perfect 2)
sample-path = right (left stop)

sample-depth : depth sample-path ≡ 2
sample-depth = refl
