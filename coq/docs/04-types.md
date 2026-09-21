# 04 · 类型系统

对应示例：`../examples/04_types.v`

### 4.1 nat 的真身：一条 S 链

Coq 里没有内建的「机器整数」。自然数是**定义出来的**：

```coq
Print nat.
```

```text
Inductive nat : Set :=  O : nat | S : nat -> nat.
```

翻译成人话：`nat` 类型有两个构造子（constructor）——

- `O : nat`——零；
- `S : nat -> nat`——后继（successor），「加一」。

于是每个自然数都是一条链：`1 = S O`，`2 = S (S O)`，`3 = S (S (S O))`……运行 `Compute (S (S (S O))).` 得 `= 3 : nat`——打印时 Coq 自动把链折叠成数字给你看（实测）。

这个设计初看低效（确实低效，第 22 章解决），换来两样无价的东西：

1. **归纳原理**：「对 O 成立、对 S k 也成立（假设对 k 成立），则对所有自然数成立」——第 12 章的归纳证明直接建立在 nat 的形状上；
2. **类型上无溢出**：数要多大有多大，`Check (2 ^ 100).` 合法（`^` 记号需 `Arith`，实测）。

但马上泼一盆冷水（实测坑）：**「类型装得下」不等于「算得动」**。一元表示下 `Compute (Nat.pow 2 100).` 会直接**内存耗尽**——2¹⁰⁰ 约需 10³⁰ 个 `S` 构造子，宇宙里的原子都不够存。「无溢出」是逻辑层面的性质；工程层面的大数计算请用二进制的 `N`/`Z`（第 22 章）。

把类型理解为「值的集合 + 形状规则」，nat 是最好的第一课：集合是所有 S 链，形状规则是「只能是 O 或 S 套另一个 nat」。

### 4.2 常用内置类型速览

| 类型 | 构造子 | 例子 |
|---|---|---|
| `nat` | `O`、`S` | `0`、`3`、`S (S O)` |
| `bool` | `true`、`false` | `negb true` |
| `list A` | `nil`（`[]`）、`cons`（`::`） | `[1; 2; 3]` |
| `option A` | `None`、`Some` | `Some 5` |
| `A * B` | 唯一的二元组构造子 | `(3, true)` |
| `sum A B`（`A + B`） | `inl`、`inr` | `inl 3` |
| `unit` | `tt` | `tt` |
| `Empty_set` | 无 | 不存在值 |

三个观察：

- **`A * B` 与 `A + B` 的记号容易和乘法加法搞混**——它们在 `type_scope` 作用域里是「积类型/和类型」（对偶与变体），在 `nat_scope` 里才是算术。`Locate "*"` 可以看到全部绑定（实测时你会发现 `*` 的解释比 `+` 还多）；
- **`list`/`option` 都是「参数化类型」**：装什么类型的东西由 `A` 决定，这叫多态（4.5 节）；
- **`Empty_set` 没有构造子**——造不出任何值。按 Curry–Howard，它对应「假命题」：`Empty_set -> A` 类型的函数能从「假」推出任何东西（第 14 章用它定义否定）。

### 4.3 万物皆有类型，类型也有类型

Coq 是「三层都有一致结构」的系统：值有类型，类型也有类型（称为 **sort**），sort 之上还有层级：

```coq
Check 3.       (* 3 : nat *)
Check nat.     (* nat : Set *)
Check bool.    (* bool : Set *)
Check Set.     (* Set : Type *)
Check Type.    (* Type : Type —— 打印时隐藏层级编号 *)
```

三个 sort 的分工，初学阶段记这个版本就够：

| Sort | 住着谁 | 例子 |
|---|---|---|
| `Set` | 数据类型 | `nat`、`bool`、`list nat` |
| `Prop` | 命题 | `3 = 3`、`forall n, n + 0 = n` |
| `Type` | 上面两者共同的「父类」 | `Set : Type`、`Prop : Type`，以及 `list` 这样的类型构造子 |

日常说「类型」时通常指 `Set`/`Type` 层的居民；说「命题」指 `Prop` 层的居民。**Prop 里的东西不可计算**——`3 = 3` 不能 `Compute`，它只能被证明或证伪；这与接下来这条对照着记。

### 4.4 Prop 与 bool 的第一次照面

新手最困惑的一对：`3 = 3`（Prop）与 `Nat.eqb 3 3`（bool）有什么区别？

```coq
Check (3 = 3).       (* 3 = 3 : Prop *)
Check (Nat.eqb 3 3). (* Nat.eqb 3 3 : bool *)
Compute (Nat.eqb 3 3).  (* = true : bool *)
Compute (3 = 3).        (* = 3 = 3 : Prop —— 不报错！见下 *)
```

- **bool 是数据**：`true`/`false` 两个值，程序可以对它 match、if、计算——**运行时**用来做分支；
- **Prop 是命题**：`3 = 3` 是一个断言，回答它要靠**构造证明**，而不是「算」。

有个容易想当然的地方（实测）：`Compute (3 = 3).` 并不报错——它打印 `= 3 = 3 : Prop`。Compute 只是把命题这个项**规范化后原样还给你**，它不回答「成立与否」；`3 = 3` 也不是 `true`。命题的真假是证明的事，求值帮不上忙。

「都是相等性，为什么要两套？」——因为它们回答不同的问题：`Nat.eqb 3 3` 问「程序算出来是不是 true」（可计算但只对具体值有意义）；`3 = 3` 及其推广 `forall n, n + 0 = n` 表达数学断言（覆盖无穷多情况，无法靠计算穷尽）。两座桥（`Nat.eqb_eq`：bool 等于 true 当且仅当命题成立）在第 15 章的 reflect 主题下正式讲。

### 4.5 类型推断：标注可省则省

Coq 的类型推断能力与 OCaml 同源（都源自 Hindley–Milner 传统，Coq 加了依赖类型的扩展），绝大多数标注可以省：

```coq
Definition fortytwo := 42.
Check fortytwo.        (* fortytwo : nat —— 推断出来的 *)

Definition double (n : nat) : nat := 2 * n.
Definition double' n := 2 * n.
Check double'.         (* double' : nat -> nat —— 参数类型也能推 *)
```

但**省标注不等于不检查**：

```coq
Fail Check (double true).
(* The term "true" has type "bool" while it is expected
   to have type "nat". *)
```

什么时候该写标注？本教程的习惯：**公开定义写全**（`Definition f (n : nat) : nat := ...`）——类型即文档且防推断意外；**内部辅助小函数**可省。教学代码一律写全。

### 4.6 多态与隐式参数

「对任何类型 A 都成立」的函数，把 A 作为参数：

```coq
Definition id {A : Type} (a : A) : A := a.
```

花括号 `{A : Type}` 表示**隐式参数**：调用时不用写，由其他参数推断：

```coq
Check (id 10).       (* id 10 : nat —— A 被推断为 nat *)
Check (id true).     (* id true : bool —— A 被推断为 bool *)
Check (@id nat 10).  (* @id nat 10 : nat —— @ 关掉隐式，手动给全 *)
```

`@` 是个重要前缀：「接下来的参数全部显式给」。两个使用场景：

1. 想显式指定隐式参数（推断结果不合意时）；
2. 引用多态常量本身——`Check id.` 只会看到 `id : forall A : Type, A -> A`，而 `Check (@id nat).` 能谈到「nat 版本的 id」。

标准库的空表与拼表也这样用：

```coq
Check (@nil nat).        (* @nil nat : list nat —— 空表要说明装什么 *)
Check (cons true nil).   (* (true :: nil)%list : list bool *)
```

注意打印时 Coq 自动换用 `::` 记号显示。`list` 的 `A` 是隐式的，所以 `[1; 2]` 不需要写 `list nat [1; 2]`——糖衣之下，一切仍是显式的类型检查（第 8 章展开列表）。

### 4.7 构造子的纪律

每个构造子只接受**自己类型声明的参数**，一点不含糊：

```coq
Fail Check (S true).
(* The term "true" has type "bool" while it is expected
   to have type "nat". *)
```

`S` 只吃 nat。跨类型转换不存在「隐式提升」——整数转浮点、char 转 int 这类 C 的日常，在 Coq 里都必须显式发生。这在证明语境是刚需：**隐式转换是逻辑漏洞的温床**（`0.999... == 1` 型的意外），Coq 从类型层根除了它们。

### 4.8 本章坑位清单（实测）

1. **以为 `3` 是机器整数**：它是 `S (S (S O))`；性能敏感场景第 22 章换 `N`/`Z`；
2. **以为 `Compute (Nat.pow 2 100)` 只是慢**：实测直接 **内存耗尽**——一元表示撑不起大数，`Check` 装得下≠`Compute` 算得动；
3. **以为 `Compute (3 = 3)` 会报错**：实测打印 `= 3 = 3 : Prop`——求值只做规范化，不回答命题真假；
4. **隐式参数想显式给却忘了 `@`**：`Check (id nat 10).` 会把 nat 当成 A 的值——必须 `@id nat 10`（实测如期失败）；
5. **`A * B` / `A + B` 与算术混淆**：作用域决定含义，怀疑时 `Locate "+"`；
6. **以为类型标注是「建议」**：写错照样编译失败，标注参与检查，不是注释。

---
上一章：[03 · 第一个证明](03-first-proof.md) ｜ 下一章：[05 · 表达式与运算符](05-expressions.md) ｜ 返回：[README](../README.md)
