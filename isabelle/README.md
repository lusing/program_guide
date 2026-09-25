# Isabelle/HOL 教程（Isabelle2025-2）

面向**会编程、初学证明助手**的读者：从"机器当裁判"的心智模型讲到项与类型、
数据类型、递归与归纳、化简器、Isar 证明语言，再到霍尔逻辑与编译器正确性
两个大案例，最后以工程组织、诊断方法与代码生成收束；附录六章补齐**类型类**
（`class`/`instantiation`）、**共归**（`codatatype`/`primcorec`）、
**Eisbach**（`method`/`match`）、**子集抽象**（`typedef`/`lift_definition`）、
**商类型**（`quotient_type`/`transfer`）与**序与格**（`Orderings`/`Lattices`）
六条 HOL 生态里最常见的进阶设施。

第二轮扩充（31–53 章）把 `G:\hol` 十六本手册的缺口逐一补上：
**手册覆盖篇 31–44**（归纳定义、Sledgehammer、Nitpick、嵌套/互斥
datatype、partial_function、corec 友元、codegen/locale/类进阶、
Main 库漫游、Isabelle/ML、tactic、jEdit/PIDE、文档生成）；
**库与对象逻辑篇 45–48**（HOL-Library 选讲、HOL-Analysis 入门、
FOL 一阶逻辑、ZF 集合论）；**数学原理篇 49–53**（λ 演算与 STLC
类型安全双定理、自然演绎、Knaster–Tarski 不动点、Newman 引理、
ε-δ 分析基础）——每条数学定理都在 Isabelle 里证出来，不是空谈。

**章号 = 示例编号**——01–53 章每章对应 `examples/`（及其会话子目录）
里一个经 `isabelle build` 构建通过、且两遍输出逐字节一致的 `.thy` 文件。

> 核心理念：**每个示例都是被机器逐条认可过的数学文本，不是"能跑就行"的程序。**
> 正文里出现的每一段输出都从 `build/` 产物里抽出，不是想象中的样子。
> 详见 [01 章](docs/01-overview.md)。

## 目录结构

```text
isabelle/
├── README.md        本文件
├── CHEATSheet.md    语法速查 + 实测坑位索引（300+ 条）
├── run-all.sh       验证脚本（bash）
├── docs/            30 章教程（01 → 30 顺序阅读）
├── examples/        30 个 .thy 示例 + ROOT（章号 = 示例编号）
└── build/           验证产物（build.log + 两遍输出，可删）
```

## 章节索引

| 章 | 主题 | 示例 |
|---|---|---|
| [01 开场：机器当裁判](docs/01-overview.md) | 心智模型、环境自检、ASCII 转义硬规则 | `T01_overview.thy` |
| [02 第一个理论](docs/02-first-theory.md) | 定义 / 命题 / 证明三件套 | `T02_first_theory.thy` |
| [03 项与类型](docs/03-terms-types.md) | nat/int、类型标注、`Main` 的边界 | `T03_terms_types.thy` |
| [04 数据类型](docs/04-datatype.md) | `datatype`、case、自动生成的定理 | `T04_datatype.thy` |
| [05 递归与终止性](docs/05-recursion.md) | `primrec` / `fun` / `function` / `partial_function` | `T05_recursion.thy` |
| [06 归纳](docs/06-induction.md) | 结构化归纳、`arbitrary:`、归纳假设泛化 | `T06_induction.thy` |
| [07 化简器](docs/07-simp.md) | `simp` 的方向性、`add`/`del`、`split` | `T07_simp.thy` |
| [08 自动化与两种风格](docs/08-auto-vs-isar.md) | apply 风格 vs Isar、缩进选目标 | `T08_auto_vs_isar.thy` |
| [09 逻辑规则手动档](docs/09-logic-rules.md) | `rule`/`erule`/`drule`、`intro`/`elim` | `T09_logic_rules.thy` |
| [10 列表库实战](docs/10-lists.md) | map/filter/fold/rev、重排三件套 | `T10_lists.thy` |
| [11 nat 算术](docs/11-arithmetic.md) | 截断减法、归纳与化简的配合 | `T11_arithmetic.thy` |
| [12 Isar 基础](docs/12-isar-basics.md) | have/show、moreover、also-finally | `T12_isar_basics.thy` |
| [13 Isar 进阶](docs/13-isar-advanced.md) | obtain / consider / subgoal / fix | `T13_isar_advanced.thy` |
| [14 集合](docs/14-sets.md) | 谓词即集合、`blast` 的领地 | `T14_sets.thy` |
| [15 关系与良基](docs/15-relations-wf.md) | 闭包归纳、`measure`、手写 `termination` | `T15_relations_wf.thy` |
| [16 函数定义深水区](docs/16-functions-deep.md) | 快排 / 欧几里得的终止性、结构递归改写 | `T16_functions_deep.thy` |
| [17 自动化的边界](docs/17-automation.md) | simp→metis 的代价阶梯、`find_theorems` | `T17_automation.thy` |
| [18 大案例：霍尔逻辑](docs/18-hoare.md) | IMP 语言、大步语义、五条 Hoare 规则 | `T18_hoare.thy` |
| [19 代码生成](docs/19-codegen.md) | 三种求值引擎、`[code]`、`export_code` | `T19_codegen.thy` |
| [20 Locale](docs/20-locales.md) | semigroup/monoid、`interpretation`、`sublocale` | `T20_locales.thy` |
| [21 会话与工程组织](docs/21-sessions.md) | ROOT、名字空间、bundle、属性增删 | `T21_sessions.thy` |
| [22 诊断](docs/22-diagnosis.md) | 打印开关、报错速查表 | `T22_diagnosis.thy` |
| [23 工程实践](docs/23-engineering.md) | 探索式证明 → 归档形式、裸 `context` | `T23_engineering.thy` |
| [24 综合案例：编译器](docs/24-capstone.md) | 栈机、`exec_compile`、常量折叠优化 | `T24_capstone.thy` |
| [25 类型类](docs/25-classes.md) | `class` / `instantiation` / 子类 / sort 约束 | `T25_classes.thy` |
| [26 共归与 codatatype](docs/26-codatatype.md) | `codatatype` / `primcorec` / 无限流与树 | `T26_codatatype.thy` |
| [27 Eisbach 方法 DSL](docs/27-eisbach.md) | `method` / `match premises` / `match conclusion` | `T27_eisbach.thy` |
| [28 抽象类型 typedef](docs/28-typedef.md) | `typedef` / `setup_lifting` / `lift_definition` | `T28_typedef.thy` |
| [29 商类型 quotient_type](docs/29-quotient.md) | `quotient_type` / `Quotient` / `transfer` | `T29_quotient.thy` |
| [30 序与格类层次](docs/30-order.md) | `Orderings` / `Lattices` / `mono` / `instantiation linorder` | `T30_order.thy` |
| [31 归纳定义](docs/31-inductive.md) | `inductive` / 规则归纳 / `intro!` 自爆点 | `T31_inductive.thy` |
| [32 Sledgehammer](docs/32-sledgehammer.md) | 命令不是方法 / 本地 E/cvc5/z3 / metis 与 smt | `T32_sledgehammer.thy` |
| [33 Nitpick](docs/33-nitpick.md) | `expect` 断言 / card 基数 / 反例优先工作流 | `T33_nitpick.thy` |
| [34 嵌套与互斥 datatype](docs/34-datatypes-deep.md) | BNF 白名单 / 互斥归纳 / 嵌套 size·map | `T34_datatypes_deep.thy` |
| [35 partial_function 深水](docs/35-partial-function.md) | 单方程铁律 / `raw_induct` / code 注册 | `T35_partial_function.thy` |
| [36 corec 友元](docs/36-corec-friends.md) | `corec` 三档 / friends / `corecursive` lfilter | `T36_corec_friends.thy`（Lib） |
| [37 代码生成进阶](docs/37-codegen-deep.md) | 三引擎 / `[code_unfold]` / `export_code` | `T37_codegen_deep.thy` |
| [38 Locale 进阶](docs/38-locales-deep.md) | locale 内定义 / `sublocale` 义务 / `interpret` | `T38_locales_deep.thy` |
| [39 类型类进阶](docs/39-classes-deep.md) | `overloading` / 非空义务实例 / sort 读法 | `T39_classes_deep.thy` |
| [40 Main 库漫游](docs/40-main-tour.md) | `∑`/`card`/`⇀`/`THE`/nibble 内幕 | `T40_main_tour.thy` |
| [41 Isabelle/ML 世界](docs/41-ml-world.md) | ML 块 / 反引号四件套 / 输出纪律 | `T41_ml_world.thy` |
| [42 tactic 与自定义方法](docs/42-tactics.md) | `resolve_tac` / `method_setup` / SUBGOAL | `T42_tactics.thy` |
| [43 jEdit 与系统工具](docs/43-system-jedit.md) | PIDE / 面板 / Windows Cygwin 三连坑 | `T43_system_jedit.thy` |
| [44 文档生成 sugar](docs/44-document-sugar.md) | 文档反引号 / markup / 会话文档 | `T44_document_sugar.thy` |
| [45 HOL-Library 选讲](docs/45-library-tour.md) | Multiset / Sublist / AList / while_option | `T45_library_tour.thy`（Lib） |
| [46 HOL-Analysis 入门](docs/46-analysis-intro.md) | 滤子 / 极限 / 连续 / DERIV / IVT | `T46_analysis_intro.thy` |
| [47 FOL 一阶逻辑](docs/47-fol.md) | IFOL/FOL / `P(x)` 函数式写法 / 量词手动挡 | `T47_fol.thy`（FOL） |
| [48 ZF 集合论](docs/48-zf.md) | 公理定理形态 / `Ord` / 超穷归纳 | `T48_zf.thy`（ZF） |
| [49 λ 演算与 STLC](docs/49-stlc.md) | de Bruijn / weakening / 进展+保持 | `T49_stlc.thy` |
| [50 自然演绎](docs/50-natded.md) | ND↔Isar / 导出规则兵器谱 / 经典等价链 | `T50_natded.thy` |
| [51 Knaster–Tarski](docs/51-fixpoints.md) | `lfp` 三刻画 / gfp 对偶 / 三首编曲 | `T51_fixpoints.thy` |
| [52 重写系统与 Newman](docs/52-rewrite-ars.md) | ARS locale / 强归纳过 trancl / 合流 | `T52_rewrite_ars.thy` |
| [53 ε-δ 分析基础](docs/53-epsilon-delta.md) | 裸 ε-N/ε-δ / 与滤子定义的等价 | `T53_epsilon_delta.thy` |

学习路线：01–03 心智模型与基本材料 → 04–07 数据建模与化简 →
08–13 证明技法主线（自动化 / 逻辑 / 归纳 / Isar）→ 14–17 结构与方法论
→ 18–19 大案例 → 20–23 工程化 → 24 综合收束 → 25–30 六个进阶专题
（类 / 共归 / Eisbach / typedef / quotient / Orderings+Lattices）。

## 工具链

| 组件 | 值 |
|---|---|
| 发行版 | Isabelle2025-2 |
| 可执行文件（Windows） | `G:\xulun3\isabelle\Isabelle2025-2\bin\isabelle`（**必须经自带 Cygwin**，见下） |
| 可执行文件（macOS） | `/Applications/Isabelle2025-2.app/bin/isabelle` |
| 可执行文件（Linux） | `/home/admin/hol/Isabelle2025-2/bin/isabelle`（本机 Ubuntu 22.04 实测路径） |
| ML 系统 | polyml-5.9.2，`x86_64_32-windows` / `x86_64_32-darwin` / `x86_64_32-linux` |
| 会话（四组） | `IsaTut`（HOL-Eisbach，examples/）/ `IsaTutLib`（HOL-Library，examples/lib/）/ `IsaTutFOL`（FOL，examples/fol/）/ `IsaTutZF`（ZF，examples/zf/）——一个裸会话独占一个目录 |
| 交互前端 | `isabelle jedit`（随发行版自带） |
| 本地 ATP/SAT | contrib 自带 `e-3.2` / `cvc5-1.2.0` / `z3-4.4.0pre` / `verit` / `minisat-2.2.1`（第 32/33 章全离线可用） |

发行版自带预编译的 `Pure` / `HOL` 堆镜像；`HOL-Eisbach` / `HOL-Library` /
`FOL` / `ZF` 四个堆需要现场构建一次（本机 Windows/Cygwin 实测：
Eisbach 27 秒、Library 约 3 分钟、FOL/ZF 各约 1 分钟），之后全部命中缓存。
`run-all.sh` 会按 `uname -s` 自选默认 `ISABELLE` 路径与重入方式；
显式覆盖用 `ISABELLE=/path/to/isabelle ./run-all.sh`。

**Windows 专行**（run-all.sh 已自动处理，手动操作时需知道）：
Git Bash 里直接跑 `bin/isabelle` 报
`Failed to determine hardware and operating system type!`——唯一正解是
经 `contrib/cygwin/bin/bash --login` 进入 Cygwin 世界，且登录 shell 里
`isabelle` 不在 PATH（用完整 `/cygdrive/.../bin/isabelle` 路径）。

## 验证命令

```bash
cd isabelle
./run-all.sh              # 全量：build + 两遍 process_theories + 逐字节比对
./run-all.sh T07_simp     # 只报告一个 theory（build/抽取仍全量）
./run-all.sh clean        # 清 build/ 下本脚本产物
```

**判定标准**（四关，全部通过才算过）：

1. `isabelle build -D examples` 退出码 0（四个会话：IsaTut 及其
   lib/fol/zf 子目录里的三个附加会话），且日志无 `FAILED` /
   `Unfinished session` / `^\*\*\*`——Isabelle/Scala 工具失败不一定让
   进程退出码非 0，必须查日志；
2. `process_theories -O` 抽出的 `==== NN 开始 ====` / `==== NN 结束 ====`
   区间标记齐全、非空、无控制字符、无溃逃痕迹；
3. 同一命令连跑两遍；
4. 区间逐字节一致。

第 4 关值得解释：其他语言项目可以拿两个引擎（或两种二进制）互相比对，
**Isabelle 只有一个引擎**，没有"跨通道一致性"可比。于是用"运行间确定性"
替代——两次输出不一样就说明示例依赖了并行调度、随机源或环境状态，
那本身就是 bug。实测这一步抓到过真问题：默认开启 `parallel_print` 时，
24 个示例里有 12 个两次运行的消息顺序不同；关掉并行打印后差异归零。

## 环境注意事项（Windows/Cygwin + Linux + macOS 三端实测）

- **SQLite 构建库与 `-journal` 清理**：写库时要 `unlink` 掉 `-journal`。
  Linux 下普通权限就能删；macOS 本机对 `~/` 下未签名二进制的 `unlink`
  返回 EPERM，于是报 `[SQLITE_ERROR] cannot commit` / `[SQLITE_IOERR_DELETE]`。
  脚本的应对是**把 `USER_HOME` 指到 `/tmp` 下**——两平台都受益（隔离产物
  与 `~/.isabelle`），macOS 上更是必需。之所以改 `USER_HOME` 而不是
  直接改 `ISABELLE_HOME_USER` / `ISABELLE_HEAPS`：它们在 `etc/settings`
  里是**无条件**赋值，靠环境变量改不动，但都由 `USER_HOME` 派生。
- **控制字符检查用 POSIX `[[:cntrl:]]`**：曾经写的是 `[^[:print:][:space:]]`，
  Linux 的 `LC_ALL=C` 下 `[:print:]` 只覆盖 ASCII，示例标记里的中文
  `==== 01 开始 ====` 会被误判为"含控制字符"，24 个 theory 全错。
  `[[:cntrl:]]` 两平台语义一致，只匹配 0x00–0x1F / 0x7F。
- **源文件一律 ASCII 转义**：分隔符写 `\<open>` `\<close>`，项里写
  `\<forall>` `\<in>` `\<longrightarrow>`。字面 `‹ › ∀` 会被拒（第 1 章
  有实测边界表）。
- **常量名不能用 `ALL EX SUM PROD INT UN INF SUP`**：词法层整词替换成符号，
  报 `Failed to parse prop` 且位置指向 RHS（第 18 章）。

## 示例怎么读

- **章号 = 示例编号**：`docs/07-simp.md` ↔ `examples/T07_simp.thy`，
  每章开头一行"对应示例"标注。
- 示例是**扁平**放在 `examples/` 下的（不做 `NN_topic/` 子目录），
  因为 `process_theories -D` 的临时 Draft 会话要求扁平布局。
- 每章末尾有 10 条"本章坑位清单"（共 240 条），
  `CHEATSheet.md` 按症状重新索引了一遍。
- 改示例后重跑：`./run-all.sh T18_hoare`。

## 相关教程

同为证明助手：[coq](../coq/README.md)、[lean4](../lean4/README.md)、
[agda](../agda/README.md)；ML 系函数式对照
[haskell](../haskell/README.md)、[ocaml](../ocaml/README.md)。
