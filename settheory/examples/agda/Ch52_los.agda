-- 第 52 章：混合性质的构造版（钻石代数 2 元反链拼装）

module Ch52_los where

open import Data.Bool using (Bool; true; false; _∧_; _∨_; not)
open import Data.Product using (_×_; _,_; Σ)
open import Relation.Binary.PropositionalEquality using (_≡_; refl)

-- 钻石代数
data Dia : Set where
  d0 du dv d1 : Dia

dmeet : Dia → Dia → Dia
dmeet d0 _ = d0
dmeet _ d0 = d0
dmeet du du = du
dmeet dv dv = dv
dmeet d1 x = x
dmeet x d1 = x
dmeet _ _ = d0

djoin : Dia → Dia → Dia
djoin d1 _ = d1
djoin _ d1 = d1
djoin d0 x = x
djoin x d0 = x
djoin du du = du
djoin dv dv = dv
djoin _ _ = d1

-- 反链判定：u ⊥ v 即 dmeet u v = d0
⊥ᵈ : Dia → Dia → Bool
⊥ᵈ a b with dmeet a b
... | d0 = true
... | _ = false

-- 混合见证选择器（与 Lean 通道同构）
mixb : Dia → Dia → Dia
mixb d0 d0 = d0
mixb du d0 = du
mixb d0 dv = dv
mixb _ _ = d1

-- 主定理：{u, v} 是反链；任何 a_u a_v 有混合 b
--   b 满足 dmeet b du = dmeet a_u du 且 dmeet b dv = dmeet a_v dv
uv-antichain : ⊥ᵈ du dv ≡ true
uv-antichain = refl

mix-du : (a_u : Dia) → dmeet (mixb (dmeet a_u du) (dmeet d1 dv)) du
                ≡ dmeet a_u du
mix-du d0 = refl
mix-du du = refl
mix-du dv = refl
mix-du d1 = refl

mix-dv : (a_v : Dia) → dmeet (mixb (dmeet d1 du) (dmeet a_v dv)) dv
                ≡ dmeet a_v dv
mix-dv d0 = refl
mix-dv du = refl
mix-dv dv = refl
mix-dv d1 = refl

-- 组合形式：任意对的混合存在（16 组合）
mix-exists : (a_u a_v : Dia) →
  Σ Dia (λ b → (dmeet b du ≡ dmeet a_u du) × (dmeet b dv ≡ dmeet a_v dv))
mix-exists a_u a_v =
  ( mixb (dmeet a_u du) (dmeet a_v dv)
  , mix-intro₁ a_u a_v , mix-intro₂ a_u a_v )
  where
   mix-intro₁ : (a_u a_v : Dia) →
     dmeet (mixb (dmeet a_u du) (dmeet a_v dv)) du ≡ dmeet a_u du
   mix-intro₁ d0 d0 = refl
   mix-intro₁ d0 du = refl
   mix-intro₁ d0 dv = refl
   mix-intro₁ d0 d1 = refl
   mix-intro₁ du d0 = refl
   mix-intro₁ du du = refl
   mix-intro₁ du dv = refl
   mix-intro₁ du d1 = refl
   mix-intro₁ dv d0 = refl
   mix-intro₁ dv du = refl
   mix-intro₁ dv dv = refl
   mix-intro₁ dv d1 = refl
   mix-intro₁ d1 d0 = refl
   mix-intro₁ d1 du = refl
   mix-intro₁ d1 dv = refl
   mix-intro₁ d1 d1 = refl
   mix-intro₂ : (a_u a_v : Dia) →
     dmeet (mixb (dmeet a_u du) (dmeet a_v dv)) dv ≡ dmeet a_v dv
   mix-intro₂ d0 d0 = refl
   mix-intro₂ d0 du = refl
   mix-intro₂ d0 dv = refl
   mix-intro₂ d0 d1 = refl
   mix-intro₂ du d0 = refl
   mix-intro₂ du du = refl
   mix-intro₂ du dv = refl
   mix-intro₂ du d1 = refl
   mix-intro₂ dv d0 = refl
   mix-intro₂ dv du = refl
   mix-intro₂ dv dv = refl
   mix-intro₂ dv d1 = refl
   mix-intro₂ d1 d0 = refl
   mix-intro₂ d1 du = refl
   mix-intro₂ d1 dv = refl
   mix-intro₂ d1 d1 = refl

