-- 第 102 章：f-闭包点的构造性判定、见证依赖函数与
-- f-谢拉赫型条款（闭包 + 层捕获）。
module Ch102_woodin where

open import Data.Nat using (ℕ; zero; suc; _<_; _≤_; z≤n; s≤s)
open import Data.Nat.Properties using (≤-refl; ≤-trans)
open import Data.Bool using (Bool; true; false; if_then_else_)
open import Data.List using (List; []; _∷_)
open import Data.Product using (_×_; _,_)
open import Data.Empty using (⊥)
open import Relation.Binary.PropositionalEquality using (_≡_; refl)
open import Relation.Nullary using (¬_)

-- ── 零、自建件 ──

leq : ℕ → ℕ → Bool
leq zero b = true
leq (suc a) zero = false
leq (suc a) (suc b) = leq a b

eq1 : ℕ → Bool
eq1 zero = false
eq1 (suc zero) = true
eq1 (suc (suc i)) = false

z<s : ∀ {n} → zero < suc n
z<s = s≤s z≤n

n≰sucn : ∀ n → ¬ (suc n ≤ n)
n≰sucn zero ()
n≰sucn (suc n) (s≤s p) = n≰sucn n p

-- ── 一、f-闭包（定义 1.25(i) 影子）与函数样本 ──

closed : (ℕ → ℕ) → ℕ → Set
closed f k = ∀ i → i < k → f i < k

fsucc : ℕ → ℕ
fsucc i = if leq i 3 then suc i else 5

c1 : ℕ → ℕ
c1 i = 1

c13 : ℕ → ℕ
c13 i = if eq1 i then 3 else 1

-- ── 二、样本函数的具体闭包事实 ──

-- c1 在一切 κ≥2 处闭包：目标 c1 i < k 即 1<k 即 2≤k——同一事实。
c1-closed : ∀ k → 2 ≤ k → closed c1 k
c1-closed k h i hi = h

-- c13 在 κ=4 处闭包。
c13-closed-4 : closed c13 4
c13-closed-4 zero hi = s≤s (s≤s z≤n)
c13-closed-4 (suc zero) hi = ≤-refl
c13-closed-4 (suc (suc zero)) hi = s≤s (s≤s z≤n)
c13-closed-4 (suc (suc (suc zero))) hi = s≤s (s≤s z≤n)
c13-closed-4 (suc (suc (suc (suc i)))) (s≤s (s≤s (s≤s (s≤s ()))))

-- c13 在 κ=2 处闭包失败：f(1)=3 ≮ 2。
¬c13-2 : ¬ closed c13 2
¬c13-2 h with h (suc zero) ≤-refl
... | s≤s (s≤s ())

-- ── 三、后继型函数：[1,5] 内无闭包点（核心反例） ──

fsucc-gt : ∀ i → i < 5 → i < fsucc i
fsucc-gt zero hi = ≤-refl
fsucc-gt (suc zero) hi = ≤-refl
fsucc-gt (suc (suc zero)) hi = ≤-refl
fsucc-gt (suc (suc (suc zero))) hi = ≤-refl
fsucc-gt (suc (suc (suc (suc i)))) hi = hi

no-gap : ∀ m v → suc m ≤ v → suc v ≤ suc m → ⊥
no-gap m v q (s≤s p) = n≰sucn m (≤-trans q p)

fsucc-not-closed : ∀ k → 1 ≤ k → k ≤ 5 → ¬ closed fsucc k
fsucc-not-closed (suc m) h1 (s≤s h4) hcl =
  no-gap m (fsucc m) (fsucc-gt m (s≤s h4)) (hcl m ≤-refl)

-- ── 四、f-谢拉赫型条款与见证分离 ──

data _∈L_ : ℕ → List ℕ → Set where
  here  : ∀ {x xs} → x ∈L (x ∷ xs)
  there : ∀ {y x xs} → x ∈L xs → x ∈L (y ∷ xs)

record FWit : Set where
  constructor fwit
  field
    κ    : ℕ
    jfκ  : ℕ
    cap  : List ℕ

fShelah : (ℕ → ℕ) → FWit → Set
fShelah f w =
  closed f (FWit.κ w) × (FWit.κ w < FWit.jfκ w × FWit.jfκ w ∈L FWit.cap w)

-- 见证样本：c1 在 (2,3,[3]) 处 f-谢拉赫成立。
c1-wit : FWit
c1-wit = fwit 2 3 (3 ∷ [])

c1-fShelah : fShelah c1 c1-wit
c1-fShelah = c1-closed 2 (s≤s (s≤s z≤n)) , (≤-refl , here)

fsucc-not-fShelah : ¬ fShelah fsucc c1-wit
fsucc-not-fShelah (hcl , _) =
  fsucc-not-closed 2 (s≤s z≤n) (s≤s (s≤s z≤n)) hcl

-- 见证分离：c1 的闭包见证含 κ=2，c13 到 κ=4 才开始——
-- 单一 κ 无法同时服务两个函数。
witnesses-depend :
  (closed c1 2 × closed c13 4) × (¬ closed c13 2 × ¬ closed fsucc 2)
witnesses-depend =
  (c1-closed 2 (s≤s (s≤s z≤n)) , c13-closed-4) ,
  (¬c13-2 , fsucc-not-closed 2 (s≤s z≤n) (s≤s (s≤s z≤n)))
