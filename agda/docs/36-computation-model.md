# 36 · Agda 的计算模型：规范化、卡住项与 copattern

从本章起进入**书本篇**（36–44 章）：以两本 Agda 教材为蓝本扩充教程——
Sandy Maguire《Certainty by Construction: Software and Mathematics in
Agda》与 Aaron Stump《Verified Functional Programming in Agda》。
本章取材 Maguire 第一章的 1.8–1.16 节，回答一个前面 35 章一直默认、
却从没正面交代的问题：**Agda 到底怎么「算」**。为什么 `3 + 0` 一行
`refl` 就过、`n + 0` 就非归纳不可（13 章）？为什么有的函数定义写两行、
有的写四行，语义相同却「好证」差出天？record 为什么能白送 η 等式而
函数不能？答案全部落在两个词上：**规范化（normalization）**与
**卡住（stuckness）**。把这两个词想明白，前面几十章里「凭手感」的部分
会一次性转正。

对应示例：`../examples/Ex36_computation-model.agda`

本章报错/警告文本均为 Agda 2.9.0 + stdlib 3.0 实测原样粘贴
（复现用的临时探针文件已删除，报错路径显示为当时的探针路径）。

## 36.1 Agda 没有「运行」，只有规范化

Maguire 的心智模型一句话：**每个函数定义都是一组「左形 = 右形」的
重写规则；求值就是不停地拿外层表达式去匹配规则的左边，匹配上就替换
成右边，直到无规则可套**。这个过程叫规范化（normalize），套不出来的
最终形态叫正规形（normal form）。交互式工具里对应的命令是
Normalise（Emacs/VSCode 的 `C-c C-n`），给它任意表达式，它在信息窗
吐正规形——没有执行、没有状态、没有时间，只有代入。

手算一遍 `not (not false)`：

1. 外层 `not (…)`：`not` 的两条规则只认 `not true` 与 `not false`
   这种「参数是构造子」的形状，而这里的参数是**调用** `not false`，
   匹配不上——外层先不动；
2. 内层 `not false` 命中规则，变成 `true`；
3. 整个式子随之变成 `not true`，现在外层能匹配了，变 `false`；
4. `false` 是构造子，无规则可套，收工。

不想手算就写一枚「单元测试」——03 章见过、Maguire 书里正式命名：

```agda
_ : not (not false) ≡ false
_ = refl
```

`_` 是「我不关心这个名字」的写法；整个测试只用到 11 章的 `≡` 和
唯一的构造子 `refl`：**`refl` 通过 ⇔ 两侧规范化后同语法**。想把
结论说谎成 `true`，整个文件直接不过检查（实测）：

```text
/Volumes/mac004/code/programming/agda/examples/TmpProbe36f.agda:5.5-9: error: [UnequalTerms]
The terms
  false
and
  true
are not equal at type Bool
when checking that the expression refl has type
not (not false) ≡ true
```

Agda 的单元测试**只在失败时开口**，失败即编译失败——「no news is
good news」是 Maguire 的原话。这与 20 章的 `--compile` 流水线并不
矛盾：真要让 GHC 生成可执行文件时，Agda 仍会把这套语义翻译过去，
但**类型检查阶段所见的一切「计算」都是规范化**，与运行无关。

顺带记一笔报错文案：2.9.0 的等式不成立报错是
`The terms … and … are not equal at type …` 三段式，
与 13 章引用的 2.8 时代 `… !=< …` 文案不同（同一条代码两个版本都
跑过才敢这么说）——搜索引擎时代读老教程要心里有数。

## 36.2 两个 `_∨_`：分支因子与「信息不足时仍能推进」

同一布尔或，两种写法。真值表流（下称 `∨₁`）四个组合各一行；
Maguire 推荐流（`∨₂`）只查第一个参数：

```agda
_∨₁_ : Bool → Bool → Bool
false ∨₁ false = false
false ∨₁ true  = true
true  ∨₁ false = true
true  ∨₁ true  = true

_∨₂_ : Bool → Bool → Bool
false ∨₂ other = other
true  ∨₂ other = true
```

语义完全等价——示例里把四组合穷举成一条定理，每格一行 `refl`：

```agda
∨-equiv : (a b : Bool) → (a ∨₁ b) ≡ (a ∨₂ b)
∨-equiv false false = refl
∨-equiv false true  = refl
∨-equiv true  false = refl
∨-equiv true  true  = refl
```

计算性质却天差地别，看**偏应用**（留一个口子）时各自算成什么。
先记坑：**算子留空的下划线必须紧贴算子**（`∨₂_`）；写成
`true ∨₂ _`（带空格）时那个 `_` 是隐式元变量 hole，整个式子立刻
从「函数」掉回「Bool」，实测：

```text
/Volumes/mac004/code/programming/agda/examples/TmpProbe36h.agda:7.22-32: error: [UnequalTypes]
The type
  (z : _8) → Bool
is not a subtype of
  Bool
when checking that the expression λ _ → true has type Bool
```

回到正题。`true ∨₂_` 展开是 `λ other → true ∨₂ other`；第一个参数
已是构造子 `true`，规则 `true ∨₂ other = true` 不看 `other` 直接套上，
正规形就是常函数——所以这条 `refl` 过：

```agda
section₂ : (true ∨₂_) ≡ (λ _ → true)
section₂ = refl
```

`true ∨₁_` 呢？`∨₁` 的定义对**第二个**参数也分情况，而第二个参数
还是变量，没有任何规则可套——整个 λ 原地卡住，与 `(λ _ → true)`
不同语法，`refl` 被拒（实测）：

```text
/Volumes/mac004/code/programming/agda/examples/TmpProbe36a.agda:10.16-20: error: [UnequalTerms]
The terms
  true ∨₁ section
and
  true
are not equal at type Bool
when checking that the expression refl has type
(true ∨₁_) ≡ (λ _ → true)
```

（报错里那个 `section` 是 Agda 给 section 的隐藏参数起的名字。）

一句话结论：**`∨₂` 在信息不足时仍能推进，`∨₁` 必须等凑齐两个参数**。
Maguire 把这叫 branching factor——每多查一个参数，程序就多劈一次叉；
「少查」不只是省行数，是**给未来的证明省义务**。stdlib 早已身体力行
（`Data/Bool/Base.agda` 真实源码，2.3→3.0 从未改过形状）：

```agda
_∨_ : Bool → Bool → Bool
true  ∨ b = true
false ∨ b = b
```

正是 `∨₂`，而且第一分支放 `true`（示例 36.7 节有逐字对照）。

## 36.3 卡住项：算不动的三种姿势

定义（Maguire 原话意译）：**规范化后仍不是构造子、最外层又没有规则
可套的项，叫 stuck（卡住，类型论黑话 neutral）**；它在等来能把它
「顶开」的信息。类型检查器只比正规形的语法，所以「卡住 = refl
无能为力」——13 章开篇 `n + zero` 的墙、28 坑清单里反复出现的
「先化简再 refl」，根源全在这一节。三种典型姿势：

**姿势一：等一个没给到的参数**。36.2 的 `true ∨₁_` 就是标准像：
`∨₁` 要看第二个参数，而第二个参数是变量。

**姿势二：postulate 永远卡住**。`postulate` 拉进来的变量没有任何
计算信息（书里话说得很白：Agda 允许你「假设存在」，但不保证真存在，
于是给你一个永远算不动的替身）：

```agda
postulate always-stuck : Bool
```

对它做的一切要求「看它一眼」的运算全部卡死。硬算 `not always-stuck`
为 `false`（实测）：

```text
/Volumes/mac004/code/programming/agda/examples/TmpProbe36c.agda:6.5-9: error: [UnequalTerms]
The terms
  not always-stuck
and
  false
are not equal at type Bool
when checking that the expression refl has type
not always-stuck ≡ false
```

`true ∨₁ always-stuck` 同理卡死（`∨₁` 要查第二个参数，实测）：

```text
/Volumes/mac004/code/programming/agda/examples/TmpProbe36i.agda:11.7-11: error: [UnequalTerms]
The terms
  true ∨₁ always-stuck
and
  true
are not equal at type Bool
when checking that the expression refl has type
(true ∨₁ always-stuck) ≡ true
```

而 `true ∨₂ always-stuck ≡ true` 一行 `refl` 过——`∨₂` 根本不查
第二个参数。**同一份缺失信息，一个程序死于卡住、一个程序照常推进**，
这就是 36.2「分支因子」的兑现时刻。Maguire 的预言值得全文背诵：
避免实现里的一次模式匹配，就避免后续**每个**关于它的证明里的一次
分情况义务——「三行证明与八十一行证明之差」。示例里还有一组链式
推进可玩味：

```agda
and-then-or : (b : Bool) → ((true ∨₂ b) ∨₂ (false ∨₂ b)) ≡ true
and-then-or b = refl      -- b 全程没被看，两处 ∨₂ 各自立刻算成/交还信息
```

（`true ∨₂ _` 立刻出 `true`，外层查第一个参数即收工；
`false ∨₂ b` 卡住成 `b` 也无妨——外层根本不看第二个参数。）

**姿势三：被变量参数顶住的递归函数**。`_+_` 在左参数上递归，`n + zero`
对变量 `n` 卡住（13 章 13.1 的旧账，现在有了正式名字）。卡住项之间
反而「平等待之」——两个一模一样的卡住项仍同语法：

```agda
plus-stuck : (n : ℕ) → (n + zero) + n ≡ (n + zero) + n
plus-stuck n = refl       -- 左右同为 stuck，语法一致，refl 照过
-- 想动卡住的 n + zero？只能归纳（13 章），不能硬算。
```

## 36.4 record：构造、投影三件套与 copattern

Maguire 1.15–1.16 节的手感训练。手搓积类型（与 stdlib `Data.Product._×_`
同构，09 章的老朋友自己再捏一遍）：

```agda
record _⊗_ (A B : Set) : Set where
  field
    fst : A
    snd : B

open _⊗_ public   -- 把 fst/snd 拉进作用域：投影函数 / copattern 头都靠它
```

**构造**有两条路。老式字面量，字段名 = 值：

```agda
pair₁ : Bool ⊗ ℕ
pair₁ = record { fst = true ; snd = 3 }
```

copattern：**不定义 record 本身，按字段逐个给定义**——「你要我的哪个
部分，我就先答哪个部分」：

```agda
pair₂ : Bool ⊗ ℕ
fst pair₂ = not true ∨₂ false
snd pair₂ = (1 + 2) + zero
```

copattern 可以嵌套（示例对 stdlib `_×_` 演示）：

```agda
nested : Bool × (Bool × ℕ)
proj₁ nested = true
proj₁ (proj₂ nested) = false
proj₂ (proj₂ nested) = 7
```

**投影**三件套，Maguire 点名三种、示例全数跑通：

```agda
p2a : Bool
p2a = fst pair₁            -- ① 选择器函数：字段本来就是函数 R → 字段类型

p2b : Bool
p2b = pair₁ .fst           -- ② 点投影：字段名挪到调用者后面（与 ① 同物不同皮）

p2c : Bool
p2c = unpack pair₁         -- ③ record 模式匹配；用不到的字段可以不绑
  where unpack : (r : Bool ⊗ ℕ) → Bool
        unpack record { fst = x } = x
```

实测坑：**copattern 的左端要求字段名先在作用域里**（也就是先
`open _⊗_`），否则 `fst q = true` 这种写法连 parse 都不过：

```text
/Volumes/mac004/code/programming/agda/examples/TmpProbe36g.agda:8.1-6: error: [NoParseForLHS]
Could not parse the left-hand side fst q
Problematic expression: (fst q)
Operators used in the grammar:
  None
when scope checking the left-hand side fst q in the definition of q
```

报错分类 `NoParseForLHS` 值得注意——不是「不认识的函数」而是
「这个形状不配当左端」：没 `open` 时 `fst` 不是可见投影名，
Agda 压根不知道你想表达 copattern。

## 36.5 record 白送 η，函数外延要另花钱

record 的 η 规则：**一个 record 值等于「把它所有字段现取再现装」**，
而且等式是**定义级**的——`refl` 直接认：

```agda
eta-⊗ : (r : Bool ⊗ ℕ) → r ≡ record { fst = fst r ; snd = snd r }
eta-⊗ r = refl

eta-× : (p : Bool × ℕ) → p ≡ ((proj₁ p) , (proj₂ p))
eta-× p = refl
```

（外层那对括号是刚需：`,_`（stdlib 的逗号构造）与 `_≡_` 同为
level 4 且互不结合，`p ≡ a , b` 直接 parse 不过——实测
`Could not parse the application`，报错还会好心地列出参与文法的
两个算子及其优先级；`proj₁ p`/`proj₂ p` 自带括号只是习惯，应用本来
就比算子结合更紧。见 36.8 坑 5。）

函数的情况呢？示例里造一对逐点相等、写法不同的函数：

```agda
f₁ : Bool → Bool
f₁ b = b ∨₂ true

f₂ : Bool → Bool
f₂ b = true
```

逐点等一行搞定（Bool 只有两个构造子，各 `refl` 一下）：

```agda
pointwise : (b : Bool) → f₁ b ≡ f₂ b
pointwise false = refl
pointwise true  = refl
```

但把「函数相等」整体交给 `refl`，实测被拒：

```text
/Volumes/mac004/code/programming/agda/examples/TmpProbe36b.agda:12.7-11: error: [UnequalTerms]
The terms
  x ∨₂ true
and
  true
are not equal at type Bool
when checking that the expression refl has type f₁ ≡ f₂
```

报错把病根摊开给你看：比较函数相等时 Agda 把两边同时施加到新鲜
变量 `x` 上（内部起名 `x`），左边规范化成**卡住项** `x ∨₂ true`
（`∨₂` 要查 `x`），右边是 `true`——36.3 姿势一的原样复刻。
「行为一致 ⇒ 函数一致」这一步叫**外延性（extensionality）**，
Agda 的定义级等式里**没有**，要么分情况把 `∀` 内的等式逐点证（如
`pointwise`），要么 import 公理（32 章实测：3.0 的住址是
`Axiom.Extensionality.Propositional`，里面的 `Extensionality a b` 是这条
公理的**类型**；网上教程常说的 `Function.Extensionality` 在 3.0 不存在）。
示例为了自包含 postulate 了一枚 `funext` 然后立刻兑现：

```agda
f₁≡f₂ : f₁ ≡ f₂
f₁≡f₂ = funext pointwise
```

注意别和**定义级的 η**混了：函数的 η-展开 `f ≡ (λ x → f x)` 不需要
任何公理，`refl` 就认（示例 `eta-λ = refl`）。缺的从来不是 η，是
「两个**写法不同**的函数体逐点相同 ⇒ 相等」这一步。

postulate 版 `funext` 有个教学外溢：本示例含 `postulate`，可它照样
能通过 `--compile`（20 章流水线），只是产物一旦**求值到** postulate
就当场自爆。探针实测（`main = run (putStrLn mystery)`，
`postulate mystery : String`）：

```text
TmpProbe36j: Uncaught exception ghc-internal:GHC.Internal.Exception.ErrorCall:

MAlonzo Runtime Error: postulate evaluated: TmpProbe36j.mystery
```

卡住的两种代价：类型检查期处处 `refl` 不认（静但诚实），运行期
`postulate evaluated`（响但延迟）。证明里的 postulate（如 `funext`）
永远不被求值，属于安全用法；**计算路径上的 postulate 是定时炸弹**——
这也回应 01 章「类型即命题」的另一面：`postulate` 花的是公理的代价，
编译器不替你付，只在运行时装你账上。

## 36.6 类型位置也在算：一段会规范化的类型

依赖类型语言里类型是表达式，规范化同样发生。示例造了个「在类型里
做布尔运算」的别名并让 `refl` 验收：

```agda
len₊ : Set
len₊ = if (not (false ∨₂ true)) ∨₂ false then Bool else ℕ

same-type : len₊ ≡ ℕ
same-type = refl
```

手算：`false ∨₂ true → true`；`not true → false`；`false ∨₂ false →
false`；`if false then Bool else ℕ → ℕ`。所以 `len₊` 就是 `ℕ`，
`refl` 过关——**类型检查器与求值器是同一台机器**，没有「先看类型
再算值」的两截流程。05 章 Π、16 章 Vec 索引的一切「类型会算」现象，
底座都是这同一台规范化机器。类型层计算玩出花（把数字、格式串编码
进类型）是 Stump 第 7 章的主戏，43 章见。

## 36.7 stdlib 对照

| 本章手搓 | stdlib 3.0 正品 | 说明 |
|---|---|---|
| `_∨₂_` | `Data.Bool.Base._∨_` | 正品正是少分支写法（36.2 贴过源码） |
| `record _⊗_` | `Data.Product._×_` | 正品带 `WHERE`/隐式参数与 syntax 声明（09 章拆过） |
| `fst` / `snd` | `proj₁` / `proj₂` | 命名：stdlib 用「投影」数学名 |
| `p ≡ ((proj₁ p) , (proj₂ p))` | `Data.Product.η?`/`,-≡,` 家族 | 库里有现成的「逐字段等 ⇒ record 等」搬运引理 |
| postulate 版 `funext` | `Axiom.Extensionality.Propositional.Extensionality` | 公理的**类型**在 3.0 的确切住址（32 章实测：没有 `Function.Extensionality` 模块，库也不给证明），postulate 只为示例自包含 |
| `if … then … else …` | `Agda.Builtin.Bool.if_*` | 对**条件**分完情况、对两个分支值绝不多看——与 `∨₂` 同一哲学 |

`Data.Bool.Base` 里 `_*_`（与）、`xor`、`not` 全是同款「最小分支」
笔法；读库时留意每个定义「查了参数的哪一面」，那就是库作者给你
标注的「证明时要在哪分情况」。

## 36.8 坑位清单（本项目实测）

1. **refl 只认「算到同形」**：卡住项不是 bug 也不是真理，是「还没
   轮到算」——`not always-stuck ≡ false` 报
   `The terms not always-stuck and false are not equal`（36.3）。
   化简不动就换武器：分情况、归纳（13 章）或外延（32 章）。
2. **section 的下划线必须紧贴算子**：`true ∨₂_` 是函数（`Bool → Bool`），
   `true ∨₂ _` 的 `_` 是元变量 hole，式子掉回 Bool，报
   `The type (z : _8) → Bool is not a subtype of Bool`（36.2）。
3. **`using` 名单漏构造子 = 模式变体吃天**：`open import Data.Bool
   using (Bool; true)`（漏 `false`）后写 `false ∨₂ other = other`，
   `false` 变成**变量模式**吞掉一切，实测两连警告：
   `PatternShadowsConstructor`（变量 false 撞构造子名）+
   `UnreachableClauses`（后一条规则永不可达）。类型检查照过，
   程序已经悄悄不是你以为的那个函数——build.sh 下这类警告直出
   stderr，别 `2>/dev/null` 掉。
4. **copattern 左端要先 `open` record 模块**：否则 `NoParseForLHS`
   （36.4）——报错分类是「parse 不过」而非「类型不对」，见招拆招。
5. **`,_,` 与 `_≡_` 同为 level 4 互不结合**：`p ≡ a , b` 报
   `Could not parse the application`；把逗号式整块加括号
   `p ≡ (a , b)` 即可（36.5）。
6. **函数外延没有免费 η**：`f₁ ≡ f₂` 硬 `refl` 报
   `The terms x ∨₂ true and true are not equal`（36.5）——比较时
   已代入新变量，卡在卡住项上；`λ x → f x ≡ f` 的 η 倒是白送
   （`eta-λ = refl`），两个「η」别叫混。
7. **postulate 编译期无感、运行期爆雷**：含 postulate 的 main 照样
   `--compile` 成功，执行到它才吐 `MAlonzo Runtime Error: postulate
   evaluated`（36.5）。证明用（永不被求值）与计算用（迟早被求值）
   一线之隔。
8. **2.9 报错文案换代**：`The terms … and … are not equal at type …`
   取代旧版 `… !=< …`；老教程里的报错对着不上的话，先怀疑版本
   （35 章迁移清单同款思路）。

---
上一章：[35 · macOS 校验与 3.0 迁移](35-macos-checklist.md) ｜ 下一章：[37 · pattern 同义词与差分整数](37-pattern-synonyms.md) ｜ 返回：[README](../README.md)
