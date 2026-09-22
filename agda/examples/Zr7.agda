module Zr7 where
open import Reflection
open import Agda.Builtin.Unit using (⊤; tt)
x : Nat
x = unquote (quoteTC 42)
open import Agda.Builtin.Nat using (Nat)
