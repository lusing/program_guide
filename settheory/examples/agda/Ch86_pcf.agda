-- 第 86 章 · 谢旯 pcf 理论（冯琦第二卷 §1.3）
-- 有限正则集合上的标尺、主超滤子与传递生成元样品。
module Ch86_pcf where

open import Data.Nat using (ℕ; zero; suc; _≤_; z≤n; s≤s)
open import Data.List using (List; []; _∷_)
open import Data.List.Membership.Propositional using (_∈_)
open import Data.List.Relation.Unary.Any using (here; there)
open import Data.Product using (_×_; _,_)
open import Relation.Binary.PropositionalEquality using (_≡_; refl)

A : List ℕ
A = 3 ∷ 5 ∷ 7 ∷ []

le-pw : (ℕ → ℕ) → (ℕ → ℕ) → Set
le-pw f g = ∀ {n} → n ∈ A → f n ≤ g n

scale0 scale1 scale2 : ℕ → ℕ
scale0 _ = 0
scale1 _ = 1
scale2 _ = 2

scale-increasing-01 : le-pw scale0 scale1 × (scale0 3 ≤ scale1 3)
scale-increasing-01 = (λ _ → z≤n) , z≤n

scale-increasing-12 : le-pw scale1 scale2 × (scale1 3 ≤ scale2 3)
scale-increasing-12 = (λ _ → s≤s z≤n) , s≤s z≤n

principal : ℕ → List ℕ → Set
principal a X = a ∈ X

principal-singleton : ∀ a → a ∈ A → principal a (a ∷ [])
principal-singleton _ _ = here refl

generator : ℕ → List ℕ
generator 3 = 3 ∷ []
generator 5 = 3 ∷ 5 ∷ []
generator 7 = 3 ∷ 5 ∷ 7 ∷ []
generator _ = []

generator-3 : generator 3 ≡ 3 ∷ []
generator-3 = refl

generator-5 : generator 5 ≡ 3 ∷ 5 ∷ []
generator-5 = refl

generator-7 : generator 7 ≡ 3 ∷ 5 ∷ 7 ∷ []
generator-7 = refl

gen-trans-5-3 : 3 ∈ generator 5
gen-trans-5-3 = here refl

gen-trans-chain : 3 ∈ generator 7
gen-trans-chain = here refl
