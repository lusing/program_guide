-- 第 02 章 集合论：Agda 通道。
-- 把集合实现为“布尔特征函数” X → Bool：成员关系是可判定的，
-- 于是并/交/补与德摩根律全部可以构造性证明，无需函数外延公理
-- （逐点相等即可），也无需经典逻辑排中律。

module Ch02_sets where

open import Data.Bool using (Bool; true; false; not; _∨_; _∧_; T)
open import Relation.Binary.PropositionalEquality using (_≡_; refl; cong)
open import Data.Nat using (ℕ; _≤?_; s≤s; z≤n)
open import Data.List using (List; []; _∷_; foldr; filter; _++_)
open import Data.Unit using (tt)
open import Data.Empty using (⊥-elim)
open import Function using (_∘_)
open import Relation.Nullary using (Dec; yes; no)

-- 特征函数集合：A x = true 当且仅当 x ∈ A。
Setᶠ : Set → Set
Setᶠ X = X → Bool

infix 4 _∈ᶠ_
_∈ᶠ_ : ∀ {X} → X → Setᶠ X → Bool
x ∈ᶠ A = A x

-- 空集：任何元素的成员判定都是 false。
∅ᶠ : ∀ {X} → Setᶠ X
∅ᶠ _ = false

-- 全集：任何元素都属于它。
univᶠ : ∀ {X} → Setᶠ X
univᶠ _ = true

-- 并、交、补逐点定义。
infixr 5 _∪ᶠ_
_∪ᶠ_ : ∀ {X} → Setᶠ X → Setᶠ X → Setᶠ X
(A ∪ᶠ B) x = A x ∨ B x

infixr 6 _∩ᶠ_
_∩ᶠ_ : ∀ {X} → Setᶠ X → Setᶠ X → Setᶠ X
(A ∩ᶠ B) x = A x ∧ B x

∁ᶠ : ∀ {X} → Setᶠ X → Setᶠ X
∁ᶠ A x = not (A x)

-- Bool 上的德摩根律（可判定世界的完整四条，模式匹配即真值表）。
deMorgan∨ : ∀ a b → not (a ∨ b) ≡ not a ∧ not b
deMorgan∨ false _ = refl
deMorgan∨ true  _ = refl

deMorgan∧ : ∀ a b → not (a ∧ b) ≡ not a ∨ not b
deMorgan∧ false _ = refl
deMorgan∧ true  _ = refl

-- 集合德摩根律（逐点版）：不需要函数外延公理，因为我们只在
-- 每个固定点 x 上比较两个 Bool 值。
compl-union : ∀ {X} (A B : Setᶠ X) (x : X) →
              ∁ᶠ (A ∪ᶠ B) x ≡ (∁ᶠ A ∩ᶠ ∁ᶠ B) x
compl-union A B x = deMorgan∨ (A x) (B x)

compl-inter : ∀ {X} (A B : Setᶠ X) (x : X) →
              ∁ᶠ (A ∩ᶠ B) x ≡ (∁ᶠ A ∪ᶠ ∁ᶠ B) x
compl-inter A B x = deMorgan∧ (A x) (B x)

-- 子集关系命题化：A ⊆ B 当且仅当对任意 x，A 命中则 B 命中。
infix 4 _⊆ᶠ_
_⊆ᶠ_ : ∀ {X} → Setᶠ X → Setᶠ X → Set
A ⊆ᶠ B = ∀ x → T (A x) → T (B x)

-- 定理 3.7：空集是任何集合的子集。T false 即 ⊥，空模式 () 闭合。
empty-subset : ∀ {X} (A : Setᶠ X) → ∅ᶠ ⊆ᶠ A
empty-subset A x ()

-- 定理 3.12 性质 1 的左半边：A ⊆ A ∪ B。
-- 对 A x 分情形：true 时目标化归为 ⊤；false 时假设是 T false = ⊥。
subset-union-left : ∀ {X} (A B : Setᶠ X) → A ⊆ᶠ (A ∪ᶠ B)
subset-union-left A B x hx with A x
... | true  = tt
... | false = ⊥-elim hx

-- 自然数区间 [a, b] 的特征函数：用可判定比较 _≤?_ 实现。
interval : ℕ → ℕ → Setᶠ ℕ
interval a b x with a ≤? x | x ≤? b
... | yes _ | yes _ = true
... | _     | _     = false

-- 有限索引族：List 上的 foldr 就是有限并。
finiteUnion : ∀ {X} → List (Setᶠ X) → Setᶠ X
finiteUnion []       = ∅ᶠ
finiteUnion (A ∷ As) = A ∪ᶠ finiteUnion As

-- 有限族的德摩根律：补(有限并) = 逐补的有限交（用 foldr 表达）。
finiteDeMorgan : ∀ {X} (As : List (Setᶠ X)) (x : X) →
  not (finiteUnion As x) ≡
  foldr (λ A acc → not (A x) ∧ acc) true As
finiteDeMorgan []       x = refl
finiteDeMorgan (A ∷ As) x
  rewrite deMorgan∨ (A x) (finiteUnion As x)
        | finiteDeMorgan As x = refl
