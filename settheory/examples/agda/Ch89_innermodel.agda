-- 第 89 章 · 内模型 HOD、L[A] 与 L(ℝ)（冯琦第二卷 §2.2）
-- 两件样品：谓词原子让 U∩M 免参可定义（引理 2.23/2.24 的引擎）；
-- 彻底性对 ∈ 向下传递（引理 2.27(2)）。
module Ch89_innermodel where

open import Data.Nat using (ℕ; zero; suc)
open import Data.Bool using (Bool; true; false; not; _∧_; _∨_)
open import Data.List using (List; []; _∷_)
open import Data.List.Membership.Propositional using (_∈_)
open import Data.Product using (_×_; _,_; ∃)
open import Relation.Binary.PropositionalEquality using (_≡_; refl)
open import Relation.Nullary using (¬_)

-- ---------- 一、相对化公式语言与谓词原子 ----------

data FmA : Set where
  ftt fff : FmA
  feq : ℕ → FmA                -- 自由变元 x = 参数
  fmem : ℕ → FmA               -- x ∈ 参数
  finA : FmA                   -- 谓词原子：x ∈ U
  fneg : FmA → FmA
  fOr : FmA → FmA → FmA

eqb : ℕ → ℕ → Bool
eqb zero zero = true
eqb zero (suc _) = false
eqb (suc _) zero = false
eqb (suc m) (suc n) = eqb m n

satA : (mem : ℕ → ℕ → Bool) (U : ℕ → Bool) → FmA → ℕ → Bool
satA mem U ftt _ = true
satA mem U fff _ = false
satA mem U (feq p) x = eqb x p
satA mem U (fmem p) x = mem x p
satA mem U finA x = U x
satA mem U (fneg φ) x = not (satA mem U φ x)
satA mem U (fOr φ ψ) x = satA mem U φ x ∨ satA mem U ψ x

-- U∩M 由原子公式免参定义——L[U] = L[Ũ]（引理 2.24）的成员层引擎。
UA-definable : ∀ (mem : ℕ → ℕ → Bool) (U : ℕ → Bool) (M : List ℕ) →
  ∃ λ φ → ∀ x → x ∈ M → (satA mem U φ x ≡ true → U x ≡ true)
UA-definable mem U M = finA , λ x _ h → h

-- ---------- 二、彻底性对 ∈ 向下传递（引理 2.27(2)） ----------

open import Data.Empty using (⊥)
open import Relation.Nullary.Negation using (contradiction)

data Reach (mem : ℕ → ℕ → Set) : ℕ → ℕ → Set where
  rhead : ∀ x → Reach mem x x
  rstep : ∀ {x y z} → mem x y → Reach mem y z → Reach mem x z

Hered : (P : ℕ → Set) (mem : ℕ → ℕ → Set) → ℕ → Set
Hered P mem x = ∀ y → Reach mem y x → P y

-- 可达关系的传递性（对第一变元结构递归）。
reach-trans : ∀ {mem : ℕ → ℕ → Set} {u v w : ℕ} →
  Reach mem u v → Reach mem v w → Reach mem u w
reach-trans (rhead x) h2 = h2
reach-trans (rstep hmem hr) h2 = rstep hmem (reach-trans hr h2)

-- 引理 2.27(2)：彻底性对 ∈ 向下传递。
hered-down : ∀ {P : ℕ → Set} {mem : ℕ → ℕ → Set} {x y : ℕ} →
  Hered P mem x → mem y x → Hered P mem y
hered-down hx hxy z hz = hx z (reach-trans hz (rstep hxy (rhead _)))
