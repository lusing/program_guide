-- 第 98 章：布尔项 Def 算子——谓词外延性与参数局部性（构造性）。
module Ch98_lu where

open import Data.Bool using (Bool; true; false; _∧_; not)
open import Data.List using (List; []; _∷_; _++_)
open import Data.Nat using (ℕ; _≡ᵇ_)
open import Data.Product using (_×_; _,_; Σ)
open import Relation.Binary.PropositionalEquality
  using (_≡_; refl; cong; cong₂)

-- 布尔项：self 是 x∈P；mem a 是参数 a∈P；eq a 是 x=a。
data BTerm : Set where
  bself : BTerm
  bmem : ℕ → BTerm
  beq : ℕ → BTerm
  band : BTerm → BTerm → BTerm
  bnot : BTerm → BTerm

params : BTerm → List ℕ
params bself = []
params (bmem a) = a ∷ []
params (beq a) = a ∷ []
params (band l r) = params l ++ params r
params (bnot l) = params l

beval : (ℕ → Bool) → BTerm → ℕ → Bool
beval P bself x = P x
beval P (bmem a) x = P a
beval P (beq a) x = x ≡ᵇ a
beval P (band l r) x = beval P l x ∧ beval P r x
beval P (bnot l) x = not (beval P l x)

-- 谓词外延性：外延相等 ⟹ 定义内容相同（L[U] 只依赖 U 外延）。
eval-ext : (P Q : ℕ → Bool) → (∀ a → P a ≡ Q a) →
  ∀ t x → beval P t x ≡ beval Q t x
eval-ext P Q hPQ bself x = hPQ x
eval-ext P Q hPQ (bmem a) x = hPQ a
eval-ext P Q hPQ (beq a) x = refl
eval-ext P Q hPQ (band l r) x =
  cong₂ _∧_ (eval-ext P Q hPQ l x) (eval-ext P Q hPQ r x)
eval-ext P Q hPQ (bnot l) x =
  cong not (eval-ext P Q hPQ l x)

-- 自建列表成员关系（避免 stdlib 版本命名差异）。
data _∈'_ : ℕ → List ℕ → Set where
  here' : ∀ {x xs} → x ∈' (x ∷ xs)
  there' : ∀ {y x xs} → x ∈' xs → x ∈' (y ∷ xs)

∈'-++-left : ∀ a l r → a ∈' l → a ∈' (l ++ r)
∈'-++-left a (x ∷ l) r here' = here'
∈'-++-left a (x ∷ l) r (there' p) = there' (∈'-++-left a l r p)

∈'-++-right : ∀ a l r → a ∈' r → a ∈' (l ++ r)
∈'-++-right a [] r p = p
∈'-++-right a (x ∷ l) r p = there' (∈'-++-right a l r p)

-- 参数局部性：P、Q 在 R 上一致、x 满足 R、参数都满足 R
-- ⟹ 求值一致（L[U]=L[Ũ] 截断的影子）。
eval-local : (P Q : ℕ → Bool) (R : ℕ → Set) →
  (∀ a → R a → P a ≡ Q a) →
  ∀ x → R x → ∀ t → (∀ a → a ∈' params t → R a) →
  beval P t x ≡ beval Q t x
eval-local P Q R hR x Hx bself Hin = hR x Hx
eval-local P Q R hR x Hx (bmem a) Hin = hR a (Hin a here')
eval-local P Q R hR x Hx (beq a) Hin = refl
eval-local P Q R hR x Hx (band l r) Hin =
  cong₂ _∧_
    (eval-local P Q R hR x Hx l (λ a Ha → Hin a (∈'-++-left a (params l) (params r) Ha)))
    (eval-local P Q R hR x Hx r (λ a Ha → Hin a (∈'-++-right a (params l) (params r) Ha)))
eval-local P Q R hR x Hx (bnot l) Hin =
  cong not (eval-local P Q R hR x Hx l Hin)

-- 样本：焦点 2 的主测度。
peq2 : ℕ → Bool
peq2 n = n ≡ᵇ 2

sample-self : beval peq2 bself 2 ≡ true
sample-self = refl

sample-other : beval peq2 bself 0 ≡ false
sample-other = refl

sample-and : beval peq2 (band (beq 2) bself) 2 ≡ true
sample-and = refl
