-- 第 08 章 奇异基数：几乎不交函数族的构造性核查
--
-- Silver 证明链的组合核：f ≠ g ⟹ 除有界多处外 f(α) ≠ g(α)。
-- 有限域版本是可判定检查。

module Ch08_adf where

open import Data.Nat using (ℕ; zero; suc; _≟_)
open import Data.Bool using (Bool; true; false; if_then_else_; _∧_)
open import Relation.Nullary using (yes; no)
open import Relation.Nullary.Decidable using (isYes)
open import Relation.Binary.PropositionalEquality using (_≡_; refl)

-- ---------- 一、有限域上的几乎不交判定 ----------
-- 检查窗口 [B, B+K) 内无碰撞即"几乎不交的有限证据"
ad-window : (f g : ℕ → ℕ) (B K : ℕ) → Bool
ad-window f g B K = go B K
  where
   go : ℕ → ℕ → Bool
   go _ zero = true
   go n (suc k) =
     if isYes ((f n) ≟ (g n)) then false
     else go (suc n) k

-- ---------- 二、常值函数族的几乎不交性 ----------

f3 : ℕ → ℕ
f3 _ = 3

g7 : ℕ → ℕ
g7 _ = 7

-- 3-常值与 7-常值从 0 起就逐点不同
ad-3-7 : ad-window f3 g7 0 10 ≡ true
ad-3-7 = refl

-- 自己与自己"碰撞"——不是几乎不交
ad-self : ad-window f3 f3 0 10 ≡ false
ad-self = refl

-- ---------- 三、切片分离（Silver 构造的核） ----------
-- X ≠ Y ⟹ f_X 与 f_Y 在 max 后分离

slice₃ : ℕ → ℕ
slice₃ _ = 3

slice₅ : ℕ → ℕ
slice₅ _ = 5

ad-slices : ad-window slice₃ slice₅ 0 10 ≡ true
ad-slices = refl
