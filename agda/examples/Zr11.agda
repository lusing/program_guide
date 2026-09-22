module Zr11 where
open import Reflection
open import Agda.Builtin.Nat using (Nat)
open import Agda.Builtin.Unit using (⊤; tt)
open import Agda.Builtin.List using (_∷_)
open Reflection.Clause using (clause)
unquoteDef z = defineFun z (clause [] [] (quoteTerm 42) ∷ [])
