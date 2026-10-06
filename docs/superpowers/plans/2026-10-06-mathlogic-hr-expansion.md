# mathlogic H&R 全谱扩充实施计划

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 把 mathlogic 教程（26 章/78 单元全绿）扩充为 Huth&Ryan 全谱教程：26 章全部教程化扩写 + 新增 27–34 章（LTL/模型检查算法/CTL*/完全正确性/模态三件套/符号 MC 与 μ 演算）。

**Architecture:** 英文 2e 文本层为内容主源（pdftotext 按节提取到 `.scratch/hr/`），中译本扫描件仅 RapidOCR 抽目录/章首页对齐术语。每章交付=教程文档（docs/NN-*.md，≥200 行、文字多于代码、代码摘录自真实 examples 文件）+ 裁剪通道机器单元（examples/NN_topic/exNN_topic.*，build.ps1 自动发现）。11 批次，每批一个 commit。

**Tech Stack:** Coq 通道改用 **Rocq Platform 9.1**（`G:\rocq\Rocq-Platform~9.1~2026.01\bin\coqc.exe`，原 scoop coqc 8.20.1 弃用——见 Task 0b 迁移）/ Lean 4.25（bare core）/ Agda 2.8.0(WSL)+stdlib 2.3 / Isabelle2025-2(Cygwin) / HOL4(WSL) / HoTT(Rocq 9.1 同二进制)；pdftotext；RapidOCR（cudnn G:\cudnn\9.24）。

**Spec:** `docs/superpowers/specs/2026-10-06-mathlogic-hr-expansion-design.md`

## Global Constraints

- **教程标准**（spec 原文，逐条可检验）：自包含（只读 docs 学会，不踢读者去原书）；每章 ≥200 行且文字行数多于代码行数；每段代码前后必有文字；正文代码摘录自 examples/ 真实文件并注明文件名；章首保留「> 对书：」行（溯源用）；章末保留坑位速记。
- **页码换算**：PDF 页 = 书页 + 16（已实测：PDF 17 = 书页 1）。提取命令模板：
  `pdftotext -f <起> -l <止> "G:/book/计算机/Logic in computer science modelling and reasoning about systems (Michael Huth, Mark Ryan) (Z-Library).pdf" .scratch/hr/<名>.txt`
- **OCR 纪律**：中译本只 OCR 目录页与各章首页，只取术语名词；公式一律以英文 2e 文本层为准。
- **命名**：章目录 `examples/NN_topic/`，文件 `exNN_topic.{v,agda,lean,thy,sml}`；Isabelle 需在 `examples/ROOT` 追加 `session MLNN in "NN_topic" = HOL + options [document = false] theories exNN_topic`。
- **验证**：单章 `pwsh -NoProfile -Command '& ./build.ps1 -Chapter NN'`；全量 `-All`；判定沿用六通道既有口径（exit 0/无 error/[OK] 标记）。既有 78 单元每批零回归。
  **coq 通道用 Rocq 9.1**（Task 0b 完成后 build.ps1 的 coqc 指向 `G:\rocq\Rocq-Platform~9.1~2026.01\bin\coqc.exe`）；`deprecated` 类 Warning 容忍，`(?m)^Error` 仍是失败线。
- **教程验收协议**（每章交付前跑，Git Bash）：
  ```bash
  cd /g/code/guide/mathlogic
  wc -l docs/NN-x.md                      # ≥200
  awk '/^```/{f=!f;next} !f{n++} END{print "prose:",n}' docs/NN-x.md   # prose 行数
  awk '/^```/{f=!f;next} f{n++} END{print "code:",n}' docs/NN-x.md     # 须 < prose
  grep -n '自行\|见原书\|参见原书\|读者自己看' docs/NN-x.md              # 须无输出
  ```
  另抽查 2 段正文代码：用 `grep -F "<片段首行>" examples/NN_topic/<对应文件>` 确认逐字存在。
- **通道坑先查**：动笔前读 `mathlogic/CHEATSheet.md` 与 docs/ 相邻章节坑位速记（Lean `lemma` 非关键字、HOL4 metis 静默爆炸、Agda with-under-with 等）。
- **诚实止步**：某通道卡住按惯例「止步+坑位速记」，不许假装全绿。
- **提交**：每批 `feat(mathlogic): 批次N——…`，结尾 `Co-Authored-By: Claude Code <noreply@anthropic.com>`；同步把 PLAN.md 蓝图表对应行标 ✅。
- 新章通道裁剪：27–29、31–34 只用 Coq+Lean；30 用 Coq+Lean+Isabelle。

---

## 批次零：取材准备（Task 0，无 commit 独立验收）

### Task 0: 源文本提取与术语对照

**Files:**
- Create: `.scratch/hr/` 下 20 个节段文本（不入库，.scratch 已在 gitignore 外但不提交）

- [ ] **Step 1: 提取英文 2e 全部相关节段**（PDF 页=书页+16）

```bash
cd /g/code/guide && mkdir -p .scratch/hr
B="G:/book/计算机/Logic in computer science modelling and reasoning about systems (Michael Huth, Mark Ryan) (Z-Library).pdf"
pdftotext -f 17 -l 46  "$B" .scratch/hr/s1_1-1_2.txt    # 宣言句+自然演绎全套(书1-30)
pdftotext -f 47 -l 68  "$B" .scratch/hr/s1_3-1_4.txt    # 形式语言+语义+归纳法+可靠完备(书31-52)
pdftotext -f 69 -l 87  "$B" .scratch/hr/s1_5-1_6.txt    # 范式+Horn+SAT求解器(书53-71)
pdftotext -f 114 -l 137 "$B" .scratch/hr/s2_2-2_3.txt   # FOL语法+ND+量词等价(书98-121)
pdftotext -f 138 -l 156 "$B" .scratch/hr/s2_4-2_6.txt   # FOL语义+等式+不可判定+表达力(书122-140)
pdftotext -f 191 -l 202 "$B" .scratch/hr/s3_2.txt       # LTL(书175-186)
pdftotext -f 203 -l 232 "$B" .scratch/hr/s3_3-3_4.txt   # 迁移系统+NuSMV+CTL(书187-216)
pdftotext -f 233 -l 236 "$B" .scratch/hr/s3_5.txt       # CTL*与表达力(书217-220)
pdftotext -f 237 -l 260 "$B" .scratch/hr/s3_6-3_7.txt   # MC算法+公平性+不动点(书221-244)
pdftotext -f 274 -l 314 "$B" .scratch/hr/s4_2-4_5.txt   # 程序验证全章(书258-298)
pdftotext -f 323 -l 346 "$B" .scratch/hr/s5_1-5_4.txt   # 模态K+逻辑工程+模态ND(书306-330)
pdftotext -f 347 -l 365 "$B" .scratch/hr/s5_5.txt       # KT45n知识逻辑(书331-349)
pdftotext -f 374 -l 397 "$B" .scratch/hr/s6_1-6_2.txt   # BDD与四算法(书358-381)
pdftotext -f 398 -l 413 "$B" .scratch/hr/s6_3-6_4.txt   # 符号MC+关系μ演算(书382-397)
ls -la .scratch/hr/   # 14 个文件，各非空
```

- [ ] **Step 2: 中译本术语抽样 OCR**

用 RapidOCR（cudnn 路径 `G:\cudnn\9.24`，复用 book-library-rename 项目的调用方式）对中译本
`G:\book\计算机\面向计算机科学的数理逻辑 ([德] 哈斯  [英] 瑞安) (Z-Library).pdf` 的**目录页与各章第一页**
（约 15 页）转 PNG 后识别，产出 `.scratch/hr/terms-zh.md`：三列对照表
（英文术语 / 中译本译名 / 教程现行译名）。只收名词（natural deduction→自然演绎、sequent calculus、
tableau、Kripke semantics→克里普克语义、model checking→模型检测、binary decision diagram→二叉判决图 等），
识别失败的行标注「(OCR 存疑）」但不阻塞——教程现行术语不变，对照表最终进 CHEATSheet。

- [ ] **Step 3: 抽查文本层质量**

`head -50 .scratch/hr/s3_5.txt` 确认 CTL* 节文字可读（2e 文本层偶见连字/缺空格，
公式以正文版面为准时对照 PDF 页图）。若某节文本层损坏，记录到 `.scratch/hr/terms-zh.md` 尾部，
该节改读英文 PDF 页面截图人工转录（不向 OCR 要公式）。

**验收**：14 个节段文件非空 + terms-zh.md 有 ≥20 行对照。无 commit（.scratch 不入库）。

### Task 0b: coq 通道迁移到 Rocq 9.1（先行硬门槛）

Coq 通道从 scoop coqc 8.20.1 迁到 `G:\rocq\Rocq-Platform~9.1~2026.01\bin\coqc.exe`
（与 HoTT 通道同一二进制）。已冒烟实测：ex02 原样编译 exit 0，仅有
`Loading Stdlib without prefix is deprecated` 警告——迁移风险低，但须全量跑一遍确认。

**Files:**
- Modify: `mathlogic/build.ps1`（coq 分支：coqc 调用换 Rocq 路径）
- Modify: `mathlogic/examples/*/ex*.v`（仅当有真 Error 时逐个修；顺手把裸
  `Require Import` 现代化为 `From Stdlib Require Import` 消警告）
- Modify: `mathlogic/CHEATSheet.md`、`mathlogic/PLAN.md`（coq 通道行更新为 Rocq 9.1）

- [ ] **Step 1:** 改 build.ps1 coq 分支：`& coqc -q $target` →
  `& 'G:\rocq\Rocq-Platform~9.1~2026.01\bin\coqc.exe' -q $target`（判定逻辑不变）。
  头部注释的通道判定表同步改「Rocq 9.1（G:\rocq，原 8.20 弃用）」。
- [ ] **Step 2:** `pwsh -NoProfile -Command '& ./build.ps1 -Lang coq'` 全量跑 coq 通道。
  对任何 `Error` 逐个修（已知雷区：stdlib 改名件——le_gt_dec、ring 系引理，
  见 coq-tutorial-build 记忆的 Rocq 9.1 迁移清单）；只有 deprecated 警告的文件
  机械改写 `Require Import X` → `From Stdlib Require Import X` 消警告后复跑。
- [ ] **Step 3:** `pwsh -NoProfile -Command '& ./build.ps1 -All'` 78/78 全绿（六通道全口径）。
- [ ] **Step 4:** CHEATSheet 通道表与 PLAN.md 六通道表的 coq 行改为 Rocq 9.1 入口；
  commit：

```bash
cd /g/code/guide && git add mathlogic && git commit -m "chore(mathlogic): coq 通道迁移 Rocq 9.1（8.20 弃用，78 单元复跑全绿）

Co-Authored-By: Claude Code <noreply@anthropic.com>"
```

---

## 批次一：01–04 命题篇上

### Task 1: 01 章扩写（全景与可满足关系暗线）

**Files:**
- Modify: `mathlogic/docs/01-intro.md`（77 行 → ≥200 行）
- 代码：无改动（引用 `examples/01_intro/` 现有文件）

**Interfaces:**
- Produces: 全书暗线之首「逻辑 = 可满足关系 M ⊨ φ」的表述，26/29/34 章收官时引用。

- [ ] **Step 1:** 读 `.scratch/hr/s1_1-1_2.txt` 前段（§1.1）与 2e 前言（PDF 12–16 页，
  `pdftotext -f 12 -l 16` 另提）。读现有 `docs/01-intro.md` 与 `examples/01_intro/` 各文件。
- [ ] **Step 2:** 按此大纲重写：
  1. 为什么 CS 需要逻辑——§1.1 火车/出租车例全程讲解（论点有效性直觉→形式化需求）；
  2. 全书暗线：M ⊨ φ 可满足关系（2e 前言 leitmotif），逐家兑现方式预告；
  3. 逻辑三件套：语法/证明演算/语义（保留现有骨架，每件套配例子）；
  4. 六家谱系与账本（保留现有表格与 hello-logic，摘录真实代码段+逐段讲解）；
  5. 构造 vs 经典的账本对照预告（为 04/11 章埋钩）；
  6. 坑位速记（保留原有）。
- [ ] **Step 3:** 跑教程验收协议；`grep -F` 抽查 2 段摘录。
- [ ] **Step 4:** `pwsh -NoProfile -Command '& ./build.ps1 -Chapter 01'` 全绿。

### Task 2: 02 章扩写（命题语义，103 行 → ≥200 行）

**Files:**
- Modify: `mathlogic/docs/02-propsem.md`

- [ ] **Step 1:** 读 `.scratch/hr/s1_3-1_4.txt`（§1.3 形式语言、§1.4 语义、§1.4.2 数学归纳法、
  §1.4.3/1.4.4 可靠与完备）。
- [ ] **Step 2:** 在现有骨架上扩写：
  1. 语法作为归纳类型——§1.3 的 BNF 与良构公式唯一可读性直觉；
  2. ★新增小节「数学归纳法的三种形态」（§1.4.2：自然数归纳/结构归纳/课程归纳对照，
     各自在本教程哪章用到——02 结构归纳、22 课程归纳）；
  3. 真值表语义逐个连接词讲（§1.4.1），eval 摘录讲解保留；
  4. 一致性引理与蛮力判定器（保留现有，补「为什么这是可靠性的最小完整现场」）；
  5. §1.4.3/1.4.4 的 ND 可靠/完备与本章语义版判定的分工（指向 23 章）；
  6. 四家对照表与坑位速记（保留）。
- [ ] **Step 3:** 教程验收协议 + 摘录抽查。
- [ ] **Step 4:** `build.ps1 -Chapter 02` 全绿。

### Task 3: 03 章扩写加深（NJp 全套规则 + 派生规则）

**Files:**
- Modify: `mathlogic/docs/03-njp.md`（67 行 → ≥240 行）
- 代码：视缺口在 `examples/03_njp/ex03_njp.v` 与 `ex03_njp.lean` **追加**派生规则示例
  （不改现有定义）：`mt : (p → q) → ¬q → ¬p`、`pbc 对照`（经典通道已有则只写文档）、
  `nn_i : p → ¬¬p`、`lem 派生演示`（均 Coq+Lean；Agda/Isabelle/HOL4 通道只文档对照）

**Interfaces:**
- Consumes: §1.2 全套规则文本（.scratch/hr/s1_1-1_2.txt）
- Produces: 派生规则 mt/nn_i 的机器件名（04 章矩阵引用时可指向本章例）

- [ ] **Step 1:** 读 `.scratch/hr/s1_1-1_2.txt` §1.2 全部；读现有 `ex03_njp.v/.lean` 确认
  现有构造子名（先读代码再写追加件，避免撞名）。
- [ ] **Step 2:** 写追加代码单元（Coq+Lean 各一份），含 Example 级定理：
  `example_mt`、`example_nn_intro`、`example_derived_lem_use`（用 LEM 派生规则证
  `p ∨ ¬p` 参与的小论证）。`build.ps1 -Chapter 03` 通过。
- [ ] **Step 3:** 按大纲重写文档：
  1. ND 的哲学：证明是构造活动（§1.2 开头）；
  2. ★九条基础规则逐个讲（∧i/∧e₁/∧e₂/∨i₁/∨i₂/∨e/→i/→e/¬i/¬e/⊥e），每条：
     规则图（文本绘制）、直觉解读、机器构造子摘录、最小示例；
  3. 证明框（proof box）记法讲解（§1.2.1 的竖式）与演算数据化的对应；
  4. ★派生规则一节（§1.2.2）：MT/LEM/¬¬i/PBC 的**推导**（从基础规则造出）+ 机器件摘录；
  5. ★可证等价（§1.2.4）与「证明中替换」直觉；★反证法旁白（§1.2.5：PBC 的地位，
     指向 04/11 章构造性账本）；
  6. HOL4 首秀五连坑保留；坑位速记扩充。
- [ ] **Step 4:** 教程验收协议 + 摘录抽查（grep -F 对 ex03_njp.v）。

### Task 4: 04 章扩写（经典加成矩阵教学线）

**Files:**
- Modify: `mathlogic/docs/04-classical.md`（63 行 → ≥200 行）

- [ ] **Step 1:** 读现有文档与 `examples/04_classical/` 各通道文件（五原理：LEM/DNE/PBC/MT?/Peirce——
  以实际代码为准列清单）。
- [ ] **Step 2:** 重写：每个原理一节——自然语言动机（什么时候人类论证偷偷用了它）→
  规则/公理形态 → 机器证明摘录讲解 → 在等价矩阵中的位置；矩阵一节讲「五原理互相可推」
  的证明环是怎么搭的（哪条链最意外）；HoTT 首秀与 h-level 注记保留扩充；坑位速记保留。
- [ ] **Step 3:** 教程验收协议；`build.ps1 -Chapter 04` 全绿。

- [ ] **Step 5（批次一收口）:** `pwsh -NoProfile -Command '& ./build.ps1 -All'` 78+ 单元零回归；
  PLAN.md 把 01–04 标「扩写✅」；

```bash
cd /g/code/guide && git add mathlogic && git commit -m "feat(mathlogic): 批次一——01-04 教程化扩写，03 织入 H&R ND 全套与派生规则

Co-Authored-By: Claude Code <noreply@anthropic.com>"
```

---

## 批次二：05–08 命题篇下

### Task 5: 05 章扩写（Hilbert 系统）

- Modify: `docs/05-hilbert.md`（64→≥200）。大纲：公理模式 vs 规则的哲学（为什么 Hilbert
  「难用但好证元定理」）；三个公理模式逐个讲（K/S/否定系）；MP 的唯一规则地位；
  演绎定理——证法全貌（对推导归纳的三种情形）逐步展开，机器件摘录；深浅嵌入对照点保留；
  HOL4 浅嵌入坑位保留。验收协议 + `build.ps1 -Chapter 05`。

### Task 6: 06 章扩写（矢列演算 G）

- Modify: `docs/06-sequent.md`（56→≥200）。大纲：从 ND 到矢列的动机（前提集合化、
  可判定搜索）；矢列 Γ ⊢ Δ 的读法（合取推出析取）；九规则逐个讲（左右规则成对直觉）；
  可靠性旗舰的证明骨架（对推导归纳）讲解；「G 天生经典」与直觉主义矢列（右部单公式）
  的分叉点。验收协议 + `-Chapter 06`。

### Task 7: 07 章扩写（语义表列）

- Modify: `docs/07-tableau.md`（59→≥200）。大纲：表列=反向矢列搜索的直觉（从「找反模型」
  出发）；展开规则族（α/β 分类讲）；闭枝与完成枝；fuel 化搜索的机器实现摘录讲解；
  三定理链（sound/complete/decides）各用一节讲透依赖关系。验收协议 + `-Chapter 07`。

### Task 8: 08 章扩写加深（范式 + H&R §1.5）

- Modify: `docs/08-cnf.md`（51→≥220）。源：`.scratch/hr/s1_5-1_6.txt` 前半（§1.5）。
- 大纲：★语义等价/可满足/有效三概念精确化（§1.5.1，三者两两关系表）；★文字/子句/
  CNF 定义链；NNF 变换四条规则；★CNF 化与**有效性检查**的对偶（§1.5.2：CNF 有效
  ⟺ 每个子句含互补文字——机器判定器摘录讲解）；分配律膨胀警告（指数爆炸例子）；
  Tseitin 预告（指向 09 章 SAT 工程）；Agda case-tree 互卡实录保留。
- 验收协议 + `-Chapter 08`。

- 批次二收口：`-All` 零回归 + PLAN.md 标 05–08 + commit「批次二——05-08 教程化扩写，08 织入 H&R 范式三概念」。

---

## 批次三：09–10 SAT/BDD 加深

### Task 9: 09 章扩写加深（Horn 线性求解器新单元）

**Files:**
- Modify: `docs/09-dpll.md`（64→≥260）
- Modify: `examples/09_dpll/ex09_dpll.v`、`ex09_dpll.lean`（追加 Horn 单元）

**Interfaces:**
- Produces: `horn : Type := list nat * option nat`（前提表+结论，None=⊥）、
  `hsat : list nat -> list horn -> bool`、`hsat_sound`、`hsat_complete`
  （Coq/Lean 同名，26 章图景引用）。

- [ ] **Step 1:** 读 `.scratch/hr/s1_5-1_6.txt` §1.5.3/1.6.1/1.6.2；读现有 ex09 两文件。
- [ ] **Step 2:** 实现 Horn 标记算法（Coq+Lean）：

```coq
(* Horn 子句 = 前提原子表 × 结论（None 表示 ⊥ 目标子句） *)
Definition horn : Type := (list nat * option nat)%type.
(* sweep：扫一遍子句表，凡前提全已标记且结论未标的，标记结论 *)
Definition sweep (cs : list horn) (m : list nat) : list nat := (* fold 追加 *)
(* close：fuel = 原子数+1 遍不动点迭代（每遍至少多标一个，否则收敛） *)
Fixpoint close (fuel : nat) (cs : list horn) (m : list nat) : list nat
(* hsat：从全体「事实子句」（空前提）出发 close，⊥(None 结论) 未被触发则可满足 *)
Definition hsat (atoms : list nat) (cs : list horn) : bool
Theorem hsat_sound : hsat atoms cs = true -> exists v, 全部子句在 v 下成立
Theorem hsat_complete : hsat atoms cs = false -> 不可满足
```

  证明路线：marked 集单调递增（引理 `close_mono`），故 fuel=|atoms|+1 足够；
  完备性=「标记集恰是最小模型」（对 close 步数归纳 + 反模型构造）。
  Lean 版注意 `lemma` 非关键字、构造子头索引泛化（CHEATSheet 先查）。
- [ ] **Step 3:** `build.ps1 -Chapter 09` 通过（既有单元+h新增 horn 单元）。
- [ ] **Step 4:** 文档扩写：DPLL 回顾（保留现有 upd 装配讲解）→ ★Horn 子句与线性时间
  可满足性（§1.5.3：Horn 形态定义、为什么 Horn 可以线性）→ 标记算法逐步 trace
  （一个 5 子句例子逐遍标记表）→ ★sound/complete 证明讲解（最小模型直觉）→
  ★§1.6.2 三次标记求解器概念（文档级：全命题逻辑的 marking/Stålmarck 风格，
  与 Horn 的分工）→ 坑位速记扩充。
- [ ] **Step 5:** 教程验收协议 + 摘录抽查。

### Task 10: 10 章扩写加深（reduce/restrict/exists 三算法）

**Files:**
- Modify: `docs/10-bdd.md`（53→≥240）
- Modify: `examples/10_bdd/ex10_bdd.v`、`ex10_bdd.lean`（追加三算法单元）

**Interfaces:**
- Produces: `restrict : bdd -> nat -> bool -> bdd` + `restrict_correct`、
  `exb : bdd -> nat -> bdd` + `exb_correct`（34 章符号 MC 的 pre_∃ 直接消费 exb/apply/restrict）。

- [ ] **Step 1:** 读 `.scratch/hr/s6_1-6_2.txt`（§6.1 OBDD、§6.2 reduce/apply/restrict/exists/评估）；
  读现有 ex10 两文件（apply/mk 深度编码现场）。
- [ ] **Step 2:** 追加实现（Coq+Lean）：

```coq
(* restrict：把变元 x 钉为常量 b——x 层节点直接选分支 *)
Fixpoint restrict (f : bdd) (x : nat) (b : bool) : bdd
Theorem restrict_correct : forall f x b env,
  beval env (restrict f x b) = beval (update env x b) f
(* exb：存在量词消元 = 两个 restrict 的析取（语义：f[0/x] ∨ f[1/x]） *)
Definition exb (f : bdd) (x : nat) : bdd := bor (restrict f x false) (restrict f x true)
Theorem exb_correct : forall f x env,
  beval env (exb f x) = beval (update env x false) f || beval (update env x true) f
```

  （bor=现有 apply 的或实例；reduce 在树形深编码下是「无共享坍缩」——沿用本章既有
  坍缩现场讲解，不强行机器化 DAG。）
- [ ] **Step 3:** `build.ps1 -Chapter 10` 通过。
- [ ] **Step 4:** 文档扩写：BDD 定义与序约束（§6.1，OBDD 三约简规则：去重/去冗余测试/共享）→
  apply/mk 回顾（保留）→ ★restrict/exists 算法与正确性讲解（代入语义视角：restrict 就是
  语义代入的语法化，与 14 章代入引理呼应）→ ★§6.2.5 OBDD 评估（变量序敏感性爆炸例：
  加法器 vs 乘法器）→ 坑位速记扩充。
- [ ] **Step 5:** 教程验收协议。

- 批次三收口：`-All` 零回归 + PLAN.md 标 09/10 + commit「批次三——09-10 加深：Horn 线性求解器与 BDD 三算法」。

---

## 批次四：11–13 直觉主义篇

### Task 11: 11 章扩写（Glivenko）

- Modify: `docs/11-glivenko.md`（46→≥200）。大纲：经典 vs 直觉的可证性鸿沟（从 04 章矩阵
  接棒）；¬¬ 翻译的思想（把经典真「藏进」双重否定）；三板斧（保留现有，每斧扩成完整小节：
  规则推导图+机器件摘录+为什么这是 Glivenko 的引擎）；Glivenko 定理陈述与**命题层 vs FOL 层**
  的分工（FOL 层要加量词条款——为 16 章埋钩，Mints 教学线）；HoTT 侧注记保留扩充；
  坑位速记保留。验收协议 + `-Chapter 11`。

### Task 12: 12 章扩写（Curry–Howard）

- Modify: `docs/12-ch.md`（47→≥200）。大纲：命题即类型对照表从零讲（连接词↔类型构造子
  全表）；证明即程序：每个 ND 规则的 λ 项形态；闭值 canonical forms（为什么「正规证明的
  主连接词就是引入规则」是 CH 的皇冠）；析取性质（∨ 的证明必带标签——与经典真值表的
  对立）；HoTT 截断丢标签注记保留。验收协议 + `-Chapter 12`。

### Task 13: 13 章扩写（Kripke 语义，与 31 章分工）

- Modify: `docs/13-kripke.md`（62→≥220）。大纲：可能世界直觉（信息状态 vs 真值）；
  直觉主义 Kripke 模型三件套（W/≤/单调赋值）+ 单调性引理机器件讲解；两世界 LEM 反例
  全程；**新增小节「本章 vs 31 章的分工」**：直觉主义 Kripke（≤ 预序+单调性+→ 的语义）
  vs 古典模态 Kripke（任意 R+□◇）——一张对照表锁死边界，31 章直接引用；
  DNE 空真认知修正实录保留。验收协议 + `-Chapter 13`。

- 批次四收口：`-All` 零回归 + PLAN.md + commit「批次四——11-13 直觉主义篇教程化扩写」。

---

## 批次五：14–16 FOL 语法/语义/ND

### Task 14: 14 章扩写加深（代入与捕获）

- Modify: `docs/14-folsyntax.md`（63→≥220）。源：`.scratch/hr/s2_2-2_3.txt` §2.2。
- 大纲：★项/公式的两层的 BNF（§2.2.1/2.2.2）；★自由/约束变元与作用域（§2.2.3，
  嵌套量词遮蔽例）；★代入的定义逐条款讲（§2.2.4），**捕获问题完整反例**先行
  （`∃y. x<y` 代入 `x:=y` 事故）→ 防捕获的条件（「t 对 x 自由」）→ 机器实现
  （fv 条款含 In x 条件教训保留扩充）；代入交换引理讲解。验收协议 + `-Chapter 14`。

### Task 15: 15 章扩写加深（模型与等式语义）

- Modify: `docs/15-folsem.md`（65→≥220）。源：`.scratch/hr/s2_4-2_6.txt` §2.4。
- 大纲：★模型=论域+解释（§2.4.1，两项谓词符号的解释例）；★环境/查找与满足关系
  逐条款（§2.4.2）；★等式语义（§2.4.3：= 解释真实相等，= 的 ND 规则在 16 章，
  本章先立语义锚点）；一致性引理+代入交换（保留现有旗舰讲解扩充）；locale 理论
  对照保留。验收协议 + `-Chapter 15`。

### Task 16: 16 章扩写加深（量词规则 + 等式 =i/=e 新单元）

**Files:**
- Modify: `docs/16-folnd.md`（67→≥260）
- Modify: `examples/16_folnd/ex16_folnd.v`、`ex16_folnd.lean`（追加等式单元）

**Interfaces:**
- Produces: ND 演算新增构造子 `EqI : nd Γ (FEq t t)`、`EqE : nd Γ (FEq t1 t2) -> nd Γ φ[t1/x] -> nd Γ φ[t2/x]`
  （若 form 无 FEq 原子需先加原子并扩 eval：解释为论域相等）；派生件 `eq_sym`、`eq_trans`。

- [ ] **Step 1:** 读 `.scratch/hr/s2_2-2_3.txt` §2.3 全部；读现有 ex16 两文件确认
  form/nd 现状（有无等式原子）。
- [ ] **Step 2:** 追加等式单元（Coq+Lean）：FEq 原子（若缺）+ eval 条款 +
  `EqI`/`EqE` 构造子 + 派生定理 `eq_sym : nd [] (FEq a b) -> nd [] (FEq b a)` 形态示例、
  `eq_trans`、一个「等式替换进谓词」的完整 Example。语义侧补一句 eval 等式条款即可
  （不做等式规则可靠性大定理——文档注明边界）。
- [ ] **Step 3:** `build.ps1 -Chapter 16` 通过。
- [ ] **Step 4:** 文档扩写：★量词四规则逐个讲（∀i/∀e/∃i/∃e，每条侧条件的**反例**
  先行：∀i 的本征变量污染事故、∃e 的逃逸事故）→ ★等式规则 =i/=e（§2.3.1 尾部：
  =i 自反公理、=e 替换规则的几何直觉「相等者可互换」）→ 机器件摘录讲解 →
  ★量词等价族（§2.3.2：¬∀↔∃¬ 等四条，证明框讲解）→ Drinker 三旗舰保留扩充 →
  坑位速记扩充。
- [ ] **Step 5:** 教程验收协议。

- 批次五收口：`-All` 零回归 + PLAN.md + commit「批次五——14-16 教程化扩写，16 织入等式规则 =i/=e」。

---

## 批次六：17–21 FOL 演算与可判定性

### Task 17: 17 章扩写（FOL Hilbert 与 Gen 侧条件）

- Modify: `docs/17-folhilbert.md`（66→≥200）。大纲：FOL 化 Hilbert 的三件新行李
  （量词公理模式/Gen 规则/代入侧条件）；**裸演绎定理在 FOL 失败的反例先行**
  （`x=0 ⊢ ∀x.x=0` 事故）→ Gen 侧条件的精确表述 → 演绎定理修复版证明逐步讲；
  GenMove 公理记账的诚实性讨论；Lean 三连坑实录保留。验收 + `-Chapter 17`。

### Task 18: 18 章扩写（前束范式）

- Modify: `docs/18-prenex.md`（58→≥200）。大纲：前束形的定义与「量词全部出门」直觉；
  四条量词穿越定理逐个讲（每条：等价式、侧条件、为什么侧条件不对称是**本质的**
  ——变量捕获反例）；机器证明摘录；穿越算法与终止性。验收 + `-Chapter 18`。

### Task 19: 19 章扩写（合一与归结）

- Modify: `docs/19-resolution.md`（71→≥220）。大纲：归结推理的全貌（从 CNF 到反驳：
  「证 ¬φ 不可满足」的反证式工作方式）；合一算法逐步 trace（两个项的分歧集消解表）；
  ★occurs check 反例先行（`x = f(x)` 的无穷项事故）→ 结构锚机器件讲解；
  归结可靠性的侧条件版证明骨架。验收 + `-Chapter 19`。

### Task 20: 20 章扩写（Herbrand 与 SLD）

- Modify: `docs/20-herbrand.md`（61→≥220）。大纲：Herbrand 宇宙/基的构造（为什么
  「只需考虑项做成的模型」）；Horn 程序的 T_P 算子（一步推导直觉）+ 单调性机器件；
  最小不动点=最小模型（Knaster–Tarski 边界实录保留）；SLD 归结与 Prolog 桥
  （计算规则/搜索策略的选择点）；头原子引理讲解。验收 + `-Chapter 20`。

### Task 21: 21 章扩写加深（PCP 归约 + 表达能力）

- Modify: `docs/21-decidability.md`（64→≥240）。源：`.scratch/hr/s2_4-2_6.txt` §2.5/2.6。
- 大纲：可判定性图景回顾（presburger 现场保留）→ ★**Post 对应问题**（PCP：
  定义+一个可解/一个不可解实例的手工 trace）→ ★PCP 归约证 FOL 不可判定
  （§2.5：归约构造的思想——把 PCP 实例编码为 FOL 有效式，逐块讲解，
  文档级；机器面只做 PCP 小实例的求解器演示）→ ★表达能力（§2.6：
  传递闭包一阶不可表达——紧致性论证直觉；存在二阶 ESO 恰好抓住它；
  USO 对照；这张图与 29 章 CTL* 表达线的呼应）。
- 验收 + `-Chapter 21`。

- 批次六收口：`-All` 零回归 + PLAN.md + commit「批次六——17-21 教程化扩写，21 织入 PCP 归约与表达力」。

---

## 批次七：22–24 元理论与 CTL 加深

### Task 22: 22 章扩写（不完备性教学展开）

- Modify: `docs/22-incompleteness.md`（73→≥220）。大纲：三步行军图（可表示性→对角化→
  不可证句）每步一节：可表示性（「证明是有限对象，可被算术谈论」+ 20 章 TP_mono
  的机器面呼应）；对角化（自指的构造——不动点引理直觉，「本句不可证」怎么合法说出）；
  第一定理收束 + 第二定理（一致性不可内证）+ 机器化先例索引扩充（各助手社区的
  完备形式化清单）。文档章，无代码单元；验收协议 + `-Chapter 22`（无单元则跳过构建步）。

### Task 23: 23 章扩写（Henkin 完备性教学展开）

- Modify: `docs/23-completeness.md`（65→≥220）。大纲：完备性=「语义与证毕之缝的缝合」
  （接 02 章的缝）；Henkin 构造七步每步一节（极大一致化/Lindenbaum/见证扩张/项模型/
  真值引理/收束），每步给「这步在防什么」的反向动机；紧致性与 L-S 推论（从构造白拿
  的两枚果实）；先例索引扩充。验收 + `-Chapter 23`。

### Task 24: 24 章扩写加深（CTL 标记算法 + 不动点正确性新单元）

**Files:**
- Modify: `docs/24-temporal.md`（59→≥280）
- Modify: `examples/24_temporal/ex24_temporal.v`、`ex24_temporal.lean`（追加标记算法单元）

**Interfaces:**
- Produces: `satctl : model -> ctl -> list st`（有限模型标记算法）+
  `satctl_correct : forall m f s, In s (satctl m f) <-> ctlsat m s f`
  （28 章公平性变体与 34 章 μ 演算编码引用）。

- [ ] **Step 1:** 读 `.scratch/hr/s3_3-3_4.txt`（§3.3 迁移系统/互斥例、§3.4 CTL 全套）与
  `.scratch/hr/s3_6-3_7.txt`（§3.6.1 标记算法、§3.7 不动点刻画）；读现有 ex24 两文件。
- [ ] **Step 2:** 追加标记算法单元（Coq+Lean）：

```coq
(* 有限模型：状态表 + 迁移关系表 + 标记函数（沿用现有 model 定义） *)
(* satctl：按公式结构递归——EU 用最小不动点迭代（n 次，n=状态数），EG 用最大不动点 *)
Fixpoint sat_eu (m : model) (s1 s2 : list st) (fuel : nat) : list st
Definition satctl (m : model) (f : ctl) : list st
Theorem satctl_correct : forall m f s, In s (satctl m f) <-> ctlsat m s f
```

  证明路线：迭代链单调+有限载体→fuel=|S|+1 收敛（引理 `iter_mono`/`iter_stable`）；
  不动点=语义展开等价（接现有 AG/EG 展开构件）。
- [ ] **Step 3:** `build.ps1 -Chapter 24` 通过。
- [ ] **Step 4:** 文档扩写：时态逻辑动机（§3.1 一句话+24 章现有引子）→ ★CTL 语法
  （路径量词×时态算子成对，八组合）→ 语义（计算树展开图讲解）→ ★规范实践模式表
  （§3.4.3：安全性/活性/公平性诉求各配 CTL 式子与反例）→ ★重要等价与 adequate sets
  （§3.4.4/3.4.5）→ ★标记算法（§3.6.1：SAT_φ 自底向上标记伪码逐行讲+机器件摘录）→
  ★不动点刻画与 SATEG/SATEU 正确性（§3.7：为什么 EU 是最小、EG 是最大不动点——
  单向包含各给直觉）→ 坑位速记扩充。
- [ ] **Step 5:** 教程验收协议。

- 批次七收口：`-All` 零回归 + PLAN.md + commit「批次七——22-24 扩写，24 织入 CTL 标记算法与不动点正确性」。

---

## 批次八：25 加深 + 30 新章（完全正确性）

### Task 25: 25 章扩写加深（部分 vs 完全 + proof tableaux）

- Modify: `docs/25-hoare.md`（94→≥260）。源：`.scratch/hr/s4_2-4_5.txt` §4.2/4.3。
- 大纲：验证框架（§4.2.1 core 语言对照本章 IMP）→ 霍尔三元组语义
  （§4.2.2）→ ★**部分 vs 完全正确性**（§4.2.3：{P}c{Q} 两种读法、
  while 发散时部分正确性「免费成立」的猫腻——为 30 章埋钩）→ ★程序变量 vs 逻辑变量
  （§4.2.4：逻辑变量不出现在程序里，用来冻结初值——mid 例）→ 演算规则逐个讲
  （赋值公理的**反向代入**为什么对，前件加强/后件减弱）→ ★proof tableaux 竖式记法
  （§4.3.2：中途断言的行文纪律，与机器推导树对照）→ while 五通道对照保留扩充 →
  坑位速记保留。验收 + `-Chapter 25`。

### Task 26: 30 章新建（完全正确性、minimal-sum 案例、契约）

**Files:**
- Create: `docs/30-totalcorrect.md`（≥260 行）
- Create: `examples/30_totalcorrect/ex30_totalcorrect.v`、`ex30_totalcorrect.lean`、`ex30_totalcorrect.thy`
- Modify: `examples/ROOT`（追加 `session ML30 in "30_totalcorrect" = HOL + options [document = false] theories ex30_totalcorrect`）

**Interfaces:**
- Consumes: 25 章 IMP 语义/hoare 定义（各通道按现有文件自包含复制骨架——章间不跨文件 import）
- Produces: `hoareT P c Q`（完全正确性定义）+ 全正确 while 规则 `hoareT_while` 可靠性 +
  `minsum_partial`/`minsum_total` 案例定理（26 章图景引用）。

- [ ] **Step 1:** 读 `.scratch/hr/s4_2-4_5.txt` §4.3.3（minimal-sum 案例）/§4.4（完全正确
  演算）/§4.5（契约）；读 `examples/25_hoare/` 对应通道文件复制 IMP 骨架。
- [ ] **Step 2:** Coq+Lean+Isabelle 三通道实现：

```coq
(* 完全正确性：前件成立则存在终止态且满足后件 *)
Definition hoareT (P Q : state -> Prop) (c : cmd) : Prop :=
  forall s, P s -> exists s', exec c s s' /\ Q s'.
(* 全正确 while：变体 V（自然数表达式）每轮严格递减 *)
Theorem hoareT_while : forall P b c V,
  (forall n, hoareT (fun s => P s /\ beval s b = true /\ V s = n)
                 c (fun s => P s /\ V s < n)) ->
  hoareT P (While b c) (fun s => P s /\ beval s b = false).
```

  证明路线：对循环执行步数（或 V 初值）做强归纳；变体自然数良基性挡无穷下降。
  Isabelle 版用既有 IMP 语义照搬规则归纳（裸 `induct rule:` 对构造子头索引的坑先查
  CHEATSheet——显式实例化 arbitrary: 模式）。
- [ ] **Step 3:** minimal-sum 案例：§4.3.3 的程序（求数组最小和段的和）按书逐行配断言，
  三通道各证 `minsum_partial` 与 `minsum_total`（变体=剩余扫描长度）。
  `build.ps1 -Chapter 30` 全绿。
- [ ] **Step 4:** 写 `docs/30-totalcorrect.md`：完全正确性语义 → ★变体方法
  （§4.4：为什么自然数变体足够/良基推广一句带过）→ 全正确演算规则表（与 25 章
  部分版逐条对照，唯一动的是 while）→ ★minimal-sum 案例全程（书的招牌案例：
  非平凡循环不变式怎么「想」出来——先写后置条件再倒推的教学线；机器证明摘录讲解）→
  ★契约式设计（§4.5：前置/后置/不变式作为接口规约，与霍尔三元组的对应）→
  坑位速记。
- [ ] **Step 5:** 教程验收协议 + ROOT 追加后 `build.ps1 -Chapter 30` 复跑。

- 批次八收口：`-All` 零回归 + PLAN.md + commit「批次八——25 加深 + 30 完全正确性新章（minimal-sum 三通道）」。

---

## 批次九：27–29 时态逻辑三新章

### Task 27: 27 章新建（LTL）

**Files:**
- Create: `docs/27-ltl.md`（≥260 行）
- Create: `examples/27_ltl/ex27_ltl.v`、`ex27_ltl.lean`

**Interfaces:**
- Produces: `ltl` 语法、`ltlsat : (nat -> st -> bool) -> nat -> ltl -> Prop`（路径=赋值流，
  位置参数 i 表示后缀 π^i）、等价件 `ltl_F_unfold : ltlsat π i (LF φ) <-> ltlsat π i (LU LTrue φ)`、
  `ltl_G_dual`、`ltl_F_or`、`ltl_G_and`、`ltl_FF`（28/29 章引用语义定义形态）。

- [ ] **Step 1:** 读 `.scratch/hr/s3_2.txt` 全部（§3.2.1–3.2.5）。
- [ ] **Step 2:** Coq+Lean 实现：

```coq
Inductive ltl := LAtom (p:nat) | LTrue | LNeg φ | LAnd φ ψ | LX φ | LF φ | LG φ | LU φ ψ.
(* 路径 = nat -> (nat -> bool)：第 i 个状态的原子赋值；满足关系对位置归纳 *)
Definition path := nat -> nat -> bool.
Fixpoint/Inductive ltlsat (π : path) (i : nat) (φ : ltl) : Prop
  (* LU：∃j≥i. π^j ⊨ ψ ∧ ∀k. i≤k<j → π^k ⊨ φ —— 归纳谓词（非 Fixpoint，U 无界） *)
```

  等价定理五个（F=tru U、G=¬F¬、F∨分配、G∧分配、FF=F 幂等），全部对 ltlsat 归纳/
  存在见证组装；LX 的语义（π^(i+1)）顺带证 `ltl_X_neg : ¬X φ ↔ X ¬φ`。
- [ ] **Step 3:** `build.ps1 -Chapter 27` 全绿。
- [ ] **Step 4:** 写文档：时间作为路径（§3.2.1 引子：LTL 沿单路径量化，与 CTL 分叉）→
  语法（X/F/G/U/R/W 族，后两者导出版）→ 语义逐条款（后缀 π^i 的记法先行）→
  ★规范实践模式表（§3.2.3：响应 G(req→F ack)、持续 FG、无限经常 GF、嵌套组合，
  每个模式配「说人话」与机器语义例）→ ★重要等价（§3.2.4 全表：对偶/分配/幂等，
  机器证明摘录五件讲解）→ ★adequate sets（§3.2.5：{¬,∧,X,U} 足够——导出算子定义法）→
  坑位速记。
- [ ] **Step 5:** 教程验收协议。

### Task 28: 28 章新建（模型检查算法与公平性）

**Files:**
- Create: `docs/28-mcalgo.md`（≥260 行）
- Create: `examples/28_mcalgo/ex28_mcalgo.v`、`ex28_mcalgo.lean`

**Interfaces:**
- Consumes: 24 章 `satctl`（文档引用；代码按惯例自包含复制骨架）
- Produces: 互斥双进程有限模型 `mutex : model` + 活性/安全性验证例 `check_mutex_safe`、
  公平路径谓词 `fair_path` + 公平版 EG 构件 `sat_eg_fair`（34 章引用公平性概念）。

- [ ] **Step 1:** 读 `.scratch/hr/s3_3-3_4.txt` §3.3（互斥/NuSMV/ferryman/ABP 选读互斥即可）
  与 `.scratch/hr/s3_6-3_7.txt` §3.6.2（公平性）/§3.6.3（LTL MC 归约）。
- [ ] **Step 2:** Coq+Lean 实现：互斥双进程模型（状态=两进程各自 n/t/c 三态×轮转位，
  状态表手列 ≤18 态）；`check_mutex_safe : forall s, In s (satctl mutex (AG ¬(c1∧c2) 编码)) = true`
  形态的计算判定（`vm_compute`/`decide` 收口）；公平性：`fair_path m F π`（无限经常落入
  公平集 F）+ `sat_eg_fair`（存在满足公平约束的 EG 见证——语义层定义+一个具体公平
  例子的判定）。
- [ ] **Step 3:** `build.ps1 -Chapter 28` 全绿。
- [ ] **Step 4:** 写文档：模型检查工作流全景（§3.3：模型 M/性质 φ/「M,s₀⊨φ?」+反例轨）→
  ★互斥例子全程（两进程协议的非形式描述→状态表→AG 安全性/AG(t→AF c) 活性机器验证
  摘录讲解——**活性失败现场**：无公平性时调度器可永远偏心，反例路径展示）→
  ★公平性（§3.6.2：简单/公平约束两级；公平 EG 的思想——只在公平路径上找见证）→
  ★LTL 模型检查归约概念（§3.6.3 文档级：自动机化/积图判定，为什么比 CTL 难一档）→
  NuSMV 工具侧注（文档级一段：工程工具与本章教学模型的对应）→ 坑位速记。
- [ ] **Step 5:** 教程验收协议。

### Task 29: 29 章新建（CTL* 与表达能力对照）

**Files:**
- Create: `docs/29-ctlstar.md`（≥240 行）
- Create: `examples/29_ctlstar/ex29_ctlstar.v`、`ex29_ctlstar.lean`

- [ ] **Step 1:** 读 `.scratch/hr/s3_5.txt` 全部（§3.5 含两个不可表达反例——**以书原文为准**，
  提取该书给出的具体反模型图与公式）。
- [ ] **Step 2:** Coq+Lean 实现：两层语法（state form/path form 双归纳互嵌）；语义；
  **反例机器现场**：按书 §3.5 的具体反模型（LTL 的 FG p 无 CTL 等价：书上给一对模型
  M₁/M₂ 使任意 CTL 候选式区分失败的方向——机器单元只需：实现书上反模型 +
  对关键候选式（如 AF(AG p) 与 A(FG p) 的对应物）求值出**不同真值**，
  `Example ctl_cannot : eval_ctlsat m s φ_book = true /\ eval_ltl_universal m s ψ_book = false`）；
  CTL⊄LTL 方向同理按书。
- [ ] **Step 3:** `build.ps1 -Chapter 29` 全绿。
- [ ] **Step 4:** 写文档：为什么需要 CTL*（LTL 与 CTL 各有所不能——两个直觉例子先行）→
  两层语法（状态公式/路径公式的相互嵌入）→ 语义 → ★表达能力三角形
  （LTL⊂CTL*、CTL⊂CTL*、互不包含——两个反例全程机器求值讲解，反模型图文本绘制）→
  ★CTL 中的布尔组合（§3.5.1）与 ★过去算子（§3.5.2：Y/O/S 族——为什么工程上少用
  但表达方便）→ 与 21 章二阶表达线的呼应一段 → 坑位速记。
- [ ] **Step 5:** 教程验收协议。

- 批次九收口：`-All` 零回归 + PLAN.md + commit「批次九——27-29 新章：LTL/MC 算法与公平性/CTL*」。

---

## 批次十：31–33 模态三件套

### Task 30: 31 章新建（模态逻辑 K）

**Files:**
- Create: `docs/31-modal.md`（≥260 行）
- Create: `examples/31_modal/ex31_modal.v`、`ex31_modal.lean`

**Interfaces:**
- Produces: `frame := {W : Type; R : W -> W -> Prop}` 形态、`msat : frame -> (W -> nat -> Prop) -> W -> mform -> Prop`、
  有效件 `K_valid : 任意框架 ⊨ □(φ→ψ)→(□φ→□ψ)`、`nec : (⊨φ) -> (⊨□φ)`、`dia_dual`（32 章直接消费 frame/msat 定义形态）。

- [ ] **Step 1:** 读 `.scratch/hr/s5_1-5_4.txt` §5.1/5.2。
- [ ] **Step 2:** Coq+Lean 实现：`mform`（□◇ 双原生或 ◇ 导出——选 □ 原生 ◇ 导出），
  `msat` 语义（□φ：∀w'. R w w' → ⊨w' φ）；机器定理：`K_valid`（任意框架）、
  `nec`（全局有效→□后全局有效）、`dia_dual : ⊨ ◇φ ↔ ¬□¬φ`、`box_and : □φ∧□ψ ↔ □(φ∧ψ)`、
  反例件 `T_not_valid : ∃框架, ⊭ □φ→φ`（非自反框架具体构造——为 32 章对应理论埋钩）。
- [ ] **Step 3:** `build.ps1 -Chapter 31` 全绿。
- [ ] **Step 4:** 写文档：modes of truth（§5.1：必然/可能/知识/信念/义务——同一语法
  多解读）→ 语法 → ★Kripke 语义（可达关系 R 任意；与 13 章直觉主义版对照表——
  单调性无、R 无约束、否定古典）→ ★有效式库（§5.3.1：K 模式/对偶/分配族逐个讲+
  机器件摘录）→ ★必然化规则（「定理必然为定理」与「前提不能必然化」的对照——
  `nec` 的全局量词位置逐字讲）→ 坑位速记。
- [ ] **Step 5:** 教程验收协议。

### Task 31: 32 章新建（对应理论与逻辑工程）

**Files:**
- Create: `docs/32-correspondence.md`（≥260 行）
- Create: `examples/32_correspondence/ex32_correspondence.v`、`ex32_correspondence.lean`

- [ ] **Step 1:** 读 `.scratch/hr/s5_1-5_4.txt` §5.3 全部。
- [ ] **Step 2:** Coq+Lean 实现（复用 31 章 frame/msat 形态自包含）：五条**性质→有效**
  方向机器证明：

```coq
Theorem T_valid : (forall w, R w w) -> forall v w, msat v w (MImp (MBox φ) φ).
Theorem D_valid : (forall w, exists w', R w w') -> ... (MImp (MBox φ) (MDia φ)).
Theorem B_valid : (forall w w', R w w' -> R w' w) -> ... (MImp φ (MBox (MDia φ))).
Theorem four_valid : (forall x y z, R x y -> R y z -> R x z) -> ... (MImp (MBox φ) (MBox (MBox φ))).
Theorem five_valid : (forall x y z, R x y -> R x z -> R y z) -> ... (MImp (MDia φ) (MBox (MDia φ))).
```

  逆方向（有效→框架性质，「如果该式在所有世界有效则 R 必有该性质」）：
  Coq+Lean 各证一条代表（T 的逆：取 φ=原子 p、构造赋值使前提成立反推自反），
  其余文档讲解。
- [ ] **Step 3:** `build.ps1 -Chapter 32` 全绿。
- [ ] **Step 4:** 写文档：逻辑工程问题（§5.3 引子：要选「正确的」模态逻辑=选 R 的性质）→
  ★可达关系性质表（§5.3.2：自反/serial/对称/传递/欧性逐个讲+各配反模型图）→
  ★对应理论（§5.3.3：性质⟷公式模式双向表；正向五条机器件摘录讲解；逆向的
  证法思想——「拿一个世界当探针」）→ ★逻辑选型（§5.3.4：K/KT4=S4/KT45=S5/KT43…
  各适用场景：S4 必然性、S5 知识、D 信念一致性）→ 坑位速记。
- [ ] **Step 5:** 教程验收协议。

### Task 32: 33 章新建（模态自然演绎与 KT45n 知识逻辑）

**Files:**
- Create: `docs/33-modalnd.md`（≥260 行）
- Create: `examples/33_modalnd/ex33_modalnd.v`、`ex33_modalnd.lean`

- [ ] **Step 1:** 读 `.scratch/hr/s5_1-5_4.txt` §5.4 与 `.scratch/hr/s5_5.txt` 全部。
- [ ] **Step 2:** Coq+Lean 实现：模态 ND 深嵌入 `mnd : list mform -> mform -> Prop`
  （□i 严格性：仅当 Γ 全为 □ 形时可引入 □——构造子侧条件 `all boxed Γ`；
  □e/◇i/◇e 按 §5.4）；派生件：`¬◇φ ⊢ □¬φ`、`□(φ∧ψ) ⊢ □φ` 等 §5.4 例题两条；
  KT45n：多主体 `K_i` 语法族；muddy children 两孩版**模型求值现场**
  （可能世界=泥额组合×父亲宣告轮次；逐轮淘汰世界的列表计算——
  `Example muddy2 : 第二轮宣告后两孩都知道` 的 eval 判定）。
- [ ] **Step 3:** `build.ps1 -Chapter 33` 全绿。
- [ ] **Step 4:** 写文档：模态 ND 的四条新规则（§5.4：□i 的严格性纪律——「虚线框」
  直觉：进入框内只剩必然知识；为什么裸 Γ 不行）→ 机器演算摘录讲解 →
  ★多主体知识（§5.5.1/5.5.2：K_i φ「主体 i 知道 φ」；KT45n 公理：T 知识为真、
  4 正自省、5 负自省——各配直观解读）→ ★muddy children 全程（§5.5.1 谜题
  非形式讲解→可能世界建模→父亲每次宣告=公开宣布「至少一个泥额」后的世界淘汰→
  机器求值摘录→n 孩推广一段）→ wise men 对照一段（文档级）→ 坑位速记。
- [ ] **Step 5:** 教程验收协议。

- 批次十收口：`-All` 零回归 + PLAN.md + commit「批次十——31-33 新章：模态逻辑三件套」。

---

## 批次十一：34 新章 + 26 收官重写

### Task 33: 34 章新建（符号模型检查与关系 μ 演算）

**Files:**
- Create: `docs/34-symbolicmc.md`（≥280 行）
- Create: `examples/34_symbolicmc/ex34_symbolicmc.v`、`ex34_symbolicmc.lean`

**Interfaces:**
- Consumes: 10 章 `restrict/exb/apply`（自包含复制）、24 章 CTL 语义形态
- Produces: `preE : (st -> bool) -> (st -> st -> bool) -> (st -> bool)` 形态 +
  `preE_correct`、μ 演算 `mueval`（有限载体不动点迭代）+ `ctl_to_mu_correct`
  （EG/ EU 编码等价于 24 章语义，26 章图景引用）。

- [ ] **Step 1:** 读 `.scratch/hr/s6_3-6_4.txt` 全部（§6.3 符号 MC、§6.4 关系 μ 演算）。
- [ ] **Step 2:** Coq+Lean 实现：
  1. 状态集=布尔函数/BDD（小例子直接布尔函数，BDD 接口引用 10 章件）；
     `preE X R s := ∃s'. R s s' ∧ X s'`——用 exb/apply 的 BDD 版或布尔函数直接版 +
     `preE_correct : preE X R s = true <-> exists s', R s s' = true /\ X s' = true`；
  2. μ 演算语法（原子/布尔连接/◇ 模态/μ/ν，变元单调性侧条件文档说明）；
     `mueval : (list (st->bool)) -> muform -> (st -> bool)`——μ=从 ⊥ 起迭代 |S|+1 次、
     ν=从 ⊤ 起（有限载体收敛，引理 `iter_lfp`/`iter_gfp`）；
  3. 编码 `EG φ ↦ νZ. φ ∧ ◇Z`、`E[φ U ψ] ↦ μZ. ψ ∨ (φ ∧ ◇Z)`，证
     `ctl_to_mu_correct : mueval env (ctl_to_mu f) s = true <-> ctlsat m s f`
     （EG/EU 两条旗舰；其余连接词文档给表）。
- [ ] **Step 3:** `build.ps1 -Chapter 34` 全绿。
- [ ] **Step 4:** 写文档：状态爆炸问题（§6.3 引子：显式枚举的墙）→ ★状态集与迁移关系
  的特征函数/OBDD 编码（§6.3.1/6.3.2：布尔编码逐位讲）→ ★pre_∃/pre_∀ 计算
  （§6.3.3：「一步倒带」的几何直觉+机器件摘录）→ ★不动点迭代做 CTL（SAT_EG=
  从全集约减、SAT_EU=从目标集扩张——迭代图示）→ ★关系 μ 演算（§6.4：
  最小/最大不动点算子语法语义；为什么单调性保证不动点存在——Knaster–Tarski
  直觉版）→ ★CTL 编码进 μ 演算（§6.4.2 全表+两条机器等价讲解）→
  「符号 MC 是 10 章 BDD 与 24 章 CTL 的合流点」收束 → 坑位速记。
- [ ] **Step 5:** 教程验收协议。

### Task 34: 26 章收官重写 + README/PLAN/CHEATSheet 对账

**Files:**
- Modify: `docs/26-wrapup.md`（131→≥220）
- Modify: `mathlogic/README.md`、`mathlogic/PLAN.md`、`mathlogic/CHEATSheet.md`

- [ ] **Step 1:** 重写 26 章：图景更新为「SAT→SMT→MC（显式 24/28 → 符号 34 → 表达力
  天梯 29）→程序验证（25 部分/30 完全）→模态与知识（31–33）→ITP」；全书四条暗线
  逐条收账（每章一句话回扣）；总坑位清单补 27–34 新坑；**八书导读更新**：H&R 各章
  →本教程章节映射全表（H&R ch1→01-09、ch2→14-21、ch3→24/27/28/29、ch4→25/30、
  ch5→31/32/33、ch6→10/34）。
- [ ] **Step 2:** README 章节表补 27–34 行+「已知边界」更新；PLAN.md 蓝图表全标 ✅ 并追加
  27–34 行；CHEATSheet 追加：(a) 27–34 新通道坑；(b) 中译本术语对照小节
  （消费 Task 0 的 terms-zh.md，把「OCR 存疑」行剔除或核实后收录）。
- [ ] **Step 3:** `pwsh -NoProfile -Command '& ./build.ps1 -All'` 全量终验：既有 78 单元+
  新增单元全绿（单元数写进 commit message）；README 顶部「已完结」行更新章数与单元数。
- [ ] **Step 4:** 教程验收协议对 26 章；全 docs 抽查一遍「文字多于代码」全局口径：

```bash
cd /g/code/guide/mathlogic
for f in docs/*.md; do
  p=$(awk '/^```/{f=!f;next} !f{n++} END{print n+0}' "$f")
  c=$(awk '/^```/{f=!f;next} f{n++} END{print n+0}' "$f")
  l=$(wc -l < "$f")
  [ "$l" -lt 200 ] && echo "SHORT $f $l"
  [ "$c" -ge "$p" ] && echo "CODE-HEAVY $f prose=$p code=$c"
done   # 须无输出
```

- [ ] **Step 5:** commit「批次十一——34 新章 + 26 收官重写 + 全库对账」。

---

## Self-Review 记录

- Spec 覆盖：26 章扩写（T1–T25 对应）+ 6 处 H&R 织入（T3/T8/T9/T10/T14-T16/T21/T24/T25）+
  8 新章（T26–T33）+ 收官对账（T34）+ 取材/术语（T0）——spec 每条均有任务。
- 占位符扫描：无 TBD；所有代码件给出签名与证明路线；所有文档给出节级大纲。
- 类型一致：Task 9 产出 `hsat/hsat_sound`、Task 10 产出 `restrict/exb`（34 章消费）、
  Task 24 产出 `satctl/satctl_correct`（28/34 引用）、Task 26 产出 `hoareT_while/minsum_*`、
  Task 27 产出 `ltlsat`（28/29 引用形态）、Task 30 产出 `frame/msat`（31=Task30 的
  编号注意：31 章任务号是 Task 30，32 章=Task 31，33 章=Task 32）——接口名前后一致。
