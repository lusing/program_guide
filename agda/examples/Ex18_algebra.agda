------------------------------------------------------------------------
-- 第 18 章配套示例：关系代数与抽象代数
------------------------------------------------------------------------

module Ex18_algebra where

open import Level using (Level; 0ℓ; _⊔_)
open import Relation.Binary.PropositionalEquality
  using (_≡_; refl; sym; trans; cong; cong₂)
import Relation.Binary.PropositionalEquality as Eq
open import Relation.Binary
  using (Setoid; Preorder; Poset; IsEquivalence; IsPreorder; IsPartialOrder)
open import Algebra using (Monoid; Semigroup)
open import Algebra.Structures using (IsMagma; IsSemigroup; IsMonoid)

open import Data.Nat.Base
  using (ℕ; zero; suc; _+_; _*_; _^_; _≤_; z≤n; s≤s; +-0-rawMonoid; *-1-rawMonoid)
open import Data.Nat.Properties
  using (≤-poset; ≤-preorder; ≤-refl; ≤-reflexive; +-assoc; +-monoˡ-≤; +-monoʳ-≤; m≤n+m; +-0-monoid; *-1-monoid; ^-distribˡ-+-*)
open import Data.List.Base
  using (List; _∷_; []; _++_; map; length; ++-[]-rawMonoid)
open import Data.List.Properties
  using (++-assoc; ++-identityˡ; ++-identityʳ; ++-monoid; length-++)
open import Data.Bool.Base using (Bool; true; false)
open import Data.Product using (_×_; _,_)
open import Function.Base using (id; _∘_)

------------------------------------------------------------------------
-- 18.1 关系的三层包装：Setoid ⊂ Preorder ⊂ Poset
------------------------------------------------------------------------

-- Setoid：集合 + 一个等价关系（记录字段：Carrier / _≈_ / isEquivalence）
Bool≡-setoid : Setoid 0ℓ 0ℓ
Bool≡-setoid = record
  { Carrier       = Bool
  ; _≈_           = _≡_
  ; isEquivalence = record { refl = refl; sym = sym; trans = trans }
  }

-- 现成的 (ℕ, ≤) 偏序：Data.Nat.Properties 直接给 Poset
-- 记录套记录：Poset ⊇ isPartialOrder ⊇ isPreorder ⊇ isEquivalence
module ≤P = Poset ≤-poset

_ : ≤P.Carrier ≡ ℕ
_ = refl

-- 字段即引理：reflexive/trans/antisym 都是 Poset 记录的公开字段
mono-refl : (n : ℕ) → n ≤ n
mono-refl n = ≤P.refl   -- refl 的参数是隐式的（Reflexive _≤_）

antisym-demo : ∀ {m n} → m ≤ n → n ≤ m → m ≡ n
antisym-demo = ≤P.antisym

------------------------------------------------------------------------
-- 18.2 推理框架：begin / ≡⟨⟩ / ≤⟨⟩ / ∎（Relation.Binary.Reasoning）
------------------------------------------------------------------------

import Relation.Binary.Reasoning.PartialOrder

module _ where
  open Relation.Binary.Reasoning.PartialOrder ≤-poset

  ≤-chain : 2 ≤ 4
  ≤-chain = begin
    1 + 1  ≡⟨ refl ⟩
    2      ≤⟨ s≤s (s≤s z≤n) ⟩
    4      ∎

  -- 混合等式与不等式的多步链（常数写在加法左侧，保证可约）
  mono-demo : ∀ {m n} → m ≤ n → 1 + m ≤ 2 + n
  mono-demo {m} {n} m≤n = begin
    1 + m  ≤⟨ +-monoʳ-≤ 1 m≤n ⟩
    1 + n  ≤⟨ m≤n+m (1 + n) 1 ⟩
    2 + n  ∎

------------------------------------------------------------------------
-- 18.3 抽象代数：Monoid 是一个 record（Carrier / _≈_ / _∙_ / ε / isMonoid）
------------------------------------------------------------------------

n+0≡n : ∀ n → n + zero ≡ n
n+0≡n zero    = refl
n+0≡n (suc n) = cong suc (n+0≡n n)

ℕ+-monoid : Monoid 0ℓ 0ℓ
ℕ+-monoid = record
  { Carrier  = ℕ
  ; _≈_      = _≡_
  ; _∙_      = _+_
  ; ε        = zero
  ; isMonoid = record
      { isSemigroup = record
          { isMagma = record
              { isEquivalence = Eq.isEquivalence
              ; ∙-cong        = cong₂ _+_
              }
          ; assoc = +-assoc
          }
      ; identity = (λ _ → refl) , n+0≡n   -- 左单位元 refl；右单位元要归纳
      }
  }

-- 记录字段就是「定理的仓库」：投影即引理
∙ʸ : ℕ → ℕ → ℕ
∙ʸ = Monoid._∙_ ℕ+-monoid

εʸ : ℕ
εʸ = Monoid.ε ℕ+-monoid

_ : ∙ʸ 3 4 ≡ 7
_ = refl

_ : εʸ ≡ 0
_ = refl

-- 字段是嵌套 record：assoc/identityˡ/identityʳ 一路 public 投影出来
assocℕ : ∀ x y z → (x + y) + z ≡ x + (y + z)
assocℕ = Monoid.assoc ℕ+-monoid

idʳℕ : ∀ x → x + εʸ ≡ x
idʳℕ = Monoid.identityʳ ℕ+-monoid

-- stdlib 早就给 (ℕ, +, 0) 做过同一份包装，行为一致：
_ : Monoid._∙_ +-0-monoid 3 4 ≡ 7
_ = refl

-- List ℕ 的 append monoid：手工再来一份，再用 stdlib 的 ++-monoid 对账
Listℕ++-monoid : Monoid 0ℓ 0ℓ
Listℕ++-monoid = record
  { Carrier  = List ℕ
  ; _≈_      = _≡_
  ; _∙_      = _++_
  ; ε        = []
  ; isMonoid = record
      { isSemigroup = record
          { isMagma = record
              { isEquivalence = Eq.isEquivalence
              ; ∙-cong        = cong₂ _++_
              }
          ; assoc = ++-assoc
          }
      ; identity = ++-identityˡ , ++-identityʳ
      }
  }

_ : Monoid._∙_ (++-monoid ℕ) (1 ∷ []) (2 ∷ []) ≡ 1 ∷ 2 ∷ []
_ = refl

-- 单位元一侧 refl、另一侧归纳——和 ℕ 版完全平行，这就是 Monoid 的价值
_ : Monoid.identityʳ Listℕ++-monoid (1 ∷ []) ≡ refl
_ = refl

------------------------------------------------------------------------
-- 18.4 多项式泛化：任何一个 Monoid 上都有 sum（Algebra.Properties.Monoid.Sum）
------------------------------------------------------------------------

import Algebra.Properties.Monoid.Sum as MonoSum
import Data.Vec.Functional as VF

-- sum 的参数是「定长向量」（Data.Vec.Functional），长度在类型里
v₃ : VF.Vector ℕ 3
v₃ = 1 VF.∷ 2 VF.∷ 3 VF.∷ VF.[]

_ : MonoSum.sum ℕ+-monoid v₃ ≡ 6
_ = refl

v₂ : VF.Vector (List ℕ) 2
v₂ = (1 ∷ []) VF.∷ (2 ∷ 3 ∷ []) VF.∷ VF.[]

_ : MonoSum.sum Listℕ++-monoid v₂ ≡ 1 ∷ 2 ∷ 3 ∷ []
_ = refl

------------------------------------------------------------------------
-- 18.5 结构之间：monoid 同态（新版 Algebra.Morphism.Structures）
------------------------------------------------------------------------

-- 同态 = 一个函数 + 保运算（homo）+ 保单位元（ε-homo）。
-- 注意：Data.Nat.Properties 里的 ^-monoid-morphism 用的是 1.5 版起
-- 弃用的 IsMonoidMorphism，触碰会报 deprecation 警告；这里手写新 record。

open import Algebra.Morphism.Structures using (IsMonoidHomomorphism)

-- 2^：把 (ℕ, +, 0) 送进 (ℕ, *, 1)
two-pow-hom : IsMonoidHomomorphism +-0-rawMonoid *-1-rawMonoid (2 ^_)
two-pow-hom = record
  { isMagmaHomomorphism = record
      { isRelHomomorphism = record { cong = cong (2 ^_) }
      ; homo              = ^-distribˡ-+-* 2
      }
  ; ε-homo = refl                        -- 2 ^ 0 ≡ 1 定义成立
  }

module P = IsMonoidHomomorphism two-pow-hom

pow-distrib : ∀ m n → 2 ^ (m + n) ≡ (2 ^ m) * (2 ^ n)
pow-distrib = P.homo

pow-ε : 2 ^ 0 ≡ 1
pow-ε = P.ε-homo

-- length：把 (List ℕ, ++, []) 送进 (ℕ, +, 0)
length-hom : IsMonoidHomomorphism (++-[]-rawMonoid ℕ) +-0-rawMonoid length
length-hom = record
  { isMagmaHomomorphism = record
      { isRelHomomorphism = record { cong = cong length }
      ; homo              = λ xs ys → length-++ xs { ys }
      }
  ; ε-homo = refl
  }

module L = IsMonoidHomomorphism length-hom

++-length-law : ∀ xs ys → length (xs ++ ys) ≡ length xs + length ys
++-length-law = L.homo
