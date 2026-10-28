-- 第 83 章：主超滤超幂退化与对偶数截断超有理数（构造性）。
module Ch83_twolines where

open import Data.Bool using (Bool; true; false; if_then_else_)
open import Data.Integer using (ℤ; +_; _+_; _*_)
open import Data.Nat using (ℕ; zero; suc)
open import Data.Product using (Σ; _×_; _,_; ∃)
open import Relation.Binary.PropositionalEquality using (_≡_; refl; cong)

-- ─────────────────────────────────────────────────────────────
-- 一、主超滤超幂退化（焦点 a 的求值）：f ≡ g ⟺ f(a) = g(a)。
-- ─────────────────────────────────────────────────────────────

-- 整数相等判定（自建，避免 stdlib 版本命名差异）。
eqℤ : ℤ → ℤ → Bool
eqℤ i j = (Data.Integer.∣ i Data.Integer.- j ∣) Data.Nat.≡ᵇ 0

eval-at : {A : Set} → A → (A → ℤ) → (A → ℤ) → Bool
eval-at a f g = eqℤ (f a) (g a)

-- 退化：每个等价类有常值代表。
const-rep : {A : Set} → (a : A) (f : A → ℤ) →
  Σ (A → ℤ) (λ c → ((x : A) → c x ≡ f a))
const-rep a f = (λ x → f a) , (λ x → refl)

-- ─────────────────────────────────────────────────────────────
-- 二、对偶数 a + b·ε（ε² = 0）：非 Archimedean 截断超有理数。
-- ─────────────────────────────────────────────────────────────

record Dual : Set where
  field
    dRe : ℤ
    dEp : ℤ

mkD : ℤ → ℤ → Dual
mkD a b = record { dRe = a ; dEp = b }

d+ : Dual → Dual → Dual
d+ x y = mkD (Dual.dRe x + Dual.dRe y) (Dual.dEp x + Dual.dEp y)

d* : Dual → Dual → Dual
d* x y = mkD (Dual.dRe x * Dual.dRe y) (Dual.dRe x * Dual.dEp y + Dual.dEp x * Dual.dRe y)

ε : Dual
ε = mkD (+ 0) (+ 1)

one : Dual
one = mkD (+ 1) (+ 0)

-- (1+ε)² = 1 + 2ε：ε² = 0 的截断律。
one-plus-ε² : d* (d+ one ε) (d+ one ε) ≡ mkD (+ 1) (+ 2)
one-plus-ε² = refl

-- 标准部分乘法超越律的截断见证。
transfer-7 : d* (mkD (+ 7) (+ 0)) (mkD (+ 1) (+ 0)) ≡ mkD (+ 7) (+ 0)
transfer-7 = refl
