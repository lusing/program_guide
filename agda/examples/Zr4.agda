module Zr4 where
open import Reflection
open import Agda.Builtin.List using (_∷_; [])
open import Agda.Builtin.Nat using (Nat; _+_)
open import Agda.Builtin.Unit using (⊤; tt)
open Reflection.Clause using (clause)
unquoteDecl four : Nat = do
  declareDef (vArg four) (def (quote Nat) [])
  defineFun four (clause [] [] (quoteTerm (2 + 2)) ∷ [])
