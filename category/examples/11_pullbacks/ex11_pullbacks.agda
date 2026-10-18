------------------------------------------------------------------------
-- ex10 —— 等化子与拉回
-- 三书对位：贺伟 2.2/2.4 /《高级范畴论》3.3–3.4 / Simmons 2.6–2.7
--
-- 本章机器内容：泛性质定义 + 旗舰抽象定理「单态射的拉回仍是单态射」。
-- TyCat 具体纤维积在 Coq/Lean 版（Agda 的 Σ 证明分量需要证明
-- 无关性，唯一性证明走 setoid——作为边界记录在文档）。
------------------------------------------------------------------------

open import Level using (Level; _⊔_; 0ℓ) renaming (suc to lsuc)
open import Data.Product using (Σ; _×_; _,_; proj₁; proj₂)
open import Relation.Binary.PropositionalEquality as Eq using (_≡_; refl; cong; trans; sym)
open Eq.≡-Reasoning

------------------------------------------------------------------------

record Category (o ℓ : Level) : Set (lsuc (o ⊔ ℓ)) where
  field
    Obj : Set o
    Hom : Obj → Obj → Set ℓ
    idn : ∀ {a} → Hom a a
    comp : ∀ {a b c} → Hom a b → Hom b c → Hom a c
    idL : ∀ {a b} (f : Hom a b) → comp (idn {a}) f ≡ f
    idR : ∀ {a b} (f : Hom a b) → comp f (idn {b}) ≡ f
    assoc : ∀ {a b c d} (f : Hom a b) (g : Hom b c) (h : Hom c d)
          → comp (comp f g) h ≡ comp f (comp g h)

open Category

------------------------------------------------------------------------
-- 定义

Mono : ∀ {o ℓ} (C : Category o ℓ) (a b : Obj C) → Hom C a b → Set (o ⊔ ℓ)
Mono C a b f = ∀ (c : Obj C) (g h : Hom C c a)
             → comp C g f ≡ comp C h f → g ≡ h

-- 拉回：p1;f = p2;g 的泛方块（存在 + 唯一）
IsPullback : ∀ {o ℓ} (C : Category o ℓ) (a b c p : Obj C)
             (f : Hom C a c) (g : Hom C b c)
             (p1 : Hom C p a) (p2 : Hom C p b) → Set (o ⊔ ℓ)
IsPullback C a b c p f g p1 p2 =
  (comp C p1 f ≡ comp C p2 g)
  × (∀ (x : Obj C) (u : Hom C x a) (v : Hom C x b)
       → comp C u f ≡ comp C v g
       → Σ (Hom C x p) λ m →
           (comp C m p1 ≡ u × comp C m p2 ≡ v)
             × (∀ m' → comp C m' p1 ≡ u → comp C m' p2 ≡ v → m' ≡ m))

-- 等化子 = 拉回沿对角线的特例；推出 = 反范畴里的拉回（文档层）

------------------------------------------------------------------------
-- 旗舰：单态射的拉回仍是单态射
-- 证明骨架：u;p2 = v;p2 要证 u = v——让 u、v 竞争「u 自己造的锥」，
-- v;p1 = u;p1 由 f 单性从「两边后复合 f 相等」逼出。

pb-of-mono :
  ∀ {o ℓ} {C : Category o ℓ} {a b c p : Obj C}
    {f : Hom C a c} {g : Hom C b c} {p1 : Hom C p a} {p2 : Hom C p b}
  → IsPullback C a b c p f g p1 p2
  → Mono C a c f
  → Mono C p b p2
pb-of-mono {C = C} {f = f} {g = g} {p1 = p1} {p2 = p2} (sq , univ) Hf x u v Huv =
  let
    Hcone : comp C (comp C u p1) f ≡ comp C (comp C u p2) g
    Hcone = trans (assoc C u p1 f) (trans (cong (comp C u) sq) (sym (assoc C u p2 g)))
    m , (m1 , m2) , muniq = univ x (comp C u p1) (comp C u p2) Hcone
    Hu : u ≡ m
    Hu = muniq u refl refl
    -- v;p1 = u;p1：两边后复合 f 后都化到 (u;p2);g
    Evp1f : comp C (comp C v p1) f ≡ comp C (comp C v p2) g
    Evp1f = trans (assoc C v p1 f) (trans (cong (comp C v) sq) (sym (assoc C v p2 g)))
    Evg : comp C (comp C v p2) g ≡ comp C (comp C u p1) f
    Evg = begin
      comp C (comp C v p2) g   ≡⟨ cong (λ k → comp C k g) (sym Huv) ⟩
      comp C (comp C u p2) g   ≡⟨ sym Hcone ⟩
      comp C (comp C u p1) f   ∎
    Evp1 : comp C v p1 ≡ comp C u p1
    Evp1 = Hf x (comp C v p1) (comp C u p1) (trans Evp1f Evg)
    Hv : v ≡ m
    Hv = muniq v Evp1 (sym Huv)
  in
  begin
    u                     ≡⟨ Hu ⟩
    m                     ≡⟨ sym Hv ⟩
    v
  ∎

------------------------------------------------------------------------
-- 坑位速记：
-- 1. 「让 v 竞争 u 的锥」的两条方程：Evp1 走「v;p2 = u;p2 + 两边
--    的方块」换向（trans 链按 assoc → cong(sq) → sym(assoc) 摆），
--    单性在最后一步收网。
-- 2. Agda 版无 PI：TyCat 纤维积的唯一性要求 Σ 证明分量相等——
--    边界记录（Coq 用 PI、Lean 用 Subtype.ext 免费拿）。
-- 3. IsPullback 的唯一子句三参数（m' + 两条方程）——Σ 的嵌套
--    按 (方程对) × 唯一 拆。
------------------------------------------------------------------------
