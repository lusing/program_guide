-- 第 93 章：高阶无穷导引——有限相对强度 DAG。
-- woodinWitness 是「超紧与武丁见证的联合假设」节点，不是裸武丁基数。
module Ch93_higherinfinity where

open import Data.Empty using (⊥)
open import Data.Nat using (ℕ; _≤_; _<_; z≤n; s≤s)
open import Data.Nat.Properties using (≤-refl; ≤-trans; <⇒≤; <-irrefl)
open import Relation.Binary.PropositionalEquality using (refl)

data Node : Set where
  zfc measurable supercompact woodinWitness : Node

rank : Node → ℕ
rank zfc = 0
rank measurable = 1
rank supercompact = 2
rank woodinWitness = 3

data Step : Node → Node → Set where
  zm : Step zfc measurable
  ms : Step measurable supercompact
  sw : Step supercompact woodinWitness

data Reach : Node → Node → Set where
  refl : ∀ {x} → Reach x x
  tail : ∀ {x y z} → Reach x y → Step y z → Reach x z

reach-trans : ∀ {x y z} → Reach x y → Reach y z → Reach x z
reach-trans hxy refl = hxy
reach-trans hxy (tail hyz s) = tail (reach-trans hxy hyz) s

step-rank : ∀ {x y} → Step x y → rank x < rank y
step-rank zm = s≤s z≤n
step-rank ms = s≤s (s≤s z≤n)
step-rank sw = s≤s (s≤s (s≤s z≤n))

reach-rank : ∀ {x y} → Reach x y → rank x ≤ rank y
reach-rank refl = ≤-refl
reach-rank (tail r s) = ≤-trans (reach-rank r) (<⇒≤ (step-rank s))

no-back : ∀ {x y} → Step x y → Reach y x → ⊥
no-back s r = <-irrefl refl (≤-trans (step-rank s) (reach-rank r))

guide-path : Reach zfc woodinWitness
guide-path = tail (tail (tail refl zm) ms) sw

no-return : Reach woodinWitness supercompact → ⊥
no-return = no-back sw
