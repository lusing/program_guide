# 55 · de Bruijn 判据与 kernel 原理

对应示例：`../examples/T55_de_bruijn_kernel.thy`

## 55.1 一句话概括

54 章讲了 LCF 的架构思想：极小内核 + 抽象类型 thm + 策略层自由组合。本章打开 Isabelle 的真实 kernel，看这三条是如何具体落实的。重点是**理解为什么这套设计能担保可靠性**，而不是学新证明技巧。

## 55.2 de Bruijn 判据的三条要求

de Bruijn 判据（第 54 章）说一个证明检查器值得信任当且仅当：

1. **内核极小**：只有一小段代码说"这一步对"。
2. **类型即命题**：命题是类型，证明是该类型的项。
3. **无特殊信任假设**：除了内核和类型检查器，不需要信任任何其他组件。

Isabelle 的落实方式：

- 第 1 条：kernel 是 `src/Pure/thm.ML` 一个文件，推理规则是 `Thm` 结构体里十几个函数。整个 Isabelle 发行版（1467 个 .thy、几百万行 ML/Scala）的可靠性都压在这一个文件上。
- 第 2 条：Isabelle 的命题是 `term` 类型（高阶逻辑的语法树），证明是 `thm` 类型（sequent：假设 + 结论 + 约束）。`thm` 是 ML 抽象类型——它的值**只能**通过 kernel 函数构造。
- 第 3 条：策略层（simp、blast、auto、metis……）产出的每个 `thm` 都经过了 kernel 函数的类型检查。策略有 bug 不会导致"假定理"——最多导致"证不出来"或"证错目标"，但产出物永远是真定理。

## 55.3 thm 的底层表示：sequent

在 ML 里，`thm` 的底层表示是一个 record（sequent）：

- `prop`：结论（一个 `term`）
- `hyps`：假设列表（被 `assume` 引入的命题）
- `tpairs`：flex-flex 约束对（高阶合一的残留物，通常为空）
- `shyps`：排序假设（类型类的假设，通常为空）

用 ML 拿一条真实定理拆开看（实测）：

```isabelle
lemma demo_thm: "A \<Longrightarrow> B \<Longrightarrow> A \<and> B"
  by blast

ML ‹
  val th = @{thm demo_thm}
  val _ = writeln ("prop = " ^ @{make_string} (Thm.prop_of th))
  val _ = writeln ("hyps = " ^ @{make_string} (Thm.hyps_of th))
  val _ = writeln ("nprems = " ^ string_of_int (Thm.nprems_of th))
›
```

注意 `hyps` 是空列表——因为 `A \<Longrightarrow> B \<Longrightarrow> A \<and> B` 里的 A、B 是**自由变量**（元变量），不是假设。真正的假设要用 `Thm.assume` 引入，见 55.4。

## 55.4 推理规则即 ML 函数：kernel 实战

现在用 kernel 函数从零构造一条定理。目标：证 `A \<Longrightarrow> A`（同一律）。步骤：

1. `Thm.assume`：引入假设 A，得到 thm `A \<turnstile> A`。
2. `Thm.implies_intr`：把假设 A 变成前件，得到 `\<turnstile> A \<Longrightarrow> A`。

每一步都是一个 kernel 函数调用，ML 类型系统保证没有别的路可以造出 `thm`。

```isabelle
ML ‹
  val ctxt = @{context}
  val a = @{cterm "Trueprop A"}
  val th1 = Thm.assume a
  val _ = writeln ("assume 后: " ^ @{make_string} (Thm.prop_of th1))
  val _ = writeln ("hyps = " ^ @{make_string} (Thm.hyps_of th1))
  val th2 = Thm.implies_intr a th1
  val _ = writeln ("implies_intr 后: " ^ @{make_string} (Thm.prop_of th2))
  val _ = writeln ("hyps = " ^ @{make_string} (Thm.hyps_of th2))
›
```

输出里能清楚看到 sequent 的变化：

- `assume` 后：prop 是 `A`，hyps 是 `[A]`——假设里有一条 A。
- `implies_intr` 后：prop 变成 `A \<longrightarrow> A`（源码形式 `A \<Longrightarrow> A`），hyps 清空。

这就是 LCF 的核心机制：**thm 的构造过程就是 sequent 的变换过程**，每个变换对应一条推理规则，ML 类型系统保证变换合法。

## 55.5 复合规则：transitive 与 meta-equality

再来一个稍复杂的例子：用等式传递性 `Thm.transitive` 把 `x \<equiv> y` 和 `y \<equiv> z` 串成 `x \<equiv> z`。注意这里用的是 **meta-level equality**（`\<equiv>`，Pure.eq），不是 HOL 的 `=`——`Thm.transitive` 是 Pure 层的规则，操作的是 `\<equiv>`。

```isabelle
ML ‹
  val x = @{cterm "x :: 'a"}
  val y = @{cterm "y :: 'a"}
  val z = @{cterm "z :: 'a"}
  val xy = Thm.assume @{cterm "x \<equiv> (y::'a)"}
  val yz = Thm.assume @{cterm "y \<equiv> (z::'a)"}
  val xz = Thm.transitive xy yz
  val _ = writeln ("transitive: " ^ @{make_string} (Thm.prop_of xz))
  val _ = writeln ("hyps = " ^ @{make_string} (Thm.hyps_of xz))
›
```

注意 hyps 里有两条假设（`x \<equiv> y` 和 `y \<equiv> z`），它们还没被 `implies_intr` 消掉。这展示了 sequent 的精髓：**定理不是"裸命题"，而是"在某些假设下命题成立"**。

## 55.6 为什么策略层不可能伪造定理

上面看到的 `Thm.assume`、`Thm.implies_intr`、`Thm.transitive` 都是 `Thm` 结构体的导出函数。`thm` 类型在 ML 里是抽象的——**没有构造器暴露给外部代码**。

这意味着：

- 用户 ML 代码不能写 `Thm.Thm (...)` 来"手工造"一个 thm——类型系统拒绝。
- 唯一的"造 thm"途径就是调 kernel 函数。
- 每个 kernel 函数对应一条逻辑上合法的推理规则。

所以 simp、blast、auto、metis、Sledgehammer……这些策略无论多复杂，它们产出的每个 thm 都经过了 kernel 函数的把关。策略有 bug 的后果是"证不出"或"证错目标"，但**绝不会**产出假定理——因为假定理过不了 kernel 的类型检查。

这就是 LCF 架构的可靠性担保：**信任基础 = kernel 一个文件 + ML 类型检查器**。其他几百万行代码都不在信任基础里。

## 55.7 kernel 之外：oracles 与信任扩展

严格来说，Isabelle 的信任基础除了 kernel 还有一个小口子：**oracles**。Oracle 是一个"不经过推理就产 thm"的通道（如 `oracle` 声明、`skip_proof`、`sorry`）。用了 oracle 的定理在打印时会带上标记（`[oracle]` 或 `[sorry]`），提醒你这步没走 kernel。

这是有意的工程设计：有些场景（快速原型、教学演示）你需要"先假设它对，以后再补证"。但信任敏感的场景（如 seL4 内核验证）会扫描最终定理确保没有 oracle 标记。

```isabelle
ML ‹
  val oracle_thm = Skip_Proof.make_thm @{theory} @{prop "1 + 1 = (3::nat)"}
  val _ = writeln ("oracle 定理: " ^ @{make_string} (Thm.prop_of oracle_thm))
›
```

上面用 `Skip_Proof.make_thm` 造了一条假定理 `1 + 1 = 3`——这是**唯一**能"伪造" thm 的途径，而它本身也是一个 oracle（打印时会标记）。正常证明流程不会碰它。

## 55.8 与 41 章的接口

第 41 章讲了 `@{thm}` 反引号拿定理、`Proof_Context.get_thm` 按名查。本章讲的是这些 thm 的**底层结构**与**可靠性来源**。两条线合起来：

- 41 章：怎么用 ML 操作 thm（查、打印、传递）。
- 本章：thm 为什么可靠（kernel 把关 + 抽象类型）。
- 42 章：怎么写 tactic 产出新 thm（调 kernel 函数）。

---

## 本章坑位清单（实测）

1. `Thm.assume` 的参数是 `cterm`（certified term，带类型证书），不是 `term`。用 `@{cterm}` 反引号构造。
2. `Thm.assume` 要求 cterm 的类型是 `prop`（不是 `bool`）——HOL 命题要用 `Trueprop` 包装：`@{cterm "Trueprop A"}`。直接写 `@{cterm "A :: bool"}` 报 `assume: prop`。
3. `@{cterm}` 里的类型标注必须写全：写 `@{cterm "x"}` 会报 "Failed to parse term"——自由变量也要标类型。
4. `Thm.transitive` 操作的是 **meta-level equality**（`\<equiv>`，Pure.eq），不是 HOL 的 `=`。用 `=` 报 `transitive: premises`。
5. `Thm.transitive` 要求两个等式的中间项**完全相等**（不是可合一，是相等）。类型不同直接抛 `THM` 异常。
6. `Skip_Proof.make_thm` 造出的定理带 oracle 标记，不能参与正常证明——它会被 `Thm.check_hyps` 拒绝。
7. `Thm.hyps_of` 返回的是假设的**源码形式**（`term list`），不是 `cterm list`。要做 kernel 操作得重新 certity。

---

上一章：[54 · LCF 与 ML 的诞生](54-lcf-ml-history.md) ｜ 下一章：[56 · Isabelle 架构演进](56-isabelle-architecture.md) ｜ 返回：[README](../README.md)
