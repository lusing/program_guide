-- 第 04 章 实数：Baire 空间的树表示（Jech (4.10)-(4.13)）
--
-- 𝒩 = ℕ→ℕ（Baire 空间）。闭集 ↔ 无极大节点的树 T：
-- f ∈ [T] ⟺ f 的每个初始段都在 T 里。导树 T' 剥掉"单干道"。

module Ch04_reals where

open import Data.Nat using (ℕ; zero; suc)
open import Data.List using (List; []; _∷_; length)
open import Data.Product using (_×_; _,_; ∃)
open import Data.Sum using (_⊎_; inj₁; inj₂)
open import Data.Unit using (⊤; tt)
open import Data.Empty using (⊥)
open import Relation.Binary.PropositionalEquality using (_≡_; refl; cong)

Baire : Set
Baire = ℕ → ℕ

-- 初始段关系（列表 ≤ 列表）
infix 4 _⊑_

_⊑_ : List ℕ → List ℕ → Set
[]       ⊑ _        = ⊤
(_ ∷ _)  ⊑ []       = ⊥
(x ∷ xs) ⊑ (y ∷ ys) = (x ≡ y) × (xs ⊑ ys)

-- f 的前 k 项（函数 → 列表）
prefix : ℕ → Baire → List ℕ
prefix zero    f = []
prefix (suc k) f = f zero ∷ prefix k (λ n → f (suc n))

-- f 延伸 s：f 的前 length s 项恰为 s（U_s 的成员条件）
infix 4 _≺_

_≺_ : Baire → List ℕ → Set
f ≺ s = prefix (length s) f ≡ s

-- ---------- 树：对初始段封闭的序列集 ----------

isTree : (List ℕ → Set) → Set
isTree T = ∀ t s → T t → s ⊑ t → T s

-- ---------- 两棵具体的树 ----------

-- 全树：所有有限序列都属于 T_full。[T_full] = 整个 Baire 空间
T-full : List ℕ → Set
T-full _ = ⊤

full-is-tree : isTree T-full
full-is-tree t s _ _ = tt

-- 有限树：只收录长度 ≤ 2 的序列（有极大节点，[T] = ∅）
open import Data.Nat using (_≤_)

T-bounded : List ℕ → Set
T-bounded s = length s ≤ 2

-- ---------- 导树 T'（Jech (4.13)）----------
-- t ∈ T' ⟺ T 里有两条互不相容的真延伸（"分叉节点"）

infixl 5 _++_

_++_ : List ℕ → List ℕ → List ℕ
[] ++ ys = ys
(x ∷ xs) ++ ys = x ∷ (xs ++ ys)

incompatible : List ℕ → List ℕ → Set
incompatible s t = (s ⊑ t → ⊥) × (t ⊑ s → ⊥)

-- T' 的成员条件（谓词提升版）
T-der : (List ℕ → Set) → List ℕ → Set
T-der T t = ∃ λ s₁ → ∃ λ s₂ →
              (T s₁) × (T s₂) × (t ⊑ s₁) × (t ⊑ s₂) × incompatible s₁ s₂

-- 首项不同的延伸必不相容（对公共前缀 t 归纳）
zero-one-incompat : (t : List ℕ) →
  ((t ++ (0 ∷ [])) ⊑ (t ++ (1 ∷ [])) → ⊥) × ((t ++ (1 ∷ [])) ⊑ (t ++ (0 ∷ [])) → ⊥)
zero-one-incompat []      = (λ { (() , _) }) , (λ { (() , _) })
zero-one-incompat (x ∷ t) =
  (λ { (refl , p) → proj₁ (zero-one-incompat t) p }) ,
  (λ { (refl , p) → proj₂ (zero-one-incompat t) p })
  where
   open import Data.Product using (proj₁; proj₂)

-- t 是 t ++ (a ∷ []) 的初始段（自反延伸）
⊑-append : (t : List ℕ) (a : ℕ) → t ⊑ t ++ (a ∷ [])
⊑-append []      a = tt
⊑-append (x ∷ t) a = refl , ⊑-append t a

-- 具体事实：全树处处分叉（每个节点都派生 0/1 两枝）
T-full-derived : (t : List ℕ) → T-der T-full t
T-full-derived t =
  (t ++ (0 ∷ []) , t ++ (1 ∷ []) ,
   tt , tt ,
   ⊑-append t 0 , ⊑-append t 1 ,
   zero-one-incompat t)

-- 结论骨架：T-full = T-full'（完美）；有限树迭代导树终将见空。
-- [T]-[T'] 至多可数的论证（Jech §4 末）在 docs 正文展开。
