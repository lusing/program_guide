-- 第 07 章 滤子与 club：有限域上的闭性检查器
--
-- club（闭无界）定义在正则基数 κ 上；有限序数域只有"闭"的
-- 类比（无界退化）。闭性 ⟺ 每个被自身元素从下方逼近的点
-- 都在集合内——这个内核是可判定的。

module Ch07_club where

open import Data.Nat using (ℕ; zero; suc; _<_; _≤_; _∸_; z≤n; s≤s)
open import Data.Nat.Properties using (_≟_; _<?_; _≤?_)
open import Data.Bool using (Bool; true; false; if_then_else_; _∧_)
open import Data.List using (List; []; _∷_; upTo)
open import Relation.Nullary using (yes; no)
open import Relation.Nullary.Decidable using (isYes)
open import Relation.Binary.PropositionalEquality using (_≡_; refl)

-- ---------- 一、成员与逼近（可判定内核） ----------

member? : ℕ → List ℕ → Bool
member? n [] = false
member? n (x ∷ xs) with (n ≟ x)
... | yes _ = true
... | no  _ = member? n xs

-- c 从下方一步逼近 k（|k - c| ≤ 1 且 c < k）
approaches : ℕ → ℕ → Bool
approaches c k =
  if isYes (c <? k)
  then isYes ((k ∸ c) ≤? 1)
  else false

has-approach : ℕ → List ℕ → Bool
has-approach k [] = false
has-approach k (c ∷ cs) =
  if approaches c k then true else has-approach k cs

-- ---------- 二、闭性检查 ----------
-- C 在 [0,N) 内闭 ⟺ 每个有逼近者的 k 都已在 C 中

check-point : List ℕ → ℕ → Bool
check-point C k =
  if member? k C then true
  else if has-approach k C then false
  else true

is-closed-in : List ℕ → ℕ → Bool
is-closed-in C N = go (upTo N)
  where
   go : List ℕ → Bool
   go [] = true
   go (k ∷ ks) = check-point C k ∧ go ks

-- ---------- 三、示例 ----------

odds : List ℕ
odds = 1 ∷ 3 ∷ 5 ∷ 7 ∷ 9 ∷ []

full : List ℕ
full = upTo 10

-- {奇数} 在 [0,10) 不闭（偶数 2 被 1、3 逼近而缺席）：
not-closed-odds : is-closed-in odds 10 ≡ false
not-closed-odds = refl

-- 全集显然闭：
closed-full : is-closed-in full 10 ≡ true
closed-full = refl

-- 加上偶数后闭（离散无逼近的补点，或全在场）：
evens-added : List ℕ
evens-added = 0 ∷ 1 ∷ 2 ∷ 3 ∷ 4 ∷ 5 ∷ 6 ∷ 7 ∷ 8 ∷ 9 ∷ []
closed-after-fill : is-closed-in evens-added 10 ≡ true
closed-after-fill = refl
