-- 第 112 章：有限补集之交空与两层树的截面——Σ¹₂ 的影子。
module Ch112_sigma12 where

open import Data.Nat using (ℕ; zero; suc)
open import Data.List using (List; []; _∷_; length; filter)
open import Data.List.Relation.Unary.Any using (Any; here; there; map)
open import Data.Product using (_×_; _,_; proj₁; proj₂)
open import Relation.Binary.PropositionalEquality using (_≡_; refl; cong; sym; trans)
open import Relation.Nullary using (Dec; yes; no; ¬_; ¬?)
open import Data.Empty using (⊥; ⊥-elim)
open import Data.Bool using (Bool; true; false; if_then_else_)

-- ── 零、自建件（沿 110/111 章 Dec 路线） ──

pred : ℕ → ℕ
pred zero = zero
pred (suc k) = k

nat-eq-dec : (x y : ℕ) → Dec (x ≡ y)
nat-eq-dec zero zero = yes refl
nat-eq-dec zero (suc _) = no (λ ())
nat-eq-dec (suc _) zero = no (λ ())
nat-eq-dec (suc m) (suc n) with nat-eq-dec m n
... | yes e = yes (cong suc e)
... | no ne = no (λ se → ne (cong pred se))

nat-eq : ℕ → ℕ → Bool
nat-eq zero zero = true
nat-eq zero (suc _) = false
nat-eq (suc _) zero = false
nat-eq (suc m) (suc n) = nat-eq m n

inL-dec : (x : ℕ) (l : List ℕ) → Dec (Any (x ≡_) l)
inL-dec x [] = no (λ ())
inL-dec x (y ∷ ys) with nat-eq-dec x y
... | yes e = yes (here e)
... | no ne with inL-dec x ys
...   | yes e2 = yes (there e2)
...   | no ne2 = no nd
  where
  nd : Any (x ≡_) (y ∷ ys) → ⊥
  nd (here e) = ne e
  nd (there e) = ne2 e

list-eq : List ℕ → List ℕ → Bool
list-eq [] [] = true
list-eq [] (_ ∷ _) = false
list-eq (_ ∷ _) [] = false
list-eq (x ∷ xs) (y ∷ ys) = if nat-eq x y then list-eq xs ys else false

takeL : ℕ → List ℕ → List ℕ
takeL zero _ = []
takeL (suc k) [] = []
takeL (suc k) (x ∷ xs) = x ∷ takeL k xs

-- ── 一、两层树的截面（定义 3.8 的有限替身） ──

sec : (T : List (List ℕ × List ℕ)) (a : List ℕ) → List (List ℕ)
sec [] a = []
sec ((s , h) ∷ T) a =
  if list-eq s (takeL (length h) a) then h ∷ sec T a else sec T a

-- ── 二、补集之交空（博雷尔代码补运算的核——引理 3.15） ──

compl : (U A : List ℕ) → List ℕ
compl U A = filter (λ z → ¬? (inL-dec z A)) U

-- filter 保留者不在 D 中（Dec 分支自带证明——沿 110 章 filter-mem）。
filter-disj : (D C : List ℕ) (x : ℕ) →
              Any (x ≡_) (filter (λ z → ¬? (inL-dec z D)) C) →
              ¬ (Any (x ≡_) D)
filter-disj D [] x ()
filter-disj D (y ∷ C) x h with inL-dec y D
filter-disj D (y ∷ C) x h | yes yd = filter-disj D C x h
filter-disj D (y ∷ C) x h | no nyd with h
... | here e = λ h2 → nyd (map (λ p → trans (sym e) p) h2)
... | there t = filter-disj D C x t

-- 补集之交空：x ∈ A ∧ x ∈ A^c ⟹ ⊥（两行收口）。
not-in-both : (U A : List ℕ) (x : ℕ) →
              Any (x ≡_) A → Any (x ≡_) (compl U A) → ⊥
not-in-both U A x ha hc = filter-disj A U x hc ha

-- ── 三、样本账 ──

Tb : List (List ℕ × List ℕ)
Tb = ([] , []) ∷
     (zero ∷ [] , zero ∷ []) ∷
     (zero ∷ [] , suc zero ∷ []) ∷
     (zero ∷ zero ∷ [] , zero ∷ zero ∷ []) ∷ []

sec-sample : sec Tb (zero ∷ zero ∷ []) ≡
             [] ∷ (zero ∷ []) ∷ (suc zero ∷ []) ∷ (zero ∷ zero ∷ []) ∷ []
sec-sample = refl

sec-sample2 : sec Tb (zero ∷ suc zero ∷ []) ≡
              [] ∷ (zero ∷ []) ∷ (suc zero ∷ []) ∷ []
sec-sample2 = refl

-- 补集样本：U = [0,1,2]、A = [1]：A^c = [0,2]。
compl-sample : compl (zero ∷ suc zero ∷ suc (suc zero) ∷ [])
                    (suc zero ∷ []) ≡
               zero ∷ (suc (suc zero) ∷ [])
compl-sample = refl
