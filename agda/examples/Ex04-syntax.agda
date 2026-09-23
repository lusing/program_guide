------------------------------------------------------------------------
-- 第 04 章示例：记号与运算符
--
-- mixfix 名字、infix/infixl/infixr 与优先级、syntax 声明、
-- 括号类运算符、词法级记号（if_then_else_）、Unicode 命名。
--
-- 注意：本文件原名 Ex04_syntax.agda，但 Agda 规定标识符里被下划线
-- 分隔的片段不能是关键字（syntax 是关键字），该文件名根本无法通过
-- 词法检查，故按 stdlib 惯例（∃-syntax 等）改用连字符。
--
-- 类型检查：cd agda && agda examples/Ex04-syntax.agda
------------------------------------------------------------------------

module Ex04-syntax where

open import Data.Nat using (ℕ; zero; suc; _+_; _*_)
open import Data.Bool using (Bool; true; false)
open import Data.List using (List; []; _∷_)
open import Relation.Binary.PropositionalEquality using (_≡_; refl)
open import Data.Product.Base using (Σ; _,_)

------------------------------------------------------------------------
-- 4.1 运算符就是带洞（_）的普通名字
------------------------------------------------------------------------

infixl 6 _⊞_
infixr 7 _⊠_

_⊞_ : ℕ → ℕ → ℕ
x ⊞ y = suc (x + y)

_⊠_ : ℕ → ℕ → ℕ
x ⊠ y = x * suc y

_ : (_⊞_ 2) 3 ≡ 2 ⊞ 3
_ = refl

#_ : {A : Set} → List A → ℕ
# []       = 0
# (x ∷ xs) = suc (# xs)

infix 10 #_

_ : # (1 ∷ 2 ∷ 3 ∷ []) ≡ 3
_ = refl

------------------------------------------------------------------------
-- 4.2 优先级数字与结合性
------------------------------------------------------------------------

_ : 1 ⊞ 2 ⊠ 3 ≡ 1 ⊞ (2 ⊠ 3)
_ = refl

_ : 1 ⊞ 2 ⊞ 3 ≡ (1 ⊞ 2) ⊞ 3
_ = refl

infixr 7 _^_

_^_ : ℕ → ℕ → ℕ
x ^ zero = 1
x ^ suc n = x * (x ^ n)

_ : 2 ^ 3 ^ 2 ≡ 2 ^ (3 ^ 2)
_ = refl

-- 只写 infix（不带 l/r）＝ 不可结合：1 ⊘ 2 ⊘ 3 直接报
-- 「Could not parse the application」（Agda 没有 nonassoc 关键字！）
postulate
  _⊘_ : ℕ → ℕ → ℕ

infix 6 _⊘_

_ : 1 ⊘ 2 ≡ 1 ⊘ 2
_ = refl

------------------------------------------------------------------------
-- 4.3 括号与词法记号
------------------------------------------------------------------------

infix 9 _[_]

_[_] : {A B : Set} → (A → B) → A → B
f [ x ] = f x

_ : suc [ 2 + 3 ] ≡ 6
_ = refl

-- 词元拼起来的多元记号：stdlib 的 if_then_else_ 就是这个形状
infix 0 if_then_else_

if_then_else_ : {A : Set} → Bool → A → A → A
if true  then x else y = x
if false then x else y = y

_ : (if true then 2 ⊞ 4 else 9) ≡ 7
_ = refl

-- 自造一个「小等式」数据类型，看看 _≡_ 记号本身没有特权
infix 4 _≡ₐ_

data _≡ₐ_ {A : Set} (x : A) : A → Set where
  reflₐ : x ≡ₐ x

_ : 2 + 3 ≡ₐ 5
_ = reflₐ

------------------------------------------------------------------------
-- 4.4 syntax 声明：给简单名字换个表面记号
------------------------------------------------------------------------

-- (1) 换顺序：`a ∋ A` 其实是 ∋-syntax A a
∋-syntax : (A : Set) (a : A) → A
∋-syntax _ a = a

infix 4 ∋-syntax
syntax ∋-syntax A a = a ∋ A

_ : (5 ∋ ℕ) ≡ 5
_ = refl

-- (2) 备用拼法：syntax 的左侧必须是「无洞的简单名字」，
--     带洞的 if_then_else_ 要先包一层
ite-syntax : {A : Set} → (b : Bool) (x y : A) → A
ite-syntax = if_then_else_

syntax ite-syntax b x y = b ◃ x ▹ y

_ : (true ◃ 2 ▹ 9) ⊞ 4 ≡ 7
_ = refl

-- (3) 捕获 λ（binder capture）：stdlib 的 ∃[ x ] B / Σ[ x ∈ A ] B 全靠它
∃-syntax : {A : Set} → (A → Set) → Set
∃-syntax {A} B = Σ A B

syntax ∃-syntax (λ x → B) = ∃[ x ] B

data Even : ℕ → Set where
  e0  : Even 0
  e+2 : ∀ {n} → Even n → Even (suc (suc n))

twoEven : ∃[ n ] Even n
twoEven = 2 , e+2 e0

------------------------------------------------------------------------
-- 4.5 操作符字符与 Unicode 命名
------------------------------------------------------------------------

-- ASCII 运算符字符随便拼（? 参与名字也没问题）
_?!_ : Bool → Bool → Bool
x ?! y = if x then y else false

_ : true ?! false ≡ false
_ = refl

infix 4 _⊼_

notb : Bool → Bool
notb true = false
notb false = true

_⊼_ : Bool → Bool → Bool
x ⊼ y = notb (x ?! y)

_ : (true ⊼ true) ≡ false
_ = refl

_ : (false ⊼ true) ≡ true
_ = refl
