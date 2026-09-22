module Tmp12u where

open import Relation.Nullary using (¬_)
open import Data.Empty using (⊥)

-- 试图构造性写出 ¬¬A → A：洞填不出来
¬¬-elim′ : ∀ {A : Set} → ¬ ¬ A → A
¬¬-elim′ ¬¬a = _
