-- 第 58 章：函数的构造性面貌（Makinson Ch3）
-- 单射谓词、复合保持律、有限选择函数、对合小双射。
module Ch58_functions where

open import Data.Nat using (ℕ; zero; suc; _+_)
open import Data.Nat.Properties using (_≟_)
open import Data.List using (List; []; _∷_)
open import Data.Bool using (Bool; true; false; if_then_else_)
open import Data.Empty using (⊥)
open import Data.Product using (_×_; _,_)
open import Relation.Nullary using (yes; no; ¬_)
open import Relation.Binary.PropositionalEquality using (_≡_; refl; cong)

-- ---------- 单射谓词与复合 ----------

Inj : (ℕ → ℕ) → Set
Inj f = ∀ a b → f a ≡ f b → a ≡ b

-- 后继单射：构造子的注入原理（refl 模式即统一）
suc-inj : Inj suc
suc-inj _ _ refl = refl

-- 双射不动点式的复合：单射∘单射 = 单射
inj-comp : (f g : ℕ → ℕ) → Inj f → Inj g → Inj (λ x → f (g x))
inj-comp f g hf hg a b h = hg a b (hf (g a) (g b) h)

-- 常值函数不单射的见证（0 与 1 同像）
const-not-inj : ¬ (Inj (λ _ → zero))
const-not-inj h = contradiction (h zero (suc zero) refl)
  where contradiction : zero ≡ suc zero → ⊥
        contradiction ()

-- ---------- 选择函数的有限构造性 ----------

-- 对有限族（表的表），取每族首元素——AC 在有限时免费
choice-first : List (List ℕ) → List (ℕ × List ℕ)
choice-first [] = []
choice-first ([] ∷ fam) = choice-first fam
choice-first ((x ∷ s) ∷ fam) = (x , x ∷ s) ∷ choice-first fam

-- ---------- 交的闭项见证（特征函数同构的计算侧） ----------

mem : ℕ → List ℕ → Bool
mem x [] = false
mem x (y ∷ ys) with x ≟ y
... | yes _ = true
... | no  _ = mem x ys

inter : List ℕ → List ℕ → List ℕ
inter [] _ = []
inter (x ∷ xs) ys = if mem x ys then x ∷ inter xs ys else inter xs ys

w1 : mem 2 (inter (1 ∷ 2 ∷ []) (2 ∷ 3 ∷ [])) ≡ true
w1 = refl

w2 : mem 1 (inter (1 ∷ 2 ∷ []) (2 ∷ 3 ∷ [])) ≡ false
w2 = refl

-- ---------- 对合小双射：交换 0 与 1 ----------

swap01 : ℕ → ℕ
swap01 zero = suc zero
swap01 (suc zero) = zero
swap01 n = n

swap-invol : ∀ n → swap01 (swap01 n) ≡ n
swap-invol zero = refl
swap-invol (suc zero) = refl
swap-invol (suc (suc n)) = refl
