# 03 · 第一个文件

前两章我们站在远处看 Agda：01 章讲清了「类型即命题、程序即证明」的心智模型，
02 章把命令行、`.agda-lib` 和 Emacs 交互这套工具链跑通了。但从这一章开始要
真的动手写文件——而第一个文件就会撞上一堆「编译器觉得你不讲理」的瞬间：
`0` 到底是什么类型？为什么 `open import` 后面还要 `using`？交互式会话里
一键 `Compute` 的事，源文件里怎么表达？本章用一个「显微镜式」的最小模块
回答这些问题：逐行解剖一个文件，看清每条语法线的职责，并教你**读懂报错**
——在 Agda 里，报错信息不是惩罚，是类型检查器跟你说话的方式。

对应示例：`../examples/Ex03_basics.agda`

本章所有报错文本均为 Agda 2.8.0 + stdlib 2.3 实测原样粘贴，没跑过的输出不上墙。

## 3.1 逐行解剖一个最小模块

先把示例文件的开头原样放在这里：

```agda
module Ex03_basics where

open import Data.Nat using (ℕ; zero; suc; _+_; _*_)
open import Data.List using (List; []; _∷_)
open import Relation.Binary.PropositionalEquality using (_≡_; refl)

import Data.List as L
```

**`module Ex03_basics where`** —— 模块头。三件事粘在这一行里：关键字
`module`、模块名、关键字 `where`。模块名有两个硬性义务：(1) 它是标识符，
不能以数字开头、不能混入被下划线分隔的关键字（01 章撞过 `01_intro`，
04 章的示例文件甚至因为 `syntax` 是关键字被迫改名，剧透到此为止）；
(2) **必须和文件名严格一致**——不一致时 type checker 第一关就把你推出门：

```text
/home/xulun/code/programming/agda/examples/TmpD.agda:1.8-17: error: [ModuleNameDoesntMatchFileName]
The name `WrongName` of the top level module does not match the
file name. A such named module should be defined in one of the
following files:
  /home/xulun/code/programming/agda/examples/WrongName.agda
  ...
```

报错怎么读（坐标格式、错误码、when 链）3.8 节统一讲，这里先记住结论：
文件名与模块名这对「双胞胎」必须互相转写得出，差一个字符都不行。

**`where` 之后**的一切都是「声明区」：类型签名、函数定义、`data`、
`postulate`、嵌套的 `module`……但**不是**「顺序随意」——实测：作用域解析是
从上往下的，函数体里引用后面才声明的名字会直接 `Not in scope`
（想用 `g` 定义 `f`、又互相递归，得把两条放进 `mutual` 块）。惯例是
先签名后定义、被用的定义在被用之前：

```text
examples/TmpFwd.agda:6.7-8: error: [NotInScope]
Not in scope:
  g at examples/TmpFwd.agda:6.7-8
when scope checking g
```

**`open import Data.Nat using (ℕ; zero; suc; _+_; _*_)`** —— 一行叠了三个
动作：`import Data.Nat` 把模块拉进依赖图（并保证它被类型检查过）；
`using (…)` 挑名字；`open` 把挑出来的**倒进当前作用域**，于是可以写
`1 ∷ 2 ∷ []` 而不必写 `Data.List._∷_ 1 (Data.List._∷_ 2 Data.List.[])`。
`using` 可换成 `hiding (x)` 或 `renaming (old to new)`，三者可组合。为什么
费这个劲？stdlib 各模块同名极多，**显式过滤是防冲突刚需**，不是洁癖；后面
会看到 `using` 的过滤粒度甚至能坑到字面量机制。

**`import Data.List as L`** —— 不 open，只起别名，之后用限定名 `L.length`
访问，适合「偶尔用一两个名字、不污染作用域」；示例里
`len3 = L.length list3` 就是这个用法。另一个冷知识：`import` 行可以出现在
文件**中间**，作用域从该行往后生效。

## 3.2 类型标注与函数定义

Agda 的函数定义永远是「一行冒号、一行（或多行）等号」成对出现：

```agda
idℕ : ℕ → ℕ
idℕ n = n

double : (n : ℕ) → ℕ
double zero = 0
double (suc n) = suc (suc (double n))
```

要点：

- **类型签名不是注释，是合同。**没有签名的定义 Agda 会拒绝
  （`Missing type signature for left hand side double zero`——和 Coq 可省类型、
  Haskell 靠事后 lint 不同，Agda 把签名做进了语法层，终止检查与分派都靠它）。
- 冒号读「是」，等号读「定义为」。`idℕ : ℕ → ℕ` 与 `idℕ n = n` 的 `n` 是两行
  之间唯一的胶水——左边出现过的变量名，右边就是它的定义。
- 签名里 `(n : ℕ) → ℕ` 和 `ℕ → ℕ` 是**同一个类型**，区别只是 `n` 被起了名字，
  供后面的依赖类型用（05、10 章的主角）；本章先习惯这种书写。
- 同一个函数名可以写**多条等式规则**，每条对应一种输入形状——这就是模式匹配
  （`double zero` 与 `double (suc n)` 两行分别处理 0 和后继），按从上到下第一个
  能匹配的执行，第 06 章整章展开。
- 定义体不一定有参数：`inc = suc` 直接说「inc 就是 suc 这个函数本身」。
  函数是普通值，能被起别名、被传递（17 章）。

没有 `main`、没有 IO 也能玩得转——本章到 19 章之前所有示例都只做类型检查。

## 3.3 字面量多态：`0` 可以是多少类型？

先看一个容易答错的题：`three = 3`，这个 `3` 是什么类型？答案是——**看期望值**。
Agda 的字面量分两层机制，两层我们都在本机实测过：

**第一层：默认落点。**什么都不配时，自然数字面量按旧式内置处理，落到内建
ℕ：`suc (suc (suc zero))`。这条路径不需要任何 import——它是「兼容层」，
也是新手最容易误以为是「全部真相」的地方（实测证据见本节末尾的坑）。

```agda
three : ℕ
three = 3

_ : three ≡ suc (suc (suc zero))
_ = refl
```

**第二层：实例化多态（Agda ≥ 2.6.2 + stdlib 2.x 的 `FromNat`/`FromNeg`
机制）。**想让 `0`、`7`、`-3` 在别的类型上落地，要给目标类型登记 `Number A`
（非负字面量）或 `Negative A`（负字面量）的**实例**。自定义类型也行——示例里
给 `Parity`（奇偶）登记了实例，于是 `7 : Parity` 合法且规约成 `odd`：

```agda
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
```

`Constraint : Nat → Set` 是字面量的准入闸：默认写成 `λ _ → ⊤`（一切放行），
也可以收紧成「只许非零」「只许偶数」等谓词——检查器会做实例搜索去证明它。

**本机实测踩平的两个暗坑**（都是 stdlib 2.3 真实行为，值得单独背下来）：

坑 A：**光 `open import Agda.Builtin.FromNat using (Number)` 不够，机制根本
不生效。**`BUILTIN FROMNAT`  pragma 挂在字段函数 `fromNat` 上，`Number` 记录
类型本身不触发它；必须把 `fromNat` 也 `using` 进作用域，字面量才会走实例路径：

```agda
open import Agda.Builtin.FromNat using (Number; fromNat)
open import Agda.Builtin.FromNeg using (Negative; fromNeg)
open import Data.Unit.Base using (⊤; tt)
```

没带 `fromNat` 时的症状极其迷惑——字面量默默落回 ℕ，然后在你的类型上报错：

```text
/home/xulun/code/programming/agda/examples/TmpK.agda:31.6-7: error: [UnequalTerms]
ℕ != Parity
when checking that the expression 7 has type Parity
```

坑 B：**机制一旦激活，连裸的 ℕ 字面量也要走实例搜索**，必须把 ℕ 自己的实例
也登记上（stdlib 备好 `Data.Nat.Literals.number`），否则连 `5 : ℕ` 都会报
`No instance of type Number ℕ was found in scope`。同理，stdlib 实例的
Constraint 都是 `λ _ → ⊤`，而 `⊤` 的证明靠带 `instance` 标记的构造子 `tt`——
所以 `Data.Unit.Base using (⊤; tt)` 里 **`tt` 不能省**（只带类型不带实例，
字面量机制当场失联）。全套配齐后，整数也能优雅地用字面量：

```agda
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

minus3 : ℤ
minus3 = -3

_ : minus3 ≡ - (+ 3)
_ = refl
```

为什么不配 `fromNeg` 就写负字面量？实测报错很自述型（但按提示手写 pragma
不优雅，正解就是上面的实例）：

```text
error: [NoBindingForBuiltin]
No binding for builtin thing FROMNEG, use {-# BUILTIN FROMNEG name
#-} to bind it to 'name'
when scope checking -3
```

最后一件冷事实：`1/2` **不是**有理数字面量——stdlib 2.3 下 `half = 1/2 : ℚ`
直接报 `Not in scope: 1/2`，有理数请用 `Data.Rational` 的 `_/_`。

## 3.4 用等式证明 + refl 代替交互式 Compute

02 章说过：`Check`/`Compute` 是交互命令，**不是源文件语法**，写进 .agda 文件
必炸。源文件里想表达「这个值算出来等于那个值」，标准姿势是**一条匿名等式 + refl**：

```agda
_ : 2 + 3 ≡ 5
_ = refl
```

读法：声明一个匿名（名字写 `_`）的对象，类型是命题 `2 + 3 ≡ 5`，值是 `refl`。
为什么 `refl` 配得上这个类型？因为 `_≡_` 的构造子 `refl` 只造得出 `x ≡ x`——
而类型检查器在放行前会把等式两边各自**规约**（求值）到范式，`2 + 3` 归约成
`5`，两边同形，通过。**编译器替你做了交互式 Compute 的活**，而且把结果焊死成
证明：以后谁改了 `_+_` 的定义导致计算变味，这个文件立刻检查失败——「测试用例
长在类型上」的最小形态。匿名声明里的新面孔：

- 开头的 `_ : 命题` 与下一行的 `_ = 证明` 配对；Agda 允许**多个**匿名声明，
  各 `_` 互不相干（别和签名里的「推断占位 `_`」混淆，那是另一个意思）；
- `≡`（输入 `\==`）从 `Relation.Binary.PropositionalEquality` 导入，比内建的
  `Agda.Builtin.Equality._≡_` 多个宇宙多态，全书统一用它；`refl` 既是构造子名，
  也是「显然成立」的礼貌说法。

refl 的边界同样重要——它只认**规约**得出的相等。`+` 的定义在第一个参数上
递归，所以左边是字面量时算得动、右边是字面量时算不动：

```agda
0+-n : (n : ℕ) → 0 + n ≡ n
0+-n n = refl        -- 通过：0 + n 一步规约成 n
```

而 `n + 0 ≡ n` refl 过不了（左边卡在 `match n` 上），必须请归纳法出场——
那是 13 章的正戏。想看失败现场？自己敲一遍，报错长这样（实测同款）：

```text
_ : 2 + 3 ≡ 6
_ = refl
-- error: [UnequalTerms]
-- 5 != 6 of type ℕ
-- when checking that the expression refl has type 2 + 3 ≡ 6
```

这条报错的漂亮之处在于 `5 != 6`：检查器**真的算了**，拿算完的结果来比对。
本章示例里 `inc (double 3) ≡ 7` 这类「串几个定义算一算」的等式就是最便宜的
单元测试——初学阶段每写一个函数都顺手来一条。

## 3.5 注释

三种「不参与类型检查」的文字，各有分工：

```agda
-- 行注释：两个短横线到行尾（后面跟不跟空格都行；单短横线不是注释，是减号/名字）
{- 块注释：可跨行，且可 {- 嵌套 -}，
   所以注释掉一整段含注释的代码毫无压力（C 系语言做不到） -}
{-# OPTIONS --safe #-}   -- pragma：必须出现在 module 头之前，影响语言开关
```

`--` 的坑：`a--b` 里 `--` 连写会被词法器判为注释起点，行尾剩什么都不检查了。
块注释支持嵌套这点和 C/Java 相反、和 OCaml/Haskell 相同。`{-# OPTIONS #-}`
严格说不是注释而是指令，第 20/22/24 章要用它开 IO、guardedness、cubical
的开关（写在 `module` 之后直接报错）。中文注释天然可用：源文件就是 UTF-8。

## 3.6 postulate 与公理：向虚空要东西

`postulate` 声明「我假定它存在」，不给定义：

```agda
postulate
  Person : Set
  alice : Person
  age : Person → ℕ
```

Curry–Howard 视角下这就是**引入公理**：逻辑上凭空多了一条不可反驳的假设。
Agda 对 postulate 的态度是「诚实但危险」：它一视同仁地参与计算和证明，但一旦
用了它，**整个模块的定理都骑在假设上**——包括你本想证明的反面。postulate 是
证明界的 `unsafePerformIO`，`agda --safe` 下直接禁用，只在确实需要外延公理、
排中律这类无法内建的原理时才破例。

对**计算**而言，postulate 像「取值未知的参数」：你不知道 `age alice` 是谁，
但 `1 + age alice` 规约成 `suc (age alice)` 毫无障碍——字面量那侧能动。

```agda
postulate
  mystery : ℕ

1+mystery : suc mystery ≡ 1 + mystery
1+mystery = refl
```

反过来 `mystery + 1 ≡ suc mystery` 就卡死了（第一个参数动不了），这条不对称
以后会反复出现（07、13 章）。另外：postulate 的等式**证不出来也拆不穿**，想
表达「未知但存在」应用 `∃`/`Σ`（09、12 章），随手 postulate 在评审证明时相当
于在纸上写「显然」。

## 3.7 命名惯例

Agda 的标识符规则比多数语言宽得多，本章示例全部用过：

```agda
my-var : ℕ      -- 连字符合法（Haskell 做不到！），my-var = 1
x′ : ℕ          -- 撇号（\':）用于变体：≤′、++′
n₀ : ℕ          -- Unicode 下标数字
类型别名 : Set   -- 中文标识符合法（UTF-8 源文件）
值 : 类型别名
```

惯例清单（stdlib 全部遵守，读库前先记住）：

- **类型/构造子**大写字母开头：`List`、宇宙 `Set`（`zero`/`suc` 是历史例外）；
- **运算符名**用 `_` 占位：`_+_`、`_≡_`、`_∷_`；前后缀记法 `#_`、`_[_]`；
  多个洞也行（04 章）；混字母要加下划线隔开（`_⊎_`、`_≫=-_`），纯符号也行
  （`_++_`）；`syntax`、`data` 这类**被 `_` 分隔开的**关键字片段不能进名字
  （04 章文件名惨案的根源）；
- 同一概念多个变体用撇号/下标区分：`_≤?_`（返回判定）、`_≤ᵇ_`（返回 Bool）、
  `≤-trans`（证明）——stdlib 2.x 的命名地图 27 章专门画；
- **模块名**用 `.` 对应目录：`Data.Nat.Base` 就是 `Data/Nat/Base.agda`。

还有一类命名值得单独说：以 `_` 结尾或包裹的形式名（`if_then_else_`、
`Σ[ x ∈ A ] B`）不是普通标识符，是 **mixfix 记法**，04 章整章讲它们。

## 3.8 报错解剖课

前面零零散散看过几条，这里把 Agda 报错的通用形状一次讲透。所有报错都遵循
同一副骨架：

```text
<文件>:<行>.<列起>-<列止>: error: [错误码]
<错误正文>
when <阶段> <相关表达式/类型>
```

- **位置**：2.8 命令行是 `行.列起-列止`（一个点分隔行列，一段短横分隔列范围），
  跟常见的 `行:列` 格式不同，第一次读容易找错坐标；
- **错误码**：方括号里的 `[NotInScope]`、`[UnequalTerms]`、
  `[NoBindingForBuiltin]`……`agda --help=error` 给全表，搜错误时比正文靠谱；
- **when 链**：从触发点一路向上叠加的 elaboration 上下文，**先读最底下那行**，
  它说明「这个错最终是在检查什么声明时冒出来的」。

三类最高频的错误，各配一条实测原文：

**(1) 作用域类（NotInScope）**——忘 import、或 import 了没 `open`、或
`using` 过滤掉了：

```text
examples/TmpA.agda:8.21-22: error: [NotInScope]
Not in scope:
  ≡ at examples/TmpA.agda:8.21-22
when scope checking ≡
```

Agda 2.8 的 NotInScope 常附 `(did you mean 'Relation...._≡_'?)` 式提示，别硬扛，
照着改。作用域错误**不需要类型检查就能报**，所以文件里到处是类型错误时也先修
作用域，一次一条。

**(2) 模块/文件结构类**——见 3.1 的 `ModuleNameDoesntMatchFileName` 与
`in the name 01_intro, the part 01 is not valid...`。修复永远在「名字」上。

**(3) 类型不匹配类（UnequalTerms）**——3.3/3.4 已见过 `5 != 6`、`ℕ != Parity`。
正文格式是 `<左边> != <右边> of type <类型>` + `when checking that the
expression <E> has type <T>`。`!=` 两侧是**规约之后**的范式，所以如果报错说的
不相等「看起来明明一样」，多半是两边还没规约到位（需要 13 章的归纳）。

调试姿势上 Agda 不像 Coq 有 tactic 状态可以走查，实用三板斧是：
(a) 把大定义拆成带签名的小步，看错误位置在哪行签名；(b) 用
`_ : 期望类型` + 逐步替换定义体定位「从哪一步开始不匹配」；(c) 命令行
`agda --only-scope-checking File.agda` **只做作用域解析不做类型检查**——
想在类型错误满地跑时先把 import 框架搭对，它很好用。

## 3.9 本章坑位清单（实测）

1. **模块名必须等于文件名，且文件名本身必须是合法标识符**：`Ex04_syntax`
   这种「下划线+关键字」的名字在词法层就非法（`the part syntax is not valid
   because it is a keyword`），和 `01` 开头是数字字面量一样过不去；
2. **import ≠ open ≠ using**：`import M` 之后名字还是不在作用域（限定名除外）；
   `using (⊤)` 会把 `tt` 的实例身份也挡在门外——字面量机制当场失灵（3.3 坑 B）；
3. **字面量实例三件套**：`Number` 记录必须配着 `fromNat` 字段一起 import 才激活；
   激活后 ℕ 的实例也得登记；ℤ 正/负字面量分别吃 `Number ℤ`/`Negative ℤ`
   两条实例（少配一条就是 `NoBindingForBuiltin FROMNEG` 或默默落回 ℕ）；
4. **refl 只认规约**：`n + 0 ≡ n` 过不了，别误以为 `≡` 弱——是 `+` 在第一个
   参数上递归；想证「算不动」的等式去学归纳（13 章），不是换写法；
5. **postulate 无义务**：它能让你「证明」任何命题（postulate ⊥ 即封神），
   认真代码要开 `--safe` 防身；探索期用完 postulate 记得回来清理；
6. **报错行列用点分隔**（`13.5-7`），别按 `行:列:行:列` 的古登堡格式找；
7. **`Checking ...` 只在真检查时打印**：缓存命中时 `agda` 零输出退出 0，
   这不是没跑（02 章坑位的回声）。

---
上一章：[02 · 工具链与交互方式](02-toolchain.md) ｜ 下一章：[04 · 记号与运算符](04-syntax.md) ｜ 返回：[README](../README.md)
