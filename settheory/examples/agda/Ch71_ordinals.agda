-- 第 71 章：序数与累积层次（冯琦 §1.7）
-- 有限冯诺伊曼序数的内禀三条件：Φ₁ 三择一（定理 1.50 有限截面）、
-- Φ₂ 最小元（定理 1.51 有限版）；RK = 尺寸恒等（命题 1.21）。
module Ch71_ordinals where

open import Data.Empty using (⊥; ⊥-elim)
open import Data.Nat using (ℕ; zero; suc; _<_; _≤_; z≤n; s≤s)
open import Data.Nat.Properties
  using (≤-refl; ≤-reflexive; ≤-trans; <-trans; ≤-antisym; ≤-total; suc-injective; <-cmp; m≤n⇒m≤1+n)
open import Data.Sum using (_⊎_; inj₁; inj₂)
open import Data.Product using (_×_; _,_; ∃)
open import Data.List using (List; []; _∷_)
open import Data.List.Membership.Propositional using (_∈_)
open import Data.List.Relation.Unary.Any using (here; there)
open import Relation.Nullary using (¬_)
open import Relation.Binary.Definitions using (Tri; tri<; tri≈; tri>)
open import Relation.Binary.PropositionalEquality using (_≡_; refl; cong; sym)

-- ---------- 有限冯诺伊曼序数 ----------

data Von : Set where
  v0 : Von
  vs : Von → Von

vsize : Von → ℕ
vsize v0 = zero
vsize (vs n) = suc (vsize n)

-- a ∈ b+1 ⟺ a = b ∨ a ∈ b（书页定义；递归于第二变元）
data _∈ᵛ_ : Von → Von → Set where
  here  : ∀ {b} → b ∈ᵛ vs b          -- 前驱 b 是 b+1 的最大元
  down : ∀ {a b} → a ∈ᵛ b → a ∈ᵛ vs b -- 更深层的成员

-- ---------- Φ₁ 的内核：成员 ⟺ 尺寸更小 ----------

∈ᵛ-size< : ∀ {a b} → a ∈ᵛ b → vsize a < vsize b
∈ᵛ-size< here = s≤s ≤-refl
∈ᵛ-size< (down m) = ≤-trans (∈ᵛ-size< m) (m≤n⇒m≤1+n ≤-refl)

-- n < n（即 suc n ≤ n）不可——一行良基
irr : ∀ {n} → suc n ≤ n → ⊥
irr (s≤s h) = irr h

vEq? : (a b : Von) → (a ≡ b) ⊎ ¬ (a ≡ b)
vEq? v0 v0 = inj₁ refl
vEq? v0 (vs _) = inj₂ (λ ())
vEq? (vs _) v0 = inj₂ (λ ())
vEq? (vs x) (vs y) with vEq? x y
... | inj₁ eq = inj₁ (cong vs eq)
... | inj₂ ne = inj₂ λ { refl → ne refl }

vsize-inj : ∀ a b → vsize a ≡ vsize b → a ≡ b
vsize-inj v0 v0 _ = refl
vsize-inj v0 (vs b) ()
vsize-inj (vs a) v0 ()
vsize-inj (vs a) (vs b) e = cong vs (vsize-inj a b (suc-injective e))

-- ≤ 且 ≠ ⟹ 严格 <
<fst : ∀ {m n : ℕ} → m ≤ n → ¬ (m ≡ n) → suc m ≤ n
<fst {zero} {zero} _ ne = ⊥-elim (ne refl)
<fst {zero} {suc n} _ _ = s≤s z≤n
<fst {suc m} {suc n} (s≤s q) ne = s≤s (<fst q (λ e → ne (cong suc e)))

size<→∈ᵛ : ∀ {a b} → vsize a < vsize b → a ∈ᵛ b
size<→∈ᵛ {b = v0} ()
size<→∈ᵛ {a} {vs b} (s≤s h) with vEq? a b
... | inj₁ eq rewrite eq = here
... | inj₂ ne with ≤-total (vsize a) (vsize b)
...   | inj₁ le = down (size<→∈ᵛ (<fst le (λ e → ne (vsize-inj a b e))))
...   | inj₂ ge = ⊥-elim (ne (vsize-inj a b (≤-antisym h ge)))

∈ᵛ-irrefl : ∀ {a} → ¬ (a ∈ᵛ a)
∈ᵛ-irrefl m = irr (∈ᵛ-size< m)

-- ---------- 定理 1.50（可比较性）的有限截面 ----------

tri : ∀ a b → (a ∈ᵛ b × ¬ (b ∈ᵛ a)) ⊎ (a ≡ b) ⊎ (b ∈ᵛ a × ¬ (a ∈ᵛ b))
tri a b with <-cmp (vsize a) (vsize b)
... | tri< lt _ _ = inj₁ (size<→∈ᵛ lt , λ m → irr (<-trans lt (∈ᵛ-size< m)))
... | tri≈ _ eq _ = inj₂ (inj₁ (vsize-inj a b eq))
... | tri> _ _ gt = inj₂ (inj₂ (size<→∈ᵛ gt , λ m → irr (<-trans (∈ᵛ-size< m) gt)))

-- ---------- Φ₂（定理 1.51 的有限版）：非空列表的 ∈-最小元 ----------

record Pick (l : List Von) : Set where
  field
    elem     : Von
    elem-in  : elem ∈ l
    size-min : ∀ b → b ∈ l → vsize elem ≤ vsize b
open Pick

pick : (c : Von) (cs : List Von) → Pick (c ∷ cs)
pick c [] = record
  { elem = c ; elem-in = here refl
  ; size-min = λ { b (here px) → ≤-reflexive (cong vsize (sym px)) } }
pick c (d ∷ cs′) with pick d cs′
... | p with ≤-total (vsize c) (vsize (elem p))
...   | inj₁ h = record
        { elem = c ; elem-in = here refl
        ; size-min = λ { b (here px) → ≤-reflexive (cong vsize (sym px))
                       ; b (there b∈) → ≤-trans h (size-min p b b∈) } }
...   | inj₂ h = record
        { elem = elem p ; elem-in = there (elem-in p)
        ; size-min = λ { b (here px) → ≤-trans h (≤-reflexive (cong vsize (sym px)))
                       ; b (there b∈) → size-min p b b∈ } }

-- 尺寸最小者即 ∈-最小：b ∈ a 给 vsize b < vsize a ≤ vsize b——自相矛盾
minimal : (c : Von) (cs : List Von) →
  ∃ λ a → (a ∈ c ∷ cs) × (∀ b → b ∈ c ∷ cs → ¬ (b ∈ᵛ a))
minimal c cs with pick c cs
... | p = elem p , elem-in p , goal
  where
  goal : ∀ b → b ∈ c ∷ cs → ¬ (b ∈ᵛ elem p)
  goal b b∈ m = irr (≤-trans (∈ᵛ-size< m) (size-min p b b∈))

-- ---------- RK：秩 = 尺寸恒等（命题 1.21 的有限版） ----------

-- 冯诺伊曼数字在秩轴上排成斜率为 1 的直线：RK(v0) = 0、RK(n+1) = RK(n)+1
rk-zero : vsize v0 ≡ zero
rk-zero = refl

rk-succ : ∀ n → vsize (vs n) ≡ suc (vsize n)
rk-succ n = refl

rk-three : vsize (vs (vs (vs v0))) ≡ 3
rk-three = refl
