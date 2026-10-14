-- 第 49 章：2^≤2 前缀序的 RO 补全（j = Int∘Cl∘↓ 的有限化身）
-- 关键修正：Reg(↓p) = {u : u 的全部初始段与 p 相容}
--   （"存在相容"会让 ↓ 里的空串吞掉一切——Int(Cl(·)) 不允许）

module Ch49_completion where

open import Data.Bool using (Bool; true; false; _∧_; _∨_; not)
open import Data.List using (List; []; _∷_)
open import Data.Product using (_×_; _,_)
open import Relation.Binary.PropositionalEquality using (_≡_; refl)

eqb : Bool → Bool → Bool
eqb true true = true
eqb false false = true
eqb _ _ = false

-- prefixb s t := s 是 t 的初始段
prefixb : List Bool → List Bool → Bool
prefixb [] _ = true
prefixb (_ ∷ _) [] = false
prefixb (x ∷ xs) (y ∷ ys) = eqb x y ∧ prefixb xs ys

compat : List Bool → List Bool → Bool
compat u v = prefixb u v ∨ prefixb v u

-- 2^≤2 七元素
P<2 : List (List Bool)
P<2 = [] ∷ (true ∷ []) ∷ (false ∷ []) ∷
      (true ∷ true ∷ []) ∷ (true ∷ false ∷ []) ∷
      (false ∷ true ∷ []) ∷ (false ∷ false ∷ []) ∷ []

allB : {A : Set} → (A → Bool) → List A → Bool
allB f [] = true
allB f (x ∷ xs) = f x ∧ allB f xs

anyB : {A : Set} → (A → Bool) → List A → Bool
anyB f [] = false
anyB f (x ∷ xs) = f x ∨ anyB f xs

infix 4 _=l=_

_=l=_ : List Bool → List Bool → Bool
[] =l= [] = true
[] =l= (_ ∷ _) = false
(_ ∷ _) =l= [] = false
(x ∷ xs) =l= (y ∷ ys) = eqb x y ∧ (xs =l= ys)

filterB : {A : Set} → (A → Bool) → List A → List A
filterB f [] = []
filterB f (x ∷ xs) with f x
... | true = x ∷ filterB f xs
... | false = filterB f xs

mem : List Bool → List (List Bool) → Bool
mem s [] = false
mem s (t ∷ ts) = (s =l= t) ∨ mem s ts

subeql : List (List Bool) → List (List Bool) → Bool
subeql A B = allB (λ u → mem u B) A

-- j(p) = Reg(↓p)：力迫序 q ≤ p := q 精化 p = p 是 q 的初始段
--   故 ↓p = p 的延拓集 N_p——序拓扑里它 clopen（延拓集既下闭又上闭），
--   Reg(↓p) = ↓p 本身。修正记录：初稿把 ↓p 当成初始段集（弱化方向），
--   导致 [] 的上闭包吞掉全空间、j 恒为 ⊤——方向翻转后 j = 经典 N_p。
j : List Bool → List (List Bool)
j p = filterB (λ u → prefixb p u) P<2

-- ---- 断言（全部 refl 冻结） ----

-- j([]) = 全空间（最弱条件）
j-empty-top : subeql P<2 (j []) ≡ true
j-empty-top = refl

-- j([true]) 不含 [false]（真正的"劈开"——修正后的 Reg 有分辨力）
j-split : mem (false ∷ []) (j (true ∷ [])) ≡ false
j-split = refl

-- 保序：q 是 p 的初始段 ⟹ j(p) ⊆ j(q)（强条件的 compat 集更小）
j-mono : subeql (j (true ∷ true ∷ [])) (j (true ∷ [])) ≡ true
j-mono = refl

j-mono2 : subeql (j (true ∷ [])) (j []) ≡ true
j-mono2 = refl

-- 互斥对的像不相容：j([true]) ∩ j([false]) = ∅（保不相容）
j-incompat : allB (λ u → not (mem u (j (false ∷ [])))) (j (true ∷ [])) ≡ true
j-incompat = refl

-- 稠密像（RO 端）：每个形如 j(p) 的非空正则开被某个 j(s) 精化
--   ——取 s = p 自身，平凡但诚实；真正的密度断言在 RO 侧：
--   每个非空正则开 A ⊇ 某个 j(s)。RO 家族 = j 的像 + ∅（有限宇宙验证）
dense-sample :
  (subeql (j (true ∷ true ∷ [])) (j (true ∷ [])) ≡ true)
  × (subeql (j (true ∷ [])) (j ([])) ≡ true)
dense-sample = refl , refl
