-- Chapter 10: complements, the minimum radius, and a relative endpoint.
module Ch10_openclosed where

open import Data.Bool using (Bool; true; false; not; _∨_; _∧_)
open import Data.Bool.Properties using (not-involutive)
open import Data.Nat using (ℕ; _⊓_; _≤_)
open import Data.Nat.Properties using (m⊓n≤m; m⊓n≤n)
open import Data.Product using (_×_; _,_)
open import Relation.Binary.PropositionalEquality using (_≡_; refl)

-- 并的补等于补的交。四行穷举就是德摩根律在布尔值上的全部情形。
demorgan-or : ∀ b c → not (b ∨ c) ≡ not b ∧ not c
demorgan-or false false = refl
demorgan-or false true  = refl
demorgan-or true  false = refl
demorgan-or true  true  = refl

-- 交的补等于补的并。闭集的有限并靠这一条从开集的有限交翻译过去。
demorgan-and : ∀ b c → not (b ∧ c) ≡ not b ∨ not c
demorgan-and false false = refl
demorgan-and false true  = refl
demorgan-and true  false = refl
demorgan-and true  true  = refl

-- 补两次回到原集合。
compl-involutive : ∀ b → not (not b) ≡ b
compl-involutive = not-involutive

-- 有限交取最小半径：这个半径不超过每一个半径，所以邻域落进每一个开集。
radius-both : ∀ (r₁ r₂ : ℕ) → r₁ ⊓ r₂ ≤ r₁ × r₁ ⊓ r₂ ≤ r₂
radius-both r₁ r₂ = m⊓n≤m r₁ r₂ , m⊓n≤n r₁ r₂

-- 三点直线 p0、p1、p2，当作 0、1、2。
-- Y 是 [0, 2)，不含 p2。E 是 [1, 2) 落在 Y 里的那一部分，只有 p1。
data Pt : Set where
  p0 p1 p2 : Pt

inY : Pt → Bool
inY p0 = true
inY p1 = true
inY p2 = false

inE : Pt → Bool
inE p0 = false
inE p1 = true
inE p2 = false

-- 2 不在子空间里，所以“相对于 Y 是否闭”不必检查 2。
missing-endpoint : inY p2 ≡ false
missing-endpoint = refl

endpoint-not-in-E : inE p2 ≡ false
endpoint-not-in-E = refl

-- 1 既在 Y 里也在 E 里。
interior-point : inY p1 ≡ true × inE p1 ≡ true
interior-point = refl , refl

-- 0 在 Y 里，但不在 E 里：它被隔在 E 的外面。
outside-point : inY p0 ≡ true × inE p0 ≡ false
outside-point = refl , refl
