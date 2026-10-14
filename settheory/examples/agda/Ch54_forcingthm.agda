-- 第 54 章：布尔真值控制的分离（sep 名的构造）

module Ch54_forcingthm where

open import Data.Bool using (Bool; true; false; _∧_; _∨_; not)
open import Data.List using (List; []; _∷_; _++_)
open import Data.Nat using (ℕ; zero; suc)
open import Data.Product using (_×_; _,_)
open import Relation.Binary.PropositionalEquality using (_≡_; refl; cong)

-- 名字（53 章同款）
data Name : Set where
  nempty : Name
  ncons : Name → Bool → Name → Name

-- G-读出（↑true 主超滤）
readout : Name → List Bool
readout nempty = []
readout (ncons σ b r) with b
... | true = b ∷ (readout σ ++ readout r)
... | false = readout σ ++ readout r

-- 分离名：{(ξ, ⟦φ(ξ)⟧) : ξ ∈ dom τ}——把真值当标号
sepname : Name → (Bool → Bool) → Name
sepname nempty φ = nempty
sepname (ncons σ b r) φ = ncons (sepname σ φ) (φ b) (sepname r φ)

-- 分离证书（恒等 φ = id 的情形：sep = τ）
cong₃ : {A B C D : Set} → (f : A → B → C → D) →
        {x₁ x₂ : A} {y₁ y₂ : B} {z₁ z₂ : C} →
        x₁ ≡ x₂ → y₁ ≡ y₂ → z₁ ≡ z₂ → f x₁ y₁ z₁ ≡ f x₂ y₂ z₂
cong₃ f refl refl refl = refl

sep-id-correct : (t : Name) → sepname t (λ x → x) ≡ t
sep-id-correct nempty = refl
sep-id-correct (ncons σ b r) = cong₃ ncons (sep-id-correct σ) refl (sep-id-correct r)
