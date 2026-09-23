------------------------------------------------------------------------
-- 第 03 章示例：第一个 Agda 文件
--
-- 逐行解剖一个最小模块：module/where、open import、类型标注、
-- 字面量多态、用 refl 代替交互式 Compute、注释、postulate、命名。
--
-- 类型检查：cd agda && agda examples/Ex03_basics.agda
------------------------------------------------------------------------

module Ex03_basics where

-- 行注释：两个短横线到行尾
{- 块注释可以跨行，
   还能嵌套 {- 像这样 -}；
   但 {-# OPTIONS … #-} 指令必须放在 module 头之前 -}

------------------------------------------------------------------------
-- 3.1 模块头与导入的几种姿势
------------------------------------------------------------------------

open import Data.Nat using (ℕ; zero; suc; _+_; _*_)
open import Data.List using (List; []; _∷_)
open import Relation.Binary.PropositionalEquality using (_≡_; refl)

-- import … as 前缀：不进作用域，用限定名访问
import Data.List as L

list3 : List ℕ
list3 = 1 ∷ 2 ∷ 3 ∷ []

len3 : ℕ
len3 = L.length list3

_ : len3 ≡ 3
_ = refl

------------------------------------------------------------------------
-- 3.2 类型标注与函数定义
------------------------------------------------------------------------

-- 类型行以冒号开头，定义行以等号开头，名字必须一致
idℕ : ℕ → ℕ
idℕ n = n

-- 一个名字可以拆成多条等式规则（模式匹配，第 06 章展开）
double : (n : ℕ) → ℕ
double zero = 0
double (suc n) = suc (suc (double n))

square : ℕ → ℕ
square n = n * n

-- 函数本身也是值：suc 的类型恰好是 ℕ → ℕ
inc : ℕ → ℕ
inc = suc

_ : inc (double 3) ≡ 7
_ = refl

------------------------------------------------------------------------
-- 3.3 字面量多态
------------------------------------------------------------------------

-- 默认落点：没有实例机制时，3 就是 suc (suc (suc zero))
three : ℕ
three = 3

_ : three ≡ suc (suc (suc zero))
_ = refl

-- —— 实例化的字面量机制（Agda ≥ 2.6.2 + stdlib 2.x）——
-- 关键：除了记录类型 Number，还必须把字段 fromNat 本身 import 进作用域，
-- BUILTIN FROMNAT 才会生效；否则字面量永远走旧的 ℕ 落点。
open import Agda.Builtin.FromNat using (Number; fromNat)
open import Agda.Builtin.FromNeg using (Negative; fromNeg)
open import Data.Unit.Base using (⊤; tt)
open import Data.Nat.Literals using () renaming (number to ℕnumber)
open import Data.Integer using (ℤ; +_; -_)
open import Data.Integer.Literals using ()
  renaming (number to ℤnumber; negative to ℤnegative)

instance
  ℕ-is-number : Number ℕ
  ℕ-is-number = ℕnumber
  ℤ-is-number : Number ℤ
  ℤ-is-number = ℤnumber
  ℤ-is-negative : Negative ℤ
  ℤ-is-negative = ℤnegative

-- 机制一开，同一个字面量按期望类型落地
sevenℤ : ℤ
sevenℤ = 7

minus3 : ℤ
minus3 = -3

_ : sevenℤ ≡ + 7
_ = refl

_ : minus3 ≡ - (+ 3)
_ = refl

-- 自定义类型也能接管字面量：提供一个 Number 实例即可
data Parity : Set where
  even odd : Parity

parityOf : ℕ → Parity
parityOf zero = even
parityOf (suc zero) = odd
parityOf (suc (suc n)) = parityOf n

instance
  parity-is-number : Number Parity
  parity-is-number = record
    { Constraint = λ _ → ⊤
    ; fromNat    = λ n → parityOf n
    }

p7 : Parity
p7 = 7

_ : p7 ≡ odd
_ = refl

------------------------------------------------------------------------
-- 3.4 用等式证明 + refl 代替交互式 Compute
------------------------------------------------------------------------

-- 编译器把两边规约到同一个范式才放行——这就是「离线 Compute」
_ : 2 + 3 ≡ 5
_ = refl

_ : 2 * 3 + 4 ≡ 10
_ = refl

_ : double 3 ≡ 6
_ = refl

_ : square 5 ≡ 25
_ = refl

-- + 在第一个参数上递归：0 + n 能算，n + 0 算不动（第 13 章归纳）
0+-n : (n : ℕ) → 0 + n ≡ n
0+-n n = refl

------------------------------------------------------------------------
-- 3.6 postulate 与公理
------------------------------------------------------------------------

postulate
  Person : Set
  alice : Person
  age : Person → ℕ

aliceAge : ℕ
aliceAge = age alice

-- postulate 像「不知道取值的参数」：计算照常，等式无从证明
postulate
  mystery : ℕ

-- 1 + mystery 规约：先展开字面量 1 = suc 0，再算 0 + mystery = mystery，
-- 得 suc mystery——所以这条 refl 成立，计算由「字面量那一侧」驱动
1+mystery : suc mystery ≡ 1 + mystery
1+mystery = refl

------------------------------------------------------------------------
-- 3.7 命名惯例
------------------------------------------------------------------------

-- 连字符是合法标识符字符（和 Haskell 不同）
my-var : ℕ
my-var = 1

_ : my-var + my-var ≡ 2
_ = refl

-- 撇号、下标数字都可以进名字
x′ : ℕ
x′ = suc my-var

n₀ : ℕ
n₀ = double my-var

_ : x′ ≡ 2
_ = refl

_ : n₀ ≡ 2
_ = refl

-- 中文标识符同样合法（UTF-8 源文件）
类型别名 : Set
类型别名 = ℕ

值 : 类型别名
值 = 21

_ : 值 * 2 ≡ 42
_ = refl
