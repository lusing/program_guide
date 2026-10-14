-- 第 61 章：有限概率的构造性面貌（Makinson Ch6）
-- 骰子对条件概率的计数 + 辛普森比值 + 贝叶斯交叉相乘。
module Ch61_probability where

open import Data.Nat using (ℕ; zero; suc; _+_; _*_; _≟_; _<_; _≤?_; _<?_)
open import Data.Nat.Base using (_≡ᵇ_)
open import Data.List using (List; []; _∷_; length; filter; concat; map)
open import Data.Product using (_×_; _,_; proj₁; proj₂)
open import Data.Bool using (Bool; true; false; if_then_else_; _∨_; not)
open import Relation.Binary.PropositionalEquality using (_≡_; refl)

-- ---------- 骰子对（和为 5 / 含 3） ----------

diePairs : List (ℕ × ℕ)
diePairs = concat (map (λ a → map (λ b → (a , b)) (1 ∷ 2 ∷ 3 ∷ 4 ∷ 5 ∷ 6 ∷ []))
                        (1 ∷ 2 ∷ 3 ∷ 4 ∷ 5 ∷ 6 ∷ []))

filterB : (ℕ × ℕ → Bool) → List (ℕ × ℕ) → List (ℕ × ℕ)
filterB f [] = []
filterB f (x ∷ xs) = if f x then x ∷ filterB f xs else filterB f xs

sumIs5 : ℕ × ℕ → Bool
sumIs5 p = proj₁ p + proj₂ p ≡ᵇ 5

has3 : ℕ × ℕ → Bool
has3 p = (proj₁ p ≡ᵇ 3) ∨ (proj₂ p ≡ᵇ 3)

n-B : ℕ
n-B = length (filterB (λ p → sumIs5 p) diePairs)

n-AB : ℕ
n-AB = length (filterB (λ p → both (sumIs5 p) (has3 p)) diePairs)
  where
  both : Bool → Bool → Bool
  both true b = b
  both false _ = false

n-A : ℕ
n-A = length (filterB (λ p → has3 p) diePairs)

cert-B4 : n-B ≡ 4
cert-B4 = refl

cert-AB2 : n-AB ≡ 2
cert-AB2 = refl

cert-A11 : n-A ≡ 11
cert-A11 = refl

-- p(A|B) = 2/4：交叉相乘 2*4 = 2*4（比例由分子分母各自承载）
cert-cross : (n-AB * 4) ≡ (2 * n-B)
cert-cross = refl

-- ---------- 辛普森：分系与合计的交叉相乘 ----------

-- 分系反转：2*5 > 1*8 与 4*8 > 6*5；合计反转：6*13 < 7*13
-- 无序数上的 > 用加法Witness：2*5 = 1*8+2 与 4*8 = 6*5+2
simpson-split1 : 2 * 5 ≡ 1 * 8 + 2
simpson-split1 = refl

simpson-split2 : 4 * 8 ≡ 6 * 5 + 2
simpson-split2 = refl

simpson-total : 6 * 13 + 13 ≡ 7 * 13
simpson-total = refl

-- ---------- 贝叶斯：交叉相乘证书 ----------

bayes-cancer : 5 * 208 ≡ 104 * 10
bayes-cancer = refl

bayes-hiv : 270 * 1605 ≡ 1350 * 321
bayes-hiv = refl

bayes-operators : 60 * 33 + 70 * 37 + 90 * 30 ≡ 7270
bayes-operators = refl

-- ---------- 期望三马：12 − 3 − 6 = 3（以 0.1 为单位） ----------

expectation : 12 * 1 ≡ 3 + 6 + 3
expectation = refl
