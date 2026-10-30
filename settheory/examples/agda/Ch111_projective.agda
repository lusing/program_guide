-- 第 111 章：有限树良基判定与秩递归——余解析集树表示的影子。
module Ch111_projective where

open import Data.Nat using (ℕ; zero; suc; _⊔_; _≤_; z≤n; s≤s)
open import Data.Nat.Properties using (≤-trans)
open import Relation.Binary.PropositionalEquality using (_≡_; refl; cong)

cong₂ : {A B C : Set} (f : A → B → C) {x y : A} {u v : B} →
         x ≡ y → u ≡ v → f x u ≡ f y v
cong₂ f refl refl = refl
open import Data.List using (List; []; _∷_; _++_)
open import Data.List.Relation.Unary.Any using (Any; here; there)
open import Data.Product using (_×_; _,_)
open import Relation.Binary.PropositionalEquality using (_≡_; refl; cong)
open import Relation.Nullary using (Dec; yes; no; ¬_)
open import Data.Empty using (⊥; ⊥-elim)

-- ── 零、自建件（沿 109/110 章 Dec 路线） ──

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

inL-dec : (x : List ℕ) (l : List (List ℕ)) → Dec (Any (x ≡_) l)
inL-dec x [] = no (λ ())
inL-dec x (y ∷ ys) with nat-eq-head x y
  where
  nat-eq-head : (a b : List ℕ) → Dec (a ≡ b)
  nat-eq-head [] [] = yes refl
  nat-eq-head [] (z ∷ _) = no (λ ())
  nat-eq-head (w ∷ _) [] = no (λ ())
  nat-eq-head (w ∷ ws) (z ∷ zs) with nat-eq-dec w z
  ... | no nwz = no (λ e → nwz (cong hd e))
    where
    hd : List ℕ → ℕ
    hd [] = zero
    hd (h ∷ _) = h
  ... | yes ewz with nat-eq-head ws zs
  ...   | no nws = no (λ e → nws (cong tl e))
    where
    tl : List ℕ → List ℕ
    tl [] = []
    tl (_ ∷ t) = t
  ...   | yes ews = yes (cong₂ _∷_ ewz ews)
inL-dec x (y ∷ ys) | yes exy = yes (here exy)
inL-dec x (y ∷ ys) | no nxy with inL-dec x ys
... | yes e = yes (there e)
... | no ne = no nd
  where
  nd : Any (x ≡_) (y ∷ ys) → ⊥
  nd (here e) = nxy e
  nd (there e) = ne e

-- ── 一、赋秩函数（燃料递归：叶 0、内部点 = 子最大 + 1） ──

rho : List (List ℕ) → ℕ → List ℕ → ℕ
rho T zero _ = zero
rho T (suc f) s with inL-dec (s ++ zero ∷ []) T | inL-dec (s ++ suc zero ∷ []) T
rho T (suc f) s | yes _ | yes _ = suc (rho T f (s ++ zero ∷ []) ⊔ rho T f (s ++ suc zero ∷ []))
rho T (suc f) s | yes _ | no _  = suc (rho T f (s ++ zero ∷ []) ⊔ rho T f (s ++ suc zero ∷ []))
rho T (suc f) s | no _  | yes _ = suc (rho T f (s ++ zero ∷ []) ⊔ rho T f (s ++ suc zero ∷ []))
rho T (suc f) s | no _  | no _  = zero

-- ── 二、秩不超过燃料（引理 3.5「秩有界」的机制件） ──

⊔-le : ∀ {a b f : ℕ} → a ≤ f → b ≤ f → a ⊔ b ≤ f
⊔-le z≤n hb = hb
⊔-le {suc a} {zero} ha z≤n = ha
⊔-le {suc a} {suc b} {suc f} (s≤s ha) (s≤s hb) = s≤s (⊔-le ha hb)

rho≤fuel : (T : List (List ℕ)) (f : ℕ) (s : List ℕ) → rho T f s ≤ f
rho≤fuel T zero s = z≤n
rho≤fuel T (suc f) s with inL-dec (s ++ zero ∷ []) T | inL-dec (s ++ suc zero ∷ []) T
rho≤fuel T (suc f) s | yes _ | yes _ = s≤s (⊔-le (rho≤fuel T f (s ++ zero ∷ []))
                                                   (rho≤fuel T f (s ++ suc zero ∷ [])))
rho≤fuel T (suc f) s | yes _ | no _  = s≤s (⊔-le (rho≤fuel T f (s ++ zero ∷ []))
                                                   (rho≤fuel T f (s ++ suc zero ∷ [])))
rho≤fuel T (suc f) s | no _ | yes _ = s≤s (⊔-le (rho≤fuel T f (s ++ zero ∷ []))
                                                   (rho≤fuel T f (s ++ suc zero ∷ [])))
rho≤fuel T (suc f) s | no _ | no _ = z≤n
-- ── 三、叶判定（双子皆不在树中 ⟹ 秩为 0） ──

not-in-child : (T : List (List ℕ)) (f : ℕ) (s : List ℕ) →
               ¬ (Any (s ++ zero ∷ [] ≡_) T) → ¬ (Any (s ++ suc zero ∷ [] ≡_) T) →
               rho T (suc f) s ≡ zero
not-in-child T f s n0 n1 with inL-dec (s ++ zero ∷ []) T | inL-dec (s ++ suc zero ∷ []) T
not-in-child T f s n0 n1 | yes h0 | _ = ⊥-elim (n0 h0)
not-in-child T f s n0 n1 | no _ | yes h1 = ⊥-elim (n1 h1)
not-in-child T f s n0 n1 | no _ | no _ = refl

-- ── 四、样本账（决定性核查） ──

T₀ : List (List ℕ)
T₀ = [] ∷ (zero ∷ []) ∷ (suc zero ∷ []) ∷ []

T₁ : List (List ℕ)
T₁ = [] ∷ (zero ∷ []) ∷ (suc zero ∷ []) ∷ (zero ∷ zero ∷ []) ∷ []

T₂ : List (List ℕ)
T₂ = [] ∷ (zero ∷ []) ∷ (suc zero ∷ []) ∷ (zero ∷ zero ∷ []) ∷ (zero ∷ suc zero ∷ []) ∷ []

-- T₀ 根秩 1（两子皆叶）；T₁ 根秩 2（= 深度，无秩树的数值影子）。
rho-T₀ : rho T₀ (suc (suc zero)) [] ≡ suc zero
rho-T₀ = refl

rho-T₁ : rho T₁ (suc (suc zero)) [] ≡ suc (suc zero)
rho-T₁ = refl

-- T₂ 的秩表：根 2、中层 1、叶 0。
rho-T₂-root : rho T₂ (suc (suc (suc zero))) [] ≡ suc (suc zero)
rho-T₂-root = refl

rho-T₂-mid : rho T₂ (suc (suc (suc zero))) (zero ∷ []) ≡ suc zero
rho-T₂-mid = refl

rho-T₂-leaf : rho T₂ (suc (suc (suc zero))) (zero ∷ zero ∷ []) ≡ zero
rho-T₂-leaf = refl
