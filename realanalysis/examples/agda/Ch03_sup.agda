-- 第 03 章 上确界：Agda 通道。
-- 无限集的上确界本质上不可构造（依赖完备性公理），
-- 但有限集的上确界——最大值——可以纯构造地证明两条基本性质：
--   1. maxl 是列表的上界（每个成员都不超过它）；
--   2. maxl 本身是成员（只要列表非空/最大值非零）。
-- 这正是“最大元 = 属于集合的上确界”的构造主义版本。

module Ch03_sup where

open import Data.List using (List; []; _∷_; foldr)
open import Data.List.Membership.Propositional using (_∈_)
open import Data.List.Relation.Unary.Any using (here; there)
open import Data.Nat using (ℕ; _⊔_; _≤_; _<_; zero; suc; z≤n; s≤s)
open import Data.Nat.Properties
  using (m≤m⊔n; m≤n⊔m; ⊔-sel; ≤-trans; ≤-refl)
open import Data.Sum using (_⊎_; inj₁; inj₂)
open import Data.Product using (_×_; _,_)
open import Relation.Binary.PropositionalEquality
  using (_≡_; refl; sym; subst)

-- 有限集的最大值：foldr 取 max，空列表约定为 0。
maxl : List ℕ → ℕ
maxl = foldr _⊔_ 0

-- 性质 1（上界性）：列表的任何成员都不超过 maxl。
-- 归纳：成员在头部用 m≤m⊔n，在尾部用归纳假设加 m≤n⊔m 传递。
maxl-upper : ∀ {x xs} → x ∈ xs → x ≤ maxl xs
maxl-upper (here refl) = m≤m⊔n _ _
maxl-upper (there p)  = ≤-trans (maxl-upper p) (m≤n⊔m _ _)

-- 性质 2（成员性/最小性的推论）：maxl 本身属于列表。
-- 前提 0 < maxl xs 排除了空列表的情形（空列表的 maxl 是 0，
-- 0 不在空列表里——有限集取 max 的“空集陷阱”与原书对
-- 空集不能谈上确界的约定遥相呼应）。
maxl-mem : ∀ xs → 0 < maxl xs → maxl xs ∈ xs
maxl-mem (x ∷ xs) h with x ⊔ maxl xs | ⊔-sel x (maxl xs)
-- ⊔-sel 判定：x ⊔ maxl xs 要么等于 x（头即最大），要么等于 maxl xs。
-- with 把目标与 h 的类型同时按 scrutinee 抽象，refl 分支里 h 自动变形。
... | .x        | inj₁ refl = here refl
... | .(maxl xs) | inj₂ refl = there (maxl-mem xs h)

-- 推论：有限集的最大值就是它的上确界——上界且在集合中。
-- 这与原书定理 4.9（上确界属于集合即最大元）互为镜像。
maxl-is-sup : ∀ xs → 0 < maxl xs →
              (∀ {x} → x ∈ xs → x ≤ maxl xs) × (maxl xs ∈ xs)
maxl-is-sup xs h = (λ {x} → maxl-upper {x} {xs}) , maxl-mem xs h
