------------------------------------------------------------------------
-- 第 09 章示例：记录与 Σ 类型
--
-- record 语法解剖（字段/实例化/访问/eta）、依赖记录、inherit 与嵌套、
-- Σ 就是内建两字段 record（直接 import Agda.Builtin.Sigma 实测）、
-- 带证明的记录（预告 26 章）、record 当接口（预告 18 章）。
--
-- 类型检查：cd agda && agda examples/Ex09_records.agda
------------------------------------------------------------------------

module Ex09_records where

open import Data.Nat using (ℕ; zero; suc; _+_; _≤_; z≤n; s≤s)
open import Data.List using (List; []; _∷_)
open import Data.Bool using (Bool; true; false)
open import Data.Unit using (⊤; tt)
open import Relation.Binary.PropositionalEquality using (_≡_; refl)
open import Data.Product
  using (Σ; Σ-syntax; _,_; proj₁; proj₂; _×_; ∃)

------------------------------------------------------------------------
-- 9.1 record 解剖：声明、实例化、字段访问
------------------------------------------------------------------------

record Point : Set where
  field
    posX : ℕ
    posY : ℕ

origin : Point
origin = record { posX = 0; posY = 0 }

p : Point
p = record { posX = 3; posY = 4 }

-- 注意：点前缀访问也要求投影名在作用域内——先 open
open Point public

-- 点前缀访问（Haskell 式）与限定投影访问
_ : p .posX ≡ 3
_ = refl

_ : (p .posX) + (p .posY) ≡ 7
_ = refl

_ : Point.posY p ≡ 4
_ = refl

-- open 之后 posX 就是「取 X 坐标」的函数，可脱离点记法直接应用
_ : posX p ≡ 3
_ = refl

-- 字段多行合并声明（同行多个字段名共享类型）
record Segment : Set where
  field
    start end : Point

seg : Segment
seg = record { start = origin; end = p }

open Segment

_ : seg .end .posX ≡ 3   -- 嵌套访问一路打点
_ = refl

-- 记录更新（record r { 字段 = … }，其余字段沿用 r 的）
p′ : Point
p′ = record p { posX = 10 }

_ : p′ .posX ≡ 10
_ = refl

_ : p′ .posY ≡ 4
_ = refl

------------------------------------------------------------------------
-- 9.1b 嵌套记录；以及 inherit 的实测命运
------------------------------------------------------------------------

-- 嵌套：字段本身是记录，实例化套娃，访问一路打点
record Sphere : Set where
  field
    center : Point
    radius : ℕ

sph : Sphere
sph = record { center = record { posX = 0; posY = 0 }; radius = 5 }

open Sphere

_ : sph .center .posX ≡ 0
_ = refl

-- 想「复用」旧字段只有两条路：嵌套包一层，或把字段抄一份重新声明。
-- 2.6 时代教程里的 `inherit Flat` 写法在本机 Agda 2.8.0 实测已不是
-- 合法关键字，报错如下（原样粘贴）：
--
--   Missing type signature for left hand side inherit Flat
--   when scope checking the declaration
--     inherit Flat

------------------------------------------------------------------------
-- 9.2 eta 契约：记录 = 唯一同构
------------------------------------------------------------------------

-- 把字段拆开再装回去，和原记录**逐点相等**（不是同构，是 refl！）
ηP : (q : Point) → record { posX = q .posX; posY = q .posY } ≡ q
ηP q = refl

-- 两个记录相等 ⟺ 所有字段相等，而字段全同就是 refl
_ : record { posX = 1; posY = 2 } ≡ record { posX = 1; posY = 2 }
_ = refl

-- 无字段记录也遵守 eta：stdlib 的 ⊤ 就是空 record，任何 x : ⊤ 都 ≡ tt
η⊤ : (x : ⊤) → x ≡ tt
η⊤ x = refl

------------------------------------------------------------------------
-- 9.3 依赖记录：后面的字段类型依赖前面的字段
------------------------------------------------------------------------

record DepBox : Set₁ where
  field
    Carrier : Set
    value : Carrier

b : DepBox
b = record { Carrier = ℕ; value = 42 }

open DepBox

_ : b .value ≡ 42
_ = refl

-- 盒子的「拆包」：DepBox 与 Σ[ S ∈ Set ] S 互相可写
toΣ : DepBox → Σ[ S ∈ Set ] S
toΣ x = (x .Carrier) , (x .value)

fromΣ : (Σ[ S ∈ Set ] S) → DepBox
fromΣ (S , v) = record { Carrier = S; value = v }

_ : fromΣ (toΣ b) ≡ b
_ = refl

------------------------------------------------------------------------
-- 9.4 Σ 类型：内建的「两字段依赖 record」
------------------------------------------------------------------------

-- 直接 import 内建模块，看 Σ 的原始定义（与 /usr/share/libghc-agda-dev/
-- lib/prim/Agda/Builtin/Sigma.agda 一字不差）：
--
--   record Σ {a b} (A : Set a) (B : A → Set b) : Set (a ⊔ b) where
--     constructor _,_
--     field
--       fst : A
--       snd : B fst          ← 第二个字段的类型依赖第一个字段！
--
-- Data.Product 只是把它改名 fst→proj₁、snd→proj₂ 再转发。

open import Agda.Builtin.Sigma using () renaming (Σ to Σ′; fst to fst₀; snd to snd₀)

q1 : Σ′ ℕ λ _ → Bool
q1 = 7 , true

_ : fst₀ q1 ≡ 7
_ = refl

-- 同一对象、同一字段，两套名字在类型层面完全可互换
_ : fst₀ q1 ≡ proj₁ q1
_ = refl

-- 非依赖对就是 record 两字段：ℕ × Bool ≡ Σ ℕ λ _ → Bool（定义同一）
q2 : ℕ × Bool
q2 = 1 , false

_ : proj₁ q2 + 1 ≡ 2
_ = refl

-- Σ 同样吃 eta：拆开装回，refl 通过
ηΣ : (pr : Σ ℕ λ _ → Bool) → (proj₁ pr , proj₂ pr) ≡ pr
ηΣ pr = refl

------------------------------------------------------------------------
-- 9.5 依赖记录实战：带证明的数据（预告 12 章 ∃、26 章排序）
------------------------------------------------------------------------

-- 「升序」作为归纳定义的关系（13 章展开这种写法，这里只消费）
data Sorted : List ℕ → Set where
  snil  : Sorted []
  sone  : ∀ {x} → Sorted (x ∷ [])
  scons : ∀ {x y ys} → x ≤ y → Sorted (y ∷ ys) → Sorted (x ∷ y ∷ ys)

-- 方式一：依赖记录 = 数据 + 对该数据的证明
record SortedList : Set where
  field
    list   : List ℕ
    sorted : Sorted list

ok : SortedList
ok = record
  { list   = 1 ∷ 2 ∷ 3 ∷ []
  ; sorted = scons (s≤s z≤n) (scons (s≤s (s≤s z≤n)) sone)
  }

open SortedList

_ : ok .list ≡ 1 ∷ 2 ∷ 3 ∷ []
_ = refl

-- 方式二：同一个东西用 Σ 写——依赖记录与 Σ 是同一概念的两副面孔
asΣ : Σ[ l ∈ List ℕ ] Sorted l
asΣ = (1 ∷ 2 ∷ 3 ∷ []) , scons (s≤s z≤n) (scons (s≤s (s≤s z≤n)) sone)

sl↔Σ : SortedList → (Σ[ l ∈ List ℕ ] Sorted l)
sl↔Σ r = (r .list) , (r .sorted)

_ : proj₁ (sl↔Σ ok) ≡ 1 ∷ 2 ∷ 3 ∷ []
_ = refl

-- 存在性：给我一个数，再证明 2 ≤ 它——12 章的 ∃ 就这么用
witness : ∃ λ n → 2 ≤ n
witness = 5 , s≤s (s≤s z≤n)

_ : proj₁ witness ≡ 5
_ = refl

-- 取「证明的第一位」不会破坏排序性：字段访问就是函数
extract : List ℕ
extract = ok .list

------------------------------------------------------------------------
-- 9.6 record 当接口：字段是运算，值是该接口的实例（预告 18 章）
------------------------------------------------------------------------

record MiniMonoid : Set₁ where
  field
    Carrier : Set
    _·_ : Carrier → Carrier → Carrier
    ε : Carrier

ℕ+-mono : MiniMonoid
ℕ+-mono = record { Carrier = ℕ; _·_ = _+_; ε = 0 }

_ : MiniMonoid._·_ ℕ+-mono 2 3 ≡ 5
_ = refl

_ : MiniMonoid.ε ℕ+-mono ≡ 0
_ = refl

------------------------------------------------------------------------
-- 9.7 派生字段：record 体内引用字段的定义，会被提升为吃记录的函数
------------------------------------------------------------------------

record PointSum : Set where
  field
    sumX : ℕ
    sumY : ℕ
  -- 体内字段名直接可用（record 自身作用域）；open 后 total 多一个记录参数
  total : ℕ
  total = sumX + sumY

ps : PointSum
ps = record { sumX = 1; sumY = 2 }

open PointSum

-- 实测：派生字段只能用普通函数形式 total ps 取用；
-- 点记法 ps .total 会报 CannotApply（点记法只认真字段）
_ : total ps ≡ 3
_ = refl
