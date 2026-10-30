-- 第 108 章：可数支撑迭代的有限影子——支撑限制、拼接协调与支撑并集。
module Ch108_pfa where

open import Data.Nat using (ℕ; zero; suc)
open import Data.List
open import Data.Product using (_×_; _,_)
open import Data.Sum using (_⊎_; inj₁; inj₂)
open import Relation.Binary.PropositionalEquality using (_≡_; refl; cong)
open import Data.List.Relation.Unary.Any using (Any; here; there)

-- ── 零、条件与支撑（可数支撑的有限影子：平凡坐标不上表） ──

Keys : List (ℕ × ℕ) → List ℕ
Keys [] = []
Keys ((i , c) ∷ q) = i ∷ Keys q

_∈K_ : ℕ → List (ℕ × ℕ) → Set
i ∈K q = Any (i ≡_) (Keys q)

-- ── 一、自建件：限制与丢弃（方程可控） ──

Take : ℕ → List (ℕ × ℕ) → List (ℕ × ℕ)
Take zero _ = []
Take (suc k) [] = []
Take (suc k) ((i , c) ∷ q) = (i , c) ∷ Take k q

Drop : ℕ → List (ℕ × ℕ) → List (ℕ × ℕ)
Drop zero q = q
Drop (suc k) [] = []
Drop (suc k) ((i , c) ∷ q) = Drop k q

Restrict : ℕ → List (ℕ × ℕ) → List (ℕ × ℕ)
Restrict k q = Take k q

-- 拼接：先取 q 的全部坐标，再接 r 在 q 长度之外的部分。
Glue : List (ℕ × ℕ) → List (ℕ × ℕ) → List (ℕ × ℕ)
Glue q r = q ++ Drop (length q) r

-- ── 二、支撑并集仍有限（Task 23 Step 2 指定件） ──

keys-∪ : (q r : List (ℕ × ℕ)) (i : ℕ) →
         i ∈K (q ++ r) → (i ∈K q) ⊎ (i ∈K r)
keys-∪ [] r i h = inj₂ h
keys-∪ ((j , c) ∷ q) r i h with h
... | here eq = inj₁ (here eq)
... | there h' with keys-∪ q r i h'
...   | inj₁ l = inj₁ (there l)
...   | inj₂ rr = inj₂ rr

keys-Drop : (k : ℕ) (q : List (ℕ × ℕ)) (i : ℕ) →
            i ∈K Drop k q → i ∈K q
keys-Drop zero q i h = h
keys-Drop (suc k) [] i ()
keys-Drop (suc k) ((j , c) ∷ q) i h = there (keys-Drop k q i h)

keys-Glue : (q r : List (ℕ × ℕ)) (i : ℕ) →
            i ∈K Glue q r → (i ∈K q) ⊎ (i ∈K r)
keys-Glue q r i h with keys-∪ q (Drop (length q) r) i h
... | inj₁ l = inj₁ l
... | inj₂ rr = inj₂ (keys-Drop (length q) r i rr)

-- ── 三、限制只缩不小支撑 ──

keys-Take : (k : ℕ) (q : List (ℕ × ℕ)) (i : ℕ) →
            i ∈K Take k q → i ∈K q
keys-Take zero q i ()
keys-Take (suc k) [] i ()
keys-Take (suc k) ((j , c) ∷ q) i h with h
... | here eq = here eq
... | there h' = there (keys-Take k q i h')

-- ── 四、拼接协调：q_{n+1} ↾ αₙ = qₙ（引理 2.27 的协调条款） ──

Take-app-self : (q s : List (ℕ × ℕ)) → Take (length q) (q ++ s) ≡ q
Take-app-self [] s = refl
Take-app-self ((i , c) ∷ q) s = cong ((i , c) ∷_) (Take-app-self q s)

glue-coherence : (q r : List (ℕ × ℕ)) → Restrict (length q) (Glue q r) ≡ q
glue-coherence q r = Take-app-self q (Drop (length q) r)

-- ── 五、样本账（决定性核查） ──

qA : List (ℕ × ℕ)
qA = (2 , 1) ∷ []

rB : List (ℕ × ℕ)
rB = (0 , 2) ∷ (4 , 1) ∷ (9 , 2) ∷ []

glue-sample : Glue qA rB ≡ (2 , 1) ∷ (4 , 1) ∷ (9 , 2) ∷ []
glue-sample = refl

coherence-sample : Restrict 1 (Glue qA rB) ≡ qA
coherence-sample = refl
