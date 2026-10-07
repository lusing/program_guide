# 龙书扩充：静态分析教程 30→48 章实施计划

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 以绿龙（Aho & Ullman 1977）与紫龙（ALSU 2006）为取材，把 30 章静态分析教程扩充为 48 章：18 个新章逻辑插入、30 个旧章整体重编号，全部自包含蒸馏，三层对账全绿。

**Architecture:** 新章沿用 docs/NN-slug.md ↔ examples/NN_slug 双轨契约；第 13 章 TAC 解释器成为 26/28/34/35/36/43 各章变换的统一语义证人；每批构建-检查-提交一次。

**Tech Stack:** C++17（MSYS2 UCRT64 g++）、ANTLR4（仅词法/前端需要的章节）、LLVM 22.1.8（执行台与 opt 对账需要的章节）、pymupdf（书籍按节抽取）。

**Spec:** docs/superpowers/specs/2026-10-05-dragon-enrichment-design.md（含 48 章结构表、旧→新映射表、每章书源与示例形态表、红线与风险——执行时随身阅读）

## Global Constraints

- 教程叙事体（问题与直觉→形式化→正确性论证→代码落地→输出解读→工程注意点），不是代码罗列；书的内容自包含蒸馏，不指派读者翻原书。
- 每章正文 ≥200 行且文字行多于代码行（fence 翻转计数）；内容优先，不为行数砍功能。
- 每个示例的 src/**、TIP.g4（若存在）、expected/**/*.txt 以 `// file:` / `; expected:` 标记围栏字节级内嵌于对应 docs。
- 验证三件套（一律绝对路径、每条命令自带 `cd /g/code/guide/compiler`；LLVM 示例先 `export PATH=/g/scoop/apps/msys2/current/ucrt64/bin:$PATH`）：
  - `bash tools/example_build.sh examples/NN_slug "$(pwd)"` —— 必须看到 `[build NN OK]` 且 grep 不到 `error:`
  - `python tools/check_example.py "$(pwd)/examples/NN_slug"`（以实际参数形态为准，先看该脚本 main）
  - `python tools/check_docs.py`
- 提交：逐批次、只 stage compiler/ 路径、消息尾注 `Co-Authored-By: Claude Code <noreply@anthropic.com>`；`.scratch/`、`tools/__pycache__/` 永不入库。
- 书籍抽取：`PYTHONIOENCODING=utf-8 python` + pymupdf 按页抽取到 `compiler/.scratch/books/`；两本书的打印页码与 PDF 页码有偏移，先抽样定位再整段抽取。
- 反斜杠纪律：含 `\n` 字面量的代码一律 Write 工具落盘，不走 bash heredoc。
- 构建/运行失败时看完整输出（grep "error:"），绝不信任旧二进制的绿灯。

---

## 批次十一（Task 1）：30 章整体重编号到 48 槽位 ✅（cc84ce7）

**Files:**
- Modify: compiler/docs/*.md（30 个文件改名+改写）、compiler/examples/*（30 个目录改名）、compiler/examples/30_finale/src/survey.cpp、compiler/examples/30_finale/expected/**、compiler/README.md

**Interfaces:**
- Produces: 48 槽位编号体系（映射表见 spec）；旧章全部落位新号；check_example/check_docs 30/30 绿（编号有空洞）。

- [x] **Step 1.1** 读 `tools/check_example.py` 全文确认调用形态与目录发现方式；读 `compiler/examples/30_finale/expected/opt/fold.cmd` 确认内嵌路径。
- [x] **Step 1.2** 写 `.scratch/renumber.py`：
  - MAP = {1:1,2:2,3:3,4:4,5:8,6:10,7:11,8:12,9:16,10:17,11:18,12:19,13:20,14:21,15:22,16:23,17:24,18:25,19:27,20:29,21:30,22:31,23:37,24:38,25:39,26:40,27:41,28:42,29:47,30:48}
  - 两阶段 `git mv`：先全部 mv 到 `_tmp_<new>_<slug>`，再 mv 到最终名（防 5→8 与旧 8 撞名）。
  - docs 改写（fence 状态机跳过代码块内部）：`^#{2,4} NN\.M` 标题号、`第 ?N ?章`（单遍回调映射）、`ch(\d\d)(?:–(\d\d))?`、`examples/NN_slug`、`docs/NN-slug`、行内 `NN\.M 节|NN\.M 小节`。
  - examples/*/src/** 与 expected/**/*.cmd 同样改写（跳过围栏内不需要——直接文件改写后再重生成内嵌）。
  - survey.cpp 的 ch 范围串机械映射端点；README 章号行重排映射。
- [x] **Step 1.3** 跑重编号脚本；`git status` 检查 rename 检出正常。
- [x] **Step 1.4** 从磁盘重生成全部 docs 的标记内嵌块（修复改名后 .cmd 等字节差异）；对每篇 docs 做『第 N 章』多重集校验：旧号 k 的出现次数 == 新号 MAP[k] 的出现次数（分文档统计），抽样人工 diff 三个文档全文。
- [x] **Step 1.5** 全量验证：30 个示例重建 + check_example + check_docs 全绿（看完整输出）。
- [x] **Step 1.6** 提交：`feat(compiler): 批次十一——30 章重编号至 48 槽位（30/30 全绿）`。

## 批次十二（Tasks 2–4）：前端理论三章 05/06/07 ✅（d845681）

### Task 2: 05 正则与自动机（05_regex_automata / docs/05-regex-automata.md）

**Files:** Create: examples/05_regex_automata/{src/re.hpp,src/re.cpp,src/main.cpp}、expected/output.txt、programs/samples.txt（判定样例串）
**书源：** 绿§3.3–3.6、紫§3.6–3.9（抽取到 .scratch/books/ 精读）。

- [x] Step 2.1 抽取书源节文本。
- [x] Step 2.2 实现 re.hpp/re.cpp：RE AST（symbol/alt/concat/star）、thompson()、subset()（ε-closure+move）、minimize()（等价类分割）；main.cpp --check 打印 TIP 三类 token 模式（标识符/整数/关键字 if）的 NFA/DFA/最小 DFA 状态数与最小 DFA 转移表，并对样例串打印接受/拒绝。
- [x] Step 2.3 programs + expected 落盘；build → check_example 绿。
- [x] Step 2.4 写 docs/05：正则式形式定义与封闭性→NFA/DFA 形式定义→Thompson 构造及正确性归纳思路→子集构造→最小化的分割不变式→为什么 aⁿbⁿ 超出正则（泵引理直觉）引出第 6 章；全文内嵌三件源码与期望输出。
- [x] Step 2.5 check_docs 绿。

### Task 3: 06 LL 分析（06_ll_parsing / docs/06-ll-parsing.md）

**Files:** Create: examples/06_ll_parsing/{TIP.g4,src/grammar.hpp,src/grammar.cpp,src/ll1.hpp,src/ll1.cpp,src/main.cpp,src/frontend 基础件按需最小集}、programs/{expr.tip,bad.tip}、expected/output.txt
**书源：** 绿§5.4–5.5、紫§4.4（含左递归消除、FIRST/FOLLOW、LL(1) 表、预测分析法、ε 产生式）。

- [x] Step 3.1 用 ANTLR lexer 供 token 流（TIP.g4 复制自 04 章），语法子集 expr/term/factor + if/while。
- [x] Step 3.2 实现 ll1.cpp：FIRST/FOLLOW 不动点计算、LL(1) 表构造+冲突检测、驱动栈预测分析；main --check FILE 打印集合、表、对 expr.tip 的产生式轨迹（接受）与 bad.tip 的报错点。
- [x] Step 3.3 expected + 三件套绿。
- [x] Step 3.4 写 docs/06：自顶向下与回溯之痛→左递归消除与左公因子（算法+例子）→FIRST/FOLLOW 归纳定义与不动点计算（回望 23 章工作表思想）→LL(1) 条件与冲突→预测分析器与递归下降的同构→ANTLR 的 ALL(*) 是这个框架的现代外推（一段工程注记）。

### Task 4: 07 LR 分析（07_lr_parsing / docs/07-lr-parsing.md）

**Files:** Create: examples/07_lr_parsing/{TIP.g4,src/items.hpp,src/items.cpp,src/slr.cpp,src/main.cpp,…}、programs/{expr.tip,ambig.tip}、expected/output.txt
**书源：** 绿§6.1–6.5、紫§4.5–4.8（项与 closure/goto、SLR 表、LR(1) 搜索符、LALR 合并、冲突、悬挂 else、二义文法+优先级）。

- [x] Step 4.1 items.cpp：LR(0) 项集族构造，逐集打印。
- [x] Step 4.2 slr.cpp：ACTION/GOTO 构造（FOLLOW 剪枝）、冲突报告；main --check：表 + expr.tip 的 shift/reduce 轨迹 + ambig.tip 的冲突演示（悬挂 else 移进偏好）。
- [x] Step 4.3 expected + 三件套绿。
- [x] Step 4.4 写 docs/07：句柄与规范归约→项=『期望看到什么』→closure/goto 直觉→SLR 为什么用 FOLLOW 剪、何时不够（给 LR(1) 例子）→LALR 同核合并→冲突两类与 yacc 优先级声明→悬挂 else 的移进偏好语义论证→回望 ANTLR/ yacc 的家谱。

- [x] **批次十二收尾**：三示例全绿 → 提交 `feat(compiler): 批次十二——05-07 正则自动机/LL/LR 前端理论（全绿）`。

## 批次十三（Tasks 5–7）：SDT 09、TAC 13、活动记录 14 ✅

### Task 5: 09 语法制导翻译（09_sdt / docs/09-sdt.md）

**Files:** Create: examples/09_sdt/{src/sdd.hpp,src/sdd.cpp,src/main.cpp}、programs/decl.tip、expected/output.txt（纯算法章可无 TIP.g4；decl.tip 作为数据被解析或直接硬编码文法+测试串——以实现选择为准，保证自包含）
**书源：** 绿§7.1–7.2、紫§5.1–5.5（SDD、综合/继承、依赖图、求值序、S-/L-属性、翻译方案）。

- [x] Step 5.1 sdd.cpp：文法+语义规则表、依赖图构造、拓扑求值；两个内置 SDD：表达式→后缀（综合）、声明块→偏移布局（继承 offset）。
- [x] Step 5.2 main --check：依赖图边表、属性值表、后缀求值==表达式值的对账行、偏移总和断言。
- [x] Step 5.3 expected + 三件套绿。
- [x] Step 5.4 写 docs/09：属性文法=文法+语义代数→依赖图与任意拓扑序求值→S-属性（一遍自底向上）与 L-属性（一遍深度优先）两个可单遍的子族→翻译方案=动作嵌入位置语义（动作在左/右的差别例子）→回望第 8 章 ast_build 访问者就是 L-属性方案的现代写法。

### Task 6: 13 三地址码与基本块（13_tac_blocks / docs/13-tac-blocks.md）

**Files:** Create: examples/13_tac_blocks/{TIP.g4,src/tacgen.hpp,src/tacgen.cpp,src/blocks.cpp,src/tacinterp.cpp,src/main.cpp,src/前端基础件(ast/ast_build/symtab/cfg 按需),src/irgen.*,src/jitrun.*,llvm.need}、programs/{fold.tip 及带分支循环一例}、expected/output.txt
**书源：** 绿§7.3–7.10、紫§6.2、8.4（三地址指令族、四元组/三元组/间接三元组、布尔与控制流翻译、leader、基本块、next-use）。

- [x] Step 6.1 tacgen.cpp：AST→TAC（临时编号、短路布尔、控制流标号）；blocks.cpp：leader 划分+块表+块内 next-use（后向一趟）。
- [x] Step 6.2 tacinterp.cpp：TAC 解释器（input/output 语义与 JIT 口径一致）；main --check：TAC 全文、块划分、next-use 表、解释器 outputs、与 JIT 同输入对账行 `interp==jit`（llvm.need + irgen/jitrun 复制自 12 章示例）。
- [x] Step 6.3 expected + 三件套绿。
- [x] Step 6.4 写 docs/13：为什么需要机器无关 IR→四元组/三元组的表示权衡→TAC 生成（每语言构造一小节走读）→leader 规则与块划分正确性→next-use 的局部反向一趟→TAC 解释器=具体语义证人（为 26/28/34/35/36/43 铺路）→LLVM IR 与 TAC 的对照片段。

### Task 7: 14 栈与活动记录（14_activation_records / docs/14-activation-records.md）

**Files:** Create: examples/14_activation_records/{src 复制 13 章 tacgen 等 + src/vm.hpp,src/vm.cpp,src/main.cpp}、programs/{calls.tip,nested.tip}、expected/output.txt
**书源：** 绿§10.1–10.2、紫§7.1–7.3（存储组织、活动树、活动记录、调用/返回序列、访问链、display 概念、变长数据一句）。

- [x] Step 7.1 vm.cpp：显式帧栈机器执行 13 章 TAC——帧含返回地址/控制链/局部槽；调用序列与返回序列分步打印帧轨迹。
- [x] Step 7.2 nested.tip 演示访问链（嵌套函数读外层变量沿链爬行）；display 数组作为替代方案在正文对照。
- [x] Step 7.3 main --check：帧布局图 + 调用轨迹 + outputs 与 13 章解释器逐字节对账行。
- [x] Step 7.4 expected + 三件套绿；写 docs/14（活动树与递归的栈本质→记录布局设计权衡→两个序列的分工→访问链 vs display→TIP 闭包=把访问链装箱带走，连接第 3 章）。

- [x] **批次十三收尾**：三示例全绿 → 提交 `feat(compiler): 批次十三——09/13/14 SDT、三地址码、活动记录（全绿）`。

## 批次十四（Tasks 8–10）：GC 15、到达+非常忙 26、框架定理 28 ✅

### Task 8: 15 垃圾回收（15_garbage_collection / docs/15-garbage-collection.md）

**Files:** Create: examples/15_garbage_collection/{src/heap.hpp,src/heap.cpp,src/collectors.cpp,src/main.cpp}、programs/graph.txt（确定性对象图+根集）、expected/output.txt（无 ANTLR）
**书源：** 紫§7.4–7.8（堆管理碎片、可达性、引用计数与环、mark-sweep、mark-compact、Cheney 复制、分代假说、保守式收集）。

- [x] Step 8.1 heap.cpp：模拟堆（对象=槽位数+指针槽）、确定性构建 API。
- [x] Step 8.2 collectors.cpp：引用计数（增减+环泄漏计数）、标记清除（工作表）、Cheney 复制（到空间指针重定向）。
- [x] Step 8.3 main --check：同一图三收集器的存活/回收计数、环样例上 refcount 泄漏而 tracing 回收的钉子行、复制后地址映射表。
- [x] Step 8.4 expected + 三件套绿；写 docs/15（堆为什么碎片→可达性=从根出发的最小不动点（前望 22 章）→引用计数的优雅与环之死→标记清除与工作表（回望 23 章）→Cheney 的指针翻转图解→分代假说→保守式与精确式、LLVM/ BoehM 一句工程注记）。

### Task 9: 26 到达定值与非常忙表达式（26_reaching_verybusy / docs/26-reaching-verybusy.md）

**Files:** Create: examples/26_reaching_verybusy/{复制 13 章 TAC 基座 + src/reach.cpp,src/verybusy.cpp,src/apps.cpp}、programs/{copy.tip,hoist.tip}、expected/output.txt
**书源：** 绿§14.1–14.6、紫§9.2.4、9.2.6（到达定值、ud 链、复制传播、非常忙、代码提升、四类问题总表）。

- [x] Step 9.1 reach.cpp：gen/kill、前向 may 方程、worklist、ud 链查询表。
- [x] Step 9.2 verybusy.cpp：后向 must；apps.cpp：复制传播（删除被传播的 copy 定值）与代码提升（把非常忙计算提到汇合点）。
- [x] Step 9.3 main --check：两分析逐块结果、ud 链样例查询、变换前后 TAC、解释器 outputs 对账（保义）、定值计数下降行。
- [x] Step 9.4 expected + 三件套绿；写 docs/26（补全四大经典：2×2 方向×may/must 总表（绿龙 14.6 的表完整转写）→到达定值方程与 ud 链→复制传播的删除条件（为什么被处处替换的 copy 才能删）→非常忙与代码提升的语义条件（不安全提升的反例）→四分析与 25 章两分析在『交/并半格』上的统一）。

### Task 10: 28 数据流框架定理（28_dfa_framework / docs/28-dfa-framework.md）

**Files:** Create: examples/28_dfa_framework/{复制 13 章 TAC 基座 + src/framework.hpp,src/instances.cpp,src/mop.cpp,src/constprop.cpp}、programs/{diamond.tip,four.tip}、expected/output.txt
**书源：** 紫§9.3（半格、转移函数单调、迭代算法、解的含义 MOP/MFP）、紫§9.4（常量传播非分配性）、绿§14.6。

- [x] Step 10.1 framework.hpp：框架=(半格, 转移, 方向) 的函数对象化求解器；instances.cpp：到达/活跃/可用/非常忙四实例。
- [x] Step 10.2 mop.cpp：小程序上路径枚举（深度界 K）算 MOP；constprop.cpp：常量传播实例（复用 24 章格）。
- [x] Step 10.3 main --check：四实例结果与 25/26 章独立实现逐块相等（强对账行）、diamond.tip 上常量传播 MFP<MOP 的差集打印、分配性实例上 MFP==MOP。
- [x] Step 10.4 expected + 三件套绿；写 docs/28（半格框架公理化→单调性为什么是收敛的引擎（高度×单调⇒有限步，证明思路完整转写）→MOP 理想解定义→MFP≤MOP 定理与证明思路→分配性等号与常量传播反例（紫 9.4.5 的菱形例子完整算给读者看）→框架视角把 20–27 章九个分析装进一个引擎）。

- [x] **批次十四收尾**：三示例全绿 → 提交 `feat(compiler): 批次十四——15/26/28 GC、四大分析补全、框架定理（全绿）`。

## 批次十五（Tasks 11–13）：支配者 32、SSA 33、DAG 34 ✅（5d41e90 + 本次）

### Task 11: 32 支配者与自然循环（32_dominators / docs/32-dominators.md）

**Files:** Create: examples/32_dominators/{CFG 基座（复制 11 章 cfg）+ src/dom.cpp,src/dfs.cpp,src/loops.cpp}、programs/{loop.tip,irreducible.tip}、expected/output.txt
**书源：** 绿§13.1–13.3、紫§9.6（支配者迭代解、支配树、DFS 与边分类、回边、可归约性、自然循环、循环嵌套）。

- [x] Step 11.1 dom.cpp：迭代支配集（init=全集）、idom 归纳、支配树打印；性质自检（自反/传递/反对称+树推导==迭代）。
- [x] Step 11.2 dfs.cpp：深度优先伸展树+边分类（后退/前进/交叉）；loops.cpp：回边→自然循环（反向可达∩支配 header 的后代）+嵌套森林；irreducible.tip 演示不可归约图。
- [x] Step 11.3 expected + 三件套绿；写 docs/11 对应文档：支配的偏序直觉→迭代方程=最大不动点（回望 22 章）→支配树为什么是树（idom 唯一性论证）→DFS 边分类规则→自然循环定义的两条件各自拦什么→可归约性=结构化控制流的图论化身→LLVM/ GCC 里这些算法的位置。

### Task 12: 33 SSA 形式（33_ssa / docs/33-ssa.md）

**Files:** Create: examples/33_ssa/{复制 13 章 TAC 基座 + 32 章 dom 基座 + src/df.cpp,src/ssa.cpp,src/ssarun.cpp}、programs/{phi.tip}、expected/output.txt、expected/opt/mem2reg.{cmd,out}
**书源：** 紫§6.2.4（SSA 定义）、紫书 SSA 构造节（支配边界、φ 插入、改名；执行时以抽取文本定位小节号）、绿§14.3 呼应。

- [x] Step 12.1 df.cpp：CHK 支配边界算法；ssa.cpp：iterated DF 的 φ 插入（live-in 过滤）+支配树栈式改名；ssarun.cpp：SSA 文本解释器。
- [x] Step 12.2 main --check：DF 表、φ 插入结果、SSA 全文、单定值断言、解释 outputs==TAC 解释 outputs。
- [x] Step 12.3 opt 对账：`tipa --emit-ir | opt -mem2reg -S` 的 phi 行 grep 进 expected/opt/mem2reg.out（版本敏感契约，照 48 章先例写 .cmd）。
- [x] Step 12.4 三件套绿；写 docs/33（唯一定值为什么值钱（定义-使用链免费、优化不必在乎别名）→φ 的并行语义（顺序化反例）→支配边界的定义与 CHK 算法推导→φ 插入的 iterated DF 收敛性→栈式改名的支配树序正确性→critical edge 与截断 SSA→mem2reg 对照读 LLVM Dump）。

### Task 13: 34 基本块 DAG（34_dag_local / docs/34-dag-local.md）

**Files:** Create: examples/34_dag_local/{复制 13 章 TAC 基座 + src/dag.cpp}、programs/{cse.tip}、expected/output.txt
**书源：** 绿§12.3–12.4（DAG 构造、值编号、代数定律）、紫§8.5、§6.1.2。

- [x] Step 13.1 dag.cpp：结点+标识表、交换律规范键、代数恒等式表命中即折叠、重发射（叶优先拓扑序）；死标识不发射。
- [x] Step 13.2 main --check：DAG 文本形态（结点表）、恒等式命中计数、变换前后 TAC、指令数下降行、解释器对账。
- [x] Step 13.3 expected + 三件套绿；写 docs/34（局部 vs 全部的分界→DAG 构造算法逐指令走读→为什么交换律要规范键（a+b 与 b+a 同结点）→代数恒等式表与强度削减呼应 35 章→从 DAG 重发射的自由度与约束（数组/指针槽保守规则，绿龙原书规则的完整转写）→值编号与 GVN 一句工程注记）。

- [x] **批次十五收尾**：三示例全绿 → 提交 `feat(compiler): 批次十五——32/33/34 支配者、SSA、DAG（全绿）`。

## 批次十六（Tasks 14–15）：循环优化 35、PRE 36 ✅

### Task 14: 35 循环优化（35_loop_opt / docs/35-loop-opt.md）

**Files:** Create: examples/35_loop_opt/{复制 13 章 TAC + 32 章循环基座 + src/licm.cpp,src/indvar.cpp}、programs/{invariant.tip,strength.tip}、expected/output.txt
**书源：** 绿§13.4–13.6（不变式计算三条件、归纳变量、强度削减、归纳变量消减）、紫§9.1.6–9.1.8、9.6。

- [x] Step 14.1 licm.cpp：自然循环+preheader 插入+不变式判据（绿龙三条件完整实现：支配所有出口/循环内唯一定值/使用处全被该定值支配）；不安全样例逐条件反例。
- [x] Step 14.2 indvar.cpp：基本/派生归纳变量识别、强度削减（i*c→j=j+c）、用判据替换的消减；乘法计数前后对比。
- [x] Step 14.3 main --check：循环表、外提计数、变换前后 TAC、多输入流解释器对账、乘法计数下降。
- [x] Step 14.4 expected + 三件套绿；写 docs/35（循环=时间的 90%→preheader 的容器角色→三条件逐条的语义必要性（每条给一个删掉就错的反例，转写绿龙论证）→归纳变量的代数骨架→强度削减的正确性论证（不变式 j≡i*c 的归纳证明思路）→消减的收益与风险→LLVM indvars/loop-rotate 工程注记）。

### Task 15: 36 部分冗余消除（36_pre / docs/36-pre.md）

**Files:** Create: examples/36_pre/{复制 13 章 TAC 基座 + src/pre.cpp}、programs/{partial.tip}、expected/output.txt
**书源：** 紫§9.5 全节（冗余来源四象限、lazy code motion、anticipated/available/earliest/postponable/latest/used 六方程、算法、不能全消除的边界）。

- [x] Step 15.1 pre.cpp：六方程求解（两后向 must、两前向 must、两收尾）+插入/删除集计算+TAC 改写。
- [x] Step 15.2 main --check：六方程逐块摘要、插入/删除位置表、变换前后计算次数对比、解释器对账。
- [x] Step 15.3 expected + 三件套绿；写 docs/35 对应文档：四象限（全冗余/部分冗余×已算/未算）的地图→为什么『最晚+仅一次』两个目标会打架（紫书反例转写）→六方程逐条：每条的方向与 must 语义、与 25/26 章四分析的家族相认→插入与删除集的推导→算法正确性论证思路→为什么 PRE 是数据流分析的集大成者（一段收官式议论）。

- [x] **批次十六收尾**：两示例全绿 → 提交 `feat(compiler): 批次十六——35/36 循环优化、部分冗余消除（全绿）`。

## 批次十七（Tasks 16–17）：寄存器分配 43、指令选择与窥孔 44 ✅

### Task 16: 43 寄存器分配（43_regalloc / docs/43-regalloc.md）

**Files:** Create: examples/43_regalloc/{复制 13 章 TAC 基座 + src/live.cpp（简化重实现块级活跃）,src/interf.cpp,src/color.cpp,src/spill.cpp}、programs/{spill.tip}、expected/output.txt
**书源：** 绿§15.5、紫§8.8（全局分配、使用计数、图着色法、Chaitin-Briggs simplify/select、溢出）。

- [x] Step 16.1 interf.cpp：活跃范围→干涉图（def 点特判：顺序活跃不算干涉）；color.cpp：simplify 栈+select+潜在溢出重命名循环（上限 3 轮）；spill.cpp：溢出变量改写为 load/store TAC。
- [x] Step 16.2 main --check：干涉边表、k=3 着色分配、相邻异色断言、spill.tip 触发溢出的改写与栈槽数、解释器对账。
- [x] Step 16.3 expected + 三件套绿；写 docs/43（寄存器=最快的存储→分配问题=图着色的归约（构造性证明：活跃⇒相邻）→Chaitin-Briggs 的栈戏法（可 k-着色子图一定能选回）→溢出的代价与重跑→合并 coalescing 的收益与破坏着色性（Briggs 悲观/乐观准则一段）→LLVM 的 greedy/ basic 分配器一句注记）。

### Task 17: 44 指令选择与窥孔（44_isel_peephole / docs/44-isel-peephole.md）

**Files:** Create: examples/44_isel_peephole/{复制 13 章 TAC 基座 + src/risc.hpp,src/risc.cpp,src/munch.cpp,src/peephole.cpp,src/riscrun.cpp}、programs/{expr.tip}、expected/output.txt
**书源：** 绿§15.3–15.7、紫§8.2（机器模型与代价）、8.6–8.9（描述符/getReg 思路、窥孔五族）、8.9 树覆盖、8.10 Ershov 数。

- [x] Step 17.1 risc.cpp：8 条指令迷你 RISC + 汇编文本；munch.cpp：表达式树 maximal munch tile 表+代价；peephole.cpp：模式族（冗余 load/store、跳到跳转、代数化简、强度削减、机器习语）反复扫描至不动点；riscrun.cpp：RISC 解释器。
- [x] Step 17.2 main --check：tile 序列+代价、窥孔逐模式命中计数、前后指令数、RISC 解释 outputs 对账。
- [x] Step 17.3 expected + 三件套绿；写 docs/44（目标机抽象到什么程度才既简单又真实→树覆盖=语法分析的重演（tile=产生式，maximal munch=贪心归约）→Ershov 数：表达式树的最小寄存器数（算法与证明思路完整转写）→窥孔=局部模式重写的不动点（与 34 章 DAG 的分工）→五族模式逐条走读→真编译器的 selectionDAG/ MachinePass 注记）。

- [x] **批次十七收尾**：两示例全绿 → 提交 `feat(compiler): 批次十七——43/44 寄存器分配、指令选择与窥孔（全绿）`。

## 批次十八（Tasks 18–19）：指令级并行 45、并行与局部性 46 ✅

### Task 18: 45 指令级并行（45_ilp / docs/45-ilp.md）

**Files:** Create: examples/45_ilp/{复制 13 章 TAC 基座 + src/deps.cpp,src/sched.cpp,src/modulo.cpp}、programs/{block.tip,pipeline.tip}、expected/output.txt
**书源：** 紫§10.1–10.3 重点（依赖三类、内存依赖保守判定、基本块依赖 DAG、表调度+优先级）、10.4 概念级、10.5（软件流水/modulo scheduling 思想）。

- [x] Step 18.1 deps.cpp：真/反/输出依赖边、内存访问一律保守（数组两个引用就依赖）；sched.cpp：关键路径优先的表调度，发射宽度 1 与 2 两种，输出周期数。
- [x] Step 18.2 modulo.cpp：两指令小循环的 modulo schedule（II=⌈max(资源, 递归依赖)⌉ 计算+展开流水打印）；调度后指令序重放断言（依赖不破）。
- [x] Step 18.3 expected + 三件套绿；写 docs/45（流水线为什么把顺序暴露成浪费→三类依赖的准确定义（每类一个反例）→内存依赖为什么只能保守（指向分析回望 42 章）→依赖 DAG 与关键路径=调度的下界→表调度贪心的正确性（拓扑序不破依赖）与次优性反例→寄存器压力与调度的相位次序问题→软件流水：重排迭代重叠执行、II 下界两个来源）。

### Task 19: 46 并行与局部性（46_parallel_locality / docs/46-parallel-locality.md）

**Files:** Create: examples/46_parallel_locality/{src/affine.cpp,src/interchange.cpp,src/cachesim.cpp,src/main.cpp}、expected/output.txt（纯模拟章）
**书源：** 紫§11.1–11.6 精选（循环级并行、迭代空间、仿射变换、数据复用、数组依赖与 GCD 检验、交换与分块）。

- [x] Step 19.1 affine.cpp：访问矩阵→方向向量→GCD 检验（依赖存在性）；interchange.cpp：交换合法性（方向向量无 <-分量）；cachesim.cpp：直接映射缓存模拟器跑嵌套循环访存序列。
- [x] Step 19.2 main --check：依赖检验结果表、交换合法性判定、N=8 小例子上 原序/交换/2×2 分块 三种 miss 计数对比 + 行主序下交换后 miss 上升的钉子行。
- [x] Step 19.3 expected + 三件套绿；写 docs/46（乘法三层循环做贯穿例子（紫书同款）→迭代空间=整点格、循环变换=格上的仿射双射→依赖的方向向量与 GCD 检验（数论一步不跳）→交换合法性定理→缓存行、空间/时间局部性、直接映射冲突→三种顺序的 miss 手算与机算对照→tiling 分块把复用装进缓存窗口→自动并行化与 Polly 注记）。

- [x] **批次十八收尾**：两示例全绿 → 提交 `feat(compiler): 批次十八——45/46 指令级并行、并行与局部性（全绿）`。

## 批次十九（Task 20）：收官章 48 更新与 README 定稿 ✅

**Files:** Modify: examples/48_finale/{src/survey.cpp,src/survey.hpp,expected/output.txt 及其它受影响 expected}、docs/48-finale.md、compiler/README.md

- [x] Step 20.1 survey.cpp 扩表：48 章体系下的新行（到达/非常忙/框架定理/支配者/SSA/DAG/循环优化/PRE/活动记录/GC/寄存器/指令选择/ILP/局部性/自动机/LL/LR/SDT），字段与口径沿用（域/方向/敏感维/可靠性）；动态计数沿用。
- [x] Step 20.2 重新生成 expected/output.txt；docs/48 的『每章一句话』从 30 句扩到 48 句（新序号新顺序）、正文相关段落同步改写（survey 解读、骨架使用次数统计重算：格上不动点/单调闭包/归纳与配对三家族的章号清单全部更新）。
- [x] Step 20.3 README 定稿：十篇 48 章全导航、龙书渊源说明（两本书各贡献了什么）、插入式阅读建议（如 5–7 紧接第 4 章、13–15 紧接第 12 章）。
- [x] Step 20.4 全量回归：48 个示例 build + check_example + check_docs 全绿（看完整输出、逐个确认 `[build OK]`）。
- [x] Step 20.5 提交：`feat(compiler): 批次十九——48 章收官更新与 README 定稿（48/48 全绿）`。
- [x] Step 20.6 更新记忆文件 compiler-tutorial-build.md（48 章结构、重编号脚本经验、新坑）。

## Self-Review 结论

- 覆盖：spec 的 18 个新章各有 Task；两书核心章节（绿 3/5/6/7/10/12/13/14/15、紫 3/4/5/6/7/8/9/10/11）全部映射到任务；紫§12 与绿§8/9/11 不加新章（已覆盖/低收益），在收官章延伸阅读中交代。
- 一致性：所有『复制 NN 章基座』均指按 house 风格把源文件复制进本章示例目录（每例自包含全部 src，不跨目录引用）——与既有 30 例的组织方式一致。
- 风险集中点：Task 1（重编号）改写面最大，已配多重集校验与抽样人审；Task 12/15 概念最重，doc 篇幅不设上限。
