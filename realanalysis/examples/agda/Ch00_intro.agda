-- 第 00 章 导言：Agda 通道。
-- Agda 的核心是 Curry–Howard：命题即类型，证明即程序。
-- 本章用自然数上的定义相等与 Archimedean 性质热身。

module Ch00_intro where

open import Data.Nat using (ℕ; zero; suc; _+_; _*_; _>_)
open import Data.Nat.Properties using (n<1+n)
open import Data.Product using (Σ; _,_)
open import Relation.Binary.PropositionalEquality using (_≡_; refl)

-- 精确算术：自然数化简是定义级的，refl 一词即可闭合。
-- 对照机器浮点：这种“算出来就严格相等”在 Float 世界并不成立。
exact-two-plus-two : 2 + 2 ≡ 4
exact-two-plus-two = refl

exact-distrib : 2 * (5 + 3) ≡ 2 * 5 + 6
exact-distrib = refl

-- 同一律：命题 A → A 的证明就是恒等函数（Curry–Howard 的第一块积木）。
identity : ∀ {A : Set} → A → A
identity x = x

-- Archimedean 性质的构造版（自然数域）：对每个 n 都能构造出
-- 一个严格更大的数 suc n，证据 n < 1+n 由标准库给出。
archimedean-nat : ∀ (n : ℕ) → Σ ℕ (λ m → m > n)
archimedean-nat n = suc n , n<1+n n

-- 迭代构造：从任意 n 出发连续取 k 次后继，仍然是良定义的自然数。
-- 这就是“无限”在构造数学里的样子：不是一个完成的对象，
-- 而是一台可以一直按下去的机器。
repeat-suc : ℕ → ℕ → ℕ
repeat-suc n zero    = n
repeat-suc n (suc k) = suc (repeat-suc n k)

-- 每多按一次后继，结果严格变大——比较的是相邻两层迭代的输出。
repeat-grows : ∀ n k → repeat-suc n (suc k) > repeat-suc n k
repeat-grows n k = n<1+n (repeat-suc n k)
