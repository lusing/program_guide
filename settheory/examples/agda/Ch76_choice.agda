-- 第 76 章：选择公理与无穷和积不等式（冯琦 §2.1–2.2）——Agda 通道
-- 构造性有限选择：良序列表中的首个成员；König 对角线的二坐标证明。
module Ch76_choice where

open import Data.Bool using (Bool; true; false; not; if_then_else_; _∨_)
open import Data.Empty using (⊥)
open import Data.List using (List; []; _∷_)
open import Data.Maybe using (Maybe; just; nothing)
open import Data.Nat using (ℕ; _≡ᵇ_)
open import Data.Product using (_×_; _,_)
open import Relation.Binary.PropositionalEquality using (_≡_; refl)

-- ---------- 定理 2.2：秩序 ⇒ 选择函数 ----------
member : ℕ → List ℕ → Bool
member x [] = false
member x (y ∷ ys) = (x ≡ᵇ y) ∨ member x ys

choose-by-order : List ℕ → List ℕ → Maybe ℕ
choose-by-order [] A = nothing
choose-by-order (x ∷ xs) A = if member x A then just x else choose-by-order xs A

-- 良序 [0,1,2,3,4] 在子集 {4,2,3} 中选择最小元 2，而非任意极小元。
choice-demo : choose-by-order (0 ∷ 1 ∷ 2 ∷ 3 ∷ 4 ∷ []) (4 ∷ 2 ∷ 3 ∷ []) ≡ just 2
choice-demo = refl

choice-empty : choose-by-order (0 ∷ 1 ∷ 2 ∷ []) (3 ∷ 4 ∷ []) ≡ nothing
choice-empty = refl

-- ---------- 定理 2.10：二坐标 König 对角线 ----------
diagonal2 : (Bool × Bool) → (Bool × Bool) → (Bool × Bool)
diagonal2 h0 h1 = not (proj₁ h0) , not (proj₂ h1)
  where
  open import Data.Product using (proj₁; proj₂)

-- f 的第 0 坐标与 h0 不同，故 f≠h0；逐个布尔值由计算排除等式。
diagonal2-left : ∀ a b c d → diagonal2 (a , b) (c , d) ≡ (a , b) → ⊥
diagonal2-left false b c d ()
diagonal2-left true b c d ()

-- f 的第 1 坐标与 h1 不同，故 f≠h1。
diagonal2-right : ∀ a b c d → diagonal2 (a , b) (c , d) ≡ (c , d) → ⊥
diagonal2-right a b c false ()
diagonal2-right a b c true ()

diagonal2-demo : diagonal2 (false , false) (true , true) ≡ (true , false)
diagonal2-demo = refl
