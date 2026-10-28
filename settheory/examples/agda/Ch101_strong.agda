-- 第 101 章：有限秩层的构造性递归、beth 尺寸链、
-- 层包含证书与见证条款记账（有限捕获不承载全域见证）。
module Ch101_strong where

open import Data.List using (List; []; _∷_; length)
open import Data.Nat using (ℕ; zero; suc; _+_; _≤_; _<_; z≤n; s≤s)
open import Data.Nat.Properties using (≤-refl; ≤-trans; m≤m+n; +-comm)
open import Data.Bool using (Bool; true; false; _∧_; _∨_; if_then_else_)
open import Data.Product using (_×_; _,_; proj₁; proj₂)
open import Data.Sum using (_⊎_; inj₁; inj₂)
open import Data.Empty using (⊥)
open import Relation.Binary.PropositionalEquality using (_≡_; refl; cong)
open import Relation.Nullary using (¬_)

-- ── 零、自建件：相等、成员、包含（沿 99 章 anyb/allb 范式）──

nat-eq : ℕ → ℕ → Bool
nat-eq zero zero = true
nat-eq zero (suc _) = false
nat-eq (suc _) zero = false
nat-eq (suc m) (suc n) = nat-eq m n

nat-eq-refl : ∀ n → nat-eq n n ≡ true
nat-eq-refl zero = refl
nat-eq-refl (suc n) = nat-eq-refl n

nat-eq-≡ : ∀ y x → nat-eq y x ≡ true → y ≡ x
nat-eq-≡ zero zero q = refl
nat-eq-≡ zero (suc x) ()
nat-eq-≡ (suc y) zero ()
nat-eq-≡ (suc y) (suc x) q = cong suc (nat-eq-≡ y x q)

data _∈L_ : ℕ → List ℕ → Set where
  here  : ∀ {x xs} → x ∈L (x ∷ xs)
  there : ∀ {y x xs} → x ∈L xs → x ∈L (y ∷ xs)

inL : ℕ → List ℕ → Bool
inL x [] = false
inL x (y ∷ ys) = nat-eq y x ∨ inL x ys

-- 反演件（模式变量是构造子，类型可约简——99 章已验证的范式）。
∨-inv : ∀ a b → (a ∨ b) ≡ true → (a ≡ true) ⊎ (b ≡ true)
∨-inv true b H = inj₁ refl
∨-inv false b H = inj₂ H

∨-trueʳ : ∀ a → (a ∨ true) ≡ true
∨-trueʳ false = refl
∨-trueʳ true = refl

inL-sound : ∀ x ys → inL x ys ≡ true → x ∈L ys
inL-sound x [] ()
inL-sound x (y ∷ ys) p with ∨-inv (nat-eq y x) (inL x ys) p
... | inj₁ q rewrite nat-eq-≡ y x q = here
... | inj₂ q = there (inL-sound x ys q)

inL-complete : ∀ x ys → x ∈L ys → inL x ys ≡ true
inL-complete x [] ()
inL-complete .y (y ∷ ys) here rewrite nat-eq-refl y = refl
inL-complete x (y ∷ ys) (there m)
  rewrite inL-complete x ys m = ∨-trueʳ (nat-eq y x)

-- 布尔包含：subL xs ys = true ⟺ xs 的元素都在 ys 中。
subL : List ℕ → List ℕ → Bool
subL [] ys = true
subL (x ∷ xs) ys = inL x ys ∧ subL xs ys

∧-true-left : ∀ a b → (a ∧ b) ≡ true → a ≡ true
∧-true-left false b H = H
∧-true-left true b H = refl

∧-true-right : ∀ a b → (a ∧ b) ≡ true → b ≡ true
∧-true-right false b ()
∧-true-right true b H = H

subL-sound : ∀ xs ys → subL xs ys ≡ true →
  ∀ x → x ∈L xs → x ∈L ys
subL-sound [] ys p x ()
subL-sound (z ∷ zs) ys p x here =
  inL-sound x ys (∧-true-left (inL z ys) (subL zs ys) p)
subL-sound (z ∷ zs) ys p x (there m) =
  subL-sound zs ys (∧-true-right (inL z ys) (subL zs ys) p) x m

subL-complete : ∀ xs ys → (∀ x → x ∈L xs → x ∈L ys) → subL xs ys ≡ true
subL-complete [] ys p = refl
subL-complete (z ∷ zs) ys p
  rewrite inL-complete z ys (p z here)
        | subL-complete zs ys (λ x m → p x (there m)) = refl

-- 点级包含（证书式，沿 100 章 ⊆L 模式）。
data _⊆L_ : List ℕ → List ℕ → Set where
  nil⊆ : ∀ {ys} → [] ⊆L ys
  cons : ∀ {z zs ys} → z ∈L ys → zs ⊆L ys → (z ∷ zs) ⊆L ys

-- ── 一、位编码有限累积层次（宇宙 {0..15}；beth 尺寸 1,2,4,16）──

half : ℕ → ℕ
half zero = zero
half (suc zero) = zero
half (suc (suc n)) = suc (half n)

oddb : ℕ → Bool
oddb zero = false
oddb (suc n) = if oddb n then false else true

testbit : ℕ → ℕ → Bool
testbit x zero = oddb x
testbit x (suc i) = testbit (half x) i

-- 元素表：使第 i 位为 1 的 i 全体（四位宇宙只需前四个位号）。
elems : ℕ → List ℕ
elems x = filter-true (0 ∷ 1 ∷ 2 ∷ 3 ∷ [])
  where
  filter-true : List ℕ → List ℕ
  filter-true [] = []
  filter-true (i ∷ is) with testbit x i
  ... | true = i ∷ filter-true is
  ... | false = filter-true is

universe : List ℕ
universe = 0 ∷ 1 ∷ 2 ∷ 3 ∷ 4 ∷ 5 ∷ 6 ∷ 7 ∷
            8 ∷ 9 ∷ 10 ∷ 11 ∷ 12 ∷ 13 ∷ 14 ∷ 15 ∷ []

-- 秩层递归（§1.2.3 定义 1.18 的 V_λ ⊆ M 在有限层的地基）：
-- level 0 = []，level (suc n) = {x ∈ universe | elems x ⊆ level n}。
keep-if : List ℕ → List ℕ → List ℕ
keep-if cur [] = []
keep-if cur (u ∷ us) with subL (elems u) cur
... | true = u ∷ keep-if cur us
... | false = keep-if cur us

level : ℕ → List ℕ
level zero = []
level (suc n) = keep-if (level n) universe

level-1 : level 1 ≡ 0 ∷ []
level-1 = refl

level-2 : level 2 ≡ 0 ∷ 1 ∷ []
level-2 = refl

level-3 : level 3 ≡ 0 ∷ 1 ∷ 2 ∷ 3 ∷ []
level-3 = refl

level-4-full : level 4 ≡ universe
level-4-full = refl

size-chain : (length (level 1) ≡ 1) × (length (level 2) ≡ 2) ×
             (length (level 3) ≡ 4) × (length (level 4) ≡ 16)
size-chain = refl , refl , refl , refl

-- 层包含证书链：V₀⊆V₁⊆V₂⊆V₃⊆V₄（前四环）。(nil⊆/cons 逐点给出。)
chain-1 : (0 ∷ []) ⊆L (0 ∷ 1 ∷ [])
chain-1 = cons here nil⊆

chain-2 : (0 ∷ 1 ∷ []) ⊆L (0 ∷ 1 ∷ 2 ∷ 3 ∷ [])
chain-2 = cons here (cons (there here) nil⊆)

chain-3 : (0 ∷ 1 ∷ 2 ∷ 3 ∷ []) ⊆L universe
chain-3 = cons here
  (cons (there here)
    (cons (there (there here))
      (cons (there (there (there here))) nil⊆)))

-- ── 二、见证条款记账 ──

max2 : ℕ → ℕ → ℕ
max2 zero b = b
max2 (suc a) zero = suc a
max2 (suc a) (suc b) = suc (max2 a b)

max2-ˡ : ∀ a b → a ≤ max2 a b
max2-ˡ zero b = z≤n
max2-ˡ (suc a) zero = ≤-refl
max2-ˡ (suc a) (suc b) = s≤s (max2-ˡ a b)

max2-ʳ : ∀ a b → b ≤ max2 a b
max2-ʳ zero b = ≤-refl
max2-ʳ (suc a) zero = z≤n
max2-ʳ (suc a) (suc b) = s≤s (max2-ʳ a b)

maxl : List ℕ → ℕ
maxl [] = zero
maxl (x ∷ xs) = max2 x (maxl xs)

maxl-ge : ∀ y xs → y ∈L xs → y ≤ maxl xs
maxl-ge y [] ()
maxl-ge .y (y ∷ xs) here = max2-ˡ y (maxl xs)
maxl-ge y (z ∷ xs) (there m) =
  ≤-trans (maxl-ge y xs m) (max2-ʳ z (maxl xs))

n≰sucn : ∀ n → ¬ (suc n ≤ n)
n≰sucn zero ()
n≰sucn (suc n) (s≤s p) = n≰sucn n p

-- 右加保序（经交换律）：a ≤ b + a。
≤-swap : ∀ a b → a ≤ b + a
≤-swap a b rewrite +-comm b a = m≤m+n a b

-- 见证记录：临界点、j(κ)、捕获的秩层号表。
record Wit : Set where
  constructor wit
  field
    crit : ℕ
    jk   : ℕ
    cap  : List ℕ

LamStrong : Wit → ℕ → Set
LamStrong w l = (Wit.crit w ≤ l) × (l < Wit.jk w) × (l ∈L Wit.cap w)

Superstrong : Wit → Set
Superstrong w = Wit.jk w ∈L Wit.cap w

IsStrong : Wit → Set
IsStrong w = ∀ l → Wit.crit w ≤ l → LamStrong w l

-- 有限捕获表不可能承载「对所有 λ 的见证」——
-- 取 L = crit + (maxl + 1)，超出表内一切层号。
not-strong-finite : ∀ w → ¬ IsStrong w
not-strong-finite w h = goal
  where
  open Wit w
  l : ℕ
  l = crit + suc (maxl cap)
  dec : LamStrong w l
  dec = h l (m≤m+n crit (suc (maxl cap)))
  mem : l ∈L cap
  mem = proj₂ (proj₂ dec)
  goal : ⊥
  goal = n≰sucn (maxl cap)
    (≤-trans (≤-swap (suc (maxl cap)) crit) (maxl-ge l cap mem))

-- 单 λ 见证样本：临界 2、j(κ)=5、捕获 [3] 是 λ=3 的强见证。
w0 : Wit
w0 = wit 2 5 (3 ∷ [])

lam3 : LamStrong w0 3
lam3 = s≤s (s≤s z≤n) ,
       s≤s (s≤s (s≤s (s≤s z≤n))) ,
       here

not-lam4 : ¬ LamStrong w0 4
not-lam4 (_ , _ , there ())

not-superstrong-w0 : ¬ Superstrong w0
not-superstrong-w0 (there ())

-- 超强见证样本：临界 2、j(κ)=4、捕获 [4]。
w1 : Wit
w1 = wit 2 4 (4 ∷ [])

superstrong-w1 : Superstrong w1
superstrong-w1 = here
