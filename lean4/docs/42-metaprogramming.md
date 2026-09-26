# 42 · 元编程

**对标**: *Functional Programming in Lean*（Metaprogramming 章）；*Reference* 第2章（Elaboration）、第23章（Notations and Macros）。

第27章讲了最轻量的语法扩展（`notation`、`macro`）。本章揭示 Lean 元编程的**全貌**：
从源代码文本到内核接受的证明项，中间经过哪些阶段，以及如何在每个阶段插手——
这正是 Lean 能把"战术""记法""自动化"统统用 Lean 自己写出来的原因。

> 本章为纯 Lean 核心（`import Lean`），在 4.34.1 验证。

## 42.1 三个阶段：Syntax → MetaM → Expr

Lean 处理一段代码经历三层，每层有对应的数据结构和单子：

| 阶段 | 数据 | 单子 | 做什么 |
|---|---|---|---|
| 解析 Parsing | `Lean.Syntax`（语法树） | `ParserM` | 文本 → 语法树 |
| 精细化 Elaboration | `Lean.Syntax` → `Lean.Expr` | `MetaM` / `TermElabM` | 语法树 → 带类型的核心表达式 |
| 内核 Kernel | `Lean.Expr` | `CoreM` | 检查类型、归约、接受/拒绝 |

- **`Syntax`** 是"还没解析含义"的语法树（记号、原子、节点）。
- **`Expr`** 是核心 λ-演算表达式（变量、应用、lambda、Pi、let、常量、字面量、sort、mvar/fvar）。
- **`MetaM`** 是元编程的主力单子：能创建 metavariable、做类型推断、归约、统一——`simp`/`omega` 等战术都活在这里。
- **`CoreM`** 更底层，能读写环境（`Environment`）、声明常量。

元编程就是写 `MetaM`/`CoreM` 程序，把 `Syntax` 变成 `Expr`。`macro`/`elab`/战术都是这套机制的不同封装。

## 42.2 Quoting 与 Antiquoting

反引号 `` `(...) `` 是 **quoting**：把一段语法当作 `Syntax` 值（而非立即解释）。
`$x` 是 **antiquoting**：把一个已有的 `Syntax`/`Expr` 嵌进引用里。

```lean
import Lean
open Lean Elab Term Meta

-- quoting 产生 Syntax 树
#eval `(1 + 2)
-- { raw := Lean.Syntax.node ... `«term_+_»
--     #[node `num #["1"], atom "+", node `num #["2"]] }
-- （即 1 + 2 的语法树：一个 term_+_ 节点，含 num 1、原子 +、num 2）

-- antiquoting：把参数 x 嵌进模板
macro "addOne" x:term : term => `($x + 1)
#eval addOne 5   -- 6
```

`` `($x + 1) `` 在宏展开时，把调用处的实参语法 `$x` 拼进 `· + 1` 模板，生成新 `Syntax`。
这就是宏"按模式造语法"的本质。带类型标注的 antiquotation 写作 `` $x:term ``（指明嵌入的是 term 类语法）。

## 42.3 macro：term 与 tactic 两个世界

`macro` 是"语法 → 语法"的纯展开，最轻量。它能定义 term 宏，也能定义 tactic 宏：

```lean
-- term 宏
macro "double" x:term : term => `(2 * $x)
#eval double 21   -- 42

-- tactic 宏：展开成已有 tactic
macro "reflexivity" : tactic => `(tactic| exact rfl)
example : 2 + 2 = 4 := by reflexivity
```

注意 tactic 引用用 `` `(tactic| ...) ``（指定 `tactic` 语法类目）。`macro` 只做语法替换，
**不访问 elaborator 上下文**——需要生成 fresh 名字、查环境、做类型推断时，必须升级到 `elab`。

## 42.4 syntax + macro_rules / elab_rules

更结构化的方式是先用 `syntax` 声明新语法，再用 `macro_rules`（纯语法）或 `elab_rules`（带精细化）实现它：

```lean
-- 声明语法类目里的新产生式，再用 macro_rules 给展开规则
syntax "twice" term : term
macro_rules
  | `(twice $x) => `($x + $x)
#eval twice 21   -- 42

-- macro_rules 也能给无参数的记号定义展开
macro_rules
  | `(mytest) => `(1 + 1)
#eval mytest     -- 2
```

`syntax "twice" term : term` 把 `twice <term>` 注册为 term 语法；`macro_rules` 用模式匹配
（`` | `(twice $x) => ... ``）给出展开。`elab_rules` 形式相同，但右边是 `TermElabM` 程序，
能调用类型推断——这是定义"需要语义信息"的语法时的工具。

## 42.5 elab：自定义 elaborator 与战术

`elab` 直接写精细化程序：输入 `Syntax`，在 `MetaM`/`TermElabM` 里产出 `Expr`。自定义 term 和 tactic 都靠它：

```lean
-- 自定义 term elaborator：返回一个 Expr
elab "answer" : term => do
  return Lean.mkNatLit 42
#eval answer   -- 42

-- 自定义 tactic：在 tactic 的 elaboration 单子里跑
open Lean Elab Tactic in
elab "triv" : tactic => do
  evalTactic (← `(tactic| exact trivial))
example : True := by triv

open Lean Elab Tactic in
elab "norm" : tactic => do
  evalTactic (← `(tactic| simp))
example : 2 + 2 = 4 := by norm
```

`elab "answer" : term => do return mkNatLit 42`：把字面量 `42` 造成 `Expr` 返回，于是 `answer`
在任何 term 位置都精细化成 `42`。自定义 tactic 用 `evalTactic (← `(tactic| ...))` 复用现成战术。

> **版本陷阱**：`elab` 体里若用到 `←`（lift 一个 meta 动作，如 `` ← `(tactic| ...) ``），
> **必须包在 `do` 块里**。写成 `elab "triv" : tactic => evalTactic (← ...)`（无 `do`）会报
> "Nested action `← ...` must be nested inside a `do` expression"。

## 42.6 运行元程序：CoreM / MetaM

`#eval` 能直接跑 `CoreM`/`MetaM` 计算（Lean 知道怎么执行这些单子），这是探索元编程 API 的利器：

```lean
-- MetaM：构造表达式、推断类型、归约到弱头范式
#eval show MetaM String from do
  let e ← mkAppM ``Nat.add #[mkNatLit 2, mkNatLit 3]   -- 构造 Nat.add 2 3
  let t ← inferType e                                   -- 推断类型
  return s!"expr={e} type={t}"
-- "expr=Nat.add (OfNat.ofNat.{0} Nat 2 (instOfNatNat 2)) (OfNat.ofNat.{0} Nat 3 (instOfNatNat 3)) type=Nat"

#eval show MetaM String from do
  let e ← mkAppM ``Nat.add #[mkNatLit 2, mkNatLit 3]
  let w ← whnf e                                        -- 弱头归约
  return s!"whnf={w}"
-- "whnf=5"
```

`mkAppM`（带类型推断的应用构造）、`inferType`、`whnf` 是 `MetaM` 的核心 API。注意 `mkNatLit 2`
造出的是 `OfNat.ofNat ... 2 ...`（数字字面量的完整形态），`whnf` 后归约成 `5`。

`CoreM` 更底层，能读环境：

```lean
#eval show CoreM String from do
  let e := mkApp (mkConst ``Nat.succ) (mkNatLit 5)   -- 手工搭 Nat.succ 5
  return toString e
-- "Nat.succ (OfNat.ofNat.{0} Nat 5 (instOfNatNat 5))"
```

## 42.7 Lean.Expr：核心表达式

`Expr` 是内核认识的 λ-演算项。它的构造子直接对应核心语法：

```lean
#eval show CoreM String from do
  return toString (Expr.lit (.natVal 7))   -- "7"
```

`Expr` 的主要构造子：`.bvar`（绑定变量，de Bruijn 索引）、`.fvar`（自由变量）、`.mvar`（元变量，
精细化时的"洞"）、`.sort`（`Sort u`）、`.const`（命名常量）、`.app`（应用）、`.lam`（λ）、
`.forallE`（Π）、`.letE`（let）、`.lit`（字面量）、`.mdata`（附加元数据）、`.proj`（结构投影）。
战术、`simp`、统一算法全都是在 manipulate `Expr`。理解 `Expr` 是深入元编程（写 `simp` 插件、
自定义战术、`aesop` 规则）的前提。

## 42.8 元编程地图

| 需求 | 工具 | 能否访问语义 |
|---|---|---|
| 纯语法替换 | `macro` / `macro_rules` | 否 |
| 声明新语法 | `syntax` | —（只声明） |
| 语法 + 类型推断 | `elab` / `elab_rules` | 是（`MetaM`） |
| 自定义记号 | `notation` / `infix` / `prefix` | 否 |
| 跑元程序探索 API | `#eval ... : CoreM/MetaM` | 是 |
| 注册自定义属性 | `register_attribute` + `initialize` | 是 |

第43章讲属性系统（`@[simp]` 等如何用 `register_attribute` 实现），第20章的定理搜索、第19章的战术
都是元编程的产物。掌握了 Syntax→MetaM→Expr 这条链，你就拿到了"用 Lean 扩展 Lean"的钥匙。

---

> 上一章：[41 · 与 Lean 交互与精细化](41-interacting-elaboration.md) ｜ 下一章：[43 · 属性系统](43-attributes.md) ｜ 返回：[README](../README.md)
