# 23 · 反射与元编程

前面 22 章里，Agda 一直站在"被检查"的那一侧：你写项，它检查项。本章把
镜头转过来——**让程序在类型检查期运行，读取目标、生成项、甚至生成新的
定义**。这就是反射（reflection）。它解决的现实问题很具体：`x + y ≡ y + x`
这类目标证得起但写不起，几百个 record 字段手搓访问器写不动，报错信息太
晦涩想换成自己的人话。Agda 的答案不是"引入一门策略语言"，而是把类型
检查器本身的一小块 API postulate 出来，做成一个单子 `TC`，让你在**同一个
语言**里写元程序——代价是：这门 API 的稳定性远不如对象语言，本章会给出
实测边界，以及一条"反射太脆就退回去"的稳态工作流。

对应示例：`../examples/Ex23_reflection.agda`

本章所有代码片段与示例文件一致或为其子集；所有报错文本都是在本项目环境
（Agda 2.8.0 + stdlib 2.3）下跑 `agda` 得到的原样输出。

## 23.1 API 分三层，先搞清楚你在哪一层

```text
Agda.Builtin.Reflection   —— 原始层：TC 单子、Term/ErrorPart 数据类型、
                              quoteTC/unify/declareDef… 全是 postulate
Reflection                —— stdlib 再导出层：加上 do 记号所需的
                              _>>=_、纯函数别名 pure、showTerm 等
Reflection.AST / .TCM / .TCM.Syntax / Reflection.Clause …  —— 分模块细节
```

用哪层都行，但**风格要一致**。本章示例走 stdlib 层：

```agda
open import Reflection
open import Agda.Builtin.List using (_∷_; [])
open import Agda.Builtin.Nat using (Nat; _+_; suc)
open import Agda.Builtin.String using (String)
open import Agda.Builtin.Unit using (⊤; tt)
open import Agda.Builtin.Equality using (_≡_; refl)
open Reflection.Clause using (clause)
```

注意 `open Reflection.Clause` 前面**没有** `import`：`Clause` 是已经导入的
`Reflection` 模块的子模块，写成 `open import Reflection.Clause` 在 2.8.0 +
stdlib 2.3 下直接失败：

```text
error: [FileNotFound]
Failed to find source of module Reflection.Clause in any of the
following locations:
  ...
when scope checking the declaration
  open import Reflection.Clause using (clause)
```

stdlib 的 `Reflection` 层也**不**帮你带出 `[]`、`∷`、`⊤`、`tt`、`String`——
这些得从 `Agda.Builtin.*` 自己拿，否则 TC 代码里的 `[]` 会去匹配反射层的
模式列表而产生歧义。

## 23.2 历史断层：2.6.1 以前的教程基本作废

老教程里你会看到这样的代码（2.6.0 及更早的"策略单"API）：

```agda
-- 2.6.1 起已不存在
legacy : Term → TC ⊤
legacy hole = quoteGoal g 1 (unify (quoteTerm refl) hole)
```

在本环境实测：

```text
error: [NotInScope]
Not in scope:
  quoteGoal
  at /home/xulun/code/programming/agda/examples/Zr8.agda:5.15-24
when scope checking quoteGoal
```

`Reflection` 里那个 `Tactic` 记录、`quoteGoal`、`unquote` 的旧式三参数用法
全部没了；取而代之的是今天的 `TC` 单子 + `macro` 声明。所以判断一段反射
代码能不能抄，第一个问题不是"逻辑对不对"，而是"它是哪一版 Agda 写的"。
本章一律以 2.8.0 为准（23.9 给出可用/不可用清单）。

## 23.3 引用世界：项是一种数据

反射的核心是把 Agda 的项表示成一个普通数据类型 `Term`（注意：这里的
`Term` 是 `Set`，可以直接对它做模式匹配）：

```agda
-- 概念形状（构造子名与字段顺序为 2.8.0 实测）
data Term : Set where
  var   : (x : Nat) → Arg (String × Term) → Term      -- 局部变量（De Bruijn 索引）
  def   : (d : Name) → Args Term → Term               -- 调用一个定义/构造子
  con   : (c : Name) → Args Term → Term               -- 构造子应用
  prop  : (t : Term) → Term                           -- 命题层项
  lit   : (v : Literal) → Term                        -- 字面量：natT/stringT/wordT/floatT
  tac   : (t : Tactic) → Term                         -- 内联策略
  -- …… 以及 lam/dom/vArg/hArg/quotHole/delayed/absent 等
```

（`Term` 在 `Agda.Builtin.Reflection` 里是 builtin 数据类型，源码里用
`{-# BUILTIN AGDATERM ... #-}` 标注，不是能在 stdlib 里 `data` 出来的东西；
上面只为阅读起见列出主要构造子。）

把对象语言的项搬进引用世界有三个动作：

- `quote foo`：把**名字** `foo` 变成 `Name`，可以出现在 `con`/`def`/`vArg`
  这类位置；
- `quoteTerm e : Term`：在顶层（TC 之外）直接引用一段代码；
- `quoteTC e : TC Term`：在 TC 单子里引用（因此可以拿到当前上下文）。

示例里三个真实片段：

```agda
reflTerm : Term
reflTerm = con (quote refl) []

natTerm : Term
natTerm = def (quote Nat) []

sumTerm : Term
sumTerm = quoteTerm (2 + 3)

sumShown : String
sumShown = showTerm sumTerm
```

`reflTerm` 值得停一下：`refl` 在这里被当成**普通构造子**，参数个数为零——
它不接收反射层面的 `unknown` 隐式实参。写成
`con (quote refl) (unknown ∷ [])` 反而会在实际使用时炸掉（`refl` 的隐式参数
是"由 unify 反向解出"的，不需要你手填）。另外 `quote refl` 要求 `refl`
**在作用域内**：忘了 `open import Agda.Builtin.Equality using (_≡_; refl)`
时，报错是 `Not in scope` 并提示你大概想用 `_≡_.refl`。

`sumShown` 打印出来的字符串是 `Agda.Builtin.Nat._+_ 2 3`——注意它**不做
规约**，`quoteTerm` 拿到的是表面语法树。这正是反射的第一个用法：把项当
数据检查、当数据打印，不需要跑任何元程序。

## 23.4 TC 单子：2.8.0 的实测量

`TC`（type checking monad）在 2.8.0 的原始层里是一整批 postulate。下面是
从 `/usr/share/libghc-agda-dev/lib/prim/Agda/Builtin/Reflection.agda` 抄出的
主要成员（顺序与源码一致）：

```text
TC                       : ∀ {a} → Set a → Set a
returnTC                 : A → TC A            -- stdlib 层改名为 pure
bindTC                   : TC A → (A → TC B) → TC B
unify                    : Term → Term → TC ⊤
typeError                : List ErrorPart → TC A
inferType                : Term → TC Type
checkType                : Term → Type → TC Term
normalise / reduce       : Term → TC Term
catchTC                  : TC A → TC A → TC A
quoteTC / unquoteTC      : A → TC Term / Term → TC A
quoteωTC                 : Setω → TC Term
getContext               : TC Telescope
extendContext / inContext
freshName                : String → TC Name
declareDef / declarePostulate : Arg Name → Type → TC ⊤
declareData / defineData
defineFun                : Name → List Clause → TC ⊤
getType / getDefinition  : Name → TC …
isMacro                  : Name → TC Bool
withNormalisation / withReconstructed / withExpandLast / withReduceDefs
formatErrorParts         : List ErrorPart → TC String
debugPrint               : String → Nat → List ErrorPart → TC ⊤
noConstraints / workOnTypes / runSpeculative / commitTC / blockTC
```

两个"曾经有、现在没有"的名字要特别记住，网上代码常见：

```text
open import Reflection using (define)
-- warning: -W[no]ModuleDoesntExport
-- The module Reflection doesn't export the following:
--   define
```

```text
open import Reflection using (getGoalType)
-- warning: -W[no]ModuleDoesntExport
-- The module Reflection doesn't export the following:
--   getGoalType
```

`define` 被 `declareDef + defineFun` 取代；`getGoalType` 被删掉——目标类型
现在只能通过"拿到那个洞（hole），再 `inferType hole`"来间接获得，这正好
和宏的形态天然吻合。

`ErrorPart` 是报错信息的构造块：`strErr`、`termErr`、`pattErr`、`nameErr`。
stdlib 层还额外给了 `showTerm : Term → String`，方便在元程序里把项转成
字符串再拼。

## 23.5 do 记号：19 章的机制原样复用

19 章说过，Agda 2.8 的 do 记号是**内建语法**，脱糖只认作用域里的
`_>>=_`。`open import Reflection` 恰好把 `TC` 的 `_>>=_`（即 `bindTC`）和
`_>>_` 放了进来，于是 TC 代码可以写 do：

```agda
macro

  quietRefl : Term → TC ⊤
  quietRefl hole = do
    g ← inferType hole
    debugPrint "Reflection" 50 (strErr "goal: " ∷ termErr g ∷ [])
    t ← quoteTC (2 + 3)
    debugPrint "Reflection" 50 (strErr "term: " ∷ strErr (showTerm t) ∷ [])
    unify reflTerm hole

t1 : 2 + 2 ≡ 4
t1 = quietRefl

t2 : suc (2 + 3) ≡ 6
t2 = quietRefl
```

`debugPrint` 只在命令行开了对应 verbosity 时才输出。实测：

```console
$ rm -rf _build && timeout 600 agda -v Reflection:100 examples/Ex23_reflection.agda
Checking Ex23_reflection (/home/xulun/code/programming/agda/examples/Ex23_reflection.agda).
goal: 2 + 2 ≡ 4
term: Agda.Builtin.Nat._+_ 2 3
goal: suc (2 + 3) ≡ 6
term: Agda.Builtin.Nat._+_ 2 3
```

看到什么值得注意的东西？第一个 `goal` 是**洞的类型**，形如
`2 + 2 ≡ 4`：Agda 在检查 `t1 = quietRefl` 时，右边那个"待填项"就是类型检查
器手里的一个元变量（meta），宏的参数正是它。第二个 `term` 说明
`quoteTC` 拿到的仍是未规约的表观项。**注意缓存**：文件没改过时 `agda` 会
直接跳过检查、什么都不打印，看到"没有输出"先想到删 `_build/`。

## 23.6 写一个宏：`macro`、洞、以及报错怎么读

`macro` 块里声明的函数类型必须是 `Term → TC ⊤`：入参是"目标洞"，出参是
要么把洞解决掉、要么报错的 TC 计算。用法是把宏名直接写在等号右边
（`t1 = quietRefl`），Agda 会把它展开成 `unquote quietRefl`。

宏里最常用的三招：

1. `unify t hole`：把项 `t` 和洞 unify（**不检查类型**，靠约束求解）；
2. `checkType t ty` / `inferType hole`：显式类型动作；
3. `typeError parts`：主动报错。

`unify` 失败时 Agda 的默认报错很难读。给一个"证不出来就说人话"的版本：

```agda
macro

  safeRefl : Term → TC ⊤
  safeRefl hole = catchTC
    (do
      unify reflTerm hole)
    (do
      g ← inferType hole
      typeError (strErr "safeRefl: 这个目标不是 refl 可证的: " ∷ termErr g ∷ []))

t3 : 3 + 3 ≡ 6
t3 = safeRefl
```

对比两种失败（都是实测）。裸 `unify` 版本作用在 `bad : 2 ≡ 3` 上：

```text
error: [UnequalTerms]
3 != 2 of type Agda.Builtin.Nat.Nat
when checking that the expression _18 has type 2 ≡ 2
```

它把内部元变量名 `_18` 和"被 unify 出来的自反类型 `2 ≡ 2`"甩到你脸上——
这告诉你宏确实把 refl 塞进去了，但没告诉你**是哪个目标**失败。加
`catchTC + typeError` 后：

```text
error: [GenericDocError]
safeRefl: 这个目标不是 refl 可证的: 2 ≡ 3
when checking that the expression unquote safeRefl has type 2 ≡ 3
```

两个细节：`catchTC` 的类型是 `TC A → TC A → TC A`（第二个参数是**动作**，
不是函数——这点和 Haskell `Control.Exception.catch` 的 `a → SomeException → a`
不同）；而报错里出现的表达式写作 `unquote safeRefl`，这就是 `t3 = safeRefl`
的脱糖形态，看到它不用慌。

## 23.7 `unquote` / `unquoteDecl` / `unquoteDef`：把定义也交给元程序

`unquote` 是项层面的策略拼接，它现在**只接受 tactic**（`Term → TC ⊤`），
不再接受一个 `Term`：

```agda
x : Nat
x = unquote (quoteTC 42)
```

```text
error: [UnequalTerms]
TC Term !=< Term → TC ⊤
when checking that the inferred type of an application
  TC Term
matches the expected type
  Term → TC ⊤
```

想把算好的项塞回来，改用 `unquoteDecl`/`unquoteDef`：它们在**声明层**运行
TC 计算，能造出新的顶层定义。示例里的完整可跑版本：

```agda
unquoteDecl four = do
  declareDef (vArg four) (def (quote Nat) [])
  defineFun four (clause [] [] (quoteTerm (2 + 2)) ∷ [])

four-ok : four ≡ 4
four-ok = refl

five : Nat
unquoteDef five =
  defineFun five (clause [] [] (quoteTerm (2 + 3)) ∷ [])

five-ok : five ≡ 5
five-ok = refl
```

要点（每一条都撞过）：

- 右侧必须是 `TC ⊤`。写 `unquoteDecl a = quoteTerm (2 + 2)` 会得到
  **两条**错误：`MissingDefinitions`（`The following names are declared but
  not accompanied by a definition: a`）加上 `ClashingDefinition`
  （`Multiple definitions of a.`）——一个类型不对的元程序会留下半个声明，
  报错因此看起来很怪。
- 被定义的名字在右侧**直接就是 `Name`**，不需要也不能 `quote`。写
  `(quote four)` 报 `[CannotQuote.Expression]`。
- `unquoteDef` 前必须有类型签名，否则
  `[Syntax.UnquoteDefRequiresSignature] Missing type signatures for unquoteDef z`。
- 带标注的写法在 2.8.0 不解析：
  `unquoteDecl four : Nat = do …` → `[ParseError]`
  （报错文本就是 `:<ERROR>  Nat = do` 那一坨）。签名要单独立一行，或者
  干脆用 `declareDef` 给出类型（`four` 的类型正是 `declareDef` 的第二参数）。
- `clause` 住在 `Reflection.Clause`，得 `open Reflection.Clause using (clause)`。
- `declareDef` 的参数是 `Arg Name`，而 `Arg` 的第二个字段在 2.8.0 是
  `Modality`：直接写 `arg-info visible relevant` 不行，`vArg`/`hArg` 这类
  pattern _synonym 展开成 `(modality relevant quantity-ω)`。手写时照这个形状。

## 23.8 标准库自己就是用它写的：求解器宏

反射最有说服力的用途，标准库已经替你做了。`Data.Nat.Tactic.RingSolver`
和 `Tactic.MonoidSolver` 就是用同一套 TC API 写的宏（内部还用了
`Reflection.Instant`/`quoteTerm` 之类的技巧）：

```agda
open import Data.Nat.Base using (ℕ; _*_)
open import Data.Nat.Tactic.RingSolver using (solve-∀)

ring1 : 2 * 3 ≡ 6
ring1 = solve-∀

ring-comm : ∀ (x y : ℕ) → x + y ≡ y + x
ring-comm = solve-∀

ring-dist : ∀ (a : ℕ) → 2 * (a + 3) ≡ 2 * a + 6
ring-dist = solve-∀
```

monoid 求解器需要你把代数结构**显式**给它（Agda 没有类型类去猜）：

```agda
open import Algebra using (Monoid)
open import Data.List.Base using (List; _++_)
open import Data.List.Properties using (++-monoid)
open import Level using (0ℓ)
open import Tactic.MonoidSolver using (solve)

listMon : Monoid 0ℓ 0ℓ
listMon = ++-monoid ℕ

assoc : (x y z : List ℕ) → (x ++ y) ++ z ≡ x ++ (y ++ z)
assoc x y z = solve listMon
```

（`++-monoid` 接一个**显式**载体：`++-monoid ℕ`。）

ring 求解器的形态限制是硬坑：目标必须是 `∀` 绑定的形式。写成 lambda 绑定
会炸：

```agda
goal2 : (a b : ℕ) → a + b ≡ b + a
goal2 a b = solve-∀
```

```text
error: [UnequalTerms]
a != b of type ℕ
when checking that the expression
Tactic.RingSolver.Core.AlmostCommutativeRing.AlmostCommutativeRing.refl
{_} {_} Data.Nat.Tactic.RingSolver.ring {_}
has type
Data.Vec.N-ary.Eqʰ ℕ.zero
(Tactic.RingSolver.Core.Expression._.Eval.⟦ … ⟧
```

（原报错还有几十行内部模块路径，这里截断。）同一个目标改成
`∀ (x y : ℕ) → x + y ≡ y + x` 就过了。差别在于 `solve-∀` 处理"整个函数
作为证明"，而 `goal2 a b = solve-∀` 时洞的类型里已经带着自由变量 `a`、`b`，
求解器把两侧规范化成 `a + b` 与 `b + a` 时被迫把它们当常数比较。

这就是反射的性价比：一行 `solve-∀` 顶掉 13 章里十几行的归纳证明。代价是
**你不再知道证明长什么样**，而且一旦版本换了、API 挪了，代码就碎。

## 23.9 三方对照

| 维度 | Agda（2.8.0） | Coq | Lean 4 | Haskell |
|---|---|---|---|---|
| 元程序语言 | 就是 Agda 本身（`TC` 单子） | Ltac/Ltac2 独立语言 | 就是 Lean 本身（`macro`/`meta`） | 就是 Haskell（TH） |
| 何时跑 | 类型检查期 | proof 编辑/编译期 | 编译期（ELAB 单子） | 编译期splice |
| 能改什么 | 生成项、造定义、加宏 | 改证明目标、生成项 | 任意语法改写 | 任意语法改写 |
| 产物是否再被检查 | 是（终止检查等照旧） | tactic 产出的项要检查 | 是 | **否**，TH 产物照样再过一遍 GHC，但 GHC 的不变式弱得多 |
| 读写"当前目标" | 宏参数即洞 + `inferType` | 内建 | `MetaExpr`/`TacticM` | 无 |
| 稳定性 | 版本间断层大（2.6.1、2.8） | 相对稳定 | API 仍在演进 | 相对稳定 |

给写过 Coq 的人的心智补丁：Agda 的宏 ≈ "只能返回一个项"的 `exact ltac:(…)`，
没有 `intro`/`rewrite` 这种改变**目标形状**的策略原语——因为 Agda 里没有
"证明状态"这个一等对象，只有类型检查器的约束队列。给写过 Lean 的人的
补丁：Lean 的 `meta` 可以改写语法节点、造任意语法；Agda 只能造**项和声明**。
给写过 Haskell 的人的补丁：TH 的 `Q` 单子换成 `TC`，`reify` 大致对应
`getDefinition`/`getType`，但 `TC` 里没有"生成任意声明再塞回模块"的后门。

## 23.10 版本脆弱性与降级策略（诚实边界）

本章能给的可靠结论只有"在 2.8.0 + stdlib 2.3 上，以下清单实测通过"：
`Term`/`Name`/`Arg`/`ErrorPart`、`quote`/`quoteTerm`/`quoteTC`、
`unify`/`inferType`/`checkType`/`normalise`/`bindTC`/`catchTC`、
`debugPrint`/`formatErrorParts`、`declareDef`/`defineFun`/`clause`、
`macro`、`unquoteDecl`/`unquoteDef`、`showTerm`（stdlib 层）、以及 stdlib 的
ring/monoid 求解器宏。

不保证的有三类：**(1)** 原始层与 stdlib 层的名字差异（`returnTC` vs `pure`、
`Reflection` 各小模块在 2.3 里的拆分）；**(2)** `Term` 构造子的字段顺序与
`Arg`/`Modality` 的形状（2.8 改了 `ArgInfo` 一次）；**(3)** 求解器宏的适用
形态（`solve-∀` 对 `∀` 形式的依赖）。

所以工程上的稳态建议是**先把反射降级成"引用 + 打印 + 手抄"**，把宏留给
真正重复的部分：

```agda
-- 稳态三步：引用、打印、把打印结果拿去和手写项比对
open import Reflection using (Term; quoteTerm; showTerm)

target : 2 + 2 ≡ 4
target = {!!}     -- 交互式里 C-x C-a C-n 规约看目标，
                   -- 或把 Term 打印出来对照结构；
                   -- 确认结构后再手写成 refl
```

这一步能拿到反射 80% 的好处（看清项的形状、确认构造子参数、生成重复
样板），却完全不受 API 断层影响。只有当"手写"确实不可扩展（字段生成器、
几百个同形引理、代数恒等式）时，才动用 `macro`/`unquoteDecl`，并且把反射
代码关在自己的模块里，方便将来一次改完。

## 23.11 坑位清单（本项目实测）

1. **旧 API 整批消失**：`quoteGoal` → `Not in scope`；2.6.1 之前的反射
   教程代码基本一行都跑不通，先确认版本再抄。
2. **`define`、`getGoalType` 不存在**：`open import Reflection using (define)`
   只给**警告** `-W[no]ModuleDoesntExport`，文件可能"看起来没事"，直到你
   真去用它才 `Not in scope`。
3. **`open import Reflection` 不给你 `[]`/`∷`/`⊤`/`tt`/`String`**：要从
   `Agda.Builtin.List`/`Unit`/`String` 补；TC 代码里 `List` 有两种含义。
4. **子模块用 `open Reflection.Clause`，不是 `open import`**：后者
   `FileNotFound`。
5. **`con (quote refl)` 必须零参**：塞 `unknown` 隐式实参后目标反而不合；
   `refl` 的隐式参数是靠 unify 反向解出来的。
6. **`quote` 一个名字要求它在作用域内**：忘了 import `refl` 时报
   `Not in scope` + 建议 `_≡_.refl`。
7. **`Arg` 需要 `Modality`**：手写 `arg-info visible relevant` 失败，
   形状是 `arg-info (modality relevant quantity-ω) relevant`；用
   `vArg`/`hArg` pattern 最省事。
8. **`unquote` 不再吃 `Term`**：`unquote (quoteTC e)` →
   `TC Term !=< Term → TC ⊤`；项层面要 splice 定义请转 `unquoteDecl`。
9. **`unquoteDecl` 右侧必须是 `TC ⊤`**：写成 `quoteTerm …` 会同时留下
   `MissingDefinitions` 和 `ClashingDefinition` 两条错，看着像两个 bug。
10. **被绑定名字直接当 `Name` 用**：`unquoteDecl four` 里写 `(quote four)`
    → `[CannotQuote.Expression]`。
11. **`unquoteDef` 要签名**：`Syntax.UnquoteDefRequiresSignature`；
    `unquoteDecl x : T = …` 的标注写法在 2.8.0 是 `ParseError`。
12. **`quoteTC refl` 会带隐式元变量进引用世界**：宏里这么写报
    `UnsolvedMetaVariables`，指向 `quoteTC refl` 那两个隐式位；改用现成的
    `Term` 常量，或 `quoteTC` 一个封闭项。
13. **`solve-∀` 只吃 `∀` 形式目标**：lambda 绑定形式炸出带
    `RingSolver.Core.AlmostCommutativeRing` 的几十行内部报错，核心是
    `a != b of type ℕ`。
14. **`++-monoid` 的载体是显式参数**、`solve` 要 `solve mon` 且 `mon` 最好是
    顶层绑定（否则宇宙层级 metavar 无解）。
15. **`-v` 调试输出会被缓存吞掉**：`agda` 对未修改文件不重新检查、什么都不
    打印；`rm -rf _build` 或改一下文件再跑。
16. **`Debug.Trace` 不是反射层**：它要 `{-# OPTIONS --rewriting #-}` 才能
    import（否则 `InfectiveImport`），且只导出 `trace`/`trace-eq`；打印只在
    `--compile` 出的可执行文件里发生，类型检查期想看东西请用 `debugPrint`。

---
上一章：[22 · 余归纳与无限流](22-codata.md) ｜ 下一章：[24 · 立方类型论初步](24-cubical.md) ｜ 返回：[README](../README.md)
