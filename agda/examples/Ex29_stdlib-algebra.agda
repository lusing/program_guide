module Ex29_stdlib-algebra where

-- 第 29 章配套示例：Algebra.Structures / Algebra.Bundles / Algebra.Definitions / Solver。
-- 所有 import 路径钉在 agda-stdlib 3.0 源码上，类型检查退出码 0。

open import Data.Nat using (ℕ; _+_; _*_; zero; suc)
open import Data.Nat.Properties
  using (+-0-isMonoid; +-0-isCommutativeMonoid; +-0-commutativeMonoid; +-semigroup)
open import Data.Nat.Tactic.RingSolver using (solve-∀)
open import Relation.Binary.PropositionalEquality
  using (_≡_; refl; sym; trans; cong; cong₂)

open import Algebra.Structures (_≡_ {A = ℕ}) public
  using (IsMonoid; IsCommutativeMonoid; IsSemigroup)
-- 3.0 的 Algebra.Bundles 没有模块参数（Carrier/_≈_ 是 record 字段）：
open import Algebra.Bundles public
  using (Monoid; CommutativeMonoid)

-- 件 1：Structures 层——现场展开 IsMonoid 记录拿派生字段。
-- 实测 `IsMonoid (∙ : Op₂ ℕ) (ε : ℕ)`，字段 {isSemigroup, identity}；assoc 从内嵌
-- IsSemigroup 透传。
m : IsMonoid _+_ 0
m = +-0-isMonoid

open IsMonoid m public
  using () renaming (identity to hasIdentity)
open IsSemigroup (IsMonoid.isSemigroup m) public
  using () renaming (assoc to hasAssoc)

assoc₃ : (a b c : ℕ) → (a + b) + c ≡ a + (b + c)
assoc₃ a b c = hasAssoc a b c

-- 件 2：Bundles 层——整包开箱，assoc / comm / identity 一个不少。
M : CommutativeMonoid _ _
M = +-0-commutativeMonoid

open CommutativeMonoid M public
  using (assoc; comm; identity; ε; _≈_)

bundle-comm : (a b : ℕ) → a + b ≡ b + a
bundle-comm = comm

-- 件 3：RingSolver 宏——让编译器把 semiring 词算平（solve-∀ 自动读目标）。
ring-demo : (a b : ℕ) → (a + b) * (a + b) ≡ a * a + (a * b) + (a * b) + b * b
ring-demo = solve-∀