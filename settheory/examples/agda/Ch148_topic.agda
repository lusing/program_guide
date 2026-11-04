module Ch148_topic where

open import Data.Nat using (ℕ)
open import Relation.Binary.PropositionalEquality using (_≡_; refl)

-- 第 148 章：有限六阶段对照；不声称机器证明任何大基数定理。

data Stage : Set where
  stage0 stage1 stage2 stage3 stage4 stage5 : Stage

code : Stage → ℕ
code stage0 = 0
code stage1 = 1
code stage2 = 2
code stage3 = 3
code stage4 = 4
code stage5 = 5

strength-code : Stage → ℕ
strength-code = code

forcing-code : Stage → ℕ
forcing-code = code

regularity-code : Stage → ℕ
regularity-code = code

strength-coherent : (s : Stage) → strength-code s ≡ code s
strength-coherent s = refl

forcing-coherent : (s : Stage) → forcing-code s ≡ code s
forcing-coherent s = refl

regularity-coherent : (s : Stage) → regularity-code s ≡ code s
regularity-coherent s = refl

first-row : code stage0 ≡ 0
first-row = refl

last-row : code stage5 ≡ 5
last-row = refl
