-- 第 117 章：荟萃塔 II——三级有限塔的构造性投影与表示等式。
-- 只验证定向图表的有限坐标机制；Q<δ、武丁假设与实数点类本体在正文。
module Ch117_tower2 where

open import Data.Nat using (ℕ)
open import Data.Sum using (_⊎_; inj₁; inj₂)
open import Relation.Binary.PropositionalEquality using (_≡_; refl)

data Level : Set where
  L0 L1 L2 : Level

data Pt : Set where
  p0 p1 p2 : Pt

mark : Level → Pt
mark L0 = p0
mark L1 = p1
mark L2 = p2

proj : Level → Pt → Pt
proj L0 _ = p0
proj L1 p2 = p1
proj L1 x = x
proj L2 x = x

lift : Level → (Pt → ℕ) → Pt → ℕ
lift k f x = f (proj k x)

rep : Level → (Pt → ℕ) → ℕ
rep k f = f (mark k)

applyId : (Pt → ℕ) → Pt → ℕ
applyId f x = f x

applyId-eq : ∀ f x → applyId f x ≡ f x
applyId-eq f x = refl

rep-lift-01 : ∀ f → rep L1 (lift L0 f) ≡ rep L0 f
rep-lift-01 f = refl

rep-lift-02 : ∀ f → rep L2 (lift L0 f) ≡ rep L0 f
rep-lift-02 f = refl

rep-lift-12 : ∀ f → rep L2 (lift L1 f) ≡ rep L1 f
rep-lift-12 f = refl

lift-01-restrict : ∀ f x → (x ≡ p0 ⊎ x ≡ p1) → lift L1 f x ≡ f x
lift-01-restrict f .p0 (inj₁ refl) = refl
lift-01-restrict f .p1 (inj₂ refl) = refl

lift-comp-01 : ∀ f x → lift L1 (lift L0 f) x ≡ lift L0 f x
lift-comp-01 f p0 = refl
lift-comp-01 f p1 = refl
lift-comp-01 f p2 = refl

lift-comp-12 : ∀ f x → lift L2 (lift L1 f) x ≡ lift L1 f x
lift-comp-12 f p0 = refl
lift-comp-12 f p1 = refl
lift-comp-12 f p2 = refl

lift-comp-02 : ∀ f x → lift L2 (lift L0 f) x ≡ lift L0 f x
lift-comp-02 f p0 = refl
lift-comp-02 f p1 = refl
lift-comp-02 f p2 = refl
