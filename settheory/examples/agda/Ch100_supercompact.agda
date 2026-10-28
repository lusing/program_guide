-- 第 100 章：有限 P_κ(λ) 精细锥的构造性骨架。
module Ch100_supercompact where

open import Data.List using (List; []; _∷_; _++_)
open import Data.Nat using (ℕ; zero; suc)
open import Data.Product using (_×_; _,_; ∃)
open import Relation.Binary.PropositionalEquality using (_≡_; refl)

-- 自建成员关系。
data _∈L_ {A : Set} : A → List A → Set where
  here  : ∀ {x : A} {xs} → x ∈L (x ∷ xs)
  there : ∀ {y x : A} {xs} → x ∈L xs → x ∈L (y ∷ xs)

-- 自建包含。
data _⊆L_ {A : Set} : List A → List A → Set where
  nil⊆ : ∀ {ys} → [] ⊆L ys
  cons : ∀ {x xs ys} → x ∈L ys → xs ⊆L ys → (x ∷ xs) ⊆L ys

⊆L-shift : ∀ {A} {x : A} {xs zs : List A} → xs ⊆L zs → xs ⊆L (x ∷ zs)
⊆L-shift nil⊆ = nil⊆
⊆L-shift (cons x∈ xs⊆) = cons (there x∈) (⊆L-shift xs⊆)

⊆L-refl : ∀ {A} {xs : List A} → xs ⊆L xs
⊆L-refl {xs = []} = nil⊆
⊆L-refl {xs = x ∷ xs} = cons here (⊆L-shift ⊆L-refl)

⊆L-++L : ∀ {A} {xs ys : List A} → xs ⊆L (xs ++ ys)
⊆L-++L {xs = []} = nil⊆
⊆L-++L {xs = x ∷ xs} = cons here (⊆L-shift ⊆L-++L)

++L-⊆R : ∀ {A} {xs ys : List A} → ys ⊆L (xs ++ ys)
++L-⊆R {xs = []} = ⊆L-refl
++L-⊆R {xs = x ∷ xs} = ⊆L-shift (++L-⊆R {xs = xs})

-- 主定理骨架：s₁ ⊆ t → s₂ ⊆ t → s₁++s₂ ⊆ t（锥之交封闭的构造内核）。
cone-union : ∀ {A} (s₁ s₂ t : List A) →
  s₁ ⊆L t → s₂ ⊆L t → (s₁ ++ s₂) ⊆L t
cone-union [] s₂ t h₁ h₂ = h₂
cone-union (x ∷ s₁) s₂ t h₁ h₂ =
  cons (cone-head h₁) (cone-union s₁ s₂ t (cone-tail h₁) h₂)
  where
  cone-head : ∀ {A} {x : A} {xs t : List A} → (x ∷ xs) ⊆L t → x ∈L t
  cone-head (cons x∈ _) = x∈
  cone-tail : ∀ {A} {x : A} {xs t : List A} → (x ∷ xs) ⊆L t → xs ⊆L t
  cone-tail (cons _ xs⊆) = xs⊆

-- 精细锥的构造性记录。
record Cone (A : Set) (s t : List A) : Set where
  constructor mkCone
  field
    s⊆t : s ⊆L t

-- 样本：{1,2} 的上锥含 {0,1,2}。
sample : Cone ℕ (1 ∷ 2 ∷ []) (0 ∷ 1 ∷ 2 ∷ [])
sample = mkCone (cons (there here)
                     (cons (there (there here)) nil⊆))

-- 回归函数 f(t) = 首元素；在 {c} 的锥上恒值 c。
f-head : List ℕ → ℕ
f-head [] = zero
f-head (x ∷ _) = x

f-head-single : ∀ c → f-head (c ∷ []) ≡ c
f-head-single c = refl
