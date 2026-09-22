{-# OPTIONS --cubical --safe #-}
module Zc8 where
open import Agda.Builtin.Bool using (Bool; true; false)
open import Agda.Builtin.Cubical.Glue
  using (primGlue; _≃_; isEquiv; equiv-proof; equivFun; pathToEquiv)
open import Agda.Builtin.Cubical.Path using (_≡_)
open import Agda.Builtin.Nat using (Nat; _+_; suc)
open import Agda.Builtin.Sigma using (Σ; _,_; fst; snd)
open import Agda.Builtin.Unit using (⊤; tt)
open import Agda.Primitive using (Level; Set)
open import Agda.Primitive.Cubical
  renaming (primINeg to ~_; primTransp to transp; primIMax to _∨_)

------------------------------------------------------------------------
-- 1. 等式即路径：refl 是常值路径
------------------------------------------------------------------------

refl : ∀ {ℓ} {A : Set ℓ} {x : A} → x ≡ x
refl {x = x} = λ i → x

-- 路径在端点处的行为：p i0 = p 的起点，p i1 = p 的终点。
nat-path : 2 + 3 ≡ 5
nat-path = refl

endpoint-check : nat-path i0 ≡ 5
endpoint-check = refl

------------------------------------------------------------------------
-- 2. 路径运算：对称、函子性、搬运
------------------------------------------------------------------------

sym : ∀ {ℓ} {A : Set ℓ} {x y : A} → x ≡ y → y ≡ x
sym p = λ i → p (~ i)

ap : ∀ {ℓ} {A B : Set ℓ} (f : A → B) {x y : A} → x ≡ y → f x ≡ f y
ap f p = λ i → f (p i)

transport : ∀ {ℓ} {A B : Set ℓ} → A ≡ B → A → B
transport p x = transp (λ i → p i) i0 x

-- 因为这里的 nat-path 就是常值路径，以下三个"路径间等式"都能用 refl 判定成立。
sym-sym-check : sym (sym nat-path) ≡ nat-path
sym-sym-check = refl

ap-check : ap suc nat-path ≡ refl {x = 6}
ap-check = refl

------------------------------------------------------------------------
-- 3. 单值性公理（univalence）：用 primGlue 把等价变成路径
------------------------------------------------------------------------

ua : ∀ {ℓ} {A B : Set ℓ} → A ≃ B → A ≡ B
ua {A = A} {B = B} e i =
  primGlue B
    (λ { (i = i0) → A ; (i = i1) → B })
    (λ { (i = i0) → e ; (i = i1) → pathToEquiv (λ i → B) })

------------------------------------------------------------------------
-- 4. 完整实例：Bool ≃ (⊤ × Bool)，于是 Bool ≡ (⊤ × Bool)
------------------------------------------------------------------------

B̂ : Set
B̂ = Σ ⊤ λ _ → Bool

swap : Bool → B̂
swap b = tt , b

-- 验证 swap 是等价：每个 y : B̂ 的"纤维"是单点的。
swapIsEquiv : isEquiv swap
swapIsEquiv .equiv-proof y .fst = snd y , refl
swapIsEquiv .equiv-proof y .snd (z , p) i =
  snd (p (~ i)) , λ j → p (j ∨ ~ i)

-- 完整证明：类型等价 → 类型路径。
boolPath : Bool ≡ B̂
boolPath = ua (swap , swapIsEquiv)

-- 沿 boolPath 搬运 true，结果就是字面上的 (tt , true)：判定成立，refl 可证。
transport-check : transport boolPath true ≡ (tt , true)
transport-check = refl

-- 等价函数的正向也用 refl 判定。
swap-fun : equivFun (swap , swapIsEquiv) false ≡ (tt , false)
swap-fun = refl
