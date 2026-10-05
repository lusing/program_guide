# 鲸书轮扩充实施计划（EAC 2e → 60 章）

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [x]`) syntax for tracking.

**Goal:** 以 Cooper & Torczon《Engineering a Compiler》2e（鲸书）为第四轮取材，在现有 54 章基础上新增 6 章、补充 4 章，重编号为 60 章；每章自包含蒸馏原书内容（不让读者翻原书），全部示例三层对账全绿。

**Architecture:** 沿用三轮验证过的模式：批式推进（重编号→逐新章→补充→收官）、每章 `docs/NN-<slug>.md` + `examples/NN_<slug>/`（章号=示例号）、机器证人（断言 + outputs 语义对账）、`check_docs.py` 字节级内嵌校验。鲸书 PDF 文本层完好（正文页偏移 +24），无需 OCR。

**Tech Stack:** C++23（MSYS2 UCRT64 g++）、ANTLR4、LLVM 22.1.8（按需）、Python 校验脚本。

**Spec:** 用户四轮恒定要求——教程而非代码罗列；讲解的代码正文引用；书籍内容提炼核心自包含；没有篇幅限制讲清楚为止。鲸书轮用户拍板：全量 6 新章 + 4 补充（60 章），重编号逻辑插入。

## Global Constraints

- 每章正文 ≥200 行且**文字行多于代码行**（fence 翻转计数）。
- 示例的 src/*.cpp|hpp、src/TIP.g4（如有）、expected/output.txt 全部以 `// file:` / `; expected:` 围栏**字节级内嵌**进正文（`tools/embed.py` 生成）。
- 三层对账：`tools/example_build.sh` → `tools/check_example.py` → `tools/check_docs.py` 全绿后才提交。
- 提交只 stage `compiler/` 路径；消息尾注 `Co-Authored-By: Claude Code <noreply@anthropic.com>`；`.scratch/`、`tools/__pycache__/` 永不入库。
- 工具链：`export PATH=/g/scoop/apps/msys2/current/ucrt64/bin:$PATH`，绝对路径调 g++/antlr/opt。
- 教学口径：鲸书 ILOC 伪码改写为 TIP 三地址码/C++23；每章注明取材节号（如"鲸书 §10.7.2"）。

## 重编号映射（旧→新）

| 旧 | 新 | | 旧 | 新 | | 旧 | 新 |
|---|---|---|---|---|---|---|---|
| 1–7 | 1–7 | | 21→23 … 29→31 | +2 | | 44 | 48 |
| **新** | **8** | | 30 | 32 | | 45 | 49 |
| 8 | 9 | | 31 | 33 | | 46 | 50 |
| 9 | 10 | | 32 | 34 | | 47 | 51 |
| 10 | 11 | | 33 | 35 | | 48 | 52 |
| 11 | 12 | | 34 | 36 | | **新** | **53** |
| 12 | 13 | | 35 | 37 | | 49 | 54 |
| 13 | 14 | | 36 | 38 | | 50 | 55 |
| **新** | **15** | | **新** | **39** | | 51 | 56 |
| 14 | 16 | | 37 | 40 | | 52 | 57 |
| 15 | 17 | | **新** | **41** | | **新** | **58** |
| 16 | 18 | | 38 | 42 | | 53 | 59 |
| 17–20 | 19–22 | | 39 | 43 | | 54 | 60 |
| | | | 40–43 | 44–47 | | | |

新章槽位与插入点：8（旧 07 后）、15（旧 13 后）、39（旧 36 后）、41（旧 37 后）、53（旧 48 后）、58（旧 52 后）。

---

### Task 1: 重编号 54→60

**Files:**
- Modify: `docs/NN-*.md` ×53、`examples/NN_*/` ×53、`README.md`、`docs/54-finale.md`（改 60-finale）
- Create: `.scratch/renumber3.py`（复用 renumber.py 骨架换映射）

- [x] 检查 renumber2.py 骨架，换 MAP 为上表，跑重编号（两阶段 git mv + 单遍回调改引用 + 哨兵防二次映射）
- [x] 计数多重集校验：新旧文件集合各 53+6（新章 Task 2-7 建），README/交叉引用全改
- [x] 全量三层回归基线（54 章）仍绿（此时新章未建、README 暂列 60 目标）
- [x] Commit: `feat(compiler): 批次二十八——54→60 重编号腾位（鲸书轮开工）`

### Task 2: 新 08 章 LR(1) 与 LALR 造表（鲸书 §3.4.2/§3.6.2/§3.7）

**Files:**
- Create: `docs/08-lr1-lalr.md`、`examples/08_lr1_lalr/src/{lr1.hpp,lr1.cpp,main.cpp}`、`examples/08_lr1_lalr/expected/output.txt`

内容：LR(0)→LR(1) 的 lookahead 动机；LR(1) 项 [A→α·β, a] 与 FIRST(βa)；CLOSURE/GOTO 带 lookahead；规范 LR(1) 项集族与 ACTION/GOTO 造表；**同心集合并 = LALR(1)**（合并后冲突可能新增但只可能是归约-归约）；SLR/LALR/规范 LR 三级对比（鲸书 §3.7 视角）；表压缩思路（同行列合并，§3.6.2）。示例：文法硬编码构造三表，绿龙 L=R 文法（07 章 SLR 冲突例）在 LR(1) 下无冲突。
断言：(1) 规范 LR(1) 对 L=R 文法零冲突而 SLR 有冲突；(2) LALR 状态数 < 规范 LR(1)；(3) 两表对合法输入接受一致（跑两个串）。**无 ANTLR**（纯算法章，简单程序对账协议）。

- [x] 写 src + 跑通断言 → expected 落盘
- [x] 写正文（嵌入、期望输出解读、练习）
- [x] 三层对账绿 → Commit: `feat(compiler): 批次二十九——08 LR(1) 与 LALR 造表`

### Task 3: 新 15 章 代码形状：数组、字符串与跳转表（鲸书 §7.5–7.8）

**Files:**
- Create: `docs/15-code-shape.md`、`examples/15_code_shape/src/{shape.hpp,shape.cpp,main.cpp}`、`examples/15_code_shape/expected/output.txt`

内容：值住哪（存储类别）；**数组地址多项式**：一维 `@A+(i−low)×w` → 二维行主序 `@A+(i−low1)×len2×w+(j−low2)×w` → **假零**调整 `@A0+(i×len2+j)×w`（省两次减法与一次乘法）；列主序与**间接向量**（每维两操作、锯齿数组）；**dope vector**（运行期形状描述子）；字符串三表示（定长/长度前缀/零终止）与 length(a+b) 的两种代价；**case 三策略**：线性链（按频度排序）、二分、跳转表 `@Table+t1×4`（密集选择、洞填 default）。示例：地址多项式展开 vs 枚举直查对账；case 策略按 (数量,密度) 自动选择并打代价对比。
断言：(1) 二维/三维地址公式与逐元素枚举一致；(2) 假零版与朴素版地址相等；(3) 密集 case 选跳转表且期望比较次数 < 线性链；(4) 稀疏 case 选二分。**无 ANTLR**。

- [x] src + 断言 → expected → 正文 → 三层绿 → Commit: `feat(compiler): 批次三十——15 代码形状（数组/字符串/case）`

### Task 4: 新 39 章 超局部与支配者值编号 SVN/DVNT（鲸书 §8.5.1+§10.5.2）

**Files:**
- Create: `docs/39-svn-dvnt.md`、`examples/39_svn_dvnt/src/{svn.hpp,svn.cpp,main.cpp}` + 本地 tac/tacgen/tacinterp 副本（35 章模式）

内容：LVN 的块界之痛；**EBB** 定义（单前驱链）；**SVN**：作用域化散列表（进块开 scope、退块删 scope）、递归沿单后继深入、多前驱块进 WorkList 空表重来；SSA 名字保证"删 scope 即撤销"；**DVNT**：沿**支配树**先序递归，φ 三判（无义/冗余/新值——无义 φ 直接删）、赋值按 LVN 处理但用 SSA 名做值号、后继 φ 参数改写（与改名阶段同型）、反直觉访问序（B4 可先于 B2/B3）；SVN 抓不到连接块的冗余而 DVNT 能；DVNT 不沿回边传播 vs LCM 能（复习 42 章 PRE）。示例程序：块间冗余（SVN 抓到）、连接块冗余（仅 DVNT 抓到）、无义 φ。
断言：(1) LVN 消 0 条、SVN 消 N1 条、DVNT 消 N2≥N1 条（同一程序三阶梯）；(2) 优化前后 outputs 相等（解释器对账）；(3) 无义 φ 数下降。

- [x] src（复用 34 章 SSA 构造本地副本 + 33 章支配树）+ 断言 → expected → 正文 → Commit: `feat(compiler): 批次三十一——39 超局部与支配者值编号`

### Task 5: 新 41 章 强度削减与线性函数测试替换（鲸书 §10.7.2）

**Files:**
- Create: `docs/41-strength-reduction.md`、`examples/41_strength_reduction/src/{osr.hpp,osr.cpp,main.cpp}` + 本地 SSA 副本

内容：循环里的 `i×4` 重复付费；**region constant**（字面常量或支配归纳变量 header 的定义）与**归纳变量 = SSA 图的 SCC**（四类合法更新：iv±rc、φ、copy）；Tarjan DFS 弹 SCC 顺序 = 操作数先于使用被分类；header = SCC 中最低 RPO 号节点；候选五型 `c×i/i×c/c+i/i+c/i−c`；**Replace/Reduce/Apply**：克隆 SCC 造新归纳变量、乘法增量乘 rc、哈希防重复；**LFTR**：`i≤n` 换 `i4≤n×4`（当 i 已死）；数组地址 `(i−1)×4+@a` 全链削减示例（鲸书 Figure 10.11 口径，ILOC→TAC 改写）；削减后原链死码由 DCE 收尾。示例程序：`for i=1..100: s = s + a[i]`（a 定长数组，地址算术显式写）。
断言：(1) 循环内 Mul 条数下降（2→0）；(2) Add 新增恰为每归纳变量每圈一条；(3) outputs 相等；(4) 非候选（两个都非归纳变量）不动。

- [x] src + 断言 → expected → 正文 → Commit: `feat(compiler): 批次三十二——41 强度削减与 LFTR`

### Task 6: 新 53 章 局部寄存器分配与 SSA 弦图（鲸书 §13.3+§13.5.2）

**Files:**
- Create: `docs/53-ssa-alloc.md`、`examples/53_ssa_alloc/src/{alloc.hpp,alloc.cpp,main.cpp}` + 本地 TAC/活跃副本

内容：分配 vs 指派；**自顶向下局部分配**：频率计数排序、留 F 个可行寄存器、整块独占（缺点：半块热值占全块）；**自底向上局部分配**：逐指令、寄存器满时驱逐**下次使用最远**者（Belady 同型、Best 1950s 血统）、脏值驱逐先 store；**SSA 干涉图是弦图**（每个 ≥4 环有弦）：为什么——两名字干涉必有一方的 def 支配另一方 def（SSA 唯一定义点+活跃性），支配树先序的**逆序 = 完美消除序**；依 PEO 贪心着色 = **最优着色**（色数=团数，无回溯无 simplify 循环）；与 52 章 Chaitin-Briggs 对照（启发式 vs 最优、事后拆 SSA 会加 copy 与寄存器需求）；溢出仍在（选点启发式同 52 章）。示例：同一 SSA 程序上弦图最优着色 vs Briggs 着色对比 + PEO 合法性独立校验（每点的后邻居成团）。
断言：(1) PEO 校验全过；(2) 弦图色数 ≤ Briggs 色数；(3) 相邻异色校验过；(4) 局部分配两法对同一块所用寄存器次数/溢出数对比合理（farthest-use ≤ 频率计数）。

- [x] src + 断言 → expected → 正文 → Commit: `feat(compiler): 批次三十三——53 局部分配与 SSA 弦图着色`

### Task 7: 新 58 章 代码放置（鲸书 §8.6.2+§8.7.2）

**Files:**
- Create: `docs/58-placement.md`、`examples/58_placement/src/{place.hpp,place.cpp,main.cpp}`

内容：布局为什么影响取指（i-cache/顺直 fall-through）；**热路径链构造**：每块初始退化链优先级 E=|edges|、按边频**降序**扫描、x 链尾+y 链头才合并、新链优先级 = min(两链优先级, P++)；**链布局**：入口链起步、放完一条链把其出边未放目标的链按优先级入 WorkList；**过程放置**：调用图边权降序贪心、合并 x→y 时 ReSource (y,z)→(x,z)、ReTarget (z,y)→(z,x)、list(y) 接到 list(x)；与 16 章跟踪线性化（结构贪心）、56 章（分支预测顺直红利）互参；频率从哪来（静态估计：回边热、循环深度加权 vs profile 边计数）。示例：鲸书 Figure 8.15/8.22 同型 CFG+调用图（频度标注），跑链构造过程表 + 布局结果 + 指标。
断言：(1) 布局后热边顺直（链内）比例 > 初始任意序；(2) 执行频度加权的 taken 分支代价下降；(3) 过程放置后热调用对的布局距离总和下降；(4) 链构造过程表与鲸书手推一致。

- [x] src + 断言 → expected → 正文 → Commit: `feat(compiler): 批次三十四——58 代码放置（热路径链/过程聚簇）`

### Task 8: 四个补充章（鲸书宝石）

**Files:**
- Modify: `examples/05_regex_automata/src/*` + `docs/05-regex-automata.md`（补 **Brzozowski 最小化**：`reachable(subset(reverse(reachable(subset(reverse(n))))))`、双份 abc|bc|ad 例）
- Modify: `examples/14_tac_blocks/src/*` + `docs/14-tac-blocks.md`（补**内存模型**：ambiguous/unambiguous 值、`*p=0` 杀全名、哪些值可住寄存器——鲸书 §5.4.3）
- Modify: `examples/35_dominators/src/*` + `docs/35-dominators.md`（补 **CHK 快支配**：IDom 表示、RPO 编号上行求交、迭代到不动点；**稀疏集**：dense/sparse 双数组、clear O(1)、成员测试两条件——鲸书 §9.5.2+§B.2.3）
- Modify: `examples/55_ilp/src/*` + `docs/55-ilp.md`（补**树高平衡**：候选树=同交换结合算子链+内部名恰一次使用、rank 叶=1/常量=0、优先队列取两小合并（Huffman 同型）、8 加数 7 周期→3 深度重建——鲸书 §8.4.2）

每章：改 src → 重建 → 新 expected → `embed.py` 重生成该章内嵌 → check_docs 绿。
断言：05 Brzozowski 结果与现有 Hopcroft 状态数相等；14 内存模型改变某分析的解释口径（outputs 有对照行）；35 CHK 与现有迭代 Dom 集相等且迭代轮数更少；55 平衡后关键路径深度 < 左结合深度且 outputs 值相等。

- [x] 05 补 Brzozowski → Commit: `feat(compiler): 批次三十五——05 补 Brzozowski 逆转最小化`
- [x] 14 补内存模型 → Commit: `feat(compiler): 批次三十六——14 补内存模型（可寄存器判定）`
- [x] 35 补 CHK+稀疏集 → Commit: `feat(compiler): 批次三十七——35 补 CHK 快支配与稀疏集`
- [x] 55 补树高平衡 → Commit: `feat(compiler): 批次三十八——55 补树高平衡`

### Task 9: 收官（60/60）

**Files:**
- Modify: `examples/60_finale/src/survey.cpp` + expected（扩至 32 行：LR(1)/代码形状/SVN-DVNT/强度削减/弦图/放置 6 新家族）
- Modify: `docs/60-finale.md`（内嵌重生成、每章一句话扩 60 句、口径 54→60）
- Modify: `README.md`（四轮四书说明、十二篇导航、验证状态 60/60）
- Modify: 记忆 `compiler-tutorial-build.md` + `MEMORY.md`

- [x] survey 扩行 + expected 重生成 + 内嵌重生成
- [x] 每章一句话 60 句、README 定稿
- [x] 全量三层回归 60/60 exit 0
- [x] Commit: `feat(compiler): 批次三十九——60 章收官更新与 README 定稿（鲸书扩充完成）`

## Self-Review

- 覆盖：鲸书 13 章正文中未覆盖的王牌（LR1/代码形状/SVN/DVNT/OSR/局部+弦图/放置）全部有任务；四宝石有补充任务。已覆盖话题不重复建设。
- 占位符：无（每任务给出算法要点与断言设计）。
- 类型一致：槽位映射表与 Task 2-7 的章号一致（8/15/39/41/53/58）。
