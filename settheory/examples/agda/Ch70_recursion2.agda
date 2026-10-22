-- 第 70 章：第二递归定义定理与彻底有限集合（冯琦 §1.5-1.6）
-- HF 归纳类型（V_ω 的构造性化身）；尺寸严格下降引理；
-- 非空列表的 ∈-极小元（定理 1.44(3) 的构造性证明：尺寸最小者即极小）。
module Ch70_recursion2 where

open import Data.Empty using (⊥; ⊥-elim)
open import Data.List using (List; []; _∷_; [_]; _++_)
open import Data.List.Membership.Propositional using (_∈_)
open import Data.List.Relation.Unary.Any using (here; there)
open import Data.Nat using (ℕ; zero; suc; _<_; _≤_; _+_; z≤n; s≤s)
open import Data.Nat.Properties
  using (≤-refl; ≤-trans; ≤-pred; ≤-total; m≤m+n; m≤n+m; <-trans)
open import Data.Product using (∃; _,_; _×_)
open import Data.Sum using (inj₁; inj₂)
open import Relation.Nullary using (¬_)
open import Relation.Binary.PropositionalEquality using (_≡_; refl)

-- ---------- V_ω 的归纳化身（定理 1.49 的三算子） ----------

data HF : Set where
  node : (children : List HF) → HF

hf-empty : HF
hf-empty = node []

hf-singleton : HF → HF
hf-singleton a = node [ a ]

-- 书页 84 递归式：f(n+1) = f(r) ∪ {f(i)}——拼接即可
hf-union : HF → HF → HF
hf-union (node cs) b = node (cs ++ [ b ])

-- Prop 级成员：不需要可判相等
hf-in : HF → HF → Set
hf-in a (node cs) = a ∈ cs

-- ---------- 尺寸：∈-下降的引擎（引理 1.8 式） ----------

mutual
  size : HF → ℕ
  size (node cs) = suc (sum-size cs)

  sum-size : List HF → ℕ
  sum-size [] = zero
  sum-size (c ∷ rest) = size c + sum-size rest

size-child-< : ∀ {cs y} → y ∈ cs → size y < size (node cs)
size-child-< (here refl) = s≤s (m≤m+n _ _)
size-child-< (there p) = ≤-trans (size-child-< p) (s≤s (m≤n+m _ _))

not-suc≤self : ∀ n → ¬ (suc n ≤ n)
not-suc≤self zero ()
not-suc≤self (suc n) h = not-suc≤self n (≤-pred h)

-- ---------- 定理 1.44(3)：非空列表的 ∈-极小元 ----------

-- 携带尺寸最小性的选元
record Pick (l : List HF) : Set where
  constructor mk
  field
    elem     : HF
    elem-in  : elem ∈ l
    size-min : ∀ b → b ∈ l → size elem ≤ size b

pick : (c : HF) (cs : List HF) → Pick (c ∷ cs)
pick c [] = record
  { elem = c ; elem-in = here refl
  ; size-min = λ { b (here refl) → ≤-refl ; b (there ()) } }
pick c (d ∷ cs′) with pick d cs′
... | p with ≤-total (size c) (size (Pick.elem p))
...   | inj₁ h = record
        { elem = c ; elem-in = here refl
        ; size-min = λ { b (here refl) → ≤-refl
                       ; b (there b∈) → ≤-trans h (Pick.size-min p b b∈) } }
...   | inj₂ h = record
        { elem = Pick.elem p ; elem-in = there (Pick.elem-in p)
        ; size-min = λ { b (here refl) → h
                       ; b (there b∈) → Pick.size-min p b b∈ } }

-- 尺寸最小者即 ∈-极小：b ∈ 列表且 b ∈ᴴ a 给出
-- size b < size a ≤ size b——自相矛盾
-- where 看不见 with 的抽象：helper 顶层参数化
-- hf-in 在投影位置卡住不归约：按目标集合分派的顶层引理
hf-in-size-< : ∀ {a b} → hf-in b a → size b < size a
hf-in-size-< {node cs} b∈c = size-child-< b∈c

minimal-goal : ∀ {l} (p : Pick l) → ∀ b → b ∈ l → ¬ hf-in b (Pick.elem p)
minimal-goal p b b∈ b∈ᴴ =
  not-suc≤self (size b)
    (≤-trans (hf-in-size-< b∈ᴴ) (Pick.size-min p b b∈))

minimal : (c : HF) (cs : List HF) →
  ∃ λ a → (a ∈ c ∷ cs) × (∀ b → b ∈ c ∷ cs → ¬ hf-in b a)
minimal c cs with pick c cs
... | p = Pick.elem p , Pick.elem-in p , minimal-goal p
