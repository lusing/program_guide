-- 第 99 章：有限紧性（命题骨架，构造性）。
module Ch99_strongcompact where

open import Data.Bool using (Bool; true; false; not; _∨_; _∧_)
open import Data.List using (List; []; _∷_)
open import Data.Nat using (ℕ; zero; suc)
open import Relation.Binary.PropositionalEquality using (_≡_; refl)

-- 自建布尔列表组合子（本版 stdlib 的 Data.List.any/all 已被
-- 重定向为 Nat 特定版本，绕开之以保证 Bool 上的可约简性）。
anyb : {A : Set} → (A → Bool) → List A → Bool
anyb p []       = false
anyb p (x ∷ xs) = p x ∨ anyb p xs

allb : {A : Set} → (A → Bool) → List A → Bool
allb p []       = true
allb p (x ∷ xs) = p x ∧ allb p xs

-- 自建列表成员关系（与第 98 章同款）。
data _∈L_ {A : Set} : A → List A → Set where
  here  : ∀ {x : A} {xs} → x ∈L (x ∷ xs)
  there : ∀ {y x : A} {xs} → x ∈L xs → x ∈L (y ∷ xs)

-- 命题变元上的文字与子句。
data Literal : Set where
  pos : ℕ → Literal
  neg : ℕ → Literal

Clause : Set
Clause = List Literal

Val : Set
Val = ℕ → Bool

lit-sat : Val → Literal → Bool
lit-sat v (pos p) = v p
lit-sat v (neg p) = not (v p)

clause-sat : Val → Clause → Bool
clause-sat v c = anyb (lit-sat v) c

theory-sat : Val → List Clause → Bool
theory-sat v T = allb (clause-sat v) T

∧-true-left : ∀ a b → (a ∧ b) ≡ true → a ≡ true
∧-true-left false b H = H
∧-true-left true  b H = refl

∧-true-right : ∀ a b → (a ∧ b) ≡ true → b ≡ true
∧-true-right false b ()
∧-true-right true  b H = H

-- 引理：allb f xs ≡ true 且 c ∈L xs ⟹ f c ≡ true。
allb-∈L : ∀ {A} (f : A → Bool) xs c → c ∈L xs →
  allb f xs ≡ true → f c ≡ true
allb-∈L f (x ∷ xs) c here      H = ∧-true-left (f x) (allb f xs) H
allb-∈L f (x ∷ xs) c (there p) H =
  allb-∈L f xs c p (∧-true-right (f x) (allb f xs) H)

-- 可满足理论的一切子理论可满足（有限紧性的骨架方向）。
sat-subset : ∀ v T S →
  (∀ c → c ∈L T → c ∈L S) →
  theory-sat v S ≡ true → theory-sat v T ≡ true
sat-subset v [] S Hincl HS = refl
sat-subset v (c ∷ T) S Hincl HS
  rewrite sat-subset v T S (λ c' c∈T → Hincl c' (there c∈T)) HS
  with clause-sat v c | allb-∈L (clause-sat v) S c (Hincl c here) HS
... | false | cSat = cSat
... | true  | cSat = refl

-- 具体样本：{{p0 ∨ ¬p1}, {p1 ∨ p2}} 在 p0=T,p1=F,p2=T 下可满足。
v0 : Val
v0 zero = true
v0 (suc zero) = false
v0 (suc (suc zero)) = true
v0 _ = false

sample1 : theory-sat v0 ((pos zero ∷ neg (suc zero) ∷ []) ∷ (pos (suc zero) ∷ pos (suc (suc zero)) ∷ []) ∷ []) ≡ true
sample1 = refl

-- 反例样本：{{p0}, {¬p0}} 在任何赋值下不可满足——穷举两赋值。
unsat-pair : ∀ v →
  theory-sat v ((pos zero ∷ []) ∷ (neg zero ∷ []) ∷ []) ≡ false
unsat-pair v with v 0
... | false = refl
... | true = refl
