-- ex05 —— Hilbert 系统 L 与演绎定理（Agda 版）
module ex05_hilbert where

open import Data.Nat using (ℕ)
open import Data.List using (List; []; _∷_; _++_)
open import Data.Sum using (_⊎_; inj₁; inj₂)
open import Data.Product using (Σ; _×_; _,_; ∃)
open import Relation.Binary.PropositionalEquality using (_≡_; refl; cong)

-- ---------- 语言 ----------

data HForm : Set where
  hvar : ℕ → HForm
  _⟶_ : HForm → HForm → HForm
  ¬h_ : HForm → HForm

-- ---------- Mendelson 三公理模式 ----------

IsAxiom : HForm → Set
IsAxiom A =
  (∃ λ p → ∃ λ q → A ≡ (p ⟶ (q ⟶ p)))
  ⊎ (∃ λ p → ∃ λ q → ∃ λ r →
       A ≡ ((p ⟶ (q ⟶ r)) ⟶ ((p ⟶ q) ⟶ (p ⟶ r))))
  ⊎ (∃ λ p → ∃ λ q → A ≡ (((¬h q) ⟶ (¬h p)) ⟶ (p ⟶ q)))

-- ---------- 自带成员关系（先于推导关系定义） ----------

infix 4 _∈_

data _∈_ {A : Set} (x : A) : List A → Set where
  here  : ∀ {xs} → x ∈ x ∷ xs
  there : ∀ {y xs} → x ∈ xs → x ∈ y ∷ xs

-- ---------- 推导关系 ----------

infix 3 _⊢_

data _⊢_ (Γ : List HForm) : HForm → Set where
  hyp : ∀ {A} → A ∈ Γ → Γ ⊢ A
  ax  : ∀ {A} → IsAxiom A → Γ ⊢ A
  mp  : ∀ {P A} → Γ ⊢ (P ⟶ A) → Γ ⊢ P → Γ ⊢ A

-- ---------- 基础设施 ----------

K-weaken : ∀ {Γ A B} → Γ ⊢ A → Γ ⊢ (B ⟶ A)
K-weaken {Γ} {A} {B} h = mp (ax (inj₁ (A , B , refl))) h

identity : ∀ {Γ p} → Γ ⊢ (p ⟶ p)
identity {Γ} {p} =
  let
    s1 = ax (inj₁ (p , (p ⟶ p) , refl))                    -- p → ((p→p) → p)
    s2 = ax (inj₂ (inj₁ (p , (p ⟶ p) , p , refl)))         -- A2 实例
    s3 = mp s2 s1                                           -- (p → (p→p)) → (p→p)
    s4 = ax (inj₁ (p , p , refl))                           -- p → (p→p)
  in mp s3 s4

-- ---------- 演绎定理：对推导归纳 ----------

deduction : ∀ {Γ p q} → (p ∷ Γ) ⊢ q → Γ ⊢ (p ⟶ q)
deduction (hyp here) = identity
deduction (hyp (there ∈Γ)) = K-weaken (hyp ∈Γ)
deduction (ax isA) = K-weaken (ax isA)
deduction {Γ} {p} (mp {r} {A} h₁ h₂) =
  let
    s2 = ax (inj₂ (inj₁ (p , r , A , refl)))               -- (p → (r → A)) → ((p → r) → (p → A))
  in mp (mp s2 (deduction h₁)) (deduction h₂)

-- 坑位速记（Agda 侧）：
-- - 推导关系用 _⊢_ 中缀；演绎定理对推导直接模式匹配（归纳即消解）；
-- - hyp here 分支的「q = p」情形由 here 构造子自动统一——不用写等式分析；
-- - 隐式 {Γ p} 必须在子句里具名绑定（deduction {Γ} {p} (mp …)）——
--   子句体看不见未绑定的函数级隐式（category 教程同款坑）。
