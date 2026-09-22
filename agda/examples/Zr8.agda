module Zr8 where
open import Reflection
open import Agda.Builtin.Unit using (⊤; tt)
legacy : Term → TC ⊤
legacy hole = quoteGoal g 1 (unify (quoteTerm refl) hole)
