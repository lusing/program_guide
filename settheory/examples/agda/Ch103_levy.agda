-- 第 103 章：Lévy 条件的有限支撑拼接与稠密扩展（书式新鲜槽号）。
module Ch103_levy where

open import Data.Nat using (ℕ; zero; suc; _+_; _<_; _≤_; z≤n; s≤s)
open import Data.Nat.Properties using (≤-refl; ≤-trans; m≤n+m; m≤m+n)
open import Data.Bool using (Bool; true; false; if_then_else_)
open import Data.Maybe using (Maybe; nothing; just)
open import Data.List using (List; []; _∷_; _++_)
open import Data.Product using (_×_; _,_; proj₁; proj₂)
open import Data.Sum using (_⊎_; inj₁; inj₂)
open import Data.Empty using (⊥; ⊥-elim)
open import Relation.Binary.PropositionalEquality
  using (_≡_; refl; cong; trans; sym)
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

Triple : Set
Triple = (ℕ × ℕ) × ℕ

-- 键相等时成员值可读。
lookup : ℕ × ℕ → List Triple → Maybe ℕ
lookup k [] = nothing
lookup k ((k' , β) ∷ t) = if key-eq k k' then just β else lookup k t

-- 相容：公共键上取值一致。
agree : List Triple → List Triple → Set
agree p q = ∀ k a b → (k , a) ∈L p → (k , b) ∈L q → a ≡ b

-- ── 一、有限支撑拼接：相容两条件的合并 ──

keys : List Triple → List (ℕ × ℕ)
keys [] = []
keys ((k , _) ∷ t) = k ∷ keys t

inKeys : ℕ × ℕ → List (ℕ × ℕ) → Bool
inKeys k [] = false
inKeys k (k' ∷ t) = if key-eq k k' then true else inKeys k t

-- 拼接：q 中去掉已被 p 覆盖的键。
splice-out : List (ℕ × ℕ) → List Triple → List Triple
splice-out ks [] = []
splice-out ks (x@((k₁ , n) , β) ∷ t) =
  if inKeys (k₁ , n) ks then splice-out ks t else x ∷ splice-out ks t

unionC : List Triple → List Triple → List Triple
unionC p q = p ++ splice-out (keys p) q

-- 成员并入账（自证）。
∈-++₁ : ∀ {A : Set} (x : A) (l r : List A) →
  (x ∈L l ⊎ x ∈L r) → x ∈L (l ++ r)
∈-++₁ x [] r (inj₁ ())
∈-++₁ x (y ∷ l) r (inj₁ here) = here
∈-++₁ x (y ∷ l) r (inj₁ (there h)) =
  there (∈-++₁ x l r (inj₁ h))
∈-++₁ x [] r (inj₂ h) = h
∈-++₁ x (y ∷ l) r (inj₂ h) = there (∈-++₁ x l r (inj₂ h))

-- 拼接保留左条件（p ⊆ unionC p q）。
unionC-left : ∀ p q x → x ∈L p → x ∈L (unionC p q)
unionC-left p q x hx = ∈-++₁ x p (splice-out (keys p) q) (inj₁ hx)

-- ── 二、书式新鲜槽号：n₀ = 已用 n 之和 + 1 ──

sumL : List ℕ → ℕ
sumL [] = zero
sumL (x ∷ t) = x + sumL t

ns-of : ℕ → List Triple → List ℕ
ns-of l [] = []
ns-of l (((a , n) , _) ∷ t) =
  if nat-eq a l then n ∷ ns-of l t else ns-of l t

freshN : ℕ → List Triple → ℕ
freshN l p = suc (sumL (ns-of l p))

-- 成员不超过总和（自证）。
sumL-≥ : ∀ l n → n ∈L l → n ≤ sumL l
sumL-≥ [] n ()
sumL-≥ (m ∷ t) .m here = m≤m+n m (sumL t)
sumL-≥ (m ∷ t) n (there h) =
  ≤-trans (sumL-≥ t n h) (m≤n+m (sumL t) m)

-- λ 槽上的已用 n 都小于 n₀（书 p152 的 n = 1+max 同型机制）。
freshN-gt : ∀ l p n → n ∈L (ns-of l p) → n < freshN l p
freshN-gt l p n hn = s≤s (sumL-≥ (ns-of l p) n hn)

-- ── 三、样本 ──

-- 键不相交的两条件拼接后原样保留。
sample-union : unionC (((2 , 0) , 1) ∷ []) (((3 , 1) , 2) ∷ [])
             ≡ (((2 , 0) , 1) ∷ ((3 , 1) , 2) ∷ [])
sample-union = refl

-- λ=2 已用槽 5：n₀ = 1+5 = 6。
sample-fresh : freshN 2 (((2 , 5) , 0) ∷ []) ≡ 6
sample-fresh = refl

-- λ=3 无已用槽：n₀ = 1。
sample-fresh-empty : freshN 3 (((2 , 5) , 0) ∷ []) ≡ 1
sample-fresh-empty = refl

-- 单元素成员的键读出。
mem-singleton-key : ∀ (k : ℕ × ℕ) (a : ℕ) (t : Triple) →
  (k , a) ∈L (t ∷ []) → k ≡ proj₁ t
mem-singleton-key .(proj₁ t) a t here = refl
mem-singleton-key k a t (there ())

2≢3 : suc (suc zero) ≡ suc (suc (suc zero)) → ⊥
2≢3 ()

-- 键不相交 ⟹ 相容（空 confrontation：k 无法两侧同时在场）。
sample-agree : agree (((2 , 0) , 1) ∷ []) (((3 , 1) , 2) ∷ [])
sample-agree k a b h1 h2 =
  ⊥-elim (2≢3 (cong proj₁
    (trans (sym (mem-singleton-key k a (((2 , 0) , 1)) h1))
           (mem-singleton-key k b (((3 , 1) , 2)) h2))))
