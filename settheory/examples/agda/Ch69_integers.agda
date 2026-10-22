-- 第 69 章：有限与无限、整数与有理数（冯琦 §1.3.5 + §1.4）
-- 典型代表元的整数构造：符号位构造子 + 加法逆元对合（命题 1.15）；
-- 奇偶析因配对 J 的具体计算（命题 1.10(2)）。
module Ch69_integers where

open import Data.Nat using (ℕ; zero; suc; _+_; _*_; _^_; _∸_)
open import Relation.Binary.PropositionalEquality
  using (_≡_; refl)

-- ---------- 定义 1.36：整数 = 自然数 ∪ 负数对 ----------

data ℤᵇ : Set where
  zpos : ℕ → ℤᵇ
  zneg : ℕ → ℤᵇ        -- zneg m 表示 −(m+1)（绝对值 m+1 ≥ 1）

-- 加法逆元（定义 1.44 的整数版）：翻转符号位
znegate : ℤᵇ → ℤᵇ
znegate (zpos zero)    = zpos zero
znegate (zpos (suc m)) = zneg m
znegate (zneg m)       = zpos (suc m)

-- 命题 1.15：−(−x) = x（对合性，三分支全部结构可判）
znegate-involutive : ∀ x → znegate (znegate x) ≡ x
znegate-involutive (zpos zero)    = refl
znegate-involutive (zpos (suc m)) = refl
znegate-involutive (zneg m)       = refl

-- 绝对值（定义 1.36(2)）
zabs : ℤᵇ → ℕ
zabs (zpos n) = n
zabs (zneg m) = suc m

abs3 : zabs (zneg 2) ≡ 3
abs3 = refl

-- ---------- 命题 1.10(2)：奇偶析因配对 J(m,n) = 2^m(2n+1) − 1 ----------

jpair : ℕ → ℕ → ℕ
jpair m n = (2 ^ m) * (2 * n + 1) ∸ 1

-- 前几项的计算见证（2^ 依指数结构递归，全部定义可计算）
j00 : jpair 0 0 ≡ 0
j00 = refl

j10 : jpair 1 0 ≡ 1
j10 = refl

j01 : jpair 0 1 ≡ 2
j01 = refl

j20 : jpair 2 0 ≡ 3
j20 = refl

j11 : jpair 1 1 ≡ 5
j11 = refl

j52 : jpair 5 2 ≡ 159
j52 = refl
