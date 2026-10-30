-- 第 107 章：主条件证书与 (M,P)-泛型条件（有限影子）。
module Ch107_proper where

open import Data.Nat using (ℕ; zero; suc)
open import Data.List using (List; []; _∷_)
open import Data.Bool using (Bool; true; false; if_then_else_; _∨_)
open import Data.Product using (_×_; _,_; ∃-syntax)
open import Data.Empty using (⊥)
open import Relation.Binary.PropositionalEquality using (_≡_; refl)
open import Relation.Nullary using (¬_)
open import Data.Unit using (⊤; tt)

-- ── 零、自建件：Bool 成员与真值族（沿 103/105 章 inKeys 路线） ──

nat-eq : ℕ → ℕ → Bool
nat-eq zero zero = true
nat-eq zero (suc _) = false
nat-eq (suc _) zero = false
nat-eq (suc m) (suc n) = nat-eq m n

inL : ℕ → List ℕ → Bool
inL x [] = false
inL x (y ∷ ys) = if nat-eq y x then true else inL x ys

T : Bool → Set
T true = ⊤
T false = ⊥

-- ── 一、相容、反链、准稠密（定义 2.21 的内核） ──

Compat : (ℕ → List ℕ) → ℕ → ℕ → Set
Compat ext r p = ∃[ s ] ((inL s (ext r) ≡ true) × (inL s (ext p) ≡ true))

Antichain : (ℕ → List ℕ) → List ℕ → Set
Antichain ext A = ∀ p → T (inL p A) → ∀ q → T (inL q A) →
  ¬ (p ≡ q) → ¬ (Compat ext p q)

PredenseBelow : (ℕ → List ℕ) → List ℕ → ℕ → Set
PredenseBelow ext A q = ∀ r → T (inL r (ext q)) →
  ∃[ p ] (T (inL p A) × Compat ext r p)

-- 反链族的成员（单层用归纳族即可——无荒谬模式需求）。
data _∈F_ : List ℕ → List (List ℕ) → Set where
  fhere  : ∀ {A Fs} → A ∈F (A ∷ Fs)
  fthere : ∀ {B A Fs} → A ∈F Fs → A ∈F (B ∷ Fs)

GenericCond : (ℕ → List ℕ) → List (List ℕ) → ℕ → Set
GenericCond ext 𝒜 q = ∀ A → A ∈F 𝒜 → PredenseBelow ext A q

-- ── 二、条件复合保持证书（Task 22 Step 2 指定件） ──

inL-mono : (xs ys : List ℕ) → (∀ x → inL x xs ≡ true → inL x ys ≡ true) →
  ∀ x → inL x xs ≡ true → inL x ys ≡ true
inL-mono xs ys h x hx = h x hx

generic-strengthen : (ext : ℕ → List ℕ) →
  (𝒜 : List (List ℕ)) → (q q' : ℕ) →
  (∀ r → T (inL r (ext q')) → T (inL r (ext q))) →
  GenericCond ext 𝒜 q → GenericCond ext 𝒜 q'
generic-strengthen ext 𝒜 q q' hsub h A hA r hr' =
  h A hA r (hsub r hr')

-- ── 三、样本宇宙：根 0 分叉到终端 1、2 ──

extT : ℕ → List ℕ
extT zero = zero ∷ suc zero ∷ suc (suc zero) ∷ []
extT (suc zero) = suc zero ∷ []
extT (suc (suc zero)) = suc (suc zero) ∷ []
extT _ = []

A12 : List ℕ
A12 = suc zero ∷ suc (suc zero) ∷ []

-- {1,2} 是反链。
antichain-12 : Antichain extT A12
antichain-12 (suc zero) hp (suc zero) hq hne
  ((suc zero) , refl , refl) = hne refl
antichain-12 (suc zero) hp (suc (suc zero)) hq hne
  ((suc zero) , refl , ())
antichain-12 (suc zero) hp (suc (suc zero)) hq hne
  ((suc (suc zero)) , () , refl)
antichain-12 (suc (suc zero)) hp (suc zero) hq hne
  ((suc zero) , () , refl)
antichain-12 (suc (suc zero)) hp (suc zero) hq hne
  ((suc (suc zero)) , refl , ())
antichain-12 (suc (suc zero)) hp (suc (suc zero)) hq hne
  ((suc (suc zero)) , refl , refl) = hne refl
antichain-12 (suc (suc (suc p))) () q hq hne hcp
antichain-12 p hp (suc (suc (suc q))) () hne hcp

-- {1,2} 在 q=0 之下准稠密。
predense-12-0 : PredenseBelow extT A12 zero
predense-12-0 zero hr =
  suc zero , tt , ((suc zero) , refl , refl)
predense-12-0 (suc zero) hr =
  suc zero , tt , ((suc zero) , refl , refl)
predense-12-0 (suc (suc zero)) hr =
  suc (suc zero) , tt , ((suc (suc zero)) , refl , refl)
predense-12-0 (suc (suc (suc r))) ()

-- 0 是 (M,P)-泛型条件。
generic-0 : GenericCond extT (A12 ∷ []) zero
generic-0 A fhere = predense-12-0

-- 证书下放：1 也泛型。
extT-mono-10 : ∀ x → T (inL x (extT (suc zero))) →
               T (inL x (extT zero))
extT-mono-10 (suc zero) h = tt

generic-1 : GenericCond extT (A12 ∷ []) (suc zero)
generic-1 = generic-strengthen extT (A12 ∷ []) zero (suc zero)
  extT-mono-10 generic-0

-- 2 同样继承。
extT-mono-20 : ∀ x → T (inL x (extT (suc (suc zero)))) →
               T (inL x (extT zero))
extT-mono-20 (suc (suc zero)) h = tt

generic-2 : GenericCond extT (A12 ∷ []) (suc (suc zero))
generic-2 = generic-strengthen extT (A12 ∷ []) zero (suc (suc zero))
  extT-mono-20 generic-0
