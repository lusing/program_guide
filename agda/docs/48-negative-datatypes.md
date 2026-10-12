# 48 · 负类型与 strict positivity：Agda 的第二道守门检查

> **第十一部分 · 语言防线（48）** ｜ 全书结构与阅读路线见 [README](../README.md)

07 章教过 Agda 的第一道守门检查：**终止性**——函数定义必须结构递归。
这一章讲第二道，它守的不是函数而是**数据类型声明**：

> **strict positivity**：归纳定义的类型不允许出现在自己构造子参数类型的
> **箭头左边**。

这条规则平时完全隐形（99% 的数据类型天然满足），所以大多数教程一句话带过。
本章把它拉出来做一次完整实测：先看它默认拦下什么，再看**放行之后**会掉进
什么坑——三行代码造出 `⊥` 的居民、以及一台会把类型检查器自己拖死的归约机。

对应示例：`../examples/Ex48_negative_datatypes.agda`

**实测口径**：本章代码与报错原文均为 **Agda 2.9.0 + stdlib 3.0** 本机实测
（复现：`cd agda && ./build.sh Ex48_negative_datatypes`；被拒的那些定义
不能进示例文件，原文来自逐条删开关跑出来的临时探针，跑完即删）。内容取材
Aaron Stump《Verified Functional Programming in Agda》9.1.4 节（负类型与
不终止），已扩写成自包含的一章，读完不需要再翻原书。

## 48.1 两道门，各守一条线

先把分工表立起来，后面所有内容都挂在这张表上：

| | 守什么 | 什么时候检查 | 绕开的开关 | 关掉之后会怎样 |
|---|---|---|---|---|
| 终止检查（07 章） | **函数定义**：递归必须结构变小 | 定义函数时 | `NON_TERMINATING` 等（104 条） | 程序可以死循环 |
| positivity 检查 | **数据类型声明**：不能负自指 | 声明 `data`/`record` 时 | `--no-positivity-check` | 逻辑直接不一致：能造 `⊥` |

两道的强度也不同——这一条是本章实测出来的：默认选项下 positivity 违规是
**error**，不是警告，尽管 `agda --help` 的措辞写的是 warn：

```text
/Volumes/mac004/.stack-home/bin/agda --help | grep -i positiv
    --positivity-check                      warn about not strictly positive data types (default)
    --no-positivity-check                   do not warn about not strictly positive data types
```

`warn about` 是 help 文本的措辞，实际行为是硬失败（48.3 的原文）。顺带一条
升级账：网上和旧教程里常见的 `--unchecked-positivity` 在这个 build 里**根本
不存在**：

```text
error: [OptionError]
Unrecognized option: --unchecked-positivity
```

## 48.2 对照组：函数域从来不是问题

示例文件的头三行先把「本章的口径」交代清楚——注意文件级选项只有一个
`--guardedness`，它是 48.6 那个 `coinductive` record 需要的，**不是** positivity
开关：

```agda
{-# OPTIONS --guardedness #-}

module Ex48_negative_datatypes where

open import Data.Empty using (⊥; ⊥-elim)
open import Data.Nat using (ℕ; zero; suc)
open import Data.Product using (_×_)
open import Relation.Binary.PropositionalEquality using (_≡_; refl)
```

`⊥` 与 `⊥-elim` 是本章的「事故现场」，`_×_` 给 `Tree` 的构造子用，`ℕ`/`zero`/`suc`
给对照组的函数域用。

新手最容易把这条规则记成「Agda 的数据类型不能带函数」——错。先把合法的样子
摆够，规则的真实边界才看得出来。

把 `ℕ → ℕ` 整个塞进构造子，检查全程沉默：

```agda
data FunBox : Set where
  box : (ℕ → ℕ) → FunBox

unbox : FunBox → ℕ → ℕ
unbox (box f) = f

funbox-test : unbox (box suc) zero ≡ suc zero
funbox-test = refl
```

`funbox-test = refl` 说明这不只是「类型过」，而是**真的能算**：`unbox (box suc) zero`
一步规约成 `suc zero`。函数当数据装、再取出来用，是 26 章单子、33 章解释器
里天天做的事。

普通归纳树也没问题，`Tree` 的每一处出现都在箭头右边：

```agda
data Tree : Set where
  leaf : Tree
  node : Tree × Tree → Tree
```

甚至「装一个从**别的类型**出去的函数」也行：

```agda
data Ctx : Set where
  cxt : (Tree → ⊥) → Ctx
```

最后一个是决定性的对照：**递归的**、**带函数域**的类型照样合法，只要箭头
左边不是它自己：

```agda
data RV : Set where
  num : ℕ → RV
  fn  : (ℕ → RV) → RV

headRV : RV → RV
headRV (num n) = num n
headRV (fn f)  = f zero

rv-test : headRV (fn (λ n → num (suc n))) ≡ num (suc zero)
rv-test = refl
```

`RV` 自指（两个构造子都造 `RV`）、也有函数域（`fn`），但那个函数的定义域是
`ℕ`，`RV` 只出现在**余域**（箭头右边，正出现）。所以规则精确的形状是：

> 坏的从来不是「函数域」，而是「**本类型出现在函数域的类型里**」——
> 也就是自身出现在箭头左边。

（这一小节有个随手撞上的一行坑：`headRV (fn suc)` 不过——`suc : ℕ → ℕ`，
而字段要的是 `ℕ → RV`，报 `[UnequalTypes] The type ℕ is not a subtype of RV`。
函数域不是「随便给个函数」，它的**余域**必须就是本类型，所以得写成
`λ n → num (suc n)`。）

## 48.3 默认被拦下的样子

现在把 `RV` 的余域换成本类型自己，就是原书 9.1.4 的那个 `Bad`：

```text
data Bad : Set where
  bad : (Bad → ⊥) → Bad
```

默认选项下（探针原文，行号是探针的）：

```text
error: [NotStrictlyPositive]
Bad is not strictly positive, because it occurs
to the left of an arrow
in the type of the constructor bad
in the definition of Bad.
```

四行报错读法：违规的类型（`Bad`）、违规的**位置**（箭头左边）、违规的具体
构造子（`bad`）、以及它属于哪条定义。注意最后两行是分开的——报错把「哪个
构造子的哪个位置」钉得很死，这是 Agda 报错里少见的直白。

理论上有三档，术语借自逻辑（`A ⊃ B ≡ ¬A ∨ B`，所以 `A` 在蕴含里是**负出现**）：

- **strictly positive**：本类型只在箭头右边出现。Agda 要求的就是这一档。
- **positive**：允许出现在**偶数个**箭头左边（两次取反相互抵消），例如
  `(Med → ⊥) → ⊥` 的双重否定。原书 9.1.4 明确点了这一档：「Positivity would
  allow it to occur to the left of an even number of arrows」。
- **negative**：奇数个箭头左边，即 `Bad → ⊥` 这种。

实测的结论是：**Agda 2.9.0 实现的检查比理论的 positive 更严**，双重否定同样
被拒，而且报错文案和上面逐字一样（连「偶数个箭头」都不区分）：

```text
error: [NotStrictlyPositive]
Med is not strictly positive, because it occurs
to the left of an arrow
in the type of the constructor med
in the definition of Med.
```

所以读 Agda 报错时，`not strictly positive` 这句要照字面理解：它说的就是
「**严格**正」，不是「正」。

## 48.4 放行之后：三行代码炸掉整个逻辑

`--no-positivity-check`（或声明级开关，48.6）把门打开，本章的主角才登场。
示例里 `Bad` 前面挂了一条 `{-# NO_POSITIVITY_CHECK #-}`：

```agda
{-# NO_POSITIVITY_CHECK #-}

data Bad : Set where
  bad : (Bad → ⊥) → Bad
```

`Bad` 的值长这样：一个 `Bad` **就是一个**「从 Bad 造 `⊥` 的方法」。拿到它就得
同时拿到那个函数和它的输入：

```agda
badFunc : Bad → ⊥
badFunc (bad f) = f (bad f)
```

这一行是自应用的源头。拆开看：模式 `bad f` 交出 `f : Bad → ⊥`；目标是 `⊥`，
而 `f` 吃的正是一个 `Bad`——手上就有一个现成的：`bad f` 本身（它就是被拆开的
那个输入）。于是 `f (bad f)` 类型完全正确。

把 `badFunc` 塞进 `bad`，闭合项就出来了：

```agda
inconsistency : ⊥
inconsistency = badFunc (bad badFunc)
```

类型检查器在这里只做了一件事：核对 `bad badFunc : Bad`、`badFunc : Bad → ⊥`，
应用结果类型是 `⊥`——**通过**。它没有把这个项归约到底（Agda 的类型检查从不
做完全规范化，这是它日常能秒回的原因），于是这枚地雷静静躺在模块里。

而 `⊥` 一旦有居民，`⊥-elim` 立刻把整个逻辑炸平：

```agda
evil : (A : Set) → A
evil A = ⊥-elim inconsistency
```

`evil : (A : Set) → A` 就是「任何命题都可证」。Curry–Howard 下 Agda 的全部
意义在于「类型检查通过 ⟹ 定理成立」，这条类型通过之后，那个承诺对**所有**
类型都成立，也就是对所有类型都不成立。

（`⊥-elim` 的隐式参数名顺手记一笔：3.0 里它不叫 `A`，写作 `{Whatever = A}`
才能点名；写 `{A = A}` 报 `[WrongNamedArgument] Function does not accept
argument {A = _} (possible arguments: w Whatever)`。报错直接把可用参数名
列出来了，这是 Agda 报错里很实用的一个习惯。）

## 48.5 为什么终止检查救不了这次事故

一个自然的疑问：07 章的终止检查不是保证「所有函数终止」吗？这里怎么还是有
死循环？

**因为 `badFunc` 里一个递归调用都没有。** 定义右侧出现的只有 `f`、`bad`，
`badFunc` 这个名字一次都没出现——终止检查器扫一遍，无可疑对象，放行。
发散不来自递归，而来自**自应用**：把一项喂给它自己。这是完全不同的机制，
07 章那套「哪个参数在变小」的语言对它毫无办法。

48.3 那个被默认拒掉的双重否定，在示例里靠声明级开关活了下来：

```agda
{-# NO_POSITIVITY_CHECK #-}

data Med : Set where
  med : ((Med → ⊥) → ⊥) → Med
```

对照实验（探针）：如果改用**真递归**去从 `Med` 造 `⊥`，终止检查器立刻在岗：

```text
error: [TerminationIssue]
Termination checking failed for the following functions:
  medFunc
Problematic call:
  medFunc
    (at .../TmpProbe48h.agda:13.28-35)
```

探针里写的是 `medFunc (med f) = f (λ m → medFunc m)`：类型全都对，但那一次
`medFunc` 调用不在结构子变小的参数上（`m` 是 λ 新绑的），于是被拒。两条结论
同时到手：positivity 与 termination **是两道独立的门**，关掉前者不会让后者
失效；而后者也管不到负类型真正的杀招。

计算侧的账也要算。原书 9.1.4 说对 `inconsistency` 按 `C-c C-n` 求值会「run
forever」，命令行同样能复现——办法是**逼**类型检查器把它归约到构造子形态
（对 `⊥` 做 `with` 匹配就必须做到这一步）：

```text
loop : ⊤
loop with inconsistency
... | ()
```

实测（探针 `TmpProbe48j.agda`，同一个文件去掉 `loop` 就是 48.4 的通过版本）：

```text
$ perl -e 'alarm 40; exec @ARGV or die' agda examples/TmpProbe48j.agda
Checking TmpProbe48j (...).
（40 秒无输出、无报错，进程被 SIGALRM 杀掉，退出码 142）

$ time agda examples/TmpProbe48c.agda     # 同一份定义，没有 loop
Checking TmpProbe48c (...).
0.22s user 0.13s system 90% cpu 0.383 total
```

0.38 秒 vs 超过 40 秒不返回——归约机一旦启动就永远出不来，这就是
`badFunc (bad badFunc) ⟶ badFunc (bad badFunc) ⟶ ...` 的真身。也正因如此，
这段代码**不能**进示例文件：它会把 `./build.sh` 挂死。本章示例只保留能通过
类型检查的那部分，这段以探针形式记录。

## 48.6 record 版本：三道闸门一个一个过

`data` 换成 `record`，情况更有意思——递归 record 要过的门不止一道。默认选项
下先来两记：

```text
error: [NotStrictlyPositive]
BadR is not strictly positive, because it occurs
to the left of an arrow
in the definition of BadR.

error: [UnguardedEtaRecord]
Recursive occurrence of this record in its definition is unguarded,
so eta-equality for this record might lead to non-termination in
the type checker.
To suppress this error, use pragma {-# ETA_EQUALITY #-}
```

第一条是 positivity（record 没有构造子，所以报错少了「in the type of the
constructor」那一行）。第二条是**另一个独立**的检查：递归 record 默认带
η 相等，而「η + 无守卫的递归」足以让类型检查器自己发散，所以 Agda 直接拦。

只关掉 positivity（`{-# OPTIONS --no-positivity-check #-}`，探针 48l）时，
第二条依然拦路——两道门的独立性到这里第二次确认。按报错给的提示补 η 的
许可，又跳出**第三**道：

```text
error: [RecursiveRecordNeedsInductivity]
Recursive record BadR needs to be declared as either inductive or
coinductive
```

三道门全过才拿到那个 `⊥`。示例里就是这么写的：

```agda
{-# NO_POSITIVITY_CHECK #-}
{-# ETA_EQUALITY #-}

record BadR : Set where
  coinductive
  field
    badR : BadR → ⊥

badFuncR : BadR → ⊥
badFuncR r = BadR.badR r r

inconsistencyR : ⊥
inconsistencyR = badFuncR (record { badR = badFuncR })
```

两条语法细节是实测的，网上抄来的写法常在这两处翻车：

- `{-# ETA_EQUALITY #-}` 是**裸写法**，不带类型名。写成 `{-# ETA_EQUALITY BadR #-}`
  在 parse 阶段就死：`error: [ParseError]` 并把 `BadR<ERROR>` 打回给你
  （语法出处 `Agda/Syntax/Parser/Parser.y:1738-1741`：`'{-#' 'ETA_EQUALITY' '#-}'`，
  没有 QName 位）。它的作用范围是紧随其后的那个 record。
- `coinductive` 是写在 `where` 块里、`field` 之前的一行，并且需要文件级
  `{-# OPTIONS --guardedness #-}`——这就是本章示例文件头上那个选项的来源，
  它与 positivity 无关。

`badFuncR r = BadR.badR r r` 与 48.4 的 `badFunc` 是同一招：从 record 里取出
函数 `BadR → ⊥`，再把 record 自己（`r`）喂进去。`inconsistencyR` 则把
`badFuncR` 自己包装成 record（record 的 η 让 `record { badR = badFuncR }`
合法）。所以「关掉 positivity 的代价」与走 `data` 还是 `record` 无关。

## 48.7 关掉检查的两种粒度，以及放错位置的哑火

开关有两个层级，选哪个是有讲究的。

**文件级**：`{-# OPTIONS --no-positivity-check #-}`（原书用的就是这个，
2.9.0 仍在，实测整个模块放行且不报任何警告）。代价是范围是整个文件——
同文件里其它数据类型也得检查也被关了，而你多半只有一个坏类型。

**声明级**：`{-# NO_POSITIVITY_CHECK #-}` 紧贴那条 `data`/`record` 声明之前
（本章示例用的就是这个）。粒度小、意图明确，责任写在脸上。

两种放错位置的写法都实测过，共同点是**不会**硬失败：

```text
error: [SafeFlagPragma]
The --safe mode does not allow OPTIONS pragma
--no-positivity-check
```

```text
warning: -W[no]UselessPragma
OPTIONS pragma only allowed at beginning of file, before top module declaration
when checking the pragma OPTIONS --no-positivity-check
```

```text
warning: -W[no]InvalidNoPositivityCheckPragma
NO_POSITIVITY_CHECKING pragmas can only precede a data/record
definition or a mutual block (that contains a data/record
definition).
```

最后那条警告值得多看一眼：文案里的名字（`NO_POSITIVITY_CHECKING`）和你写的
pragma 名（`NO_POSITIVITY_CHECK`）不一致，别以为是另一个开关。三种情况的后果
分别是：`--safe` 直接拒（104 条「--safe 是日常体检」在这里有了硬证据）；
OPTIONS 没写在文件头→警告 + 后面的 `Bad` 照常 `NotStrictlyPositive`；声明级
pragma 放在 `open import` 之前→警告 + 同样照常报错。后两种都是 43 章第 102 条
「警告族当错误治」的标准样本：退出码不变，你以为开了门，其实门还关着。

## 48.8 正道：为什么不需要这扇门

负类型诱人之处是「值里装一个作用于自身的方法」——HOAS、自解释解释器、
各种带闭包的抽象语法都会想要它。全书给出的替代方案其实已经出现过三次：

- **35 章**：SK 组合子的归约关系 `_↝_` 用**构造子表示规则**，规则的参数是
  子推导，不是闭包。
- **46 章**：`_⊢_` 同样把「给定前提就能出结论」写成构造子的**参数**（索引
  数据类型），而不是写成函数域。
- **33 章**：类型良好的 AST 把「函数」留在求值函数 `eval` 的类型里
  （`eval : Env → Tm → Val`，`Tm` 只装 de Bruijn 索引），而不是塞进 `Tm` 自己。

三处的共同点：需要「函数」的地方让它待在**类型层的函数空间**（那里 Agda
从不限制），数据类型自己只装索引与子项。这条路走通了，positivity 检查就
永远是隐形的好朋友，而不是一堵要翻的墙。

至于真的想要「无限的自指」——那是 29 章余归纳的活：`Musical.♯` 加
`--guardedness` 让流、协树合法自指，代价是构造必须被 `♯` 守卫。48.6 里
`BadR` 那句 `coinductive` 用的正是同一套 guardedness 机制，只是它配合
`--no-positivity-check` 把守卫的要求也一并绕过了，于是只剩发散。

## 48.9 这两道检查在全书里的位置

Agda 的「编译通过 ⟹ 定理成立」这句口号，靠的是两条腿：

1. 函数必须终止（07 章）——否则可以用死循环「证明」任何东西；
2. 数据类型必须严格正（本章）——否则可以用自应用「证明」任何东西。

本章把第 2 条从背景里拎出来，是因为它的报错平时见不到：写不出来的人往往
以为自己不懂依赖类型，其实是撞上了一道专门拦自指的门。而一旦知道门的两侧
是什么，判断就变成 mechanical 的：箭头左边有没有自己？有 → 换索引/换关系/
换余类型；没有 → 检查根本不会打扰你（48.2 那四个合法样子就是证明）。

顺带本章也补齐了 43 章第 104 条的另一半：`--safe` 拒绝的选项名单里，
`--no-positivity-check` 与 `postulate`、`NON_TERMINATING` 是同一级别的
（实测的 `SafeFlagPragma` 原文在 48.7）。

## 48.10 坑位清单（实测）

1. **`--unchecked-positivity` 在 2.9.0 不存在**：`[OptionError] Unrecognized
   option: --unchecked-positivity`。本机能用的只有 `--no-positivity-check`
   （文件级）与 `{-# NO_POSITIVITY_CHECK #-}`（声明级）。网上教程里那个
   `--unchecked-positivity` 是别的版本线的名字，照抄直接卡在第一行。
2. **`--help` 说 warn，实际是 error**：help 文本写 `warn about not strictly
   positive data types (default)`，默认行为却是 `[NotStrictlyPositive]` 硬
   报错、退出码非 0。以行为为准，别以 help 措辞为准。
3. **「positive 但不 strictly positive」同样被拒**：理论允许的双重否定
   `((Med → ⊥) → ⊥) → Med` 实测照报 `NotStrictlyPositive`，文案与负出现
   逐字相同。Agda 实现的是严格档，报错也不区分两种违规。
4. **函数域不是问题，自指才是**：`(ℕ → ℕ)`、`(Tree → ⊥)`、甚至递归类型
   `RV` 的 `(ℕ → RV)` 全部合法。判据只有一条：本类型有没有出现在箭头左边。
5. **函数域的余域必须精确**：`RV` 的字段是 `ℕ → RV`，所以 `fn suc` 报
   `[UnequalTypes] The type ℕ is not a subtype of RV`——要写 `fn (λ n → num (suc n))`。
6. **负类型的发散绕开终止检查**：`badFunc (bad f) = f (bad f)` 里**没有**
   递归调用，终止检查器无对象可查；发散来自自应用。想靠 07 章那套「参数
   变小」的纪律挡住它是不可能的，两道门互不接管（对照 `medFunc` 那条
   `TerminationIssue`）。
7. **`with` 一个负类型造出的 `⊥` 会把类型检查器拖死**：探针 40 秒不返回
   （SIGALRM 杀，退出码 142），而删掉 `loop` 的同一份定义 0.38 秒通过。
   这段代码绝不能进示例/CI 文件——`./build.sh` 会挂在那里。
8. **递归 record 有三道独立的门**：positivity（`NotStrictlyPositive`）、
   η（`UnguardedEtaRecord`）、归纳性（`RecursiveRecordNeedsInductivity`）。
   只关 positivity 会卡在第二道；补上 `{-# ETA_EQUALITY #-}` 才跳出第三道，
   必须写 `coinductive` 并挂 `--guardedness`。
9. **`{-# ETA_EQUALITY #-}` 是裸写法**：带类型名（`ETA_EQUALITY BadR`）直接
   `ParseError`。语法在 `Agda/Syntax/Parser/Parser.y:1738-1741`，只有
   `'{-#' 'ETA_EQUALITY' '#-}'` 三个 token，作用范围是紧随其后的 record。
10. **pragma 放错位置只给警告，门照关**：OPTIONS 不在文件头 → `UselessPragma`
    警告 + 后面照样 `NotStrictlyPositive`；`NO_POSITIVITY_CHECK` 放在
    `open import` 前 → `InvalidNoPositivityCheckPragma` 警告（文案里的
    `NO_POSITIVITY_CHECKING` 与 pragma 实名不一致，别找错开关）。两条都
    不改退出码，属于 43 章 102 条的警告族。
11. **`--safe` 与 positivity 开关互斥**：`[SafeFlagPragma] The --safe mode
    does not allow OPTIONS pragma --no-positivity-check`。所以「挂了 --safe
    的模块」可以当成「本模块没有负类型」的机器担保。
12. **`⊥-elim` 的隐式参数名是 `Whatever`**：`⊥-elim {A = A}` 报
    `WrongNamedArgument … (possible arguments: w Whatever)`；点名要写
    `{Whatever = A}`（不点名则完全没问题，`⊥-elim inconsistency` 直接过）。

---

上一章：[47 · 完全性定理与 normalization by evaluation：把两条元定理合成一台机器](47-nbe.md) ｜ 下一章：[49 · bracket abstraction：把 λ 抽象编译成 SK 组合子](49-bracket-abstraction.md) ｜ 返回：[README](../README.md)
