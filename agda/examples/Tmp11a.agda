module Tmp11a where

open import Data.Nat using (ℕ; zero; suc; _+_)
open import Data.Fin using (Fin)
open import Function using (case_of_; _∘_) -- case 的家在这里
open import Relation.Binary.PropositionalEquality
  using (_≡_; _≢_; refl; sym; trans; cong; subst; J)

-- case_of_ 的家在 Function

-- 1) refl 模式证明 cong
cong-case : ∀ {A B : Set} (f : A → B) {x y : A} → x ≡ y → f x ≡ f y
cong-case f refl = refl

-- 2) case of 版
cong-case₂ : ∀ {A B : Set} (f : A → B) {x y : A} (eq : x ≡ y) → f x ≡ f y
cong-case₂ f eq = case eq of λ { refl → refl }

-- 3) 具体值的 UIP：1 ≡ 1 的唯一证明
uip₁ : (p : 1 ≡ 1) → p ≡ refl
uip₁ refl = refl

-- 4) suc n ≢ n 用 ()
suc≢ : ∀ {n : ℕ} → suc n ≢ n
suc≢ ()

-- 5) rewrite 子句形式
rw₁ : ∀ {x y : ℕ} → x ≡ y → suc x ≡ suc y
rw₁ {x} eq rewrite eq = refl


-- 7) rewrite + 引理
n+0 : ∀ n → n + 0 ≡ n
n+0 zero    = refl
n+0 (suc n) = cong suc (n+0 n)

rw₃ : ∀ n → suc (n + 0) ≡ suc n
rw₃ n rewrite n+0 n = refl

-- 8) 点模式版
dp₁ : ∀ {A : Set} (x y : A) (eq : x ≡ y) → y ≡ x
dp₁ x .x refl = refl

-- 9) J 派生 trans
trans-J : ∀ {A : Set} {x y z : A} → x ≡ y → y ≡ z → x ≡ z
trans-J {x = x} {z = z} p q = J (λ w _ → w ≡ z → x ≡ z) p (λ r → r) q

-- 10) subst 用 Fin 家族
subst-Fin : ∀ {n m : ℕ} → n ≡ m → Fin n → Fin m
subst-Fin refl i = i

subst-use : subst (λ k → k + 0 ≡ k) (sym (n+0 2)) refl ≡ refl
subst-use = refl

-- 11) Leibniz 等式
Leib : ∀ (A : Set) → A → A → Set₁
Leib A x y = (P : A → Set) → P x → P y

≡⇒Leib : ∀ {A : Set} {x y : A} → x ≡ y → Leib A x y
≡⇒Leib eq P = subst P eq

Leib⇒≡ : ∀ {A : Set} {x y : A} → Leib A x y → x ≡ y
Leib⇒≡ {x = x} l = l (λ z → x ≡ z) refl

-- 12) with 版 cong（对照）
cong-with : ∀ {A B : Set} (f : A → B) {x y : A} (eq : x ≡ y) → f x ≡ f y
cong-with f {x} eq with eq
... | refl = refl

-- 13) 自定义等式复制品（模拟 Agda.Builtin.Equality）
data _==_ {A : Set} (x : A) : A → Set where
  refl= : x == x

sym-== : ∀ {A : Set} {x y : A} → x == y → y == x
sym-== refl= = refl=

-- 14) ≢ 直接构造
0≢1 : 0 ≢ 1
0≢1 ()

≢-sym-demo : 1 ≢ 0
≢-sym-demo = 0≢1 ∘ sym
