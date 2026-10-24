-- 第 73 章：快速增长数论函数层次（冯琦 §1.8.4）——Agda 通道
-- 构造性承载：F_α 层次的有限段（定义 1.84 的结构递归形态——F_{suc k}
-- = iterate (F_k)，极限步 F_ω(n) = F_n(n) 在有限段恰为对角线）；
-- F₁ n ≡ 2n、F₂ n ≡ n·2ⁿ 的等式证明链（定理 1.81(2) 的解析式见证）；
-- F₃ 2 ≡ 2048、Fω 2 ≡ 8 的规范化验证（refl 一眼看穿）。
-- Coq 通道承载遗传展开与古德斯坦剧场，这里专注"层次本身"的构造性。
module Ch73_fastgrowth where

open import Data.Nat using (ℕ; zero; suc; _+_; _*_; _^_)
open import Data.Nat.Properties
  using (+-identityʳ; +-suc; *-comm; *-assoc; *-identityʳ)
open import Relation.Binary.PropositionalEquality
  using (_≡_; refl; cong; trans; sym)

-- ---------- 迭代与 F 层次（定义 1.84 的结构递归形态） ----------
iterate : (ℕ → ℕ) → ℕ → ℕ → ℕ
iterate f zero x = x
iterate f (suc k) x = iterate f k (f x)

F0 : ℕ → ℕ
F0 n = suc n

F1 : ℕ → ℕ
F1 n = iterate F0 n n

F2 : ℕ → ℕ
F2 n = iterate F1 n n

F3 : ℕ → ℕ
F3 n = iterate F2 n n

-- F_k：可变层数；F_ω(n) = F_n(n) 的有限段即对角线
Fk : ℕ → ℕ → ℕ
Fk zero = F0
Fk (suc k) = λ n → iterate (Fk k) n n

Fω : ℕ → ℕ
Fω n = Fk n n

-- ---------- 迭代引理：F₀ 迭代 = 加 k ----------
iterate-F0 : ∀ k x → iterate F0 k x ≡ x + k
iterate-F0 zero x = sym (+-identityʳ x)        -- x ≡ x + 0（stdlib + 递归在首参，x+0 须引理）
iterate-F0 (suc k) x =
  trans (iterate-F0 k (suc x))                 -- ≡ suc x + k ≡ suc (x + k)（定义）
        (sym (+-suc x k))                      -- ≡ x + suc k

-- ---------- F₁ 的闭式：F₁ x ≡ x · 2 ----------
F1-closed-x : ∀ x → F1 x ≡ x * 2
F1-closed-x x =
  trans (iterate-F0 x x)                       -- ≡ x + x
        (trans (cong (λ t → x + t) (sym (+-identityʳ x)))
                                               -- ≡ x + (x + 0) ≡ 2 * x（定义）
               (*-comm 2 x))                   -- ≡ x * 2

-- ---------- F₁ 迭代 = 乘 2^k ----------
iterate-F1 : ∀ k x → iterate F1 k x ≡ x * (2 ^ k)
iterate-F1 zero x = sym (*-identityʳ x)        -- x ≡ x * 1
iterate-F1 (suc k) x =
  trans (iterate-F1 k (F1 x))                  -- ≡ F1 x * 2^k
        (trans (cong (λ t → t * (2 ^ k)) (F1-closed-x x))
                                               -- ≡ (x * 2) * 2^k
               (*-assoc x 2 (2 ^ k)))          -- ≡ x * (2 * 2^k) ≡ x * 2^(suc k)（定义）

-- ---------- 定理 1.81(2) 的解析式见证 ----------
F1-closed : ∀ n → F1 n ≡ 2 * n
F1-closed n = trans (F1-closed-x n) (*-comm n 2)

F2-closed : ∀ n → F2 n ≡ n * (2 ^ n)
F2-closed n = iterate-F1 n n

-- ---------- 规范化验证（refl 一眼看穿） ----------
F3-2 : F3 2 ≡ 2048
F3-2 = refl                                    -- F₂(F₂(2)) = F₂(8) = 8·2⁸

Fω-1 : Fω 1 ≡ 2
Fω-1 = refl                                    -- F₁(1)

Fω-2 : Fω 2 ≡ 8
Fω-2 = refl                                    -- F₂(2)

F2-24 : F2 24 ≡ 24 * (2 ^ 24)
F2-24 = F2-closed 24                           -- 改写不求值：4 亿个 suc 无人受得了

-- F_ω(3) = F₃(3) = F₂(F₂(F₂(3)))：最外层自变量 402653184，
-- 值 = 402653184·2^402653184——一元 nat 的规范化器物理不可行，
-- 只以闭式记账（F2-24：24·2^24 恰是那个最外层自变量）。
