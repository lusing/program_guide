# 56 · Isabelle 架构演进

对应示例：`../examples/T56_isabelle_architecture.thy`

## 56.1 一句话概括

54 章讲了 LCF 的谱系，55 章打开了 Isabelle 的 kernel。本章把视线拉到**系统架构**层面：Paulson 的"通用证明器"设计、Wenzel 的 Isar 声明式证明语言、以及现代 Isabelle 的并行工程基础设施。这三层加在一起，才构成今天这个能支撑 seL4 级别验证项目的系统。

## 56.2 Paulson 的洞察：一个证明器，多个逻辑

1986 年 Paulson 设计 Isabelle 时的核心洞察是：LCF 架构（极小内核 + 抽象类型 thm + 策略层）是**与具体逻辑无关的**。LCF 本身绑死了 Scott 的可计算函数逻辑，HOL 绑死了经典高阶逻辑——但 kernel 的机制（sequent 表示、推理规则即函数、类型系统把关）对任何直觉主义逻辑都适用。

Paulson 的赌注：写一个**通用逻辑框架**（Pure），让具体逻辑作为对象逻辑嵌入。Pure 提供：

- **项语言**：简单类型 λ 演算（第 49 章的 STLC 就是它的骨架）。
- **推理规则**：直觉主义自然演绎的极小集合（assume、implies_intr/elim、forall_intr/elim）。
- **合一**：高阶合一算法（Huet），用于规则匹配。

具体逻辑（HOL、FOL、ZF）通过**声明新常量、新公理**来定义。HOL 在 Pure 里声明类型 `bool`、常量 `Trueprop`（把 bool 提升为命题）、等式常量、选择算子，再加上几条公理——经典高阶逻辑就搭出来了。

这个设计的代价：Pure 的推理规则比 HOL 的需要更保守（直觉主义，不带排中律）。好处是**一条代码线支撑多个对象逻辑**——第 47 章的 FOL、第 48 章的 ZF 就是活证据。

## 56.3 Isar：从 tactic 脚本到声明式证明

LCF 传统（Cambridge LCF / HOL）的证明是**命令式脚本**：一串 tactic 调用，每步改写证明状态。这带来两个问题：

- **脆弱**：中间任何一步改了，后面全崩。
- **不可读**：脚本只告诉机器"下一步做什么"，不告诉读者"这一步为什么"。

Wenzel 1999 年的 Isar（Intelligible Semi-Automated Reasoning）把证明写成**结构化的声明式文本**：

- `fix` / `assume` / `show`：陈述局部上下文与目标。
- `have`：陈述中间结论。
- `by simp` / `by blast`：自动化策略填缝。

Isar 的关键洞察：**证明文本应该像数学证明一样可读**，机器检查只是副产品。这一设计让 Isabelle 证明可以直接进教科书（如《Concrete Semantics》），而 HOL Light 的 tactic 脚本做不到。

Isar 不是抛弃 tactic——`apply` 风格的 tactic 脚本仍然可用（第 8 章），Isar 只是在上面加了一层声明式语法。42 章的 `method_setup` 则是把自定义 tactic 接进 Isar 的桥梁。

## 56.4 现代架构：PIDE、并行与会话

2008 年后 Isabelle 经历了一次工程革命，核心是把**交互式开发**和**并行构建**做成一等公民。

**PIDE**（Prover IDE）：jEdit 前端（第 43 章）与 Isabelle 进程之间用异步协议通信。你敲键盘时 Isabelle 在后台持续解析、类型检查、证明——不需要"保存再编译"。状态栏实时显示当前命令的证明状态。VSCode 扩展（Isabelle/VSCode）也是同一协议。

**并行证明**：Isabelle 从 2011 年起支持命令级并行。一个 theory 文件里的独立命令（lemma、definition）可以并行执行——前提是它们之间没有依赖。这让多核机器能加速大型库构建。代价是输出顺序不确定——本教程的验证脚本关掉并行打印（`parallel_print=false`）就是为了可重复性。

**会话与堆**：Isabelle 的构建单位是**会话**（session，第 21 章）。一个会话编译出一棵 theory 依赖树，产出一个**堆镜像**（heap image）——ML 世界的序列化快照。后续会话可以加载父堆，避免重复构建。HOL 本身是一个堆，HOL-Eisbach、HOL-Library、HOL-Analysis 是它的扩展堆。本教程的四个会话（IsaTut、IsaTutLib、IsaTutFOL、IsaTutZF）各自加载不同的父堆。

## 56.5 信任基础的边界

把 55 章的信任分析扩展到整个系统：

- **内核**（`thm.ML`）：必须信任。
- **ML 类型检查器**（PolyML）：必须信任。
- **Isabelle/Scala**（jEdit 插件、构建工具）：不在信任基础里——它只影响用户体验，不影响定理正确性。
- **SMT 求解器**（cvc5、z3）：不在信任基础里——Sledgehammer 用它们找证明线索，但最终证明必须经 kernel 重放（第 32 章）。
- **Oracle**（`sorry`、`skip_proof`）：显式标记，信任敏感场景会扫描。

这条边界是 Isabelle 能用于高保证验证（seL4、CompCert、Flyspeck 级别的项目）的根本原因：**你需要审查的代码只有 kernel 那一个文件**。

## 56.6 与其他证明助手的架构对比

把 Isabelle 放进 2025 年的证明助手版图：

- **Coq**：kernel 是归纳演算（CIC），策略语言 Ltac 是独立的 DSL（不是 ML）。信任基础类似（一个小 kernel），但 Ltac 不在 ML 类型系统里，策略错误可能在运行时爆炸。
- **Lean 4**：kernel 是依赖类型 + 商，元语言是 Lean 本身（自举）。架构上更接近 Isabelle（声明式证明 + 极小 kernel），但元语言不是 ML。
- **HOL Light**：最纯的 LCF——kernel 只有几百行 OCaml，没有会话/堆概念，没有声明式证明语言。极简但难扩展。
- **Isabelle**：LCF 架构 + 通用逻辑框架 + 声明式证明 + 工程基础设施（PIDE、并行、会话）。功能最全，代码量也最大。

Isabelle 的独特之处在**通用逻辑框架**（Pure）：其他证明助手的 kernel 直接实现对象逻辑，Isabelle 的 kernel 实现一个元逻辑，对象逻辑是"用户级定义"。这让 Isabelle 能在一个系统里同时形式化一阶逻辑（第 47 章）、高阶逻辑（主线）和集合论（第 48 章）——其他系统做不到。

---

## 本章坑位清单（实测）

1. "Isabelle 是 HOL 家族"只对一半：Isabelle/HOL（本教程主线）确实是 HOL 家族，但 Isabelle 系统本身不是——它是通用框架。第 47 章的 FOL 和第 48 章的 ZF 也是 Isabelle。
2. Isar 的 `fix` / `assume` / `show` 不是 tactic——它们是**证明结构标记**，不调用 kernel。真正的 kernel 调用在 `by` 后面的方法里。
3. PIDE 的异步协议意味着你看到的"证明状态"可能滞后于输入——等状态栏变绿再信。
4. 并行构建时，输出顺序不确定是**设计行为**不是 bug。要可重复输出必须关 `parallel_print`（本教程 run-all.sh 的做法）。
5. 会话堆镜像（.heap 文件）是 ML 世界的序列化，跨平台不兼容——Windows 上构建的堆不能在 macOS 上加载。

---

上一章：[55 · de Bruijn 判据与 kernel](55-de-bruijn-kernel.md) ｜ 返回：[README](../README.md)
