-- 第 92 章 · 布尔值模型（冯琦第二卷 §3.5）
-- 四件样品：幂集代数 2^2 的 Ba1-Ba5 机器面；布尔值算法与
-- 基本布尔值不等式（定理 3.23(1)(2)）；逻辑公理的布尔值为 1
-- （引理 3.70 影子）；柱超滤子上的 Łoś 换算（引理 3.72 原子）
-- 与泛型名字的影子账（引理 3.75(1)）。
module Ch92_boolval where

open import Data.Bool using (Bool; true; false; _∧_; _∨_; not)
open import Data.Nat using (ℕ; zero)
open import Data.Product using (_×_; _,_; proj₁; proj₂)
open import Relation.Binary.PropositionalEquality using (_≡_; refl; cong; cong₂; trans)
open import Relation.Nullary using (¬_)
open import Data.Sum using (_⊎_; inj₁; inj₂)

-- ---------- 一、幂集代数 B = 2^2（定义 3.38 的机器面） ----------

B4 : Set
B4 = Bool × Bool

bjoin : B4 → B4 → B4
bjoin (x1 , y1) (x2 , y2) = (x1 ∨ x2) , (y1 ∨ y2)

bmeet : B4 → B4 → B4
bmeet (x1 , y1) (x2 , y2) = (x1 ∧ x2) , (y1 ∧ y2)

bcompl : B4 → B4
bcompl (x , y) = not x , not y

btop bbot : B4
btop = true , true
bbot = false , false

bimp : B4 → B4 → B4
bimp a b = bjoin (bcompl a) b

-- Ba5 互补律：四值穷举即证
ba5-meet : ∀ a → bmeet a (bcompl a) ≡ bbot
ba5-meet (false , false) = refl
ba5-meet (false , true) = refl
ba5-meet (true , false) = refl
ba5-meet (true , true) = refl

ba5-join : ∀ a → bjoin a (bcompl a) ≡ btop
ba5-join (false , false) = refl
ba5-join (false , true) = refl
ba5-join (true , false) = refl
ba5-join (true , true) = refl

-- Ba1 交换律抽查（先证坐标级交换，再双分量 cong）
∧-comm : ∀ x y → (x ∧ y) ≡ (y ∧ x)
∧-comm false false = refl
∧-comm false true = refl
∧-comm true false = refl
∧-comm true true = refl

meet-comm : ∀ a b → bmeet a b ≡ bmeet b a
meet-comm (x1 , y1) (x2 , y2) = cong₂ _,_ (∧-comm x1 x2) (∧-comm y1 y2)

not-not : ∀ a → bcompl (bcompl a) ≡ a
not-not (false , false) = refl
not-not (false , true) = refl
not-not (true , false) = refl
not-not (true , true) = refl

∨-comm : ∀ x y → (x ∨ y) ≡ (y ∨ x)
∨-comm false false = refl
∨-comm false true = refl
∨-comm true false = refl
∨-comm true true = refl

ba1-join-comm : ∀ a b → bjoin a b ≡ bjoin b a
ba1-join-comm (x1 , y1) (x2 , y2) =
  cong₂ _,_ (∨-comm x1 x2) (∨-comm y1 y2)

-- ---------- 二、布尔值算法与基本布尔值不等式（定义 3.51 / 定理 3.23） ----------

data Fm : Set where
  tt ff atom : Fm
  fnot : Fm → Fm
  fand forr fimp fiff : Fm → Fm → Fm

bval : Fm → B4 → B4
bval tt _ = btop
bval ff _ = bbot
bval atom v = v
bval (fnot φ) v = bcompl (bval φ v)
bval (fand φ ψ) v = bmeet (bval φ v) (bval ψ v)
bval (forr φ ψ) v = bjoin (bval φ v) (bval ψ v)
bval (fimp φ ψ) v = bimp (bval φ v) (bval ψ v)
bval (fiff φ ψ) v =
  bmeet (bimp (bval φ v) (bval ψ v)) (bimp (bval ψ v) (bval φ v))

-- 定理 3.23(1)：⟦φ⟧ ∧ ⟦¬φ⟧ = 0
bval-not-self : ∀ φ v → bmeet (bval φ v) (bval (fnot φ) v) ≡ bbot
bval-not-self tt _ = refl
bval-not-self ff _ = refl
bval-not-self atom v = ba5-meet v
bval-not-self (fnot φ) v with bval φ v
... | (false , false) = refl
... | (false , true) = refl
... | (true , false) = refl
... | (true , true) = refl
bval-not-self (fand φ ψ) v = ba5-meet (bmeet (bval φ v) (bval ψ v))
bval-not-self (forr φ ψ) v = ba5-meet (bjoin (bval φ v) (bval ψ v))
bval-not-self (fimp φ ψ) v = ba5-meet (bimp (bval φ v) (bval ψ v))
bval-not-self (fiff φ ψ) v = ba5-meet
  (bmeet (bimp (bval φ v) (bval ψ v)) (bimp (bval ψ v) (bval φ v)))

-- 点态序（B⁺ 中「更强条件」）
ble : B4 → B4 → Set
ble w u = proj₁ w ≡ true → proj₁ u ≡ true

-- 定理 3.23(2)：⟦φ⟧ 或 ⟦¬φ⟧ 之一含住第一坐标的 1
bval-decides : ∀ φ v → (ble (bval φ v) btop) ⊎ (ble (bcompl (bval φ v)) btop)
bval-decides φ v with proj₁ (bval φ v)
... | true = inj₁ (λ _ → refl)
... | false = inj₂ (λ _ → refl)

-- ---------- 三、逻辑公理的布尔值为 1（引理 3.70 影子） ----------

bval-identity : ∀ φ v → bimp (bval φ v) (bval φ v) ≡ btop
bval-identity φ v with bval φ v
... | (false , false) = refl
... | (false , true) = refl
... | (true , false) = refl
... | (true , true) = refl

-- ---------- 四、柱超滤子上的 Łoś 换算（引理 3.72 原子） ----------

U0 : B4 → Set
U0 a = proj₁ a ≡ true

U0-meet : ∀ a b → U0 (bmeet a b) → (U0 a) × (U0 b)
U0-meet (true , _) (true , _) h = h , refl

U0-compl : ∀ a → U0 (bcompl a) → ¬ (U0 a)
U0-compl (false , _) _ ()

U0-imp : ∀ a b → U0 a → (U0 (bimp a b) → U0 b)
U0-imp (true , _) (true , _) _ h = h
U0-imp (true , _) (false , _) _ ()

-- 泛型名字的影子账（定义 3.58 / 引理 3.75(1)）：对角赋值下
-- ⟦ǔ ∈ Ġ⟧ = u 按定义直接算出
mem1 : ℕ → (ℕ → B4) → B4
mem1 x σ = σ x

gen-diag : B4 → ℕ → B4
gen-diag u _ = u

p0 : B4
p0 = true , false

demo-generic : mem1 zero (gen-diag p0) ≡ p0
demo-generic = refl
