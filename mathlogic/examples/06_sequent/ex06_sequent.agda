-- ex06 —— 矢列演算 G（Agda 版）
module ex06_sequent where

open import Data.Nat using (ℕ)
open import Data.List using (List; []; _∷_)

-- ---------- 语言 ----------

data SForm : Set where
  svar : ℕ → SForm
  _∧s_ : SForm → SForm → SForm
  _∨s_ : SForm → SForm → SForm
  _⟶s_ : SForm → SForm → SForm
  ¬s_ : SForm → SForm

-- ---------- 自带成员关系 ----------

infix 4 _∈_

data _∈_ {A : Set} (x : A) : List A → Set where
  here  : ∀ {xs} → x ∈ x ∷ xs
  there : ∀ {y xs} → x ∈ xs → x ∈ y ∷ xs

-- ---------- 演算 G：Γ ⊦ Δ ----------

infix 3 _⊦_

data _⊦_ : List SForm → List SForm → Set where
  gAx   : ∀ {Γ Δ} (p : SForm) → p ∈ Γ → p ∈ Δ → Γ ⊦ Δ
  gLNeg : ∀ {Γ Δ} (p : SForm) → Γ ⊦ (p ∷ Δ) → ((¬s p) ∷ Γ) ⊦ Δ
  gRNeg : ∀ {Γ Δ} (p : SForm) → (p ∷ Γ) ⊦ Δ → Γ ⊦ ((¬s p) ∷ Δ)
  gLAnd : ∀ {Γ Δ} (a b : SForm) → (a ∷ b ∷ Γ) ⊦ Δ → ((a ∧s b) ∷ Γ) ⊦ Δ
  gRAnd : ∀ {Γ Δ} (a b : SForm) → Γ ⊦ (a ∷ Δ) → Γ ⊦ (b ∷ Δ) → Γ ⊦ ((a ∧s b) ∷ Δ)
  gLOr  : ∀ {Γ Δ} (a b : SForm) → (a ∷ Γ) ⊦ Δ → (b ∷ Γ) ⊦ Δ → ((a ∨s b) ∷ Γ) ⊦ Δ
  gROr  : ∀ {Γ Δ} (a b : SForm) → Γ ⊦ (a ∷ b ∷ Δ) → Γ ⊦ ((a ∨s b) ∷ Δ)
  gLImp : ∀ {Γ Δ} (a b : SForm) → Γ ⊦ (a ∷ Δ) → (b ∷ Γ) ⊦ Δ → ((a ⟶s b) ∷ Γ) ⊦ Δ
  gRImp : ∀ {Γ Δ} (a b : SForm) → (a ∷ Γ) ⊦ (b ∷ Δ) → Γ ⊦ ((a ⟶s b) ∷ Δ)

-- ---------- 现场：G 天生经典 ----------

g-¬∨p : (n : ℕ) → [] ⊦ (((¬s (svar n)) ∨s (svar n)) ∷ [])
g-¬∨p n = gROr _ _ (gRNeg _ (gAx _ here here))

g-⟶id : (n : ℕ) → [] ⊦ (((svar n) ⟶s (svar n)) ∷ [])
g-⟶id n = gRImp _ _ (gAx _ here here)

-- 坑位速记（Agda 侧）：
-- - 构造子的显式公式参数用 _ 占位——目标形状反推；
-- - 矢列记号 _⊦_ 双侧都是表——规则在表头引入，
--   所以「经典 LEM」先长成 ¬p ∨ p 的形状。
