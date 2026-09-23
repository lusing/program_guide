# 11 · 命题等式

前两章你已经「顺手」写过 `refl`：`_ : head (10 ∷ 20 ∷ []) ≡ 10` 一行过关。
本章把这张牌翻开看背面——**Agda 的等式不是逻辑 primitive，而是一个只有
一行代码的 data 类型**；对称、传递、代入、改写全从「唯一构造子 + 一次模式
匹配」长出来。理解「把 `eq : x ≡ y` 匹配到 `refl` 的瞬间，类型检查器顺手
合并 x 和 y」（端点塌缩）是 Agda 证明风格的灵魂，13/14/26 章全是它的放大版。
本章讲透 data 定义与 sym/trans/cong/subst 家族、演练模式匹配证等式、给
rewrite 正名（2.8 实测的能与不能），并用 J 与 Leibniz 等式说明坐标。

对应示例：`../examples/Ex11_equality.agda`

报错文本均为 Agda 2.8.0 + stdlib 2.3 实测原样粘贴，代码片段与示例一致。

## 11.1 等式的全部秘密：一行 data

Agda 内核自带一个微型库（装在 `lib/prim` 下），`Agda.Builtin.Equality`
**逐字**只有这么几行：

```agda
infix 4 _≡_
data _≡_ {a} {A : Set a} (x : A) : A → Set a where
  instance refl : x ≡ x
```

用 10 章的语言读它：`A` 是参数、`x` 也是**参数**、冒号右边的 `A` 才是
**索引**——`x ≡ y` 是「索引为 y、参数为 x 的一元族」。构造子 `refl` 不要
任何输入，它产出的类型是 `x ≡ x`：**等式证据只能构造在两端本来就是同一个
值的地方**。想造 `x ≡ y`（x、y 不合一）？索引方程 `x ≡ y` 无解，类型无居民。
这就是「命题等式」与布尔等价的根本分工：`_≡_`（`\equiv`）是类型层的陈述，
`refl` 是唯一可能的证据。

`Relation.Binary.PropositionalEquality` 是它的**包装壳**——Core 模块原样
一行 `open import Agda.Builtin.Equality public`，再把 sym/trans/cong/subst
这些「从一行 data 推导出的引理」集中重导出。换句话说：**标准库没给等式
任何特权，全部定理都是普通程序**。不信可以自己复刻一个等式类型
（示例 11.1 节的 `_==_`），机制立刻原样复用：

```agda
data _==_ {A : Set} (x : A) : A → Set where
  refl= : x == x

sym-== : ∀ {A : Set} {x y : A} → x == y → y == x
sym-== refl= = refl=
```

`sym-==` 只有一枝，却「证完了任意 x、y 的对称性」——为什么合法？11.3 详解。

## 11.2 refl：把两边规约到同一个值

`refl` 检查的是**转换性**（convertibility）：把等式两边各自求值化简，
最后比语法。于是这一批全部一行过关：

```agda
_ : 1 + 1 ≡ 2
_ = refl

_ : 2 + 0 ≡ 2                      -- 具体数字上的 n+0 照样算得平
_ = refl

0+n : ∀ n → 0 + n ≡ n
0+n n = refl                       -- 首参数为 0：+ 的定义直接展开

_ : 2 + 2 ≡ 1 + 3                  -- 写法不同，规范值都是 4
_ = refl
```

`0 + n ≡ n` 对**变量** n 也成立，因为 `+` 按**第一个参数**递归——它的
原始定义在内核库 `Agda.Builtin.Nat`（`Data.Nat.Base` 只是重导出）：
`zero + m = m; suc n + m = suc (n + m)`，第一条就是定义等式。但换到
另一侧，同样的话就不成立——`_ + zero` 会一路展开到 `n` 卡住：

```text
/home/xulun/code/programming/agda/examples/Tmp11d.agda:13.14-18: error: [UnequalTerms]
n + 0 != n of type ℕ
when checking that the expression refl has type n + 0 ≡ n
```

**「0+n 免费、n+0 要归纳」是 Agda 的第一课**：编码方式决定哪侧可计算化简。
想证 `∀ n → n + 0 ≡ n`，只能对 n 归纳，归纳步把 IH 抬进 `suc`：

```agda
n+0 : ∀ n → n + 0 ≡ n
n+0 zero    = refl
n+0 (suc n) = cong suc (n+0 n)
```

`cong suc p`：「f 保等式」——等式两边同时过一个函数（其证明本身也只是
`cong f refl = refl`，见 11.3）。和 Coq 对照：Agda 没有策略，你写的就是证
明项；和 Haskell 对照：`==` 返回 Bool 跑在运行时，`≡` 是类型、证据在编译
期——`2 + 3 ≡ 3 + 2` 这种闭项 Agda 直接算给你看，不需要测试用例。

## 11.3 模式匹配「证明」等式：refl 携带的约束

现在把本章最重要的一句话摆出来：

> 把 `eq : x ≡ y` 匹配到构造子 `refl` 时，唯一可行的实例化是 `y := x`
> ——模式匹配器顺手把你上下文里所有 `y` 换成了 `x`，然后 eq 本身消失。
> 这叫**端点塌缩**。分支不用多做任何事，约束已被合一器消费。

三个等价的写法演示同一瞬间（示例 11.3 节）：

```agda
cong-case : ∀ {A B : Set} (f : A → B) {x y : A} → x ≡ y → f x ≡ f y
cong-case f refl = refl

cong-case₂ : ∀ {A B : Set} (f : A → B) {x y : A} (eq : x ≡ y) → f x ≡ f y
cong-case₂ f eq = case eq of λ { refl → refl }
```

第一条是 stdlib 里 `cong` 的**源码原文**（`PropositionalEquality/Core`：
`cong f refl = refl`；示例里另给了 with 版 `cong-with`，三者全同型）。匹配
eq 到 refl 后，目标 `f x ≡ f y` 里的 y 已被替换为 x，`refl` 恰好够格——
**一条分支都没多写，「∀ 任意等式」的定理却证完了**。这正是 Coq
`induction eq` 后接 `reflexivity` 的镜像，机制完全同构（第 13 章归纳剧本的地基）。

一个小坑：`case_of_` 住在 `Function`，不在 `Relation.Nullary`。抄老教程
import 错地方只会吃警告、**退出码仍是 0**（和 10.6 的 `natToFinBound` 同款）：

```text
/home/xulun/code/programming/agda/examples/Tmp11a.agda:9.30-46: warning: -W[no]ModuleDoesntExport
The module Relation.Nullary doesn't export the following:
  case_of_
...
/home/xulun/code/programming/agda/examples/Tmp11a.agda:17.19-23: error: [NotInScope]
Not in scope:
  case
```
端点塌缩还有一个更狠的推论：**两端都是闭项时，等式的全部证明都等于 refl**。

```agda
uip₁ : (p : 1 ≡ 1) → p ≡ refl
uip₁ refl = refl
```

匹配 `p` 到 refl 是合法分支（1 和 1 本来就合一），`p ≡ refl` 的目标跟着
塌缩成 `refl ≡ refl`——一行完事。但这**不能**推广成
`∀ {x} (p : x ≡ x) → p ≡ refl`（泛等性 UIP）：变量端点上匹配 refl 只允许
「把 y 替换成 x」，不允许「证明一切证明等于 refl」。UIP 在 Agda 里要请公理
（`Axiom.UniquenessOfIdentityProofs`），立方类型论（24 章）里还会失效——
「具体值的等式证明唯一」这种局部版本才是免费的。

stdlib 家族全员到齐（「签名 + 单行 refl 模式」，实现在
`PropositionalEquality/Core` 原样如此）：

```agda
sym : ∀ {A : Set} {x y : A} → x ≡ y → y ≡ x
sym refl = refl
trans : ∀ {A : Set} {x y z : A} → x ≡ y → y ≡ z → x ≡ z
trans refl eq = eq
subst : ∀ {A : Set} (P : A → Set) {x y : A} → x ≡ y → P x → P y
subst P refl p = p
```

链式拼装一个小型「证明脚本」：

```agda
_ : suc (2 + 0) + 0 ≡ 3
_ = trans (n+0 (suc (2 + 0))) (cong suc (n+0 2))

plus0-preserves-+ : ∀ {a b : ℕ} → a ≡ b → a + 0 ≡ b + 0
plus0-preserves-+ eq = cong₂ _+_ eq refl
```

最后用一个显式模式收尾：`swap-args` 左端把 eq 匹配成 refl，同时点模式
`.x` **断言**第二参数必须等于第一参数（`.` 是「只查不绑」）：

```agda
swap-args : ∀ {A : Set} (x y : A) (eq : x ≡ y) → y ≡ x
swap-args x .x refl = refl
```

匹配 eq ≡ refl 已迫使 x ≡ y，`y` 处写 `.x` 只是显式记账——它和 11.8 的
rewrite 殊途同归（见该节末尾）。

## 11.4 subst 与 transport：类型沿着等式走

把 `subst : (P : A → Set) → x ≡ y → P x → P y` 读成物流：`P : A → Set`
是一条「类型随位置变化」的传送带，`x ≡ y` 是从 x 到 y 的车票，
`subst P eq` 把住在 `P x` 里的货物搬到 `P y`。Agda 里它就是 `transport`——
源码一行 `subst P refl p = p`：匹配车票到 refl 的当下，起点终点已经合并，
货物原地不动即完成搬运。最直观的依赖族还是 10 章的 `Fin`：

```agda
cast : ∀ {n m : ℕ} → n ≡ m → Fin n → Fin m
cast eq = subst (λ k → Fin k) eq

cast-id : ∀ {n} (i : Fin n) → cast refl i ≡ i
cast-id i = refl
```

`cast refl i` 按定义立刻规约成 `i`，refl 即证——沿 refl 的 transport 是
恒等，这条「函子律」免费。稍难的真实例子：把引理 `n+0` 的**方向**搬过来用：

```agda
subst-use : subst (λ k → k + 0 ≡ k) (sym (n+0 2)) refl ≡ refl
subst-use = refl
```

`sym (n+0 2) : 2 ≡ 2 + 0` 是「反向车票」，`subst` 把证明
`refl : 2 + 0 ≡ 2` 从族 `λ k → k + 0 ≡ k` 的 `k = 2` 位搬到 `k = 2 + 0` 位；
全程被计算钉死，整体又归约回 `refl`。24 章立方类型论（`--cubical`）会给出
真正路径意义的 `transport`，命题等式的 `subst` 是它的 intensional 前身。

## 11.5 J：基于等式的归纳

`_≡_` 的**消去原理**（induction principle）叫 J 规则，stdlib 给了原语版
（`PropositionalEquality/Properties` 第 38 行）：

```agda
J : {A : Set} {x : A} (B : (y : A) → x ≡ y → Set)
    {y : A} (p : x ≡ y) → B x refl → B y p
J B refl b = b
```

签名读法：想对 `p : x ≡ y` 做归纳，先交出「动机」B——规定**每个候选端点
和每条候选证明上你要证什么**；再交 refl 情形的证据 `b : B x refl`；J 返回
一般情形 `B y p`。实现照旧只有一行 `J B refl b = b`——对等式归纳的全部
工作就是**端点塌缩**：匹配 p 到 refl 的一瞬，y 并为 x、p 并为 refl，目标
自动换成 b 的类型。

用 J 现场重建 trans（体会「怎么选动机」；示例 `trans-via-J`）：

```agda
trans-via-J : ∀ {A : Set} {x y z : A} → x ≡ y → y ≡ z → x ≡ z
trans-via-J {x = x} {z = z} p q = J (λ w _ → w ≡ z → x ≡ z) p (λ r → r) q
```

动机 B = 「对任意中间点 w 和任意桥票 w→y，给出 w≡z → x≡z」；refl 端点
交恒等函数 `(λ r → r)`；J 把这份「只在 x 端成立的礼物」沿 p 搬运到 y 端，
正好接上 q。sym、subst 同样各是一条 J 的实例化——**整族等式引理都是
同一个消去原理的投影**。教科书里的 J 常写成参数序 `J B b p`，stdlib 是
`J B p b`（票在前、证据在后），抄代码时留意。等式归纳永远是平凡的，不平凡
的是**它允许你把已知等式当重写规则用**——11.8 见。

## 11.6 加餐：Leibniz 等式——不可区分者即相等

不用 data，纯用 λ 也能「定义相等」：**x 与 y 相等，当且仅当一切性质 P
对二者同真同假**（Leibniz 律）。在 Agda 里写出来（注意它住在 `Set₁`，
因为量化了谓词族 `A → Set`）。两个方向都通：

```agda
Leib : ∀ (A : Set) → A → A → Set₁
Leib A x y = (P : A → Set) → P x → P y

≡⇒Leib : ∀ {A : Set} {x y : A} → x ≡ y → Leib A x y
≡⇒Leib eq P = subst P eq

-- 反向要「聪明的谓词」：把 P 实例化为「和 x 相等」本身，再喂进 refl
Leib⇒≡ : ∀ {A : Set} {x y : A} → Leib A x y → x ≡ y
Leib⇒≡ {x = x} l = l (λ z → x ≡ z) refl
```

这说明命题等式「不多不少，刚好是不可区分性」。那为何 stdlib 仍以 data 为准？
因为 **refl 的转换检查与模式匹配塌缩是内核免费提供的**，Leibniz 版每次都要手
动实例化谓词、还升宇宙。24 章立方 Path 是第三条路，先按下不表。

## 11.7 ≠：否定就是「吃假设的函数」

stdlib 的「不等」没有任何新机制（`PropositionalEquality/Core`）：

```agda
x ≢ y = ¬ x ≡ y            -- _≢_（\nequiv）定义处
¬ A   = A → ⊥              -- Relation.Nullary.Negation.Core 第 26 行
```

展开两层：`x ≢ y` 就是 `(x ≡ y) → ⊥`——**证不等 = 交出吃等式证据产荒谬的
函数**。而 10 章你已经见过「荒谬怎么产出」：等式类型凑不出候选构造子时，
一个 `()` 分支都不写：

```agda
0≢1 : 0 ≢ 1
0≢1 ()                       -- 0 ≡ 1：zero 与 suc 索引方程无解，分支不存在

suc-≠ : ∀ {n : ℕ} → suc n ≢ n
suc-≠ ()                     -- suc n ≡ n 连 occurs check 都过不了
```

`≢` 的对称性是函数复合（∘ 在 `Function`；`f ∘ g` 先算 g——方向写反是
新手第一坑，实测报错相当扎眼）：

```agda
≢-sym : 1 ≢ 0
≢-sym = 0≢1 ∘ sym            -- (1≡0) --sym--> (0≡1) --0≢1--> ⊥
```

写成 `sym ∘ 0≢1` 会怎样？⊥ 接不上一个 ≡ 类型：

```text
/home/xulun/code/programming/agda/examples/Tmp11a.agda:82.20-23: error: [UnequalTerms]
Data.Irrelevant.Irrelevant Data.Empty.Empty !=< (_x_163 ≡ _y_164)
when checking that the expression 0≢1 has type
(x : 0 ≡ 1) → _x_163 ≡ _y_164
```

报错第一行「`Irrelevant Empty` 不等于一个 ≡ 类型」就是 12 章 ⊥ 的入口：
stdlib 把 ⊥ 定义为无关证明的 `Irrelevant Empty`，所以报错里它总以全名出现。

## 11.8 rewrite：子句级改写，和 .eq 的一体两面

`rewrite`（Agda 2.6.1+）是给「证明现场」用的代入 tactic 化语法。
2.8.0 实测可用形态**只有一种：挂在左端之后的子句级改写**：

```agda
rw-cong : ∀ {x y : ℕ} → x ≡ y → suc x ≡ suc y
rw-cong {x} eq rewrite eq = refl

rw-sym : ∀ {x y : ℕ} → x ≡ y → suc y ≡ suc x
rw-sym {x} eq rewrite sym eq = refl

rw-lemma : ∀ n → suc (n + 0) ≡ suc n
rw-lemma n rewrite n+0 n = refl
```

语义：`rewrite e` 取 e 的类型 `lhs ≡ rhs`，在**目标类型**里把 lhs 的出现
换成 rhs，然后照旧交证明。`rw-cong` 里目标 `suc x ≡ suc y` 经 eq 改成
`suc y ≡ suc y`，refl 收官——与 11.3 的 `cong-case f refl = refl` 逻辑同型，
差别只在 rewrite **不拆左端**：eq 保留原样、变量不被并掉，适合「手里还有
别的假设要用」的场合。`rw-sym` 用 `sym eq` 反向改写，`rw-lemma` 直接拿
归纳引理当改写规则——这一条几乎是 Coq `rewrite` 的同款手感。

必须澄清一个**实测与流传语法的出入**：项级 `rewrite e in x` 在 Agda 2.8.0
**不存在**，任何位置任何括号组合都直接 ParseError：

```text
/home/xulun/code/programming/agda/examples/Tmp11b.agda:11.10: error: [ParseError]
rewrite<ERROR>  eq in p₀)
```

（`{-# OPTIONS --rewriting #-}` 是「自定义重写规则」的 REWRITE pragma，与此
无关，加了也救不回来。）网上教程的 `rewrite ... in ...` 请按
「子句级 rewrite + 新版本 sugar」理解，写 2.8 代码用上面的形态。

rewrite 与点模式是**一枚硬币的两面**。三种等价证法并排（(b)(c) 见示例）：

```agda
-- (a) rewrite 子句级：目标被改写，eq 还在手里
rw-cong {x} eq rewrite eq = refl

-- (b) refl 模式：端点当场合并，eq 消失
rw-mode : ∀ {x y : ℕ} → x ≡ y → suc x ≡ suc y
rw-mode refl = refl

-- (c) 点模式显式记账：swap-args x .x refl = refl（11.3）
```

展开后 (a) 就是 `subst` 的用法（编译器造一个「目标关于 x 泛化、沿 eq
transport」的 motive），(b)(c) 把同样的合一结果写进模式。**模式匹配是免费
的 rewrite，rewrite 是不动模式的匹配**；覆盖率与点模式检查完全一致。

两条实测行为要留意。其一，多条改写用 `|` 串接，但**后一条可能空转**——
rewrite 是按「可转换的出现」抽象的，改写顺序敏感，空转只给警告且退出码 0：

```text
/home/xulun/code/programming/agda/examples/Tmp11c.agda:16.30-35: warning: -W[no]RewritesNothing
`rewrite' did not apply
when checking that the clause
Tmp11c.-rewrite28 n _ refl rewrite n+0 n = refl has type
(n lhs : ℕ) → lhs ≡ suc n → suc lhs ≡ suc (suc n)
```

（这是 `rewrite n+0 (suc n) | n+0 n = refl` 证 `suc (suc (n + 0)) ≡ suc (suc n)`
的现场：第一条改写把可转换出现抽象为 `lhs` 并留下约束 `lhs ≡ suc n`，
第二条的 `n + 0` 已被裹走，无处可改。）注意报错里的
`(n lhs : ℕ) → lhs ≡ suc n → ...`——rewrite 在幕后**给子句加了参数**，
读这种被展长的 clause 是 Agda 报错基本功。其二，`rewrite` 只作用于类型层的
`_≡_`（含其对称），对 `_≢_` 和序关系都不行——那些走 14 章推理框架。

## 11.9 练习路线

1. 仿 `uip₁` 证 `uip₂ : (p : 2 + 2 ≡ 4) → p ≡ refl`（一行 refl）。
2. 不用 rewrite，只用 sym/trans/cong 证 `∀ n → n + 1 ≡ suc n`
   （对 n 归纳，感受 cong 与 refl 分支各自在哪一步）。
3. 把 `rw-lemma` 的改写方向换掉：`rw-lemma n rewrite sym (n+0 n) = refl`
   编译试试，读它报的错——再解释为什么它「不该过」。

## 11.10 坑位清单（本项目实测）

1. **refl 查的是转换（规约后可比）**：`0 + n ≡ n` 一行 refl，
   `n + 0 ≡ n` 必报 `UnequalTerms`（原文见 11.2），要归纳——「哪侧免费」
   由定义的递归参数决定。
2. **项级 `rewrite e in x` 在 2.8.0 是 ParseError**（11.8 实测）；rewrite
   只有子句级形态，多条用 `|` 串接。
3. **RewritesNothing 警告、退出码仍 0**：多条 rewrite 时后条被前条「吃掉」
   目标，静默空转——CI 别只看退出码。
4. **`case_of_` 在 `Function`**，从 `Relation.Nullary` using 只报
   ModuleDoesntExport 警告，炸点在使用处 NotInScope（10.6 同款家族）。
5. **复合方向**：`f ∘ g` 先 g 后 f；`1 ≢ 0` 要写 `0≢1 ∘ sym`，写反得到
   带着 `Irrelevant Empty` 全名的天书报错（11.7 原文）。
6. **J 的参数序**：stdlib 是 `J B p b`（票在前），教科书常见 `J B b p`，
   抄代码先对签名。
7. **Leibniz 等式在 Set₁**：量化谓词族升宇宙；`Leib⇒≡` 靠实例化
   `λ z → x ≡ z`，换方向（`λ z → z ≡ x`）得到的是 `y ≡ x`。
8. **UIP 只赚局部**：闭端点（`1 ≡ 1`）可证「一切证明等于 refl」（`uip₁`），
   变元端点不行——那是 `Axiom.UniquenessOfIdentityProofs` 的公理地盘。
   跨类型等式（`0 ≡ true` 不合式）另走异质等式 `HeterogeneousEquality`。

---
上一章：[10 · 依赖类型入门：Fin](10-dependent.md) ｜ 下一章：[12 · 逻辑连接词](12-logic.md) ｜ 返回：[README](../README.md)
