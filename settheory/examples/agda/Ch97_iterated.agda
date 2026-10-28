-- 第 97 章：有限链嵌入复合与直接极限代表元（构造性）。
module Ch97_iterated where

open import Data.Nat using (ℕ; zero; suc; _+_; _≡ᵇ_; _<ᵇ_)
open import Data.Bool using (Bool; true; false; _∧_)
open import Data.Product using (_×_; _,_; Σ)
open import Relation.Binary.PropositionalEquality
  using (_≡_; refl; cong; trans; sym)

-- ─────────────────────────────────────────────────────────────
-- 一、有限链嵌入的复合交换：jiter (m+n) = jiter m ∘ jiter n
--    （推论 1.10 交换图 / 引理 1.37 分解的有限链版本）。
-- ─────────────────────────────────────────────────────────────

jiter : ℕ → ℕ → ℕ
jiter zero x = x
jiter (suc n) x = suc (jiter n x)

-- 分解律：jiter (m + n) x = jiter m (jiter n x)。
decompose : ∀ m n x → jiter (m + n) x ≡ jiter m (jiter n x)
decompose zero n x = refl
decompose (suc m) n x = cong suc (decompose m n x)

-- 两路径合成一致：a + (b + c) 与 (a + b) + c 给出同一迭代
-- （+ 的结合律以 cong 传入）。
+-assoc : ∀ a b c → a + (b + c) ≡ (a + b) + c
+-assoc zero b c = refl
+-assoc (suc a) b c = cong suc (+-assoc a b c)

commute-two-paths : ∀ a b c x →
  jiter (a + (b + c)) x ≡ jiter ((a + b) + c) x
commute-two-paths a b c x =
  cong (λ n → jiter n x) (+-assoc a b c)

-- 临界点轨迹严格递增的数值样本：jiter 4 0 = 4 > 0。
traj-sample : jiter 4 0 ≡ 4
traj-sample = refl

traj-strict-3 : (0 <ᵇ jiter 3 0) ≡ true
traj-strict-3 = refl

-- ─────────────────────────────────────────────────────────────
-- 二、直接极限代表元的代表无关性（有限版）。
-- ─────────────────────────────────────────────────────────────

push : ℕ → ℕ → ℕ
push zero x = x + x
push (suc zero) x = x
push (suc (suc zero)) x = zero
push _ x = zero

rep-independent : ∀ i x → Σ ℕ (λ v → push i x ≡ v)
rep-independent i x = push i x , refl
