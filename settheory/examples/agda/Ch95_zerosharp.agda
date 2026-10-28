-- 第 95 章：有限不可辨别元的封闭律与配对比较引擎（构造性）。
module Ch95_zerosharp where

open import Data.Bool using (Bool; true; false; not; _∨_; if_then_else_)
open import Data.List using (List; []; _∷_; map)
open import Data.Product using (_×_; _,_)
open import Data.Nat using (ℕ; zero; suc; _+_; _≡ᵇ_; _<ᵇ_)
open import Relation.Binary.PropositionalEquality
  using (_≡_; refl; trans; sym)

-- 递增检查：构造性布尔判定。
inc : List ℕ → Bool
inc [] = true
inc (x ∷ l) = inc-step x l
  where
  inc-step : ℕ → List ℕ → Bool
  inc-step x [] = true
  inc-step x (y ∷ r) = if x <ᵇ y then inc-step y r else false

inb : ℕ → List ℕ → Bool
inb x [] = false
inb x (y ∷ ys) = (x ≡ᵇ y) ∨ inb x ys

sub : List ℕ → List ℕ → Set
sub t s = ∀ x → inb x t ≡ true → inb x s ≡ true

agreeing : (List ℕ → Bool) → List ℕ → Set
agreeing f s =
  ∀ t u → inc t ≡ true → inc u ≡ true →
    sub t s → sub u s → f t ≡ f u

indisc : (List ℕ → Bool) → List ℕ → Set
indisc f s = inc s ≡ true × agreeing f s

-- 封闭律：不可辨别集的递增子集仍不可辨别。
sub-closure : ∀ f s t → indisc f s → inc t ≡ true → sub t s → indisc f t
sub-closure f s t (hsorted , hagree) hinc hsub =
  hinc , λ u v hu hv h1 h2 →
    hagree u v hu hv (λ x hx → hsub x (h1 x hx)) (λ x hx → hsub x (h2 x hx))

-- 配对比较引擎（引理 1.15 的核心等式）：t1、t2 各与公共高块 t3
-- 同色，则 t1 与 t2 同色。「取更高的第三块」是无限部分，此处只留内核。
cmp-engine : (g : List ℕ → Bool) (t1 t2 t3 : List ℕ) →
  g t1 ≡ g t3 → g t2 ≡ g t3 → g t1 ≡ g t2
cmp-engine g t1 t2 t3 e1 e2 = trans e1 (sym e2)

-- 具体样本：和的奇偶染色下 {0,2,4} 的全部递增二元组取值一致。
even : ℕ → Bool
even zero = true
even (suc n) = not (even n)

g2 : List ℕ → Bool
g2 (x ∷ y ∷ []) = even (x + y)
g2 _ = true

sample-agree-02 : g2 (0 ∷ 2 ∷ []) ≡ true
sample-agree-02 = refl

sample-agree-24 : g2 (2 ∷ 4 ∷ []) ≡ true
sample-agree-24 = refl

sample-agree-04 : g2 (0 ∷ 4 ∷ []) ≡ true
sample-agree-04 = refl

sample-counter : g2 (1 ∷ 2 ∷ []) ≡ false
sample-counter = refl

-- 平移不变样本：σ = +2 保持偶点上的取值。
shift-same :
  g2 (map (λ x → 2 + x) (0 ∷ 2 ∷ [])) ≡ g2 (0 ∷ 2 ∷ [])
shift-same = refl
