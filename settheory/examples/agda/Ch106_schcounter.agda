-- 第 106 章：有限 SCH 账簿、最小失败归约与交织引理影子。
module Ch106_schcounter where

open import Data.Nat using (ℕ; zero; suc; _+_; _≤_; z≤n; s≤s)
open import Data.Nat.Properties
  using (≤-refl; ≤-trans; m≤n+m; m≤m+n; +-assoc; +-comm)
open import Data.List using (List; []; _∷_; length; _++_)
open import Data.Product using (_×_; _,_; ∃-syntax)
open import Data.Unit using (⊤; tt)
open import Data.Empty using (⊥)
open import Relation.Binary.PropositionalEquality
  using (_≡_; refl; cong; subst; sym)
open import Relation.Nullary using (¬_)

-- ── 一、账簿与 GMW 形态 ──

gchPoint : ℕ → Set
gchPoint b = b ≡ 0

jumpPoint : ℕ → Set
jumpPoint b = b ≡ 1

gch≠jump : ∀ {b} → gchPoint b → ¬ jumpPoint b
gch≠jump {zero} refl ()

-- 初始段全 GCH。
data AllGCH : List ℕ → Set where
  ag-nil  : AllGCH []
  ag-cons : ∀ {t} → AllGCH t → AllGCH (0 ∷ t)

-- GMW 账簿：初始段全 GCH + 末位跳档。
data GMW : List ℕ → Set where
  gmw-top : jumpPoint 1 → GMW (1 ∷ [])
  gmw-pre : ∀ {t} → GMW t → GMW (0 ∷ t)

-- 长度账：GMW 账非空（账顶总在）。
gmw-length-pos : ∀ {B} → GMW B → 1 ≤ length B
gmw-length-pos (gmw-top _) = s≤s z≤n
gmw-length-pos (gmw-pre _) = s≤s z≤n

-- 最小失败归约：GMW 账 = 全 GCH 前缀 + 跳档末位（分解唯一形态）。
gmw-decompose : ∀ {B} → GMW B → ∃[ T ] (B ≡ T ++ (1 ∷ [])) × AllGCH T
gmw-decompose (gmw-top refl) = [] , (refl , ag-nil)
gmw-decompose (gmw-pre {t} h)
  with gmw-decompose h
... | T , (eq , ag) = (0 ∷ T) , (cong (0 ∷_) eq , ag-cons ag)

-- 前缀逐点全零（非末位点既是 GCH 点又非跳档点）。
all-zero-prefix : List ℕ → Set
all-zero-prefix [] = ⊤
all-zero-prefix (zero ∷ t) = all-zero-prefix t
all-zero-prefix (suc _ ∷ _) = ⊥

gmw-prefix-zero : ∀ {B} → GMW B →
  ∃[ T ] (B ≡ T ++ (1 ∷ [])) × all-zero-prefix T
gmw-prefix-zero (gmw-top refl) = [] , (refl , tt)
gmw-prefix-zero (gmw-pre h)
  with gmw-prefix-zero h
... | T , (eq , az) = (0 ∷ T) , (cong (0 ∷_) eq , az)

-- ── 二、交织引理（引理 2.20）影子 ──

ShiftsAbove : (ℕ → ℕ) → (ℕ → ℕ) → Set
ShiftsAbove a b = ∃[ k ] (∀ n → k ≤ n → b n ≤ a (n + k))

+-n0 : ∀ m → m + 0 ≡ m
+-n0 zero = refl
+-n0 (suc m) = cong suc (+-n0 m)

shifts-refl : (a : ℕ → ℕ) → ShiftsAbove a a
shifts-refl a = 0 , (λ n _ → rew n ≤-refl)
  where
  rew : (n : ℕ) → a n ≤ a n → a n ≤ a (n + 0)
  rew n p rewrite +-n0 n = p

shifts-trans : (a b c : ℕ → ℕ) →
  ShiftsAbove a b → ShiftsAbove b c → ShiftsAbove a c
shifts-trans a b c (k₁ , e₁) (k₂ , e₂) =
  k₁ + k₂ , (λ n hn →
    ≤-trans (e₂ n (≤-trans (m≤n+m k₂ k₁) hn))
            (rew n (e₁ (n + k₂)
                        (≤-trans (m≤m+n k₁ k₂)
                                 (≤-trans hn (m≤m+n n k₂))))))
  where
  rew : (n : ℕ) → b (n + k₂) ≤ a (n + k₂ + k₁) → b (n + k₂) ≤ a (n + (k₁ + k₂))
  rew n p rewrite +-assoc n k₂ k₁ | +-comm k₂ k₁ = p

n+0+2≡n+2 : ∀ n → n + 0 + 2 ≡ n + 2
n+0+2≡n+2 n rewrite +-n0 n = refl

-- 样本：快序列支配慢序列（k=0；目标经 n+0+2≡n+2 归约）。
shift-sample : ShiftsAbove (λ n → n + 2) (λ n → n)
shift-sample = 0 , (λ n _ →
  subst (n ≤_) (sym (n+0+2≡n+2 n)) (m≤m+n n 2))

-- 账簿样本。
ledger : List ℕ
ledger = 0 ∷ 0 ∷ 0 ∷ 1 ∷ []

ledger-gmw : GMW ledger
ledger-gmw = gmw-pre (gmw-pre (gmw-pre (gmw-top refl)))
