module Zr1 where
open import Reflection
open import Agda.Builtin.List using (_∷_; [])
open import Agda.Builtin.Nat using (_+_)
open import Agda.Builtin.Unit using (⊤; tt)
open import Agda.Builtin.Equality using (_≡_; refl)
reflTerm : Term
reflTerm = con (quote refl) []
macro
  quietRefl : Term → TC ⊤
  quietRefl hole = unify reflTerm hole
safeRefl : Term → TC ⊤
safeRefl hole = catchTC (unify reflTerm hole)
  (do
    g ← inferType hole
    typeError (strErr "safeRefl: 这个目标不是 refl 可证的: " ∷ termErr g ∷ []))
bad1 : 2 ≡ 3
bad1 = quietRefl
