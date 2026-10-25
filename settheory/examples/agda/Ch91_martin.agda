-- 第 91 章 · 马丁公理之合理性与迭代力迫（冯琦第二卷 §3.4）
-- 四件样品：一步迭代的相容分解（定理 3.14 的组合核心）、
-- 典型嵌入的完备性半边（引理 3.54(6)）、有限支撑与坐标合并
-- （定义 3.36）、Solovay-Tennenbaum 记录函数的加倍配对实现
-- （定理 3.18 的 (b) 款；加倍以避开除法，一般不等式由
-- Lean/Coq 承载，此处给编译期验讫的配对表）。
module Ch91_martin where

open import Data.Nat using (ℕ; zero; suc; _+_; _*_; _≤_; z≤n; s≤s)
open import Data.Bool using (Bool; true; false)
open import Data.Maybe using (Maybe; just; nothing)
open import Data.List using (List; []; _∷_; _++_; length; map)
open import Data.Product using (_×_; _,_; ∃; proj₁; proj₂)
open import Relation.Binary.PropositionalEquality using (_≡_; refl; sym; cong)
open import Relation.Nullary using (¬_)

_↔_ : ∀ {a} (A B : Set a) → Set a
A ↔ B = (A → B) × (B → A)

-- ---------- 一、一步迭代的相容分解（定理 3.14 的组合核心） ----------

-- q 延拓 p（更强）：q = p ++ r
Ext : List Bool → List Bool → Set
Ext p q = ∃ λ r → q ≡ p ++ r

++-[] : (l : List Bool) → l ++ [] ≡ l
++-[] [] = refl
++-[] (x ∷ xs) = cong (x ∷_) (++-[] xs)

ext-refl : ∀ p → Ext p p
ext-refl p = [] , sym (++-[] p)

-- 相容：存在公共延长（力迫相容的一般形态）
agree : List Bool → List Bool → Set
agree p q = ∃ λ r → Ext p r × Ext q r

-- 迭代条件：第一步与第二步各一个串条件
IterCnd = List Bool × List Bool

ExtPair : IterCnd → IterCnd → Set
ExtPair x y = Ext (proj₁ x) (proj₁ y) × Ext (proj₂ x) (proj₂ y)

-- (p,q) 与 (p',q') 相容 ⟺ 两个分量分别相容（合并与投影互逆）
iterAgree-iff : ∀ x y →
  (∃ λ r → ExtPair x r × ExtPair y r) ↔
    (agree (proj₁ x) (proj₁ y) × agree (proj₂ x) (proj₂ y))
iterAgree-iff x y = (forth , back)
  where
  forth : (∃ λ r → ExtPair x r × ExtPair y r) →
          (agree (proj₁ x) (proj₁ y) × agree (proj₂ x) (proj₂ y))
  forth (r , ((h1 , h2) , (h3 , h4))) =
    (proj₁ r , (h1 , h3)) , (proj₂ r , (h2 , h4))
  back : (agree (proj₁ x) (proj₁ y) × agree (proj₂ x) (proj₂ y)) →
         (∃ λ r → ExtPair x r × ExtPair y r)
  back ((r1 , (e1 , e2)) , (r2 , (e3 , e4))) =
    (r1 , r2) , ((e1 , e3) , (e2 , e4))

-- ---------- 二、典型嵌入的完备性半边（引理 3.54(6)） ----------

canon : List Bool → IterCnd
canon p = p , []

agree-[][] : agree [] []
agree-[][] = [] , (ext-refl [] , ext-refl [])

-- 典型嵌入下的冲突完全由第一分量决定（第二分量是最大元）
canon-conflict-iff : ∀ p p' →
  (¬ (∃ λ r → ExtPair (canon p) r × ExtPair (canon p') r)) ↔ (¬ (agree p p'))
canon-conflict-iff p p' = (forth , back)
  where
  forth : (¬ (∃ λ r → ExtPair (canon p) r × ExtPair (canon p') r)) → (¬ (agree p p'))
  forth h (r1 , (e1 , e2)) =
    h ((r1 , []) , ((e1 , ext-refl []) , (e2 , ext-refl [])))
  back : (¬ (agree p p')) → (¬ (∃ λ r → ExtPair (canon p) r × ExtPair (canon p') r))
  back h (r , ((e1 , e2) , (ha , hb))) = h (proj₁ r , (e1 , ha))

-- ---------- 三、有限支撑迭代（定义 3.36） ----------

-- 支撑：偏离最大元的坐标个数（递归定义）
sptN : List (Maybe Bool) → ℕ
sptN [] = 0
sptN (just _ ∷ p) = suc (sptN p)
sptN (nothing ∷ p) = sptN p

≤-step : ∀ {m n : ℕ} → m ≤ n → m ≤ suc n
≤-step z≤n = z≤n
≤-step (s≤s h) = s≤s (≤-step h)

s≤ss : ∀ n → n ≤ suc n
s≤ss zero = z≤n
s≤ss (suc n) = s≤s (s≤ss n)

≤-trans : ∀ {a b c : ℕ} → a ≤ b → b ≤ c → a ≤ c
≤-trans z≤n _ = z≤n
≤-trans (s≤s h) (s≤s k) = s≤s (≤-trans h k)

-- 支撑天然有限：不超过条件长度
sptN-≤ : ∀ p → sptN p ≤ length p
sptN-≤ [] = z≤n
sptN-≤ (just x ∷ p) = s≤s (sptN-≤ p)
sptN-≤ (nothing ∷ p) = ≤-trans (sptN-≤ p) (s≤ss (length p))

-- 相容两条件的合并：每个坐标取首先给出决定者
mergeC : List (Maybe Bool) → List (Maybe Bool) → List (Maybe Bool)
mergeC [] q = q
mergeC (just x ∷ p) (_ ∷ q) = just x ∷ mergeC p q
mergeC (nothing ∷ p) (b ∷ q) = b ∷ mergeC p q
mergeC p [] = p

-- 具体例：合并两个相容条件得到逐坐标决定并（编译期验讫）
demo-merge : mergeC (nothing ∷ just true ∷ []) (just false ∷ nothing ∷ [])
             ≡ just false ∷ just true ∷ []
demo-merge = refl

-- 支撑演示（编译期验讫）
demo-spt : sptN (nothing ∷ just true ∷ nothing ∷ []) ≡ 1
demo-spt = refl

-- ---------- 四、Solovay-Tennenbaum 记录函数（加倍配对） ----------

-- Cantor 配对的加倍版本：2×π(β,γ) = (β+γ)(β+γ+1) + 2γ
-- （加倍以避开除法；β ≤ π(β,γ) ⟺ 2β ≤ 2π(β,γ)）
cantor2 : ℕ → ℕ → ℕ
cantor2 b g = (b + g) * (b + g + 1) + 2 * g

-- 配对表（行 β、列 γ）：每个编号都不小于其行号——
-- 记录函数公理 (b) 的有限验讫
demo-cantor2 : map (λ b → map (λ g → cantor2 b g)
                      (0 ∷ 1 ∷ 2 ∷ []))
                  (0 ∷ 1 ∷ 2 ∷ [])
               ≡ ((0 ∷ 4 ∷ 10 ∷ [])
                  ∷ (2 ∷ 8 ∷ 16 ∷ [])
                  ∷ (6 ∷ 14 ∷ 24 ∷ [])
                  ∷ [])
demo-cantor2 = refl
