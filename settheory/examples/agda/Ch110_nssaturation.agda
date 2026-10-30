-- 第 110 章：投影、核刻画与提升——饱和界与光影原理的有限影子。
module Ch110_nssaturation where

open import Data.Nat using (ℕ; zero; suc)
open import Data.List using (List; []; _∷_; _++_; filter)
open import Data.List.Relation.Unary.Any using (Any; here; there; map)
open import Data.Product using (_×_; _,_; proj₁; proj₂)
open import Data.Sum using (_⊎_; inj₁; inj₂)
open import Relation.Binary.PropositionalEquality using (_≡_; refl; cong; sym; trans; subst)
open import Relation.Nullary using (Dec; yes; no; ¬_; ¬?)
open import Data.Empty using (⊥; ⊥-elim)

pred : ℕ → ℕ
pred zero = zero
pred (suc k) = k

-- ── 零、自建件（沿 109 章 Dec 路线） ──

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

-- ── 一、投影：抹掉坐标 0（N ↦ N∩ω₁ 的影子） ──

projL : List ℕ → List ℕ
projL X = diffL X (zero ∷ [])

-- ── 二、核刻画：理想（X ⊆ {0}）= 投影的核 ──

inI0 : List ℕ → Set
inI0 X = ∀ x → Any (x ≡_) X → x ≡ zero

kernel-forward : (X : List ℕ) → inI0 X → projL X ≡ []
kernel-forward X hI = no-elem-nil (projL X) hnil
  where
  hnil : ∀ x → ¬ (Any (x ≡_) (projL X))
  hnil x h with diffL-any X (zero ∷ []) x h
  ... | h1 , h2 = ⊥-elim (h2 (here (hI x h1)))

zero-eq : (x : ℕ) → Any (x ≡_) (zero ∷ []) → x ≡ zero
zero-eq x (here e) = e
zero-eq x (there ())

filter-mem : (D : List ℕ) (x : ℕ) → ¬ (Any (x ≡_) D) →
             (C : List ℕ) → Any (x ≡_) C → Any (x ≡_) (diffL C D)
filter-mem D x nxd [] ()
filter-mem D x nxd (y ∷ C) (here e) with inL-dec y D
... | yes yd = ⊥-elim (nxd (map (trans e) yd))
... | no nyd = here e
filter-mem D x nxd (y ∷ C) (there t) with inL-dec y D
... | yes yd = filter-mem D x nxd C t
... | no nyd = there (filter-mem D x nxd C t)

kernel-backward : (X : List ℕ) → projL X ≡ [] → inI0 X
kernel-backward X hp x hx with inL-dec x (zero ∷ [])
... | yes xd = zero-eq x xd
... | no nxd = ⊥-elim (hnil (subst (λ l → Any (x ≡_) l) hp mem))
  where
  mem : Any (x ≡_) (projL X)
  mem = filter-mem (zero ∷ []) x nxd X hx
  hnil : Any (x ≡_) [] → ⊥
  hnil ()

-- ── 三、提升：Y ⊆ {1,2} 时 Y 是自己的原像 ──

neq10 : zero ≡ suc zero → ⊥
neq10 ()

neq20 : zero ≡ suc (suc zero) → ⊥
neq20 ()

keep-no : (y : ℕ) → Any (y ≡_) (zero ∷ []) →
          ((y ≡ suc zero) ⊎ (y ≡ suc (suc zero))) → ⊥
keep-no y y0 (inj₁ e) = neq10 (trans (sym (zero-eq y y0)) e)
keep-no y y0 (inj₂ e) = neq20 (trans (sym (zero-eq y y0)) e)

projL-keep : (Y : List ℕ) →
             (∀ y → Any (y ≡_) Y → (y ≡ suc zero) ⊎ (y ≡ suc (suc zero))) →
             projL Y ≡ Y
projL-keep [] p = refl
projL-keep (y ∷ Y) p with inL-dec y (zero ∷ [])
... | yes y0 = ⊥-elim (keep-no y y0 (p y (here refl)))
... | no ny0 = cong (y ∷_) (projL-keep Y p')
  where
  p' : ∀ z → Any (z ≡_) Y → (z ≡ suc zero) ⊎ (z ≡ suc (suc zero))
  p' z hz = p z (there hz)

-- ── 四、样本账（决定性核查） ──

U0 : List ℕ
U0 = zero ∷ suc zero ∷ suc (suc zero) ∷ []

proj-sample : projL U0 ≡ suc zero ∷ suc (suc zero) ∷ []
proj-sample = refl

proj-sample2 : projL (zero ∷ suc zero ∷ []) ≡ suc zero ∷ []
proj-sample2 = refl

proj-sample3 : projL (zero ∷ []) ≡ []
proj-sample3 = refl
