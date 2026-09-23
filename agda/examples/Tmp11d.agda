module Tmp11d where

open import Data.Nat using (ℕ; zero; suc; _+_)
open import Relation.Binary.PropositionalEquality
  using (_≡_; refl; sym; trans; cong)

n+0 : ∀ n → n + 0 ≡ n
n+0 zero    = refl
n+0 (suc n) = cong suc (n+0 n)

-- 错误 1：refl 证不了 n+0≡n
bad-refl : ∀ n → n + 0 ≡ n
bad-refl n = refl

-- 错误 2：rewrite 一个已被模式拆掉的变量
bad-rw : (n : ℕ) (eq : n ≡ 0) → suc n ≡ suc 0
bad-rw zero eq rewrite eq = refl

-- 警告：rewrite 空转
rw-nothing : ∀ {x y : ℕ} → x ≡ y → x ≡ y
rw-nothing eq rewrite n+0 1 = eq
