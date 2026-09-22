# 06 · 数据类型与模式匹配

上一章给「类型住在哪层」搭好了舞台，这一章开演主角戏：**数据怎么声明、
函数怎么分派**。Agda 的 `data` 一行顶三件事——定义类型、给出构造子、
顺便生成一条归纳原理；而模式匹配远不止 `case` 的语法糖：通配符、荒谬模式
`()`、点模式 `.pat`、`with` 抽象，每一条都同时是**逻辑推理规则**——
「这个分支不可能发生」在 Agda 里的意思，是检查器亲手验证了那个类型为空。
本章把模式的整个家族一次点齐，并用 Bool/ℕ 混合索引的小例子演示「分支消失」
的真实手感；索引类型的大餐（Fin）留给 10 章，Vec 的长度魔术留给 16 章。

对应示例：`../examples/Ex06_patterns.agda`

Curry–Howard 视角先立好：`data` = 命题的归纳定义；构造子 = 引入规则；
模式匹配 = 消除规则。下文每个「翻车现场」的报错原文都是本机实测。

## 6.1 data 声明解剖：参数 vs 索引

一个 `data` 声明的骨架：

```agda
data Ordering : Set where
  lt eq gt : Ordering
```

关键字 `data`、类型名、冒号、**该类型住的宇宙**（05 章的全部意义在此兑现：
构造子字段要是「太大」，这层就装不下）、`where`、构造子列表。

**参数（parameter）与索引（index）的第一炮。**同一行里两种「函数箭头」地位
完全不同：

```agda
data Option (A : Set) : Set where        -- A 是参数
  some : A → Option A
  none : Option A

data Mixed : ℕ → Bool → Set where        -- n 和 b 是索引
  here  : Mixed zero true
  there : ∀ {n : ℕ} → Mixed (suc n) false
```

判别口诀：**在所有构造子的返回类型里位置固定的，是参数；会变形的，是索引。**
`Option` 的 `A` 无论 `some` 还是 `none` 都原样出现——参数；`Mixed` 的
第一个索引在 `here` 里是 `zero`、在 `there` 里是 `suc n`——索引。

两者的本质差别在「信息量」。`Option A` 是**一族**类型拼成的和：
`some 3` 与 `none` 是同一类型的兄弟，拆开后才知道谁是谁。而 `Mixed` 是
**类型家族**：`here` 和 `there {2}` 分别住在 `Mixed zero true` 和
`Mixed 3 false` 里——索引把「值的知识」焊进了类型，于是：

- 拿错组合的类型**根本构造不出来**（不存在 `Mixed zero false` 的值）；
- 模式匹配时，不相容的分支可以整条删掉（6.3 荒谬模式）；
- 构造子的隐式参数（`there {n}` 的 `n`）携带索引证据，匹配时可反推。

索引会变的字段自动成为构造子的**隐式参数**：`there` 的 `n` 不用手动传，
这也是 05 章 `{A = …}` 那套约定的主场。

## 6.2 模式家族：构造子、通配符、变量、嵌套

```agda
flipO : Ordering → Ordering
flipO lt = gt          -- 具体构造子模式
flipO eq = eq
flipO gt = lt

fromSome : Option ℕ → ℕ
fromSome (some n) = n  -- 构造子模式：拆模式带出字段绑定
fromSome none     = 0

const₀ : ℕ → Ordering → ℕ
const₀ x _ = x         -- 通配符 _：匹配一切但不绑定

idPat : ℕ → ℕ
idPat n = n            -- 变量模式：绑定整个参数
```

注意两个 `_` 是**互相独立**的两张空白牌，不是「同一个通配」；同一位置
想复用值就得给它起名。变量模式还有微妙的第二身份，见 6.4 的非线性报错。

嵌套模式可以一路套到底：

```agda
second : ℕ → Bool
second zero          = false
second (suc zero)    = false
second (suc (suc n)) = true

_ : second 5 ≡ true
_ = refl
```

三条分支两两不重叠、共同穷尽——但 Agda **不要求**你做到这一点，
重叠与缺口各有章法（6.5、6.3）。

## 6.3 荒谬模式 ()：分支消失的两种姿势

`()` 读作「这里不可能有值」。检查器放行它的唯一标准：**该位置的类型是空的，
而且空得可以机械判定**。两个层级：

**姿势一：空类型本身。**`⊥`（`Data.Empty`）没有构造子，`⊥ → 任何命题`
即爆炸原理：

```agda
from⊥ : ⊥ → ℕ
from⊥ ()
```

**姿势二：索引不相容，实例为零。**`Mixed zero false` 明明写在宇宙里，
但没有任何构造子造得出它——对这种「局部空」，() 照样管用。
把 `Mixed` 的四种索引组合全列出来，只有两种有居民：

```agda
probe : (n : ℕ) (b : Bool) → Mixed n b → Bool
probe zero    true  here  = true
probe zero    false ()    -- Mixed zero false 是空的
probe (suc n) true  ()    -- Mixed (suc n) true 也是空的
probe (suc n) false there = false
```

四条分支**不多不少**被检查器认可——它按索引把候选构造子筛了一遍。
再举一个单索引的最小样本，这就是本章的「Bool 版 IsTrue」（stdlib 对应物是
`Data.Bool.Base` 里的 `T : Bool → Set`，`T true = ⊤`、`T false = ⊥`）：

```agda
data IsTrue : Bool → Set where
  it : IsTrue true

needTrue : (b : Bool) → IsTrue b → ℕ
needTrue true  it = 1
needTrue false ()          -- IsTrue false 无构造子：分支不存在
```

如果非要给不可能的组合写**正常模式**，Agda 的报错直接教你改用 ()（实测原文）：

```text
needTrue false it = 1
--> error: [ImpossibleConstructor.UnifyConflict]
    The case for the constructor it is impossible
    because unification ended with a conflicting equation
      true ≟ false
    Possible solution: remove the clause, or use an absurd pattern ().
```

一个必须提前立好的规矩：「空」要**检查器算得动**。构造子头冲突（true 对
false）、`suc n` 对 `zero`，它秒判；而依赖「`n + m ≡ 0` 则 `n ≡ 0`」这类
算术事实的空，得靠引理或更强的索引设计——10 章的 `Fin` 会给你一次
「荒谬模式当证明用」的完整实战，那里才是这招的主场。

## 6.4 点模式 .pat：被等式实例化的变量

点模式的语义一句话：**「这一位的值已被本条目其他模式钉死，我替你把它写出来」**。
它是断言（assertion），不是约束（constraint）——差别见下面三个现场。

**现场一：两个独立输入写同一个变量（非线性模式）报错。**

```text
j : ℕ → ℕ → ℕ
j n n = n
--> error: [UnequalTerms]
    n != n₁ of type ℕ
    when checking that all occurrences of pattern variable n have the
    same value
```

天真地以为打个点就能修——错：

```text
j n .n = n
--> error: [UnequalTerms]
    n != x of type ℕ
    when checking that the given dot pattern n matches the inferred value x
```

第二位**没有任何东西钉住它**，`.n` 断言了一个不成立的「已知」。
想让函数「只在两参数相等时有行为」，模式匹配无能为力，那是判定函数
（6.6 的 `_≟ℕ_`、15 章的 `Dec`）的活。

**现场二：构造子把两个索引焊死时，点模式如虎添翼。**

```agda
data Pair2 : Bool → Bool → Set where
  pr : (b : Bool) → Pair2 b b

e : (x y : Bool) → Pair2 x y → Bool
e .b .b (pr b) = b     -- pr b 同时钉住 x 和 y，两处点都是「推论」

_ : e true true (pr true) ≡ true
_ = refl
```

`x`、`y` 本来自由，但第三个参数的模式 `pr b` 把类型 `Pair2 x y` 与
`Pair2 b b` 统一，等式约束实例化（unification）顺手解出 `x := b`、`y := b`——
点位上写 `.b` 正是复述这份推导。实测同一条目写 `e b b (pr b)` 也能过：
后两个 `b` 被 Agda **自动补点**（forced 变量自动 dot 化），显式点只是写给人看的。

**现场三：显式字段决定索引时复用绑定。**

```agda
data Box : ℕ → Set where
  bx : (n : ℕ) → Box n

copy : (n : ℕ) → Box n → ℕ
copy n (bx .n) = n     -- 第二位是被第一位钉死的「推论」

box3 : Box 3
box3 = bx 3

_ : copy 3 box3 ≡ 3
_ = refl
```

规律浮出水面：**点模式出现的地方，就是「逻辑推导发生过」的地方**。
这也是它和通配符 `_` 的分野——`_` 是「我不关心」，`.pat` 是「我关心，
而且我已经知道了」。

## 6.5 重叠分支：按书写顺序，先匹配先赢

Agda 的分支列表是**有序模式序列**，第一条能匹配的执行，后面的同类输入
静默失效——顺序就是语义：

```agda
firstWins : ℕ → Bool
firstWins (suc n) = false
firstWins zero    = true

specificFirst : ℕ → Bool
specificFirst 1       = true
specificFirst (suc n) = false
specificFirst zero    = true

_ : firstWins 1 ≡ false
_ = refl
_ : specificFirst 1 ≡ true
_ = refl
```

同一个输入 `1`，两种顺序两个答案（refl 亲证）。和 Haskell 不同，
Agda **不会**帮你发现漏网的输入——不穷尽只是「另一个函数」，
但不合理的重叠确实有检测：**完全被前面分支吞掉的条目会报警告**
`-W[no]UnreachableClauses`（实测，注意它只是 warning，退出码仍 0）：

```text
g (suc n) = false
g 1 = true
g zero = true
--> warning: -W[no]UnreachableClauses
    Unreachable clause
    when checking the definition of g
```

「没报错 ≠ 没白写」——CI 里 warning 攒多了，第一条被静默的 bug 就藏不住了。
兜底分支的正规写法是通配符压轴（`catchAll` 见示例），或者干脆学 6.3
用 () 显式声明「剩下的不可能」。

## 6.6 with 抽象：对中间计算结果再分情况

递归算出来的值还要拿来做 case，写在哪？模式只能拆「参数」，拆不了
「计算结果」——这就是 `with` 的存在理由。自然数相等判定：

```agda
infix 4 _≟ℕ_
_≟ℕ_ : (m n : ℕ) → Bool
zero   ≟ℕ zero    = true
zero   ≟ℕ suc n   = false
suc m  ≟ℕ zero    = false
suc m  ≟ℕ suc n   with m ≟ℕ n
... | true  = true
... | false = false

_ : (2 ≟ℕ 2) ≡ true
_ = refl
_ : (2 ≟ℕ 5) ≡ false
_ = refl
```

读法：`with e` 把表达式 `e` 抽成隐形的额外参数；`...` 沿用上一行等号左
整串模式；`| p` 给抽出来的值匹配。可以一次抽多个，用 `|` 串起来：

```agda
_andB_ : (x y : Bool) → Bool
x andB y with x | y
... | true  | b = b
... | false | _ = false
```

with 的**杀手锏是精化（refinement）**：抽象值反过来钉住原参数——
6.4 的等式实例化在这里自动发生：

```agda
witness : (b : Bool) → IsTrue b → ℕ
witness b t with t
witness .true it | it = 1
```

`it : IsTrue true` 与 `t : IsTrue b` 统一出 `b := true`，于是原参数 `b`
的点位改写成 `.true`（实测：写 `witness b it | it` 也收——forced 变量
被自动打点，见 6.4 现场二）。15 章的 `Dec`、16 章 Vec 的越界防御，
全都建在这台「with + 精化」的引擎上。

顺带一个实测小坑：`_≟ℕ_` 和 `_≡_` 若同为 `infix 4`，写
`_ : 2 ≟ℕ 2 ≡ true` 会 `[NoParseForApplication]`——两个同级非结合中缀
夹在一条线上，解析器直接罢工。老实加括号：`(2 ≟ℕ 2) ≡ true`。

## 6.7 字面量模式：数字是 suc 链的糖

03 章讲过字面量的实例机制，但**模式里的数字走的是另一条路：直接展开成
构造子链**——所以它们照样参与 6.5 的顺序匹配：

```agda
f : ℕ → ℕ
f 0       = 1
f 2       = 3         -- 即 suc (suc zero)
f (suc n) = n

_ : f 0 ≡ 1
_ = refl
_ : f 2 ≡ 3
_ = refl
_ : f 5 ≡ 4
_ = refl
```

完全展开的等价写法（各分支顺序照抄，语义分毫不差）：

```agda
f′ : ℕ → ℕ
f′ zero              = 1
f′ (suc (suc zero))  = 3
f′ (suc n)           = n

_ : f 5 ≡ f′ 5
_ = refl
```

数字模式**不属于** `FromNat` 实例机制——它只认 ℕ 的构造子。给自定义类型
注册过字面量实例（03 章的 `Parity`），模式里照样不能写数字（实测原文，
`ℕ.suc` 泄露天机）：

```text
h : Parity → ℕ
h 7 = 0
--> error: [ConstructorPatternInWrongDatatype]
    ℕ.suc is not a constructor of the datatype Parity
    when checking that the pattern 7 has type Parity
```

于是「字面量 → suc 展开」这条规则同时解释了：为什么 `f 2` 能夹在
`zero` 和 `suc n` 之间改变匹配顺序（它就是 `suc (suc zero)`），
以及为什么换个类型数字就不灵。

## 6.8 组合拳：混合索引的「符号检查」

把参数/索引、荒谬、点模式、顺序全用上——`signMixed` 给 `Mixed` 四种
索引组合逐一发号，空组合零成本处理：

```agda
signMixed : (n : ℕ) (b : Bool) → Mixed n b → ℕ
signMixed zero    true  here          = 0
signMixed (suc n) false (there {n})   = 1
signMixed zero    false ()
signMixed (suc n) true  ()

_ : signMixed 0 true here ≡ 0
_ = refl
```

`(there {n})` 显式命名了隐式参数 `n`，让它和 `(suc n)` 里的 `n` 挂钩——
这是索引证据在模式层的日常用法。索引即文档、即测试用例、即证明：
以后每定义一个 `data`，都值得一问「我这几个参数里，有资格当索引的是谁」。

## 6.9 本章坑位清单（实测）

1. **参数位置丢信息**：该做索引的东西写成参数（`Mixed : Bool → Set` 式
   扁平化），6.3 的「分支消失」红利就全没了——建模时先问「哪个组合根本
   不该存在」；
2. **索引变化的字段是构造子隐式参数**：`there {n}`，模式里要复用它就
   显式命名 `{n}`，硬写 `there n` 会撞上
   `WrongNumberOfConstructorArguments`（构造子元数按「含隐式参数」计）；
3. **荒谬模式不是玄学**：空必须**可判定**——构造子冲突秒过，
   依赖算术引理的空它不认（报错就是 ImpossibleConstructor 系列）；
   不可能分支写成普通模式会被 `UnifyConflict` 当场抓住并教你改 ()；
4. **点模式是断言不是约束**：独立两参数写 `j n n` 报错，改 `j n .n`
   照样报错（"the given dot pattern n matches the inferred value"）——
   没有等式来源就没有点可打；
5. **forced 变量自动打点**：`e b b (pr b)` 实测能过——别以为 Agda 忘了
   6.4 的规则，显式 `.b` 只是文档价值；
6. **重叠只警告不报错**：被完全覆盖的分支是 `UnreachableClauses` warning，
   文件退出码仍 0——`specificFirst` 挪顺序改变行为全靠自觉复查；
7. **字面量模式 = suc 展开，与实例无关**：`Parity` 上 `h 7` 直接被
   `ConstructorPatternInWrongDatatype` 拒绝；
8. **with 行的 fixity 要错开**：`_≟ℕ_` 与 `_≡_` 同级不结合 →
   `NoParseForApplication`，判定结果进等式请一律加括号。

---
上一章：[05 · 类型系统与宇宙](05-universes.md) ｜ 下一章：[07 · 递归与终止检查](07-recursion.md) ｜ 返回：[README](../README.md)
