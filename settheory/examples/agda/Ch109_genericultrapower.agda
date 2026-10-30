-- 第 109 章：理想力迫的序与商关系——泛型超幂的有限影子。
module Ch109_genericultrapower where

open import Data.Nat using (ℕ; zero; suc; _<ᵇ_)
open import Data.List using (List; []; _∷_; _++_; filter; filterᵇ)
open import Data.List.Relation.Unary.Any using (Any; here; there; map)
open import Data.Product using (_×_; _,_; proj₁; proj₂)
open import Relation.Binary.PropositionalEquality using (_≡_; refl; cong; sym; trans)
open import Relation.Nullary using (Dec; yes; no; ¬_; ¬?)
open import Data.Bool using (Bool; true; false; if_then_else_; T)
open import Data.Empty using (⊥; ⊥-elim)
open import Data.Unit using (⊤; tt)

pred : ℕ → ℕ
pred zero = zero
pred (suc k) = k

-- ── 零、自建件：可判定的成员关系（Dec 路线——方程随 yes/no 保留） ──

nat-eq-dec : (x y : ℕ) → Dec (x ≡ y)
nat-eq-dec zero zero = yes refl
nat-eq-dec zero (suc _) = no (λ ())
nat-eq-dec (suc _) zero = no (λ ())
nat-eq-dec (suc m) (suc n) with nat-eq-dec m n
... | yes e = yes (cong suc e)
... | no ne = no (λ se → ne (cong pred se))

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

-- ── 一、理想力迫的序：C ≤ D ⟺ C − D ∈ I（差集的成员刻画） ──

diffL : List ℕ → List ℕ → List ℕ
diffL C D = filter (λ z → ¬? (inL-dec z D)) C

diffL-any : (C D : List ℕ) (x : ℕ) →
            Any (x ≡_) (diffL C D) → Any (x ≡_) C × ¬ (Any (x ≡_) D)
diffL-any [] D x ()
diffL-any (y ∷ C) D x h with inL-dec y D
... | yes yd = let ih = diffL-any C D x h in there (proj₁ ih) , proj₂ ih
... | no nyd with h
...   | here eq = here eq ,
                 (λ ad → nyd (map (λ xw → trans (sym eq) xw) ad))
...   | there h' = let ih = diffL-any C D x h' in there (proj₁ ih) , proj₂ ih

no-elem-nil : {A : Set} (l : List A) → (∀ x → ¬ (Any (x ≡_) l)) → l ≡ []
no-elem-nil [] _ = refl
no-elem-nil (x ∷ l) h = ⊥-elim (h x (here refl))

diffL-id : (C : List ℕ) → diffL C C ≡ []
diffL-id C = no-elem-nil (diffL C C) hnil
  where
  hnil : ∀ x → ¬ (Any (x ≡_) (diffL C C))
  hnil x h with diffL-any C C x h
  ... | h1 , h2 = ⊥-elim (h2 h1)

-- ── 二、商关系：X ≡ Y（mod I）⟺ X△Y ∈ I ──

nat-eq : ℕ → ℕ → Bool
nat-eq zero zero = true
nat-eq zero (suc _) = false
nat-eq (suc _) zero = false
nat-eq (suc m) (suc n) = nat-eq m n

list-eq : List ℕ → List ℕ → Bool
list-eq [] [] = true
list-eq [] (_ ∷ _) = false
list-eq (_ ∷ _) [] = false
list-eq (x ∷ xs) (y ∷ ys) = if nat-eq x y then list-eq xs ys else false

inLL : List ℕ → List (List ℕ) → Bool
inLL X [] = false
inLL X (Y ∷ I) = if list-eq X Y then true else inLL X I

eqv : List (List ℕ) → List ℕ → List ℕ → Set
eqv I X Y = T (inLL (diffL X Y ++ diffL Y X) I)

++-nil : (l : List ℕ) → l ++ [] ≡ l
++-nil [] = refl
++-nil (x ∷ l) = cong (x ∷_) (++-nil l)

eqv-refl : (I : List (List ℕ)) (X : List ℕ) →
           T (inLL [] I) → eqv I X X
eqv-refl I X h rewrite diffL-id X = h

-- ── 三、样本理想与真值集（决定性核查） ──

U0 : List ℕ
U0 = 0 ∷ 1 ∷ 2 ∷ []

I0 : List (List ℕ)
I0 = [] ∷ (0 ∷ []) ∷ []

-- 序样本：{1} ≤ {0,1}（差 ∅ ∈ I0）。
forces-sample : T (inLL (diffL (1 ∷ []) (0 ∷ 1 ∷ [])) I0)
forces-sample = tt

-- 商关系样本：U0 ≡ {1,2}（对称差 [0] ∈ I0）。
eqv-sample : eqv I0 U0 (1 ∷ 2 ∷ [])
eqv-sample = tt

-- 样本函数（U0 → ℕ 的表）。
f1 g1 : ℕ → ℕ
f1 zero = 3
f1 (suc zero) = 1
f1 _ = 4
g1 zero = 2
g1 (suc zero) = 2
g1 _ = 0

-- Bool 成员（样本核查用）。
inLb : ℕ → List ℕ → Bool
inLb x [] = false
inLb x (y ∷ ys) = if nat-eq y x then true else inLb x ys

-- 真值集：{a | f1 a < g1 a} = {1}——在主滤子 G1 下裁决为真。
truth-sample : inLb 1 (filterᵇ (λ a → f1 a <ᵇ g1 a) U0) ≡ true
truth-sample = refl

-- 引理 2.29 的影子：主滤子下 [Id] 的取值是那一点。
id-sample : inLb 1 (filterᵇ (λ a → nat-eq a 1) U0) ≡ true
id-sample = refl
