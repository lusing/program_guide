-- 第 88 章 · L 中的组合原理与弱紧基数（冯琦第二卷 §2.1.4-2.1.5）
-- 样品：Jensen 苏斯林树构造的封口引擎（定理 2.12 性质 (4)）——
-- 被封口的反链在一切更高层保持极大；附计算样品。
module Ch88_lcomb where

open import Data.Nat using (ℕ; zero; suc; _≤_; _≟_; s≤s)
open import Data.Nat.Properties using (≤-pred; ≤∧≢⇒<)
open import Data.Bool using (Bool; true; false; not; _∧_; _∨_)
open import Data.List using (List; []; _∷_; _++_; map; concatMap)
open import Data.List.Membership.Propositional using (_∈_)
open import Data.Product using (_×_; _,_; ∃)
open import Data.Unit using (⊤; tt)
open import Relation.Binary.PropositionalEquality
  using (_≡_; _≢_; refl; sym; cong; trans)
open import Relation.Nullary using (yes; no)

-- ---------- 前缀关系与传递 ----------

_-<-Prefix-of-_ : List Bool → List Bool → Set
a -<-Prefix-of- t = ∃ λ r → t ≡ a ++ r

++-assoc : ∀ (a r₁ r₂ : List Bool) → (a ++ r₁) ++ r₂ ≡ a ++ (r₁ ++ r₂)
++-assoc [] r₁ r₂ = refl
++-assoc (x ∷ xs) r₁ r₂ = cong (_∷_ x) (++-assoc xs r₁ r₂)

-- 前缀传递：封口保持的引擎。
prefix-trans : ∀ {a s t : List Bool} → a -<-Prefix-of- s → s -<-Prefix-of- t →
               a -<-Prefix-of- t
prefix-trans {a} {s} {t} (r₁ , Hs) (r₂ , Ht) =
  (r₁ ++ r₂) , trans (trans Ht (cong (λ u → u ++ r₂) Hs)) (++-assoc a r₁ r₂)

-- ---------- 封口引擎（定理 2.12 性质 (4)） ----------

sealed : List (List Bool) → List (List Bool) → Set
sealed A T = ∀ {t} → t ∈ T → ∃ λ a → (a ∈ A × a -<-Prefix-of- t)

-- 定理 2.12 性质 (4)：封口一旦完成便永久保持。
-- 封口层每个节点延拓 A 的成员；此后每层节点延拓前层节点，
-- 前缀关系传递，于是 A 在所有更高层保持极大。
sealed-persists : ∀ {A : List (List Bool)} {T : ℕ → List (List Bool)} {k : ℕ} →
  sealed A (T (suc k)) →
  (∀ n → suc k ≤ n → ∀ {t} → t ∈ T (suc n) →
     ∃ λ s → (s ∈ T n × s -<-Prefix-of- t)) →
  ∀ n → suc k ≤ n → sealed A (T n)
sealed-persists {k = k} h0 hstep (suc n) (s≤s hn) with n ≟ k
... | yes e rewrite e = h0
... | no ne =
  let hle = ≤∧≢⇒< hn (λ eq → ne (sym eq))
  in λ Ht →
    let (s , Hs , Hp) = hstep n hle Ht
        (a , Ha , Haq) = sealed-persists h0 hstep n hle {s} Hs
    in a , Ha , prefix-trans Haq Hp
sealed-persists _ _ zero ()

-- ---------- 计算样品 ----------

eqb : Bool → Bool → Bool
eqb x y = (x ∧ y) ∨ (not x ∧ not y)

prefb : List Bool → List Bool → Bool
prefb [] _ = true
prefb (x ∷ xs) [] = false
prefb (x ∷ xs) (y ∷ ys) = eqb x y ∧ prefb xs ys

-- 手卷布尔 filter（本版 stdlib 的 filter 吃 Dec）。
bfilter : ∀ {A : Set} → (A → Bool) → List A → List A
bfilter f [] = []
bfilter f (x ∷ xs) with f x
... | true  = x ∷ bfilter f xs
... | false = bfilter f xs

children : List (List Bool) → List (List Bool)
children = concatMap (λ t → (t ++ (true ∷ [])) ∷ (t ++ (false ∷ [])) ∷ [])

iterate : ℕ → List (List Bool) → List (List Bool)
iterate zero l = l
iterate (suc n) l = iterate n (children l)

-- 第 2 层封口单点反链 {[true;true]}：满二元树第 2 层经其过滤。
level2 : List (List Bool)
level2 = bfilter (prefb (true ∷ (true ∷ [])))
                 (children (children (([] ∷ []) )))

level4 : List (List Bool)
level4 = iterate (suc (suc zero)) level2

allTrue : List Bool → Set
allTrue [] = ⊤
allTrue (b ∷ bs) = (b ≡ true) × allTrue bs

-- 计算验证：封口之后两层，每个节点仍是 [true;true] 的延拓。
sealed-compute : allTrue (map (prefb (true ∷ (true ∷ []))) level4)
sealed-compute = refl , (refl , (refl , (refl , tt)))
