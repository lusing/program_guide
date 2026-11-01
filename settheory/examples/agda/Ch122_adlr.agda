module Ch122_adlr where

open import Data.Bool using (Bool; false; true; not; _∧_; _∨_; if_then_else_)
open import Data.Nat using (ℕ; zero; suc; _+_; _∸_; _*_; _/_; _%_; _^_; _≡ᵇ_)
open import Data.List using (List; []; _∷_; map; concatMap; length)
open import Data.Product using (_×_; _,_)
open import Relation.Binary.PropositionalEquality using (_≡_; refl)

-- 第 122 章：有限 AD 影子；不代表无限空间中的非确定集。

b2n : Bool → ℕ
b2n b = if b then 1 else 0

i-wins : (ℕ → Bool) → Bool → Bool → Bool → Bool
i-wins f a0 z0 z1 =
  (f (b2n a0 + 4 * b2n z0) ∧ f (b2n a0 + 4 * b2n z0 + 8)) ∧
  (f (b2n a0 + 2 + 4 * b2n z1) ∧ f (b2n a0 + 2 + 4 * b2n z1 + 8))

ii-wins : (ℕ → Bool) → Bool → Bool → Bool → Bool → Bool → Bool → Bool
ii-wins f b00 b01 q000 q001 q100 q101 =
  not (f (2 * b2n b00 + 8 * b2n q000)) ∧
  not (f (2 * b2n b00 + 4 + 8 * b2n q001)) ∧
  not (f (1 + 2 * b2n b01 + 8 * b2n q100)) ∧
  not (f (1 + 2 * b2n b01 + 4 + 8 * b2n q101))

bools : List Bool
bools = false ∷ true ∷ []

triples : List (Bool × Bool × Bool)
triples = concatMap (λ a0 → concatMap (λ z0 →
  map (λ z1 → (a0 , z0 , z1)) bools) bools) bools

sextuples : List (Bool × Bool × Bool × Bool × Bool × Bool)
sextuples = concatMap (λ b00 → concatMap (λ b01 →
  concatMap (λ q000 → concatMap (λ q001 → concatMap (λ q100 →
  map (λ q101 → (b00 , b01 , q000 , q001 , q100 , q101)) bools)
  bools) bools) bools) bools) bools

anyb : {A : Set} → (A → Bool) → List A → Bool
anyb p [] = false
anyb p (x ∷ xs) = p x ∨ anyb p xs

allb : {A : Set} → (A → Bool) → List A → Bool
allb p [] = true
allb p (x ∷ xs) = p x ∧ allb p xs

i-any : (ℕ → Bool) → Bool
i-any f = anyb (λ where (a0 , z0 , z1) → i-wins f a0 z0 z1) triples

ii-any : (ℕ → Bool) → Bool
ii-any f = anyb (λ where
  (b00 , b01 , q000 , q001 , q100 , q101) →
    ii-wins f b00 b01 q000 q001 q100 q101) sextuples

even-pay : ℕ → Bool
even-pay x = (x % 2) ≡ᵇ 0

never-pay : ℕ → Bool
never-pay _ = false

-- 代表收益表上双方胜负恰好相反；张三证书是 (0,0,0)。
even-i-wins : i-wins even-pay false false false ≡ true
even-i-wins = refl

even-i-any : i-any even-pay ≡ true
even-i-any = refl

even-ii-any : ii-any even-pay ≡ false
even-ii-any = refl

never-i-any : i-any never-pay ≡ false
never-i-any = refl

never-ii-any : ii-any never-pay ≡ true
never-ii-any = refl

-- 尾等价代表：保留高两位，清除低两位；在全部 16 个终局上检查。
tail-rep : ℕ → ℕ
tail-rep x = (x / 4) * 4

upto : ℕ → List ℕ
upto zero = []
upto (suc n) = zero ∷ map suc (upto n)

terminal16 : List ℕ
terminal16 = upto 16

tailrep-idempotent-all :
  map (λ x → tail-rep (tail-rep x)) terminal16 ≡ map tail-rep terminal16
tailrep-idempotent-all = refl

tailrep-same-class-all :
  map (λ x → tail-rep x / 4) terminal16 ≡ map (λ x → x / 4) terminal16
tailrep-same-class-all = refl

tail-payoff : ℕ → Bool
tail-payoff x = not ((x % 4) ≡ᵇ 1)

filterb : {A : Set} → (A → Bool) → List A → List A
filterb p [] = []
filterb p (x ∷ xs) = if p x then x ∷ filterb p xs else filterb p xs

tailset-size-12 : length (filterb tail-payoff terminal16) ≡ 12
tailset-size-12 = refl

-- 完美树：某长度 4-d 柱的全部 2^d 个叶点属于 A。
has-perfect : (ℕ → Bool) → ℕ → Bool
has-perfect f d =
  anyb (λ s → allb (λ t → f (s * (2 ^ d) + t)) (upto (2 ^ d)))
    (upto (2 ^ (4 ∸ d)))

tight-set : ℕ → ℕ → Bool
tight-set d x = not (anyb (λ k → x ≡ᵇ k * (2 ^ d)) terminal16)

tight-depth-1 :
  (has-perfect (tight-set 1) 1 ≡ false) ×
  (length (filterb (tight-set 1) terminal16) ≡ 8)
tight-depth-1 = refl , refl

tight-depth-2 :
  (has-perfect (tight-set 2) 2 ≡ false) ×
  (length (filterb (tight-set 2) terminal16) ≡ 12)
tight-depth-2 = refl , refl

tight-depth-3 :
  (has-perfect (tight-set 3) 3 ≡ false) ×
  (length (filterb (tight-set 3) terminal16) ≡ 14)
tight-depth-3 = refl , refl

tight-depth-4 :
  (has-perfect (tight-set 4) 4 ≡ false) ×
  (length (filterb (tight-set 4) terminal16) ≡ 15)
tight-depth-4 = refl , refl

-- 定义参数编码：序数参数 p 与实数参数 a 配对为纯位串下标。
enc-param : ℕ → ℕ → ℕ
enc-param p a = p * 16 + a

dec-param : ℕ → ℕ × ℕ
dec-param c = (c / 16 , c % 16)

param-roundtrip-example : dec-param (enc-param 5 11) ≡ (5 , 11)
param-roundtrip-example = refl

param-injective-example : enc-param 5 11 ≡ 91
param-injective-example = refl
