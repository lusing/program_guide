module Zr3 where
open import Reflection
legacy : Term → TC ⊤
legacy hole = quoteGoal g 1 (unify (quoteTerm refl) hole)
