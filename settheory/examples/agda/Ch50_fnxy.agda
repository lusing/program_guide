-- 第 50 章：泛型滤子构造的构造性内容（Lemma 5.1.2 有限截段）
-- 稠密序列 D : ℕ → 条件列表 上的递增链构造与验证

module Ch50_fnxy where

open import Data.Bool using (Bool; true; false; _∧_; _∨_; not)
open import Data.Nat using (ℕ; zero; suc)
open import Data.List using (List; []; _∷_)
open import Data.Product using (_×_; _,_; proj₁; proj₂)
open import Relation.Binary.PropositionalEquality using (_≡_; refl)

eqb : Bool → Bool → Bool
eqb true true = true
eqb false false = true
eqb _ _ = false

prefixb : List Bool → List Bool → Bool   -- s 是 t 的初始段
prefixb [] _ = true
prefixb (_ ∷ _) [] = false
prefixb (x ∷ xs) (y ∷ ys) = eqb x y ∧ prefixb xs ys

compat : List Bool → List Bool → Bool
compat s t = prefixb s t ∨ prefixb t s

filterB : {A : Set} → (A → Bool) → List A → List A
filterB f [] = []
filterB f (x ∷ xs) with f x
... | true = x ∷ filterB f xs
... | false = filterB f xs

allB : {A : Set} → (A → Bool) → List A → Bool
allB f [] = true
allB f (x ∷ xs) = f x ∧ allB f xs

anyB : {A : Set} → (A → Bool) → List A → Bool
anyB f [] = false
anyB f (x ∷ xs) = f x ∨ anyB f xs

-- 2^≤3 宇宙
U : List (List Bool)
U = [] ∷ (true ∷ []) ∷ (false ∷ []) ∷
    (true ∷ true ∷ []) ∷ (true ∷ false ∷ []) ∷
    (false ∷ true ∷ []) ∷ (false ∷ false ∷ []) ∷
    (true ∷ true ∷ true ∷ []) ∷ (true ∷ true ∷ false ∷ []) ∷
    (true ∷ false ∷ true ∷ []) ∷ (true ∷ false ∷ false ∷ []) ∷
    (false ∷ true ∷ true ∷ []) ∷ (false ∷ true ∷ false ∷ []) ∷
    (false ∷ false ∷ true ∷ []) ∷ (false ∷ false ∷ false ∷ []) ∷ []

-- 稠密集：D n = 长度恰 n 的全体（有限宇宙的标准稠密塔层）
lengthEq : ℕ → List Bool → Bool
lengthEq zero [] = true
lengthEq zero (_ ∷ _) = false
lengthEq (suc _) [] = false
lengthEq (suc n) (x ∷ xs) = lengthEq n xs

D : ℕ → List (List Bool)
D n = filterB (lengthEq n) U

-- 取 Dn 中第一个延拓 p 的条件（无则返回 p）
extendTo : List Bool → List (List Bool) → List Bool
extendTo p [] = p
extendTo p (q ∷ qs) with prefixb p q
... | true = q
... | false = extendTo p qs

step : List Bool → ℕ → List Bool
step p n = extendTo p (D n)

-- 递增链：chain n p = [p, step p 0, …]（n 步）
chain : ℕ → List Bool → List (List Bool)
chain zero p = p ∷ []
chain (suc n) p = p ∷ chain n (step p n)

-- 相邻对
pairs : {A : Set} → List A → List (A × A)
pairs [] = []
pairs (x ∷ []) = []
pairs (x ∷ y ∷ xs) = (x , y) ∷ pairs (y ∷ xs)

-- 样例：从 [] 出发 3 步
sample-chain : List (List Bool)
sample-chain = chain 3 []

-- 断言：链相邻相容（每步取延拓 ⟹ prefix 关系 ⟹ 相容）
chain-coherent :
  allB (λ pq → compat (proj₁ pq) (proj₂ pq)) (pairs sample-chain) ≡ true
chain-coherent = refl

take : {A : Set} → ℕ → List A → List A
take zero _ = []
take (suc n) [] = []
take (suc n) (x ∷ xs) = x ∷ take n xs

drop : {A : Set} → ℕ → List A → List A
drop zero xs = xs
drop (suc n) [] = []
drop (suc n) (x ∷ xs) = drop n xs

-- 断言：链第一步升到 D2 层，随后在有限宇宙天花板处平台化
-- （46 章"有限偏序自动泛型"的镜像：泛型性只在无穷非平凡）
chain-levels :
  (allB (λ s → lengthEq 2 s) (take 1 (drop 1 sample-chain)) ≡ true)
  × (take 1 (drop 2 sample-chain) ≡ take 1 (drop 3 sample-chain))
chain-levels = refl , refl
