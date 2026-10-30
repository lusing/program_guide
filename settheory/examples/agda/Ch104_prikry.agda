-- 第 104 章：stem 列表递归、初始段序与纯延长/相容判定。
module Ch104_prikry where

open import Data.Nat using (ℕ; zero; suc; _<_; _≤_; z≤n; s≤s)
open import Data.Nat.Properties using (≤-refl; ≤-trans)
open import Data.List using (List; []; _∷_)
open import Data.Bool using (Bool; true; false; if_then_else_)
open import Data.Product using (_×_; _,_)
open import Data.Empty using (⊥)
open import Relation.Binary.PropositionalEquality
  using (_≡_; refl; trans; cong; sym)
open import Relation.Nullary using (¬_)

-- ── 零、自建件：相等、成员、包含 ──

nat-eq : ℕ → ℕ → Bool
nat-eq zero zero = true
nat-eq zero (suc _) = false
nat-eq (suc _) zero = false
nat-eq (suc m) (suc n) = nat-eq m n

nat-eq-refl : ∀ n → nat-eq n n ≡ true
nat-eq-refl zero = refl
nat-eq-refl (suc n) = nat-eq-refl n

nat-eq-≡ : ∀ y x → nat-eq y x ≡ true → y ≡ x
nat-eq-≡ zero zero q = refl
nat-eq-≡ zero (suc x) ()
nat-eq-≡ (suc y) zero ()
nat-eq-≡ (suc y) (suc x) q = cong suc (nat-eq-≡ y x q)

data _∈L_ {A : Set} : A → List A → Set where
  here  : ∀ {x xs} → x ∈L (x ∷ xs)
  there : ∀ {y x xs} → x ∈L xs → x ∈L (y ∷ xs)

inL : ℕ → List ℕ → Bool
inL x [] = false
inL x (y ∷ ys) = if nat-eq y x then true else inL x ys

inL-sound : ∀ x ys → inL x ys ≡ true → x ∈L ys
inL-sound x [] ()
inL-sound x (y ∷ ys) p with nat-eq y x in eq
... | true rewrite sym (nat-eq-≡ y x eq) = here
... | false = there (inL-sound x ys p)

inL-complete : ∀ x ys → x ∈L ys → inL x ys ≡ true
inL-complete x [] ()
inL-complete .y (y ∷ ys) here rewrite nat-eq-refl y = refl
inL-complete x (y ∷ ys) (there m) with nat-eq y x
... | true = refl
... | false = inL-complete x ys m

inclL : List ℕ → List ℕ → Set
inclL xs ys = ∀ x → x ∈L xs → x ∈L ys

-- ── 一、stem 递归与初始段序（Task 19 Step 2 指定件） ──

data Stem : List ℕ → Set where
  s-nil  : Stem []
  s-one  : ∀ {a} → Stem (a ∷ [])
  s-cons : ∀ {a b l} → a < b → Stem (b ∷ l) → Stem (a ∷ b ∷ l)

data IsPrefix : List ℕ → List ℕ → Set where
  p-nil    : ∀ {s} → IsPrefix [] s
  p-refl   : ∀ {s} → IsPrefix s s
  p-extend : ∀ {t x s} → IsPrefix t s → IsPrefix (x ∷ t) (x ∷ s)

isPrefix-trans : ∀ {t s u} → IsPrefix t s → IsPrefix s u → IsPrefix t u
isPrefix-trans p-nil _ = p-nil
isPrefix-trans p-refl h = h
isPrefix-trans (p-extend k) p-refl = p-extend k
isPrefix-trans (p-extend k) (p-extend k') = p-extend (isPrefix-trans k k')

-- stem 的初始段仍是 stem（对 IsPrefix 归纳 + Stem 反演）。
prefix-stem : ∀ {t s} → IsPrefix t s → Stem s → Stem t
prefix-stem p-nil _ = s-nil
prefix-stem p-refl hs = hs
prefix-stem (p-extend p-nil) hs = s-one
prefix-stem (p-extend p-refl) hs = hs
prefix-stem (p-extend (p-extend k)) (s-cons x<y hs') =
  s-cons x<y (prefix-stem (p-extend k) hs')

-- ── 二、Prikry 条件、纯延长与全序 ──

record PCond : Set where
  constructor pc
  field
    ps : List ℕ
    pb : List ℕ

ple : PCond → PCond → Set
ple p q =
  PCond.ps p ≡ PCond.ps q × inclL (PCond.pb p) (PCond.pb q)

ple-refl : ∀ p → ple p p
ple-refl p = refl , (λ x h → h)

ple-trans : ∀ p q r → ple p q → ple q r → ple p r
ple-trans p q r (e₁ , h₁) (e₂ , h₂) =
  trans e₁ e₂ , (λ x h → h₂ x (h₁ x h))

prikryLe : PCond → PCond → Set
prikryLe p q =
  IsPrefix (PCond.ps q) (PCond.ps p) × inclL (PCond.pb p) (PCond.pb q)

prikryLe-refl : ∀ p → prikryLe p p
prikryLe-refl p = p-refl , (λ x h → h)

-- 同 stem 的序归结为包含。
same-stem-le : ∀ s A B → prikryLe (pc s A) (pc s B) → inclL A B
same-stem-le s A B (_ , h) = h

-- ── 三、样本 ──

2<5 : 2 < 5
2<5 = s≤s (s≤s (s≤s z≤n))

5<7 : 5 < 7
5<7 = s≤s (s≤s (s≤s (s≤s (s≤s (s≤s z≤n)))))

sample-stem : Stem (2 ∷ 5 ∷ 7 ∷ [])
sample-stem = s-cons 2<5 (s-cons 5<7 s-one)

sample-prefix : IsPrefix (2 ∷ 5 ∷ []) (2 ∷ 5 ∷ 7 ∷ [])
sample-prefix = p-extend (p-extend p-nil)

-- 前段继承 stem 性。
sample-prefix-stem : Stem (2 ∷ 5 ∷ [])
sample-prefix-stem = prefix-stem sample-prefix sample-stem
