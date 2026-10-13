theory T55_de_bruijn_kernel
  imports Main
begin

text \<open>54 章讲了 LCF 的架构思想：极小内核 + 抽象类型 thm +
策略层自由组合。本章打开 Isabelle 的真实 kernel，
看这三条是如何具体落实的。重点是**理解为什么这套设计
能担保可靠性**，而不是学新证明技巧。\<close>

ML \<open>writeln "==== 55 开始 ===="\<close>

subsection \<open>55.1 de Bruijn 判据的三条要求\<close>

text \<open>de Bruijn 判据（第 54 章）说一个证明检查器值得信任
当且仅当：

  1. **内核极小**：只有一小段代码说"这一步对"。
  2. **类型即命题**：命题是类型，证明是该类型的项。
  3. **无特殊信任假设**：除了内核和类型检查器，
     不需要信任任何其他组件。

Isabelle 的落实方式：

  - 第 1 条：kernel 是 @{verbatim "src/Pure/thm.ML"} 一个文件，
    推理规则是 @{verbatim "Thm"} 结构体里十几个函数。
    整个 Isabelle 发行版（1467 个 .thy、几百万行 ML/Scala）
    的可靠性都压在这一个文件上。
  - 第 2 条：Isabelle 的命题是 @{verbatim "term"} 类型
    （高阶逻辑的语法树），证明是 @{verbatim "thm"} 类型
    （sequent：假设 + 结论 + 约束）。@{verbatim "thm"}
    是 ML 抽象类型——它的值**只能**通过 kernel 函数构造。
  - 第 3 条：策略层（simp、blast、auto、metis……）
    产出的每个 @{verbatim "thm"} 都经过了 kernel 函数的
    类型检查。策略有 bug 不会导致"假定理"——最多导致
    "证不出来"或"证错目标"，但产出物永远是真定理。\<close>

subsection \<open>55.2 thm 的底层表示：sequent\<close>

text \<open>在 ML 里，@{verbatim "thm"} 的底层表示是一个 record
（sequent）：

  - @{verbatim "prop"}：结论（一个 @{verbatim "term"}）
  - @{verbatim "hyps"}：假设列表（被 @{verbatim "assume"}
    引入的命题）
  - @{verbatim "tpairs"}：flex-flex 约束对（高阶合一的
    残留物，通常为空）
  - @{verbatim "shyps"}：排序假设（类型类的假设，通常为空）

用 ML 拿一条真实定理拆开看（实测）：\<close>

lemma demo_thm: "A \<Longrightarrow> B \<Longrightarrow> A \<and> B"
  by blast

ML \<open>
  val th = @{thm demo_thm}
  val _ = writeln ("prop = " ^ @{make_string} (Thm.prop_of th))
  val _ = writeln ("hyps = " ^ @{make_string} (Thm.hyps_of th))
  val _ = writeln ("nprems = " ^ string_of_int (Thm.nprems_of th))
\<close>

text \<open>注意 @{verbatim "hyps"} 是空列表——因为
@{verbatim "A \<Longrightarrow> B \<Longrightarrow> A \<and> B"} 里的
A、B 是**自由变量**（元变量），不是假设。
真正的假设要用 @{verbatim "Thm.assume"} 引入，
见 55.3。\<close>

subsection \<open>55.3 推理规则即 ML 函数：kernel 实战\<close>

text \<open>现在用 kernel 函数从零构造一条定理。目标：证
@{verbatim "A \<Longrightarrow> A"}（同一律）。步骤：

  1. @{verbatim "Thm.assume"}：引入假设 A，得到 thm
     @{verbatim "A \<turnstile> A"}。
  2. @{verbatim "Thm.implies_intr"}：把假设 A 变成
     前件，得到 @{verbatim "\<turnstile> A \<Longrightarrow> A"}。

每一步都是一个 kernel 函数调用，ML 类型系统保证
没有别的路可以造出 @{verbatim "thm"}。\<close>

ML \<open>
  val ctxt = @{context}
  val a = @{cterm "Trueprop A"}
  val th1 = Thm.assume a
  val _ = writeln ("assume 后: " ^ @{make_string} (Thm.prop_of th1))
  val _ = writeln ("hyps = " ^ @{make_string} (Thm.hyps_of th1))
  val th2 = Thm.implies_intr a th1
  val _ = writeln ("implies_intr 后: " ^ @{make_string} (Thm.prop_of th2))
  val _ = writeln ("hyps = " ^ @{make_string} (Thm.hyps_of th2))
\<close>

text \<open>输出里能清楚看到 sequent 的变化：

  - @{verbatim "assume"} 后：prop 是 @{verbatim "A"}，
    hyps 是 @{verbatim "[A]"}——假设里有一条 A。
  - @{verbatim "implies_intr"} 后：prop 变成
    @{verbatim "A \<longrightarrow> A"}（源码形式
    @{verbatim "A \<Longrightarrow> A"}），hyps 清空。

这就是 LCF 的核心机制：**thm 的构造过程就是 sequent 的
变换过程**，每个变换对应一条推理规则，ML 类型系统
保证变换合法。\<close>

subsection \<open>55.5 复合规则：transitive 与 meta-equality\<close>

text \<open>再来一个稍复杂的例子：用等式传递性
@{verbatim "Thm.transitive"} 把
@{verbatim "x \<equiv> y"} 和 @{verbatim "y \<equiv> z"} 串成
@{verbatim "x \<equiv> z"}。注意这里用的是
**meta-level equality**（@{verbatim "\<equiv>"}, Pure.eq），
不是 HOL 的 @{verbatim "="}——@{verbatim "Thm.transitive"}
是 Pure 层的规则。\<close>

ML \<open>
  val x = @{cterm "x :: 'a"}
  val y = @{cterm "y :: 'a"}
  val z = @{cterm "z :: 'a"}
  val xy = Thm.assume @{cterm "x \<equiv> (y::'a)"}
  val yz = Thm.assume @{cterm "y \<equiv> (z::'a)"}
  val xz = Thm.transitive xy yz
  val _ = writeln ("transitive: " ^ @{make_string} (Thm.prop_of xz))
  val _ = writeln ("hyps = " ^ @{make_string} (Thm.hyps_of xz))
\<close>

text \<open>注意 hyps 里有两条假设（@{verbatim "x = y"} 和
@{verbatim "y = z"}），它们还没被 @{verbatim "implies_intr"}
消掉。这展示了 sequent 的精髓：**定理不是"裸命题"，
而是"在某些假设下命题成立"**。\<close>

subsection \<open>55.5 为什么策略层不可能伪造定理\<close>

text \<open>上面看到的 @{verbatim "Thm.assume"}、
@{verbatim "Thm.implies_intr"}、@{verbatim "Thm.transitive"}
都是 @{verbatim "Thm"} 结构体的导出函数。
@{verbatim "thm"} 类型在 ML 里是抽象的——
**没有构造器暴露给外部代码**。

这意味着：

  - 用户 ML 代码不能写 @{verbatim "Thm.Thm (...)"}
    来"手工造"一个 thm——类型系统拒绝。
  - 唯一的"造 thm"途径就是调 kernel 函数。
  - 每个 kernel 函数对应一条逻辑上合法的推理规则。

所以 simp、blast、auto、metis、Sledgehammer……
这些策略无论多复杂，它们产出的每个 thm 都经过了
kernel 函数的把关。策略有 bug 的后果是"证不出"
或"证错目标"，但**绝不会**产出假定理——
因为假定理过不了 kernel 的类型检查。

这就是 LCF 架构的可靠性担保：**信任基础 =
kernel 一个文件 + ML 类型检查器**。
其他几百万行代码都不在信任基础里。\<close>

subsection \<open>55.6 kernel 之外：oracles 与信任扩展\<close>

text \<open>严格来说，Isabelle 的信任基础除了 kernel
还有一个小口子：**oracles**。oracle 是一个
"不经过推理就产 thm"的通道（如 @{verbatim "oracle"}
声明、@{verbatim "skip_proof"}、
@{verbatim "sorry"}）。用了 oracle 的定理在
打印时会带上标记（@{verbatim "[oracle]"} 或
@{verbatim "[sorry]"}），提醒你这步没走 kernel。

这是有意的工程设计：有些场景（快速原型、
教学演示）你需要"先假设它对，以后再补证"。
但信任敏感的场景（如 seL4 内核验证）会扫描
最终定理确保没有 oracle 标记。\<close>

ML \<open>
  val oracle_thm = Skip_Proof.make_thm @{theory} @{prop "1 + 1 = (3::nat)"}
  val _ = writeln ("oracle 定理: " ^ @{make_string} (Thm.prop_of oracle_thm))
\<close>

text \<open>上面用 @{verbatim "Skip_Proof.make_thm"} 造了
一条假定理 @{verbatim "1 + 1 = 3"}——这是
**唯一**能"伪造" thm 的途径，而它本身也是
一个 oracle（打印时会标记）。正常证明流程
不会碰它。\<close>

subsection \<open>55.7 与 41 章的接口\<close>

text \<open>第 41 章讲了 @{verbatim "@{thm}"} 反引号
拿定理、@{verbatim "Proof_Context.get_thm"} 按名查。
本章讲的是这些 thm 的**底层结构**与**可靠性来源**。
两条线合起来：

  - 41 章：怎么用 ML 操作 thm（查、打印、传递）。
  - 本章：thm 为什么可靠（kernel 把关 + 抽象类型）。
  - 42 章：怎么写 tactic 产出新 thm（调 kernel 函数）。\<close>

subsection \<open>55.8 坑位清单（实测）\<close>

text \<open>1. @{verbatim "Thm.assume"} 的参数是
   @{verbatim "cterm"}（certified term，带类型证书），
   不是 @{verbatim "term"}。用 @{verbatim "@{cterm}"}
   反引号构造。
2. @{verbatim "Thm.assume"} 要求 cterm 的类型是
   @{verbatim "prop"}（不是 @{verbatim "bool"}）——
   HOL 命题要用 @{verbatim "Trueprop"} 包装：
   @{verbatim "@{cterm \"Trueprop A\"}"}。
   直接写 @{verbatim "@{cterm \"A :: bool\"}"} 报
   @{verbatim "assume: prop"}。
3. @{verbatim "@{cterm}"} 里的类型标注必须写全：
   写 @{verbatim "@{cterm \"x\""}} 会报
   "Failed to parse term"——自由变量也要标类型。
4. @{verbatim "Thm.transitive"} 操作的是
   **meta-level equality**（@{verbatim "\<equiv>"},
   Pure.eq），不是 HOL 的 @{verbatim "="}。
   用 @{verbatim "="} 报 @{verbatim "transitive: premises"}。
5. @{verbatim "Thm.transitive"} 要求两个等式的
   中间项**完全相等**（不是可合一，是相等）。
   类型不同直接抛 @{verbatim "THM"} 异常。
6. @{verbatim "Skip_Proof.make_thm"} 造出的定理
   带 oracle 标记，不能参与正常证明——它会被
   @{verbatim "Thm.check_hyps"} 拒绝。
7. @{verbatim "Thm.hyps_of"} 返回的是假设的
   **源码形式**（@{verbatim "term list"}），
   不是 @{verbatim "cterm list"}。要做 kernel
   操作得重新 certity。\<close>

ML \<open>writeln "==== 55 结束 ===="\<close>

end
