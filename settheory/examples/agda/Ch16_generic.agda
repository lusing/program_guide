-- 第 16 章 泛型扩张：Cohen 偏序的前缀判定

module Ch16_generic where

open import Data.Bool using (Bool; true; false; _∧_; not)
open import Data.Nat using (ℕ; zero; suc)
open import Data.List using (List; []; _∷_)
open import Relation.Binary.PropositionalEquality using (_≡_; refl; cong)

-- 前缀判定（Cohen 偏序的序关系）
prefixb : List Bool → List Bool → Bool
prefixb [] _ = true
prefixb (_ ∷ _) [] = false
prefixb (x ∷ xs) (y ∷ ys) = eqb x y ∧ prefixb xs ys
  where
   eqb : Bool → Bool → Bool
   eqb true true = true
   eqb false false = true
   eqb _ _ = false

-- 塔构造：first_above 线性扫描
first_above : List Bool → List (List Bool) → List Bool
first_above p [] = p
first_above p (q ∷ rest) with prefixb p q
... | true = q
... | false = first_above p rest

-- 泛型塔
tower : List Bool → (ℕ → List (List Bool)) → ℕ → List Bool
tower p₀ D zero = p₀
tower p₀ D (suc n) = first_above (tower p₀ D n) (D (suc n))

-- 前缀自反
prefixb-refl : (p : List Bool) → prefixb p p ≡ true
prefixb-refl [] = refl
prefixb-refl (true ∷ ps) = cong (true ∧_) (prefixb-refl ps)
prefixb-refl (false ∷ ps) = cong (true ∧_) (prefixb-refl ps)
