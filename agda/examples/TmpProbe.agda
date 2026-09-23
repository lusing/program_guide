module TmpProbe where

open import Data.Nat using (ℕ; zero; suc; _+_)
open import Data.Vec using (Vec; []; _∷_)

head″ : ∀ {A : Set} {n} → Vec A (n + 1) → A
head″ (x ∷ xs) = x
