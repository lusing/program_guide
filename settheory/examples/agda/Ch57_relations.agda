-- 第 57 章：传递闭包的构造论（Makinson Ch2）
-- 传递闭包的归纳定义、最小性、与逆的交换律；三点环的具体见证。
module Ch57_relations where

open import Data.Nat using (ℕ)
open import Data.Empty using (⊥)
open import Data.Unit using (⊤; tt)
open import Data.Product using (_×_)
open import Relation.Binary.PropositionalEquality using (_≡_; refl)

-- ---------- 传递闭包（右递归的迭代版） ----------

Transitive : (ℕ → ℕ → Set) → Set
Transitive R = ∀ a b c → R a b → R b c → R a c

data TC (R : ℕ → ℕ → Set) : ℕ → ℕ → Set where
  step : ∀ {a b}     → R a b → TC R a b
  trans : ∀ {a b c} → TC R a b → R b c → TC R a c

-- ---------- 最小性：包含 R 的传递关系必含 R⁺ ----------

TC-minimal : (R T : ℕ → ℕ → Set) →
             (∀ a b → R a b → T a b) → Transitive T →
             ∀ a b → TC R a b → T a b
TC-minimal R T hR hT a b (step r) = hR a b r
TC-minimal R T hR hT a b (trans tc r) =
  hT a _ b (TC-minimal R T hR hT _ _ tc) (hR _ b r)

-- ---------- 闭包本身传递 ----------

-- 对第二个推导做结构归纳：trans 只向右接 R-步，归纳即递归
TC-trans : (R : ℕ → ℕ → Set) → Transitive (TC R)
TC-trans R a b c hab (step r) = trans hab r
TC-trans R a b c hab (trans h r) = trans (TC-trans R a b _ hab h) r

-- ---------- 逆与闭包交换 ----------

conv : (ℕ → ℕ → Set) → ℕ → ℕ → Set
conv R y x = R x y

TC-conv : (R : ℕ → ℕ → Set) → ∀ a b → TC R a b → TC (conv R) b a
TC-conv R a b (step r) = step r
TC-conv R a b (trans {b = b′} tc r) =
  TC-trans (conv R) b b′ a (step r) (TC-conv R a b′ tc)

-- ---------- 三点环的具体见证 ----------

data Chain : ℕ → ℕ → Set where
  c01 : Chain 0 1
  c12 : Chain 1 2
  c20 : Chain 2 0

w02 : TC Chain 0 2
w02 = trans (step c01) c12

w00 : TC Chain 0 0
w00 = trans (trans (step c01) c12) c20

-- 闭包的逆 = 逆的闭包：w20 见证
w20 : TC (conv Chain) 2 0
w20 = TC-conv Chain 0 2 w02

w22chain : TC Chain 2 2
w22chain = trans (trans (step c20) c01) c12

w22 : TC (conv Chain) 2 2
w22 = TC-conv Chain 2 2 w22chain

-- 传递性的具体使用：0→2 与 2→0 合成 0→0
w00' : TC Chain 0 0
w00' = TC-trans Chain 0 2 0 w02 (step c20)

-- 最小性使用例：全关系包含 Chain 且传递，故包含 Chain⁺
data Full : ℕ → ℕ → Set where
  full : ∀ a b → Full a b

full-trans : Transitive Full
full-trans a b c _ _ = full a c

chain-full : ∀ a b → Chain a b → Full a b
chain-full _ _ c = full _ _

TC⊆Full : ∀ a b → TC Chain a b → Full a b
TC⊆Full a b h = TC-minimal Chain Full chain-full full-trans a b h
