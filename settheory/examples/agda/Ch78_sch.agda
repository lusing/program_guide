-- 第 78 章：奇异基数假设——银杰与嘎尔文-海纳（冯琦 §2.4）——Agda 通道
-- 先用 Acc 递归证明自然数上没有无穷递减链（Lean no_omega_descending 的构造性
-- 对应物，也是定义 2.29 有秩性的引擎），再给范数的玩具模型：底空间退化到一点
-- 时 ‖f‖=sup{‖g‖+1 | g<f} 变成自然数上的恒等递推 ghNorm，范数即恒等。
module Ch78_sch where

open import Data.Empty using (⊥)
open import Data.Nat using (ℕ; zero; suc; _<_)
open import Data.Nat.Induction using (<-wellFounded)
open import Induction.WellFounded using (Acc; acc)
open import Relation.Binary.PropositionalEquality using (_≡_; refl; cong)

-- 良基关系上没有无穷下降：给定 f 使 f(n+1)<f(n)，从 f(0) 的可及性出发，
-- 每步用 rs 把可及性从 f(n) 传给更小的 f(n+1)，递归永不落地，故 ⊥。
no-desc : (f : ℕ → ℕ) → (∀ n → f (suc n) < f n) → ⊥
no-desc f step = go (f 0) (<-wellFounded (f 0)) 0 refl
  where
  go : (x : ℕ) → Acc _<_ x → ∀ n → x ≡ f n → ⊥
  go x (acc rs) zero refl = go (f 1) (rs (step 0)) 1 refl
  go x (acc rs) (suc n) refl =
    go (f (suc (suc n))) (rs (step (suc n))) (suc (suc n)) refl

-- 范数玩具模型：单点底空间上 ghNorm 就是恒等递推。
ghNorm : ℕ → ℕ
ghNorm zero = zero
ghNorm (suc n) = suc (ghNorm n)

-- 机器验证 78.4 的直觉「常值函数 n 的范数是 n」（玩具滤子下）。
norm-const : ∀ n → ghNorm n ≡ n
norm-const zero = refl
norm-const (suc n) = cong suc (norm-const n)
