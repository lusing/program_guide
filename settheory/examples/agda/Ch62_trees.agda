-- 第 62 章：树的构造性面貌（Makinson Ch7）
-- 归纳类型即"新根法递归"的原生形态；BST 搜索；n−1 边的机器验证。
module Ch62_trees where

open import Data.Nat using (ℕ; zero; suc; _+_; _*_)
open import Data.Nat.Properties using (_≟_)
open import Data.Bool using (Bool; true; false; if_then_else_)
open import Data.Product using (_×_; _,_)
open import Relation.Nullary using (yes; no)
open import Relation.Binary.PropositionalEquality
  using (_≡_; refl)

-- ---------- 二叉树：新根法递归 ----------

data BTree : Set where
  leaf : BTree
  node : BTree → ℕ → BTree → BTree

-- ---------- BST 搜索：三分支递归 ----------

leb : ℕ → ℕ → Bool
leb zero _ = true
leb _ zero = false
leb (suc m) (suc n) = leb m n

search : BTree → ℕ → Bool
search leaf _ = false
search (node l a r) x with x ≟ a
... | yes _ = true
... | no _ with leb x a
...     | true = search l x
...     | false = search r x

-- 书中 BST (d)
tD : BTree
tD = node (node (node leaf 2 leaf) 3 (node leaf 4 leaf)) 5
          (node (node leaf 6 leaf) 7 (node (node leaf 9 leaf) 10 leaf))

w-search6 : search tD 6 ≡ true
w-search6 = refl

w-search8 : search tD 8 ≡ false
w-search8 = refl

w-search9 : search tD 9 ≡ true
w-search9 = refl

-- ---------- 节点数与边数 ----------

nodes : BTree → ℕ
nodes leaf = 0
nodes (node l _ r) = 1 + nodes l + nodes r

edges : BTree → ℕ
edges leaf = 0
edges (node leaf x leaf) = 0
edges (node l x r) = edges l + edges r
  + (if ne l then 1 else 0) + (if ne r then 1 else 0)
  where
  ne : BTree → Bool
  ne leaf = false
  ne (node _ _ _) = true

-- 具体验证：tD 有 8 节点 7 边（n−1 条边）
w-nodes8 : nodes tD ≡ 8
w-nodes8 = refl

w-edges7 : edges tD ≡ 7
w-edges7 = refl

-- 链：3 节点 2 边；星型：4 节点 3 边
chain3 : BTree
chain3 = node (node (node leaf 1 leaf) 2 leaf) 3 leaf

star4 : BTree
star4 = node (node leaf 1 leaf) 0 (node leaf 2 (node leaf 3 leaf))

w-chain : nodes chain3 ≡ 3 × edges chain3 ≡ 2
w-chain = refl , refl

w-star : nodes star4 ≡ 4 × edges star4 ≡ 3
w-star = refl , refl

-- n − 1 边：三例机器验证（一般归纳证明见 Coq/Lean 通道）
