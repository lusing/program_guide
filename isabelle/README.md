# Isabelle/HOL 教程（Isabelle2025-2）

面向**会编程、初学证明助手**的读者：从"机器当裁判"的心智模型讲到项与类型、
数据类型、递归与归纳、化简器、Isar 证明语言，再到霍尔逻辑与编译器正确性
两个大案例，最后以工程组织、诊断方法与代码生成收束。

**章号 = 示例编号**——01–24 章每章对应 `examples/` 里一个经
`isabelle build` 构建通过、且两遍输出逐字节一致的 `.thy` 文件。

> 核心理念：**每个示例都是被机器逐条认可过的数学文本，不是"能跑就行"的程序。**
> 正文里出现的每一段输出都从 `build/` 产物里抽出，不是想象中的样子。
> 详见 [01 章](docs/01-overview.md)。

## 目录结构

```text
isabelle/
├── README.md        本文件
├── CHEATSheet.md    语法速查 + 实测坑位索引（240 条）
├── run-all.sh       验证脚本（bash）
├── docs/            24 章教程（01 → 24 顺序阅读）
├── examples/        24 个 .thy 示例 + ROOT（章号 = 示例编号）
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

学习路线：01–03 心智模型与基本材料 → 04–07 数据建模与化简 →
08–13 证明技法主线（自动化 / 逻辑 / 归纳 / Isar）→ 14–17 结构与方法论
→ 18–19 大案例 → 20–23 工程化 → 24 综合收束。

## 工具链

| 组件 | 值 |
|---|---|
| 发行版 | Isabelle2025-2 |
| 可执行文件 | `/Applications/Isabelle2025-2.app/bin/isabelle` |
| ML 系统 | polyml-5.9.2，`x86_64_32-darwin` |
| 会话 | `IsaTut`（见 `examples/ROOT`，父会话 `HOL`） |
| 交互前端 | `isabelle jedit`（随发行版自带） |

发行版自带预编译的 `Pure` / `HOL` 堆镜像，所以第一次 `build` 不需要
从源码重建 HOL，全量验证约 1–2 分钟。

## 验证命令

```bash
cd isabelle
./run-all.sh              # 全量：build + 两遍 process_theories + 逐字节比对
./run-all.sh T07_simp     # 只报告一个 theory（build/抽取仍全量）
./run-all.sh clean        # 清 build/ 下本脚本产物
```

**判定标准**（四关，全部通过才算过）：

1. `isabelle build -D examples` 退出码 0，且日志无 `FAILED` /
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

## 环境注意事项（本机实测）

- **构建库是 SQLite，写库要 `unlink` 掉 `-journal`**。本机 macOS 对 `~/`
  下未签名二进制的 `unlink` 返回 EPERM，于是报
  `[SQLITE_ERROR] cannot commit` / `[SQLITE_IOERR_DELETE]`。
  脚本的应对是**把 `USER_HOME` 指到 `/tmp` 下**——这是唯一有效的入口：
  `ISABELLE_HOME_USER` / `ISABELLE_HEAPS` 在 `etc/settings` 里是**无条件**
  赋值，靠环境变量改不动，但它们都由 `USER_HOME` 派生。
  若在受限沙箱里跑，还必须放开文件删除权限。
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
