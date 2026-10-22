-- 第 68 章：自然数与第一递归定义定理（冯琦 §1.3）
-- 加法递归在第二变元（书的原始形状）；交换律的双归纳（书页 51
-- 六步推导的原生形态）；与 stdlib 的 +-comm 对照。
module Ch68_naturals where

open import Data.Nat using (ℕ; zero; suc; _+_)
open import Data.Nat.Properties using (+-comm; +-suc; +-identityʳ)
open import Relation.Binary.PropositionalEquality
  using (_≡_; refl; sym; trans; cong)

-- ---------- 定理 1.15：加法 = 原始递归（递归在第二变元） ----------

infixl 6 _⊕_

_⊕_ : ℕ → ℕ → ℕ
m ⊕ zero  = m
m ⊕ suc n = suc (m ⊕ n)

-- 书页 51 基础段：0 ⊕ n = n（对 n 归纳）
⊕-zeroˡ : ∀ n → zero ⊕ n ≡ n
⊕-zeroˡ zero    = refl
⊕-zeroˡ (suc n) = cong suc (⊕-zeroˡ n)

-- 左后继引理：⊕ 的定义只递归第二变元，第一变元的后继须归纳处理
⊕-sucˡ : ∀ m k → suc m ⊕ k ≡ suc (m ⊕ k)
⊕-sucˡ m zero    = refl
⊕-sucˡ m (suc k) = cong suc (⊕-sucˡ m k)

-- ---------- 定理 1.16(1)：交换律的双归纳 ----------

⊕-comm : ∀ m n → m ⊕ n ≡ n ⊕ m
⊕-comm m zero    = sym (⊕-zeroˡ m)
⊕-comm m (suc k) = sym (hl m)
  where
  -- 内层对第二变元 p 归纳（书页 51 的嵌套归纳）
  hl : ∀ p → suc k ⊕ p ≡ p ⊕ suc k
  hl zero    = cong suc (sym (⊕-zeroˡ k))
  -- 两步：内层 IH 换面；⊕-sucˡ 把右端第一变元的后继翻进去
  hl (suc j) =
    trans (cong suc (hl j)) (sym (cong suc (⊕-sucˡ j k)))

-- ---------- 对照：书版递归与 stdlib 的 _+_ 一致 ----------

⊕≡+ : ∀ m n → m ⊕ n ≡ m + n
⊕≡+ m zero    = sym (+-identityʳ m)
⊕≡+ m (suc n) = trans (cong suc (⊕≡+ m n)) (sym (+-suc m n))

-- stdlib 官方交换律（对照锚点）
official : ∀ m n → m + n ≡ n + m
official = +-comm
