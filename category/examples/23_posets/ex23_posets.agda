------------------------------------------------------------------------
-- ex23 —— 完备预序与剩余映射（Simmons 6.1/6.2）
-- 菱形上 f(x) := x ∧ a 保全部 sup，g := 公式查表，
-- 伴随定律十六格穷尽。
------------------------------------------------------------------------

open import Data.Bool using (Bool; true; false)
open import Relation.Binary.PropositionalEquality using (_≡_; refl)

data Diam : Set where
  dBot dL dR dTop : Diam        -- ⊥ < a=dL, b=dR < ⊤

leD : Diam → Diam → Bool
leD dBot _ = true
leD dL dL = true
leD dL dTop = true
leD dR dR = true
leD dR dTop = true
leD dTop dTop = true
leD _ _ = false

supD : Diam → Diam → Diam
supD dBot z = z
supD z dBot = z
supD dL dL = dL
supD dR dR = dR
supD dTop _ = dTop
supD _ dTop = dTop
supD _ _ = dTop              -- a 与 b 的 sup 是 ⊤

infD : Diam → Diam → Diam
infD dTop z = z
infD z dTop = z
infD dBot _ = dBot
infD _ dBot = dBot
infD dL dL = dL
infD dR dR = dR
infD _ _ = dBot              -- a 与 b 的 inf 是 ⊥

fMeet : Diam → Diam
fMeet x = infD x dL

-- g(y) := ⋁{x | f x ≤ y}，按公式查表算出
gAdj : Diam → Diam
gAdj dBot = dR
gAdj dL = dTop
gAdj dR = dR
gAdj dTop = dTop

-- 伴随定律：f(x) ≤ y ⟺ x ≤ g(y) —— 十六格穷尽
adjunction-law : ∀ x y → leD (fMeet x) y ≡ leD x (gAdj y)
adjunction-law dBot dBot = refl
adjunction-law dBot dL = refl
adjunction-law dBot dR = refl
adjunction-law dBot dTop = refl
adjunction-law dL dBot = refl
adjunction-law dL dL = refl
adjunction-law dL dR = refl
adjunction-law dL dTop = refl
adjunction-law dR dBot = refl
adjunction-law dR dL = refl
adjunction-law dR dR = refl
adjunction-law dR dTop = refl
adjunction-law dTop dBot = refl
adjunction-law dTop dL = refl
adjunction-law dTop dR = refl
adjunction-law dTop dTop = refl

-- 保二元 sup
fMeet-join : ∀ x y → fMeet (supD x y) ≡ supD (fMeet x) (fMeet y)
fMeet-join dBot dBot = refl
fMeet-join dBot dL = refl
fMeet-join dBot dR = refl
fMeet-join dBot dTop = refl
fMeet-join dL dBot = refl
fMeet-join dL dL = refl
fMeet-join dL dR = refl
fMeet-join dL dTop = refl
fMeet-join dR dBot = refl
fMeet-join dR dL = refl
fMeet-join dR dR = refl
fMeet-join dR dTop = refl
fMeet-join dTop dBot = refl
fMeet-join dTop dL = refl
fMeet-join dTop dR = refl
fMeet-join dTop dTop = refl
