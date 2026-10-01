----------------------------------------------------------------
-- 10 MLTT 的判断形式与一般规则 —— Agda 侧
-- 四种判断 + 前提/对称/传递/替换；等式动作全靠模式匹配 refl
----------------------------------------------------------------

open import Data.Nat using (ℕ; zero; suc; _+_)
open import Relation.Binary.PropositionalEquality
  using (_≡_; refl; sym; trans; cong; subst)

-- ---- 判断 a : A：源码里的每行类型标注都是 ----
one : ℕ
one = suc zero

-- ---- 判断 A type ----
NatFun : Set
NatFun = ℕ → ℕ

-- ---- a ≡ b : A：定义相等，refl 居住 ----
defeq1 : (λ n → n + 1) 1 ≡ 2
defeq1 = refl

-- 0 + n 折叠（+ 递归在第一参数），n + 0 不折叠
defeq-dir : ∀ n → 0 + n ≡ n
defeq-dir n = refl

-- ---- A ≡ B ----
tyeq : _≡_ {A = Set} NatFun (ℕ → ℕ)
tyeq = refl

-- ---- 一般规则 ----

-- 前提
hyp-rule : (P : ℕ → Set) (n : ℕ) → P n → P n
hyp-rule P n h = h

-- 对称：模式匹配 refl 即得（J 的免费赠品）
sym-rule : ∀ (a b : ℕ) → a ≡ b → b ≡ a
sym-rule a .a refl = refl

-- 传递
trans-rule : ∀ (a b c : ℕ) → a ≡ b → b ≡ c → a ≡ c
trans-rule a .a c refl h2 = h2

-- 替换：J 的直接化身
subst-rule : ∀ {A : Set} (P : A → Set) {a b} → a ≡ b → P a → P b
subst-rule P refl pa = pa

-- 同余
cong-rule : ∀ (f : ℕ → ℕ) {a b} → a ≡ b → f a ≡ f b
cong-rule f refl = refl

-- ---- 定义相等 ≠ 命题相等 ----
not-defeq : ∀ n → n + 0 ≡ n      -- refl 过不了！
not-defeq zero    = refl
not-defeq (suc n) = cong suc (not-defeq n)

