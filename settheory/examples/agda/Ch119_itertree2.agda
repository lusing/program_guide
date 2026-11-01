module Ch119_itertree2 where

open import Data.Nat using (ℕ; zero; suc; _<ᵇ_; _≡ᵇ_)
open import Data.Bool using (if_then_else_; _∧_)
open import Data.List using (List; []; _∷_; map)
open import Relation.Binary.PropositionalEquality using (_≡_; refl)

-- 有限数字策略；Agda 只验证六步燃料证书，不验证一般可迭代性。
data Result : Set where done out-of-fuel illegal : Result

c-strategy : ℕ → ℕ
c-strategy zero = 0
c-strategy (suc k) = k

bad-strategy : ℕ → ℕ
bad-strategy _ = 6

legal-target : ℕ → ℕ → Data.Bool.Bool
legal-target k p = (p <ᵇ suc k) ∧ (p ≡ᵇ c-strategy k)

-- 递归参数是 fuel；每次合法移动都严格消耗一份燃料。
run-with : (ℕ → ℕ) → ℕ → ℕ → Result
run-with strategy zero k = if 5 <ᵇ k then done else out-of-fuel
run-with strategy (suc fuel) k =
  if 5 <ᵇ k then done
  else if legal-target k (strategy k)
       then run-with strategy fuel (suc k)
       else illegal

scheduled : List ℕ
scheduled = map c-strategy (0 ∷ 1 ∷ 2 ∷ 3 ∷ 4 ∷ 5 ∷ [])

scheduled-is-alternating-chain : scheduled ≡ (0 ∷ 0 ∷ 1 ∷ 2 ∷ 3 ∷ 4 ∷ [])
scheduled-is-alternating-chain = refl

comparison-terminates : run-with c-strategy 6 0 ≡ done
comparison-terminates = refl

short-budget-is-detected : run-with c-strategy 5 0 ≡ out-of-fuel
short-budget-is-detected = refl

bad-target-is-detected : run-with bad-strategy 6 0 ≡ illegal
bad-target-is-detected = refl
