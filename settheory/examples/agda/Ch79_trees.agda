-- 第 79 章：树、苏斯林树、马丁公理与划分定理（冯琦 §2.5–2.6）——Agda 通道
-- 树定义 2.31 的构造性侧影：用 rose tree（叶带标号，内节点带一棵子树表）
-- 结构递归地计算高度。height 沿子节点表取最大值再加 1；对满二叉树
-- fullTree n 机器验证高度恰为 n，对单链 chain n 同样为 n。
-- 注意边界：结构归纳只覆盖「每棵子树都有穷」的有限树；柯尼希引理的无穷
-- 树枝（定理 2.41）需要选择函数逐次走「有无穷后继」的孩子，不能由这里的
-- 结构递归推出，正文给出选择函数证明。
module Ch79_trees where

open import Data.Nat using (ℕ; zero; suc; _⊔_)
open import Data.List using (List; []; _∷_)
open import Data.Unit using (⊤; tt)
open import Relation.Binary.PropositionalEquality using (_≡_; refl; cong; trans)

-- rose tree：leaf a 为终结节点，node a ts 为带有序子树表的内节点。
data Tree (A : Set) : Set where
  leaf : A → Tree A
  node : A → List (Tree A) → Tree A

-- 定义 2.31(4) 的有限形态：叶高 0，内节点高 = 1 + 子树最大高度。
-- height 与 heightList 相互结构递归：heightList 在子树表的头元素 t 上
-- 调 height，t 是 node 实参的子项，终止检查器认得这条路。
mutual
  height : ∀ {A} → Tree A → ℕ
  height (leaf _) = zero
  height (node _ ts) = suc (heightList ts)

  heightList : ∀ {A} → List (Tree A) → ℕ
  heightList [] = zero
  heightList (t ∷ ts) = height t ⊔ heightList ts

-- 自然数 max 的两条算术事实（结构归纳自证，不引库）。
max-zero : ∀ n → n ⊔ 0 ≡ n
max-zero zero = refl
max-zero (suc n) = refl

max-idem : ∀ n → n ⊔ n ≡ n
max-idem zero = refl
max-idem (suc n) = cong suc (max-idem n)

-- 两个等高孩子合并后高度不变：满二叉树递推 height(node(t,t))=height(t)+1 的内核。
dup-height : ∀ {A} (t : Tree A) → heightList (t ∷ t ∷ []) ≡ height t
dup-height t
  rewrite max-zero (height t) | max-idem (height t) = refl

-- 深度 n 的满二叉树：fullTree 0 为叶，fullTree (n+1) 带两个 fullTree n。
fullTree : ℕ → Tree ⊤
fullTree zero = leaf tt
fullTree (suc n) = node tt (fullTree n ∷ fullTree n ∷ [])

-- 满二叉树高度恰为深度（dup-height 保证每一层只加 1）。
height-full : ∀ n → height (fullTree n) ≡ n
height-full zero = refl
height-full (suc n) =
  cong suc (trans (dup-height (fullTree n)) (height-full n))

-- 单子节点表的高度就是那个孩子的高度。
single-height : ∀ {A} (t : Tree A) → heightList (t ∷ []) ≡ height t
single-height t
  rewrite max-zero (height t) = refl

-- 单链树（每内节点只有一个孩子）：另一极端，高度同样等于深度。
chain : ℕ → Tree ⊤
chain zero = leaf tt
chain (suc n) = node tt (chain n ∷ [])

height-chain : ∀ n → height (chain n) ≡ n
height-chain zero = refl
height-chain (suc n) =
  cong suc (trans (single-height (chain n)) (height-chain n))

-- 具体样本：叶 + 深度 2 的满二叉树为孩子，根高 3。
sample : Tree ⊤
sample = node tt (leaf tt ∷ fullTree 2 ∷ [])

height-sample : height sample ≡ 3
height-sample = refl

-- 深度 3 的满二叉树高 3，逐点具体值。
height-full3 : height (fullTree 3) ≡ 3
height-full3 = refl
