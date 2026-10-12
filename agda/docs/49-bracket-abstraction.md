# 49 · bracket abstraction：把 λ 抽象编译成 SK 组合子

> **第十二部分 · λ 的消除（49）** ｜ 全书结构与阅读路线见 [README](../README.md)

35 章造了一台只有 `S`、`K`、`app` 三个构造子的语言，并证明了它的 S 自由片段
终止。那一章结尾留了一句没说破的话：**没有变量的语言怎么写函数**。
本章把它补完——不是靠给语法加 `λ`，而是靠一个翻译算法：

> **bracket abstraction**（方括号抽象）：给定变量名 `s` 和一个可能含 `s` 的
> 组合子 `v`，造出一个**不含 `s`** 的组合子，它的行为等同 `λs.v`。

算法只用到 `S` 和 `K` 两个原语，用到三条正确性账要算：产出里真的没有那个
变量（`λ*-binds`）、产出应用到参数上等于代入（`λ*-↝`）、以及支撑第二条所需
的一整套归约机器（多步归约、同余引理）。这一章把这些机器逐件搭起来，
每件都当场类型检查。

对应示例：`../examples/Ex49_bracket_abstraction.agda`

**实测口径**：本章代码与报错原文均为 **Agda 2.9.0 + stdlib 3.0** 本机实测
（复现：`cd agda && ./build.sh Ex49_bracket_abstraction`；被拒绝的写法来自
逐条改写的临时探针，跑完即删）。内容取材 Aaron Stump《Verified Functional
Programming in Agda》9.2.4 节（图 9.12–9.19），已扩写成自包含的一章，
读完不需要再翻原书。

## 49.1 语法缺口：变量从哪里来

先看本章文件的全部进口清单——七个 import 各有明确的用途，读报错时它们就是
「这一章会碰到的零件表」：

```agda
{-# OPTIONS --safe #-}

module Ex49_bracket_abstraction where

open import Data.Bool using (Bool; true; false; _∨_; if_then_else_)
open import Data.Nat using (ℕ; suc; _+_)
open import Data.Product using (Σ; _,_)
open import Data.String using (String; _==_)
open import Relation.Binary.Definitions using (Transitive)
open import Relation.Binary.PropositionalEquality using (_≡_; refl)
```

逐行交代用途，后面就不会有「这名字哪来的」：

| 进口 | 用途 |
|---|---|
| `Bool`/`true`/`false`/`_∨_`/`if_then_else_` | `contains-var` 是 Bool 谓词；`λ*` 与 `subst` 用 `if _ then _ else _` 分派 |
| `ℕ`/`suc`/`_+_` | 49.9 的尺寸账 |
| `Σ`/`_,_` | `keep` 的返回类型（49.4） |
| `String`/`_==_` | 变量名与它的**布尔**相等判定 |
| `Transitive` | 用 stdlib 的抽象来验收我们自己造的 `tc-trans`（49.6） |
| `_≡_`/`refl` | 一切等式，以及全部算例的验收手段 |

第一行 `{-# OPTIONS --safe #-}` 值得单独说一句：本章**只需要** `--safe`。
上一章（48 章）为了演示负类型必须摘掉 positivity 检查，那一下就被 `--safe`
拒了；本章所有定义都是结构递归、所有定理都是真证明，所以 `--safe` 挂上去
一路绿灯。这是「安全的元理论」与「危险的类型」之间最直观的对照。

变量的来源只有一个新构造子：

```agda
data varcomb : Set where
  S K : varcomb
  app : (a b : varcomb) → varcomb
  var : (s : String) → varcomb
```

`varcomb` 与 35 章的 `comb` 逐字同构，只多了 `var`。变量的类型选什么无所谓
——它只参与名字比较，不参与任何逻辑，所以用最省事的 `String`。书里的例子
`S K x` 就是：

```agda
S-K-x : varcomb
S-K-x = app (app S K) (var "x")
```

注意 `app` 是左结合的元语言事实：`S K x` 是 `app (app S K) (var "x")`，
即「把 S 和 K 凑成一个部分应用，再喂给 x」。整个章节都在跟这个形状打交道。

## 49.2 把小步语义搬到 varcomb

归约规则与 35 章完全同名，只是宿主类型换掉了：

```agda
infix 4 _↝_
data _↝_ : varcomb → varcomb → Set where
  ↝K : ∀ a b → app (app K a) b ↝ a
  ↝S : ∀ a b c → app (app (app S a) b) c ↝ app (app a c) (app b c)
  ↝C1 : ∀ {a a′} (b : varcomb) → a ↝ a′ → app a b ↝ app a′ b
  ↝C2 : (a : varcomb) → ∀ {b b′} → b ↝ b′ → app a b ↝ app a b′
```

四条规则的分工，用一句「谁吃掉参数、谁复制参数」就能背下：

- `↝K`：**丢弃**。`K a b ↝ a`，第二个参数 `b` 整个消失。
- `↝S`：**分发**。`S a b c ↝ a c (b c)`，第三个参数 `c` 被复制给前两个分支。
- `↝C1`/`↝C2`：**进上下文**。左子树/右子树能归约，整棵树就能归约。
  这两条的 `b` 用可见参数、`a`/`a′` 用隐式，是 35 章定下的写法：
  被归约的那一段是"局部事件"，上下文只需在类型里出现，不必每次点名。

为什么不直接 `open import Ex35_combinators` 复用那条 `_↝_`？因为它的类型是
`comb → comb → Set`，而这里两端必须是 `varcomb`。原书作者自己也把这次重抄
称作「令人遗憾的重复」（regrettable duplication），他的取舍是不让前面已经
建好的开发背上索引参数的负担。这一章接受同样的取舍，但要留下一条**可迁移的
判断力**：

> 归纳定义的**规则形状**可以参数化（见 49.6 的 `Closure` 模块——它就是靠
> 参数化逃过了第二次重抄），但归纳定义的**类型本身**参数化不起：
> 一旦把 `S`/`K`/`app` 提成参数，四条规则里每条都得再写一遍约束，
> 读者与检查器同时付双倍的钱。

后面几乎每条定理都要用「K 吞掉第二个参数」这个动作，先钉一发当弹药：

```agda
K-drops : ∀ (a : varcomb) → app (app K S) a ↝ S
K-drops a = ↝K S a
```

`↝K S a` 展开是 `app (app K S) a ↝ S`——`a` 被丢掉了，`S` 留下。这一行就是
49.3 里第一条方程的全部理由。

## 49.3 λ\*：四条方程，K 造常数、S 做分发

```agda
λ* : (s : String) → varcomb → varcomb
λ* s S = app K S
λ* s K = app K K
λ* s (app c₁ c₂) = app (app S (λ* s c₁)) (λ* s c₂)
λ* s (var s′) = if s == s′ then app (app S K) K else app K (var s′)
```

这个算法的全部直觉是：**「参数来了怎么办」只有两种基本手法**——
无视它（`K`）、把它分给子表达式（`S`）。逐条读，每条都配一步演算：

**① `λ* s S = app K S`。** 我们要的是 `λs.S`：拿到任何参数都返回 `S`。
而 `app K S` 拿到 `a` 时 `app (app K S) a ↝ S`（正是上面的 `K-drops`）。
行为一致。`λ* s K` 同理，产出 `app K K`。

**② `λ* s (app c₁ c₂) = app (app S (λ* s c₁)) (λ* s c₂)`。**
`λs.(c₁ c₂)` 拿到参数 `a` 应该变成 `(λs.c₁ a) (λs.c₂ a)`——参数要送给**两边**。
这正是 `S` 的语义：把 `↝S` 规则的方向倒过来读，

```text
app (app (app S (λ* s c₁)) (λ* s c₂)) a  ↝  app (app (λ* s c₁) a) (app (λ* s c₂) a)
```

`S` 就是那台「把最后一个参数同时递给前两个」的机器，所以它天然是消元时
分派参数的工具；`K` 则是「把参数丢掉」的工具。整个算法只用这两件事。

**③ 变量分两种。** 命中要消的那个变量时，`λs.s` 就是恒等函数，而恒等函数
在组合子语言里的名字是 `S K K`：

```text
app (app (app S K) K) a  ↝  app (app K a) (app K a)  ↝  a
```

第一步用 `↝S`（复制参数），第二步用 `↝K`（丢掉多出来的那份）。这两步正是
49.7 的 `id↝` 引理的全部内容。没命中时，`λs.s′`（`s ≠ s′`）无视参数返回
`var s′`，于是 `app K (var s′)`。

最后一条方程里那个 `if s == s′ then … else …` 用的是 `Data.String` 的布尔
相等 `_==_`。这里是本章唯一一处版本坑的高危地带，先把结论钉住：原书的
`=string` 对应 3.0 的 `_==_`，**不是**很多人第一反应的 `_≟_`——后者在 3.0
返回 `Dec (s ≡ s′)` 而不是 `Bool`，而且已挂弃用警告（两段原文见 49.11 坑位 1）。

## 49.4 定理一：产出里确实没有那个变量

先把「有没有变量」写成可计算的谓词：

```agda
contains-var : String → varcomb → Bool
contains-var s S = false
contains-var s K = false
contains-var s (app c₁ c₂) = contains-var s c₁ ∨ contains-var s c₂
contains-var s (var s′) = s == s′
```

这个谓词是「语法层」的：它只查变量名出没出现，完全不管归约。

证明里唯一的技巧需要一件工具，先把它备好。裸 `with (s == s′)` 只能拿到
`true`/`false` 这个**值**，等式「`s == s′` 就是 true/false」当场蒸发，
`rewrite` 就没料可用。19 章第 4 节教过的 `keep` 就是为这一刻准备的：

```agda
keep : ∀ {A : Set} (x : A) → Σ A (λ y → x ≡ y)
keep x = x , refl
```

`keep x` 返回一对：值 `x` 本身，以及「`x ≡ x`」这条等式。把它套在
`s == s′` 上做 `with`，分派到 `true`/`false` 的同时，那条等式作为配对的第二项
留在上下文里，`rewrite p` 就有东西可用（stdlib 里同一个主意的现代拼写是
`Function.Inspect` 的 `inspect`；`keep` 是本教程从 19 章沿用下来的老名字）。

工具就位，定理长得非常老实：

```agda
λ*-binds : ∀ (s : String) (v : varcomb) → contains-var s (λ* s v) ≡ false
```

四个分支对应 `varcomb` 的四个构造子。前三个是白送的：

```agda
λ*-binds s S = refl
λ*-binds s K = refl
λ*-binds s (app c₁ c₂) rewrite λ*-binds s c₁ | λ*-binds s c₂ = refl
```

`app` 分支读法：目标是 `contains-var s c₁ ∨ contains-var s c₂ ≡ false`，
两条归纳假设（IH）各把一边改写成 `false`，`_∨_` 的两个参数都是构造函数
字面量，`refl` 直接闭合。这就是 13 章讲的「rewrite 只走左→右」的又一次兑现。

第四个分支才用上 `keep`：

```agda
λ*-binds s (var s′) with keep (s == s′)
λ*-binds s (var s′) | true , p rewrite p = refl
λ*-binds s (var s′) | false , p rewrite p = p
```

两行的区别很值得停下来看：

- `true` 分支：`rewrite p` 把 `s == s′` 换成 `true`，于是 `λ*` 产出
  `app (app S K) K`，`contains-var` 一路规约成 `false ∨ false`，目标是
  `false ≡ false`，`refl` 收工。
- `false` 分支：`rewrite p` 之后目标是
  `contains-var s (app K (var s′)) ≡ false`，即 `false ∨ (s == s′) ≡ false`，
  也就是 `(s == s′) ≡ false` ——**这正是 `p` 自己的类型**，所以这一行写 `= p`。

第二支不能图省事写 `= refl`：`rewrite p` 只替换它认得出来的那一份
`s == s′`，`contains-var` 展开后还有第二份没跟着变，于是 `refl` 要证的成了
「一个未归约的 `isYes (map′ …)` 等于 `false`」，检查器直接拒绝。实测原文：

```text
error: [UnequalTerms]
The terms
  Relation.Nullary.isYes
  (Relation.Nullary.map′ Data.String.Properties.≈⇒≡
   Data.String.Properties.≈-reflexive
   (Data.List.Relation.Binary.Pointwise.Properties.decidable
    Data.Char.Properties._≡?_ (Data.String.toList s)
    (Data.String.toList s′)))
and
  false
are not equal at type Bool
when checking that the expression refl has type
contains-var s (if false then app (app S K) K else app K (var s′))
≡ false
```

把这条报错读透：`Data.String.toList s` 那一路是 `_==_` 的**内部实现**
（把字符串拆成字符表逐位判定），检查器把它展开到底给你看，然后说「这东西
我没法凭空等于 `false`」。它缺的就是 `p` 那一句「它确实等于 false」。**证据
在依赖类型里不能靠直觉补，得亲手递过去。**

## 49.5 替换：β 的另一半

λ 演算的 β 规则是「把参数代进体里」。要在组合子语言里陈述「`λ*` 的行为
等同 λ 抽象」，就得先有代入：

```agda
subst : varcomb → String → varcomb → varcomb
subst c s S = S
subst c s K = K
subst c s (app c₁ c₂) = app (subst c s c₁) (subst c s c₂)
subst c s (var s′) = if s == s′ then c else var s′
```

四条方程：常量原样、应用递归、命中变量换成 `c`、未命中保留。参数顺序
「被代入的项在最前」（`subst c s v`）照原书，读的时候心里翻译成「把 `c`
代进 `v` 里所有的 `s`」即可。

两个算例把「命中」与「不命中」各钉一发，`refl` 验收：

```agda
subst-demo : subst (var "y") "x" (app (var "x") (var "z")) ≡
             app (var "y") (var "z")
subst-demo = refl

subst-miss : subst (var "y") "x" (app (app S K) (var "z")) ≡
             app (app S K) (var "z")
subst-miss = refl
```

`subst-demo` 里只有 `var "x"` 被换掉，`var "z"` 原地不动；`subst-miss` 里
一个都没命中，整项不变。

一条自然的追问：49.4 已经证明产出**不含** `s`，那代入它就该是空的，为什么不
把「不含 ⇒ 代入是恒等」写成引理？因为主定理 `λ*-↝` 用不上它——`λ*` 与 `subst`
用的是**同一个**判定 `s == s′`，四个分支的目标都在检查器眼前规约到底：`S`/`K`
分支的 `subst v₂ s S` 直接是 `S`，变量分支两边各自 case-split。也就是说，
这条引理的内容已经被「同构的定义」免费给了。反过来，如果 `contains-var` 与
`subst` 用两套不同的判定（比如一个用 `_==_`、一个用 `_≡?_`），这条引理就立刻
变成必需品——这是依赖编程里一个可复用的嗅觉：**定义共享规约，证明就能省；
定义分叉，证明就要补。**

## 49.6 一步不够：传递闭包模块 `tc`

主定理要说的是「应用 `λ*` 的产出**会归约到**代入结果」。这个「会归约」往往
不是一步：`app (app (app S K) K) a ↝⁺ a` 需要两步（`↝S` 再 `↝K`）。所以先把
多步归约造出来。

造法不是给每条规则再抄一遍，而是把「关系的传递闭包」抽成一个参数化模块——
本教程第一次正经用「模块参数化在一个关系上」这个手法（09 章的模块参数化
用在类型上，这里用在关系上）：

```agda
module Closure {A : Set} (_>_ : A → A → Set) where
  data tc : A → A → Set where
    tc-step : ∀ {a b} → a > b → tc a b
    tc-trans : ∀ {a b c} → tc a b → tc b c → tc a c
```

读法与 14 章「命题即数据」完全一样：`tc a c` 的证据要么是**一步**
（`tc-step`：原关系里有的，闭包里也有），要么是**两段接起来**（`tc-trans`）。
这就是离散数学里「最小的传递扩张」的归纳定义写法——两条规则，不多不少。

实例化到本章的关系上：

```agda
open Closure _↝_

infix 4 _↝⁺_
_↝⁺_ : varcomb → varcomb → Set
_↝⁺_ = tc
```

`open Closure _↝_` 是**模块应用**：把 `Closure` 里的 `A` 定为 `varcomb`、
`_>_` 定为 `_↝_`，于是里面那个 `tc` 现在是「`↝` 的传递闭包」。别名
`_↝⁺_ = tc` 只是把数学记号 `↝⁺` 接上（书里用 `_;+_`，本教程沿用 35 章的
箭头风格）。

两件顺手的小事：

```agda
lift : ∀ {a b} → a ↝ b → a ↝⁺ b
lift = tc-step

↝⁺-trans : Transitive _↝⁺_
↝⁺-trans = tc-trans
```

`lift` 把一步归约举成多步（后面每条定理的基例都用它）。第二组更值得看一眼：
stdlib 的 `Transitive Rel` 展开就是
`∀ {a b c} → Rel a b → Rel b c → Rel a c`，与 `tc-trans` 的**类型逐字同形**，
所以整个证明就是「把 `tc-trans` 交出去」这一行。这是本教程第三次撞见同一件事
（24 章 intrinsic、47 章 `Soundness = soundness`）：

> 自己造的证明项常常已经在 stdlib 的某个抽象名字下住了；`Transitive`/
> `Reflexive`/`Symmetric` 这些不是新语法，只是给既有形状起的名。

最后手拼一条两步序列，看清 `tc-trans` 只是胶水：

```agda
two-steps : app (app (app S K) K) (app K K) ↝⁺ app K K
two-steps =
  tc-trans (tc-step (↝S K K (app K K)))             -- ↝ K (K K) (K (K K))
           (tc-step (↝K (app K K) (app K (app K K))))  -- ↝ K K
```

第一段的注释标出中项：`S K K (K K)` 经 `↝S` 变成 `K (K K) (K (K K))`；
第二段用 `↝K`，左半的 `K` 把右半整个吞掉，剩下 `K K`。两条 `tc-step` 由
`tc-trans` 接成一条长度 2 的序列。

一个容易搞错的口径：`↝⁺` 是**一步或多步**，不含「零步」。想要带自反的那版
（`↝⋆`，35 章我们自己造过 `id↝`/`step↝`），stdlib 的现成件是
`Relation.Binary.ReflexiveClosure`。本章只需要 `↝⁺`，因为每次结论确实至少
走了一步。

## 49.7 三块垫脚石：恒等组合子与两条同余

第一块就是 49.3 里那两行演算的正式版本：

```agda
id↝ : ∀ (a : varcomb) → app (app (app S K) K) a ↝⁺ a
id↝ a = tc-trans (tc-step (↝S K K a)) (tc-step (↝K a (app K a)))
```

`↝S K K a` 给 `S K K a ↝ K a (K a)`；`↝K a (app K a)` 给
`K a (K a) ↝ a`（第二个参数 `K a` 被丢掉）。两段接起来，恒等组合子的行为
就落在了 `↝⁺` 里。

第二、三块补的是 `tc` 的一个真实缺口。直觉会说：「`↝` 有两条同余规则
（`↝C1`/`↝C2`），那 `↝⁺` 当然也有。」**错。** `tc` 只保证「序列能接起来」，
不保证「序列能塞进上下文」。想直接用一步同余蒙过去，检查器立刻给你一条
类型不匹配：

```text
error: [UnequalTypes]
The type
  tc a a′
is not a subtype of
  a ↝ a′
when checking that the expression d has type a ↝ a′
```

报错点名的正是要害：`↝C1 b` 的第二个参数要的是**一步** `a ↝ a′`，
而我们手上是整段序列 `tc a a′`。方向也反过来不行——`↝⁺` 比 `↝` 大，
小的喂不了大的。所以同余必须重新证明，证明方法是对**归约序列本身**归纳：

```agda
trans-Cong1 : ∀ {a a′} (b : varcomb) → a ↝⁺ a′ → app a b ↝⁺ app a′ b
trans-Cong1 b (tc-step d) = tc-step (↝C1 b d)
trans-Cong1 b (tc-trans d₁ d₂) =
  tc-trans (trans-Cong1 b d₁) (trans-Cong1 b d₂)

trans-Cong2 : ∀ (a : varcomb) {b b′} → b ↝⁺ b′ → app a b ↝⁺ app a b′
trans-Cong2 a (tc-step d) = tc-step (↝C2 a d)
trans-Cong2 a (tc-trans d₁ d₂) =
  tc-trans (trans-Cong2 a d₁) (trans-Cong2 a d₂)
```

两条引理的形状一模一样，只有「上下文在左还是在右」的分别。它们的正确性
可以用一张图讲完：假设有一段序列

```text
c₀ ↝ c₁,  c₁ ↝ c₂,  …,  cₙ₋₁ ↝ cₙ
```

要给 `c₀ b ↝⁺ cₙ b`，做法是**在每一步下面加一层上下文**：

```text
c₀ ↝ c₁        ⟹  c₀ b ↝ c₁ b
c₁ ↝ c₂        ⟹  c₁ b ↝ c₂ b
⋮                        ⋮
cₙ₋₁ ↝ cₙ      ⟹  cₙ₋₁ b ↝ cₙ b
```

`trans-Cong1` 的两条分支就是这张图的两半：`tc-step` 是「只有一步」，
加一层上下文用 `↝C1`；`tc-trans` 是「序列被分成两段」，两段各自加上下文
（两次递归调用）再用 `tc-trans` 接回来。

这里顺手解决一个读者会从 35 章带过来的疑虑：**为什么这两条引理不需要
`Acc`？** 因为递归顺着的是 `tc` 这个**归纳定义的证明对象**走：`tc-trans`
的两支 `d₁`/`d₂` 在语法上就是原证明的真子项，终止检查一眼放行。35 章的
`normalize` 之所以要额外收一个 `Acc` 参数，是因为它递归顺着**项**走，而
`step?` 吐出的归约结果并不是原项的子模式（语法上没有变小，只有语义上变小）。
一条可复用的判断力：

> 递归参数选**证明**还是选**数据**，决定了要不要良基机器。归约序列本身
> 是免费的归纳假设；项不是。

## 49.8 主定理：`λ*` 的产出行为等同 λ 抽象

现在可以陈述并证明本章的目标了。陈述要读三遍——它说的是「对任意体 `v₁`、
任意参数 `v₂`、任意变量名 `s`，把 `λ*` 的产出应用到 `v₂` 上，会多步归约到
`v₂` 代进 `v₁` 的结果」，即 β 规则的组合子版：

```agda
λ*-↝ : ∀ (v₁ v₂ : varcomb) (s : String) →
       app (λ* s v₁) v₂ ↝⁺ subst v₂ s v₁
λ*-↝ S v₂ s = lift (↝K S v₂)
λ*-↝ K v₂ s = lift (↝K K v₂)
λ*-↝ (app c₁ c₂) v₂ s =
  tc-trans (tc-step (↝S (λ* s c₁) (λ* s c₂) v₂))
    (tc-trans (trans-Cong1 (app (λ* s c₂) v₂) (λ*-↝ c₁ v₂ s))
              (trans-Cong2 (subst v₂ s c₁) (λ*-↝ c₂ v₂ s)))
λ*-↝ (var s′) v₂ s with keep (s == s′)
λ*-↝ (var s′) v₂ s | true , p rewrite p = id↝ v₂
λ*-↝ (var s′) v₂ s | false , p rewrite p = lift (↝K (var s′) v₂)
```

四个分支逐个看。

**`S`/`K` 分支**：`λ* s S = K S`，于是左边是 `app (app K S) v₂`，`↝K` 一步
到 `S`；右边 `subst v₂ s S` 按定义就是 `S`。目标与 `↝K S v₂` 的类型相差一层
`lift`，一步即多步。`K` 分支逐字相同。这两个分支里没有归纳假设，是纯
definition-folding 的白送。

**`app` 分支**：三步棋，全章最难的一段，值得用数学写法摊开。左边先展开
`λ*`：

```text
app (λ* s (app c₁ c₂)) v₂
= app (app (app S (λ* s c₁)) (λ* s c₂)) v₂
```

- ① `↝S`：`S` 把 `v₂` **同时**递给 `(λ* s c₁)` 和 `(λ* s c₂)`：

  ```text
  ↝ app (app (λ* s c₁) v₂) (app (λ* s c₂) v₂)
  ```

- ② `trans-Cong1 (app (λ* s c₂) v₂) (λ*-↝ c₁ v₂ s)`：归纳假设 IH₁ 说的是
  `app (λ* s c₁) v₂ ↝⁺ subst v₂ s c₁`，**子项**级别的结论。把它塞进「右边
  不动」的上下文 `app □ (app (λ* s c₂) v₂)`，得到整项级别的一步推进：

  ```text
  ↝⁺ app (subst v₂ s c₁) (app (λ* s c₂) v₂)
  ```

- ③ `trans-Cong2 (subst v₂ s c₁) (λ*-↝ c₂ v₂ s)`：再用 IH₂ 把右半换掉：

  ```text
  ↝⁺ app (subst v₂ s c₁) (subst v₂ s c₂)   =   subst v₂ s (app c₁ c₂)
  ```

最后那个等号是 `subst` 的第三条方程，方向从右到左，检查器自己在类型里比。
两个 `tc-trans` 把三段接成一条完整序列。

这一支最值得记住的不是技巧，而是**同余为什么非用不可**：归纳假设的结论
住在子项上，目标住在整项上，中间那道桥就是 49.7 的 `trans-Cong1`/`2`。
没有 `tc` 的那两条免费规则，主定理在这里直接卡死——这也是原书特意在
正文里点出来的「wrinkle（小褶皱）」。

**`var` 分支**：又一次 `keep` + `rewrite`。`true`（命中）时
`λ* s (var s′)` 产出 `S K K`，`subst v₂ s (var s′)` 产出 `v₂`，正好是 `id↝ v₂`；
`false`（未命中）时产出 `K (var s′)`，`subst` 保留 `var s′`，于是一步 `↝K`
就够，即 `lift (↝K (var s′) v₂)`。

最后把主定理实例化到一个具体项上，让「行为等同」落到看得见的位置：

```agda
β-at-S : app (λ* "x" (var "x")) S ↝⁺ S
β-at-S = λ*-↝ (var "x") S "x"
```

检查这一行时 Agda 自己完成三件事：算出 `λ* "x" (var "x") = app (app S K) K`；
算出 `subst S "x" (var "x") = S`；然后确认 `λ*-↝` 那条一般定理在这个实例上的
类型正好是写出来的目标。**证明项复用为具体证据**，这是「定理即程序」在
元理论层的样本，与 47 章 `nbe` 的品味相同。

## 49.9 算例：把 Agda 当计算器（原书习题 1 的四项 + 尺寸账）

`λ*` 是纯函数，所以「翻译 λ 项」这种活儿完全可以让检查器代劳——把答案写进
等式右边，用 `refl` 验收。下面四组的结果**全部**是 Agda normalize 出来的，
不是手算：

```agda
abs-a : varcomb
abs-a = λ* "x" (λ* "y" (var "x"))

abs-a-is : abs-a ≡ app (app S (app K K)) (app (app S K) K)
abs-a-is = refl
```

即 `λx.λy.x` ↦ `S (K K) (S K K)`。读法：内层 `λy.x` 里 `y ≠ x`，得 `K (var x)`；
外层对 `app K (var x)` 消 `x`，用 `S` 分发：`S (λx.K) (λx.x) = S (K K) (S K K)`。

```agda
abs-b : varcomb
abs-b = λ* "x" (λ* "y" (var "y"))

abs-b-is : abs-b ≡
           app (app S (app (app S (app K S)) (app K K))) (app K K)
abs-b-is = refl
```

即 `λx.λy.y` ↦ `S (S (K S) (K K)) (K K)`。内层 `λy.y` 得 `S K K`（与 `x`
无关），外层对 `app (app S K) K` 消 `x`：`app` 分支用 `S` 分发，左半
`app S K` 本身又是应用，于是再分发一次得到 `S (K S) (K K)`，右半 `K`
与 `x` 无关，变成 `K K`。行为上整体等价于 `K I`，但算法不知道这件事。

```agda
abs-c : varcomb
abs-c = λ* "s" (λ* "z" (app (var "s") (var "z")))

abs-c-is : abs-c ≡
  app (app S
         (app (app S (app K S))
              (app (app S (app K K)) (app (app S K) K))))
      (app (app S (app (app S (app K S)) (app K K))) (app K K))
abs-c-is = refl
```

第三项最有意味：`λs.λz. s z` **η-等价于恒等函数**（把参数原样传下去），
组合子却长成这一大坨。这就是最小 bracket abstraction 算法的诚实报价：
它只做变量消除，不做任何优化，η 化简、公共子表达式一概不管。

```agda
abs-d : varcomb
abs-d = λ* "x" (app (var "x") (var "x"))

abs-d-is : abs-d ≡ app (app S (app (app S K) K)) (app (app S K) K)
abs-d-is = refl
```

即 `λx. x x` ↦ `S (S K K) (S K K)`：两个子项都命中变量，所以两侧各自变成
`S K K`，再由 `S` 分发。这一项是自指的源头，也是为什么「组合子语言里
`λx. x x` 能造出 Ω」——它跟 48 章那条终止性防线正好是同一件事的两面。

尺寸账用 35 章同一个 `size`（数结点个数）：

```agda
size : varcomb → ℕ
size S = 1
size K = 1
size (var s) = 1
size (app a b) = suc (size a + size b)

size-x : size (var "x") ≡ 1
size-x = refl

size-I : size (λ* "x" (var "x")) ≡ 5
size-I = refl

size-xx : size (λ* "x" (app (var "x") (var "x"))) ≡ 13
size-xx = refl

size-xyx : size (λ* "x" (λ* "y" (var "x"))) ≡ 11
size-xyx = refl

size-c : size abs-c ≡ 35
size-c = refl

-- 逐层记账：消掉内层 z 之后是 11，再消外层 s 才是 35。
size-inner : size (λ* "z" (app (var "s") (var "z"))) ≡ 11
size-inner = refl
```

四笔账摆出来：`x ↦ x` 是 1 → 5，`x x ↦ x x` 是 3 → 13，`λy.x` 是 3 → 11，
`λs.λz. s z` 是 3 → 11 → 35（体本身 3 个结点，消掉内层 `z` 变 11，再消 `s`
变 35）。原书说「我们采用的这个算法把尺寸翻一倍还不止」，
现在有机器验收的数字。原因在结构上：`app` 分支要为**两个**子项各造一份
`λ*`，所以每层应用都乘一次系数；而 `K`/`S`/未命中变量这些「无关」分支还要
各自再套一层 `K`。原书提到的替代算法（`I`/`B`/`C` 等派生组合子）正是拿
「给语法加构造子」换「少长几层」——那是原书习题 4 的意思，也是编译器
后端一直在做的取舍。

顺带把 49.4 与 49.8 的关系钉一下：`λ*-binds` 与 `λ*-↝` 一个说「产出里没有
变量」，一个说「产出行为等同 λ」。第一条是**语法**陈述（Bool 谓词 ≡ false），
第二条是**语义**陈述（归约关系里可达）。两条合起来才叫「correct
translation」，这也是本章为什么要费劲造 `tc`：**纯语法定理用不着归约机器，
行为等价一定用得到。**

## 49.10 这章在全书里的位置

把本章放回地图上看，它是三条线的交点：

- **与 35 章**：那是同一条线的上半段——语法、小步语义、终止性。35 章结束在
  「S 自由片段可归一化」，本章补上「语法能表达函数、而且翻译正确」。
  两章合起来才是组合子语言的完整故事：**能算 + 算得对**。
- **与 46/47 章**：Curry–Howard 把 `λx. t` 读成证明里的 `⇒I`，把应用读成
  `⇒E`。于是本章的 `λ*` 有一条教科书没点破的解读：它是**证明到组合子的翻译**
  ——消掉「绑定」这个语法结构，只留 `S`/`K` 两个原语。47 章的 `nbe` 走的是
  相反路线：不消语法，而是给语法一个函数空间的语义、再按结构读回。两条路
  都通向「正规形」，一条靠组合子代数，一条靠真值语义。
- **与 48 章**：上一章演示 Agda 会**拒绝**什么（负类型），本章演示 Agda 顺利
  **接受**什么：结构递归的算法、归纳定义的语义、对证明的归纳。连 `--safe`
  都不用摘，一句 postulate 也没有。对照着读，「这道防线不是装饰」这件事
  就有了两面。

可复用的手艺清单（都能在正文里指回去）：`keep`/`inspect` 保住等式（49.4、
19 章）；`rewrite` 走 IH 把 Bool 目标折叠（49.4）；模块参数化在**关系**上，
一次定义到处实例化（49.6 的 `Closure`）；自造证明与 stdlib 抽象逐字同形
（49.6 的 `Transitive`）；递归顺着证明走就不需要良基机器（49.7 与 35 章的
对照）；把计算写进等式让检查器验收（49.9，03 章就立的规矩）。

## 49.11 坑位清单（实测）

1. **`_≟_` 在 stdlib 3.0 不是布尔相等，而且已弃用**：照原书 `=string` 的
   直觉写 `if s ≟ s′ then …` 一次吃两条：

   ```text
   warning: -W[no]UserWarning
   Warning: _≟_ was deprecated in v3.0.
   Please use _≡?_ instead.
   when scope checking a ≟ b

   error: [UnequalTypes]
   The type
     Dec (a ≡ b)
   is not a subtype of
     Bool
   when checking that the expression a ≟ b has type Bool
   ```

   姿势：布尔判定用 `Data.String` 的 `_==_`，决策过程用 `_≡?_`；`_≟_` 在
   3.0 只是 `_≡?_` 的带警告别名（示例文件里已按此写法）。

2. **裸 `with (s == s′)` 丢掉等式，`rewrite` 无从下手**：`false` 分支写
   `refl` 报 49.4 那段 `UnequalTerms`（`isYes (map′ …)` 与 `false` 不等）。
   姿势：`with keep (s == s′)`（19 章）或 stdlib 的 `inspect`，把等式一起
   带进上下文。

3. **`rewrite p` 只换它认得的那一份出现**：同一分支写完 `rewrite p` 再写
   `refl` 仍然失败（第 2 条同款报错），而 `= p` 立刻通过。原因：`contains-var`
   展开后的第二份 `s == s′` 不在 rewrite 的替换范围内。姿势：**目标恰好就是
   手上那条等式时，直接把它交出去**，别硬凑 `refl`。

4. **拿 `with (s ≡? s′)` 去证关于 `_==_` 的定理不成立**：报错把目标显示成
   `if isYes (no ¬p) then …` ——决策过程那一份被抽象掉了，`isYes` 却没跟着
   规约到构造子：

   ```text
   error: [UnequalTerms]
   The terms
     Relation.Nullary.isYes (…  (Data.String.toList s) (Data.String.toList s′))
   and
     false
   are not equal at type Bool
   ```

   结论：谓词是 Bool -valued 时，分派也要用 Bool + keep；想用 `Dec` 就得把
   case 做进函数定义本身（见下一条）。

5. **把 case 做进 `λ*` 的定义能过，但 `contains-var` 依旧挡路**：把
   `λ* s (var s′)` 改写成 `with (s ≡? s′)` + `yes refl`/`no ¬p` 两支，定义本身
   类型检查通过，`λ*-binds` 的命中支也 `refl` 闭合；未命中支仍报

   ```text
   error: [UnequalTerms]
   …
   when checking that the expression refl has type
   contains-var s (λ* s (var s′) | no ¬p) ≡ false
   ```

   姿势：Bool 谓词与 `Dec` 定义不要混用；本章统一走书的 `keep` 路线。

6. **`with` 分支左端的变量必须同名，写反立刻被拒**：把未命中支写成
   `λ* s′ (var s′) | no ¬p`（想让「第一个参数」也叫 `s′`）报

   ```text
   error: [UnequalTerms]
   The terms
     s′
   and
     s′₁
   are not equal at type String
   when checking that all occurrences of pattern variable s′ have the
   same value
   ```

   姿势：with-分支照抄父分支的左端，只多写 `| …`；要引入新名字先想清楚
   它和父分支哪些出现必须重合。

7. **传递闭包没有免费同余**：把一步规则直接用到序列上（`bad b d = tc-step
   (↝C1 b d)`）报 `The type tc a a′ is not a subtype of a ↝ a′`（原文见 49.7）。
   姿势：`trans-Cong1`/`trans-Cong2` 必须自己证，对序列归纳。

8. **`Transitive` 不在 `Relation.Binary.Core`**：写成
   `open import Relation.Binary.Core using (Transitive)` 先吃一条劝告级警告
   再吃致命错误——警告里那句「did you mean」很啰嗦但方向正确：

   ```text
   warning: -W[no]ModuleDoesntExport
   The module Relation.Binary.Core doesn't export the following:
     Transitive
   error: [NotInScope]
   Not in scope:
     Transitive
   ```

   姿势：3.0 把 `Reflexive`/`Symmetric`/`Transitive` 这类**定义**放在
   `Relation.Binary.Definitions`（`Core` 只留关系/偏序的基础别名）。同一条
   普查在 44 章的迁移清单里也有位置。按 102 条的规矩，警告当错误读。

9. **`λ*` 这样的标识符合法**（正面事实）：`λ` 与 `*` 都能进 Agda 的名字，
   `λ* : (s : String) → …` 直接通过，不必像原书排版那样退回 `lambda`。
   但要留意字形：`λ*` 与 `λ`（本教程 04 章的匿名函数）在等宽字体里只差
   一个星号，读代码时先确认是哪个。

10. **名字带连字符没问题**：`contains-var`、`subst-demo`、`λ*-binds`、
    `S-K-x` 全部合法（01 章的「模块名不能以数字开头」才是硬规矩，普通标识符
    里的 `-` 不受影响）。

11. **`--safe` 与本章零冲突**（对照 48 章第 106 条式的取舍）：本文件第一行
    就挂 `{-# OPTIONS --safe #-}`，全程通过。48 章的 `--no-positivity-check`
    会被 safe 模式直接拒（`[SafeFlagPragma]`），差别正说明「正常元理论」
    不需要任何逃生门。

12. **尺寸反直觉**：`λs.λz. s z` 语义上就是恒等，`λ*` 产出 35 个结点
    （`size-c`）。别指望 bracket abstraction 顺带做化简——它只保证
    「消掉变量」和「行为等价」，η 与公共子表达式不在账单里。想在归约层
    省长度，得换算法（原书习题 4），那是编译器的事。

---

上一章：[48 · 负类型与 strict positivity：Agda 的第二道守门检查](48-negative-datatypes.md) ｜ 下一章：暂无（全书完；45 是主线收官章，43–44 为附录，46–49 是元理论、语言防线与 λ 消除的最后一块） ｜ 返回：[README](../README.md)
