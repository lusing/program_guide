----------------------------------------------------------------
-- 01 认识类型论与四大证明助手 —— Agda 侧示例
-- 内核：MLTT（直觉主义类型论 + 宇宙层级），无独立 Prop
----------------------------------------------------------------

open import Data.Nat using (ℕ; zero; suc; _+_)
open import Relation.Binary.PropositionalEquality using (_≡_; refl; cong)

-- ---- 判断形式 t : T 直接写在源码里，编译器即判断器 ----
private
  idℕ : ℕ → ℕ
  idℕ n = n

  _ : ℕ
  _ = idℕ 41

-- ---- 命题即类型：n + 0 ≡ n 本身就是一个类型 ----
-- 证明即程序：模式匹配直接构造居留项，没有 tactic 这一层
plus-zero : (n : ℕ) → n + zero ≡ n
plus-zero zero    = refl                    -- zero + zero 定义性折叠为 zero
plus-zero (suc n) = cong suc (plus-zero n)  -- suc n + zero ≡ suc (n + zero)

-- 合同性 cong 与 Coq 的 f_equal、Lean 的 congrArg 同源：
--   cong : (f : A → B) → x ≡ y → f x ≡ f y

-- ---- 宇宙分层：Set : Set₁，避免「类型的类型」导致 Girard 悖论 ----
private
  _ : Set₁
  _ = Set

  _ : Set
  _ = ℕ → ℕ                -- 小类型的函数类型仍是小类型

-- ---- 蕴涵即函数类型：组合子 B 直接就是一个类型居留项 ----
imp-trans : {P Q R : Set} → (P → Q) → (Q → R) → (P → R)
imp-trans p→q q→r p = q→r (p→q p)

-- ---- 标准库的定理也只是普通函数（区别于 Coq 的 lemma/tactic 风格） ----
module Check where
  open import Data.List using (List; _∷_; [])
  open import Data.Nat.Properties using (+-comm)

  _ : ∀ n m → n + m ≡ m + n
  _ = +-comm
