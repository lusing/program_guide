# 静态分析教程（ANTLR4 + LLVM）

以 Anders Møller & Michael I. Schwartzbach《Static Program Analysis》为骨架，在 TIP 语言上系统实现类型分析、格与不动点数据流、widening、上下文敏感、IFDS/IDE、控制流与指针分析、抽象解释。ANTLR4 构建前端，LLVM（ORC JIT）让程序真实运行以检验分析结论。

构建：`pwsh ./build.ps1`（Windows）或 `./run-all.sh`（Git Bash 自动进入 UCRT64）。首次使用先在 UCRT64 shell 内运行 `bash tools/bootstrap.sh`。

## 30 章导航

### 第一篇　地基（1–2）

- [01 概览](docs/01-overview.md) —— 静态分析是什么、为什么必须保守；本教程的路线图与验证方法（示例 `examples/01_overview`）
- [02 不可判定性](docs/02-undecidability.md) —— Rice 定理与归约机：保守性的总开关从哪来（`examples/02_undecidability`）

### 第二篇　前端与执行台（3–8）

- [03 TIP 导览](docs/03-tip-tour.md) —— 教学语言的全貌：整数、函数、闭包、指针、记录（`examples/03_tip_tour`）
- [04 ANTLR 文法](docs/04-antlr-grammar.md) —— 从产生式到词法/语法分析器；文法是分析器的第一份合同（`examples/04_antlr_grammar`）
- [05 AST](docs/05-ast.md) —— 访问者模式把语法树变成类型安全的内存（`examples/05_ast`）
- [06 作用域](docs/06-scopes.md) —— 名字解析与绑定；每个变量属于谁（`examples/06_scopes`）
- [07 控制流图](docs/07-cfg.md) —— 树摊成图，循环与分支才可谈；两遍构造与稳定编号（`examples/07_cfg`）
- [08 LLVM 执行台](docs/08-llvm-run.md) —— ORC JIT：让"具体语义"有证人（`examples/08_llvm_run`）

### 第三篇　类型推断（9–12）

- [09 类型变量](docs/09-type-vars.md) —— 类型是值的集合；变量从相等约束开始（`examples/09_type_vars`）
- [10 约束生成](docs/10-constraints.md) —— 程序翻成方程：赋值、调用、二元运算各出一条（`examples/10_constraints`）
- [11 合一](docs/11-unify.md) —— 等式求解：并查集与 occurs 检查（`examples/11_unify`）
- [12 记录与边界](docs/12-records-limits.md) —— 递归类型、多态、让合一停下的地方（`examples/12_records_limits`）

### 第四篇　格与数据流（13–19）

- [13 符号格](docs/13-sign-lattice.md) —— 五点格：⊥/−/0/+/⊤，"保守"的第一个家（`examples/13_sign_lattice`）
- [14 格的构造](docs/14-lattice-build.md) —— 域是代数：lift、product、maps 的组装语法（`examples/14_lattice_build`）
- [15 不动点](docs/15-fixpoint.md) —— 方程的答案、无限的刹车；Knaster–Tarski（`examples/15_fixpoint`）
- [16 工作表](docs/16-worklist.md) —— 只追变化、单调即止；四种顺序的收敛账（`examples/16_worklist`）
- [17 符号与常量](docs/17-sign-const.md) —— 两域同台；强更新是精度的发动机；soundness 采样检验（`examples/17_sign_const`）
- [18 经典双向流](docs/18-classic-dfa.md) —— 活跃变量（后向）与可用表达式（前向），交半格管精度（`examples/18_classic_dfa`）
- [19 转移函数](docs/19-transfer.md) —— 语义的表格化：kill/gen 的系统化（`examples/19_transfer`）

### 第五篇　精度的深水（20–22）

- [20 区间分析](docs/20-interval.md) —— 宽度换高度：无限格的第一课（`examples/20_interval`）
- [21 加宽与收窄](docs/21-widening.md) —— widen 止损、narrow 找零；策略即精度（`examples/21_widening`）
- [22 路径敏感](docs/22-path-sens.md) —— 把分支的账分开记；路径条件与爆炸的代价（`examples/22_path_sens`）

### 第六篇　跨函数的世界（23–28）

- [23 过程间分析](docs/23-interproc.md) —— 摘要与内联的两难；完全内联的精确与代价（`examples/23_interproc`）
- [24 上下文敏感](docs/24-context-sens.md) —— call-string：k 的价格表（`examples/24_context_sens`）
- [25 IFDS](docs/25-ifds.md) —— 超级图、可分配流函数、路径边制表：配对路径上的精确可达（`examples/25_ifds`）
- [26 IDE](docs/26-ide.md) —— 边缘函数让事实携带值：三构造子语言与四条规范化律（`examples/26_ide`）
- [27 0-CFA](docs/27-closure-0cfa.md) —— 闭包与间接调用：调用图是分析出来的（`examples/27_closure_0cfa`）
- [28 指针分析](docs/28-pointer.md) —— 四类约束、包含式与合一式双算法；Andersen/Steensgaard 对照（`examples/28_pointer`）

### 第七篇　收束（29–30）

- [29 抽象解释](docs/29-abstract-interp.md) —— 收集语义、α/γ、Galois 连接；"保守"写成定理并机器检验（`examples/29_abstract_interp`）
- [30 收官](docs/30-finale.md) —— 十一行对照表、LLVM 中端协作终览、延伸阅读地图与出发方向（`examples/30_finale`）

## 验证状态

30/30 示例三层对账全绿（`build → check_example → check_docs`）；`python tools/check_docs.py` 校验每章正文内嵌的全部源码、文法与期望输出与仓库字节一致；正文行数不少于 200 且文字多于代码。

每章 = `docs/NN-<slug>.md` + `examples/NN_<slug>/`（章号=示例号）。LLVM 示例的运行需要 MSYS2 UCRT64 工具链在 PATH（`run-all.sh` 自动处理；`tools/example_build.sh <examples/NN_slug> "$(pwd)"` 单独构建一个示例）。
