-- 第 75 章：传递化：刚性与有秩关系（冯琦 §1.10）——Agda 通道
-- 构造性承载两件套：(1) ∈-归纳法（定理 1.94）的构造性化身 hf-ind——
-- 玫瑰树 HF 上的结构归纳正是"对 ∈ 的归纳"，证明即良基递归本身；
-- (2) 冯诺伊曼数字的传递性（"序数是传递集合"的有限化身，定理 1.95
-- 刚性成立的形状条件）经 hf-ind 风格的归纳全程机器化。
-- 坍缩器与四个现场由 Coq/Julia/Python/Prolog 承载。
module Ch75_collapse where

open import Data.Nat using (ℕ; zero; suc)
open import Data.List using (List; []; _∷_; _++_; [_])
open import Data.Sum using (_⊎_; inj₁; inj₂)
open import Data.Empty using (⊥-elim)
open import Relation.Binary.PropositionalEquality using (_≡_; refl; subst; sym)

-- ---------- HF 世界：彻底有限集合 = 玫瑰树 ----------
data HF : Set where
  hfset : List HF → HF

children : HF → List HF
children (hfset cs) = cs

-- 成员关系（∈ 的列表化）
data _∈l_ (x : HF) : List HF → Set where
  here  : ∀ {xs} → x ∈l (x ∷ xs)
  there : ∀ {y ys} → x ∈l ys → x ∈l (y ∷ ys)

-- 空集无成员（正则性的真空端）
∉[] : ∀ {x} → x ∈l [] → ∀ {P : Set} → P
∉[] ()

-- ---------- 定理 1.94 的构造性化身：HF 上的 ∈-归纳 ----------
-- 冯琦的 ∈-归纳：若 ∀α (∀y∈α Φ(y) → Φ(α)) 则 ∀α Φ(α)。
-- 在 HF 玫瑰树上，这条就是结构归纳本身——良基递归不再需要
-- "极小反例"的经典论证，可达性证据直接长在数据里。
hf-ind : ∀ (P : HF → Set) →
         (∀ h → (∀ c → c ∈l children h → P c) → P h) →
         ∀ h → P h
hf-ind P step h = step h (go h)
  where
  go : ∀ h → ∀ c → c ∈l children h → P c
  go (hfset cs) c m = aux cs c m
    where
    aux : ∀ ds → ∀ c → c ∈l ds → P c
    aux (c' ∷ ds') c here = hf-ind P step c'
    aux (c' ∷ ds') c (there m') = aux ds' c m'

-- ---------- 冯诺伊曼数字 ----------
vn : ℕ → HF
vn zero = hfset []
vn (suc n) = hfset (children (vn n) ++ [ vn n ])

-- ---------- 附加的成员引理 ----------
∈l-++-l : ∀ {x xs ys} → x ∈l xs → x ∈l (xs ++ ys)
∈l-++-l here = here
∈l-++-l (there m) = there (∈l-++-l m)

∈l-++-cases : ∀ {x xs ys} → x ∈l (xs ++ ys) → (x ∈l xs) ⊎ (x ∈l ys)
∈l-++-cases {xs = []} m = inj₂ m
∈l-++-cases {xs = x ∷ xs} here = inj₁ here
∈l-++-cases {xs = x ∷ xs} (there m) with ∈l-++-cases m
... | inj₁ l = inj₁ (there l)
... | inj₂ r = inj₂ r

∈l-single : ∀ {x y} → x ∈l [ y ] → x ≡ y
∈l-single here = refl
∈l-single (there m) = ⊥-elim (∉[] m)

-- ---------- 传递性：序数是传递集合的有限化身 ----------
transitive : HF → Set
transitive h = ∀ x y → x ∈l children y → y ∈l children h → x ∈l children h

-- 空集传递（真空）
trans-vn0 : transitive (vn 0)
trans-vn0 x y m1 m2 = ⊥-elim (∉[] m2)

-- 归纳步：vn (suc n) 的成员 y 或是 vn n 的成员（回落 IH），
-- 或就是 vn n 自己（children 直通）
trans-vn : ∀ n → transitive (vn n) → transitive (vn (suc n))
trans-vn n ih x y m1 m2 with ∈l-++-cases m2
... | inj₁ y-mem = ∈l-++-l (ih x y m1 y-mem)
... | inj₂ y-last = ∈l-++-l (subst (λ t → x ∈l children t) (∈l-single y-last) m1)

-- 主定理：每个冯诺伊曼数字都传递（ℕ 归纳 + hf-ind 的列表体操）
vn-transitive : ∀ n → transitive (vn n)
vn-transitive zero = trans-vn0
vn-transitive (suc n) = trans-vn n (vn-transitive n)

-- ---------- 样例：vn 3 的每个成员都传递 ----------
ex-vn3-mem : ∀ x → x ∈l children (vn 3) → transitive x
ex-vn3-mem x m with ∈l-++-cases m
... | inj₁ l with ∈l-++-cases l
...   | inj₁ m0 = subst transitive (sym (∈l-single m0)) (vn-transitive 0)
...   | inj₂ r1 = subst transitive (sym (∈l-single r1)) (vn-transitive 1)
ex-vn3-mem x m | inj₂ r2 = subst transitive (sym (∈l-single r2)) (vn-transitive 2)
