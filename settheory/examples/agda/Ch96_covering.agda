-- 第 96 章：结构归纳覆盖构造（构造性）。
module Ch96_covering where

open import Data.Bool using (Bool; true; false; _∨_; _∧_)
open import Data.List using (List; []; _∷_; _++_)
open import Data.Nat using (ℕ; zero; suc; _≡ᵇ_)
open import Data.Product using (Σ; _×_; _,_)
open import Relation.Binary.PropositionalEquality
  using (_≡_; refl; cong)

-- 族：由空集、单点与二元并生成的归纳谓词。
data InFam : List ℕ → Set where
  fam-nil  : InFam []
  fam-sing : (x : ℕ) → InFam (x ∷ [])
  fam-app  : (X Y : List ℕ) → InFam X → InFam Y → InFam (X ++ Y)

inb : ℕ → List ℕ → Bool
inb x [] = false
inb x (y ∷ ys) = (x ≡ᵇ y) ∨ inb x ys

-- mem X Y = true 意为 X ⊆ Y（构造性布尔）。
mem : List ℕ → List ℕ → Bool
mem [] Y = true
mem (x ∷ X) Y = inb x Y ∧ mem X Y

eqb-refl : ∀ x → (x ≡ᵇ x) ≡ true
eqb-refl zero = refl
eqb-refl (suc x) = eqb-refl x

both : ∀ a b → a ≡ true → b ≡ true → (a ∧ b) ≡ true
both true  b ha hb = hb
both false b ha hb = ha

split : ∀ a b → (a ∧ b) ≡ true → (a ≡ true) × (b ≡ true)
split true  b h = refl , h
split false b ()

inb-head : ∀ x Y → inb x (x ∷ Y) ≡ true
inb-head x Y rewrite eqb-refl x = refl

inb-tail : ∀ x y Y → inb x Y ≡ true → inb x (y ∷ Y) ≡ true
inb-tail x y Y h with x ≡ᵇ y
... | true  = refl
... | false = h

mem-mono : ∀ x X Y → mem X Y ≡ true → mem X (x ∷ Y) ≡ true
mem-mono x [] Y h = refl
mem-mono x (x₀ ∷ X) Y h with split (inb x₀ Y) (mem X Y) h
... | p₁ , p₂ = both (inb x₀ (x ∷ Y)) (mem X (x ∷ Y))
                   (inb-tail x₀ x Y p₁) (mem-mono x X Y p₂)

-- 结构归纳覆盖构造：每个有限列表都被族中某成员包住。
cover : (X : List ℕ) → Σ (List ℕ) (λ Y → InFam Y × (mem X Y ≡ true))
cover [] = [] , fam-nil , refl
cover (x ∷ X) with cover X
... | Y , fy , my =
  (x ∷ Y) ,
  fam-app (x ∷ []) Y (fam-sing x) fy ,
  both (inb x (x ∷ Y)) (mem X (x ∷ Y))
       (inb-head x Y) (mem-mono x X Y my)

-- 样本：{2,3} 被族中成员 [1,2,3] 包住。
sample-covered : mem (2 ∷ 3 ∷ []) (1 ∷ 2 ∷ 3 ∷ []) ≡ true
sample-covered = refl

sample-miss : mem (3 ∷ 4 ∷ []) (2 ∷ 4 ∷ []) ≡ false
sample-miss = refl
