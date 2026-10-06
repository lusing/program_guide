# 静态分析教程（ANTLR4 + LLVM）

以 Anders Møller & Michael I. Schwartzbach《Static Program Analysis》为骨架，Aho & Ullman《Principles of Compiler Design》（绿龙 1977）、Aho/Lam/Sethi/Ullman《Compilers》（紫龙 2006）、Appel/Ginsburg《Modern Compiler Implementation in C》（虎书 1998）、Cooper/Torczon《Engineering a Compiler》（鲸书 2e 2012）、Robert Nystrom《Crafting Interpreters》（匠书 2021）与 Kenneth C. Louden《编译原理及实践》（L 书 1997 中译本）六本经典为扩充取材（六书核心内容全部自包含蒸馏进正文），在 TIP 语言上系统实现类型分析、格与不动点数据流、widening、上下文敏感、IFDS/IDE、控制流与指针分析、抽象解释，并补全前端原理（自动机/LL/LR(1)/LALR/Pratt/语法制导翻译/Lex 与 Yacc 心脏/错误恢复与校正）、经典优化（三地址码、四大数据流分析、框架定理、支配者、SSA、值编号三档、强度削减、DAG、循环优化、部分冗余消除）、代码形状（数组/字符串/case）、参数传递四机制（值/引用/值结果/名字与完全静态环境）、解释器工程（树遍历环境链、字节码栈机、单遍编译与回填、NaN 装箱与驻留、上值闭包）与目标代码（寄存器分配、局部与 SSA 弦图分配、指令选择、真机实地对照、TM 目标机器与四档优化、指令级并行与树高平衡、分支预测、局部性、代码放置）。ANTLR4 构建前端，LLVM（ORC JIT）让程序真实运行以检验分析结论。

构建：`pwsh ./build.ps1`（Windows）或 `./run-all.sh`（Git Bash 自动进入 UCRT64）。首次使用先在 UCRT64 shell 内运行 `bash tools/bootstrap.sh`。

## 71 章导航（十二篇全部落成）

### 第一篇　地基（1–2）

- [01 概览](docs/01-overview.md) —— 静态分析是什么、为什么必须保守；本教程的路线图与验证方法（示例 `examples/01_overview`）
- [02 不可判定性](docs/02-undecidability.md) —— Rice 定理与归约机：保守性的总开关从哪来（`examples/02_undecidability`）

### 第二篇　前端的原理（3–14）

- [03 TIP 导览](docs/03-tip-tour.md) —— 教学语言的全貌：整数、函数、闭包、指针、记录（`examples/03_tip_tour`）
- [04 ANTLR 文法](docs/04-antlr-grammar.md) —— 从产生式到词法/语法分析器；文法是分析器的第一份合同（`examples/04_antlr_grammar`）
- [05 正则与自动机](docs/05-regex-automata.md) —— Thompson 构造、子集构造、最小化（分割式与 Brzozowski 逆转两次）；多模式 scanner 与最长匹配（`examples/05_regex_automata`）
- [06 LL 分析](docs/06-ll-parsing.md) —— FIRST/FOLLOW、LL(1) 表与预测分析器、左递归消除、悬挂 else 冲突（`examples/06_ll_parsing`）
- [07 LR 分析](docs/07-lr-parsing.md) —— LR(0) 项集、SLR 造表、移进-归约、冲突与 prefer-shift（`examples/07_lr_parsing`）
- [08 LR(1) 与 LALR](docs/08-lr1-lalr.md) —— lookahead 把归约许可证发到此情此景；同心合并省回半张表（`examples/08_lr1_lalr`）
- [09 Lex 与 Yacc 心脏](docs/09-lex-yacc.md) —— 值栈与生成器时代：双栈平行、$$/$n、优先级仲裁、嵌入动作改写（`examples/09_lex_yacc`）
- [10 错误恢复与校正](docs/10-error-recovery.md) —— 四档火力（删除/恐慌/短语级/error 记号）、级联抑制、恢复后续行（`examples/10_error_recovery`）
- [11 Pratt 分析](docs/11-pratt-parsing.md) —— 运算符优先级爬升：一张中缀表让递归下降不再每层一个函数；结合性由递归层级控制（`examples/11_pratt_parsing`）
- [12 AST](docs/12-ast.md) —— 访问者模式把语法树变成类型安全的内存（`examples/12_ast`）
- [13 语法制导翻译](docs/13-sdt.md) —— 属性文法、依赖图与拓扑求值、S-/L-属性两子类、翻译方案（`examples/13_sdt`）
- [14 作用域](docs/14-scopes.md) —— 名字解析与绑定；每个变量属于谁（`examples/14_scopes`）

### 第三篇　中间表示与运行时（15–23）

- [15 树遍历解释器](docs/15-tree-walk-interp.md) —— 环境链、闭包捕获与求值前的静态检查；无 IR 的第三条执行路（`examples/15_tree_walk_interp`）

- [16 控制流图](docs/16-cfg.md) —— 树摊成图，循环与分支才可谈；两遍构造与稳定编号（`examples/16_cfg`）
- [17 LLVM 执行台](docs/17-llvm-run.md) —— ORC JIT：让"具体语义"有证人（`examples/17_llvm_run`）
- [18 三地址码与基本块](docs/18-tac-blocks.md) —— 四元组 TAC、leader 三规则、next-use、内存模型（可寄存器判定）、解释器与 JIT 对账（`examples/18_tac_blocks`）
- [19 代码形状](docs/19-code-shape.md) —— 行主序地址多项式与假零、dope vector、字符串三表示、case 三策略（`examples/19_code_shape`）
- [20 规范化与跟踪](docs/20-traces.md) —— 贪心跟踪线性化、终结符四规则、顺直链消跳转（`examples/20_traces`）
- [21 栈与活动记录](docs/21-activation-records.md) —— 活动树、帧布局、调用/返回序列、访问链与 display（`examples/21_activation_records`）
- [22 参数传递四机制](docs/22-param-passing.md) —— 值/引用/值结果/名字：同一调用四个答案；别名是分辨器（`examples/22_param_passing`）
- [23 垃圾回收](docs/23-garbage-collection.md) —— 可达性闭包、引用计数与环、标记清除、Cheney 复制（`examples/23_garbage_collection`）

### 第四篇　类型推断（24–27）

- [24 类型变量](docs/24-type-vars.md) —— 类型是值的集合；变量从相等约束开始（`examples/24_type_vars`）
- [25 约束生成](docs/25-constraints.md) —— 程序翻成方程：赋值、调用、二元运算各出一条（`examples/25_constraints`）
- [26 合一](docs/26-unify.md) —— 等式求解：并查集与 occurs 检查（`examples/26_unify`）
- [27 记录与边界](docs/27-records-limits.md) —— 递归类型、多态、让合一停下的地方（`examples/27_records_limits`）

### 第五篇　格与数据流（28–36）

- [28 符号格](docs/28-sign-lattice.md) —— 五点格：⊥/−/0/+/⊤，"保守"的第一个家（`examples/28_sign_lattice`）
- [29 格的构造](docs/29-lattice-build.md) —— 域是代数：lift、product、maps 的组装语法（`examples/29_lattice_build`）
- [30 不动点](docs/30-fixpoint.md) —— 方程的答案、无限的刹车；Knaster–Tarski（`examples/30_fixpoint`）
- [31 工作表](docs/31-worklist.md) —— 只追变化、单调即止；四种顺序的收敛账（`examples/31_worklist`）
- [32 符号与常量](docs/32-sign-const.md) —— 两域同台；强更新是精度的发动机；soundness 采样检验（`examples/32_sign_const`）
- [33 经典双向流](docs/33-classic-dfa.md) —— 活跃变量（后向）与可用表达式（前向），交半格管精度（`examples/33_classic_dfa`）
- [34 到达定值与非常忙](docs/34-reaching-verybusy.md) —— 四大分析补全、ud 链、复制传播与代码提升（`examples/34_reaching_verybusy`）
- [35 转移函数](docs/35-transfer.md) —— 语义的表格化：kill/gen 的系统化（`examples/35_transfer`）
- [36 数据流框架定理](docs/36-dfa-framework.md) —— 半格框架、收敛定理、MFP≤MOP 与非分配反例（`examples/36_dfa_framework`）

### 第六篇　精度的深水（37–39）

- [37 区间分析](docs/37-interval.md) —— 宽度换高度：无限格的第一课（`examples/37_interval`）
- [38 加宽与收窄](docs/38-widening.md) —— widen 止损、narrow 找零；策略即精度（`examples/38_widening`）
- [39 路径敏感](docs/39-path-sens.md) —— 把分支的账分开记；路径条件与爆炸的代价（`examples/39_path_sens`）

### 第七篇　控制流的结构与变换（40–48）

- [40 支配者与自然循环](docs/40-dominators.md) —— 支配集/支配树、DFS 四类边、自然循环、可归约性；CHK 快支配与稀疏集（`examples/40_dominators`）
- [41 SSA 形式](docs/41-ssa.md) —— CHK 支配边界、φ 插入、版本栈改名、与 opt mem2reg 对账（`examples/41_ssa`）
- [42 控制依赖与 SSA 往返](docs/42-cdg.md) —— 后支配、FOW 控制依赖图、φ 拆解与三方对账（`examples/42_cdg`）
- [43 基本块 DAG](docs/43-dag-local.md) —— 值图登记、代数恒等式、局部 CSE 与死结点剔除（`examples/43_dag_local`）
- [44 超局部与支配者值编号](docs/44-svn-dvnt.md) —— EBB 作用域化散列表、SSA 上沿支配树的 DVNT 与 φ 三判（`examples/44_svn_dvnt`）
- [45 循环优化](docs/45-loop-opt.md) —— preheader、三判据外提（迭代）、归纳变量识别（`examples/45_loop_opt`）
- [46 强度削减与 LFTR](docs/46-strength-reduction.md) —— SSA 图 Tarjan SCC 找归纳变量、克隆加法链、测试换界（`examples/46_strength_reduction`）
- [47 边界检查与循环展开](docs/47-bounds.md) —— guard 插入/两规则消除、循环展开推演（`examples/47_bounds`）
- [48 部分冗余消除](docs/48-pre.md) —— 六方程（antic/avail/earliest/post/used/latest）与摆位（`examples/48_pre`）

### 第八篇　跨函数的世界（49–54）

- [49 过程间分析](docs/49-interproc.md) —— 摘要与内联的两难；完全内联的精确与代价（`examples/49_interproc`）
- [50 上下文敏感](docs/50-context-sens.md) —— call-string：k 的价格表（`examples/50_context_sens`）
- [51 IFDS](docs/51-ifds.md) —— 超级图、可分配流函数、路径边制表：配对路径上的精确可达（`examples/51_ifds`）
- [52 IDE](docs/52-ide.md) —— 边缘函数让事实携带值：三构造子语言与四条规范化律（`examples/52_ide`）
- [53 0-CFA](docs/53-closure-0cfa.md) —— 闭包与间接调用：调用图是分析出来的（`examples/53_closure_0cfa`）
- [54 指针分析](docs/54-pointer.md) —— 四类约束、包含式与合一式双算法；Andersen/Steensgaard 对照（`examples/54_pointer`）

### 第九篇　语言范式的编译（55–56）

- [55 对象与类](docs/55-objects.md) —— 前缀法布局、vtable 槽表、成员测试、0-CFA 目标集（`examples/55_objects`）
- [56 闭包与函数式](docs/56-functional.md) —— 闭包转换装箱单、尾调用检测、thunk 惰性求值对账（`examples/56_functional`）

### 第十篇　字节码解释器（57–60）

- [57 字节码与栈式虚拟机](docs/57-bytecode-vm.md) —— chunk、反汇编、FETCH–DECODE–EXECUTE 与调用帧（`examples/57_bytecode_vm`）
- [58 单遍编译与回填](docs/58-single-pass.md) —— 即取即用扫描、Pratt 直接发码、编译期槽位与跳转回填（`examples/58_single_pass`）
- [59 值表示](docs/59-value-repr.md) —— NaN 装箱、字符串驻留与开放定址散列表（`examples/59_value_repr`）
- [60 上值与闭包](docs/60-upvalues.md) —— 开放上值链、close 搬家与逃逸闭包（`examples/60_upvalues`）

### 第十一篇　代码生成与并行（61–69）

- [61 寄存器分配](docs/61-regalloc.md) —— 干涉图、Chaitin–Briggs 着色、溢出与合并、相邻异色校验（`examples/61_regalloc`）
- [62 局部分配与 SSA 弦图](docs/62-ssa-alloc.md) —— 频率计数 vs farthest-use；MCS/PEO 最优着色与 Briggs 对照（`examples/62_ssa_alloc`）
- [63 指令选择与窥孔](docs/63-isel-peephole.md) —— 树重建、Ershov 标号、maximal munch、窥孔清扫（`examples/63_isel_peephole`）
- [64 真机实地](docs/64-real-codegen.md) —— Borland/80×86 与 Sun/SPARC 案例全程走读；gcc -O0/-O1 三十年对账与模式表（`examples/64_real_codegen`）
- [65 TM 目标机器](docs/65-tm-machine.md) —— 16 指令两遍汇编器模拟器 + TINY 手写前端 + 四档优化双账（`examples/65_tm_machine`）
- [66 指令级并行](docs/66-ilp.md) —— 依赖三类、关键路径、表调度、树高平衡、modulo 双下界（`examples/66_ilp`）
- [67 分支预测与预取](docs/67-predict.md) —— 二位饱和机、静态启发式、预取距离⌈延迟/迭代⌉、对齐消冲突（`examples/67_predict`）
- [68 并行与局部性](docs/68-parallel-locality.md) —— 方向向量、GCD 检验、交换合法性、缓存模拟三序对比（`examples/68_parallel_locality`）
- [69 代码放置](docs/69-placement.md) —— 热路径链构造、过程贪心聚簇、频度与地理（`examples/69_placement`）

### 第十二篇　收束（70–71）

- [70 抽象解释](docs/70-abstract-interp.md) —— 收集语义、α/γ、Galois 连接；"保守"写成定理并机器检验（`examples/70_abstract_interp`）
- [71 收官](docs/71-finale.md) —— 对照表、LLVM 中端协作终览、延伸阅读地图与出发方向（`examples/71_finale`）

## 验证状态

71/71 全绿（`build → check_example → check_docs`）。`python tools/check_docs.py` 校验每章正文内嵌的全部源码、文法与期望输出与仓库字节一致；正文行数不少于 200 且文字多于代码。

每章 = `docs/NN-<slug>.md` + `examples/NN_<slug>/`（章号=示例号）。LLVM 示例的运行需要 MSYS2 UCRT64 工具链在 PATH（`run-all.sh` 自动处理；`tools/example_build.sh <examples/NN_slug> "$(pwd)"` 单独构建一个示例）。
