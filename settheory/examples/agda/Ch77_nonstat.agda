-- 第 77 章：滤子、非荟萃集理想与广义无界闭子集（冯琦 §2.3）——Agda 通道
-- 对角线交/并德摩根对偶的构造性证明：memΔ 沿 i 归纳（0 处平凡真，suc i 处
-- 要求 C i (suc i) 与递归），mem∇ 对偶地用 ⊎。两个方向都是显式函数，不需
-- 排中律。再给尾集族 C_k(i)=(k≤i) 在 i=3 处的具体计算例（类型检查即计算）。
module Ch77_nonstat where

open import Data.Bool using (Bool; true; false; not)
open import Data.Empty using (⊥)
open import Data.Unit using (⊤; tt)
open import Data.Sum using (_⊎_; inj₁; inj₂)
open import Data.Product using (_×_; _,_)
open import Data.Nat using (ℕ; zero; suc; _≤ᵇ_)
open import Relation.Binary.PropositionalEquality using (_≡_; refl; sym; subst)

-- 对角线交成员资格（递归谓词）。
memΔ : (ℕ → ℕ → Bool) → ℕ → Set
memΔ C zero = ⊤
memΔ C (suc i) = (C i (suc i) ≡ true) × memΔ C i

-- 对角线并成员资格（对偶，用 ⊎ 与 ⊥）。
mem∇ : (ℕ → ℕ → Bool) → ℕ → Set
mem∇ X zero = ⊥
mem∇ X (suc i) = (X i (suc i) ≡ true) ⊎ mem∇ X i

-- 补集：逐位取反。
¬∘ : (ℕ → ℕ → Bool) → ℕ → ℕ → Bool
¬∘ C j i = not (C j i)

-- 非成员资格 = 成员资格推出矛盾。
notΔ : (ℕ → ℕ → Bool) → ℕ → Set
notΔ C i = memΔ C i → ⊥

true≢false : true ≡ false → ⊥
true≢false ()

-- b=true 与 not b=true 冲突：把 q 沿 p 搬运得 false≡true。
not-true : ∀ {b : Bool} → b ≡ true → not b ≡ true → ⊥
not-true p q = true≢false (sym (subst (λ x → not x ≡ true) p q))

-- 德摩根正向：i∈ΔC 与 i∈∇(κ∖C) 不能同时成立。
demorgan₁ : ∀ C i → memΔ C i → mem∇ (¬∘ C) i → ⊥
demorgan₁ C zero _ ()
demorgan₁ C (suc i) (p , ps) (inj₁ q) = not-true p q
demorgan₁ C (suc i) (p , ps) (inj₂ r) = demorgan₁ C i ps r

-- 德摩根反向：i∉ΔC 则 i∈∇(κ∖C)。构造性地按布尔值分类，不需排中律。
demorgan₂ : ∀ C i → notΔ C i → mem∇ (¬∘ C) i
demorgan₂ C zero n = n tt
demorgan₂ C (suc i) n with C i (suc i)
... | true = inj₂ (demorgan₂ C i (λ ps → n (refl , ps)))
... | false = inj₁ refl

-- 具体计算例：尾集族 C_k(i)=(k≤i)。对角线交在 i=3 处逐位为真：
-- 2≤3、1≤2、0≤1，故 memΔ tailC 3 = (refl,(refl,(refl,tt)))。
tailC : ℕ → ℕ → Bool
tailC k i = k ≤ᵇ i

memΔ-tailC-3 : memΔ tailC 3
memΔ-tailC-3 = refl , (refl , (refl , tt))
