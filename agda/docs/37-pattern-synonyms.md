# 37 · pattern 同义词与差分整数

自然数不够用，第一件事就是「把减法补回来」。教科书只给你两行——
整数 = 自然数的等价类、减法 = 加相反数——然后立刻翻篇。本章把这
两行**真的写成 Agda 程序**，并且诚实地把弯路都走一遍：给 `ℕ` 加一
枚 `pred` 构造子（规范化约不到不动点）、给 `ℕ` 贴正负标签（两个零
算不相等），中间站才是 Maguire 的差分整数 `a ⊖ b`（记录式，规范化
=同时摘 suc）——它解决了「会不会算」，还没解决「表示唯一」与「拐
杖债」（37.5、37.8）。全程取材 Sandy Maguire《Certainty by
Construction》第 2 章 2.10–2.15，第 4 章的「Overconstrained by Dot
Patterns」一节作为 37.5 的配套阅读。

真正的主角是 **pattern 同义词**（`pattern` 声明）。它是本章唯一能
同时做到三件事的语言设施：让记录式的差分整数有 `a ⊖ b` 这种**中缀
书写手感**；让 `ℤ` 的规范形有一个**能用在模式匹配里**的别名，从而
把取反函数写成三行对称表；以及（37.9）解释 stdlib 自己为什么在
`Data.Integer.Base` 里就用了它。**同义词只换名字不换计算**——这句
话既是它的威力，也是它全部的坑。

对应示例：`../examples/Ex37-patsyn.agda`

本章报错/警告文本均为 Agda 2.9.0 + stdlib 3.0 实测原样粘贴
（复现用的临时探针文件已删除，报错路径显示为当时的探针路径）；
代码片段与示例一致，示例经 `./build.sh Ex37-patsyn` 全量类型检查
通过。

## 37.1 monus：ℕ 里的「减法」不是减法

stdlib 的 `_∸_`（monus/截断减法）就是编译器内建 `Agda.Builtin.Nat`
里的 `_-_`，`Data/Nat/Base.agda:175` 用
`renaming (_-_ to _∸_)` 把它换了个名（三条款顺次是「减 0 不变 / 0
减任何数归零 / 同时摘 suc」）：

```agda
n     - zero = n
zero  - suc m = zero
suc n - suc m = n - m
```

三条规则都很讲道理，代价是**结果永远截到 0**——负数在 `ℕ` 里无处
可去。于是一整代数字段（group）该有的方程一条都不成立：

```agda
-- (2 ∸ 3) 先归零，加回来的 3 补不回 2：消去律 (m ∸ n) + n ≡ m 失效。
∸-cancel-fail : (2 ∸ 3) +ℕ 3 ≡ 3
∸-cancel-fail = refl

-- 结合律？两种括号给出两种答案：
∸-assoc-fail₁ : (3 ∸ 2) ∸ 5 ≡ 0
∸-assoc-fail₁ = refl
∸-assoc-fail₂ : 3 ∸ (2 ∸ 5) ≡ 3
∸-assoc-fail₂ = refl
```

注意这两组不是「反例证明失败」，而是 `refl` **算出了和期望相反的
值**——`3 ∸ (2 ∸ 5)` 里 `2 ∸ 5` 先归零，于是整式读回 3。这就是
36 章「Agda 只有规范化」的另一面：算得很确定，只是答案不讲理。

连「几乎显然」的 `n ∸ n ≡ zero` 都证不动。硬交 `refl`：

```text
/Volumes/mac004/code/programming/agda/examples/TmpProbe37k1.agda:6.14-18: error: [UnequalTerms]
The terms
  n ∸ n
and
  zero
are not equal at type ℕ
when checking that the expression refl has type n ∸ n ≡ zero
```

`n` 是变量，`∸` 的两条递归方程（先剥左还是先剥右）都触发不了，
`n ∸ n` 是卡住的正规式——和 13 章 `n + zero` 一模一样的剧情。真正
难受的是**左单位元压根不存在**，这条可以用荒谬模式证死：

```agda
isZero? : ℕ → Bool
isZero? zero        = true
isZero? (suc n)     = false

-- 荒谬模式的第一次出手：true ≡ false 无构造子可造，零条子句即可。
true≢false : ¬ (true ≡ false)
true≢false ()

∸-no-left-unit : (e : ℕ) → ¬ ((n : ℕ) → e ∸ n ≡ n)
∸-no-left-unit zero h = true≢false (cong isZero? (h 1))
∸-no-left-unit (suc e) h = true≢false (sym (cong isZero? (h 0)))
```

读法：假设 `h : ∀ n → e ∸ n ≡ n`。若 `e = zero`，取 `n = 1` 得
`zero ∸ 1 ≡ 1`，即 `zero ≡ suc 1`，`cong isZero?` 把它翻译成
`true ≡ false`；若 `e = suc e`，取 `n = zero` 得 `suc e ≡ zero`，
方向相反所以外面套一层 `sym`。两条子句都是**判别器 + 荒谬模式**
的固定套路（11/15 章的工具，本章开始常态化使用）。

结论：`(ℕ, ∸)` 什么都不是，而 `(ℕ, +)` 有完好的零与结合律。想要
减法漂亮，只能换地基——把「差」本身做成数据。

## 37.2 弯路一：给 ℕ 加一枚 pred

最直觉的补法（Maguire 2.11）：照 `data ℕ = zero | suc` 的样，再加
一条「往回数一个」。

```agda
data ℤ₁ : Set where
  zero₁ : ℤ₁
  suc₁  : ℤ₁ → ℤ₁
  pred₁ : ℤ₁ → ℤ₁
```

书里构造子就叫 `zero/suc/pred`；示例为避免与 `ℕ` 的零散名撞车，加
了下标 `₁`（同一条坑见 37.10 第 5 条）。病根立刻出现：**0 有无穷多
种写法**——`zero₁`、`pred₁ (suc₁ zero₁)`、`suc₁ (pred₁ zero₁)`、
`pred₁ (suc₁ (pred₁ (suc₁ zero₁)))`……于是需要一枚 `normalize`
把 `suc`/`pred` 对消。Maguire 给出的「诚实尝试」逐字搬来：

```agda
normalize₁ : ℤ₁ → ℤ₁
normalize₁ zero₁                  = zero₁
normalize₁ (suc₁ zero₁)           = suc₁ zero₁
normalize₁ (suc₁ (suc₁ x))        = suc₁ (normalize₁ (suc₁ x))
normalize₁ (suc₁ (pred₁ x))       = normalize₁ x
normalize₁ (pred₁ zero₁)          = pred₁ zero₁
normalize₁ (pred₁ (suc₁ x))       = normalize₁ x
normalize₁ (pred₁ (pred₁ x))      = pred₁ (normalize₁ (pred₁ x))
```

它对吗？书里的反例，`refl` 直接验算就能翻案：

```agda
norm₁-counterexample :
  normalize₁ (suc₁ (suc₁ (pred₁ (pred₁ zero₁)))) ≡ suc₁ (pred₁ zero₁)
norm₁-counterexample = refl

-- normalize₁ 交回了一个**自己还没被算到底**的结果：再约一轮还能约！
norm₁-not-fixpoint :
  normalize₁ (normalize₁ (suc₁ (suc₁ (pred₁ (pred₁ zero₁))))) ≡ zero₁
norm₁-not-fixpoint = refl
```

`normalize₁` 号称「规范化」，却交出 `suc₁ (pred₁ zero₁)` 这种**还
带对子**的结果；对它再跑一次才归零。也就是说它不是幂等的，甚至不
是不动点投影。病理解剖：`suc` 与 `pred` 被压进**同一条构造链**，
消对时局部模式（`suc₁ (pred₁ x)`）无法知道「该配哪一对」，匹配顺序
就成了语义的一部分。只要正负计数共用一根指针，规范化就说不清自己
「约到不动点」——这条教训会原样出现在 37.8 的良定义性证明里。

## 37.3 差分整数：把「差」做成记录（Maguire 2.12）

出路是**分账**：一个整数 = （多出来的正方块数，多出来的负方块数）。

```agda
record ℤdiff : Set where
  constructor mkℤdiff
  field
    pos : ℕ
    neg : ℕ

-- 书写手感靠 pattern 同义词找回：
pattern _⊖_ p q = mkℤdiff p q
infixl 6 _⊖_
```

`pattern _⊖_ p q = mkℤdiff p q` 是本章第一枚同义词：读作「`p` 个
正方块减去 `q` 个负方块」。它**不是**函数，也不是宏——它是给模式
匹配器看的别名，于是等式左边可以写 `(a ⊖ b)` 直接拆账本（语法细节
与全部禁令见 37.6）。

约分=两边同时摘掉一个 `suc`，摘到任何一侧见底为止：

```agda
normalize : ℤdiff → ℤdiff
normalize (zero ⊖ q)      = zero ⊖ q
normalize (suc p ⊖ zero)  = suc p ⊖ zero
normalize (suc p ⊖ suc q) = normalize (p ⊖ q)
```

与 37.2 的 `normalize₁` 的本质区别有两点：**(1)** 每步都成对消去，
`pos`/`neg` 各管各的，不存在「先配哪一对」的歧义；**(2)** 递归参数
`(p ⊖ q)` 严格是原参数的子结构，两条见底分支覆盖了所有不可能残留
的情形——所以它天生幂等（37.8 的 `norm-norm`：三条子句，两支
`refl` 白送、一支递归）。

「同一个整数」的等价类直觉在这里：`(a ⊖ b)` 与 `(a′ ⊖ b′)` 表示同
一整数，当且仅当交叉相加相等 `a +ℕ b′ ≡ a′ +ℕ b`（把 `a − b = a′ − b′`
移项，避开减法）。同一个 0 的无穷多种记账全部约到同一处：

```agda
0⊖0-many : (0 ⊖ 0) ≡ normalize (5 ⊖ 5)
0⊖0-many = refl
```

但**未约分的记账彼此不相等**，这一点必须说清楚，否则后面「唯一表
示」一节没有动机。用 `pos` 投影摘出来即可证：

```agda
posOf : ℤdiff → ℕ
posOf (p ⊖ q) = p

1≢0 : ¬ (1 ≡ 0)
1≢0 q = true≢false (sym (cong isZero? q))

1⊖1≢0⊖0 : 1 ⊖ 1 ≢ 0 ⊖ 0
1⊖1≢0⊖0 p = 1≢0 (cong posOf p)
```

算术照 Maguire 的三枚运算。`⊞` 是**不约分**的原料（两边各自相加），
加减乘一律以 `normalize` 收尾：

```agda
_⊞_ : ℤdiff → ℤdiff → ℤdiff
(a ⊖ b) ⊞ (c ⊖ d) = (a +ℕ c) ⊖ (b +ℕ d)

_+_ : ℤdiff → ℤdiff → ℤdiff
x + y = normalize (x ⊞ y)

_-_ : ℤdiff → ℤdiff → ℤdiff
(a ⊖ b) - (c ⊖ d) = normalize ((a +ℕ d) ⊖ (b +ℕ c))

_*_ : ℤdiff → ℤdiff → ℤdiff
(a ⊖ b) * (c ⊖ d) =
  normalize ((a *ℕ c +ℕ b *ℕ d) ⊖ (a *ℕ d +ℕ b *ℕ c))
```

乘法那行值得停一下：`(p − q) × (r − s) = (pr + qs) − (ps + qr)`，
负负得正不是规则，是**展开后两边账本对消的自然结果**。Maguire 式
单元测试，`refl` 即断言、规范化即执行：

```agda
test₀ : (1 ⊖ 3) + (2 ⊖ 0) ≡ 0 ⊖ 0
test₀ = refl                              -- 1−3+2 = 0

test₁ : (3 ⊖ 1) - (1 ⊖ 4) ≡ 5 ⊖ 0
test₁ = refl                              -- 2 − (−3) = 5

test₂ : (3 ⊖ 1) * (0 ⊖ 2) ≡ 0 ⊖ 4
test₂ = refl                              -- 2 × (−2) = −4
```

Maguire 在 2.12 末尾的抱怨很实在：每条运算末尾都拖着一次
`normalize`，像一根「计算拐杖」——它算什么很明白，但它**在问题域里
meaning 什么**？而且做证明时处处要带着它（37.8 就是还这笔债）。
两条出路：让表示本身唯一（37.4–37.5），或者证明拐杖与运算可交换
（37.8）。本章两条都走。

顺手实测一条命名坑：`pattern _⊖_` 已经把 `_⊖_` 这个名字**占掉**了，
再想在同作用域里把 `_⊖_` 定义成函数：

```text
/Volumes/mac004/code/programming/agda/examples/TmpProbe37k7.agda:14.1-4: error: [ClashingDefinition]
Multiple definitions of _⊖_. Previous definition
_⊖_ is in scope as
  * a pattern synonym TmpProbe37k7._⊖_ brought into scope by
    - its definition at /Volumes/mac004/code/programming/agda/examples/TmpProbe37k7.agda:12.9-12
when scope checking the declaration
  _⊖_ : ℕ → ℕ → ℕ
```

这就是示例里书中原名 `_⊖_`（`ℕ → ℕ → ℤ` 的真减法）被改名成
`_⊖ℤ_` 的原因（37.7）。28 章的老坑「一个作用域一个名」在 pattern
同义词身上同样成立。

## 37.4 标签法与修直：两块零、一枚改名（Maguire 2.13）

标签法——Maguire 2.13 用来引出「唯一表示」的那一步尝试：给 `ℕ` 贴
正负标签。

```agda
data ℤ₃ : Set where
  +₃_ : ℕ → ℤ₃
  -₃_ : ℕ → ℤ₃
```

语法上很香，但 0 还是两副面孔：`+₃ zero` 与 `-₃ zero`。要命的是它们
**在命题等式里算不相等**——判别器一秒证伪：

```agda
isPos₃ : ℤ₃ → Bool
isPos₃ (+₃ n) = true
isPos₃ (-₃ n) = false

two-zero-clash : ¬ (+₃ zero ≡ -₃ zero)
two-zero-clash p = true≢false (cong isPos₃ p)
```

想无视这条差异、硬写 `refl`，实测报错：

```text
/Volumes/mac004/code/programming/agda/examples/TmpProbe37k3.agda:13.15-19: error: [UnequalTerms]
The terms
  +₃ zero
and
  -₃ zero
are not equal at type ℤ₃
when checking that the expression refl has type +₃ zero ≡ -₃ zero
```

偏偏数学上**要求**它们是同一个数。把 `ℤ₃` 映到差分整数立刻现形：

```agda
to⊖ : ℤ₃ → ℤdiff
to⊖ (+₃ n) = n ⊖ zero
to⊖ (-₃ n) = zero ⊖ n

two-zero-agree : to⊖ (+₃ zero) ≡ to⊖ (-₃ zero)
two-zero-agree = refl
```

「相等却算不相等」的标准处置是**商集**：把等价类做成值类型。Agda
里能做（17 章 `_↔_`、24 章 cubical 的路径），但都很重。Maguire 的
招法省得到家：**改构造子的名，让坏记法根本无法书写**——把 `-_` 换
成 `-[1+_]`，「负零」失去合法性，唯一表示一次到位：

```agda
data ℤfin : Set where
  +_     : ℕ → ℤfin
  -[1+_] : ℕ → ℤfin
```

读法：`+ n` 表示 `n ⊖ 0`；`-[1+ n ]` 表示 `0 ⊖ suc n`（构造子的
花括号是名字的一部分，实参写在 `[ ]` 里，`-[1+ zero ]` 就是 −1）。
于是「正的不可能是负的」变成荒谬模式级别的常识：

```agda
isPos : ℤfin → Bool
isPos (+ n)     = true
isPos -[1+ n ]  = false

pos≢neg : (m n : ℕ) → + m ≢ -[1+ n ]
pos≢neg m n p = true≢false (cong isPos p)
```

`suc`/`pred` 跨零各管各的，正负两侧对称：

```agda
sucℤ : ℤfin → ℤfin
sucℤ (+ x)        = + suc x
sucℤ -[1+ zero ]  = + zero
sucℤ -[1+ suc x ] = -[1+ x ]

predℤ : ℤfin → ℤfin
predℤ (+ zero)    = -[1+ zero ]
predℤ (+ suc x)   = + x
predℤ -[1+ x ]    = -[1+ suc x ]

suc-pred-id : (x : ℤfin) → sucℤ (predℤ x) ≡ x
suc-pred-id (+ zero)  = refl
suc-pred-id (+ suc x) = refl
suc-pred-id -[1+ x ]  = refl
```

这条引理值得对比 37.2：在 `ℤ₁` 上「`suc₁` 与 `pred₁` 互为逆」根本
写不出来（`pred₁ (suc₁ x) ≡ x` 成立，但 `suc₁ (pred₁ x) ≡ x` 在
`x = zero₁` 处就崩），而这里三行 `refl`。改表示远胜于补引理——这
是「构造子命名即设计」的教科书写法。

## 37.5 规范形做成类型：荒谬模式、dot pattern 与过度约束

上面是「用表示排除坏值」。另一条互补的路：保留差分表示，把
**规范形做成一个命题族**，让类型系统替你盯住坏情形。

```agda
data IsCanon : ℤdiff → Set where
  posForm : (p : ℕ) → IsCanon (p ⊖ zero)
  negForm : (n : ℕ) → IsCanon (zero ⊖ suc n)
```

两个构造子恰好是 `normalize` 的两类不动点；索引为 `suc p ⊖ suc n`
的纤维**无人认领**，于是「两侧同时非零」不是任何规范形——零条子句
证死：

```agda
noCanon : (p n : ℕ) → ¬ IsCanon (suc p ⊖ suc n)
noCanon p n ()
```

荒谬模式 `()` 在这里成立**当且仅当**索引真的匹配不到任何构造子：
`posForm` 要求第二侧是 `zero`、`negForm` 要求第一侧是 `zero`，而
`suc p ⊖ suc n` 两侧都是 `suc`。这条「无构造子」的判定是 Agda 自己
做的，不是作者声明的，所以它同时给出了 37.3 拐杖的语义解释。

约分必落进规范形（对本 `p`/`q` 双参数的结构递归，13 章口径）：

```agda
norm-IsCanon : (x : ℤdiff) → IsCanon (normalize x)
norm-IsCanon (zero ⊖ zero)    = posForm zero
norm-IsCanon (zero ⊖ suc n)   = negForm n
norm-IsCanon (suc p ⊖ zero)   = posForm (suc p)
norm-IsCanon (suc p ⊖ suc n)  = norm-IsCanon (p ⊖ n)
```

四条子句一条都不能省。想偷懒把首两支并成 `norm-IsCanon (zero ⊖ n)
= negForm n`，实测撞上索引检查：

```text
/Volumes/mac004/code/programming/agda/examples/TmpProbe37k2.agda:27.27-36: error: [UnequalTerms]
The terms
  suc n
and
  n
are not equal at type ℕ
when checking that the expression negForm n has type
IsCanon (normalize (zero ⊖ n))
```

因为 `zero ⊖ zero` 这支约分后落在 `posForm` 上，`negForm` 的索引
`zero ⊖ suc n` 对不上——正是 37.2「`normalize₁` 不是幂等」的同一类
错误在**类型层**被拦下。

消费 `IsCanon` 时要用 **dot pattern**：证明参数会逼出索引等式，把
等式如实写回左边（`.` 前缀表示「这里不新增信息，只是记录已推出的
结果」）：

```agda
whichSide : (x : ℤdiff) → IsCanon x → Bool
whichSide .(p ⊖ zero)       (posForm p) = true
whichSide .(zero ⊖ suc n)   (negForm n) = false
```

两条子句就已经穷尽（`suc p ⊖ suc n` 那支被 `noCanon` 判死，模式匹
配器不需要第三条）。

Maguire 第 4 章「Overconstrained by Dot Patterns」给了 dot pattern
的另一面：**点多到互相矛盾时，Agda 会拒绝猜**。他把「靠加法造出来
的小于等于」定义成一枚索引族（探针原文，`_+_` 即 `Data.Nat` 的加
法；本示例里它改名叫 `_+ℕ_`）：

```agda
data _≤ₗ_ : ℕ → ℕ → Set where
  lte : (a b : ℕ) → a ≤ₗ (a + b)
```

一个构造子、两枚自由参数：`lte a b` 是「从 `a` 走 `b` 步到 `a + b`」
的证据。注意索引是**算出来的**（`a + b`），这正是「索引由计算给出」
的典型场景。想证「两侧同时 `suc` 仍保持关系」，写对了是干净的一行
——把 Agda 解出的等式如实 dot 在左边：

```agda
suc-mono′ : {x y : ℕ} → x ≤ₗ y → suc x ≤ₗ suc y
suc-mono′ {x} {.(x + b)} (lte .x b) = lte (suc x) b
```

`lte .x b : x ≤ₗ (x + b)` 与期望索引 `x ≤ₗ y` 联立解出
`y ≡ x + b`，把它写成 dot（`{.(x + b)}`）之后，右边
`lte (suc x) b : suc x ≤ₗ suc x + b` 与目标 `suc x ≤ₗ suc y` 同型，
过关（探针里这一条先出现，独立检查通过）。

可是如果**把引理单态化到 `y ≡ x` 的实例上**——两个索引恰好是同一个
变量——约束系统就没有语法解了：

```agda
suc-mono-mono : {x : ℕ} → x ≤ₗ x → suc x ≤ₗ suc x
suc-mono-mono {x} (lte .x b) = lte (suc x) b
```

报错是本章最壮观的一条：

```text
/Volumes/mac004/code/programming/agda/examples/TmpProbe37i.agda:15.20-28: error: [SplitError.UnificationStuck]
I'm not sure if there should be a case for the constructor lte,
because I get stuck when trying to solve the following unification
problems (inferred index ≟ expected index):
  a ≟ x
  a + b ≟ x
Possible reason why unification failed:
  Cannot solve variable a of type ℕ with solution a + b because the
  variable occurs in the solution, or in the type of one of the
  variables in the solution.
when checking that the pattern lte .x b has type x ≤ₗ x
```

两个方程 `a ≟ x`、`a + b ≟ x` 合起来要 `a ≟ a + b`，**变量出现在
自己的解里**——除非 `b` 是 `zero`，否则无解；而 `b` 是变量，Agda
不能判定，于是它老实交代「I'm not sure」，既不接纳也不拒绝这条子
句（老教程把它叫 unification stuck）。有意思的是 37.1 的判别器在
这里复活：`x ≤ₗ x` 的唯一证据确实是 `lte x zero`（取 `b := zero`），
可 `a ≟ x` 与 `a + zero ≟ x` 要把 `+ zero` **化简**掉才合一，而模式
匹配器不做化简——它只解语法上无歧义的联立。解法有两条：别把引理
单态化（像 `suc-mono′` 那样留 `y` 的一般形式，点够用就行），或者把
关系定义成索引不重叠、不靠计算给出的形状（本例的 `ℤfin` 就是靠这
一招吃到唯一表示的）。教训：**索引算出来的东西越多，点就要写得越
准**——这与 37.1 `n ∸ n` 卡住是同一枚硬币的两面。

最后把「唯一表示」的范畴式证词落地：`ℤfin` 与约到底的 `ℤdiff` 互
译，两边都是纯计算：

```agda
fromDiff : ℤdiff → ℤfin
fromDiff (a ⊖ b) = go a b
  where
  go : (a b : ℕ) → ℤfin
  go zero zero      = + zero
  go zero (suc n)   = -[1+ n ]
  go (suc p) zero   = + suc p
  go (suc p) (suc n) = go p n

toDiff : ℤfin → ℤdiff
toDiff (+ n)      = n ⊖ zero
toDiff -[1+ n ]   = zero ⊖ suc n

from-to⁺ : (n : ℕ) → fromDiff (toDiff (+ n)) ≡ + n
from-to⁺ zero     = refl
from-to⁺ (suc n)  = refl

from-to⁻ : (n : ℕ) → fromDiff (toDiff -[1+ n ]) ≡ -[1+ n ]
from-to⁻ n        = refl

to-from : (a b : ℕ) → toDiff (fromDiff (a ⊖ b)) ≡ normalize (a ⊖ b)
to-from zero zero       = refl
to-from zero (suc n)    = refl
to-from (suc p) zero    = refl
to-from (suc p) (suc n) = to-from p n
```

解读：`fromDiff ∘ toDiff = id`（`ℤfin` 的每个数原样往返，两支 `refl`
就够，因为 `toDiff` 的输出必然落在 `posForm`/`negForm` 里），
`toDiff ∘ fromDiff = normalize`（差分整数的每条**纤维**被折到规范
代表元；归纳一支不能省，因为它正是 `normalize` 的对消步）。一个
往返处处 `refl`，另一个往返必须结构递归——这种不对称就是
「规范化不是恒等、而是投影」的最便宜证据。

## 37.6 pattern 同义词：语法、红蓝黑与「规范形别名」

`pattern` 声明的语法就是一行等式：

```agda
pattern 名字 变量… = 模式
```

它和函数声明共享中缀/优先级的一切（`infixl 6 _⊖_` 照写），但语义
完全不同：**同义词不做任何计算**，它只是让模式匹配器在匹配时把左
边展开成右边。Agda 对它的四条硬规矩，全部实测过：

**(1) 右边只许「红字 + 黑字」**——构造子、别的 pattern 同义词、变
量；**蓝函数**（普通定义的函数）一律禁止。掺一个进去：

```text
/Volumes/mac004/code/programming/agda/examples/TmpProbe37b.agda:14.1-35: error: [NoParseForLHS]
Could not parse the pattern synonym right-hand side suc (double n)
Problematic expression: (double n)
Operators used in the grammar:
  None
when scope checking the declaration
  pattern badBlue n = suc (double n)
```

**(2) 左边的每个变量都必须在右边登场**（否则同义词匹配时会漏信息）：

```text
/Volumes/mac004/code/programming/agda/examples/TmpProbe37c.agda:6.21-22: error: [UnusedVariableInPatternSynonym]
Unused variable in pattern synonym: n
when scope checking the declaration
  pattern badUnused m n = suc m
```

**(3) 右边的每个变量都必须被左边绑定**（禁止「凭空冒出的自由变量」）：

```text
/Volumes/mac004/code/programming/agda/examples/TmpProbe37d.agda:9.1-28: error: [UnboundVariablesInPatternSynonym]
Unbound variables in pattern synonym: q
when scope checking the declaration
  pattern badPair p = (p , q)
```

**(4) 左边的参数位置只能是变量**，写构造子形状会被当成遮蔽：

```text
/Volumes/mac004/code/programming/agda/examples/TmpProbe37e.agda:6.16-20: error: [PatternSynonymArgumentShadows.Constructor]
Pattern synonym variable zero shadows constructor defined at:
/Volumes/mac004/.stack-home/agda-build/.stack-work/install/x86_64-osx/faff8921e62ea95999f0f67e79eaab55f9b7dfb901de7a43aed2846e77ed6496/9.14.1/share/x86_64-osx-ghc-9.14.1-inplace/Agda-2.9.0/lib/prim/Agda/Builtin/Nat.agda:9.3-7
when scope checking the declaration
  pattern badLHS zero = suc zero
```

禁令 (1) 是 Maguire 划的重点，也是本章的「为什么」：**模式匹配里
等号左边冒生的标识符一律是新变量（黑字），匹配只认构造子与同义词
（红字）**。如果同义词右边允许蓝函数，一个黑字函数名就能伪装成红
字进入模式，匹配器的「只在数据形状上分派」这条保证当场作废。所以
这不是风味，是安全闸门。

顺带实测两条合法但少见的形状（都 exit 0）：同义词名可以长成像变
量，无参同义词也可以是纯构造子别名——

```agda
pattern x y = suc y     -- 名字像黑字，但声明为同义词后就是红字
pattern one′ = suc zero -- 无参：它是模式，不是值 1 的宏
```

这也不是什么生僻技巧：stdlib 自己就靠 pattern 同义词给证明造短名，
`Data.Nat.Base:32` 的 `pattern 2+ n = suc (suc n)`（注释写着
smart constructor），以及 :65–67 的

```agda
pattern z<s     {n}     = s≤s (z≤n {n})
pattern s<s {m} {n} m<n = s≤s {m} {n} m<n
```

顺便演示了左边第三件事：**左边的变量也可以是隐式变量 `{n}`**，
使用时靠索引推断填上。

第二条（无参同义词）尤其要留神：一旦 `one′` 不在作用域里，
`h one′ = zero` 里的 `one′` **静默降级为新变量**，程序照编译，语义
全错：

```agda
module Hidden where
  pattern one′ = suc zero

h : ℕ → ℕ
h one′ = zero            -- 作者以为：h 1 = 0，其余恒等；其实 one′ 是新变量
h n = n

wrong : h (suc (suc zero)) ≡ zero
wrong = refl             -- 编译过！说明 h 已悄悄变成「恒返 zero」
```

Agda 只肯给一条警告（实测 exit 0，程序类型检查「成功」）：

```text
/Volumes/mac004/code/programming/agda/examples/TmpProbe37h.agda:13.1-8: warning: -W[no]UnreachableClauses
Unreachable clause
when checking the definition of h
```

第一条子句吃下了所有输入，第二条 `h n = n` 永远够不到——**「怎么
第二支没生效」的 UnreachableClauses 警告，就是同义词拼错/漏 import
的指纹**。跨模块使用时写限定名 `h₂ Hidden.one′ = zero`，行为立刻
回到预期（`right : h₂ (suc (suc zero)) ≡ suc (suc zero)` 也 `refl`
过关）。

回到主线。`ℤfin` 永远由 `+_` 与 `-[1+_]` 构成，但用差分记号重述规
范形，正负两侧立刻对称——这就是 Maguire 2.14 的「规范形别名」手法
（示例里的名字带 `ℤ` 以免与 `_⊖_` 混淆）：

```agda
pattern ℤ⊖0 n     = + n          -- 规范形：n ⊖ 0（含零）
pattern 0ℤ⊖ n     = -[1+ n ]     -- 规范形：0 ⊖ suc n（严格负）
```

有了别名，取反从「四处补 suc」变成三行对照表：

```agda
infix 8 -_
-_ : ℤfin → ℤfin               -- 前缀取反（stdlib 同款拼写 `-_`）
- (ℤ⊖0 zero)      = ℤ⊖0 zero     -- 0 的镜像还是 0
- (ℤ⊖0 (suc n))   = 0ℤ⊖ n        -- +(n+1) ↦ 0⊖(n+1)
- (0ℤ⊖ n)         = ℤ⊖0 (suc n)  -- 0⊖(1+n) ↦ +(n+1)

-- 对合性零证明：三条子句每条都是「算两步回到原形」。
neg-involutive : (x : ℤfin) → - (- x) ≡ x
neg-involutive (ℤ⊖0 zero)     = refl
neg-involutive (ℤ⊖0 (suc n))  = refl
neg-involutive (0ℤ⊖ n)         = refl
```

这就是「同义词只换名字不换计算」的收益：证明里没有任何新思想，
只是**读得懂了**。第三支 `-(0ℤ⊖ n) = ℤ⊖0 (suc n)` 为什么不用像第一
支那样把 `n` 拆开？因为 `-[1+ zero ]` 的镜像是 `+ (suc zero)`，
`suc` 挪到了别名外面——`ℤ⊖0`/`0ℤ⊖` 这对名字把「差一格」的偏移写
进了命名，函数体就不必反复补偿。

**坑：同义词的实参是复合模式时必须加括号。**把上面第二支改成
`- (ℤ⊖0 suc n) = 0ℤ⊖ n`（漏掉里层括号，让 `suc` 与 `n` 变成两枚实
参）：

```text
/Volumes/mac004/code/programming/agda/examples/TmpProbe37k4.agda:16.4-13: error: [BadArgumentsToPatternSynonym]
Bad arguments to pattern synonym ℤ⊖0
when checking that the clause - ℤ⊖0 suc n = 0ℤ⊖ n has type
ℤfin → ℤfin
```

`ℤ⊖0` 只吃一枚参数，实参位置多出来的一截让 Agda 无法把它读成一个
模式——直接拒绝，比静默误读好得多。同理，别名**出现在右边（值位
置）**时就是普通应用缩写：

```agda
one : ℤfin
one = ℤ⊖0 1

minus-one : ℤfin
minus-one = 0ℤ⊖ 0
```

最后交代一下标题里的 `rewrite`。本章有两层「重写」：一层是
Maguire 的手法——**不动数据类型，只重写它的名字**（`+_` 改读作
`ℤ⊖0`、`-[1+_]` 改读作 `0ℤ⊖`），这就是 pattern 同义词；另一层是证
明里的 `rewrite`  tactic-ish 设施（36/13 章），本章在 37.8 的
`step-ˡ`/`step-ʳ` 里靠它把 `suc` 搬出加法。两者共同点是：**都只改
达人的写法，不改计算结果**。

## 37.7 真减法 `_⊖ℤ_`、整数加法与乘法（Maguire 2.15）

有了 `ℤfin`，`ℕ` 上的减法终于可以返回真值。书中原名 `_⊖_`，本示例
该名的 pattern 同义词版本已被 37.3 占用（37.3 末尾实测的
`ClashingDefinition`），故记作 `_⊖ℤ_`：

```agda
infixl 6 _⊖ℤ_
_⊖ℤ_ : ℕ → ℕ → ℤfin
zero  ⊖ℤ zero     = ℤ⊖0 zero
zero  ⊖ℤ suc n    = 0ℤ⊖ n
suc m ⊖ℤ zero     = ℤ⊖0 (suc m)
suc m ⊖ℤ suc n    = m ⊖ℤ n
```

第四条就是 37.2 想要的「同时摘 suc」，但这次落在**唯一表示**上，
所以它每步都在往规范形走、不会留下半截对子。它与差分记录的
`normalize` 精确互洽：

```agda
⊖ℤ-normalize : (m n : ℕ) → fromDiff (m ⊖ n) ≡ m ⊖ℤ n
⊖ℤ-normalize zero zero      = refl
⊖ℤ-normalize zero (suc n)   = refl
⊖ℤ-normalize (suc m) zero   = refl
⊖ℤ-normalize (suc m) (suc n) = ⊖ℤ-normalize m n
```

前三支 `refl`：两个定义在见底处逐字一致。第四支必须归纳——两边
都在递归，Agda 无法把它们算成同一个东西，这是「同一算法的两种表
达」的常规税。

整数加法四行，Maguire 的分派口诀「同号直接加，异号化归为真减法」：

```agda
infixl 6 _+ℤ_
_+ℤ_ : ℤfin → ℤfin → ℤfin
+ x +ℤ + y        = + (x +ℕ y)
+ x +ℤ -[1+ y ]   = x ⊖ℤ suc y
-[1+ x ] +ℤ + y   = y ⊖ℤ suc x
-[1+ x ] +ℤ -[1+ y ] = -[1+ x +ℕ suc y ]
```

第二支读法：`x + (−(1+y))` 就是 `x ⊖ (1+y)`，正是 37.1 想要的方程
`m − n` 的完整版——这次结果不必截零，因为值域里有负数。

乘法按「乘数形状」分派（5 行，仍然纯计算），顺带演示同义词在模式
位置的第二次出手：

```agda
infixl 7 _×ℤ_
_×ℤ_ : ℤfin → ℤfin → ℤfin
x ×ℤ ℤ⊖0 zero         = ℤ⊖0 zero
x ×ℤ ℤ⊖0 (suc zero)   = x
x ×ℤ 0ℤ⊖ zero         = - x
x ×ℤ ℤ⊖0 (suc (suc y)) = (ℤ⊖0 (suc y) ×ℤ x) +ℤ x
x ×ℤ 0ℤ⊖ (suc y)      = (0ℤ⊖ y ×ℤ x) +ℤ (- x)
```

书末两枚测试（Maguire 2.15）：

```agda
test₃ : (- (ℤ⊖0 2)) ×ℤ (- (ℤ⊖0 6)) ≡ ℤ⊖0 12
test₃ = refl                              -- (−2)×(−6)=12

test₄ : (ℤ⊖0 3) +ℤ (- (ℤ⊖0 10)) ≡ 0ℤ⊖ 6
test₄ = refl                              -- 3−10=−7
```

`test₄` 的右边 `0ℤ⊖ 6` 即 `-[1+ 6 ]`，也就是 −7：`refl` 一路把
`3 ⊖ℤ 10` 算到规范负形。这条断言在 37.1 的世界里根本无法书写。

命名工程上的三件事，示例开头就交代了（也是本项目平铺模块的老规矩）：

- `Data.Nat` 的 `_+_`/`_*_` 改名导入为 `_+ℕ_`/`_*ℕ_`，把 `_+_`/`_*_`
  腾给差分整数（Maguire 书里靠模块分层回避，本项目一个 module 到底）；
- 前缀取反必须写 `-_`（stdlib 拼法，`infix 8 -_`），写成 `_-_` 会
  与差分整数的二元 `_-_` 撞成 `ClashingDefinition`（37.3 同款）；
- 书里的 `ℤ⊖` 别名加上 `ℤ` 字样（`ℤ⊖0`/`0ℤ⊖`），既避开与 `_⊖_` 的
  视觉混淆，也验证了一件事：含 `⊖`、`ℤ`、数字混排的运算符名在
  2.9.0 的词法里合法（实测 exit 0）。

## 37.8 良定义性：两条约分路径殊途同归

Maguire 2.12 那根「计算拐杖」（每条运算末尾拖一次 `normalize`）到
底欠了什么债？给定 `(a ⊖ b)` 与 `(c ⊖ d)`，加法有两种约分日程：

- **路径一（先加后约）**：`normalize ((a⊖b) ⊞ (c⊖d))`——账本并起来
  做总约分，也就是 `_+_` 的定义；
- **路径二（先约后加）**：`normalize (normalize (a⊖b) ⊞ normalize (c⊖d))`
  ——先把两侧各自折成规范代表元，并账之后已经没有可对消的东西。

良定义性 = 两条路径终点是**同一个值**。这就是「加法定义在等价类
上」的计算内容：代表元怎么记账不影响结果。

```agda
two-paths : (a b c d : ℕ) →
  normalize ((a ⊖ b) ⊞ (c ⊖ d))
    ≡ normalize (normalize (a ⊖ b) ⊞ normalize (c ⊖ d))
```

`refl` 证不了它：`a`/`b`/`c`/`d` 是变量，`normalize` 的第一参数立刻
卡住（37.1 的老剧情），而且 `⊞` 里的 `+ℕ` 也动不了。需要三对搬运
引理。第一步手搓 stdlib 里没有的引理——把 `suc` 从加法**左边**搬出
来（对照 13 章的 `+-suc`，它在右边）：

```agda
suc-plus : (m n : ℕ) → suc m +ℕ n ≡ suc (m +ℕ n)
suc-plus zero n = refl
suc-plus (suc m) n = cong suc (suc-plus m n)
```

`_+_` 是「剥第一个参数」定义的（`zero + m = m`；`suc n + m = suc
(n + m)`），把 `suc` 从里面搬到外面需要归纳——注意 stdlib 3.0 里
**没有**现成的 `suc m + n ≡ suc (m + n)`：同名引理 `suc-+` 只存在于
`Data.Nat.Binary.Properties:724`（管的是二元自然数）与
`Data.Integer.Properties:1232`（管的是 `ℤ`），类型都不对；`ℕ` 上有的
是右边版本的 `+-suc : m + suc n ≡ suc (m + n)`（:548）。想直接
import 一个叫 `suc-plus` 的名，实测只有一条**警告**（真正致命的是
随后使用点的 NotInScope）：

```text
/Volumes/mac004/code/programming/agda/examples/TmpProbe37k5.agda:5.33-49: warning: -W[no]ModuleDoesntExport
The module Data.Nat.Properties doesn't export the following:
  suc-plus
when scope checking the declaration
  open import Data.Nat.Properties using (suc-plus)
```

（stdlib 3.0 的 `Data.Nat.Properties` 确实有 `+-suc : m + suc n ≡
suc (m + n)`，`suc` 在里的版本要自己搬——本节就用这个拼写。）

**引理 A（消一步不影响「加完再约」）**。左侧账本两侧各多一个
`suc`，对消它之后再并账，与先并账再总约分同归：

```agda
step-ˡ : (y : ℤdiff) (p q : ℕ) →
  normalize ((suc p ⊖ suc q) ⊞ y) ≡ normalize ((p ⊖ q) ⊞ y)
step-ˡ (a ⊖ b) p q rewrite suc-plus p a | suc-plus q b = refl

step-ʳ : (x : ℤdiff) (p q : ℕ) →
  normalize (x ⊞ (suc p ⊖ suc q)) ≡ normalize (x ⊞ (p ⊖ q))
step-ʳ (a ⊖ b) p q rewrite +-suc a p | +-suc b q = refl
```

这两条是整节的技术心脏，写法上有两个要点：

1. **`y`/`x` 必须在子句左边拆开**（写成 `(a ⊖ b)`）。否则目标里出现
   `suc p +ℕ c`（`c` 是变量），`normalize` 的第三条分支 `suc ⊖ suc`
   匹配不上，`refl` 死在卡住项前。
2. **`rewrite` 是有序的**：`suc-plus p a | suc-plus q b` 先把两个
   `suc` 从 `+ℕ` 外面搬进去（`suc p +ℕ a ≡ suc (p +ℕ a)`），目标左
   边就变成 `normalize (suc (p +ℕ a) ⊖ suc (q +ℕ b) ⊞ …)`，此时
   `normalize` 的 `suc ⊖ suc` 分支**当场触发一次对消**，两边归化到
   同一个正规式，`refl` 收尾。右版本用 `+-suc`（`suc` 在里的方向）
   所以不必再搬。

**引理 B（一侧提前约分无关紧要）**：把 `normalize` 塞进 `⊞` 的任
意一侧都可以拿出来。这是对本参数的归纳，归纳假设正好用在递归一步
上，`sym step` 用来把「多出来的 suc」补回去：

```agda
plus-ˡ : (y : ℤdiff) (a b : ℕ) →
  normalize (normalize (a ⊖ b) ⊞ y) ≡ normalize ((a ⊖ b) ⊞ y)
plus-ˡ y zero b = refl
plus-ˡ y (suc a) zero = refl
plus-ˡ y (suc a) (suc b) = begin
  normalize (normalize (suc a ⊖ suc b) ⊞ y)  ≡⟨⟩
  normalize (normalize (a ⊖ b) ⊞ y)          ≡⟨ plus-ˡ y a b ⟩
  normalize ((a ⊖ b) ⊞ y)                    ≡⟨ sym (step-ˡ y a b) ⟩
  normalize ((suc a ⊖ suc b) ⊞ y)            ∎
```

三条子句恰好穷尽（`zero ⊖ b`、`suc a ⊖ zero` 见底；`suc/suc` 走
归纳）。注意第一、二支是 `refl`：`normalize (zero ⊖ b) = zero ⊖ b`、
`normalize (suc a ⊖ zero) = suc a ⊖ zero`，即见底分支的不动点性在
证明里免费兑现。右版本对称：

```agda
plus-ʳ : (x : ℤdiff) (a b : ℕ) →
  normalize (x ⊞ normalize (a ⊖ b)) ≡ normalize (x ⊞ (a ⊖ b))
plus-ʳ x zero b = refl
plus-ʳ x (suc a) zero = refl
plus-ʳ x (suc a) (suc b) = begin
  normalize (x ⊞ normalize (suc a ⊖ suc b))  ≡⟨⟩
  normalize (x ⊞ normalize (a ⊖ b))          ≡⟨ plus-ʳ x a b ⟩
  normalize (x ⊞ (a ⊖ b))                    ≡⟨ sym (step-ʳ x a b) ⟩
  normalize (x ⊞ (suc a ⊖ suc b))            ∎
```

写 `begin … ∎` 链得先把 `module ≡-Reasoning` 列进 `using`（它是
module，不是名字，光 import `PropositionalEquality` 不够）：

```text
/Volumes/mac004/code/programming/agda/examples/TmpProbe37k8.agda:9.7-12: error: [NotInScope]
Not in scope:
  begin
  at /Volumes/mac004/code/programming/agda/examples/TmpProbe37k8.agda:9.7-12
    (did you mean
       'Relation.Binary.PropositionalEquality.≡-Reasoning.begin_'?)
when scope checking begin
```

**幂等性**单独拎出来（`normalize` 的输出确实是不动点）：

```agda
norm-norm : (a b : ℕ) → normalize (normalize (a ⊖ b)) ≡ normalize (a ⊖ b)
norm-norm zero b = refl
norm-norm (suc a) zero = refl
norm-norm (suc a) (suc b) = norm-norm a b
```

这条正是 37.2 里 `normalize₁` 失败的地方（`norm₁-not-fixpoint` 用
`refl` 证出了「不等于」）。同一个断言，换个表示就成了三行定理。

定理本体是两次「拿出来」的接力：

```agda
two-paths a b c d = begin
  normalize ((a ⊖ b) ⊞ (c ⊖ d))
    ≡⟨ sym (plus-ˡ (c ⊖ d) a b) ⟩
  normalize (normalize (a ⊖ b) ⊞ (c ⊖ d))
    ≡⟨ sym (plus-ʳ (normalize (a ⊖ b)) c d) ⟩
  normalize (normalize (a ⊖ b) ⊞ normalize (c ⊖ d)) ∎
```

先用 `sym (plus-ˡ …)` 把左侧账本的 `normalize` **塞进去**，再用
`sym (plus-ʳ …)` 把右侧的塞进去——方向是「规范 → 原始」的反向，
所以两条都套 `sym`。最后把它改写成运算层面的读法：

```agda
plus-respects-normalize : (x y : ℤdiff) →
  x + y ≡ normalize x + normalize y
plus-respects-normalize (a ⊖ b) (c ⊖ d) = two-paths a b c d
```

证明体只有一行：把 `x`/`y` 用 pattern 同义词 `_⊖_` 拆开，剩下的
`two-paths` 已经干完了。这行也是本章对 pattern 同义词的最终致谢——
如果只能在 RHS 用别名，这条定理还得手写 `mkℤdiff` 的字段投影。

## 37.9 stdlib 对照：Data.Integer（3.0）就是这么造的

本章的 `ℤfin` 与 stdlib 的 `ℤ` 逐字同名，不是巧合：Maguire 的
「标签法 → 修直」正是 stdlib 的路线。`Data.Integer.Base` 第 36–42
行：

```agda
open import Agda.Builtin.Int public
  using ()
  renaming
  ( Int    to ℤ
  ; pos    to infix 8 +_  -- "+ n"      stands for "n"
  ; negsuc to -[1+_]      -- "-[1+ n ]" stands for "- (1 + n)"
  )
```

类型本身是编译器内建的 `Agda.Builtin.Int`（为了和 GHC 的 `Integer`
对接），但**两个构造子的名字就是 stdlib 自己起的**，而且第 46–47
行立刻用 pattern 同义词造对称记号：

```agda
-- Some additional patterns that provide symmetry around 0

pattern +0       = + 0
pattern +[1+_] n = + (ℕ.suc n)
```

对照注释原话「provide symmetry around 0」：stdlib 的动机与本章
`ℤ⊖0`/`0ℤ⊖` 完全一致。取反 `-_`（Base.agda:216）恰好就是用这三枚
模式写成的三行表：

```agda
-_ : ℤ → ℤ
- -[1+ n ] = +[1+ n ]
- +0       = +0
- +[1+ n ] = -[1+ n ]
```

和本章 37.6 的 `-_` 是同构的写法（差别只在 stdlib 用 `+0`/`+[1+_]`
拆正侧、本章用 `ℤ⊖0`/`0ℤ⊖` 记差分），连「零单独一支、`suc` 偏移
藏在别名里」的编排都一样。

| 本章（Ex37-patsyn） | stdlib 3.0 | 备注 |
| --- | --- | --- |
| `ℤfin` | `Data.Integer` 的 `ℤ`（`Agda.Builtin.Int`） | 唯一表示，同一对构造子名 |
| `+_` / `-[1+_]` | `pos → infix 8 +_` / `negsuc → -[1+_]` | Base.agda:40–41 |
| `pattern ℤ⊖0` / `pattern 0ℤ⊖` | `pattern +0` / `pattern +[1+_]` | Base.agda:46–47，「symmetry around 0」 |
| `-_`（三支对称表） | `-_`（Base.agda:216，同样三支） | 优先级都声明为 `infix 8` |
| `_⊖ℤ_`（结构递归 4 支） | `_⊖_ : ℕ → ℕ → ℤ`（Base.agda:224） | stdlib 用 `<ᵇ`/`∸` 走内建快路 |
| `_+ℤ_`（4 支同号/异号分派） | `_+_ : ℤ → ℤ → ℤ`（Base.agda:231） | 四条子句逐一同形 |
| `ℤdiff` + `normalize` | 无 | 唯一表示赢了，商集只活在同构故事里 |

那条「有趣的差异」值得抄源码注释原话（Base.agda:221–223）：

```agda
-- Subtraction of natural numbers.
-- We define it using _<ᵇ_ and _∸_ rather than inductively so that it
-- is backed by builtin operations. This makes it much faster.
_⊖_ : ℕ → ℕ → ℤ
m ⊖ n with m ℕ.<ᵇ n
... | true  = - + (n ℕ.∸ m)
... | false = + (m ℕ.∸ n)
```

也就是说：stdlib 明确放弃了我们 37.7 那种归纳写法，理由是**求值速
度**（36 章的规范化开销在这里变成工程决策）。语义上两者逐项一致
（本节的 `⊖ℤ-normalize` 与 37.5 的 `to-from` 合起来就是这种一致性
的抽象版），但要证 `_⊖ℤ_ ≡ stdlib _⊖_` 得会处理 `<ᵇ` 的判定，成本
不低——这就是「快路」在证明世界里的账单。

闭算测试全部用 stdlib 原名（`import Data.Integer as ℤS`，不 open，
避免与本章 `_+_`/`_*_` 抢名字）：

```agda
int-test₀ : (ℤS.+ 3) ℤS.+ (ℤS.-[1+ 1 ]) ≡ ℤS.+ 1
int-test₀ = refl                          -- 3 + (−2) = 1

int-test₁ : (ℤS.+ 3) ℤS.- (ℤS.+ 5) ≡ ℤS.-[1+ 1 ]
int-test₁ = refl                          -- 3 − 5 = −2

int-test₂ : (ℤS.-[1+ 1 ]) ℤS.* (ℤS.-[1+ 2 ]) ≡ ℤS.+ 6
int-test₂ = refl                          -- (−2)×(−3) = 6

int-test₃ : 3 ℤS.⊖ 5 ≡ ℤS.-[1+ 1 ]
int-test₃ = refl                          -- 与本章 ⊖ℤ 同答案

-- 同构：两条 round-trip 全部 refl 过关
fin→int→fin : (x : ℤfin) → int→fin (fin→int x) ≡ x
fin→int→fin (+ n)     = refl
fin→int→fin -[1+ n ]  = refl
```

顺带两条实测事实供查阅：本 stdlib 树里**没有** `Data.Integer.Simple`
（2.x 时代的纯 Agda 版本已移除），想要 37.7 那种结构递归定义只能像
示例这样自己写；stdlib 的 `suc`/`pred` 在 `ℤ` 上定义为 `1ℤ + i` 与
`-1ℤ + i`（Base.agda:245/250），和本章 `sucℤ`/`predℤ` 的显式三分支
是同一种函数的两种写法。

## 37.10 坑位清单（本项目实测）

1. **pattern 同义词右边掺蓝函数**：`pattern badBlue n = suc (double
   n)` → `NoParseForLHS / Could not parse the pattern synonym right-hand
   side`（37.6）。同义词只许红（构造子/同义词）+ 黑（变量）。
2. **左边变量没全用上**：`pattern badUnused m n = suc m` →
   `UnusedVariableInPatternSynonym`；反之右边冒出左边没绑的变量 →
   `UnboundVariablesInPatternSynonym`（`badPair p = (p , q)`）。
3. **左边的参数位置写构造子**：`pattern badLHS zero = suc zero` →
   `PatternSynonymArgumentShadows.Constructor`，报错还会把被遮蔽的
   `Agda/Builtin/Nat.agda:9.3-7` 指给你看。
4. **同义词实参漏括号**：`- (ℤ⊖0 suc n)` →
   `BadArgumentsToPatternSynonym`（37.6）。`suc n` 被读成两枚实参，
   必须写 `(suc n)`。
5. **同义词名出了作用域 = 静默降级为新变量**：`h one′ = zero` 只给
   一条 `UnreachableClauses` 警告、`exit 0`，随后 `wrong = refl`
   照样通过——本章最阴的坑。跨模块请用限定名 `Hidden.one′`（37.6）。
6. **一个名字只许一条定义**：`pattern _⊖_` 与函数 `_⊖_ : ℕ → ℕ → ℕ`
   并存 → `ClashingDefinition / Multiple definitions of _⊖_`。平铺
   module 里还得把 `Data.Nat` 的 `_+_`/`_*_` 改名导入，前缀取反写
   `-_`（stdlib 拼法）而不是 `_-_`（37.7）。
7. **模块名/文件名里不能有被下划线分开的关键字或数字片段**：
   `module TmpProbe37_2 where` → `in the name TmpProbe37_2, the part 2
   is not valid because it is a literal`。本章文件名因此是
   `Ex37-patsyn.agda`（连字符），不是 `Ex37_pattern`——`pattern` 是关
   键字（04/22 章同款，README 亦有说明）。
8. **`Data.Nat.Properties` 没有 `suc-plus`**：`using (suc-plus)` 只是
   warning（`ModuleDoesntExport`），真正炸的是使用点。stdlib 有的是
   `+-suc : m + suc n ≡ suc (m + n)`；`suc` 在左的版本自己证（37.8）。
9. **`begin … ∎` 忘了 `module ≡-Reasoning`**：`Not in scope: begin`，
   提示里那串 `…≡-Reasoning.begin_?` 就是答案（37.8）。
10. **想合并 `norm-IsCanon` 的分支**：`norm-IsCanon (zero ⊖ n) =
    negForm n` → `The terms suc n and n are not equal at type ℕ`。
    带索引的构造子返回类型是**精确**的，`posForm zero` 那一支不可
    能被 `negForm` 顶替（37.5）。
11. **dot pattern 给少了 / 索引过度约束**：`suc-mono-mono {x} (lte
    .x b) = lte (suc x) b : x ≤ₗ x → suc x ≤ₗ suc x` 里两条方程
    `a ≟ x, a + b ≟ x` 联立成 `a ≟ a + b` → 变量出现在自己的解里，
    `SplitError.UnificationStuck`「I'm not sure if there should be a
    case」（37.5）。Agda 不做 `+ zero` 化简，也不会替你猜 `b :=
    zero`：解出来的等式要么 dot 出来，要么别把引理单态化。
12. **`refl` 证不动约分次序**：`n ∸ n ≡ zero` 卡住（37.1）、
    `two-paths` 里 `normalize` 与 `+ℕ` 都动不了（37.8）。凡是「变量
    挡在递归参数前面」的方程，只能归纳或 rewrite，`refl` 只覆盖闭
    项。
13. **`normalize₁` 不幂等不是 bug 是设计缺陷**：`suc`/`pred` 压在同
    一条构造链上，任何匹配顺序都约不到不动点（37.2 的
    `norm₁-not-fixpoint` 用 `refl` 反证）。分账（`ℤdiff`）或唯一表
    示（`ℤfin`）才是治本。
14. **未约分的记账彼此不相等**：`1 ⊖ 1 ≢ 0 ⊖ 0`（`cong posOf` 一秒
    证死）。差分整数的「同一个整数」是**约分后**的相等，写测试时先
    `normalize`，否则断言会莫名其妙地失败（37.3）。
15. **直接跑 `agda` 不设 locale 会看不到报错**：编码崩溃
    `Error when handling error: <stdout>: commitAndReleaseBuffer:
    invalid argument (cannot encode character '\8760')`（`\8760` 就是
    `≠`，报错文案里那个 U+2260 打不出去，真报错被吞了）——
    `build.sh` 第 13–15 行已经替你补上 `LC_ALL=en_US.UTF-8`，手工调
    `agda` 复现报错时别忘了（35 章迁移清单同款）。

---
上一章：[36 · 计算模型](36-computation-model.md) ｜ 下一章：[38 · instance 参数与模算术](38-instance-modular.md) ｜ 返回：[README](../README.md)
