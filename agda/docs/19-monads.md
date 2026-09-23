# 19 · Functor/Applicative/Monad

到上一章为止，我们见过了 Agda 表达「结构」的标准姿势：18 章的代数簿
（Semigroup/Monoid/Ring）是**载体集合 + 运算 + 定律**的 record 打包。本章
看同一族思想的另一个分身：把「结构」套在**类型构造子** `F : Set → Set`
上——Functor、Applicative、Monad。Haskell 用 type class 实现这三个词，
Agda **没有 type class**，一切靠显式 record 参数传递——这恰好是 9 章
「记录即接口」和 18 章「结构即值」两条线的汇合点。本章还会实测一个重要
发现：Agda 2.8 的 do 记号是**内建语法**，stdlib 2.3 里没有任何一行
`syntax` 声明为它背书，它脱糖时只认作用域里的 `_>>=_`——选哪个 Monad
实例，完全由你 open 了什么决定。

对应示例：`../examples/Ex19_monads.agda`

本章所有代码片段均与示例文件一致；报错文本均为实测原样粘贴。

## 19.1 Effect 模块族的地图

stdlib 2.3 实测的目录结构（`/usr/share/agda-stdlib/src/Effect/`）：

```text
Effect/Functor.agda      Effect/Applicative.agda   Effect/Monad.agda
Effect/Functor/          Effect/Applicative/       Effect/Choice.agda
  Predicate.agda           Indexed.agda Predicate   Effect/Empty.agda
Effect/Monad/            Effect/Foldable.agda      Effect/Comonad.agda
  State/ Reader/ Writer/ IO/ Identity/ Error/
  Continuation/ Partiality/ Indexed/ Predicate/
```

三件事要先钉死：

1. **层级靠字段嵌套**：`RawApplicative` 有字段 `rawFunctor : RawFunctor F`，
   `RawMonad` 有字段 `rawApplicative : RawApplicative F`——想构造一个
   Monad 就得先交出下两层（或事后升级，见 19.2 的 `mkRawMonad` 捷径）。
2. **`Raw` 前缀 = 不含定律**。`Effect/Functor.agda` 与 `Effect/Monad.agda`
   文件头注释原话「Note that currently the functor/monad laws are
   **not included** here」——只约束有运算，不约束运算满足定律；定律版
   在 `Axiom.Monad` 等模块另讲，日常编程基本用 `Raw*`。
3. **实例住在数据这边**：`Data.Maybe.Effectful`、`Data.List.Effectful`、
   `Data.Vec.Effectful`… 命名清一色 `functor / applicative / monad /
   monadZero / monadPlus`。本章示例故意**不走现成实例**，从字段手工
   搭一遍，这样你知道每个零件放在哪。

## 19.2 record 定义 Monad：没有 class，也就没有「隐式选实例」

先看 stdlib 里 Monad 的真身（`Effect/Monad.agda` 实测摘录）：

```agda
record RawMonad (F : Set f → Set g) : Set (suc f ⊔ g) where
  field
    rawApplicative : RawApplicative F
    _>>=_ : F A → (A → F B) → F B

  open RawApplicative rawApplicative public
  -- 定义体（非字段）派生：_>>_、=<<、>=>、<=<、Kleisli、when、unless
```

对比 Haskell：

```haskell
class Monad m where        -- type class：一个类型只能有一个实例，
  return :: a -> m a       -- 调用点由编译器隐式解析
  (>>=)  :: m a -> (a -> m b) -> m b
```

Agda 这边 `RawMonad` 是个**普通 record 值**：`maybeMonad`、`listMonad`
都是「Monad 这个类型的居民」。要用哪个实例，写在明面上——函数可以
像收普通参数一样收它（19.7 的 `Trans.monad maybeMonad` 就是）。Haskell
的 `instance Monad Maybe` 是全局唯一登记，Agda 的 `maybeMonad` 只是个
可以复制、改名、塞进模块的局部值——9 章「record 即接口」的应用题。

手工实例化 Maybe 三层（示例 §1，注意 universe 注解，19.9 坑 5 解释它
为什么不能省）：

```agda
maybeFunctor : RawFunctor {ℓ = 0ℓ} {ℓ′ = 0ℓ} Maybe
maybeFunctor = record { _<$>_ = Maybe.map }

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
```

record 字段**顺序随意、可缺省**——但只允许事后能被别处约束的字段，
这里 `rawApplicative` 与 `_>>=_` 一个都不能少。偷懒通道是
`mkRawMonad : (F) → (pure) → (bind) → RawMonad F`：只给两个运算，
applicative 层自动用 `do` 补出来（`Effect/Monad.agda` 源码如此）。

List 是同一套骨架换零件（示例 §2）：

```agda
listApplicative : RawApplicative {f = 0ℓ} {g = 0ℓ} List
listApplicative = record
  { rawFunctor = listFunctor
  ; pure       = List.[_]
  ; _<*>_      = List.ap
  }
-- listMonad 同形：_>>=_ = flip List.concatMap
```

## 19.3 每层的算子清单（实测名 + 实测坑）

| 层 | 必给字段 | record 体里白送的派生 |
|---|---|---|
| `RawFunctor` | `_<$>_` | `<$_`（写作 `<$`）、`<&>_`（写作 `<&>`）、`ignore` |
| `RawApplicative` | `rawFunctor`、`pure`、`_<*>_` | `⊛`、`<*`、`*>`、`zipWith`、`zip`（`⊗`）、`return` |
| `RawMonad` | `rawApplicative`、`_>>=_` | `>>`、`=<<`、`>=>`、`<=<`、`Kleisli`、`when`、`unless` |

`join` 是个例外——它**不在字段里**，因为 `join : F (F A) → F A` 只有当
`F` 的类型两层宇宙相等（`g = f`）时才存在，所以 stdlib 把它放进参数化
模块：

```agda
-- When level g=f, a join/μ operator is definable
module Join {F : Set f → Set f} (M : RawMonad F) where
  join : F (F A) → F A
  join = _>>=_ id
```

示例 §3–§5 用 refl 逐个打卡（这就是 Agda 的「跑一遍看输出」）：

```agda
add1-just : ((λ x → x + 1) <$> just 41) ≡ just 42
add1-just = refl
flip-bind : (just 10 <&> λ x → x + 1) ≡ just 11
flip-bind = refl
right-unit : (just 5 >>= pure) ≡ just 5
right-unit = refl
join-just  : Join.join maybeMonad (just (just 7)) ≡ just 7
join-just  = refl
```

实测坑一：**`<$_` 不是照着名字敲**。record 里字段叫 `_<$_`，你在源码
里写的却是 `<$`；把 `_<$_` 整体当运算符用会当场翻车——实测报
`NoParseForApplication`：`Could not parse the application 0 <$_ (just 99)`，
错误信息还附了算子表（`<$` 是 postfix operator section, level 4）。

实测坑二：这些算子全是 **level 4**，和 `_≡_` 平级，等式左边不套括号
直接语法错误——实测报 `Could not parse the application
(λ x → x + 1) <$> just 41 ≡ just 42`，并列出参与竞争的算子表。

## 19.4 Applicative：平行组合与列表叉积

`<*>`（ASCII 写法 `⊛ = \circledast` 是同一函数的 Unicode 别名）的精髓是
**组合子之间没有数据依赖**：函数已经在上下文里了，只差喂参。柯里化
函数逐个喂（示例 §4）：

```agda
two-track : ((pure _+_ ⊛ just 10) ⊛ just 1) ≡ just 11
two-track = refl
```

而 `⊗`（字段 `zip`，由 `zipWith f x y = f <$> x <*> y` 派生）在 List 上
就是**笛卡尔积**——不是 `Data.List` 那个「短的对齐」zip：

```agda
cross  : List (ℕ × ℕ)
cross  = (1 ∷ 2 ∷ []) ⊗ (10 ∷ 100 ∷ [])

cross≡ : cross ≡ ((1 , 10) ∷ (1 , 100) ∷ (2 , 10) ∷ (2 , 100) ∷ [])
cross≡ = refl
```

`Data.List.zipWith` 给的是 `((1 , 10) ∷ (2 , 100) ∷ [])`——同名不同货，
一个截断一个叉乘，写代码时认准你 open 的是哪层。`<*` 留左丢右、
`*>` 丢左留右，同样是叉积之后再筛（`keep-left≡ = refl`：
`[1,2] <* [9,9] ≡ [1,1,2,2]`，先配对再丢右，元素按叉积翻倍）。

Monad 也能表达同样的叉积（19.5 的 `crossM≡`），区别在**意图**：
Applicative 声明「这些效应互相独立、可并行/可重排」，Monad 声明
「后者依赖前者」。`RawMonad` 提供 `rawApplicative` 字段（且
`_>>_ = _*>_`），所以任何 Monad 都是 Applicative——方向永远单向。

## 19.5 do 记号：内建语法糖，脱糖只认 `_>>=_`

先实测一个反直觉的事实：在 stdlib 2.3 全库 grep `syntax`，**找不到**
任何 `do` 的语法声明——do 记号是 Agda 2.6.2 起**内建在解析/脱糖阶段**
的，不来自任何库。于是它的名字查找规则非常朴素：脱糖结果里出现的
`_>>=_` 就是**词法作用域里那个 `_>>=_`**。

规则集（示例 §6 全部实测）：

- `x ← e` 开头的行：脱糖成 `e >>= λ x → 其余语句`；
- `let x = …` 行：只加定义，不产生任何 bind；
- 裸表达式行（后面还有语句）：脱糖成丢弃结果的 bind；
- **最后一行必须是一个表达式**，原样保留——脱糖器不会替你补
  `pure/return`。只写 `do x ← e` 会撞上实测错误：

```text
examples/Tmp19e.agda:21.7-22.8: error: [DoNotationError]
The last statement in a 'do' block must be an expression or an
absurd match.
```

由此推论：`ret`？stdlib 2.3 的 `Effect.Monad` 根本没有这个字段（grep
零命中），老书里的 `ret (x + 1)` 是一版前的遗产名；现在的名字是
`pure`（`return` 是它的别名，挂在 `RawApplicative` 里）。

布局式 do 的三件套（Maybe 顺序短路 / let / List 枚举）：

```agda
module MaybeDo where
  open RawMonad maybeMonad

  chain : Maybe ℕ
  chain = do
    x ← pure 1
    y ← just (x + 1)
    pure (x + y)          -- ≡ just 3

  short : Maybe ℕ
  short = do
    x ← nothing
    pure (x + 1)          -- ≡ nothing，中途失败整块短路

module ListDo where
  open RawMonad listMonad

  crossM : List (ℕ × ℕ)
  crossM = do
    x ← 1 ∷ 2 ∷ []
    y ← 10 ∷ 100 ∷ []
    pure (x , y)          -- 叉积；示例另以 crossM≡ = refl 证 crossM ≡ ListApp.cross
```

**坑三（本章标题级）**：同一个 `do { x ← pure 1; pure (x + 1) }` 写进
不同文件，含义由作用域里的 `_>>=_` 决定。`MaybeDo` 里它是「顺序且可
短路」，`ListDo` 里它是「枚举所有组合」。Agda 不做任何解析——它就是
字面替换。两个候选同时在场时反而安全，因为会直接歧义报错（实测，
示例初稿真的撞上过）：

```text
examples/Ex19_monads.agda:135.24-27: error: [AmbiguousName]
Ambiguous name _>>=_. It could refer to any one of
  Ex19_monads.MonadDemo._>>=_ bound at
    /usr/share/agda-stdlib/src/Effect/Monad.agda:35.5-10
  Maybe._>>=_ bound at
    /usr/share/agda-stdlib/src/Data/Maybe/Base.agda:92.1-6
```

这个报错要背下来：**它不是坏消息，是护栏**——Haskell 里实例选择发生
在编译器内部，Agda 把它变成作用域问题，冲突当场报告。反面是：只要
**恰好一个**候选在作用域里，do 就悄悄用它，语义漂移没人拦——示例
坚持每个用法圈一个子模块（`MaybeDo`/`ListDo`）。

实测坑四：**花括号多语句不合法**。想写 Haskell 式 `do { x ← e ; e′ }`：
`do { …`（有空格）时 `{ }` 被解析成**隐式实参**，报
`{just 1} cannot appear by itself. It needs to be the argument to a
function expecting an implicit argument.`（HiddenNotInArgumentPosition）；
紧贴的 `do{ … }` 只收**单条表达式**，一旦内部出现绑定加 `;`，就在第一个
`;` 处报 `ParseError: expected sequence of bound identifiers`。结论：
多语句 do 请用布局（换行缩进）形式，这是 Agda 的正门。

## 19.6 带零与选择的 Monad：`empty` 与 `<|>`

`Effect/Empty.agda`、`Effect/Choice.agda` 提供 `RawEmpty`（字段 `empty`）
和 `RawChoice`（字段 `_<|>_`，源码里符号写作 `<|>`），叠上 Monad 就是
`RawMonadZero` / `RawMonadPlus`；Applicative 侧的对应层
`RawApplicativeZero` 还白送一个 `guard : Bool → F ⊤`（false 即 empty）。
Maybe 的实例（示例 §1 末尾）：

```agda
maybeMonadPlus : RawMonadPlus {f = 0ℓ} {g = 0ℓ} Maybe
maybeMonadPlus = record
  { rawMonadZero = maybeMonadZero
  ; rawChoice    = record { _<|>_ = _<∣>_ }
  }

module PlusDemo where
  open RawMonadPlus maybeMonadPlus

  rescue  : Maybe ℕ
  rescue  = first-try <|> pure 42        -- first-try = nothing，≡ just 42
  empty0  : empty {A = ℕ} ≡ nothing
```

List 的对应物里 `empty = []`、`<|> = _++_`——`<|>` 就是「换下一个
备选」。这是 `Alternative` 家族，Haskell 的 `<|>` 同义。

## 19.7 变换器风格：把两层效应叠成一个 Monad

Monad 不好直接叠加（`Maybe (IO A)` 没有标准 bind），函数式语言的通用
答案是 **monad transformer**：`T` 吃一个下层 Monad `M` 吐出一个新 Monad。
stdlib 把这件事做成两个 record（`Effect/Monad.agda` 源码实测）：

```agda
record RawMonadTd (F : Set f → Set g₁) (TF : Set f → Set g₂) : Set (suc f ⊔ g₁ ⊔ g₂) where
  field
    lift     : F A → TF A
    rawMonad : RawMonad TF
  open RawMonad rawMonad public

RawMonadT : (T : (Set f → Set g₁) → (Set f → Set g₂)) → Set (suc f ⊔ suc g₁ ⊔ g₂)
RawMonadT T = ∀ {M} → RawMonad M → RawMonadTd M (T M)
```

`RawMonadT` 就是「变换器」的类型：一个函数，收任意下层 Monad，返回
「带 lift 的新 Monad」。`lift` 字段负责把下层计算抬进栈。

示例 §8 没有 postulate 任何玩具，用的是 stdlib 真货
`Effect.Monad.State.Transformer`，搭一个「携带 ℕ 状态、可失败」的两层
栈 `StateT ℕ Maybe`：

```agda
module StackDemo where
  S : Set
  S = ℕ

  mon : RawMonad (StateT S Maybe)
  mon = Trans.monad maybeMonad          -- 下层显式传入，这就是「无 class」的代价与自由

  open RawMonad mon
  open RawMonadState (Trans.monadState {S = S} maybeMonad)

  program : StateT S Maybe ℕ
  program = do
    n ← get
    put (n + 1)
    m ← get
    pure (m + m)

  program-from-3 : runStateT program 3 ≡ just (4 , 8)
  program-from-3 = refl

  lifted : StateT S Maybe ℕ
  lifted = Trans.monadT {S = S} maybeMonad .RawMonadTd.lift (just 10)
  -- 示例另证 lifted≡ : runStateT lifted 0 ≡ just (0 , 10)
```

`get/put/modify` 来自 `RawMonadState` record（字段只有 `gets` 和
`modify`，`get = gets id`、`put = modify ∘′ const` 是派生）。`lift`
把纯 Maybe 计算嵌进栈，状态原样穿过。对照 Haskell：mtl 靠
`MonadState`/`MonadTrans` 类把 `get`、`lift` 隐式解析出来；Agda 这边
每一层「谁是谁的实例」都是函数实参。于是 `StateT S Maybe` 和
`MaybeT (StateT S)`（若存在）是两个不同的值、两种失败语义——**栈的
次序写在类型里**，不存在「让 GHC 猜」。

## 19.8 三方对照速查表

| 概念 | Haskell | Agda（stdlib 2.3 实测） | 备注 |
|---|---|---|---|
| Functor | `class Functor f where fmap` | `record RawFunctor F where _<$>_` | 无定律字段 |
| 白送算子 | `<$` | `<$_`（源码符号 `<$`）、`<&>`、`ignore` | 名字别照 record 敲 |
| Applicative | `class Applicative`，`<*>` `pure` | `record RawApplicative`，`_<*>_` `pure` | 另有 `⊛` 别名、`⊗ = zip` |
| Monad | `class Monad`，`return`/`>>=` | `record RawMonad`，`pure`/`_>>=_` | `return = pure` 是派生别名 |
| join | `Control.Monad.join` | `Join.join M`（参数化模块） | 宇宙层数条件 |
| 实例声明 | `instance Monad Maybe`（全局唯一） | `maybeMonad : RawMonad Maybe`（普通值） | 可多份、可传参 |
| do 记号 | 关键字 + 类解析 | 内建脱糖，只认作用域 `_>>=_` | 尾句须是表达式 |
| 变换器 | `class MonadTrans` + mtl | `RawMonadT` + 显式传参 | 栈序在类型里 |
| 定律 | 无（约定俗成） | 无（`Raw*`；另见 `Axiom.*`） | refl 抽查具体点 |

## 19.9 坑位清单（本项目实测）

1. **`ret` 已死**：stdlib 2.3 的 Effect 家族全库无 `ret` 字段，
   do 尾句请写 `pure`/`return`；老教程（≈ stdlib 1.x）照抄必
   `NotInScope`。
2. **do 尾句必须是表达式**：脱糖器不补 return，`do x ← e` 报
   `DoNotationError`；末尾自动 `pure` 是 Haskell 的惯性，别带过来。
3. **花括号 do 不可用**：`do { … ; … }` 的空格版被解析成隐式实参
   （`HiddenNotInArgumentPosition`），`do{ … ; … }` 多语句报
   `expected sequence of bound identifiers`——多语句只认布局式。
4. **实例选择 = 作用域管理**：do 没有类型类解析，`_>>=_` 谁在
   用谁；两个候选歧义报错（护栏），一个候选则完全静默——
   每个 do 用法圈进自己的小 module（示例的 `MaybeDo`/`ListDo` 模式）。
5. **宇宙层级要手动钉**：`RawFunctor Maybe` 不写 `{ℓ = 0ℓ} {ℓ′ = 0ℓ}`
   时，metavariable 常常无解，报错是 `UnsolvedMetaVariables` 且指向
   record 类型那一行的两个宇宙位——实例值不像 class 有默认单态化，
   该标就标。
6. **算子名与 level 都要留心**：`_<$_` 的运算符符号是 `<$`，写
   `0 <$_ just 99` 直接 `NoParseForApplication`；`<$>`/`<*>`/`⊛` 全是
   level 4、和 `_≡_` 平级，等式左边必须整体加括号；grep 源码时
   `<*>` 与别名 `⊛` 两种写法都要搜。
7. **join 不在 record 里**：它住在 `module Join (M : RawMonad F)`，
   用法 `Join.join maybeMonad …`；在 `open RawMonad` 之后裸打 `join`
   会 NotInScope（它根本不是什么字段）。
8. **`Data.List` 的 zip 与 applicative 的 `⊗` 同名异实**：前者截断、
   后者叉积；`crossM ≡ ListApp.cross` 只在 List 的这套 ap/concatMap
   实现下**恰好**成立（本例 refl 可证），换实例就没有免费午餐。

---
上一章：[18 · 关系代数与抽象代数](18-algebra.md) ｜ 下一章：[20 · IO 与真实程序](20-io.md) ｜ 返回：[README](../README.md)
