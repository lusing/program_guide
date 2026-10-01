----------------------------------------------------------------
-- 14 全域与层级 —— Agda 侧：Set ℓ 塔与 Level 代数
----------------------------------------------------------------

open import Level using (Level; _⊔_) renaming (suc to lsuc; zero to lzero)
open import Data.Nat using (ℕ; zero; suc)

-- ---- 塔式上楼 ----
private
  _ : Set
  _ = ℕ                      -- ℕ : Set₀

  _ : Set₁
  _ = Set₀                   -- Set₀ : Set₁

  _ : Set₂
  _ = Set₁                   -- Set₁ : Set₂ —— 永不循环

-- ---- 宇宙多态：Level 显式当家 ----
myId : ∀ {ℓ} {A : Set ℓ} → A → A
myId a = a

private
  _ : ℕ
  _ = myId 3                 -- ℓ = 0 的实例

  _ : ℕ → ℕ
  _ = myId (λ n → n)

-- Set₀ 上的定义也能在 Set₁ 用？——不行！Agda 【无】Cumulativity：
private
  -- _ : Set₁
  -- _ = ℕ                 -- 错：ℕ : Set₀ ≠ Set₁，要显式 lift
  record Lift (ℓ : Level) (A : Set ℓ) : Set (lsuc ℓ) where
    constructor lift
    field lower : A

  _ : Set₁
  _ = Lift lzero ℕ              -- 官方升层器（标准库 Data.Unit 式）

-- ---- 双参数族的层级 = 上确界 ----
Pair : ∀ {a b} → Set a → Set b → Set (a ⊔ b)
Pair A B = A → B            -- 函数类型的层级是两端 ⊔（教学版）

record Prod2 {a b} (A : Set a) (B : Set b) : Set (a ⊔ b) where
  constructor _,_
  field
    pr1 : A
    pr2 : B
open Prod2 public

ex : Prod2 ℕ (Lift lzero ℕ)
ex = 3 , lift 3

_ : ℕ
_ = pr1 ex

-- ---- 「类型 + 居留项」的宇宙账单 ----
record TyAndTerm : Set₁ where
  constructor mkTT
  field A   : Set
        val : A
open TyAndTerm public

natEx : TyAndTerm
natEx = mkTT ℕ 3

_ : ℕ
_ = val natEx






