# 静态分析教程（ANTLR4 + LLVM）

以 Anders Møller & Michael I. Schwartzbach《Static Program Analysis》为骨架，Aho & Ullman《Principles of Compiler Design》（绿龙 1977）、Aho/Lam/Sethi/Ullman《Compilers》（紫龙 2006）、Appel/Ginsburg《Modern Compiler Implementation in C》（虎书 1998）与 Cooper/Torczon《Engineering a Compiler》（鲸书 2e 2012）四本经典为扩充取材（四书核心内容全部自包含蒸馏进正文），在 TIP 语言上系统实现类型分析、格与不动点数据流、widening、上下文敏感、IFDS/IDE、控制流与指针分析、抽象解释，并补全前端原理（自动机/LL/LR(1)/LALR/语法制导翻译）、经典优化（三地址码、四大数据流分析、框架定理、支配者、SSA、值编号三档、强度削减、DAG、循环优化、部分冗余消除）、代码形状（数组/字符串/case）与目标代码（寄存器分配、局部与 SSA 弦图分配、指令选择、指令级并行与树高平衡、分支预测、局部性、代码放置）。ANTLR4 构建前端，LLVM（ORC JIT）让程序真实运行以检验分析结论。

构建：`pwsh ./build.ps1`（Windows）或 `./run-all.sh`（Git Bash 自动进入 UCRT64）。首次使用先在 UCRT64 shell 内运行 `bash tools/bootstrap.sh`。

## 60 章导航（十一篇全部落成）

### 第一篇　地基（1–2）

- [01 概览](docs/01-overview.md) —— 静态分析是什么、为什么必须保守；本教程的路线图与验证方法（示例 `examples/01_overview`）
- [02 不可判定性](docs/02-undecidability.md) —— Rice 定理与归约机：保守性的总开关从哪来（`examples/02_undecidability`）

### 第二篇　前端的原理（3–11）

- [03 TIP 导览](docs/03-tip-tour.md) —— 教学语言的全貌：整数、函数、闭包、指针、记录（`examples/03_tip_tour`）
- [04 ANTLR 文法](docs/04-antlr-grammar.md) —— 从产生式到词法/语法分析器；文法是分析器的第一份合同（`examples/04_antlr_grammar`）
- [05 正则与自动机](docs/05-regex-automata.md) —— Thompson 构造、子集构造、最小化（分割式与 Brzozowski 逆转两次）；多模式 scanner 与最长匹配（`examples/05_regex_automata`）
- [06 LL 分析](docs/06-ll-parsing.md) —— FIRST/FOLLOW、LL(1) 表与预测分析器、左递归消除、悬挂 else 冲突（`examples/06_ll_parsing`）
- [07 LR 分析](docs/07-lr-parsing.md) —— LR(0) 项集、SLR 造表、移进-归约、冲突与 prefer-shift（`examples/07_lr_parsing`）
- [08 LR(1) 与 LALR](docs/08-lr1-lalr.md) —— lookahead 把归约许可证发到此情此景；同心合并省回半张表（`examples/08_lr1_lalr`）
- [09 AST](docs/09-ast.md) —— 访问者模式把语法树变成类型安全的内存（`examples/09_ast`）
- [10 语法制导翻译](docs/10-sdt.md) —— 属性文法、依赖图与拓扑求值、S-/L-属性两子类、翻译方案（`examples/10_sdt`）
- [11 作用域](docs/11-scopes.md) —— 名字解析与绑定；每个变量属于谁（`examples/11_scopes`）

### 第三篇　中间表示与运行时（12–18）

- [12 控制流图](docs/12-cfg.md) —— 树摊成图，循环与分支才可谈；两遍构造与稳定编号（`examples/12_cfg`）
- [13 LLVM 执行台](docs/13-llvm-run.md) —— ORC JIT：让"具体语义"有证人（`examples/13_llvm_run`）
- [14 三地址码与基本块](docs/14-tac-blocks.md) —— 四元组 TAC、leader 三规则、next-use、内存模型（可寄存器判定）、解释器与 JIT 对账（`examples/14_tac_blocks`）
- [15 代码形状](docs/15-code-shape.md) —— 行主序地址多项式与假零、dope vector、字符串三表示、case 三策略（`examples/15_code_shape`）
- [16 规范化与跟踪](docs/16-traces.md) —— 贪心跟踪线性化、终结符四规则、顺直链消跳转（`examples/16_traces`）
- [17 栈与活动记录](docs/17-activation-records.md) —— 活动树、帧布局、调用/返回序列、访问链与 display（`examples/17_activation_records`）
- [18 垃圾回收](docs/18-garbage-collection.md) —— 可达性闭包、引用计数与环、标记清除、Cheney 复制（`examples/18_garbage_collection`）

### 第四篇　类型推断（19–22）

- [19 类型变量](docs/19-type-vars.md) —— 类型是值的集合；变量从相等约束开始（`examples/19_type_vars`）
- [20 约束生成](docs/20-constraints.md) —— 程序翻成方程：赋值、调用、二元运算各出一条（`examples/20_constraints`）
- [21 合一](docs/21-unify.md) —— 等式求解：并查集与 occurs 检查（`examples/21_unify`）
- [22 记录与边界](docs/22-records-limits.md) —— 递归类型、多态、让合一停下的地方（`examples/22_records_limits`）

### 第五篇　格与数据流（23–31）

- [23 符号格](docs/23-sign-lattice.md) —— 五点格：⊥/−/0/+/⊤，"保守"的第一个家（`examples/23_sign_lattice`）
- [24 格的构造](docs/24-lattice-build.md) —— 域是代数：lift、product、maps 的组装语法（`examples/24_lattice_build`）
- [25 不动点](docs/25-fixpoint.md) —— 方程的答案、无限的刹车；Knaster–Tarski（`examples/25_fixpoint`）
- [26 工作表](docs/26-worklist.md) —— 只追变化、单调即止；四种顺序的收敛账（`examples/26_worklist`）
- [27 符号与常量](docs/27-sign-const.md) —— 两域同台；强更新是精度的发动机；soundness 采样检验（`examples/27_sign_const`）
- [28 经典双向流](docs/28-classic-dfa.md) —— 活跃变量（后向）与可用表达式（前向），交半格管精度（`examples/28_classic_dfa`）
- [29 到达定值与非常忙](docs/29-reaching-verybusy.md) —— 四大分析补全、ud 链、复制传播与代码提升（`examples/29_reaching_verybusy`）
- [30 转移函数](docs/30-transfer.md) —— 语义的表格化：kill/gen 的系统化（`examples/30_transfer`）
- [31 数据流框架定理](docs/31-dfa-framework.md) —— 半格框架、收敛定理、MFP≤MOP 与非分配反例（`examples/31_dfa_framework`）

### 第六篇　精度的深水（32–34）

- [32 区间分析](docs/32-interval.md) —— 宽度换高度：无限格的第一课（`examples/32_interval`）
- [33 加宽与收窄](docs/33-widening.md) —— widen 止损、narrow 找零；策略即精度（`examples/33_widening`）
- [34 路径敏感](docs/34-path-sens.md) —— 把分支的账分开记；路径条件与爆炸的代价（`examples/34_path_sens`）

### 第七篇　控制流的结构与变换（35–43）

- [35 支配者与自然循环](docs/35-dominators.md) —— 支配集/支配树、DFS 四类边、自然循环、可归约性；CHK 快支配与稀疏集（`examples/35_dominators`）
- [36 SSA 形式](docs/36-ssa.md) —— CHK 支配边界、φ 插入、版本栈改名、与 opt mem2reg 对账（`examples/36_ssa`）
- [37 控制依赖与 SSA 往返](docs/37-cdg.md) —— 后支配、FOW 控制依赖图、φ 拆解与三方对账（`examples/37_cdg`）
- [38 基本块 DAG](docs/38-dag-local.md) —— 值图登记、代数恒等式、局部 CSE 与死结点剔除（`examples/38_dag_local`）
- [39 超局部与支配者值编号](docs/39-svn-dvnt.md) —— EBB 作用域化散列表、SSA 上沿支配树的 DVNT 与 φ 三判（`examples/39_svn_dvnt`）
- [40 循环优化](docs/40-loop-opt.md) —— preheader、三判据外提（迭代）、归纳变量识别（`examples/40_loop_opt`）
- [41 强度削减与 LFTR](docs/41-strength-reduction.md) —— SSA 图 Tarjan SCC 找归纳变量、克隆加法链、测试换界（`examples/41_strength_reduction`）
- [42 边界检查与循环展开](docs/42-bounds.md) —— guard 插入/两规则消除、循环展开推演（`examples/42_bounds`）
- [43 部分冗余消除](docs/43-pre.md) —— 六方程（antic/avail/earliest/post/used/latest）与摆位（`examples/43_pre`）

### 第八篇　跨函数的世界（44–49）

- [44 过程间分析](docs/44-interproc.md) —— 摘要与内联的两难；完全内联的精确与代价（`examples/44_interproc`）
- [45 上下文敏感](docs/45-context-sens.md) —— call-string：k 的价格表（`examples/45_context_sens`）
- [46 IFDS](docs/46-ifds.md) —— 超级图、可分配流函数、路径边制表：配对路径上的精确可达（`examples/46_ifds`）
- [47 IDE](docs/47-ide.md) —— 边缘函数让事实携带值：三构造子语言与四条规范化律（`examples/47_ide`）
- [48 0-CFA](docs/48-closure-0cfa.md) —— 闭包与间接调用：调用图是分析出来的（`examples/48_closure_0cfa`）
- [49 指针分析](docs/49-pointer.md) —— 四类约束、包含式与合一式双算法；Andersen/Steensgaard 对照（`examples/49_pointer`）

### 第九篇　语言范式的编译（50–51）

- [50 对象与类](docs/50-objects.md) —— 前缀法布局、vtable 槽表、成员测试、0-CFA 目标集（`examples/50_objects`）
- [51 闭包与函数式](docs/51-functional.md) —— 闭包转换装箱单、尾调用检测、thunk 惰性求值对账（`examples/51_functional`）

### 第十篇　代码生成与并行（52–58）

- [52 寄存器分配](docs/52-regalloc.md) —— 干涉图、Chaitin–Briggs 着色、溢出与合并、相邻异色校验（`examples/52_regalloc`）
- [53 局部分配与 SSA 弦图](docs/53-ssa-alloc.md) —— 频率计数 vs farthest-use；MCS/PEO 最优着色与 Briggs 对照（`examples/53_ssa_alloc`）
- [54 指令选择与窥孔](docs/54-isel-peephole.md) —— 树重建、Ershov 标号、maximal munch、窥孔清扫（`examples/54_isel_peephole`）
- [55 指令级并行](docs/55-ilp.md) —— 依赖三类、关键路径、表调度、树高平衡、modulo 双下界（`examples/55_ilp`）
- [56 分支预测与预取](docs/56-predict.md) —— 二位饱和机、静态启发式、预取距离⌈延迟/迭代⌉、对齐消冲突（`examples/56_predict`）
- [57 并行与局部性](docs/57-parallel-locality.md) —— 方向向量、GCD 检验、交换合法性、缓存模拟三序对比（`examples/57_parallel_locality`）
- [58 代码放置](docs/58-placement.md) —— 热路径链构造、过程贪心聚簇、频度与地理（`examples/58_placement`）

### 第十一篇　收束（59–60）

- [59 抽象解释](docs/59-abstract-interp.md) —— 收集语义、α/γ、Galois 连接；"保守"写成定理并机器检验（`examples/59_abstract_interp`）
- [60 收官](docs/60-finale.md) —— 对照表、LLVM 中端协作终览、延伸阅读地图与出发方向（`examples/60_finale`）

## 验证状态

60/60 全绿（`build → check_example → check_docs`）。`python tools/check_docs.py` 校验每章正文内嵌的全部源码、文法与期望输出与仓库字节一致；正文行数不少于 200 且文字多于代码。

每章 = `docs/NN-<slug>.md` + `examples/NN_<slug>/`（章号=示例号）。LLVM 示例的运行需要 MSYS2 UCRT64 工具链在 PATH（`run-all.sh` 自动处理；`tools/example_build.sh <examples/NN_slug> "$(pwd)"` 单独构建一个示例）。
