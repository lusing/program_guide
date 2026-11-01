-- 第 116 章：荟萃塔 I——支撑单调与复合（塔序 ≤ 的机制面）、
-- 像与 club 的构造性面（定义 3.10/3.15 的机制核；本体留在正文
-- docs/116-tower1.md）。
module Ch116_tower1 where

open import Data.Nat using (ℕ; zero; suc)
open import Data.Bool using (Bool; true; false; _∧_; _∨_)
open import Data.List using (List; []; _∷_; _++_; foldr)
open import Data.Product using (_×_; _,_)
open import Relation.Binary.PropositionalEquality using (_≡_; refl; cong; sym; trans)
open import Data.Empty using (⊥; ⊥-elim)
open import Data.Sum using (_⊎_; inj₁; inj₂)

-- ── 零、宇宙与子集 ──
Subset : Set
Subset = ℕ → Bool

-- 轮换 g = (012)：构造子形。
gcyc : ℕ → ℕ
gcyc zero = suc zero
gcyc (suc zero) = suc (suc zero)
gcyc (suc (suc n)) = n

-- U 的成员判定。
inU : ℕ → Bool
inU zero = true
inU (suc zero) = true
inU (suc (suc zero)) = true
inU (suc (suc (suc n))) = false

-- 自建相等判定（沿 110-115 章纪律）。
eq? : ℕ → ℕ → Bool
eq? zero zero = true
eq? zero (suc _) = false
eq? (suc _) zero = false
eq? (suc m) (suc n) = eq? m n

-- ── 一、支撑（∪X 的点级化身）与单调（塔序 ≤ 的 (a) 款） ──

Cond : Set
Cond = List Subset

supp : Cond → Subset
supp X b = foldr (λ A r → A b ∨ r) false X

-- ∨ 的结合律（Bool 点级）。
∨-assoc : (a b c : Bool) → (a ∨ b) ∨ c ≡ a ∨ (b ∨ c)
∨-assoc true b c = refl
∨-assoc false b c = refl

-- 支撑的并置：supp (X ++ Y) = supp X ∪ supp Y（点级）。
supp-++ : (X Y : Cond) → ∀ b →
  supp (X ++ Y) b ≡ (supp X b ∨ supp Y b)
supp-++ [] Y b = refl
supp-++ (A ∷ X) Y b =
  trans (cong (λ r → A b ∨ r) (supp-++ X Y b))
        (sym (∨-assoc (A b) (supp X b) (supp Y b)))

-- 复合（传递性的支撑面）：supp Z ⊆ supp Y ⊆ supp X ⟹ supp Z ⊆ supp X。
supp-trans : (X Y Z : Cond) →
  (∀ b → supp Y b ≡ true → supp X b ≡ true) →
  (∀ b → supp Z b ≡ true → supp Y b ≡ true) →
  (∀ b → supp Z b ≡ true → supp X b ≡ true)
supp-trans X Y Z h1 h2 b hz = h1 b (h2 b hz)

-- 单调在并置下的表现：h : supp Y ⊆ supp X ⟹ supp (Y ++ Z) ⊆ supp (X ++ Z)。
∨-elim : ∀ {a b : Bool} → a ∨ b ≡ true → (a ≡ true) ⊎ (b ≡ true)
∨-elim {true} {b} h = inj₁ refl
∨-elim {false} {true} h = inj₂ refl
∨-elim {false} {false} ()

r-∨-true : ∀ a → a ∨ true ≡ true
r-∨-true false = refl
r-∨-true true = refl

supp-++-mono : (X Y Z : Cond) →
  (∀ b → supp Y b ≡ true → supp X b ≡ true) →
  (∀ b → supp (Y ++ Z) b ≡ true → supp (X ++ Z) b ≡ true)
supp-++-mono X Y Z h b hy
  rewrite supp-++ Y Z b | supp-++ X Z b
  with ∨-elim hy
... | inj₁ hyb = trans (cong (λ r → r ∨ supp Z b) (h b hyb)) refl
... | inj₂ hzb rewrite hzb = r-∨-true (supp X b)

-- ── 二、像与 club（一元影子——像只在载体上取） ──

imageN : (ℕ → ℕ) → Subset → Subset
imageN f A b =
  inU b ∧ foldr (λ a r → (inU a ∧ (A a ∧ eq? (f a) b)) ∨ r) false
                (zero ∷ suc zero ∷ suc (suc zero) ∷ [])

clubf : (ℕ → ℕ) → Subset → Set
clubf f A = ∀ b → imageN f A b ≡ true → A b ≡ true

-- ∧ 的左分量提取。
∧-left : ∀ {p q : Bool} → p ∧ q ≡ true → p ≡ true
∧-left {true} {q} h = refl
∧-left {false} {q} ()

-- ∧ 的右分量提取。
∧-right : ∀ {p q : Bool} → p ∧ q ≡ true → q ≡ true
∧-right {true} {q} h = h
∧-right {false} {q} ()

-- ∅ 属于每个 club：像无见证（右分量恒 false）。
clubf-∅ : ∀ f → clubf f (λ _ → false)
clubf-∅ f b h = ⊥-elim (false-elim (∧-right h))
  where
  false-elim : foldr (λ a r → (inU a ∧ (false ∧ eq? (f a) b)) ∨ r) false
                     (zero ∷ suc zero ∷ suc (suc zero) ∷ []) ≡ true → ⊥
  false-elim ()

-- U 属于每个 club：像带载体守卫（左分量即所求）。
clubf-U : ∀ f → clubf f inU
clubf-U f b h = ∧-left h
