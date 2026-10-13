-- 第 18 章 V^B：三值布尔代数上的力迫关系

module Ch18_vb where

open import Data.Bool using (Bool; true; false; not; _∧_; _∨_)
open import Relation.Binary.PropositionalEquality using (_≡_; refl)
open import Data.Product using (_×_; _,_)

-- 三值代数用嵌套 Bool 编码：false=0、(true,false)=½、(true,true)=1
data B3 : Set where
  b0 : B3
  b½ : B3
  b1 : B3

bsup : B3 → B3 → B3
bsup b0 u = u
bsup u b0 = u
bsup b½ b½ = b½
bsup b½ b1 = b1
bsup b1 _  = b1

bneg : B3 → B3
bneg b0 = b1
bneg b½ = b½
bneg b1 = b0

bimp : B3 → B3 → B3
bimp u v = bsup (bneg u) v

-- 力迫关系：p ⊩ φ ⟺ e(p) ≤ ‖φ‖
_≤₃_ : B3 → B3 → Bool
b0 ≤₃ _ = true
b½ ≤₃ b0 = false
b½ ≤₃ _ = true
b1 ≤₃ b1 = true
b1 ≤₃ _ = false

Forces : B3 → B3 → Set
Forces p v = (p ≤₃ v) ≡ true

-- 具体例
test-force : Forces b½ b1
test-force = refl

-- 1 ≰ ½（不可力迫的例）
open import Data.Empty using (⊥)
test-not : Forces b1 b½ → ⊥
test-not ()
