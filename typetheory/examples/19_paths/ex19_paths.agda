----------------------------------------------------------------
-- 19 恒等类型的同伦解读 —— Agda 侧
-- Agda 的 _≡_ 与 mini-HoTT 的 paths 同构（Type 层！不是 Prop）。
-- 模式匹配 refl = J；群律每条一两行
----------------------------------------------------------------

open import Function using (_∘_)
open import Data.Nat using (ℕ; zero; suc; _+_)
open import Relation.Binary.PropositionalEquality
  using (_≡_; refl; sym; trans; cong; subst; module ≡-Reasoning)

-- ---- 群律（镜像 Coq 版四条） ----

·-identityʳ : ∀ {A : Set} {x y : A} (p : x ≡ y) → trans p refl ≡ p
·-identityʳ refl = refl

·-inverseʳ : ∀ {A : Set} {x y : A} (p : x ≡ y) → trans p (sym p) ≡ refl
·-inverseʳ refl = refl

·-inverseˡ : ∀ {A : Set} {x y : A} (p : x ≡ y) → trans (sym p) p ≡ refl
·-inverseˡ refl = refl

sym-involutive : ∀ {A : Set} {x y : A} (p : x ≡ y) → sym (sym p) ≡ p
sym-involutive refl = refl

-- ---- ap（= cong）的函子律 ----

ap-· : ∀ {A B : Set} (f : A → B) {x y z : A}
  (p : x ≡ y) (q : y ≡ z) → cong f (trans p q) ≡ trans (cong f p) (cong f q)
ap-· f refl refl = refl

ap-compose : ∀ {A B C : Set} (g : B → C) (f : A → B) {x y : A} (p : x ≡ y)
  → cong (g ∘ f) p ≡ cong g (cong f p)

ap-compose g f refl = refl

-- ---- transport（= subst）的组合律 ----

transport-· : ∀ {A : Set} (P : A → Set) {x y z : A}
  (p : x ≡ y) (q : y ≡ z) (u : P x)
  → subst P (trans p q) u ≡ subst P q (subst P p u)
transport-· P refl refl u = refl

-- ---- 与 Coq 版的对照 ----
-- Agda 的 _≡_ 在 Set（≈ Type）层：高维结构【有地方放】；
-- Coq 的 eq 在 Prop 层——高维同伦需要自造 paths（ex19_paths.v）。
-- 这是 19 章正文「住在哪层」的活对照。

-- 2D 动作：ap10
ap10 : ∀ {A B : Set} {f g : A → B} → f ≡ g → ∀ a → f a ≡ g a
ap10 refl _ = refl

-- 数值搬运（0 + n 折叠的一侧才能纯 refl）
numeric-subst : ∀ n → subst (λ m → 0 + m ≡ m) {x = n} refl refl ≡ refl
numeric-subst n = refl
