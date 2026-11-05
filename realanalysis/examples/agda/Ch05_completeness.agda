-- 第 05 章 实数域（下）：Agda 通道。
-- 完备性（最小上界性质）在构造主义里不成立——它正是 ℝ 的公理。
-- 但它的离散影子可以纯构造地证明：ℕ 上任何在某个 b 处为真的
-- 可判定谓词都有“最小真值点”。这就是最小上界性质的
-- 离散版本：无限上升的可判定链条必有首个成立位置。

module Ch05_completeness where

open import Data.Bool using (Bool; true; false)
open import Data.Nat using (ℕ; zero; suc; _≤_; _<_; _*_; _≤ᵇ_; z≤n; s≤s)
open import Data.Product using (Σ; _×_; _,_)
open import Data.Empty using (⊥-elim)
open import Relation.Nullary using (¬_)
open import Relation.Binary.PropositionalEquality
  using (_≡_; refl; sym; trans)

-- Bool 的两个值不同（空模式即判据）。
false≢true : ¬ (false ≡ true)
false≢true ()

-- 最小真值点：给定 P 在 b 处为真，存在 n 使 P n 为真，
-- 且任何满足 P 的 m 都 ≥ n。
-- 归纳 b：若 P 0 为真则 n = 0 最小性平凡；
-- 否则把谓词整体左移一位（P′ n = P (suc n)），在更小的界 b 上递归，
-- 再把结果右移回来。
-- 移位引理：P 0 为假时，左移谓词 P′ n = P (suc n) 的最小真值点
-- 右移一位即为 P 的最小真值点。
shift-min : ∀ (P : ℕ → Bool) → P 0 ≡ false →
            Σ ℕ (λ n → (P (suc n) ≡ true) × (∀ m → P (suc m) ≡ true → n ≤ m)) →
            Σ ℕ (λ n → (P n ≡ true) × (∀ m → P m ≡ true → n ≤ m))
shift-min P eq0 (n' , pt' , min') = suc n' , pt' , go
  where
  go : ∀ m → P m ≡ true → suc n' ≤ m
  go zero    pm = ⊥-elim (false≢true (trans (sym eq0) pm))
  go (suc m) pm = s≤s (min' m pm)

find-min : ∀ (P : ℕ → Bool) (b : ℕ) → P b ≡ true →
           Σ ℕ (λ n → (P n ≡ true) × (∀ m → P m ≡ true → n ≤ m))
find-min P zero    pb = 0 , pb , λ _ _ → z≤n
find-min P (suc b) pb with P 0 in eq0
... | true  = 0 , eq0 , λ _ _ → z≤n
... | false = shift-min P eq0 (find-min (λ n → P (suc n)) b pb)

-- 实例：找第一个满足 100 ≤ n * n 的 n（即 10 的离散判定）。
-- 这是“{n | n² ≥ 100} 的最小元”——离散世界里的上确界计算。
P100 : ℕ → Bool
P100 n = 100 ≤ᵇ (n * n)

answer : Σ ℕ (λ n → (P100 n ≡ true) × (∀ m → P100 m ≡ true → n ≤ m))
answer = find-min P100 100 refl
