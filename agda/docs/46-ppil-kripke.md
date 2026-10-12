# 46 · Kripke 语义与可靠性定理：给直觉主义逻辑一个「真值」

> **第十部分 · 元理论（46–47）** ｜ 全书结构与阅读路线见 [README](../README.md)

前面 45 章都在用 Agda **写程序、证定理**。这一章和下一章把镜头掉转 180 度：
拿 Agda 去研究「Agda 里这套逻辑本身」。这是元理论（metatheory）的入口，
也是本教程唯一一处要证明**关于证明的东西**：

- 46 章（本章）：给直觉主义逻辑一个 Kripke 语义，证明**可靠性定理**
  （可证 ⟹ 处处为真），然后反过来用它**证明某个公式不可证**（Peirce 律）。
- 47 章：证明**完全性定理**（处处为真 ⟹ 可证），并把可靠性与完全性两次
  证明合成一台真的**证明归一化器**（normalization by evaluation）。

14 章 14.8 节撞过一堵墙：排中律、DNE、Peirce 律在 Agda 里**写不出来**，
只能 `postulate` 引进来，代价是 `--safe` 不再成立。那一章的结论是「构造上
没有这条路」——严格说那只是**证据缺失**：Agda 报 `UnsolvedMetaVariables`，
我们据此推测写不出。本章要把推测变成定理：

> 造一个具体的 Kripke 结构（一台有限世界的反模型），跑一遍可靠性定理，
> 得到 `¬ ([] ⊢ Peirce)`——**Peirce 律在直觉主义逻辑里不可证**，这是一条
> 类型检查通过的 Agda 定理，不是「我试过了没写出来」。

对应示例：`../examples/Ex46_ppil_kripke.agda`

**实测口径**：本章全部代码与报错原文均为 **Agda 2.9.0 + stdlib 3.0** 本机实测
（复现：`cd agda && ./build.sh Ex46_ppil_kripke`；报错原文来自当时写完示例后
逐条改坏的临时探针文件，跑完即删）。引用的 stdlib 源码行号取自本机 git 源
`/Volumes/mac004/lang/agda-stdlib/src`。内容取材 Aaron Stump
《Verified Functional Programming in Agda》第 10 章 10.1–10.4 节，已按本机
版本重写为自包含叙述，读完本章不需要再翻原书。

## 46.1 先把三层楼画清楚

元理论的全部工作就是在三层东西之间架桥。这三层本章一开始就要分清楚，
后面每一步都会标明「这是哪一层」：

| 层 | 记号 | 是什么 | Agda 里怎么做 |
|---|---|---|---|
| 语法 | `Γ ⊢ A` | 「A 可以从假设 Γ 推导出来」——**证明对象** | 一个索引数据类型，构造子 = 推理规则 |
| 语义 | `k , w ⊩ A` | 「在结构 k 的世界 w 里 A 为真」——**真值证据** | 一个返回 `Set` 的递归函数（类型层计算） |
| 桥梁 | `Γ ⊨ A` | 「Γ 的任意模型都满足 A」——**语义推论** | 对**所有**结构量化的类型（因此住在 Set₁） |

两座桥是本章与下一章的主角：

- **可靠性**（Soundness）：`Γ ⊢ A → Γ ⊨ A`。句法不会说谎——凡是能证出来的，
  在任何解释下都真。证明方法：对**推导**归纳（七个规则七个分支）。
- **完全性**（Completeness，47 章）：`Γ ⊨ A → Γ ⊢ A`。语义不会说谎——凡是
  处处为真的，都能证出来。

可靠性是「容易」的那一侧（构造子逐个对着语义检查即可），完全性需要**造一个
专用的结构**（通用结构 U：世界就是上下文）。把这两侧夹在一起，中间就掉出
一台计算机器——这是 47 章的结尾，也是本章埋的线。

顺带一提「对证明归纳」这件事在本教程的地位：35 章已经练过「规则即构造子」
（一步归约关系 `_↝_` 直接做成数据类型），本章把同一手法用在**推理规则**上，
再第一次完整走一遍「对证明对象做归纳」的元定理。

## 46.2 语言：正命题直觉主义逻辑（PPIL）

先把材料准备好。示例的开头是十行 import，逐条说明为什么需要：

```agda
module Ex46_ppil_kripke where

open import Agda.Builtin.String using (String)
open import Data.Bool using (Bool; true; false; if_then_else_)
open import Data.List using (List; []; _∷_)
open import Data.Product using (_×_; _,_; proj₁; proj₂)
open import Data.Unit using (⊤; tt)
open import Level using (0ℓ)
open import Relation.Binary.Core using (Rel)
open import Relation.Binary.Definitions using (Reflexive; Transitive)
open import Relation.Binary.PropositionalEquality using (_≡_; refl)
open import Relation.Nullary using (¬_)
```

- `String`：命题变量用字符串命名（和原书一致）。注意这里**不需要**字符串
  相等判定——变量为真与否是「列出成正构造子」的索引类型（46.7 的 `val`），
  不做计算，所以拿不到 `Data.String.EqualDec`。
- `Bool` 与 `if_then_else_`：只为一件事服务——46.3 里合取消去规则的
  「用一个 Bool 参数选合取支」巧技。
- `List`：上下文（假设表）就是公式表。
- `Product`：合取的语义是积，`_×_`、`_,_`、`proj₁`、`proj₂` 全套要用。
- `Unit`：`⊤` 是 `Top` 的语义，也是空上下文的语义证据。
- `Level` 的 `0ℓ`：给关系打层级标签（46.5）。
- `Relation.Binary.Core` 的 `Rel`：`Rel A ℓ = A → A → Set ℓ`（该文件第 35 行），
  「A 上的 ℓ 层级二元关系」的简称。
- `Relation.Binary.Definitions` 的 `Reflexive`/`Transitive`：预序的两条要求，
  直接复用 stdlib 的命名而不是自己定义。本机行号：`Reflexive` 第 41 行
  （`Reflexive _∼_ = ∀ {x} → x ∼ x`）、`Transitive` 第 72 行
  （`Transitive _∼_ = Trans _∼_ _√_ _∼_` 的形式，`Trans` 在第 56 行）。
- `PropositionalEquality` 的 `_≡_`/`refl`：46.8 那三条「语义是算出来的」演示
  要用它把类型层面的等式钉住。
- `Relation.Nullary` 的 `¬_`：本章末尾的不可证性陈述。3.0 里它是层级多态的
  （`¬_ : Set a → Set a`，`Relation/Nullary/Negation/Core.agda` 第 26 行），
  所以连住在 Set₁ 的命题也能否定（47 章用到这一点）。

### 公式

```agda
data Formula : Set where
  var : String → Formula
  Top : Formula
  _⇒_ : Formula → Formula → Formula
  _∧_ : Formula → Formula → Formula

infixr 2 _⇒_
infixr 3 _∧_
```

四类公式：命题变量、真、蕴含、合取。**没有 ∨，也没有 ¬**。这个片段叫
PPIL（Positive Propositional Intuitionistic Logic）。为什么砍掉 ∨ 和 ¬：
`¬ A` 就是 `A ⇒ ⊥`，而 `⊥` 和 `∨` 都是「否定性」构造——它们的语义要讲
「对所有未来世界……或者某个未来世界……」这种带否定/析取的量化，完全性
证明里那台归一化器（47 章）会显著变复杂，原书因此把语言限定在正片段。
这个选择的代价本章看不见，47.6 会现形：`nbe` 的输出长度会和输入不一样，
而这件事只有在正片段里才能算得干净。

`_⇒_` 右结合、级别 2，`_∧_` 右结合、级别 3，于是 `p ⇒ q ⇒ r` 读作
`p ⇒ (q ⇒ r)`，`p ∧ q ⇒ r` 读作 `(p ∧ q) ⇒ r`。**级别必须比后面的turnstile
紧**，46.13 坑位 3 记录了两条方向相反的实测报错。

命名公式先备好四个：

```agda
p q r : Formula
p = var "p"
q = var "q"
r = var "r"

Peirce : Formula
Peirce = ((p ⇒ q) ⇒ p) ⇒ p

dup : Formula
dup = p ⇒ p ∧ p
```

`Peirce` 是 46.11 的主角（经典逻辑的招牌公理之一，直觉主义拿不到）。它
只用到 `⇒`，正好在 PPIL 的语言里——反模型不用先扩语言。`dup` 是一开始那
条简单定理的主角。

## 46.3 证明即数据：`Γ ⊢ A` 的七条规则

上下文（假设表）就是公式表：

```agda
Ctxt = List Formula
```

自然推演（natural deduction）的推导规则，本教程的老手艺是**把规则做成
构造子**：结论是 `Γ ⊢ A`，前提就是构造子的参数。

```agda
data _⊢_ : Ctxt → Formula → Set where
  id : ∀ {Γ A} → A ∷ Γ ⊢ A
  wk : ∀ {Γ A B} → Γ ⊢ A → B ∷ Γ ⊢ A
  ⇒I : ∀ {Γ A B} → (A ∷ Γ) ⊢ B → Γ ⊢ A ⇒ B
  ⇒E : ∀ {Γ A B} → Γ ⊢ A ⇒ B → Γ ⊢ A → Γ ⊢ B
  ⊤I : ∀ {Γ} → Γ ⊢ Top
  ∧I : ∀ {Γ A B} → Γ ⊢ A → Γ ⊢ B → Γ ⊢ A ∧ B
  ∧E : ∀ (b : Bool) {Γ A B} → Γ ⊢ A ∧ B → Γ ⊢ (if b then A else B)

infix 1 _⊢_
```

逐条读（这一列就是逻辑课本的那七条规则，只是竖线换成了冒号）：

- `id`（公理/identity）：上下文最左那条假设可以直接引用——`A ∷ Γ ⊢ A`。
- `wk`（weakening，结构规则）：多加一条假设不削弱已有结论。
- `⇒I`（蕴含引入）：把 `A` 挂进上下文后能证 `B`，就证出 `A ⇒ B`。
- ⇒E（蕴含消去，modus ponens）：`A ⇒ B` 加 `A` 得 `B`。
- `⊤I`：真的证明是免费的。
- `∧I` / `∧E`：合取的引入与消去。

七个构造子对应七条规则，**没有第八个**：`_⊢_` 是归纳定义，只有这些方式能
造出一个元素。这就是「证明即数据」的含义——一个 `Γ ⊢ A` 的值**就是**一份
从规则表里拼出来的推导树，Agda 的类型检查器保证它每一处拼接都合法。Curry–
Howard 的另一副面孔同时成立：`⇒I` 是 λ、`⇒E` 是应用、`id` 是变量、`wk` 是
de Bruijn 位移，所以这些值也**就是**简单类型 λ 演算的项。47 章的归一化器
正是靠这重身份才有意义。

`∧E` 那条值得单独讲，它是全章最漂亮的一行。**逻辑课给合取两条消去规则**
（`∧E₁`、`∧E₂`），原书把它们压成一条：多带一个 `Bool` 参数 `b`，结论公式
是 `if b then A else B`。`b` 是**可见**参数（写在 `∀ (b : Bool)` 而不是
`∀ {b : Bool}`），因为选哪一支是调用方要明说的信息。妙处在于 `if` 出现在
**类型位置**：`∧E true p` 的类型是 `Γ ⊢ if true then A else B`，Agda 一算
就约简成 `Γ ⊢ A`。这是 11 章「类型层计算 / 卡住项」那条主线在索引里的又
一次出场——**约简发生在检查类型时，不需要任何引理**。

最后 `infix 1 _⊢_`：turnstile 级别必须比 `⇒`（2）、`∧`（3）**松**，否则
`Γ ⊢ A ⇒ B` 会被解析成 `(Γ ⊢ A) ⇒ B`，报 `ShouldBeASort`（46.13 坑位 3 实录）。

## 46.4 四道手写推导：把规则当积木

定理之前先练手。第一道：`⊢ p ⇒ (p ∧ p)`。

```agda
th-dup : [] ⊢ dup
th-dup = ⇒I (∧I id id)
```

推导树画出来是：

```text
   p ⊢ p      p ⊢ p
   ---------------- ∧I
       p ⊢ p ∧ p
   ---------------- ⇒I
    ⊢ p ⇒ p ∧ p
```

`id` 在上下文 `p ∷ []` 里直接引用 `p`，`∧I` 把两份拼成 `p ∧ p`，`⇒I` 撤掉
假设。Agda 侧完全不需要「上下文里确实有 p」这种引理：`id` 的类型 `A ∷ Γ ⊢ A`
把这件事写在了构造子签名里，用不上就是类型不匹配。

第二道把 `wk` 用上：

```agda
th-wk : ∀ {Γ} → Γ ⊢ p → q ∷ r ∷ Γ ⊢ p
th-wk th = wk (wk th)
```

假设表左边多加两条无关假设，原结论照样可用——两次 `wk`。这是「结构规则」
在数据层的直接体现，也是后面 47 章 `weaken¤` 的原型。

第三道是合取结合律，纯粹拿 `id` + `∧I`/`∧E` 拼：

```agda
th-assoc : [] ⊢ (p ∧ q) ∧ r ⇒ p ∧ (q ∧ r)
th-assoc = ⇒I (∧I (∧E true (∧E true id))
                  (∧I (∧E false (∧E true id)) (∧E false id)))
```

进入 `⇒I` 后上下文是 `(p ∧ q) ∧ r ∷ []`，目标 `p ∧ (q ∧ r)`：

- `id` 拿到 `(p ∧ q) ∧ r`；`∧E true id` 得 `p ∧ q`；再 `∧E true` 得 `p`——
  这就是 `∧I` 的第一支。
- 第二支要 `q ∧ r`：`q` 来自 `∧E false (∧E true id)`（先取 `p ∧ q` 的右支），
  `r` 来自 `∧E false id`（直接取最外层右支）。

`∧E true` / `∧E false` 的交替就是「往积的哪一层钻」，而 Agda 每次都在类型
位置上把 `if` 算掉，所以四个 `∧E` 的结论公式全是自动核对的。

第四道是蕴含的「转发」，唯一一条需要数 `wk` 次数的：

```agda
th-chain : [] ⊢ (p ⇒ q) ⇒ (q ⇒ r) ⇒ p ⇒ r
th-chain = ⇒I (⇒I (⇒I (⇒E (wk id) (⇒E (wk (wk id)) id))))
```

三层 `⇒I` 之后上下文是 `p ∷ (q ⇒ r) ∷ (p ⇒ q) ∷ []`（记住 `∷` 往**左**加，
所以最左是最后引入的假设），目标 `r`。最外层 `⇒E` 要 `q ⇒ r` 和 `q`：

- `q ⇒ r` 在第二位，从 `id : (q ⇒ r) ∷ (p ⇒ q) ∷ [] ⊢ q ⇒ r` 出发，往左补
  一条 `p`，即 `wk id`。
- `q` 再用一次 `⇒E`：`p ⇒ q` 在第三位 → `wk (wk id)`（补两条），`p` 在第一位
  → `id` 直接拿。

数 weaken 次数这件事很容易错一位。稳妥的心法是：**从 `id` 出发往回数目标假设
左边还有几条后来引入的假设**，那正是 `wk` 的层数。

## 46.5 Kripke 结构：世界、未来、赋值

语义一侧的全部数据装在一个 record 里：

```agda
record struct : Set₁ where
  field
    W : Set
    R : Rel W 0ℓ
    reflR : Reflexive R
    transR : Transitive R
    V : W → String → Set
    monoV : ∀ {w w′} → R w w′ → ∀ {x} → V w x → V w′ x

open struct
```

四个数据字段 + 两个定律字段，正是 Kripke 结构的教科书定义：

- `W : Set`：世界的集合。
- `R : Rel W 0ℓ`：「未来」关系，展开是 `W → W → Set 0ℓ`。**w R w′ 读作
  「w′ 是 w 的未来可能世界」**（或者说 w′ 比 w 知道得多）。
- `reflR : Reflexive R`、`transR : Transitive R`：预序（自反 + 传递，不必
  反对称）。`Reflexive R` 展开就是 `∀ {x} → R x x`，`Transitive R` 展开是
  `∀ {x y z} → R x y → R y z → R x z`——stdlib 的定义，白送。
- `V : W → String → Set`：赋值。
- `monoV`：赋值对 `R` 单调。

三个细节值得停下来。

**第一，`V` 不是 `W → String → Bool`，而是证据类型。**「变量 x 在世界 w 为真」
当且仅当**存在**一个 `V w x` 的值。没有构造子就是「不成立」——这正是
29 章、35 章反复用的「负信息靠缺席」约定。好处在 46.7、46.11 兑现两次：
反模型里「q 处处不为真」根本不用写，少列一个构造子就是不为真，而想引用
这一事实时用一个 `()` 荒谬分支即可。

**第二，`struct` 为什么住在 `Set₁`。**字段 `V` 的取值是 `Set`，也就是
`W → String → Set` 这个类型本身住在 `Set₁`；一个 record 的层级由字段层级
的最大值决定，所以 `struct : Set₁`。原书跑在 `--no-universe-polymorphism`
下，这一层完全不存在（所有类型层级写死）。层级不是装饰：`_⊨_`（46.10）要
对**所有**结构量化，于是它也住在 `Set₁`。这不是可以绕过的技术细节，而是
「对模型量化」这件事本身的必要代价。

**第三，`open struct` 那一行。**record 的字段投影定义在**与 record 同名的
模块**里（09 章的老坑）：不 `open struct` 就写不出 `W k`、`V k w x`。而且
`open` 的结果不会随 `import` 传播出去——47 章 `open import Ex46_ppil_kripke`
之后必须**再 open 一次**，否则 `W` 不在作用域（实测 `NotInScope: W`）。

## 46.6 满足关系 `⊩`：一个返回类型的递归函数

语义的核心是把「公式 A 在世界 w 为真」翻译成一个类型：

```agda
_,_⊩_ : (k : struct) → W k → Formula → Set
k , w ⊩ var x = V k w x
k , w ⊩ Top = ⊤
k , w ⊩ A ⇒ B = ∀ {w′ : W k} → R k w w′ → k , w′ ⊩ A → k , w′ ⊩ B
k , w ⊩ A ∧ B = (k , w ⊩ A) × (k , w ⊩ B)

infix 1 _,_⊩_
```

`_,_⊩_` 是**对公式结构递归的函数，返回值是类型**（`Set`）。这是 11 章、
31 章「类型层计算」的标准姿势，只是这次递归的对象是逻辑公式、返回的是
「A 为真的证据长什么样」。四行分别解释：

- `var x`：交给结构的赋值 `V`。语义的全部「公理内容」都在这里，由具体
  结构决定。
- `Top`：`⊤`——永远有一个证据（`tt`），所以真命题不需要理由。
- `A ∧ B`：逐点配对，积类型。合取的语义就是「两边都真」，一条都不用证。
- `A ⇒ B`：**整个 Kripke 语义的全部要害在这一行**。它**不是**
  「`k , w ⊩ A` 蕴含 `k , w ⊩ B`」（那就退化成经典语义了），而是

  > 对 w 的**每一个**未来世界 w′，只要那里 A 为真，那里 B 也为真。

  因为 `R` 自反，w 自己也在量化范围内，所以经典的两条性质都保住了；但
  「对未来量化」多出来一层，正是这层多出来的要求，让直觉主义逻辑和经典
  逻辑分家。直觉读法：断言一个蕴含，是断言它在**一切后续认知状态**下都不
  被推翻——此刻我尚不知道 `p ⇒ q` 成不成立没关系，只要无论知识怎么增长，
  一旦 `p` 冒头，`q` 就必须跟着冒头。

这行的类型形状也要看清：`∀ {w′ : W k} → R k w w′ → …` 里的 `w′` 和 `R`
证据都是**隐式**的。于是「使用一个蕴含的证据」就是「交出一个未来的地址」：
46.7 和 46.11 的每个证明都在对 `R` 的证据做模式匹配，靠它挑出自己在说哪个
世界。这种「隐式参数当地址用」的写法第一次出现，值得记住形状。

`infix 1 _,_⊩_`：和 `⊢` 同样的级别要求（比 `⇒`/`∧` 松）。级别写紧一档实测
`NoParseForLHS`（46.13 坑位 3 有原文）。

把语义从公式抬到上下文，只有一句右折叠：

```agda
_,_⊩ctxt_ : (k : struct) → W k → Ctxt → Set
k , w ⊩ctxt [] = ⊤
k , w ⊩ctxt (A ∷ Γ) = (k , w ⊩ A) × (k , w ⊩ctxt Γ)

infix 1 _,_⊩ctxt_
```

「Γ 为真」=「Γ 里每条公式都为真」，折叠成嵌套积 `A₁ × (A₂ × (… × ⊤))`。
空上下文的证据是 `tt`——后面 46.10、46.11 两次要用 `tt` 交代「空假设表当然
成立」。

## 46.7 一台具体的结构 K

抽象定义看完了，装一台最小的机器。形状是原书那类三世界图：

```text
      1          2
    w0 ────→ w1     w2      （w1、w2 极大；p、q 只在 w1、w2 为真）
        └────────→ w2
```

三个世界、两条前进边（w0 到 w1、w0 到 w2），w1 与 w2 互不相连。

```agda
data world : Set where
  w0 w1 w2 : world

data rel : world → world → Set where
  r00 : rel w0 w0
  r11 : rel w1 w1
  r22 : rel w2 w2
  r01 : rel w0 w1
  r02 : rel w0 w2
```

`rel` 只列出**成立**的边：三条自反边 + 两条前进边。图上没有的边（比如
`w1 → w2`）没有构造子，于是「w2 不是 w1 的未来」这条负信息**自动**成立——
不需要写出来，也没法引用。这是归纳谓词的标准读法（29 章），在元理论里同样
好用：语义要求的每条定律都只需覆盖「真实存在的边」。

预序两条要求各自是一份小程序：

```agda
refl-rel : Reflexive rel
refl-rel {w0} = r00
refl-rel {w1} = r11
refl-rel {w2} = r22
```

`Reflexive rel` 展开成 `∀ {x} → rel x x`，所以对 `x` 的三个值做匹配即可。

```agda
trans-rel : Transitive rel
trans-rel r00 r00 = r00
trans-rel r00 r01 = r01
trans-rel r00 r02 = r02
trans-rel r11 r11 = r11
trans-rel r22 r22 = r22
trans-rel r01 r11 = r01
trans-rel r02 r22 = r02
```

`Transitive rel` 展开是 `∀ {x y z} → rel x y → rel y z → rel x z`。这里对
**两个证明**做模式匹配：能列出几个可行组合就写几行。不可能的组合（比如
`r11 r01`：`w1 → w1` 后面接 `w0 → w1`，中点不同）根本不成类型，**不需要**
写荒谬分支——Agda 自己会检查覆盖性，七个分支已经把九种可能边对全盖住
（不成立的边对无处可来）。这是归纳关系做「可枚举小模型」的便利之处。

赋值：

```agda
data val : world → String → Set where
  v1p : val w1 "p"
  v1q : val w1 "q"
  v2p : val w2 "p"
  v2q : val w2 "q"
```

w1、w2 里 p、q 都为真；w0 里**一个构造子都没有**，所以「w0 ⊩ p」和
「w0 ⊩ q」都不成立。这正是 46.5 说的「负信息靠缺席」。

单调性字段要的是一份函数：

```agda
mono-val : ∀ {w w′} → rel w w′ → ∀ {x} → val w x → val w′ x
mono-val r00 u = u
mono-val r11 u = u
mono-val r22 u = u
mono-val r01 ()
mono-val r02 ()
```

自反边走一步什么也不变（`u` 原样给回）。从 w0 出发的两条边 `r01`、`r02`
为什么能写 `()`？因为 `mono-val` 要的是「对**任意** x，`val w0 x` 的证据搬到
w1」，而 `val w0 x` 一个构造子都没有：`()` 分支的意思是「这个参数的模式无
法被构造」，Agda 检查 `val w0 x` 的值域在 `w = w0` 时确实是空的（索引 `w0`
对四条构造子都不匹配）。荒谬模式在这里承担了「w0 什么都不真」这条事实的
全部证明工作。

装成结构：

```agda
K : struct
K = record { W = world; R = rel; reflR = refl-rel; transR = trans-rel
           ; V = val; monoV = mono-val }
```

`record { … }` 语法在这里必须有，因为六个字段全要显式给；`R = rel` 给的是
关系本身，而 `reflR`/`transR` 给它的两条定律是**值**，所以结构的合法性=数据
+ 证明一起交。这就是「模型是记录，定律是字段」的做法（09 章记录技术的
元理论版）。

## 46.8 语义是算出来的，不是猜出来的

`⊩` 是对公式结构的递归定义，所以每个具体公式的真值类型都能**算**出来。
这一点可以用 `refl` 机器验收——`refl` 能过就说明两边**定义上**是同一个类型
（11 章的规范化、13 章的 ≡ 在这里合流成一件工具）：

```agda
⊩-∧-computes : (K , w1 ⊩ p ∧ q) ≡ (val w1 "p" × val w1 "q")
⊩-∧-computes = refl

⊩-⇒-computes : (K , w0 ⊩ p ⇒ q) ≡
              (∀ {w′ : world} → rel w0 w′ → val w′ "p" → val w′ "q")
⊩-⇒-computes = refl

⊩-ctxt-computes : (K , w1 ⊩ctxt p ∷ q ∷ []) ≡
                 (val w1 "p" × (val w1 "q" × ⊤))
⊩-ctxt-computes = refl
```

第二条最值得看：蕴含的语义在**类型层面**被算成一个隐式量化的函数类型，
`world`、`rel`、`val` 这些具体名字直接浮出来——「世界 w0 里 `p ⇒ q` 为真」
这件事**就是**「w0 的每个未来里 p 真则 q 真」这个 Agda 类型，没有中间商。
有了这三条，下面这些结论就不是比喻而是计算：

`p ⇒ q` 在 w0 为真吗？为真，因为 p 和 q 在 w0 的**所有**未来里同步成立：

```agda
test-⊩-⇒ : K , w0 ⊩ p ⇒ q
test-⊩-⇒ r00 ()
test-⊩-⇒ r01 _ = v1q
test-⊩-⇒ r02 _ = v2q
```

`test-⊩-⇒` 的目标类型按 46.8 第二条就是那个 `∀ {w′} → rel w0 w′ → val w′ "p"
→ val w′ "q"`。w0 的未来只有三个地址（r00/r01/r02），于是证明就是对 `rel w0 w′`
的证据做三次匹配：

- `r00`（w′ = w0）：需要 `val w0 "q"`，但假设里有 `val w0 "p"`——而它没有
  构造子，`()` 直接把整支吸收掉。这就是「前件在 w0 假，所以蕴含真」的构造
  形态：给定一个不可能的 `val w0 "p"`，什么都不用做。
- `r01`（w′ = w1）：交出 `v1q`。p 的证据 `_` 被丢弃（它的存在只是前提）。
- `r02`（w′ = w2）：交出 `v2q`。

三行代码把「Kripke 蕴含」的用法教完了：**先报地址，再给证据**。

反过来，w0 里 p、q 都不真，而且这件事可以证明（不是「看起来没有」）：

```agda
no-p-at-w0 : ∀ {A : Set} → K , w0 ⊩ p → A
no-p-at-w0 ()

no-q-at-w0 : ∀ {A : Set} → K , w0 ⊩ q → A
no-q-at-w0 ()
```

「`∀ {A : Set} → 空类型 → A` + 零条子句」是 Agda 里宣告一个类型无元素的
标准写法（10 章、14 章都出现过）：写一条 `()` 就够了，Agda 检查 `val w0 "p"`
确实没有构造子。注意这两条**必须在类型算开之后**才看得见空——`K , w0 ⊩ p`
要先约简成 `val w0 "p"`，这就是 46.8 那三条 `refl` 的用处。

但 w0 不真不等于永远不真：

```agda
p-arrives-later : K , w1 ⊩ p
p-arrives-later = v1p
```

这两件事并排站着（`no-p-at-w0` 与 `p-arrives-later`），就是直觉主义拒绝排中
律的**语义空间**：`p ∨ ¬ p` 在 w0 不成立，因为 p 会「迟到」。14 章只能从
构造侧说「写不出来」，这里能指着模型说「在这个世界里它就是假」。

## 46.9 单调性定理：真理在未来不消失

结构只要求**赋值**单调（`monoV`）。元定理是：单调性沿公式结构传播，
**任意公式**都单调。

```agda
mono⊩ : ∀ {k : struct} {w w′ : W k} {A : Formula} →
       R k w w′ → k , w ⊩ A → k , w′ ⊩ A
mono⊩ {k = k} {A = var x} r u = monoV k r u
mono⊩ {A = Top} r u = tt
mono⊩ {k = k} {A = A ⇒ B} r u r′ u′ = u (transR k r r′) u′
mono⊩ {A = A ∧ B} r (u₁ , u₂) = mono⊩ {A = A} r u₁ , mono⊩ {A = B} r u₂
```

四个构造子四个分支，对公式 `A` 归纳（归纳指标是隐式参数，靠 `{A = …}` 匹配
——2.9.0 的终止检查接受这种写法，实测通过，因为被模式匹配的隐式参数照样
算「可用参数」）。逐支：

- 变量：手上 `u : V k w x`，要的 `V k w′ x` 正是结构的 `monoV` 字段。唯一
  用到公理的一支。
- 真：`⊤` 白送 `tt`。
- 合取：拆成两支各自递归，再配对回去。
- **蕴含：这一支不递归**，也是整个定义最容易被看漏的地方。手上
  `u : k , w ⊩ A ⇒ B`，按定义就是
  `∀ {x} → R k w x → k , x ⊩ A → k , x ⊩ B`；目标是
  `k , w′ ⊩ A ⇒ B`，即再吃一个未来 `r′ : R k w′ w″` 和 `u′ : k , w″ ⊩ A`
  之后交出 `k , w″ ⊩ B`。手上已经有 `R k w w′` 和 `R k w′ w″`，用传递性
  `transR k r r′` 拼出 `R k w w″`，直接喂给 `u` 就完事。

为什么蕴含分支不需要递归？因为**语义定义已经把单调性内置在蕴含的含义里**
——`⊩ A ⇒ B` 本来就对全部未来量化，搬一步只是换个量化起点。原书特别点出
这一点，值得对照 46.6 那行定义看：单调性定理的「容易」不是巧合，是定义
选形的结果。

顺带留意 `monoV k r u` 与 `transR k r r′` 都显式带上结构 `k`：分支头部要
`{k = k}` 把隐式参数钉住（坑位 6 记录不钉的报错原文）。

上下文版本只是把逐点单调折叠进积里：

```agda
mono⊩ctxt : ∀ {k : struct} {Γ : Ctxt} {w w′ : W k} →
            R k w w′ → k , w ⊩ctxt Γ → k , w′ ⊩ctxt Γ
mono⊩ctxt {Γ = []} r u = tt
mono⊩ctxt {Γ = A ∷ Γ} r (u₁ , u₂) =
  mono⊩ {A = A} r u₁ , mono⊩ctxt {Γ = Γ} r u₂
```

这次归纳指标是上下文 `Γ`，两支：空的给 `tt`，非空的拆积、头一支交给 `mono⊩`、
尾巴递归。**这一条是 46.10 可靠性证明里唯一需要的外力**。

## 46.10 语义推论与可靠性定理

先定义「语义推论」——本章第一个跨层的陈述：

```agda
_⊨_ : Ctxt → Formula → Set₁
Γ ⊨ A = ∀ {k : struct} {w : W k} → k , w ⊩ctxt Γ → k , w ⊩ A

infix 1 _⊨_
```

读作：随便挑一个结构、一个世界，只要那里 Γ 全真，那里 A 也真。**量词跨过
所有 struct**，这就是 46.5 说的层级代价的来源：`∀ {k : struct}` 让 `Γ ⊨ A`
住在 Set₁。`⊨` 与 `⊢` 的形似不是巧合，它俩一个是语义的、一个是句法的，
可靠性定理说的正是「⊢ 蕴含 ⊨」。

定理本身对**推导**归纳：七个规则七个（实为八个，`∧E` 的 Bool 分两式）分支。
为了不让隐式量词的会计工作压住主线，先把量词写开：

```agda
soundness : ∀ {Γ A} → Γ ⊢ A →
            ∀ {k : struct} {w : W k} → k , w ⊩ctxt Γ → k , w ⊩ A
soundness id g = proj₁ g
soundness (wk th) g = soundness th (proj₂ g)
soundness (⇒I {Γ} {A} th) g r u = soundness th (u , mono⊩ctxt r g)
soundness (⇒E th₁ th₂) {k} g = soundness th₁ g (reflR k) (soundness th₂ g)
soundness ⊤I g = tt
soundness (∧I th₁ th₂) g = soundness th₁ g , soundness th₂ g
soundness (∧E true th) g = proj₁ (soundness th g)
soundness (∧E false th) g = proj₂ (soundness th g)
```

逐支读（这一列是全章最重要的三百字）：

- **`id`**：结论 `A` 就是上下文最左那条假设，而 `g : k , w ⊩ctxt (A ∷ Γ)`
  按定义是 `(k , w ⊩ A) × …`，所以 `proj₁ g` 正是要的东西。一行，无需引理。
- **`wk`**：`g : k , w ⊩ctxt (B ∷ Γ)` = `(k , w ⊩ B) × (k , w ⊩ctxt Γ)`。
  新假设的证据用不上（结论不涉及它），所以丢掉第一支，把 `proj₂ g` 喂给递归。
- **`⇒I`：这里用到单调性，也是全证明唯一一处非平凡搬运。**递归调用要的
  是 `k , w′ ⊩ctxt (A ∷ Γ)`——注意世界换成了 `w′`（蕴含语义里那个未来）。
  手上只有 `g : k , w ⊩ctxt Γ`（旧世界）和 `u : k , w′ ⊩ A`（新假设在新
  世界为真）。配对之前必须先用 `mono⊩ctxt r g` 把 Γ 的真从 w 搬到 w′。
  这一步就是「直觉主义蕴含对未来量化」的直接后果：假设表也要跟着搬到未来。
- **`⇒E`**：`soundness th₁ g : k , w ⊩ A ⇒ B`，按定义是个吃「未来地址 +
  A 的证据」的函数。用**自反性** `reflR k` 把自己交回去（"当前世界也是我
  的一个未来"），再喂 `soundness th₂ g`，得到 `k , w ⊩ B`。
- **`⊤I`**：`tt`。
- **`∧I`**：两支各自递归再配对。
- **`∧E true/false`**：`soundness th g : k , w ⊩ A ∧ B` 是积，取对应投影即可；
  结论公式里那个 `if true then A else B` 早已在**类型位置**约简成 `A`，所以
  不需要任何引理来桥接（46.3 那个巧技在这里第二次兑现）。

证明的骨架就是「对构造子归纳 + 语义定义展开」，七个分支没有一个用到
反证、排中或任何公理。

最后把定理换回 `⊨` 记号（类型逐字相等，所以一行就够）：

```agda
Soundness : ∀ {Γ A} → Γ ⊢ A → Γ ⊨ A
Soundness = soundness
```

为什么不直接把七条子句写在 `Soundness` 上？原书就是这么写的，照抄形态在
2.9.0 **也**能过（实测：把上面八行 `soundness` 的结论类型换成 `Γ ⊨ A`、
递归调用改成 `Soundness`，整体加载通过）。但那里的 ⇒E 子句要写成
`Soundness (⇒E th₁ th₂) {k} g = …`，其中 `{k}` 属于 `⊨` **展开出来的**隐式
参数，一点都不属于 `⇒E`——一旦误挂到 `⇒E` 自己身上，实测立刻报
`WrongHidingInLHS`（46.13 坑位 5 有原文）。先写开量词、再一行换名，这笔
隐式参数的账就不用手算，而且 `mono⊩ctxt`/`reflR` 出现在哪一行一目了然。

可靠性定理是**可以跑的**。46.4 手写的 `th-assoc` 送进去，在世界 w0 处实例化：

```agda
assoc-at-w0 : K , w0 ⊩ (p ∧ q) ∧ r ⇒ p ∧ (q ∧ r)
assoc-at-w0 = Soundness th-assoc {K} {w0} tt

dup-at-w0 : K , w0 ⊩ dup
dup-at-w0 = Soundness th-dup {K} {w0} tt
```

`{K} {w0} tt` 三个参数的意思：挑结构 K、挑世界 w0、交上空上下文 K , w0 ⊩ctxt []
的证据（就是 `tt`，46.6 的定义）。跑完得到的是一条关于**这台具体机器**的语义
事实——「结合律在 K 的 w0 为真」。定理是个函数，实例化它就得到计算结果，
这与 45 章 `run … ≡ …` 那条 `refl` 是同一件事的两面。

## 46.11 反模型机器：Peirce 律不可证

现在把可靠性倒过来用。**逻辑**很直白：

> 若 `Γ ⊢ A`，则 Γ 的每个模型都满足 A（Soundness）。
> 逆否：找到一个模型、一个世界，使 A 在那里不为真，则 A 不可证。

这套机器需要两样东西：一个合适的结构，和「A 在那个世界不为真」的否定证明。
经典逻辑的招牌公理 Peirce 律 `((p ⇒ q) ⇒ p) ⇒ p` 只用到 `⇒`，PPIL 的语言
完全够用。反模型是一条三世界链：

```text
  z0 ────→ z1 ────→ z2        p：从 z1 起为真；  q：处处不为真
   └─────────────────→ z2
```

先把骨架摆出来：

```agda
data pworld : Set where
  z0 z1 z2 : pworld

data prel : pworld → pworld → Set where
  t00 : prel z0 z0
  t11 : prel z1 z1
  t22 : prel z2 z2
  t01 : prel z0 z1
  t12 : prel z1 z2
  t02 : prel z0 z2

prefl-prel : Reflexive prel
prefl-prel {z0} = t00
prefl-prel {z1} = t11
prefl-prel {z2} = t22

ptran-prel : Transitive prel
ptran-prel t00 u = u
ptran-prel t11 t11 = t11
ptran-prel t11 t12 = t12
ptran-prel t12 t22 = t12
ptran-prel t22 t22 = t22
ptran-prel t01 t11 = t01
ptran-prel t01 t12 = t02
ptran-prel t02 t22 = t02

data pval : pworld → String → Set where
  u1p : pval z1 "p"
  u2p : pval z2 "p"

pmono-pval : ∀ {w w′} → prel w w′ → ∀ {x} → pval w x → pval w′ x
pmono-pval t00 ()
pmono-pval t11 u = u
pmono-pval t22 u = u
pmono-pval t01 ()
pmono-pval t12 u1p = u2p
pmono-pval t02 ()

P : struct
P = record { W = pworld; R = prel; reflR = prefl-prel; transR = ptran-prel
           ; V = pval; monoV = pmono-pval }
```

对照 46.7 的 K，这里有三处新东西：

- `ptran-prel` 比 K 的对应物多一条**新边**要拼：`t01` 接 `t12` 得 `t02`
  （`ptran-prel t01 t12 = t02`）。K 里没有跨两跳的新边，所以那边的传递性
  表没这项。**这条恰好是 Peirce 反模型成立的关键**：z0 的未来里必须
  同时看得见 z1 和 z2，而 z1 到 z2 还有一步。
- 第一个分支写成 `ptran-prel t00 u = u`：`t00` 是第一支时中点必然是 z0，
  于是第二支也只能是 `t00`（z0 的出边只有自反边和两条到 z1/z2 的边，作为
  「y = z0」的第二参数只有 `t00` 可用），所以一支顶三支。写定理时能这样
  压缩，全靠关系是归纳的。
- `pval` **只有 p**：q 一个构造子都没有，即「q 处处不为真」。而单调性
  `pmono-pval` 在 `t12` 那支要把 z1 的 p 证据搬到 z2，就得点名
  `u2p`——写 `pmono-pval t12 u = u` 实测报 `UnequalTerms`
  （`z1` 与 `z2` 在 `pworld` 上不等，坑位 7）。而 `t00 t01 t02` 三支
  用 `()` 吸收，因为 z0 里没有 p 的证据可搬。

三件武器开始装配。第一件：z0 里 p 不真、z1 里 q 不真，都是荒谬分支：

```agda
p-not-at-z0 : ∀ {A : Set} → P , z0 ⊩ p → A
p-not-at-z0 ()

p-not-q-at-z1 : ∀ {A : Set} → P , z1 ⊩ q → A
p-not-q-at-z1 ()
```

第二件，全章最绕也最妙的一步——**前件 `(p ⇒ q) ⇒ p` 在 z0 居然为真**：

```agda
peirce-antecedent : P , z0 ⊩ (p ⇒ q) ⇒ p
peirce-antecedent t00 u = p-not-q-at-z1 (u t01 u1p)
peirce-antecedent t01 u = u1p
peirce-antecedent t02 u = u2p
```

目标类型 `P , z0 ⊩ (p ⇒ q) ⇒ p` 按 46.6 展开是：

> 对 z0 的每个未来 w′，如果 `P , w′ ⊩ p ⇒ q`，那么 `P , w′ ⊩ p`。

第一个参数（隐式）是未来地址 `prel z0 w′`，第二个 `u` 是那个前件。三个分支
对应 z0 的三个未来：

- **`t01`（w′ = z1）**：目标是 `P , z1 ⊩ p`，直接交出 `u1p`。前件 `u` 根本
  没用到——p 从 z1 起就为真，这正是反模型的设计。
- **`t02`（w′ = z2）**：同理交出 `u2p`。
- **`t00`（w′ = z0）**：目标 `P , z0 ⊩ p` **不成立**（`p-not-at-z0`）。
  所以必须从假设 `u : P , z0 ⊩ p ⇒ q` 里榨出矛盾来。怎么榨？把 `u` 拿去
  问一个它自己必须回答的未来：`u t01 u1p` 要求 `P , z1 ⊩ q`——因为
  `t01 : prel z0 z1` 是 z0 的一个未来，而那里 p 真（`u1p`）。可 q 在 z1
  不真，于是 `p-not-q-at-z1 (…)` 把这个不可能的证据吸收成任何东西，包括
  我们要的 `P , z0 ⊩ p`。

读懂这一支是读懂 Kripke 语义的分水岭：**「`(p ⇒ q)` 在 z0 为假」这个事实，
是通过「它承诺对每个未来都成立，而 z1 这个未来违约」来反驳的。** 违约者
`u1p`（z1 里 p 真）加上 `q 在 z1 不真`，矛盾就到手了。也就是说：z0 处前件
`(p ⇒ q) ⇒ p` 之所以为真，**恰恰因为它的假设 `(p ⇒ q)` 在 z0 是假的**——
假前件什么都保证得了。这一直觉在经典逻辑里同样成立，但这里是用构造
讲清楚的，不是靠真值表。

第三件：把前件递到最外层，z0 处要 p，拿不到，于是 Peirce 律在 z0 崩掉：

```agda
peirce-not-⊩ : ¬ (P , z0 ⊩ Peirce)
peirce-not-⊩ h = p-not-at-z0 (h t00 peirce-antecedent)
```

`h` 是「Peirce 律在 z0 为真」的假设。`Peirce = ((p⇒q)⇒p)⇒p` 展开后是个吃
「未来地址 + 前件证据」的函数，所以 `h t00 peirce-antecedent` 就是
`P , z0 ⊩ p`——把 z0 自己当未来（`t00`），把刚证好的前件当证据
（`peirce-antecedent`），结论却是 z0 里 p 为真，`p-not-at-z0` 收尾。
一行就是一次函数应用，这就是「隐式参数当地址」的用法。

最后一步，可靠性定理盖章：

```agda
not-Peirce : ¬ ([] ⊢ Peirce)
not-Peirce h = peirce-not-⊩ (Soundness h {P} {z0} tt)
```

若有证明 `[] ⊢ Peirce`，`Soundness` 就把它送到**任意**结构任意世界；专门喂
它 P、z0、空上下文证据 `tt`，得到 `P , z0 ⊩ Peirce`，与
`peirce-not-⊩` 矛盾。整条链——语法证明、可靠性、反模型、否定——全部由
Agda 类型检查器验收，没有任何 `postulate`。

对照 14 章的进步值得说清楚：那里「DNE / Peirce 写不出来」的证据是
Agda 报 `UnsolvedMetaVariables`，那只是**我们的机器不够聪明**；这里的证据
是一台**构造出来的有限反模型**外加一条已验证的元定理，是**逻辑本身**不给
你这条公理。负面的元数学结果也可以被机器验证，这是依赖类型编程最好的一
面，也是 47 章完全性定理的动机（既然不可证，那么「语义上就有人反对」这句
话能不能反过来证？）。

## 46.12 这章在全书里的位置

零件清单：`Formula`/`_⊢_` 是 07/10 章的归纳与索引类型（35 章「规则即构造子」
的第二号应用）；`V`/`rel`/`pval` 那种「没有构造子就是假」是 29 章的负信息
约定；`⊩` 是 11/31 章的类型层递归返回 `Set`；`mono⊩`/`soundness` 是
14 章逻辑连接词 + 15 章归纳剧本（这次归纳的对象是证明）；`refl` 验收类型
计算是 11 章规范化 + 13 章等式的合流；`struct` 记录带定律字段是 09 章；
`Rel`/`Reflexive`/`Transitive` 是 39 章 stdlib 关系产业；`¬_` 是 14 章。

新引入的只有一件事：**镜头掉转，用同一套语言谈论这套语言本身**。

47 章接的正是本章留下的两个钩子：

- 可靠性用了「对所有结构量化」的 `⊨`，完全性要把这个全称**削弱**成一次
  实例化——挑哪个结构？答案是造一个专用结构 U（世界=上下文，未来=扩张，
  赋值=可证性）。
- `Soundness` 与 `Completeness` 都是**函数**。把它们前后合成，就得到
  `Γ ⊢ A → Γ ⊢ A`，而它是一台真的归一化器：46.3 那句「证明也是 λ 项」
  在这里兑现成 β-归约。

## 46.13 坑位清单（实测）

1. **`Data.Unit` 3.0 只导出 `⊤` 与 `tt`，没有 `unit`**：写
   `using (⊤; unit)` 报 warning `-W[no]ModuleDoesntExport
   The module Data.Unit doesn't export the following: unit`，紧接着真正
   的失败在后面每个用 `tt` 的地方：`Not in scope: tt (did you mean
   'Data.Unit.tt'?)`。原书（IAL 库）用的名字是 `J`/`unit`，移植时统一换 `tt`。
2. **`∧E` 里 `if` 必须加括号**：`Γ ⊢ if b then A else B` 报
   `NoParseForApplication: Could not parse the application
   Γ ⊢ if b then A else B`，报错里附的算子表点破了原因：
   `⊢ (infix operator, level 1)`、`if_then_else (prefix operator, level 0)`。
   写合法：`Γ ⊢ (if b then A else B)`。
3. **turnstile 的级别必须比连接词松**，两个方向都实测过：
   - `_,_⊩_` 写成 `infix 3`（比 `⇒` 的 2 紧）时，语义定义那行直接
     `NoParseForLHS: Could not parse the left-hand side k , w ⊩ A ⇒ B
     Problematic expression: (k , w ⊩ A)`——`(k , w ⊩ A)` 先结合了，
     而它不是合法的模式。
   - `_⊢_` 写成 `infix 4`（比 `⇒` 紧）时，`⇒I` 的签名 `Γ ⊢ A ⇒ B` 被读成
     `(Γ ⊢ A) ⇒ B`，报 `ShouldBeASort: Formula should be a sort, but it isn't`。
   约定：连接词占 2/3，三个 turnstile（`⊢`、`⊩`、`⊩ctxt`、`⊨`）一律 1。
4. **`struct : Set₁` 不是可以商量的**：字段 `V : W → String → Set` 的取值
   住在 Set，故 `struct` 至少在 Set₁；进而 `Γ ⊨ A`（对 struct 量化）也在
   Set₁。照原书那样假设「层级只有一层」的写法在 2.9.0 + stdlib 3.0 下
   过不了——`Rel W 0ℓ` 这一层标签也是同一件事的体现。好消息是 stdlib 3.0
   的 `¬_` 是层级多态的，Set₁ 上的命题照样能写否定（47 章用到）。
5. **`⊨` 记号上的子句：`{k}` 属于定义，不属于构造子**。照抄原书形态
   （七条子句直接写在 `Γ ⊢ A → Γ ⊨ A` 上，⇒E 那支写
   `Soundness (⇒E th₁ th₂) {k} g = …`）在 2.9.0 实测**可以**整体加载；
   但把 `{k = k}` 挂到 `⇒E` 的模式上——`Soundness (⇒E {k = k} th₁ th₂) g = …`
   ——立刻报 `WrongHidingInLHS: Unexpected implicit argument when checking
   that the pattern ⇒E {k = k} th₁ th₂ has type Γ ⊢ A`（`⇒E` 的隐式参数
   只有 `Γ A B`）。本示例因此用两步写法（量词写开的 `soundness` +
   `Soundness = soundness`），把这笔账摆在明面上。
6. **record 字段投影要先钉结构**：`mono⊩` 的变量分支若写
   `mono⊩ {A = var x} r u = monoV _ r u`（不显式绑 `k`）报
   `UnsolvedConstraints`，卡住的正是记录字段：
   `_V_273 _w′_268 _x_277 =< V k w′ x (blocked on _V_273)`、
   `R k w w′ =< _R_270 _w_267 _w′_268 (blocked on _R_270)`，外加一串
   `UnsolvedMetaVariables`。修法：分支头写 `{k = k}`，字段调用一律
   `monoV k r u`、`transR k r r′` 显式带上 `k`。`mono⊩ctxt`/`soundness`
   里同理（`reflR k`）。
7. **单调性分支必须点名目标世界的构造子**：`pmono-pval t12 u = u` 报
   `UnequalTerms: The terms z1 and z2 are not equal at type pworld when
   checking that the expression u has type pval z2 x`。`t12` 从 z1 走到 z2，
   返回值只能是 z2 那一侧的构造子 `u2p`，所以左边也要匹配到 `u1p`。
8. **`Bool` 选支不必抬到 Set**：`∧E` 的 `if b then A else B` 里 `if` 选的是
   **公式**（`Formula`，住在 Set），不要画蛇添足写成
   `if {A = Set} b then A else B`——后者实测报 `HiddenNotInArgumentPosition`
   并顺带 `UnequalTypes`（拿 `Bool` 和 `Level` 比）。`Data.Bool` 的
   `if_then_else_` 本身是层级多态的，隐式参数由主体自己定。
9. **`open struct` 不随 import 传播**：见 46.5。本章内部没踩到（本模块
   自己 open 了），但 47 章 `open import Ex46_ppil_kripke` 之后第一次引用
   `W U` 就报 `Not in scope: W (did you mean 'struct.W'?)`，必须再补一行
   `open struct`。

---

上一章：[45 · 记忆化即类型优化：Shape 索引的 Trie 与 Memoizes 谓词](45-memoize.md) ｜ 下一章：[47 · 完全性定理与 normalization by evaluation：把两条元定理合成一台机器](47-nbe.md) ｜ 返回：[README](../README.md)
