module Tmp11c where

open import Relation.Binary.PropositionalEquality using (_≡_; refl; sym; cong)
open import Data.Nat using (ℕ; suc; zero; _+_)

n+0 : ∀ n → n + 0 ≡ n
n+0 zero    = refl
n+0 (suc n) = cong suc (n+0 n)

-- 子句级 rewrite + sym
rw-a : ∀ {x y : ℕ} → x ≡ y → suc y ≡ suc x
rw-a {x} eq rewrite sym eq = refl

-- 多条 rewrite 用 |
rw-b : ∀ n → suc (suc (n + 0)) ≡ suc (suc n)
rw-b n rewrite n+0 (suc n) | n+0 n = refl

-- with 后 rewrite？
rw-c : ∀ n → suc (n + 0) ≡ suc n
rw-c n rewrite n+0 n with n
rw-c .zero | zero = refl
rw-c .(suc m) | suc m rewrite n+0 m = refl
