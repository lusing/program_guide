------------------------------------------------------------------------
-- Ex19 · Functor / Applicative / Monad:Effect 模块族与 do 记号
--
-- 用显式 record 手工实例化 Maybe 与 List 的三层结构,并用 do 记号、
-- applicative 平行组合、Kleisli 箭头、StateT 变换器栈驱动它们。
-- 所有等式都以 refl 结束——这就是 Agda 版的「跑一遍看输出」。
------------------------------------------------------------------------

module Ex19_monads where

open import Effect.Functor     using (RawFunctor)
open import Effect.Applicative using (RawApplicative)
open import Effect.Monad       using (RawMonad; RawMonadZero; RawMonadPlus;
                                      RawMonadTd; module Join)
open import Effect.Monad.State.Transformer as Trans
  using (StateT; runStateT; evalStateT; RawMonadState)
open import Data.Nat           using (ℕ; _+_; suc)
open import Data.Maybe.Base    as Maybe using (Maybe; just; nothing; _<∣>_)
open import Data.List.Base     as List using (List; []; _∷_; concatMap; ap)
open import Data.Product.Base  using (_×_; _,_)
open import Data.Unit.Polymorphic using (⊤; tt)
open import Function.Base      using (const; flip)
open import Level              using (0ℓ)
open import Relation.Binary.PropositionalEquality using (_≡_; refl)

------------------------------------------------------------------------
-- 1. 三层结构都是 record:只填最小的字段,派生算子自动到位

maybeFunctor : RawFunctor {ℓ = 0ℓ} {ℓ′ = 0ℓ} Maybe
maybeFunctor = record { _<$>_ = Maybe.map }

-- _<*>_ 用 _>>=_ 展开,语义与 stdlib 的「只有两边都成功才有结果」一致
maybeApplicative : RawApplicative {f = 0ℓ} {g = 0ℓ} Maybe
maybeApplicative = record
  { rawFunctor = maybeFunctor
  ; pure       = just
  ; _<*>_      = λ f x → Maybe._>>=_ f λ g → Maybe._>>=_ x λ y → just (g y)
  }

maybeMonad : RawMonad {f = 0ℓ} {g = 0ℓ} Maybe
maybeMonad = record
  { rawApplicative = maybeApplicative
  ; _>>=_          = Maybe._>>=_
  }

-- Maybe 还带 zero(nothing)与 choice(_<∣>_),合成 MonadPlus
maybeMonadZero : RawMonadZero {f = 0ℓ} {g = 0ℓ} Maybe
maybeMonadZero = record
  { rawMonad = maybeMonad
  ; rawEmpty = record { empty = nothing }
  }

maybeMonadPlus : RawMonadPlus {f = 0ℓ} {g = 0ℓ} Maybe
maybeMonadPlus = record
  { rawMonadZero = maybeMonadZero
  ; rawChoice    = record { _<|>_ = _<∣>_ }
  }

------------------------------------------------------------------------
-- 2. List 的同构三层:纯函数版「非确定性选择」

listFunctor : RawFunctor {ℓ = 0ℓ} {ℓ′ = 0ℓ} List
listFunctor = record { _<$>_ = List.map }

listApplicative : RawApplicative {f = 0ℓ} {g = 0ℓ} List
listApplicative = record
  { rawFunctor = listFunctor
  ; pure       = List.[_]
  ; _<*>_      = List.ap
  }

listMonad : RawMonad {f = 0ℓ} {g = 0ℓ} List
listMonad = record
  { rawApplicative = listApplicative
  ; _>>=_          = flip List.concatMap
  }

------------------------------------------------------------------------
-- 3. Functor 算子:<$> 与它的两个兄弟 <$、<&>

module FunctorDemo where
  open RawFunctor maybeFunctor

  add1-just : ((λ x → x + 1) <$> just 41) ≡ just 42
  add1-just = refl

  flip-bind : (just 10 <&> λ x → x + 1) ≡ just 11
  flip-bind = refl

  constant : (0 <$ just 99) ≡ just 0
  constant = refl

  -- ignore 把任意效应压成 F ⊤(丢弃结果,保留形状)
  ignore-just : ignore (just 42) ≡ just tt
  ignore-just = refl

------------------------------------------------------------------------
-- 4. Applicative 算子:⊛ 平行组合;⊗ = zip 在 List 上是叉积

module MaybeApp where
  open RawApplicative maybeApplicative

  par : ((just suc) ⊛ (just 1)) ≡ just 2
  par = refl

  -- 柯里化的纯函数用 ⊛ 逐个喂参数:组合之间没有数据依赖
  two-track : ((pure _+_ ⊛ just 10) ⊛ just 1) ≡ just 11
  two-track = refl

module ListApp where
  open RawApplicative listApplicative

  -- ⊗ 把左右两个「选择集」两两配对(2×2 = 4)
  cross : List (ℕ × ℕ)
  cross = (1 ∷ 2 ∷ []) ⊗ (10 ∷ 100 ∷ [])

  cross≡ : cross ≡ ((1 , 10) ∷ (1 , 100) ∷ (2 , 10) ∷ (2 , 100) ∷ [])
  cross≡ = refl

  -- <* 留左丢右:先叉积,再按元素筛掉右边的结果
  keep-left : List ℕ
  keep-left = (1 ∷ 2 ∷ []) <* (9 ∷ 9 ∷ [])

  keep-left≡ : keep-left ≡ (1 ∷ 1 ∷ 2 ∷ 2 ∷ [])
  keep-left≡ = refl

------------------------------------------------------------------------
-- 5. Monad 算子:>>=、Kleisli 箭头 >=>、join

module MonadDemo where
  open RawMonad maybeMonad

  sucM : ℕ → Maybe ℕ
  sucM n = just (suc n)

  right-unit : (just 5 >>= pure) ≡ just 5
  right-unit = refl

  left-unit : (pure 5 >>= sucM) ≡ sucM 5
  left-unit = refl

  kleisli : (sucM >=> sucM) 0 ≡ just 2
  kleisli = refl

  kleisli-flip : (sucM <=< sucM) 0 ≡ just 2
  kleisli-flip = refl

  -- join 不在 RawMonad 字段里,而在参数化模块 Join 中(避免命名冲突)
  join-just : Join.join maybeMonad (just (just 7)) ≡ just 7
  join-just = refl

------------------------------------------------------------------------
-- 6. do 记号:Agda 2.8 内建语法,脱糖成作用域里的 _>>=_ 与 pure

module MaybeDo where
  open RawMonad maybeMonad

  chain : Maybe ℕ
  chain = do
    x ← pure 1
    y ← just (x + 1)
    pure (x + y)

  chain≡ : chain ≡ just 3
  chain≡ = refl

  -- 中途 nothing:整块短路,后面的语句根本不执行
  short : Maybe ℕ
  short = do
    x ← nothing
    pure (x + 1)

  short≡ : short ≡ nothing
  short≡ = refl

  -- let 语句只加定义,不加效应
  with-let : Maybe ℕ
  with-let = do
    x ← just 2
    let double = x + x
    pure double

  with-let≡ : with-let ≡ just 4
  with-let≡ = refl

module ListDo where
  open RawMonad listMonad

  -- 同一个「写法」,换实例就换语义:List 的 do 枚举所有组合
  crossM : List (ℕ × ℕ)
  crossM = do
    x ← 1 ∷ 2 ∷ []
    y ← 10 ∷ 100 ∷ []
    pure (x , y)

  -- do 版叉积与 applicative 版 ⊗ 结果一致(脱糖后本同源)
  crossM≡ : crossM ≡ ListApp.cross
  crossM≡ = refl

  fail-empty : List ℕ
  fail-empty = do
    x ← []
    pure x

  fail-empty≡ : fail-empty ≡ []
  fail-empty≡ = refl

------------------------------------------------------------------------
-- 7. MonadPlus:empty 与 <|> 给计算加上「换一个试试」

module PlusDemo where
  open RawMonadPlus maybeMonadPlus

  first-try : Maybe ℕ
  first-try = do
    x ← nothing
    pure (x + 1)

  rescue : Maybe ℕ
  rescue = first-try <|> pure 42

  rescue≡ : rescue ≡ just 42
  rescue≡ = refl

  rescue-noop : (just 1 <|> pure 42) ≡ just 1
  rescue-noop = refl

  empty-is-nothing : empty {A = ℕ} ≡ nothing
  empty-is-nothing = refl

------------------------------------------------------------------------
-- 8. 变换器栈:StateT ℕ Maybe = 「携带 ℕ 状态的可失败计算」
--    stdlib 的 StateT 是真正的 Monad 变换器:下层 RawMonad 显式传入,
--    Trans.monadT 提供 lift(RawMonadTd 记录的字段)。

module StackDemo where
  S : Set
  S = ℕ

  mon : RawMonad (StateT S Maybe)
  mon = Trans.monad maybeMonad

  open RawMonad mon
  open RawMonadState (Trans.monadState {S = S} maybeMonad)

  -- get / put / modify 由 RawMonadState 的两个字段 gets、modify 派生

  program : StateT S Maybe ℕ
  program = do
    n ← get
    put (n + 1)
    m ← get
    pure (m + m)

  program-from-3 : runStateT program 3 ≡ just (4 , 8)
  program-from-3 = refl

  -- lift:把下层纯 Maybe 计算嵌入栈(状态原样传递)
  lifted : StateT S Maybe ℕ
  lifted = Trans.monadT {S = S} maybeMonad .RawMonadTd.lift (just 10)

  lifted≡ : runStateT lifted 0 ≡ just (0 , 10)
  lifted≡ = refl

  -- evalStateT:只要结果不要终态(需要一个下层 RawFunctor)
  eval : Maybe ℕ
  eval = evalStateT maybeFunctor program 3

  eval≡ : eval ≡ just 8
  eval≡ = refl

------------------------------------------------------------------------
-- 9. 与 Haskell 的三方对照(注释版速查):
--
--   Haskell   class Functor f where fmap        -- 隐式实例,一型一实例
--   Agda      record RawFunctor F where _<$>_   -- 显式值,想要哪个传哪个
--   Haskell   main = do { x ← readLn ; print x }
--   Agda      main = run $ do x ← getLine ; ...  -- do 内建,脱糖找 >>=/pure
--
-- do 的语义由当前作用域里 open 的是哪个 RawMonad 记录决定——
-- 见 MaybeDo(顺序短路)与 ListDo(枚举组合)的对比。
