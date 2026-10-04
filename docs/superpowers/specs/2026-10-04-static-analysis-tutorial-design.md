# 静态分析教程（ANTLR4 + LLVM）设计文档

**日期**：2026-10-04
**状态**：已与用户确认，待 spec 审阅
**工作目录**：`G:\code\guide\compiler\`（新建，与已有 `llvm/` 教程并列：那本讲 LLVM 工具本身，这本讲以 spa.pdf 为骨架的静态分析）

## 1. 主题定位

这是一本**静态分析教程**，不是编译器构造教程，也不是代码踩坑集。

- **理论骨架**：Anders Møller & Michael I. Schwartzbach, *Static Program Analysis*（`G:\book\计算机\编译原理\spa.pdf`，2026-09-30 版）。全书 12 章：类型分析、格论、单调数据流框架、widening、路径/过程间/上下文敏感、IFDS/IDE、控制流分析、指针分析、抽象解释。
- **被分析语言**：spa 定义的 TIP（Tiny Imperative Programming Language）——整型值世界（`input`/`output` 流）、`if`/`while`、函数（含一等函数值与间接调用）、指针（`alloc`/`&`/`*`/`null`）、记录。语法语义有正式定义，且原书按"逐章子语言"展开，天然适合增量式实验台。
- **ANTLR4 的角色**：构建 TIP 前端（lexer/parser/AST/CFG），它是"被分析程序的入口"，服务于分析，不占理论主线。使用本地源码树 `G:\github\java\antlr4`（4.13.3-SNAPSHOT，含 C++ runtime）。
- **LLVM 的角色**：分析底座，三项用途：
  1. 让 TIP 程序真实可运行——用 ORC JIT 枚举具体输入执行，**经验检验分析结论的可靠性**（soundness 的可执行直觉）；
  2. 与工业级中端分析/优化对照阅读（SCCP、mem2reg 后的 SSA、`opt -print-after-all`）；
  3. 第 8 章用 IRBuilder 写一个极简后端（一章完成，只支撑执行，不追求代码生成质量）。使用本地源码树 `G:\github\lang\llvm-project`。
- **LLVM C++ API 细节不重复讲授**：读者需要查 API 时引用已有《llvm》教程对应章节。

## 2. 写作风格（硬性要求）

1. **原理推导为主线**。每章按"问题与直觉 → 形式化（格/约束/不动点/Galois 连接）→ 为什么正确（可靠性论证思路）→ 原理在 TIP 上的落地 → 真实分析输出"组织。
2. **代码只在原理讲透之后出现**，作为原理的落地；所有代码分段内嵌正文，每段前有"为什么需要它"，后有"它在做什么、关键点是什么"。读者只读 `docs/` 不打开 `examples/` 即可学完全书，**不允许让用户自己看源码**。
3. **不写代码坑罗列**：取消 CHEATSheet 文档、取消"坑清单/陷阱表"体例。每章末尾仅保留一小节叙述体"工程注意点"（3–5 条，嵌在连贯论述里，说明现象/原因/后果）。
4. 每篇正文 ≥ 200 行，文字篇幅多于代码。
5. 正文引用的全部输出必须是分析器/编译器在本机的真实产物，逐字节对账，不杜撰。
6. 确定性纪律：分析结果不打印地址、耗时、平台相关值；枚举执行使用固定输入集合；平局按编号/字典序。

## 3. 章目（30 章，七篇）

### 第一篇 · 为什么静态分析（01–02，spa ch1）

| 章 | 标题 | 教学要点 |
|---|---|---|
| 01 | 静态分析是什么 | 四类应用（程序验证、缺陷发现、编译优化、安全分析）；贯穿全书的小例子：同一程序，编译器、lint、分析器各自"知道"什么 |
| 02 | 不可判定性与可靠近似 | 停机问题/Rice 定理推出精确答案不存在；sound 与 complete 的取舍直觉；精度—成本谱系；分析三要素（性质、方向、近似）预告 |

### 第二篇 · 搭建分析实验台：TIP + ANTLR + LLVM（03–08）

| 章 | 标题 | 教学要点 |
|---|---|---|
| 03 | TIP 语言导览 | 语法语义全貌（spa 2.1）；三个阶乘程序 ite/rec/foo 精读；整型流世界为什么让分析问题更纯粹 |
| 04 | ANTLR 文法工程 | 完整 TIP.g4：词法规则、ANTLR4 原生左递归与优先级、LL(*) 与歧义报告；文法即形式化的第一次练习 |
| 05 | 从 Parse Tree 到 AST | Listener/Visitor 机制差别；为什么分析不直接在 parse tree 上做；AST 类型设计与遍历框架 |
| 06 | 名字与作用域 | 符号表、词法作用域、函数前向引用（先注册函数名再解析函数体）；分析需要的绑定信息；重名诊断 |
| 07 | 控制流图 | 从 AST 归纳构造 CFG（spa 2.5）；entry/exit、pred/succ；语句级与块级节点的权衡 |
| 08 | TIP 上 LLVM：让程序可运行 | IRBuilder 极简后端（一章完成）+ ORC JIT；`opt -print-after-all` 初观工业分析管线；立约：**真实执行是检验分析结论的标尺** |

### 第三篇 · 类型分析（09–12，spa ch3）

| 章 | 标题 | 教学要点 |
|---|---|---|
| 09 | 类型与类型变量 | 类型作为"对值的最早一层抽象"；int/函数/指针/记录类型；类型变量从哪里引入 |
| 10 | 类型约束 | 逐条推导每条语法产生式贡献什么约束；约束是可阅读、可独立检验的数据 |
| 11 | Robinson 合一 | 合一作为约束求解；occurs check；主类型思想——为什么解是完备且最一般的 |
| 12 | 记录类型与类型分析的边界 | spa 3.4–3.5；字段约束；flow-insensitive 的局限——为后续章节埋问题 |

### 第四篇 · 格论与单调数据流框架（13–19，spa ch4–5）

| 章 | 标题 | 教学要点 |
|---|---|---|
| 13 | 从符号分析到格 | 动机：每程序点 x 可能为正/负/零；部分序与格的定义；⊤⊥ 的操作意义 |
| 14 | 构造格 | 提升、积格、映射格、幂集格；复合类型（记录/堆）的抽象域从哪来 |
| 15 | 单调方程与不动点 | 约束方程、单调性、Tarski 不动点定理：为什么迭代一定停、停下的就是正确答案 |
| 16 | 不动点算法 | 混沌迭代与 worklist；终止性与复杂度；初始值为何取 ⊥（may/must 对偶取 ⊤） |
| 17 | 符号分析与常量传播落地 | 两个前向分析完整实现；与 LLVM SCCP 对照；JIT 枚举检验可靠性 |
| 18 | 四大经典数据流分析 | 活跃变量、可用表达式、非常忙表达式、到达定值；前/后向与 may/must 的统一分类 |
| 19 | 传递函数的一般理论 | spa 5.10；初始化变量分析；单调框架的精确定义与正确性论证结构（为 ch29 铺路） |

### 第五篇 · 精度的三个方向（20–24，spa ch6–8）

| 章 | 标题 | 教学要点 |
|---|---|---|
| 20 | 区间分析 | 无穷高度格上的问题：迭代为什么不再终止 |
| 21 | Widening 与 Narrowing | widening 强制收敛、narrowing 回收精度；widening point 的选择如何影响结果 |
| 22 | 路径敏感 | 分支条件携带的信息；assertion 精炼（spa 7.1）；路径爆炸与合并策略 |
| 23 | 过程间分析 | 过程内 CFG 的失效；过程间 CFG；被调函数随意近似如何摧毁精度 |
| 24 | 上下文敏感 | call-strings k-CFA 与 functional approach；精度—成本权衡；JIT 实测精度差异 |

### 第六篇 · 可分配框架、控制流与指针（25–28，spa ch9–11 精选）

| 章 | 标题 | 教学要点 |
|---|---|---|
| 25 | IFDS 框架 | distributive 性质；传递函数编码为图边；超级图与路径边算法；多项式时间的由来 |
| 26 | IDE 框架 | 环境边与非格事实；常量传播的 IFDS 升级；与朴素 worklist 的精度/性能对照 |
| 27 | 高阶控制流分析 | λ 闭包分析；0-CFA 与 cubic 算法；TIP 一等函数；"先有鸡还是蛋"的不动点解法 |
| 28 | 指针分析 | allocation-site 抽象；Andersen（包含约束）与 Steensgaard（合一，O(n)）对比；null 指针分析；流敏感为何昂贵 |

### 第七篇 · 抽象解释与收官（29–30，spa ch12）

| 章 | 标题 | 教学要点 |
|---|---|---|
| 29 | 抽象解释 | collecting semantics 是最精确的"分析"；抽象/具体化函数与 Galois 连接；soundness 定理的完整陈述与证明结构 |
| 30 | 收官：分析的科学与工程 | 用 Galois 连接重看全书分析；optimality/completeness；LLVM 中端分析—变换协作；现代方向（SMT/路径敏感工业工具）与延伸阅读地图 |

## 4. 工程结构

```
compiler/
├── .gitignore
├── README.md                 # 书目导读 + 30 章导航（无 CHEATSheet）
├── build.ps1                 # Windows 主入口（pwsh 7）：自动发现 examples/*，三层对账
├── run-all.sh                # Git Bash 主入口，同样判定
├── tools/
│   ├── bootstrap.sh          # 一次性：pacman 装 UCRT64 llvm/cmake/ninja；源码构建 ANTLR 工具 jar
│   ├── build_antlr_runtime.sh# 从 G:\github\java\antlr4\runtime\Cpp 构建 libantlr4-runtime.a
│   ├── check_example.py      # 单示例三层对账，被两个入口共同调用
│   └── tiprt.c               # tip_input/tip_output 运行时（极简后端与原生执行共用）
├── docs/                     # 01-overview.md … 30-finale.md（30 篇）
├── examples/                 # 章号=示例号：01_overview/ … 30_finale/
│   └── NN_<slug>/
│       ├── TIP.g4            # 该章文法快照
│       ├── src/              # 分析器源码（driver/ast/sema/cfg/analysis/…，第 8 章起含后端）
│       ├── programs/         # 固定 TIP 样例（含错误路径样例）
│       └── expected/         # 期望分析结果文本 + 枚举执行输入集
└── build/                    # gitignore：antlr jar、runtime 库、generated parser、tipa.exe、.ll、exe、.o
```

**示例目录 slug**（与 docs 同名）：
`01_overview, 02_undecidability, 03_tip_tour, 04_antlr_grammar, 05_ast, 06_scopes, 07_cfg, 08_llvm_run, 09_type_vars, 10_constraints, 11_unify, 12_records_limits, 13_sign_lattice, 14_lattice_build, 15_fixpoint, 16_worklist, 17_sign_const, 18_classic_dfa, 19_transfer, 20_interval, 21_widening, 22_path_sens, 23_interproc, 24_context_sens, 25_ifds, 26_ide, 27_closure_0cfa, 28_pointer, 29_abstract_interp, 30_finale`

**工具链**：

- 宿主：scoop MSYS2（`G:\scoop\apps\msys2\current`，子环境当前为空，pacman 联网已验证）。bootstrap 安装：`mingw-w64-ucrt-x86_64-{llvm,clang,c,gcc,cmake,ninja}`（提供 llvm-config、opt、lli、LLVM C++ 开发库、g++）。
- ANTLR 工具：`mvn -pl tool -am -DskipTests package`（Maven 3.10 + JDK 17 已就位）产出 `antlr4-complete.jar`；C++ runtime：`runtime/Cpp` 下 cmake 构建静态库。
- 分析器本体：C++17，UCRT64 g++ 编译（`-Wall -Wextra` 零告警），clang++ 门控登记。

## 5. 验证方案（每章三层对账）

1. **分析结果对账**：分析器对 `programs/` 中每个 TIP 程序逐程序点输出抽象值（固定文本格式），与 `expected/` 逐字节一致。错误路径样例（未声明/类型冲突/语法错）检查退出码与诊断文本。
2. **可靠性经验测试**（第 8 章具备执行能力后）：对每个前向分析，用 ORC JIT 在固定具体输入集合上真实执行，断言每个观察到的具体值 ∈ 该点预测的抽象集合。这是 soundness 的可执行检验；若分析升级导致集合变化，expected 与执行集合同步更新并在章中说明。
3. **LLVM 对照**：涉及与工业分析对应的章节（17 常量传播/SCCP、19、30），运行 `opt` 抓取相应输出作为正文对照材料（expected 中以独立文件保存）。

判定：编译器/分析器编译零告警；分析器退出码正确；三层对账全过；两遍运行逐字节一致（确定性）。

## 6. 范围边界（YAGNI）

- 不实现 TIP 的原生优化编译器后端：第 8 章后端只到"可运行"，不做指令选择质量。
- 不写 LLVM out-of-tree pass（这是《llvm》教程的内容）。
- spa 第 9–11 章只精选 IFDS/IDE/0-CFA/指针四节（25–28），其余子主题（escape analysis、flow-sensitive pointer 全貌）在正文以一段论述带过并指明原书章节。
- 不引入 SMT 求解器依赖；第 22、30 章只做概念性对照。
