# 04 · 记号与运算符

Agda 源码和核心演算之间没有「语法糖展开器」这一层：`x + y * 1 ≡ y * 1 + x`
是命题，`Σ[ x ∈ A ] B` 是类型，`1 ∷ 2 ∷ []` 是数据——所有这些「表面记号」由
三个正交的机制撑起：**mixfix 名字**（名字里带洞 `_`）、**fixity 声明**
（`infixl`/`infixr`/`infix` + 优先级数字）、**syntax 声明**（给已有简单名字换
皮）。机制少，但每一样都有值得抠到底的细节。本章把「这个式子到底怎么解析」
彻底讲清：优先级冲突时 Agda 会把整张优先级表打进报错里，学会读表，就不用猜。

对应示例：`../examples/Ex04-syntax.agda`

先回答看到文件名就会冒出的问题：为什么示例叫 `Ex04-syntax`（连字符）而不是
`Ex04_syntax`？因为 `syntax` 是关键字，**被下划线分隔的关键字片段连词法检查都
过不了**（4.1 有报错原文）。stdlib 遇到同样问题用同样解法：`Σ-syntax`、
`∃-syntax`、`∋-syntax` 全用连字符；文件名先例见 `Data/Vec/N-ary.agda`、
`Codata/Musical/Colist/Infinite-merge.agda`（本机 stdlib 实测存在）。

## 4.1 运算符就是带洞（_）的普通名字

Agda 的标识符本身就是模板：名字里的 `_` 标记参数洞，洞的个数和位置决定它
是什么形状的记法。示例的前两个定义：

```agda
infixl 6 _⊞_
infixr 7 _⊠_

_⊞_ : ℕ → ℕ → ℕ
x ⊞ y = suc (x + y)

_⊠_ : ℕ → ℕ → ℕ
x ⊠ y = x * suc y
```

`_⊞_` 两边各一洞，是中缀；把洞挪到一端就是前缀/后缀——**Agda 没有
`prefix`/`postfix` 关键字**，它们都只是单洞 mixfix 名。示例自造的 `#_`
（洞在右，「xs 的元素个数」`# (1 ∷ 2 ∷ 3 ∷ []) ≡ 3`）与 stdlib 推理框架收尾的
`_∎`（洞在左，`Relation/Binary/Reasoning/Syntax.agda` 441-444 行原文）：

```agda
  infix 3 _∎

  _∎ : ∀ x → R x x
  x ∎ = reflexive
```

名字在任何位置都是名字：传递、部分应用与记法写法完全同价（示例原文
`_ : (_⊞_ 2) 3 ≡ 2 ⊞ 3; _ = refl`）。洞可以多个、token 可以多段：示例有双洞的
`_[_]`（`infix 9`）和三洞四词元的 `if_then_else_`；stdlib 里
`Data/List/Base.agda:479` 一行声明了两种三洞记法
`infixl 5 _[_]%=_ _[_]∷=_`。

`data` 的名字也能 mixfix——**`_≡_` 这个「看起来像语言核心」的记号，就是一个
普通归纳族的名字配了条 infix 声明**（Agda prim 库
`Agda/Builtin/Equality.agda:5-6` 原文）：

```agda
infix 4 _≡_
data _≡_ {a} {A : Set a} (x : A) : A → Set a where
  refl : x ≡ x
```

示例照抄配方造了个「小号等式」：`infix 4 _≡ₐ_` 加
`data _≡ₐ_ {A : Set} (x : A) : A → Set where reflₐ : x ≡ₐ x`，用法
`_ : 2 + 3 ≡ₐ 5; _ = reflₐ`——语法层面与 `_≡_` 毫无差别。词法上给名字起洞有
三条红线（都实测）：

1. **`_` 分隔的片段不能是关键字**。`module Ex04_syntax where` 连 parse 都过不
   去（坐标只有一个点 `1.20`——词法错误，还没进语法层）：

   ```text
   /home/xulun/code/programming/agda/examples/Ex04_syntax.agda:1.20: error: [ParseError]
   in the name Ex04_syntax, the part syntax is not valid because it is a keyword
   ```

   `lambda`、`let`、`where` 同理。stdlib 在 `Function/Reasoning.agda:13` 留了
   句原文注释，是这条约束的官方吐槽：
   `-- Need to give _∋_ a new name as syntax cannot contain underscores`
2. **连字符是字母类字符、不切分片段，下划线才切分**——躲开关键字片段的标准
   姿势就是把分隔的 `_` 换成 `-`（`∃-syntax`、`sum⁺-syntax` 都是单片段名）。
   判定区分大小写：模块路径里的 `Data` 与关键字 `data` 井水不犯河水。
3. **`?` 是合法符号字符**：判定性比较的标准名 `_≤?_`（`Data/Nat.agda:29`
   导出）就是纯符号洞名；示例的 `_?!_` 同理。

## 4.2 fixity 声明：infixl / infixr / infix 与优先级数字

中缀名字需要一条 fixity 声明教解析器拼树：`infixl 6 _⊞_`（左结合，级别 6）、
`infixr 7 _⊠_`（右结合）、`infix 6 _⊘_`（**不可结合**）。Agda 只有这三个
关键字，**没有 Haskell 的 `nonassoc`——`infix` 本身就是不可结合**。写
`nonassoc` 不会被当关键字纠正，而是被当成普通标识符解析成函数声明（实测）：

```text
/home/xulun/code/programming/agda/examples/TmpE7.agda:3.1-15: error: [MissingTypeSignature.Function]
Missing type signature for left hand side nonassoc 6 _⊘_
when scope checking the declaration
  nonassoc 6 _⊘_
```

### 4.2.1 优先级规则与解析树示波器

- 数字越大绑得越紧；任意自然数可用，0 最松（stdlib 给 `if_then_else_` 配
  `infix 0`，`Data/Bool/Base.agda:71`），没有 Haskell 的 9 上限；
- **没声明 fixity 的运算符默认 level 20、不可结合**——与 Haskell（默认
  infixl 9）两头都不同。忘声明的中缀名连用两次直接拒判（实测）：

  ```text
  /home/xulun/code/programming/agda/examples/TmpE4.agda:9.9-18: error: [NoParseForApplication]
  Could not parse the application 1 ⊕ 2 ⊕ 3
  Operators used in the grammar:
    ⊕ (infix operator, level 20) [_⊕_ (/home/xulun/code/programming/agda/examples/TmpE4.agda:6.3-6)]
  when scope checking 1 ⊕ 2 ⊕ 3
  ```

- 尾槽对操作数有级别门槛：`infixl n` 左槽收 ≥ n、右槽只收 ≥ n+1；`infixr`
  反之；`infix` 两槽都 ≥ n+1；够不着门槛的子式必须加括号。中间洞比尾槽宽松
  （token 本身就是界定符）。这条规则能验算本章一切实测：`1 ⊕ 2 * 3`（⊕ 默认
  20、`_*_` 7）中 `2 * 3` 级别 6 进不了 ⊕ 的右尾槽（≥21），解析成
  `(1 ⊕ 2) * 3`；示例的 `1 ⊞ 2 ⊠ 3` 里 ⊠ 级别 7 恰好够 ⊞（infixl 6）右槽的
  门槛，被整体吸进右操作数——所以下面这三条示例里的 refl 等式其实是一台台
  「解析树示波器」：

  ```agda
  _ : 1 ⊞ 2 ⊠ 3 ≡ 1 ⊞ (2 ⊠ 3)   -- 级别 6 < 7：⊠ 先结合
  _ = refl

  _ : 1 ⊞ 2 ⊞ 3 ≡ (1 ⊞ 2) ⊞ 3   -- infixl 6 同级左结合
  _ = refl

  infixr 7 _^_                   -- 定义见示例：x ^ zero = 1 等

  _ : 2 ^ 3 ^ 2 ≡ 2 ^ (3 ^ 2)   -- 幂塔右结合：3^2=9, 2^9=512
  _ = refl
  ```

### 4.2.2 「Operators used in the grammar」表怎么读

上面报错中间那两行就是解析器甩出的优先级表，字段逐个拆：

```text
  ⊕ (infix operator, level 20) [_⊕_ (…/examples/TmpE4.agda:6.3-6)]
  ↑符号   ↑结合性      ↑级别    ↑名字   ↑fixity 声明所在位置
```

最后一项**指向声明行**（infix 声明或 postulate/import），不是使用处——跨模块
导入多个同名运算符时，它直接告诉你「此刻这个 `_⊕_` 的记法是谁家的」。表出现
两行就是两个运算符打架：实测 `_⊗_`（infixl 7）接 `_⊙_`（infixr 7）写
`1 ⊗ 2 ⊙ 3`，同样报 `NoParseForApplication`，表里两个运算符各占一行——
**同级别不同结合性 = 谁也吞不下谁**。这就是 stdlib 给每个常用记号**钉死专属
级别**的原因：`_≡_`/`_≤ᵇ_` 4、`_++_` 5、`_+_` 6、`_*_` 7（声明行分别为
`Agda/Builtin/Equality.agda:5`、`Data/Nat/Base.agda:46`、
`Data/List/Base.agda:52`、`Agda/Builtin/Nat.agda:15-16`）。新造中缀记号前，先在
这张级别地图上占坑，别人才撞不掉你的。

顺带两条规矩：不可结合 ≠ 不能用两次——`_ : 1 ⊘ 2 ≡ 1 ⊘ 2` 合法（示例原文，
`≡` 级别 4，两侧各自成树，不存在「连着三个 ⊘」的链）；**fixity 声明顺序
模块级自由**——示例把 `infix 10 #_` 写在定义之后照编照过，实测在文件末尾
声明、前面的使用一样生效（惯例仍是紧贴签名写）。

## 4.3 词法记号：if_then_else_ 的级别课

把关键字当 token 拼进 mixfix 名字，是 Agda 独有的「自造控制结构」姿势——
`if_then_else_` 在 stdlib 里就不是内建语法，而是 `Data/Bool/Base.agda:71` 的
一行 `infix 0 if_then_else_` 加一条普通定义。示例原样复刻：

```agda
infix 0 if_then_else_

if_then_else_ : {A : Set} → Bool → A → A → A
if true  then x else y = x
if false then x else y = y

_ : (if true then 2 ⊞ 4 else 9) ≡ 7
_ = refl
```

外面那对括号不是摆设：级别 0 意味着 else 尾槽「级别 ≥ 1 什么都收」，会一路
向右吞。实测去掉括号写 `a = if true then 2 else 3 ≡ 2`，报错把吞出来的结构
原样招了：

```text
/home/xulun/code/programming/agda/examples/TmpE14.agda:8.25-30: error: [UnequalTerms]
Set !=< ℕ
when checking that the expression 3 ≡ 2 has type ℕ
```

`3 ≡ 2 : Set` 被塞进要 `ℕ` 的 else 槽。**「类型层报错、病根在解析」的案子，
先按级别脑补一遍括号**，比盯着类型看有用。对照高洞记号：示例的
`f [ x ] = f x`（`infix 9`）里 `suc [ 2 + 3 ] ≡ 6` 过关——6 级的 `_+_` 进 9 级
`_[_]` 的中洞毫无障碍：中洞宽松、尾槽严苛，一眼可辨。

## 4.4 syntax 声明：给已有名字换皮

mixfix 名字管「洞在哪」，`syntax` 声明管「纯重排/换词」：不改函数，只改书写。
形状是 `syntax <简单名字> <参数序列> = <token 布局>`。左边只收**无洞的简单名**，
带洞直接拒（对 `syntax _⊞_ x y = x plus y` 与 `syntax if_then_else_ …` 的实测
同款报错）：

```text
error: [ParseError]
Syntax declarations are allowed only for simple names (without holes)
```

所以带洞的 `if_then_else_` 想换皮，得先包一层无洞别名——示例与 stdlib 的
`∋-syntax = _∋_` 都是这一招。示例的三发实操，一类用法一发：

```agda
-- (1) 换顺序/换词（stdlib Function/Reasoning.agda 同款做出 a ∶ A）
∋-syntax : (A : Set) (a : A) → A
∋-syntax _ a = a

infix 4 ∋-syntax
syntax ∋-syntax A a = a ∋ A

_ : (5 ∋ ℕ) ≡ 5
_ = refl

-- (2) 备用拼法：if_then_else_ 简写成 b ◃ x ▹ y
ite-syntax : {A : Set} → (b : Bool) (x y : A) → A
ite-syntax = if_then_else_

syntax ite-syntax b x y = b ◃ x ▹ y

_ : (true ◃ 2 ▹ 9) ⊞ 4 ≡ 7
_ = refl

-- (3) 捕获 binder：右侧参数写 (λ x → B)，用户输入的整段 λ 被绑定
∃-syntax : {A : Set} → (A → Set) → Set
∃-syntax {A} B = Σ A B

syntax ∃-syntax (λ x → B) = ∃[ x ] B
```

第 (3) 类是整个 stdlib 数学 DSL 的地基（以下三行全部实测 grep 自 stdlib 原文）：

```agda
syntax Σ-syntax A (λ x → B) = Σ[ x ∈ A ] B         -- Data/Product/Base.agda:55
syntax sum-syntax n (λ i → x) = ∑[ i < n ] x       -- Algebra/Properties/Monoid/Sum.agda:51
syntax Thunk-syntax (λ j → e) i = Thunk[ j < i ] e -- Codata/Sized/Thunk.agda:37
```

binder 捕获的实战价值，示例那段「2 是偶数」的证明足够说明：
`twoEven : ∃[ n ] Even n; twoEven = 2 , e+2 e0` 里 `n` 同时出现在类型和值里，
就靠上面那行 syntax（右侧的 `_,_` 也是记号——从 `Data.Product.Base` 进口的
对构造子，洞夹逗号又一例）。syntax 还能做**无洞包裹式**记号：
`Data/Rational/Base.agda:284` 用 `syntax floor p = ⌊ p ⌋` 把普通函数装进数学
括号（`⌈ ⌉`、`[ ]` 同款三条）。

两条使用须知的实测版：

- 记号的优先级取**左边简单名字**的 fixity：stdlib 给 `Σ-syntax`/`∃-syntax` 配
  `infix 2`、`∋-syntax` 配 `infixl 0`（均实测 grep 到声明行），换皮记号跟着
  走。示例的 `ite-syntax` 没声明（默认 20），`◃ ▹` 就表现得像最紧的记号：
  实测 `true ◃ 2 ▹ 9 ⊞ 4` 不加括号也能 parse，且正是 `(true ◃ 2 ▹ 9) ⊞ 4`
  （6 级的 ⊞ 进不了 20 级的 y 尾槽）。
- `do` 记号**不是**用户级 syntax 声明：stdlib 2.3 的 `Effect/`、`IO/` 里 grep
  不到任何 do 相关 syntax（实测），块布局与 `_>>=_` 尾拼是解析器内建规则——
  19 章学单子不需要先学本章。

## 4.5 Unicode、Emacs 输入与命名惯例

Agda 源码是 UTF-8，标识符直接吃 Unicode（03 章已见过 `ℕ`、`x′`、`n₀`、
`类型别名`）。日常输入靠 Emacs 的 `agda-input` 输入法：`C-c C-\` 开启后 `\`
起头打拉丁提示串选字。**提示串以本机 `agda-input.el`（elpa agda2-mode-2.8.0）
为准**，下表全部 grep 自该文件：

| 键入 | 出字 | 说明 |
|---|---|---|
| `\->` 或 `\r-` | → | 函数箭头；`\r=`/`\=>` 出 ⇒ |
| `\bN` `\bZ` `\bQ` `\bR` | ℕ ℤ ℚ ℝ | 黑板体统一 `\b` 前缀 |
| `\Gl` | λ | **不是 `\lambda`**；`\GL` 是 Λ |
| `\GS` `\ex` `\all` `\0` | Σ ∃ ∀ ∅ | Gamma-Sigma 出 Σ |
| `\==` | ≡ | `\==n` ≢、`\===` ≣ |
| `\::` `\<=` `\x` `\u+` | ∷ ≤ × ⊎ | cons、比较、积、不相并 |
| `\inf` | ∞ | **`\oo` 是 ⊚**（agda-input.el:343），老教程的 `\oo → ∞` 在本机不对 |

打 `\r` 这类「一族字符」的键会进候选态：`→⇒⇛⭆⇉⇄↦…` 列在候选缓冲区，数字键
选择；`∈ ∋` 在 `\member` 队，`⊢ ⊤ ⊥` 在 `\entails` 队。记不准就
`M-x customize-group agda-input` 现场查表。

命名惯例（03 章 3.7 的续篇，stdlib 全库一致）：**同概念三件套**用尾缀区分
返回域——`_≤_`（Prop）、`_≤ᵇ_`（Bool，`Data/Nat/Base.agda:46`）、`_≤?_`
（Dec，`Data/Nat.agda:29`），证明叫 `≤-trans` 式「关系名-属性名」；撇号/上下标
做变体（`_⊔′_`、`_++_` 对 `_ʳ++_`）；类型/构造子大写在先，函数小写；模块名与
目录一一对应，含关键字片段时同样连字符绕（先例见本章开头）。

## 4.6 作用域：open importing 的过滤器与四种冲突

`import M` 把名字放进限定作用域，`open` 才倒进当前作用域；过滤器有
`using`（只要这些）、`hiding`（除了这些）、`renaming`（改名进口），组内用 `;`
分隔。实测通过的组合：

```agda
open import Data.List using (List) renaming ([] to emptyL; _∷_ to _◃_)
```

但 `using` 与 `hiding` **语义互斥**：同写不报错、只警告，`hiding` 整个被无视
（实测）：

```text
warning: -W[no]UselessHiding
Ignoring names in `hiding' directive: _+_
```

名字在作用域里撞车，报错分四档，各配实测原文：

**(1) 同一行自撞**：`using (x)` 与 `renaming (x to y)` 对同一个名登记两次：

```text
/home/xulun/code/programming/agda/examples/TmpE8.agda:3.40-60: error: [RepeatedNamesInImportDirective]
Repeated name in import directive: _++_
when scope checking the declaration
  open import Data.List using (List; []; _++_) renaming (_++_ to _⧺_)
```

要改名就 `using ()` 留空、只走 renaming。

**(2) 用了模块没导出的名**：**只是 warning**，导入行照样「成功」：

```text
warning: -W[no]ModuleDoesntExport
The module Data.List.NonEmpty doesn't export the following:
  _++_
```

名不会进作用域，症状延后成 `Not in scope`。stdlib 2.3 里不少老名字挪了家
（README 钦定的头号坑）——**退出码 0 不等于导入全对，回头翻 stderr 的 warning**。

**(3) 两个来源同名**：不撞行、只撞使用，用时才报，且把每个候选的完整定义位置
列出来（实测原文，删去「is in scope as」重复段）：

```text
/home/xulun/code/programming/agda/examples/TmpE12.agda:7.8-12: error: [AmbiguousName]
Ambiguous name _++_. It could refer to any one of
  Data.List._++_ bound at
    /usr/share/agda-stdlib/src/Data/List/Base.agda:54.1-5
  Data.Vec.Base._++_ bound at
    /usr/share/agda-stdlib/src/Data/Vec/Base.agda:108.1-5
```

修复就是对其中一条来源动 `hiding`/`renaming`，或退回限定名。**同名且同源不算
撞**：`Data.List` 与 `Data.List.Base` 各导一次 `_++_` 解析为同一实体，实测
退出 0。

**(4) 顺序问题**：`import` 只对**之后**的声明生效（03 章结论，实测原文——
`xs : List ℕ` 写在 `open import Data.List` 之前）：

```text
/home/xulun/code/programming/agda/examples/TmpF3.agda:3.6-10: error: [NotInScope]
Not in scope:
  List
  at /home/xulun/code/programming/agda/examples/TmpF3.agda:3.6-10
when scope checking List
```

2.8 的同类报错常附 `did you mean 'Data.List.List' …` 提示，但它按编辑距离
推荐，不一定猜中你真正想导的模块。

fixity 与 syntax 跟着名字进作用域：实测 `renaming (_++_ to _⧺_)` 之后
`(1 ∷ []) ⧺ (2 ∷ []) ⧺ 3 ∷ []` 直接过关——级别与结合性随原名 `infixr 5` 继承，
不必给 `_⧺_` 重发声明；自己新造的 `_⊞_` 给别的模块用也无需额外动作。
**记号属性跟着定义走**，4.2 的「声明顺序自由」仅限本模块内部，跨模块仍要
「先导后用」。

## 4.7 本章坑位清单（实测）

1. **`_关键字_` 片段词法非法**：`module Ex04_syntax` 报
   `the part syntax is not valid because it is a keyword`（ParseError，模块名
   与文件名同规）——本章示例因此叫 `Ex04-syntax.agda`，stdlib 同款先例
   `∃-syntax`、`N-ary.agda`；
2. **Agda 没有 `nonassoc`**：`infix` 即不可结合；写 `nonassoc 6 _⊘_` 会被当
   普通名字，报 `Missing type signature for left hand side nonassoc 6 _⊘_`；
3. **默认级别 20 且不可结合**（Haskell 是 infixl 9）：忘声明 fixity 的中缀名
   连用两次就 `NoParseForApplication`；报错里的「Operators used in the
   grammar」表先读 fixity/level，再看声明位置坐标（指向定义行，不是使用处）；
4. **同级别不同结合性不能相邻**（infixl 7 撞 infixr 7 实测报错）：新记号先在
   stdlib 级别地图占坑（≡/≤ᵇ 4、++ 5、+ 6、* 7、if_then_else_ 0）；低级别
   子式进高级别尾槽必须加括号，中洞例外宽松；
5. **级别 0 = 贪婪**：`if_then_else_` 的 else 槽吞下 `3 ≡ 2`，症状却是类型层
   `Set !=< ℕ`——先补括号再怀疑类型；
6. **syntax 左边只收无洞简单名**：`syntax if_then_else_ …` 直接拒；给带洞名
   换皮先包无洞别名（stdlib 原文注释：`Need to give _∋_ a new name as syntax
   cannot contain underscores`）；syntax 记号的优先级取左名的 fixity；
7. **using 到不存在的名字只是 warning**（`ModuleDoesntExport`），退出码照 0；
   `using (x) renaming (x to y)` 才是硬错（`RepeatedNamesInImportDirective`）；
   `using`+`hiding` 同写则 hiding 被无视（`UselessHiding`）——正经组合只有
   「using+renaming（不同名）」和裸 hiding；
8. **同名歧义在「用」时爆**（`AmbiguousName` 列全部候选与来源），同名同源不
   歧义——修冲突要用 hiding/renaming，重排 import 行序没用；
9. **Emacs 输入表别背老教程**：本机 `\bN` 出 ℕ、`\Gl` 出 λ、`\inf` 出 ∞，而
   `\oo` 是 ⊚——以 `agda-input.el` / `M-x customize-group agda-input` 为准。

---
上一章：[03 · 第一个文件](03-basics.md) ｜ 下一章：[05 · 类型系统与宇宙](05-universes.md) ｜ 返回：[README](../README.md)
