-- ex12 —— Curry–Howard 与析取性质（Agda 版）
-- 完整 STLC+case 的类型化判断见 Coq 通道；本文件给同构骨架
-- （lookup/闭环境/值分类）与 DP 的模式匹配内核。
module ex12_ch where

open import Data.Empty using (⊥)
open import Data.Nat using (ℕ; zero; suc)
open import Data.List using (List; []; _∷_)
open import Data.Sum using (_⊎_; inj₁; inj₂)
open import Data.Product using (_×_; _,_; Σ; ∃)
open import Relation.Nullary using (¬_)
open import Relation.Binary.PropositionalEquality using (_≡_; refl)

-- ---------- 类型与项 ----------

data Ty : Set where
  base : ℕ → Ty
  _⇒_  : Ty → Ty → Ty
  _∨t_ : Ty → Ty → Ty

data Tm : Set where
  var  : ℕ → Tm
  lam  : Ty → Tm → Tm
  app  : Tm → Tm → Tm
  inl  : Ty → Tm → Tm
  inr  : Ty → Tm → Tm

-- ---------- 环境 lookup ----------

data Lookup : List Ty → ℕ → Ty → Set where
  here : ∀ {T Γ} → Lookup (T ∷ Γ) zero T
  there : ∀ {T Γ x T'} → Lookup Γ x T → Lookup (T' ∷ Γ) (suc x) T

-- 空环境无 lookup：闭项的 var 不可类型化
lookup-[] : ∀ {x T} → ¬ (Lookup [] x T)
lookup-[] ()

-- ---------- 类型化 ----------

infix 3 _⊢_∶_

data _⊢_∶_ (Γ : List Ty) : Tm → Ty → Set where
  tvar : ∀ {x T} → Lookup Γ x T → Γ ⊢ var x ∶ T
  tlam : ∀ {T body T₂} →
         (T ∷ Γ) ⊢ body ∶ T₂ → Γ ⊢ lam T body ∶ (T ⇒ T₂)
  tapp : ∀ {t₁ t₂ T₁ T₂} →
         Γ ⊢ t₁ ∶ (T₁ ⇒ T₂) → Γ ⊢ t₂ ∶ T₁ → Γ ⊢ app t₁ t₂ ∶ T₂
  tinl : ∀ {t T₁ T₂} →
         Γ ⊢ t ∶ T₁ → Γ ⊢ inl T₂ t ∶ (T₁ ∨t T₂)
  tinr : ∀ {t T₁ T₂} →
         Γ ⊢ t ∶ T₂ → Γ ⊢ inr T₁ t ∶ (T₁ ∨t T₂)

-- ---------- 值 ----------

data Value : Tm → Set where
  v-lam : ∀ {T body} → Value (lam T body)
  v-inl : ∀ {T t} → Value (inl T t)
  v-inr : ∀ {T t} → Value (inr T t)

-- ---------- 旗舰：析取性质 ----------

-- 闭的值证明，若类型是 ∨，必单侧且携带子证明
dp : ∀ {t T₁ T₂} → Value t → [] ⊢ t ∶ (T₁ ∨t T₂) →
     (Σ Tm (λ t' → t ≡ inl T₂ t' × ([] ⊢ t' ∶ T₁)))
     ⊎ (Σ Tm (λ t' → t ≡ inr T₁ t' × ([] ⊢ t' ∶ T₂)))
dp v-lam ()
dp (v-inl {T} {t'}) (tinl ht) = inj₁ (t' , refl , ht)
dp (v-inr {T} {t'}) (tinr ht) = inj₂ (t' , refl , ht)

-- 闭值函数必是 λ
canonical-⇒ : ∀ {t T₁ T₂} → Value t → [] ⊢ t ∶ (T₁ ⇒ T₂) →
              Σ Ty (λ T' → Σ Tm (λ body → t ≡ lam T' body))
canonical-⇒ (v-lam {T} {body}) (tlam _) = T , body , refl
canonical-⇒ v-inl ()
canonical-⇒ v-inr ()

-- 坑位速记（Agda 侧）：
-- - v-lam () 对空模式（lam 不可能类型化为 ∨/⇒ 的错位构造子）
--   一击必杀——值分类的模式匹配本身就是 inversion；
-- - Lookup 自带（Data.List.Membership 的化身）；lookup-[] 由
--   空模式直接得——「闭项无自由变元」的类型化表述。