# 静态分析教程（ANTLR4 + LLVM）

以 Anders Møller & Michael I. Schwartzbach《Static Program Analysis》为骨架，Aho & Ullman《Principles of Compiler Design》（绿龙 1977）、Aho/Lam/Sethi/Ullman《Compilers》（紫龙 2006）与 Appel/Ginsburg《Modern Compiler Implementation in C》（虎书 1998）三本经典为扩充取材（三书核心内容全部自包含蒸馏进正文），在 TIP 语言上系统实现类型分析、格与不动点数据流、widening、上下文敏感、IFDS/IDE、控制流与指针分析、抽象解释，并补全前端原理（自动机/LL/LR/语法制导翻译）、经典优化（三地址码、四大数据流分析、框架定理、支配者、SSA、DAG、循环优化、部分冗余消除）与目标代码（寄存器分配、指令选择、指令级并行、局部性）。ANTLR4 构建前端，LLVM（ORC JIT）让程序真实运行以检验分析结论。

构建：`pwsh ./build.ps1`（Windows）或 `./run-all.sh`（Git Bash 自动进入 UCRT64）。首次使用先在 UCRT64 shell 内运行 `bash tools/bootstrap.sh`。

## 48 章导航（十一篇全部落成）

### 第一篇　地基（1–2）

- [01 概览](docs/01-overview.md) —— 静态分析是什么、为什么必须保守；本教程的路线图与验证方法（示例 `examples/01_overview`）
- [02 不可判定性](docs/02-undecidability.md) —— Rice 定理与归约机：保守性的总开关从哪来（`examples/02_undecidability`）

### 第二篇　前端的原理（3–10）

- [03 TIP 导览](docs/03-tip-tour.md) —— 教学语言的全貌：整数、函数、闭包、指针、记录（`examples/03_tip_tour`）
- [04 ANTLR 文法](docs/04-antlr-grammar.md) —— 从产生式到词法/语法分析器；文法是分析器的第一份合同（`examples/04_antlr_grammar`）
- [05 正则与自动机](docs/05-regex-automata.md) —— Thompson 构造、子集构造、最小化；多模式 scanner 与最长匹配（`examples/05_regex_automata`）
- [06 LL 分析](docs/06-ll-parsing.md) —— FIRST/FOLLOW、LL(1) 表与预测分析器、左递归消除、悬挂 else 冲突（`examples/06_ll_parsing`）
- [07 LR 分析](docs/07-lr-parsing.md) —— LR(0) 项集、SLR 造表、移进-归约、冲突与 prefer-shift（`examples/07_lr_parsing`）
- [08 AST](docs/08-ast.md) —— 访问者模式把语法树变成类型安全的内存（`examples/08_ast`）
- [09 语法制导翻译](docs/09-sdt.md) —— 属性文法、依赖图与拓扑求值、S-/L-属性两子类、翻译方案（`examples/09_sdt`）
- [10 作用域](docs/10-scopes.md) —— 名字解析与绑定；每个变量属于谁（`examples/10_scopes`）

### 第三篇　中间表示与运行时（11–16）

- [14 规范化与跟踪](docs/14-traces.md) —— 贪心跟踪线性化、终结符四规则、顺直链消跳转（`examples/14_traces`）

- [11 控制流图](docs/11-cfg.md) —— 树摊成图，循环与分支才可谈；两遍构造与稳定编号（`examples/11_cfg`）
- [12 LLVM 执行台](docs/12-llvm-run.md) —— ORC JIT：让"具体语义"有证人（`examples/12_llvm_run`）
- [13 三地址码与基本块](docs/13-tac-blocks.md) —— 四元组 TAC、leader 三规则、next-use、解释器与 JIT 对账（`examples/13_tac_blocks`）
- [14 栈与活动记录](docs/15-activation-records.md) —— 活动树、帧布局、调用/返回序列、访问链与 display（`examples/15_activation_records`）
- [15 垃圾回收](docs/16-garbage-collection.md) —— 可达性闭包、引用计数与环、标记清除、Cheney 复制（`examples/16_garbage_collection`）

### 第四篇　类型推断（17–20）

- [16 类型变量](docs/17-type-vars.md) —— 类型是值的集合；变量从相等约束开始（`examples/17_type_vars`）
- [17 约束生成](docs/18-constraints.md) —— 程序翻成方程：赋值、调用、二元运算各出一条（`examples/18_constraints`）
- [18 合一](docs/19-unify.md) —— 等式求解：并查集与 occurs 检查（`examples/19_unify`）
- [19 记录与边界](docs/20-records-limits.md) —— 递归类型、多态、让合一停下的地方（`examples/20_records_limits`）

### 第五篇　格与数据流（21–29）

- [20 符号格](docs/21-sign-lattice.md) —— 五点格：⊥/−/0/+/⊤，"保守"的第一个家（`examples/21_sign_lattice`）
- [21 格的构造](docs/22-lattice-build.md) —— 域是代数：lift、product、maps 的组装语法（`examples/22_lattice_build`）
- [22 不动点](docs/23-fixpoint.md) —— 方程的答案、无限的刹车；Knaster–Tarski（`examples/23_fixpoint`）
- [23 工作表](docs/24-worklist.md) —— 只追变化、单调即止；四种顺序的收敛账（`examples/24_worklist`）
- [24 符号与常量](docs/25-sign-const.md) —— 两域同台；强更新是精度的发动机；soundness 采样检验（`examples/25_sign_const`）
- [25 经典双向流](docs/26-classic-dfa.md) —— 活跃变量（后向）与可用表达式（前向），交半格管精度（`examples/26_classic_dfa`）
- [26 到达定值与非常忙](docs/27-reaching-verybusy.md) —— 四大分析补全、ud 链、复制传播与代码提升（`examples/27_reaching_verybusy`）
- [27 转移函数](docs/28-transfer.md) —— 语义的表格化：kill/gen 的系统化（`examples/28_transfer`）
- [28 数据流框架定理](docs/29-dfa-framework.md) —— 半格框架、收敛定理、MFP≤MOP 与非分配反例（`examples/29_dfa_framework`）

### 第六篇　精度的深水（30–32）

- [29 区间分析](docs/30-interval.md) —— 宽度换高度：无限格的第一课（`examples/30_interval`）
- [30 加宽与收窄](docs/31-widening.md) —— widen 止损、narrow 找零；策略即精度（`examples/31_widening`）
- [31 路径敏感](docs/32-path-sens.md) —— 把分支的账分开记；路径条件与爆炸的代价（`examples/32_path_sens`）

### 第七篇　控制流的结构与变换（33–39）

- [35 控制依赖与 SSA 往返](docs/35-cdg.md) —— 后支配、FOW 控制依赖图、φ 拆解与三方对账（`examples/35_cdg`）
- [38 边界检查与循环展开](docs/38-bounds.md) —— guard 插入/两规则消除、循环展开推演（`examples/38_bounds`）

- [32 支配者与自然循环](docs/33-dominators.md) —— 支配集/支配树、DFS 四类边、自然循环、可归约性（`examples/33_dominators`）
- [33 SSA 形式](docs/34-ssa.md) —— CHK 支配边界、φ 插入、版本栈改名、与 opt mem2reg 对账（`examples/34_ssa`）
- [34 基本块 DAG](docs/36-dag-local.md) —— 值图登记、代数恒等式、局部 CSE 与死结点剔除（`examples/36_dag_local`）
- [35 循环优化](docs/37-loop-opt.md) —— preheader、三判据外提（迭代）、归纳变量识别（`examples/37_loop_opt`）
- [36 部分冗余消除](docs/39-pre.md) —— 六方程（antic/avail/earliest/post/used/latest）与摆位（`examples/39_pre`）

### 第八篇　跨函数的世界（40–45）

- [37 过程间分析](docs/40-interproc.md) —— 摘要与内联的两难；完全内联的精确与代价（`examples/40_interproc`）
- [38 上下文敏感](docs/41-context-sens.md) —— call-string：k 的价格表（`examples/41_context_sens`）
- [39 IFDS](docs/42-ifds.md) —— 超级图、可分配流函数、路径边制表：配对路径上的精确可达（`examples/42_ifds`）
- [40 IDE](docs/43-ide.md) —— 边缘函数让事实携带值：三构造子语言与四条规范化律（`examples/43_ide`）
- [41 0-CFA](docs/44-closure-0cfa.md) —— 闭包与间接调用：调用图是分析出来的（`examples/44_closure_0cfa`）
- [42 指针分析](docs/45-pointer.md) —— 四类约束、包含式与合一式双算法；Andersen/Steensgaard 对照（`examples/45_pointer`）

### 第九篇　语言范式的编译（46–47）

- [46 对象与类](docs/46-objects.md) —— 前缀法布局、vtable 槽表、成员测试、0-CFA 目标集（`examples/46_objects`）
- [47 闭包与函数式](docs/47-functional.md) —— 闭包转换装箱单、尾调用检测、thunk 惰性求值对账（`examples/47_functional`）

### 第十篇　代码生成与并行（48–52）

- [51 分支预测与预取](docs/51-predict.md) —— 二位饱和机、静态启发式、预取距离⌈延迟/迭代⌉、对齐消冲突（`examples/51_predict`）

- [43 寄存器分配](docs/48-regalloc.md) —— 干涉图、Chaitin–Briggs 着色、溢出与相邻异色校验（`examples/48_regalloc`）
- [44 指令选择与窥孔](docs/49-isel-peephole.md) —— 树重建、Ershov 标号、maximal munch、窥孔清扫（`examples/49_isel_peephole`）
- [45 指令级并行](docs/50-ilp.md) —— 依赖三类、关键路径、表调度、modulo 双下界（`examples/50_ilp`）
- [46 并行与局部性](docs/52-parallel-locality.md) —— 方向向量、GCD 检验、交换合法性、缓存模拟三序对比（`examples/52_parallel_locality`）

### 第十一篇　收束（53–54）

- [47 抽象解释](docs/53-abstract-interp.md) —— 收集语义、α/γ、Galois 连接；"保守"写成定理并机器检验（`examples/53_abstract_interp`）
- [48 收官](docs/54-finale.md) —— 对照表、LLVM 中端协作终览、延伸阅读地图与出发方向（`examples/54_finale`）

## 验证状态

54/54 全绿（`build → check_example → check_docs`）；其余新章按上述槽位扩充中。`python tools/check_docs.py` 校验每章正文内嵌的全部源码、文法与期望输出与仓库字节一致；正文行数不少于 200 且文字多于代码。

每章 = `docs/NN-<slug>.md` + `examples/NN_<slug>/`（章号=示例号）。LLVM 示例的运行需要 MSYS2 UCRT64 工具链在 PATH（`run-all.sh` 自动处理；`tools/example_build.sh <examples/NN_slug> "$(pwd)"` 单独构建一个示例）。
