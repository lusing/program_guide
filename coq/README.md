# Coq 教程（Rocq 9.1/9.2/9.3）

面向**会编程（任意语言背景）、初学 Coq** 的读者：从证明助手的心智模型讲到
类型系统、归纳类型、tactic 证明技法，再到 AST 求值器、插入排序正确性、
列表定律等证明实战，继而是依赖类型、余归纳、一般递归、自反证明四大进阶
主题与综合项目**表达式解释器与优化器**，最后进入三大篇：**验证算法篇**
（33–47 章，VFA 卷）、**语言理论篇**（48–67 章，PLF 卷）与**分离逻辑篇**
（93–105 章，SLF 卷）。分离逻辑篇从堆谓词与三元组出发，逐步构造最弱前条件
生成器并证明其可靠性，最后验证数组、快速排序与记录操作。
**章号 = 示例编号**——除无独立示例的汇总章外，各章对应 `examples/` 里一个经
`rocq compile` 编译验证的完整 .v 文件，84 章为 100+ 条实测坑位总清单。

> 核心理念：**类型即命题，程序即证明。** Coq 把"写代码"和"证定理"变成
> 同一种语言里的同一件事——编译通过就是定理成立；详见
> [01 章](docs/01-intro.md) 与 [84 章](docs/84-pitfalls.md)。

## 目录结构

```text
coq/
├── README.md        本文件
├── build.ps1        编译验证脚本（PowerShell）
├── build.sh         编译验证脚本（macOS / Linux，用法同 build.ps1）
├── docs/            90 篇教程（按章号组织，部分章号空缺）
├── examples/        91 个 .v 示例（章号 = 示例编号，部分章号空缺）
├── tools/           文档核查脚本（check_docs_coverage.py）
└── build/           编译输出（已 gitignore）
```

## 章节索引

| 章 | 主题 | 示例 |
|---|---|---|
| [01 认识 Coq](docs/01-intro.md) | Coq 是什么、Check / Compute 与第一个证明 | `01_intro.v` |
| [02 工具链与运行方式](docs/02-toolchain.md) | rocq/coqc/coqtop、问询四件套、Coq→Rocq 更名史 | `02_toolchain.v` |
| [03 第一个证明](docs/03-first-proof.md) | Proof-Qed 解剖、Fail、Abort | `03_first_proof.v` |
| [04 类型系统](docs/04-types.md) | nat 真身、sorts、多态与隐式参数 | `04_types.v` |
| [05 表达式与运算符](docs/05-expressions.md) | 记号、nat 算术坑、if 真身、%Z | `05_expressions.v` |
| [06 元组与记录](docs/06-tuples-records.md) | 积类型、Record、字段名坑 | `06_tuples_records.v` |
| [07 模式匹配](docs/07-patterns.md) | match 词汇表、穷尽 / 冗余分支 | `07_patterns.v` |
| [08 列表](docs/08-lists.md) | list 操作、fold 方向与参数序坑 | `08_lists.v` |
| [09 归纳类型：自定义数据](docs/09-inductive.md) | 枚举、自造 bool/nat、二叉树 | `09_inductive.v` |
| [10 递归函数：Fixpoint 与终止性](docs/10-fixpoint.md) | 结构递归、守卫检查实测边界 | `10_fixpoint.v` |
| [11 证明状态与 tactic 机理](docs/11-proof-state.md) | 证明状态演变、apply / exact | `11_proof_state.v` |
| [12 归纳证明](docs/12-induction.md) | 归纳剧本四例（nat / list） | `12_induction.v` |
| [13 重写、化简与分情况讨论](docs/13-rewrite.md) | rewrite 方向学、destruct、discriminate | `13_rewrite.v` |
| [14 命题逻辑](docs/14-logic.md) | /\ \/ -> ~ iff 与子弹层级 | `14_logic.v` |
| [15 谓词逻辑与 reflect](docs/15-predicates.md) | 归纳谓词、exists、强化、reflect | `15_predicates.v` |
| [16 高阶函数及其证明](docs/16-higher-order.md) | map 定律、filter 幂等 | `16_higher_order.v` |
| [17 Option：安全建模](docs/17-option.md) | option 建模、bind 链、定律 | `17_option.v` |
| [18 策略武器库与模块](docs/18-tactics-modules.md) | auto / assert、模块签名封装 | `18_tactics_modules.v` |
| [19 Ltac：自定义策略](docs/19-ltac.md) | 参数 / 递归 / match goal / fail n / Hint | `19_ltac.v` |
| [20 决策过程](docs/20-decision.md) | ring / lia / nia / field / lra / tauto | `20_decision.v` |
| [21 表达式求值器：AST 入门](docs/21-ast.md) | aexp 求值器 + 优化器正确性 | `21_ast.v` |
| [22 列表定律证明实战](docs/22-list-laws.md) | 六条列表定律 + rev_acc 强化 | `22_list_laws.v` |
| [23 插入排序与正确性证明](docs/23-sorting.md) | 插入排序 + 有序 / 重排双正确性 | `23_sorting.v` |
| [24 数值专题：nat、N 与 Z](docs/24-numbers.md) | nat/N/Z、lia、作用域坑 | `24_numbers.v` |
| [25 测试与断言风格](docs/25-testing.md) | Example 即测试、Print Assumptions | `25_testing.v` |
| [26 依赖类型与强规范](docs/26-dependent.md) | vect、sig/sumbool、Defined vs Qed | `26_dependent.v` |
| [27 互归纳：树与森林](docs/27-mutual.md) | Scheme、嵌套 fix、正性约束 | `27_mutual.v` |
| [28 二叉搜索树实战](docs/28-bst.md) | 谓词建模、引理库、剪枝查找 | `28_bst.v` |
| [29 余归纳与无限数据](docs/29-coinductive.md) | CoFixpoint、guard、互模拟 | `29_coinductive.v` |
| [30 一般递归](docs/30-general-recursion.md) | 燃料、良基递归、Program Fixpoint | `30_general_recursion.v` |
| [31 自反证明](docs/31-reflection.md) | 判定函数 + 桥定理、flatten 规格化 | `31_reflection.v` |
| [32 综合实战：表达式解释器与优化器](docs/32-project.md) | 解释器 + 双 pass 流水线 + Extraction | `32_project.v` |
| [33 置换与排序推理](docs/33-perm.md) | lia 边界、reflect 案例分析、Permutation 代数 | `33_perm.v` |
| [34 插入排序与规格模式](docs/34-sort.md) | sorted+Permutation 双规格 | `34_sort.v` |
| [35 选择排序：燃料与 measure](docs/35-selection.md) | fuel、Function measure 递归 | `35_selection.v` |
| [36 归并排序：终止性递归](docs/36-merge.md) | split/merge/mergesort | `36_merge.v` |
| [37 多重集：另一种规格风格](docs/37-multiset.md) | bag/union、Permutation 互译 | `37_multiset.v` |
| [38 可判定规格](docs/38-decide.md) | 可判定 vs 存在式规格 | `38_decide.v` |
| [39 二叉搜索树的验证](docs/39-searchtree.md) | 抽象函数规格、insert/lookup | `39_searchtree.v` |
| [40 抽取：把验证代码变成 OCaml](docs/40-extract.md) | Recursive Extraction 实战 | `40_extract.v` |
| [41 红黑树](docs/41-redblack.md) | 平衡不变量、insert 正确性 | `41_redblack.v` |
| [42 抽象数据类型](docs/42-adt.md) | Module Type、多实现 TABLE | `42_adt.v` |
| [43 优先队列](docs/43-priqueue.md) | PRIQUEUE 接口与实现 | `43_priqueue.v` |
| [44 二项式堆](docs/44-binom.md) | binomial heap | `44_binom.v` |
| [45 Trie：字符串键的映射](docs/45-trie.md) | positive 编码、trie 操作 | `45_trie.v` |
| [46 Bag 与置换的代数](docs/46-bagperm.md) | bag 公理化、与 Permutation 互推 | `46_bagperm.v` |
| [47 四色定理](docs/47-color.md) | 五色定理证明工程 | `47_color.v` |
| [48 映射：把函数当数据结构](docs/48-maps.md) | total_map、`!->` 记号、更新引理 | `48_maps.v` |
| [49 证明即项：Curry–Howard 落地](docs/49-proof-terms.md) | 证明项、`IndProp` 的另一面 | `49_proof_terms.v` |
| [50 归纳原则解剖](docs/50-induction-principles.md) | `Print ... _ind`、一般化归纳 | `50_induction_principles.v` |
| [51 关系、闭包与确定性](docs/51-relations.md) | 偏函数/等价/序、自反传递闭包 | `51_relations.v` |
| [52 自定义记号与语法](docs/52-notation.md) | Coercion、Custom Entry、level 阶梯 | `52_notation.v` |
| [53 Imp：状态、命令与大步语义](docs/53-imp-semantics.md) | state、com、ceval 七规则、栈机 | `53_imp_semantics.v` |
| [54 燃料求值器：把关系变回函数](docs/54-fuel-evaluation.md) | ceval_step、与 ceval 的等价 | `54_fuel_evaluation.v` |
| [55 小步语义：执行即关系](docs/55-smallstep.md) | step/multi、大小步等价、star | `55_smallstep.v` |
| [56 行为等价：程序何时相同](docs/56-equiv.md) | aeval/beval 等价、确定性、常量折叠与优化正确性 | `56_equiv.v` |
| [57 词法与语法解析](docs/57-parsing.md) | 正则匹配、tokenize、解析组合子 | `57_parsing.v` |
| [58 Hoare 逻辑](docs/58-hoare.md) | 三元组、七条规则、循环不变量 | `58_hoare.v` |
| [59 装饰程序：不变量的寻找法](docs/59-decorated.md) | 验证条件生成、装饰命令、自动化 | `59_decorated.v` |
| [60 霍尔逻辑作为逻辑](docs/60-hoare-logic.md) | 三元组的归纳定义、有效性 | `60_hoare_logic.v` |
| [61 自动化工程：evar 搜索与 hint 数据库](docs/61-automation.md) | auto/eauto、hint 数据库 | `61_automation.v` |
| [62 简单类型 λ 演算](docs/62-stlc.md) | STLC、progress、preservation | `62_stlc.v` |
| [63 类型检查算法](docs/63-typechecking.md) | type_check 函数与正确性 | `63_typechecking.v` |
| [64 子类型](docs/64-subtyping.md) | 宽度/深度子类型、包含、Records | `64_subtyping.v` |
| [65 STLC 规范化](docs/65-normalization.md) | 良类型 ⟹ 强终止、Cantor 式归纳 | `65_normalization.v` |
| [67 引用与副作用](docs/67-references.md) | store、位置类型、引用安全 | `67_references.v` |
| [84 坑清单与最佳实践](docs/84-pitfalls.md) | 110+ 条实测坑位与最佳实践总清单 | — |
| [85 属性测试入门：QuickChick](docs/85-quickstart.md) | PBT 定位、removeP 反例与收缩、四要素 | `85_quickstart.v` |
| [86 类型类机制](docs/86-typeclasses.md) | Class/Instance、隐式推广、实例搜索、Monad | `86_typeclasses.v` |
| [87 随机生成器：G 单子](docs/87-generators.md) | returnGen/bind、choose、尺寸燃料、freq | `87_generators.v` |
| [88 可检查性质与收缩](docs/88-checkers.md) | Checker/Checkable、forAll、贪心收缩、collect | `88_checkers.v` |
| [89 条件性质与按规格生成](docs/89-conditional.md) | `==>` 与 discard 风暴、genSortedList、BST | `89_conditional.v` |
| [90 QCDerive 自动派生](docs/90-deriving.md) | Show/Arbitrary/Shrink/SuchThat/DecOpt 派生 | `90_deriving.v` |
| [91 案例：带类型的 Imp 的程序生成](docs/91-timp.md) | 按类型生成、backtrack、类型保持收缩 | `91_timp.v` |
| [92 quickchick 命令行与变异测试](docs/92-cli.md) | `(*! *)` 注解、变异测试、mutant 生死 | `92_cli.v` |
| [93 分离逻辑入门](docs/93-slf-basic.md) | 三元组、堆规格与 x-tactics | `93_slf_basic.v` |
| [94 表示谓词](docs/94-slf-repr.md) | 链表、树、栈与计数器的堆表示 | `94_slf_repr.v` |
| [95 堆谓词](docs/95-slf-hprop.md) | 分离合取、纯事实、存在量词与堆语义 | `95_slf_hprop.v` |
| [96 堆蕴含](docs/96-slf-himpl.md) | `==>`、推理引理与 xsimpl 自动化 | `96_slf_himpl.v` |
| [97 三元组](docs/97-slf-triples.md) | Hoare 三元组语义、定义与结构规则 | `97_slf_triples.v` |
| [98 推理规则](docs/98-slf-rules.md) | 语言构件、原语规格与手工验证 | `98_slf_rules.v` |
| [99 魔法杖](docs/99-slf-wand.md) | hwand、qwand 与分支框架规则 | `99_slf_wand.v` |
| [100 最弱前条件语义](docs/100-slf-wpsem.md) | wp 的语义、结构规则与 Texan 三元组 | `100_slf_wpsem.v` |
| [101 最弱前条件生成器](docs/101-slf-wpgen.md) | wpgen、公式化简与 x-tactics 构造 | `101_slf_wpgen.v` |
| [102 wpgen 可靠性](docs/102-slf-wpsound.md) | 生成器语义正确性与自动化可靠性证明 | `102_slf_wpsound.v` |
| [103 仿射分离逻辑](docs/103-slf-affine.md) | 可丢弃资源、仿射三元组与 `\GC` | `103_slf_affine.v` |
| [104 数组分离逻辑](docs/104-slf-arrays.md) | 数组区间、聚焦、借用与快速排序验证 | `104_slf_arrays.v` |
| [105 记录分离逻辑](docs/105-slf-records.md) | 字段布局、三层访问规格与记录分配 | `105_slf_records.v` |

学习路线：01–05 语言与基本证明 → 06–10 数据建模（元组/匹配/列表/归纳/
递归）→ 11–15 证明技法主线（归纳/重写/逻辑）→ 16–18 高阶与工程化 →
**19–20 自动化双章（Ltac 与决策过程）** → 21–25 实战递进（AST → 列表定律
→ 排序 → 数值 → 测试）→ **26–31 进阶四重奏（依赖类型 → 互归纳 → BST →
余归纳 → 一般递归 → 自反证明）** → 32 综合项目收束 → **33–47 验证算法篇（VFA：置换 → 排序规格 → 选择/归并 →
多重集 → 可判定 → BST → 抽取 → 红黑树 → ADT → 优先队列 → 二项式堆 →
Trie → Bag → 四色）** → **48–67 语言理论篇（映射 → 归纳原则 → 关系 → 记号 →
Imp 三种语义 → 行为等价 → 解析 → Hoare 三连 → 自动化 → STLC → 类型检查 →
子类型 → 规范化 → 引用）** → 84 坑清单（写代码前先查）→ **85–92 属性测试篇
（QuickChick：入门 → 类型类 → 生成器 → 检查器与收缩 → 条件性质 → 自动派生
→ TImp 案例 → 命令行与变异测试）** → **93–105 分离逻辑篇（SLF：三元组 →
表示谓词 → 堆谓词与蕴含 → 推理规则 → 魔法杖 → 最弱前条件 → wpgen 与可靠性 →
仿射逻辑 → 数组 → 记录）**。

19–20 与 26–31 八章为 2026-09 按经典教材《交互式定理证明与程序开发：
Coq 归纳构造演算的艺术》（Bertot & Casteran，中译本）扩充的「书本篇」；
33–47 章为 2026-10 按 _Software Foundations_ 第三卷 _Verified Functional
Algorithms_ 扩充的「验证算法篇」；48–67 章为 2026-10 按 _Software
Foundations_（LF 卷 + PLF 卷精选）扩充的「语言理论篇」；85–92 章为 2026-10
按 _Software Foundations_ 第四卷 _QuickChick: Property-Based Testing in
Rocq_（v2.1）扩充的「属性测试篇」（QuickChick 2.2.0，`Derive` 已更名
`QCDerive`，测试命令置于模块外执行）；93–105 章为 2026-10 按 _Software
Foundations_ 第六卷 _Separation Logic Foundations_（v1.0）扩充的「分离逻辑篇」。
各部分内容均已自包含提炼，无需翻阅原书。2026-10 起全书按
[Rocq 9.2.0 参考手册](https://rocq-prover.org/doc/V9.2.0/refman/index.html)
校准，主体以 rocq 9.3.0 + stdlib 9.2.0 实测复验（早期环境为 Coq 8.20.1）；
属性测试篇以 rocq 9.1.1 + QuickChick 2.2.0 实测，分离逻辑篇以 rocq 9.1.1
和项目内 `lib/slf/` 库实测。

## 工具链

| 组件 | 路径 / 版本 |
|---|---|
| prover（本教程实测环境，macOS + opam） | rocq 9.3.0（`opam install rocq-prover`，rocq-core 9.3.0）/ stdlib 9.2.0 |
| 分离逻辑篇 | rocq 9.1.1 + 项目内 `lib/slf/` 库（示例使用 `@slf` 构建标志） |
| Windows | Rocq Platform 2026.07.0（2026-07-30 版，主配 Rocq 9.1，可选 8.12.2–8.20.1 与 9.0） |
| 编译器入口 | `rocq compile`（兼容名 coqc） |
| 交互顶层 | `rocq repl`（兼容名 coqtop） |

2024 年 Coq 更名 **Rocq**；9.0 起标准库命名空间 `Coq.*` → `Stdlib.*`
（前言库进一步拆出 `Corelib.*`），本教程全部示例已按 9.x 写法
（`From Stdlib Require Import ...`）验证。

## 验证命令

```powershell
cd coq
.\build.ps1 -All                        # 复制到 build/ 加 ex_ 前缀逐个 rocq compile 编译
.\build.ps1 -File 03_first_proof.v      # 单文件编译验证
.\build.ps1 -Clean                      # 清理 build/
```

macOS / Linux 下用等价的 bash 脚本（用法一致）：

```bash
cd coq
chmod +x build.sh
./build.sh -All                        # 复制到 build/ 加 ex_ 前缀逐个 rocq compile 编译
./build.sh -File 03_first_proof.v      # 单文件编译验证
./build.sh -Clean                      # 清理 build/
```

**判定标准**：全部 91 个示例 `rocq compile` 退出码 0，且不新增告警；
对纳入覆盖关卡的章节运行 `python3 tools/check_docs_coverage.py NN --mutate`，
其中分离逻辑篇 93–105 章必须逐章报 `missing 0` 且 `mutate check ok`
（正文必须引用示例的每一行非空内容，包括中文注释；01–32 章为早期体例，
不在此关卡内）。`32_project.v` 的 `Recursive Extraction` 会向输出打印抽取的
OCaml 代码；85–92 章的 `QuickChick`/`Sample` 命令在编译时抽取 OCaml 并当场
运行随机测试（性质被证伪不影响退出码，需看输出中的 Passed/Failed），全量
编译耗时略长属正常。

## 平台差异说明

- .v 文件为 UTF-8 **无 BOM**，中文注释可直接编译。
- Windows 下 scoop 的 `coq` 包停在 8.x 旧版线；要用 9.x 请装 Rocq
  Platform 或 opam。
- macOS 实测：opam 安装 `opam install rocq-prover`，二进制在
  `~/.opam/default/bin`（rocq 9.3.0 + rocq-stdlib 9.2.0），加入 PATH 后
  直接 `./build.sh -All` 即可。
- 老资料（含本书 2004 年原版）是 `Coq.*` 命名空间与旧 tactic 名
  （omega 已删、fourier 弃用等），抄代码先 `Fail Check 名字.` 探路。

## 示例怎么读

- **章号 = 示例编号**：`docs/05-expressions.md` ↔ `examples/05_expressions.v`，
  每章开头一行"对应示例"标注。
- 84 章无示例，是全教程坑位的汇总清单——写代码前先查它。
- 改示例后重跑对应文件：`.\build.ps1 -File NN_xxx.v`（macOS / Linux 用
  `./build.sh -File NN_xxx.v`）。

## 相关教程

同为证明助手的 [lean4](../lean4/README.md)（数学定理主线）；ML 系函数式
对照 [sml](../sml/README.md) / [ocaml](../ocaml/README.md)；惰性函数式与
类型类 [haskell](../haskell/README.md)。
