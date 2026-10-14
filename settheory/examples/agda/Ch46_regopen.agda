-- 第 46 章 预序字典：2^<3 前缀序上的稠密/前稠密/原子/相容性检查

module Ch46_regopen where

open import Data.Bool using (Bool; true; false; _∧_; _∨_; not)
open import Data.Nat using (ℕ; zero; suc)
open import Data.List using (List; []; _∷_; _++_; concatMap; map)
open import Data.Product using (_×_; _,_)
open import Relation.Binary.PropositionalEquality using (_≡_; refl; cong)

eqb : Bool → Bool → Bool
eqb true true = true
eqb false false = true
eqb _ _ = false

-- 自写 allB/anyB（Data.List.all 已弃用——坑位总账 #19 套路）
allB : {A : Set} → (A → Bool) → List A → Bool
allB f [] = true
allB f (x ∷ xs) = f x ∧ allB f xs

anyB : {A : Set} → (A → Bool) → List A → Bool
anyB f [] = false
anyB f (x ∷ xs) = f x ∨ anyB f xs

-- prefixb p q := "p 是 q 的初始段"（与 Ch16 一致）
prefixb : List Bool → List Bool → Bool
prefixb [] _ = true
prefixb (_ ∷ _) [] = false
prefixb (x ∷ xs) (y ∷ ys) = eqb x y ∧ prefixb xs ys

-- Cohen 方向的序：s ⊑ t := t 是 s 的初始段（延拓 = 精化）
infix 4 _⊑_

_⊑_ : List Bool → List Bool → Bool
s ⊑ t = prefixb t s

-- 相容：有公共延拓（前缀序中 ⟺ 一方是另一方初始段）
compat : List Bool → List Bool → Bool
compat s t = prefixb s t ∨ prefixb t s

-- 0-1 串各长度层：layers n = 恰长 n 的全体
bit : List Bool
bit = true ∷ false ∷ []

layers : ℕ → List (List Bool)
layers zero = [] ∷ []
layers (suc n) = concatMap (λ s → map (λ b → b ∷ s) bit) (layers n)

P<3 : List (List Bool)
P<3 = layers zero ++ layers 1 ++ layers 2

-- 稠密：∀p ∈ P<3, ∃q ∈ D 使 q ⊑ p（D 能延拓到每个条件下方）
denseb : List (List Bool) → Bool
denseb D = allB (λ p → anyB (λ q → q ⊑ p) D) P<3

-- 前稠密：∀p ∈ P<3, ∃q ∈ D 与 p 相容
predenseb : List (List Bool) → Bool
predenseb D = allB (λ p → anyB (λ q → compat q p) D) P<3

-- 无原子：每个 p 都有两个互不相容的严格精化 p⌢b（尾接才是延拓！）
split-refine : List Bool → List Bool × List Bool
split-refine s = (s ++ (true ∷ [])) , (s ++ (false ∷ []))

atomless : Bool
atomless = allB (λ p → let (l , r) = split-refine p
                      in (l ⊑ p) ∧ (r ⊑ p) ∧ not (compat l r)) P<3

-- ---- 事实锁定（真值由 refl 冻结） ----

-- P<3 自身稠密（取 q = p，⊑ 自反）
⊑-refl : (p : List Bool) → (p ⊑ p) ≡ true
⊑-refl p = prefixb-refl p
  where
   prefixb-refl : (p : List Bool) → prefixb p p ≡ true
   prefixb-refl [] = refl
   prefixb-refl (true ∷ xs) = cong (true ∧_) (prefixb-refl xs)
   prefixb-refl (false ∷ xs) = cong (true ∧_) (prefixb-refl xs)

dense-P : denseb P<3 ≡ true
dense-P = refl

-- 单点 {[ ]} 不稠密：空串不能延拓到长度 1 的条件
not-dense-unit : denseb ([] ∷ []) ≡ false
not-dense-unit = refl

-- 但 {[ ]} 前稠密：空串与一切相容（它是所有串的初始段）
predense-unit : predenseb ([] ∷ []) ≡ true
predense-unit = refl

-- 2^<3 无原子（Viale Exercise 2.2.12 的有限核查）
atomless-P : atomless ≡ true
atomless-P = refl

-- 长度 2 的四个串：两两不相容的极大反链
antichain-2 : List (List Bool)
antichain-2 = (true ∷ true ∷ []) ∷ (true ∷ false ∷ []) ∷
              (false ∷ true ∷ []) ∷ (false ∷ false ∷ []) ∷ []

_≟l_ : List Bool → List Bool → Bool
[] ≟l [] = true
[] ≟l (_ ∷ _) = false
(_ ∷ _) ≟l [] = false
(x ∷ xs) ≟l (y ∷ ys) = eqb x y ∧ (xs ≟l ys)

pairwise-incompat : Bool
pairwise-incompat =
  allB (λ s → allB (λ t → not (compat s t) ∨ (s ≟l t)) antichain-2) antichain-2

-- 极大反链 = 前稠密 + 两两不相容
max-antichain-2 : pairwise-incompat ∧ predenseb antichain-2 ≡ true
max-antichain-2 = refl
