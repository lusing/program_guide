# 22 · 余归纳与无限流

07 章的终止性检查说：递归调用必须"变小"——消耗的对象要结构递减。这一章看它的**镜像**：
如果递归不是在"消费"已有数据，而是在"生产"永远生产不完的对象（无限流、永不退出的服务），
标准就反过来——每层递归在走完下一步观测之前，必须先产出一个构造子。这就是
**guardedness（保序条件）**。Agda 对余归纳显式 opt-in：文件第一行
`{-# OPTIONS --guardedness #-}`，再用 Codata.Musical 的乐符记法 `♯_`（延迟盒子）/`♭`
（拆盒）控制哪里生产、哪里消费。本章从 `Stream ℕ` 的全 1 流讲到 bisimilarity，最后回收
02/20 章的伏笔——IO 和它到底什么关系。

对应示例：`../examples/Ex22-codata.agda`

**文件名先交代一句**：本章示例是 `Ex22-codata.agda`（连字符），不是其他章节的 `ExNN_xxx` 下划线式——`codata`
在 Agda 2.8.0 是保留关键字，模块名下划线分段的每一段都不允许是关键字，探针 `TmpPr22_codata.agda` 实
测报错：

```text
in the name TmpPr22_codata, the part codata is not valid because it is a keyword
```

引号写法 `module Ex22_"codata"` 又不被 module 头语法接受（2.8.0 实测）。唯一出路是 04 章 `syntax`
同款处理：文件名/模块名用连字符——Agda 允许标识符里出现 `-`，`Ex22-codata` 是合法模块名。README 索引
表里的 `Ex22_codata.agda` 以本说明为准。

## 22.1 入场券：--guardedness pragma

示例文件的前两行就是本章第一道门：

```agda
{-# OPTIONS --guardedness #-}

module Ex22-codata where
```

没有第一行会怎样？只要 import 任何 `Codata.Musical.*`（或 `IO`），实测立刻被拒（探针
`Tmp22f.agda`，缺 pragma 只 import 记法模块）：

```text
error: [InfectiveImport]
Importing module Codata.Musical.Notation using the --guardedness
flag from a module which does not.
when scope checking the declaration
  open import Codata.Musical.Notation using (∞)
```

"Infective"（传染性）是 Agda 报错分类器的原话：开过 `--guardedness` 的模块会**污染**下游，这是有意
的防火墙。guardedness 放松的是终止检查的拒绝面（允许"永远在产"的定义），而终止检查是全语言一致性的
地基，放松必须逐文件签字画押。02 章说这行 pragma 是 "IO 的入场券"、20 章靠它换来 `forever` 式循环，
原因本章见分晓：**`IO` 的 stdlib 建模本身就长在 `∞` 上**（22.7 回收）。

示例的共享导入（§0 区块，本章各节都从这里面取名字）：

```agda
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
```

## 22.2 乐符记法：♯ 是生产额度，♭ 是消费授权

`Codata.Musical.Notation` 的全部真身是一行再导出，内容在编译器内置库
`/usr/share/libghc-agda-dev/lib/prim/Agda/Builtin/Coinduction.agda`：

```agda
infix 1000 ♯_

postulate
  ∞  : ∀ {a} (A : Set a) → Set a
  ♯_ : ∀ {a} {A : Set a} → A → ∞ A
  ♭  : ∀ {a} {A : Set a} → ∞ A → A

{-# BUILTIN INFINITY ∞  #-}
{-# BUILTIN SHARP    ♯_ #-}
{-# BUILTIN FLAT     ♭  #-}
```

三个都是 `postulate` + BUILTIN——和 21 章的 String 一样是"半原语"：逻辑上 ∞ 只是普通
类型构造器，但终止检查器**认标记**（SHARP/FLAT），知道 `♯_` 是延迟构造子、`♭` 是强制
（force）。心智模型：**`♯ x` 是"承诺以后给你 x"的 thunk 的类型版，`♭` 是兑现承诺**——
生产者每层递归前发新欠条，消费者凭欠条兑一次货。示例 §1 用这套记法手搓流：

```agda
data Stream (A : Set) : Set where
  _∷_ : (x : A) (xs : ∞ (Stream A)) → Stream A
```

和 06 章的 `List` 只差一个字：尾参数是 `∞ (Stream A)` 而非 `Stream A`——**类型层面**的延迟。`data`
声明本身合法（对终止检查这是普通归纳声明）；流的"无限"不来自类型系统漏洞，而来自下一节的生产者写
法。

## 22.3 guardedness：生产者的放行线与拒绝线

合法的两个流（示例 §1）：

```agda
-- 合法余递归:递归调用整体在 ♯_ 之下(guarded)
ones : Stream ℕ; ones = 1 ∷ ♯ ones
natsFrom : ℕ → Stream ℕ; natsFrom n = n ∷ ♯ natsFrom (suc n)
```

`ones` 的递归调用外面裹着 `♯`：每次观测先看到 `1 ∷`，剩下的"再说"——生产速度 ≥ 消耗
速度，永远不欠账。`natsFrom` 是"结构递归 + guarded 余递归"混体：`suc n` 变大没关系，
关键是递归结果整体进了 `♯`。

机器版 guarded 条件：**递归调用必须（类型检查器能看见地）直接位于 `♯_` 之下**；穿过 `♭`、藏在函数调
用里都算泄漏。示例注释钉了反面教材（探针 `Tmp22b.agda` 完整跑过，源码就是下面三行加一个 `tail`）：

```agda
tail : ∀ {A : Set} → Stream A → Stream A; tail (x ∷ xs) = ♭ xs
bad : Stream ℕ; bad = 1 ∷ ♯ tail bad   -- 递归穿过 ♭ 泄漏,终止检查拒绝
```
```text
error: [TerminationIssue]
Termination checking failed for the following functions:
  bad
Problematic calls:
  Tmp22b.♯-0 (at /…/Tmp22b.agda:15.11-12)
  bad (at /…/Tmp22b.agda:15.18-21)
```

`bad` 表面上递归也在 `♯` 下，但 `♯` 里装的是 `tail bad`——观测就是 `♭ (♯(tail bad)) = tail bad`，`tail`
把欠条当场拆掉再喂回去，"每层至少产一个构造子"的承诺被 `♭` 撤销；报错里 `♯-0` 是检查器指认"这个延迟
没保住"的位置。对照 `ones`：`♯ ones` 装的就是 `ones` 本身，`♭` 之后原样交付。
**经验法则：`♯` 里只放"裸的递归调用"，别放任何会拆箱的东西。**

## 22.4 生产者与消费者：smap / szipWith / take

示例 §2 三件套。前两个是生产者（递归在 `♯` 下，guarded）：

```agda
smap : (A → B) → Stream A → Stream B; smap f (x ∷ xs) = f x ∷ ♯ smap f (♭ xs)
szipWith : (A → B → C) → Stream A → Stream B → Stream C
szipWith _∙_ (x ∷ xs) (y ∷ ys) = (x ∙ y) ∷ ♯ szipWith _∙_ (♭ xs) (♭ ys)
```

套路：模式匹配拿到 `xs : ∞ (Stream B)` 后立刻 `♭ xs` 兑现再递归——但**兑现发生在参数位**，递归结果重
新装箱 `♯ smap f (♭ xs)`，承诺额度没漏。这同时是**惰性**的精确刻画：不 `♭` 就不算，`f` 只在消费端要
下一个元素时被触发。消费者反过来：对 `ℕ` 结构递归（07 章正统检查），对流只 `♭` 不造：

```agda
-- 消费者在 ℕ 上结构递归,对 Stream 只做 ♭(只读不生产)
stake : (n : ℕ) → Stream A → V.Vec A n
stake zero    xs       = V.[]
stake (suc n) (x ∷ xs) = x V.∷ stake n (♭ xs)
```

`stake` 就是 `take`（示例为避免与 stdlib 版混线而改名，22.7 末尾并排看）。返回 `V.Vec A n`——**长度索引**
（16 章）保证"恰好取 n 个"。消费结果全部可算（类型检查器就是求值机）：

```agda
-- 消费结果全部可算(类型检查器就是求值机):
five-nats : stake 5 (natsFrom 0) ≡ (0 V.∷ 1 V.∷ 2 V.∷ 3 V.∷ 4 V.∷ V.[]); five-nats = refl
five-ones : stake 5 ones ≡ (1 V.∷ 1 V.∷ 1 V.∷ 1 V.∷ 1 V.∷ V.[]); five-ones = refl
```

生产和消费可以**交换**——这是定理，不是实例：

```agda
-- 消费者与生产者可交换:引理在 n 上归纳,等式两边逐层 ♭
stake-smap : (f : A → B) (n : ℕ) (xs : Stream A) → stake n (smap f xs) ≡ V.map f (stake n xs)
stake-smap f zero    xs       = refl
stake-smap f (suc n) (x ∷ xs) = cong (f x V.∷_) (stake-smap f n (♭ xs))
```

剧本是 13 章归纳的标准姿势：对 `n` 归纳。`zero` 情形两边算成 `V.[]`，refl 白送；`suc` 情形两边
whnf 后都是 `f x ∷ …`，`cong (f x ∷_)` 把目标约化为对 `♭ xs` 的归纳假设——递归出现在**参数** `♭ xs`
（结构子项）上完全合法，因为这是引理、受终止检查，不是余递归定义。逐层观测逐层对齐，正是余世界里的
"归纳"。混合运算的前缀也可算：

```agda
-- 逐位相加流的前缀也可算
sz3 : stake 3 (szipWith _+_ ones (natsFrom 0)) ≡ (1 V.∷ 2 V.∷ 3 V.∷ V.[]); sz3 = refl
```

（无限对象在有限窗口里和普通数据毫无区别。）§2 收尾一座桥，从无限流到"至多有限"的 Colist（List 的余
归纳表亲，定义同款只多一个 `∞`）：

```agda
-- ♭ 后转 Colist:无限流 → 有限前缀列(也是生产性的)
fromStream : Stream A → Colist A; fromStream (x ∷ xs) = x ∷ ♯ fromStream (♭ xs)
```

## 22.5 互模拟 _~_：流的"相等"要一层层对齐着证

先撞墙再给药。无限流能用普通等式 `≡` 说事吗？探针实测（`Tmp22d.agda`）：

```agda
probeA : ones ≡ (1 ∷ ♯ ones); probeA = refl   -- 报错!
```
```text
error: [UnequalTerms]
Tmp22d.♯-0 != Tmp22d.♯-2 of type ∞ (Stream ℕ)
when checking that the expression refl has type
ones ≡ 1 ∷ Tmp22d.♯-2
```

按理 `ones` 的定义就是 `1 ∷ ♯ ones`，为何关不掉？因为 `≡` 的可见计算是**有穷展开**：两侧各 whnf 一
步后，剩下的两个延迟盒子在检查器眼里是两个不同标记（`♯-0` 与 `♯-2`），它不做"把盒子永远对齐下去"的
共归纳推理。结论：**`≡` 太细，流相等要按观测定义**——bisimilarity（互模拟）：头相等、并且尾巴还
互模拟。示例 §3 手搓：

```agda
data _~_ {A : Set} : Stream A → Stream A → Set where
  _∷_ : {x y : A} {xs ys : ∞ (Stream A)} → x ≡ y → ∞ (♭ xs ~ ♭ ys) → (x ∷ xs) ~ (y ∷ ys)
```

读构造子：证两流互模拟 = 头相等证明 `x ≡ y`（头是普通归纳命题，refl/subst 随便用）+
一张**欠条** `∞ (♭ xs ~ ♭ ys)`——尾巴的证明义务也装箱，留给下一个观测者。于是三个基本性质各一段，且它们本身也是
guarded 余递归函数：

```agda
refl-~ : (xs : Stream A) → xs ~ xs; refl-~ (x ∷ xs) = refl ∷ ♯ refl-~ (♭ xs)
sym-~ : {xs ys : Stream A} → xs ~ ys → ys ~ xs; sym-~ (x≡ ∷ xs≈) = sym x≡ ∷ ♯ sym-~ (♭ xs≈)
trans-~ : {xs ys zs : Stream A} → xs ~ ys → ys ~ zs → xs ~ zs
trans-~ (x≡ ∷ xs≈) (y≡ ∷ ys≈) = trans x≡ y≡ ∷ ♯ trans-~ (♭ xs≈) (♭ ys≈)
```

非平凡的一枚——"全体 +1" 把 `0,1,2,…` 变 `1,2,3,…`：

```agda
-- 非平凡的互模拟:逐位 +1 把 0,1,2,… 变成 1,2,3,…
-- 参数化在 n 上,归纳假设与证明义务逐层严格咬合
smap-suc : (n : ℕ) → smap suc (natsFrom n) ~ natsFrom (suc n); smap-suc n = refl ∷ ♯ smap-suc (suc n)
```

妙处：引理参数化在有限量 `n : ℕ` 上，余递归的每层义务恰好用 `suc n` 兑现——**生产流的同时在生产证
明**，欠条和数字一起滚动。示例再把代数性质用起来钉三个实例：

```agda
ones-~ : ones ~ ones; ones-~ = refl-~ ones
nats-~ : natsFrom 1 ~ smap suc (natsFrom 0); nats-~ = sym-~ (smap-suc 0)
nats-~= : natsFrom 1 ~ natsFrom 1; nats-~= = trans-~ nats-~ (sym-~ nats-~)
```

bisimilarity 点到为止：`_~_` 是流的"合理相等"，stdlib `Codata.Musical.Stream` 里同款叫 `_≈_` 且配
好 `Setoid`（18 章词汇；探针 `Tmp22e.agda` 用 stdlib 版也证过同款引理）；up-to 技巧等深水留给后续章
节。记住一条就够：**无限对象的"相等"是观测层的归纳定义，不是计算层的反射律。**

## 22.6 Conat 彩排：可以"永远数不完"的自然数

示例 §4 同一配方做余自然数——把 `ℕ` 归纳定义里递归出现的位置换进 `∞`：

```agda
data Coℕ : Set where
  cozero : Coℕ
  cosuc  : (n : ∞ Coℕ) → Coℕ

infinity : Coℕ; infinity = cosuc (♯ infinity)

two : Coℕ; two = cosuc (♯ cosuc (♯ cozero))
```

`infinity` = 无限个 `suc`（永不 `cozero`）——归纳 `ℕ` 里非法，余归纳里是正经营生；`two` 是有限值，两
层后就到底。要**观测**它得有预算的观察者（`lower` 在 `bound` 上结构递归：消费永远有界、生产永远有
额，两边在有限窗口汇合）：

```agda
-- 观测器:只允许看 bound 层,看不完返回 nothing
lower : (bound : ℕ) → Coℕ → Maybe ℕ
lower zero    n         = nothing
lower (suc b) cozero    = just zero
lower (suc b) (cosuc n) with lower b (♭ n)
...                       | just m  = just (suc m)
...                       | nothing = nothing

lower-two : lower 5 two ≡ just 2; lower-two = refl
lower-inf : lower 100 infinity ≡ nothing; lower-inf = refl
```

预算 5 层数得完 `two`；预算 100 层追不上 `infinity`，诚实返回 `nothing`——`Maybe` 又一次替代了"程序
卡死"（**观测不完**）。为什么示例不直接用 `Codata.Musical.Conat`？它的构造子就叫 `zero`/`suc`，和本
文件已导入的 `Data.Nat.Base` 同名冲突（22.9 第 5 条），手搓 `cozero`/`cosuc` 版既避开冲突，也把
stdlib 的定义原样展示。

## 22.7 Costring 与 IO：正式回收 02/20 章的伏笔

`Codata.Musical.Costring` 的定义（stdlib 源码 `/usr/share/agda-stdlib/src/`）：

```agda
Costring : Set
Costring = Colist Char

toCostring : String → Costring
toCostring = Colist.fromList ∘ String.toList
```

21 章的 `String` 是"一整块已知文本"，`Costring` 是"可能永远在读的文本"。它存在的理由就是 20 章的
IO：输入输出本来就惰性——stdin 没关，就永远"还有下一个字符"。示例 §5 接线：

```agda
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
```

`IO.Infinite` 的 `getContents : IO Costring`（整个 stdin 作为无限流）、
`putStr : Costring → IO ⊤`（边产边发，不要求攒完整串）——`cat` 是二者拼接，一个
**真正流式**的管道程序。示例不定义 `main`（20 章约定可执行程序只归 `Ex20_io`；本文件
做类型检查，`cat` 是"良型的程序文本"）。

现在兑现承诺。20 章的 **`IO` 定义**（`IO/Base.agda`）：

```agda
data IO (A : Set a) : Set (suc a) where
  lift : (m : Prim.IO A) → IO A
  pure : (x : A) → IO A
  bind : {B : Set a} (m : ∞ (IO B)) (f : (x : B) → ∞ (IO A)) → IO A
  seq  : {B : Set a} (m₁ : ∞ (IO B)) (m₂ : ∞ (IO A)) → IO A
```

`bind` 的参数就是本章的 `∞`：单子链接的每一步都是"先欠后还"的 guarded 结构，`forever` 这类不终止的
IO 循环靠它过终止检查，唯一的 `NON_TERMINATING` 额度集中在解释器 `run` 里。所以 02 章说
`--guardedness` 是 "IO 的入场券" 绝非虚言：**import IO ⇒ 需要 guardedness ⇒ 本章 ♯/♭ 就是 IO 语义的零件**。
（历史注脚：2.x 之前 stdlib 曾有纯余归纳的 `Codata.Musical.IO`，后换成现在这套 "guarded 深嵌入 + 单
点 run"，`∞` 血统未变。）

顺带一条实测 scoping 规则（示例注释点过）：Agda **顶层作用域按声明顺序解析**，`finiteCostring` 必须
写在 `cat` 之前——探针把引用挪到定义后实测报 `Not in scope`（`TmpPr22g.agda`，详见坑位 7）。

§5 收尾对照 stdlib 自家的流——与 §1 手搓版同构、接口齐全（`repeat`/`map`/`iterate`/`take`/
`_≈_`…），示例改名导入并验算一条：

```agda
-- 对照:stdlib 自家的 Stream(与 §1 手搓版同构),take 也可算
open import Codata.Musical.Stream as Std using ()
  renaming (Stream to SStream; take to stake′; repeat to repeat′)
open import Data.Vec.Base using (_∷_; [])

std-ones : SStream ℕ; std-ones = repeat′ 1
std-take : stake′ 3 std-ones ≡ (1 ∷ 1 ∷ 1 ∷ []); std-take = refl
```

（stdlib `repeat x = x ∷ ♯ repeat x` 与示例 `ones` 逐字符相同，`take` 同款结构递归。）最后那行不带
限定名的 `Data.Vec.Base using (_∷_; [])` 让 Stream/Colist/Vec 的三个 `_∷_` 同处一个作用域，全靠
**期望类型消歧**（16 章约定）：`std-take` 右侧期望 `Vec ℕ 3`，选中 Vec 版。工程建议见坑位 6。

## 22.8 和 Coq / Haskell 的三方对照

| | Haskell | Coq | Agda（本章） |
|---|---|---|---|
| 无限对象 | 默认惰性，随便写 | `CoInductive` + `CoFixpoint` | `♯`/`♭` + data 声明 |
| 防发散检查 | 无（运行时 ⊥ 兜底） | guardedness 内建、自动 | `--guardedness` 逐文件开关 |
| 延迟的表示 | 隐式（运行时 thunk） | 隐式（构造子参数即惰性） | 显式（类型里看得见 `∞`） |
| 流相等 | `==`（不可判，⊥） | bisimulation 关系 | 手搓 `_~_` / stdlib `_≈_` |
| 副作用循环 | IO 单子天然可无穷 | 不面向执行 | IO 深嵌入 `∞ (IO A)`（20 章） |

Coq 把 guardedness 做成**全自动**判定（`CoFixpoint` 里机器检查"每层先产构造子"），Agda 拆成
**显式记号 + 逐文件开关**——多敲的 `♯`/`♭` 换来"惰性发生在哪"在类型里肉眼可见，还能像 `stake-smap`
那样精确划"只消费不生产"的界。Haskell 是反面：谁都不检查，`ones = 1 : ones` 能写，`bad = 1 : tail bad`
也能写（运行时栈溢出见真章）——Agda 的 Tmp22b 报错正是替你在编译期预支了这次事故。

## 22.9 坑位清单（每条都有实测报错或示例内注释支撑）

1. **忘写 `{-# OPTIONS --guardedness #-}` 就 import `Codata.Musical.*` 或 `IO`**：报
   `InfectiveImport`（原文见 22.1）——报错行指 import 行，修的是文件首行，和 20 章 IO 同款。
2. **`codata` 是保留关键字**：`module Ex22_codata` 实测 `in the name …, the part
   codata is not valid because it is a keyword`——下划线分段的**每一段**不得是关键字
   （04 章 `syntax` 先例）；文件名/模块名改连字符 `Ex22-codata`。
3. **递归穿 `♭` 即泄漏**：`bad = 1 ∷ ♯ tail bad` 看着有 `♯` 仍报 `TerminationIssue`（Problematic
   calls 点名 `♯-0` 与 `bad`，原文见 22.3）。`♯` 里只放裸递归调用；一切"先拆箱再喂"的组合都不
   guarded。
4. **`refl` 证不了流的自展开**：`ones ≡ 1 ∷ ♯ ones` 实测 `UnequalTerms: ♯-0 != ♯-2
   of type ∞ (Stream ℕ)`——`≡` 不做共归纳；无限对象的相等走 `_~_`/`_≈_`（22.5），别拿
   `≡` 硬碰。
5. **`Codata.Musical.Conat` 的 `zero`/`suc` 与 `Data.Nat.Base` 撞名**：同文件双导入同名冲突，要么
   `renaming`/`as` 限定（Base/API 命名税，21/27 章反复出现），要么像示例一样手搓 `cozero`/`cosuc`。
6. **多个 `_∷_` 同作用域**（List/Colist/Stream/Vec 都有）：期望类型消歧多数场景好用（`std-take` 即
   例），但一旦选错，报错里是 `X.∷-0 != Y.∷-1` 式天书——长文件请老实写限定名（示例消费者一律
   `V.∷`）。
7. **顶层声明按顺序解析**：引用定义在其后的顶层名字实测 `Not in scope: k`——不像想象中"函数随便互相
   引用"，跨顺序要显式 `mutual` 块（探针 `TmpPr22g.agda`）。
8. **`IO.Infinite` 的 `getContents` 与有限层同名不同物**：它返回 `IO Costring`、读整个 stdin 而非
   `IO String`，示例必须 `renaming (… to …∞)`；和 20 章 `IO.Base` 的 `getLine : IO String` 混用时，报
   错以 "Costring 不匹配 String" 现身——先检查拿没拿对版本。

---
上一章：[21 · 文本处理](21-strings.md) ｜ 下一章：[23 · 反射与元编程](23-reflection.md) ｜ 返回：[README](../README.md)
