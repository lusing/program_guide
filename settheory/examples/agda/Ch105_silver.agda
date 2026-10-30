-- 第 105 章：Silver 条件（有限部分函数）的偏序律、合并与支撑。
module Ch105_silver where

open import Data.Nat using (ℕ; zero; suc; _<_; _≤_; z≤n; s≤s; _<ᵇ_)
open import Data.Nat.Properties using (≤-refl; ≤-trans; m≤n⇒m≤1+n)
open import Data.List using (List; []; _∷_; _++_; filterᵇ; length)
open import Data.Bool using (Bool; true; false; if_then_else_)
open import Data.Product using (_×_; _,_; proj₁; proj₂)
open import Data.Sum using (_⊎_; inj₁; inj₂)
open import Data.Empty using (⊥)
open import Relation.Binary.PropositionalEquality
  using (_≡_; refl; cong; trans)
open import Relation.Nullary using (¬_)

-- ── 零、自建件 ──

nat-eq : ℕ → ℕ → Bool
nat-eq zero zero = true
nat-eq zero (suc _) = false
nat-eq (suc _) zero = false
nat-eq (suc m) (suc n) = nat-eq m n

key-eq : ℕ × ℕ → ℕ × ℕ → Bool
key-eq (a , b) (c , d) = if nat-eq a c then nat-eq b d else false

data _∈L_ {A : Set} : A → List A → Set where
  here  : ∀ {x xs} → x ∈L (x ∷ xs)
  there : ∀ {y x xs} → x ∈L xs → x ∈L (y ∷ xs)

∈-++₁ : ∀ {A : Set} (x : A) (l r : List A) →
  (x ∈L l) ⊎ (x ∈L r) → x ∈L (l ++ r)
∈-++₁ x [] r (inj₁ ())
∈-++₁ x (y ∷ l) r (inj₁ here) = here
∈-++₁ x (y ∷ l) r (inj₁ (there h)) =
  there (∈-++₁ x l r (inj₁ h))
∈-++₁ x [] r (inj₂ h) = h
∈-++₁ x (y ∷ l) r (inj₂ h) =
  there (∈-++₁ x l r (inj₂ h))

Triple : Set
Triple = (ℕ × ℕ) × ℕ

-- ── 一、Silver 条件与偏序律（Task 20 Step 2 指定件） ──

-- 反向包含：q ≤ p ⟺ p ⊆ q。
extC : List Triple → List Triple → Set
extC p q = ∀ x → x ∈L p → x ∈L q

extC-refl : ∀ p → extC p p
extC-refl p x h = h

extC-trans : ∀ p q r → extC p q → extC q r → extC p r
extC-trans p q r h₁ h₂ x hx = h₂ x (h₁ x hx)

keys : List Triple → List (ℕ × ℕ)
keys [] = []
keys ((k , _) ∷ t) = k ∷ keys t

inKeys : ℕ × ℕ → List (ℕ × ℕ) → Bool
inKeys k [] = false
inKeys k (k' ∷ t) = if key-eq k k' then true else inKeys k t

-- 合并：q 中去掉已覆盖键。
splice : List (ℕ × ℕ) → List Triple → List Triple
splice ks [] = []
splice ks (x@((k , n) , _) ∷ t) =
  if inKeys (k , n) ks then splice ks t else x ∷ splice ks t

unionC : List Triple → List Triple → List Triple
unionC p q = p ++ splice (keys p) q

unionC-left : ∀ p q x → x ∈L p → x ∈L (unionC p q)
unionC-left p q x hx =
  ∈-++₁ x p (splice (keys p) q) (inj₁ hx)

-- ── 二、支撑与 Easton 条款（定义 2.9/2.10 影子） ──

support : List Triple → List ℕ
support [] = []
support (((a , _) , _) ∷ t) = a ∷ support t

below : ℕ → List ℕ → List ℕ
below mu l = filterᵇ (λ a → a <ᵇ mu) l

easton-ok : List Triple → ℕ → Set
easton-ok p mu = length (below mu (support p)) < mu

-- filter 长度不超过原表（自证）。
below-length : ∀ mu l → length (below mu l) ≤ length l
below-length mu [] = z≤n
below-length mu (a ∷ t) with a <ᵇ mu
... | true = s≤s (below-length mu t)
... | false = m≤n⇒m≤1+n (below-length mu t)

support-length : ∀ p → length (support p) ≤ length p
support-length [] = z≤n
support-length (((a , _) , _) ∷ t) = s≤s (support-length t)

-- |dom| ≤ 2 ⟹ |spt ∩ 3| < 3（Easton 小条件样本）。
easton-small : ∀ p → length p ≤ 2 → easton-ok p 3
easton-small p h =
  s≤s (≤-trans (below-length 3 (support p))
    (≤-trans (support-length p) h))

-- ── 三、相容（键不相交 ⟹ 相容）与大拿影子样本 ──

agree : List Triple → List Triple → Set
agree p q = ∀ x y → x ∈L p → y ∈L q →
  proj₁ x ≡ proj₁ y → proj₂ x ≡ proj₂ y

-- 样本：键不相交时相容性空洞成立（键等式不可满足）。
key-disjoint-agree :
  agree (((0 , 0) , 0) ∷ []) (((1 , 0) , 1) ∷ [])
key-disjoint-agree _ _ here here hkey = cong proj₁ hkey
key-disjoint-agree _ _ here (there ())
key-disjoint-agree _ _ (there ()) _

-- 合并是两侧的下界（大拿/master condition 的双元样本）。
unionC-master-left : ∀ p q → extC p (unionC p q)
unionC-master-left p q x hx =
  ∈-++₁ x p (splice (keys p) q) (inj₁ hx)
