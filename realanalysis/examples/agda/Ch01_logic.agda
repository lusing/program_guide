-- 第 01 章 数学语言与证明技巧：Agda 通道。
-- 展示构造性逻辑（逆否、德摩根的构造性片段）、可判定世界中的
-- 完整德摩根（Bool）、量词顺序，以及归纳法证明求和公式。

module Ch01_logic where

open import Relation.Binary.PropositionalEquality
  using (_≡_; refl; cong; sym; module ≡-Reasoning)
open import Data.Nat using (ℕ; zero; suc; _+_; _*_; _>_; _<_)
open import Data.Nat.Properties
  using (n<1+n; *-comm; *-distribˡ-+; +-suc; +-identityʳ)
open import Data.Bool using (Bool; true; false; not; _∨_; _∧_)
open import Data.Sum using (_⊎_; inj₁; inj₂)
open import Data.Product using (_×_; _,_; Σ)
open import Relation.Nullary using (¬_)
open import Function using (_∘_)
open ≡-Reasoning

-- 逆否命题：(A → B) → (¬ B → ¬ A) 构造性成立。
contraposition : ∀ {A B : Set} → (A → B) → ¬ B → ¬ A
contraposition f ¬b a = ¬b (f a)

-- 命题层面的德摩根律之一：¬(A ⊎ B) ↔ (¬ A × ¬ B)，两个方向都构造性成立。
¬⊎→× : ∀ {A B : Set} → ¬ (A ⊎ B) → (¬ A × ¬ B)
¬⊎→× f = (f ∘ inj₁) , (f ∘ inj₂)

×→¬⊎ : ∀ {A B : Set} → (¬ A × ¬ B) → ¬ (A ⊎ B)
×→¬⊎ (¬a , _)  (inj₁ a) = ¬a a
×→¬⊎ (_ , ¬b)  (inj₂ b) = ¬b b

-- 可判定世界（Bool）里的完整德摩根律：四条全部成立，
-- 因为真值可以逐一枚举（模式匹配即是真值表）。
deMorgan-or : ∀ a b → not (a ∨ b) ≡ not a ∧ not b
deMorgan-or false _ = refl
deMorgan-or true  _ = refl

deMorgan-and : ∀ a b → not (a ∧ b) ≡ not a ∨ not b
deMorgan-and false _ = refl
deMorgan-and true  _ = refl

-- 量词顺序（自然数域，构造版）：对每个 n 都存在更大的 m = suc n。
-- 这对应原书 ∀x ∃y, y > x 的真命题，证据是一个可运行的函数。
forall-exists-order : ∀ (n : ℕ) → Σ ℕ (λ m → m > n)
forall-exists-order n = suc n , n<1+n n

-- 归纳证明：sum n = 1 + 2 + ... + n。
sum : ℕ → ℕ
sum zero    = zero
sum (suc n) = sum n + suc n

-- 辅助引理：n + 2 ≡ suc (suc n)。
-- Agda 的加法在第一个参数上递归，n + 2 不会定义级化简，
-- 需要 +-suc 与 +-identityʳ 逐层搬运。
plus2 : ∀ n → n + 2 ≡ suc (suc n)
plus2 n = begin
  n + 2             ≡⟨ +-suc n 1 ⟩
  suc (n + 1)       ≡⟨ cong suc (+-suc n 0) ⟩
  suc (suc (n + 0)) ≡⟨ cong (λ t → suc (suc t)) (+-identityʳ n) ⟩
  suc (suc n)       ∎

-- 先证无除法版本 2 * sum n ≡ n * (1 + n)。
-- 归纳步骤是一条显式的等式推理链：分配律展开、代入归纳假设、
-- 交换律对齐因子、分配律回收，最后 plus2 收尾。
sum-double : ∀ n → 2 * sum n ≡ n * suc n
sum-double zero    = refl
sum-double (suc n) = begin
  2 * (sum n + suc n)   ≡⟨ *-distribˡ-+ 2 (sum n) (suc n) ⟩
  2 * sum n + 2 * suc n ≡⟨ cong (_+ (2 * suc n)) (sum-double n) ⟩
  n * suc n + 2 * suc n ≡⟨ cong (n * suc n +_) (*-comm 2 (suc n)) ⟩
  n * suc n + suc n * 2 ≡⟨ cong (_+ (suc n * 2)) (*-comm n (suc n)) ⟩
  suc n * n + suc n * 2 ≡⟨ sym (*-distribˡ-+ (suc n) n 2) ⟩
  suc n * (n + 2)       ≡⟨ cong (suc n *_) (plus2 n) ⟩
  suc n * suc (suc n)   ∎

-- 归纳法的骨架本身：把“对所有 n 成立”拆成零情形与后继情形，
-- 这正是原书所说的多米诺骨牌。
module InductionSkeleton (P : ℕ → Set)
  (base : P zero)
  (step : ∀ n → P n → P (suc n)) where

  proof-by-induction : ∀ n → P n
  proof-by-induction zero    = base
  proof-by-induction (suc n) = step n (proof-by-induction n)
