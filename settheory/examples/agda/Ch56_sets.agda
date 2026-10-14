-- 第 56 章：朴素集合的构造性面貌（Makinson Ch1）
-- 成员级子集关系、交的格律（stdlib ∈-filter⁺/⁻）、幂集的 2^n 计数。
module Ch56_sets where

open import Data.Nat using (ℕ; zero; suc; _+_; _*_; _^_)
open import Data.Nat.Properties using (_≟_; +-identityʳ)
open import Data.List using (List; []; _∷_; _++_; filter; length; map)
open import Data.Bool using (Bool; true; false; not)
open import Data.Empty using (⊥; ⊥-elim)
open import Data.Product using (_×_; _,_; proj₁; proj₂)
open import Relation.Nullary using (yes; no; ¬_)
open import Relation.Nullary.Decidable.Core using (¬?)
open import Relation.Binary.PropositionalEquality
  using (_≡_; refl; sym; trans; cong; cong₂)

-- ---------- 成员与子集 ----------

open import Data.List.Membership.Propositional using (_∈_)
import Data.List.Membership.DecPropositional as DecMem
open module MemNat = DecMem _≟_ using (_∈?_)
open import Data.List.Membership.Propositional.Properties
  using (∈-filter⁺; ∈-filter⁻)

_⊆_ : List ℕ → List ℕ → Set
xs ⊆ ys = ∀ z → z ∈ xs → z ∈ ys

⊆-refl : ∀ xs → xs ⊆ xs
⊆-refl xs z h = h

⊆-trans : ∀ xs ys zs → xs ⊆ ys → ys ⊆ zs → xs ⊆ zs
⊆-trans xs ys zs h1 h2 z hz = h2 z (h1 z hz)

∅-⊆ : ∀ xs → [] ⊆ xs
∅-⊆ xs z ()

-- ---------- 集合运算（Decidable 谓词版 filter） ----------

_∩_ : List ℕ → List ℕ → List ℕ
xs ∩ ys = filter (λ w → w ∈? ys) xs

_−_ : List ℕ → List ℕ → List ℕ
xs − ys = filter (λ w → ¬? (w ∈? ys)) xs

-- ---------- 交的三条格律 ----------

∩-⊆ˡ : ∀ xs ys → (xs ∩ ys) ⊆ xs
∩-⊆ˡ xs ys z h = proj₁ (∈-filter⁻ (λ w → w ∈? ys) {xs = xs} h)

∩-⊆ʳ : ∀ xs ys → (xs ∩ ys) ⊆ ys
∩-⊆ʳ xs ys z h = proj₂ (∈-filter⁻ (λ w → w ∈? ys) {xs = xs} h)

-- 交的交换律：根植于"且"的交换律——两个成员资格在分量间对调
∩-comm : ∀ xs ys → (xs ∩ ys) ⊆ (ys ∩ xs)
∩-comm xs ys z h = ∈-filter⁺ (λ w → w ∈? xs) (proj₂ p) (proj₁ p)
  where
  p : z ∈ xs × z ∈ ys
  p = ∈-filter⁻ (λ w → w ∈? ys) {xs = xs} h

-- 差的两条单向包含（成员级）
−-⊆ : ∀ xs ys → (xs − ys) ⊆ xs
−-⊆ xs ys z h = proj₁ (∈-filter⁻ (λ w → ¬? (w ∈? ys)) {xs = xs} h)

−-∩-∅ : ∀ xs ys → ((xs − ys) ∩ ys) ⊆ []
−-∩-∅ xs ys z h = ⊥-elim (proj₂ q (proj₂ p))
  where
  p : z ∈ filter (λ w → ¬? (w ∈? ys)) xs × z ∈ ys
  p = ∈-filter⁻ (λ w → w ∈? ys) h
  q : z ∈ xs × ¬ (z ∈ ys)
  q = ∈-filter⁻ (λ w → ¬? (w ∈? ys)) (proj₁ p)

-- ---------- 差不交换的具体见证（闭项计算） ----------

memB : ℕ → List ℕ → Bool
memB x [] = false
memB x (y ∷ ys) with x ≟ y
... | yes _ = true
... | no  _ = memB x ys

w1 : memB 1 ((1 ∷ 2 ∷ []) ∩ (2 ∷ 3 ∷ [])) ≡ false
w1 = refl

w2 : memB 1 ((1 ∷ 2 ∷ []) − (2 ∷ 3 ∷ [])) ≡ true
w2 = refl

w3 : memB 1 ((2 ∷ 3 ∷ []) − (1 ∷ 2 ∷ [])) ≡ false
w3 = refl

-- ---------- 幂集 ----------

pow : List ℕ → List (List ℕ)
pow [] = [] ∷ []
pow (x ∷ xs) = pow xs ++ map (x ∷_) (pow xs)

open import Data.List.Properties using (length-++; length-map)

-- builtin _*_ 按 suc-左参数展开：2 * n → n + (n + 0)，再补一个右单位律
double : ∀ n → 2 * n ≡ n + n
double n = cong (n +_) (+-identityʳ n)

pow-len : ∀ xs → length (pow xs) ≡ 2 ^ length xs
pow-len [] = refl
pow-len (x ∷ xs) =
  trans (length-++ (pow xs))
    (trans (cong₂ _+_ (pow-len xs)
              (trans (length-map (x ∷_) (pow xs)) (pow-len xs)))
      (sym (double (2 ^ length xs))))

-- 具体计算：𝒫({1,2,3}) 有 8 个元素
cert-pow3 : length (pow (1 ∷ 2 ∷ 3 ∷ [])) ≡ 8
cert-pow3 = refl
