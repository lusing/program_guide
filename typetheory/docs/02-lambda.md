# 02 无类型 λ 演算

> 对应读本：Hindley《Basic Simple Type Theory》第 1 章；TTAFP 第 1 章；
> de Bruijn 技法见 TAPL 第 6 章。
> 代码：`examples/02_lambda/`——Lean / Coq / Agda **三份同构实现**
> （同一算法、同一批测试），逐行可对照。

## 2.1 项的语法

无类型 λ 演算只有三种构词法：

```text
M, N ::= x            变量
      |  λx. M        抽象（函数）
      |  M N          应用
```

就这三条， expressive power 却是图灵完备的——它是所有函数式语言与
所有证明助手内核的共同祖先。本指南后续的每一种「类型系统」都是
在这三项式语法上加限制或加信息。

**自由变量与捕获**。`FV(M)` 是未被绑定器捕获的变量；代换
`[x := N]M` 的定义里藏着一个著名陷阱：

```text
[ x := y ] (λy. x)   应该是  λz. y   （先把 λy 改名 λz）
而不是  λy. y        （y 被外面的 λy 「捕获」了）
```

教学上通常说「代换时顺手改名」（α-转换）。工程上有更省事的方案：
**de Bruijn 指标**——变量不叫名字，而用「离最近绑定器的层数」：

```text
λx. λy. x        →  λ. λ. 1
λx. λy. y        →  λ. λ. 0
λf. (λx. f x) x  →  λ. (λ. 1 0) 0
```

α-等价（改名）变成**同一个项**，代换永远无捕获——代价是可读性。
三家示例代码全部用 de Bruijn，`examples/02_lambda/` 的最后一组测试
专门复现了捕获现场：

```text
(λx. λy. x) z  →  λw. z        -- 正确：z 移入 λy 时指标 0 → 1
   （naive 代换会得到 λy. y —— 自由变量被绑定器吞掉）
```

## 2.2 β 与 η：计算与外延

**β-归约**是 λ 演算的核心计算规则：

```text
(λx. M) N  →β  [x := N] M
```

**η-归约/η-展开**表达函数的外延性：

```text
λx. M x  →η  M      （x ∉ FV(M)）
```

直觉：`M` 与「把参数原样喂给 M 的函数」在所有输入上行为相同，
故可互相替换。η 在第 12 章（相等类型）还会回来——**η-相等**是
定义相等的重要组成部分（函数的 η：`f ≡ λx. f x`；积的 η：`p ≡ (p.1, p.2)`）。

## 2.3 归约策略与 Church–Rosser

一个项里可能同时有多个 redex。归约策略决定先缩哪个：

- **最左最外（normal order）**：总选语法最左、不在任何 λ 体之内的
  redex。定理：**若项有 β-范式，normal order 必能到达它**。
- **call-by-name / call-by-value** 等按需策略：不保证到达范式，但
  实现效率好，是现实语言的语义（TAPL 语境）。

**Church–Rosser 定理**（1936，对 β）：

> 若 `M →β* N₁` 且 `M →β* N₂`，则存在 P 使 `N₁ →β* P` 且 `N₂ →β* P`。

推论二连：① 范式若存在则**唯一**；② 两个范式不同的项**不可能**等价。
第 24 章元理论再谈证明思路。示例代码用 normal order，
`normalizeFuel` 是「带燃料的规范化」——燃料既是对发散项的逃生门
（Ω 永不停），也是三家终止检查器都满意的写法：

```lean
def normalizeFuel : Nat → Term → Term
  | 0, t => t
  | n+1, t => match step t with
    | none => t
    | some t' => normalizeFuel n t'
```

> **三家的终止立场**：Lean/Coq 只检查声明的递归（结构/良基）；
> Agda 检查文件里**所有**递归函数。`step` 本身对发散项只是「走一步」
> ——它总能返回，所以结构递归即可通过三家检查。真正发散的是
> 「无限次做 step」，这个循环被燃料参数挡在类型系统之外。

## 2.4 组合子逻辑：S 与 K

只用两个组合子就能表达一切可计算函数：

```text
K = λx y. x              -- 常函数
S = λx y z. x z (y z)    -- 复杂但万能
```

它们与逻辑的呼应（第 5 章的主角）：K 的类型 `A → B → A` 恰是命题
逻辑公理；S 的类型 `(A → B → C) → (A → B) → A → C` 恰是另一公理。
先看计算侧：

```text
S K K  →β*  λx. x = I     -- 恒等函数可以「拼」出来
```

三份示例都机器验证了这条：`normalizeFuel 100 (S K K) = λ. 0`。
顺带验证了 `(S K K) 7 = 7`——组合逻辑在无类型世界里忠实模拟 λ 演算
（Curry 定理：可解性两边一致）。

## 2.5 Church 数、不动点与不一致

**Church 数**把自然数编码为「迭代 n 次」：

```text
2  =  λf x. f (f x)         3  =  λf x. f (f (f x))
+  =  λm n f x. m f (n f x)
×  =  λm n f. m (n f)       ↑  =  λm n. n m
```

示例代码让 normalizer 真算了：`2+3→5`、`2×3→6`、`2^3→8`、
`2^5→32`（64 步归约，`stepsToNf` 可数）。

**自应用与发散**。无类型世界允许 `ω = λx. x x`，于是

```text
Ω = ω ω →β ω ω →β …       -- 每一步都回到自身，永不停止
```

三家示例都验证了 `step Ω = some Ω`。更进一步，用不动点组合子

```text
Y = λf. (λx. f (x x)) (λx. f (x x))     -- Y f →* f (Y f)
```

可以定义任意递归。但「一切函数都有不动点 + 自由自应用」在逻辑上
是要命的：把 λ 演算当作命题的逻辑（Curry 悖论），可以推出任意命题；
Kleene–Rosser 1935 证明原始无类型系统**不一致**。这正是 Church 转向
类型论的动因，也是下一章的主角。

## 2.6 三份镜像代码导读

同一算法在三家的样子（`examples/02_lambda/ex02_lambda.{lean,v,agda}`）：

| 环节 | Lean | Coq | Agda |
|---|---|---|---|
| 数据类型 | `inductive Term` | `Inductive term` | `data Term` |
| 平移 | `def shift (d : Int) (c : Nat) : Term → Term` | `Fixpoint shift (d : Z)` | `shift : ℤ → ℕ → Term → Term` |
| β 单步 | `def step : Term → Option Term` + 模式匹配 | 同构 `Fixpoint` + `option_map` | `step` + `with` 分支 |
| 范式 | 燃料递归 | 同 | 同 |
| 机器验证 | `example ... := by rfl` | `Example ... vm_compute. reflexivity.` | `name : lhs ≡ rhs` + `refl` |

三个值得驻足的细节：

1. **if 的条件类型**。Lean 的 `if c ≤ k` 直接吃 `Prop`（`decidable`）；
   Agda 的 `if_then_else_` 只吃 `Bool`，Dec 要用 `⌊ c ≤? k ⌋` 降下来；
   Coq 用 `Nat.leb c k` 显式返回布尔——三家对「可判定性」的态度
   在一行代码里就分了岔。
2. **vm_compute vs rfl**。Coq 的 `reflexivity` 默认用懒求值，
   `vm_compute` 换字节码虚拟机——λ 归约这种重计算必须切过去，
   否则秒级变分钟级。Lean 的 `by rfl` / `#eval` 走编译器；
   Agda 的类型检查器内部有自己的规约器，`refl` 直接吃下
   200 步归约毫无压力。
3. **应用链的括号**。`m f (n f x)` 是 `((m f) ((n f) x))`——
   de Bruijn 下漏一层 `app` 嵌套是实打实的错误（本批测试初稿就
   错过一次：`2+3` 解码不出 5 才暴露）。

## 2.7 从 λ 到类型：下一章预告

无类型 λ 演算全能但不一致。Church 1940 的解法：给每个项**预先**
配一个类型，`(λx. M) N` 只在 `N` 的类型与 λ 捕获的变量类型吻合时
才合法。`ω = λx. x x` 从此写不出来——`x` 不能同时是函数类型和它自己的
参数类型。这就是 λ→，第 3 章见。

> **坑位速记**
> ① de Bruijn 应用链必须显式嵌套：`m f x` 是 `(m f) x` 不是
> `m (f x)`，`cplus` 初稿因此翻车；
> ② Coq 里 `nat` 字面量 ≥ 5000 触发 `abstract-large-number` 警告，
> 燃料参数用小数字（本批统一 500）；
> ③ Agda 的 `if` 只吃 `Bool`，`Dec`（`≤?`/`≟`）要 `⌊_⌋`；
> ④ Agda 数据类型/构造子首字母可以小写（`term`/`var`），与 Lean/Coq
> 大写惯例不同，本文件三家分别用了各家地道风格；
> ⑤ bound 变量不受 shift 影响（`shift 1 0 (λ. 0 0)` 等于自身）——
> 检验对代换的理解时先想清楚变量的自由/绑定身份。

---

上一章：[01 认识类型论](01-intro.md) · 下一章：[03 λ→](03-stlc.md)
