-- 第 60 章：计数的构造性面貌（Makinson Ch5）
-- 四式选取的小例枚举 + banana 重排 60 + 帕斯卡行。
module Ch60_counting where

open import Data.Nat using (ℕ; zero; suc; _+_; _*_)
open import Data.Nat.Base using (_≡ᵇ_)
open import Data.List using (List; []; _∷_; length; filter; concat; map)
open import Data.Product using (_×_; _,_; proj₁; proj₂)
open import Data.Bool using (Bool; true; false; if_then_else_; _∧_; not)
open import Relation.Binary.PropositionalEquality using (_≡_; refl)

-- ---------- 五选二：四模式的计数 ----------

leq : ℕ → ℕ → Bool
leq zero _ = true
leq _ zero = false
leq (suc a) (suc b) = leq a b

allPairs5 : List (ℕ × ℕ)
allPairs5 = concat (map (λ a → map (λ b → (a , b)) (0 ∷ 1 ∷ 2 ∷ 3 ∷ 4 ∷ []))
                        (0 ∷ 1 ∷ 2 ∷ 3 ∷ 4 ∷ []))

filterB : (ℕ × ℕ → Bool) → List (ℕ × ℕ) → List (ℕ × ℕ)
filterB f [] = []
filterB f (x ∷ xs) = if f x then x ∷ filterB f xs else filterB f xs

countWith : (ℕ × ℕ → Bool) → ℕ
countWith f = length (filterB f allPairs5)

-- O+R+：25；O+R−（a≠b）：20；O−R+（a≤b）：15；O−R−（a<b）：10
w-total : ℕ
w-total = countWith (λ _ → true)

w-neq : ℕ
w-neq = countWith (λ p → not (Data.Nat.Base._≡ᵇ_ (proj₁ p) (proj₂ p)))

w-le : ℕ
w-le = countWith (λ p → leq (proj₁ p) (proj₂ p))

w-lt : ℕ
w-lt = countWith (λ p → leq (suc (proj₁ p)) (proj₂ p))

cert-total : w-total ≡ 25
cert-total = refl

cert-neq : w-neq ≡ 20
cert-neq = refl

cert-le : w-le ≡ 15
cert-le = refl

cert-lt : w-lt ≡ 10
cert-lt = refl

-- ---------- banana 重排 = 60（多重集的字谜生成计数） ----------

data _∈'_ : ℕ → List ℕ → Set where
  here' : ∀ {x ys} → x ∈' (x ∷ ys)
  there' : ∀ {x y ys} → x ∈' ys → x ∈' (y ∷ ys)

remove1 : ℕ → List ℕ → List ℕ
remove1 x [] = []
remove1 x (y ∷ ys) with Data.Nat.Base._≡ᵇ_ x y
... | true = ys
... | false = y ∷ remove1 x ys

anyB : ℕ → List ℕ → Bool
anyB x [] = false
anyB x (y ∷ ys) with Data.Nat.Base._≡ᵇ_ x y
... | true = true
... | false = anyB x ys

dedup : List ℕ → List ℕ
dedup [] = []
dedup (x ∷ xs) with anyB x (dedup xs)
... | true = dedup xs
... | false = x ∷ dedup xs

fuel-anagrams : ℕ → List ℕ → List (List ℕ)
fuel-anagrams zero _ = [] ∷ []
fuel-anagrams (suc f) l with l
... | [] = [] ∷ []
... | _ = concat (map (λ x → map (λ t → x ∷ t) (fuel-anagrams f (remove1 x l)))
                     (dedup l))

banana-count : ℕ
banana-count = length (fuel-anagrams 6 (1 ∷ 3 ∷ 3 ∷ 3 ∷ 2 ∷ 2 ∷ []))

cert-banana : banana-count ≡ 60
cert-banana = refl
