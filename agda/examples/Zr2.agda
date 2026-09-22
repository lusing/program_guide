module Zr2 where
open import Reflection
open import Agda.Builtin.List using (_∷_; [])
open import Agda.Builtin.Nat using (_+_)
open import Agda.Builtin.Unit using (⊤; tt)
open import Agda.Builtin.Equality using (_≡_; refl)
reflTerm : Term
reflTerm = con (quote refl) []
macro
  safeRefl : Term → TC ⊤
  safeRefl hole = catchTC (unify reflTerm hole)
    (do
      g ← inferType hole
      typeError (strErr "safeRefl: 这个目标不是 refl 可证的: " ∷ termErr g ∷ []))
bad2 : 2 ≡ 3
bad2 = safeRefl
