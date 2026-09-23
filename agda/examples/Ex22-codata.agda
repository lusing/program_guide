------------------------------------------------------------------------
-- Ex22 · 余归纳与无限流
--
-- 用 Codata.Musical 的 ♯/♭ 自己定义 Stream 与 _~_(互模拟),
-- 实测 guardedness 的放行与拒绝边界;Costring 与 IO 的接线。
-- 本文件第一行的 pragma 是入场券(02/20 章伏笔在此正式回收)。
-- 注:因 module 名撞关键字 codata,本文件名为 Ex22-codata.agda(见下方说明)。
------------------------------------------------------------------------

{-# OPTIONS --guardedness #-}

-- 词法实测:Agda 2.8.0 中 codata 是保留关键字,而标识符被下划线分段的
-- 每一段都不能是关键字,所以 module Ex22_codata 无法通过词法检查;
-- 引号写法 module Ex22_"codata" 又不被 module 头的语法接受(2.8.0 实测)。
-- 依 04 章先例(syntax 同款问题)改用连字符:文件名 Ex22-codata.agda。
module Ex22-codata where

open import Codata.Musical.Notation using (∞; ♯_; ♭)
open import Codata.Musical.Costring using (Costring; toCostring)
open import Codata.Musical.Colist using (Colist; []; _∷_)
open import Data.Nat.Base using (ℕ; zero; suc; _+_)
open import Data.Maybe.Base using (Maybe; just; nothing)
open import Data.Vec.Base as V using ()
open import Relation.Binary.PropositionalEquality using (_≡_; refl; cong; sym; trans)

private
  variable
    A B C : Set

------------------------------------------------------------------------
-- §1 Stream = 构造子装延迟:♯_ 是"生产额度",♭ 是"消费授权"

data Stream (A : Set) : Set where
  _∷_ : (x : A) (xs : ∞ (Stream A)) → Stream A

-- 合法余递归:递归调用整体在 ♯_ 之下(guarded)
ones : Stream ℕ
ones = 1 ∷ ♯ ones

natsFrom : ℕ → Stream ℕ
natsFrom n = n ∷ ♯ natsFrom (suc n)

-- 非法形态(正文 §2 贴实测报错,此处不落源码):
--   bad = 1 ∷ ♯ tail bad  -- 递归穿过 ♭ 泄漏,终止检查拒绝

------------------------------------------------------------------------
-- §2 生产者:构造无限流;消费者:从无限流榨取有限值

smap : (A → B) → Stream A → Stream B
smap f (x ∷ xs) = f x ∷ ♯ smap f (♭ xs)

szipWith : (A → B → C) → Stream A → Stream B → Stream C
szipWith _∙_ (x ∷ xs) (y ∷ ys) = (x ∙ y) ∷ ♯ szipWith _∙_ (♭ xs) (♭ ys)

-- 消费者在 ℕ 上结构递归,对 Stream 只做 ♭(只读不生产)
stake : (n : ℕ) → Stream A → V.Vec A n
stake zero    xs       = V.[]
stake (suc n) (x ∷ xs) = x V.∷ stake n (♭ xs)

-- 消费结果全部可算(类型检查器就是求值机):
five-nats : stake 5 (natsFrom 0) ≡ (0 V.∷ 1 V.∷ 2 V.∷ 3 V.∷ 4 V.∷ V.[])
five-nats = refl

five-ones : stake 5 ones ≡ (1 V.∷ 1 V.∷ 1 V.∷ 1 V.∷ 1 V.∷ V.[])
five-ones = refl

-- 消费者与生产者可交换:引理在 n 上归纳,等式两边逐层 ♭
stake-smap : (f : A → B) (n : ℕ) (xs : Stream A) →
             stake n (smap f xs) ≡ V.map f (stake n xs)
stake-smap f zero    xs       = refl
stake-smap f (suc n) (x ∷ xs) = cong (f x V.∷_) (stake-smap f n (♭ xs))

-- 逐位相加流的前缀也可算
sz3 : stake 3 (szipWith _+_ ones (natsFrom 0)) ≡
      (1 V.∷ 2 V.∷ 3 V.∷ V.[])
sz3 = refl

-- ♭ 后转 Colist:无限流 → 有限前缀列(也是生产性的)
fromStream : Stream A → Colist A
fromStream (x ∷ xs) = x ∷ ♯ fromStream (♭ xs)

------------------------------------------------------------------------
-- §3 互模拟 _~_:流的"相等"要一层层对齐着证

data _~_ {A : Set} : Stream A → Stream A → Set where
  _∷_ : {x y : A} {xs ys : ∞ (Stream A)} →
        x ≡ y → ∞ (♭ xs ~ ♭ ys) → (x ∷ xs) ~ (y ∷ ys)

refl-~ : (xs : Stream A) → xs ~ xs
refl-~ (x ∷ xs) = refl ∷ ♯ refl-~ (♭ xs)

sym-~ : {xs ys : Stream A} → xs ~ ys → ys ~ xs
sym-~ (x≡ ∷ xs≈) = sym x≡ ∷ ♯ sym-~ (♭ xs≈)

trans-~ : {xs ys zs : Stream A} → xs ~ ys → ys ~ zs → xs ~ zs
trans-~ (x≡ ∷ xs≈) (y≡ ∷ ys≈) = trans x≡ y≡ ∷ ♯ trans-~ (♭ xs≈) (♭ ys≈)

-- 非平凡的互模拟:逐位 +1 把 0,1,2,… 变成 1,2,3,…
-- 参数化在 n 上,归纳假设与证明义务逐层严格咬合(正文 §5 讨论)
smap-suc : (n : ℕ) → smap suc (natsFrom n) ~ natsFrom (suc n)
smap-suc n = refl ∷ ♯ smap-suc (suc n)

-- 互模拟自反性的具体用法
ones-~ : ones ~ ones
ones-~ = refl-~ ones

-- sym/trans 组合出反向与传递闭包实例
nats-~ : natsFrom 1 ~ smap suc (natsFrom 0)
nats-~ = sym-~ (smap-suc 0)

nats-~= : natsFrom 1 ~ natsFrom 1
nats-~= = trans-~ nats-~ (sym-~ nats-~)

------------------------------------------------------------------------
-- §4 Conat 彩排:可以"永远数不完"的自然数

data Coℕ : Set where
  cozero : Coℕ
  cosuc  : (n : ∞ Coℕ) → Coℕ

infinity : Coℕ
infinity = cosuc (♯ infinity)

two : Coℕ
two = cosuc (♯ cosuc (♯ cozero))

-- 观测器:只允许看 bound 层,看不完返回 nothing
lower : (bound : ℕ) → Coℕ → Maybe ℕ
lower zero    n         = nothing
lower (suc b) cozero    = just zero
lower (suc b) (cosuc n) with lower b (♭ n)
...                       | just m  = just (suc m)
...                       | nothing = nothing

lower-two : lower 5 two ≡ just 2
lower-two = refl

lower-inf : lower 100 infinity ≡ nothing
lower-inf = refl

------------------------------------------------------------------------
-- §5 Costring 与 IO --guardedness 的正式回收

-- Costring = 可能无限的字符流(stdlib 定义:Colist Char)
-- 有限 String 只能整体进入,Costring 可以边产边消费
open import IO using (IO; _>>=_; _>>_)
open import Data.Unit.Polymorphic using (⊤)
open import IO.Infinite using ()
  renaming (getContents to getContents∞; putStr to putStr∞)

-- 有限→无限的安全注入(Agda 顶层作用域按声明顺序解析,引用必须在前面)
finiteCostring : Costring
finiteCostring = toCostring "hello"

cat : IO ⊤
cat = do
  putStr∞ finiteCostring
  s ← getContents∞
  putStr∞ s

-- 对照:stdlib 自家的 Stream(与 §1 手搓版同构),take 也可算
open import Codata.Musical.Stream as Std using ()
  renaming (Stream to SStream; take to stake′; repeat to repeat′)
open import Data.Vec.Base using (_∷_; [])

std-ones : SStream ℕ
std-ones = repeat′ 1

std-take : stake′ 3 std-ones ≡ (1 ∷ 1 ∷ 1 ∷ [])
std-take = refl
