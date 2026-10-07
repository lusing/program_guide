# mathlogic 教程 Jongsma《Discrete Mathematics via Logic and Proof》全谱扩充设计（2026-10-07）

## 背景与目标

mathlogic 教程现况：42 章全部交付（H&R 26 章 + Ben-Ari 8 章），120 个验证单元全绿
（七通道：Coq/Rocq 9.1、Agda、Lean 4.25 裸 core、Isabelle2025-2、HOL4、Coq-HoTT、
SWI-Prolog 10）。

本轮以 Calvin Jongsma《Introduction to Discrete Mathematics via Logic and Proof》
（Springer UTM 2019，496 页，8 章，文本层完好免 OCR）为纲，新增 **9 章（43–51）**，
把教程从「纯逻辑谱」扩成「逻辑 → 离散数学」全谱：归纳与递归、Peano 算术、整除、
集合与计数、无穷与停机问题、函数与等价关系、偏序与格、Boole 代数与逻辑电路、
图论专题。这与书的教学线完全一致：**逻辑不是孤立学科，而是读懂数学证明的钥匙**；
后续每个离散主题都以第 1–2 章的推理规则为底座。

用户指令的三条硬要求（沿用 [[tutorial-prose-over-code]]）：

1. **教程而非代码罗列**：所有要讲的代码在正文中引用，不许让读者自己看源码。
2. **提炼原书核心内容并全部自包含**：不写「见原书 §x.y」式的踢皮球；原书该主题的
   核心概念、定理、证明思路全部内嵌到 docs 讲清。
3. **无篇幅限制，讲清楚为止**：每章 ≥200 行、文字多于代码。

## 书的定位与映射

Jongsma 书八篇 → 本教程章节映射：

| 书章 | 内容 | 本教程归属 |
|---|---|---|
| 1 Propositional Logic（1.1–1.9） | 论证语义、Fitch 式 Proof Diagram、全部 ND 规则、条件证明/MT/反证 | 已有 02/03/04 覆盖（更深的机器化）；43 章首织入「非形式证明方法 ↔ ND 规则」桥 |
| 2 First-Order Logic（2.1–2.4） | 符号化、语法语义、同一律规则、量词规则 | 已有 14–18 覆盖 |
| 3 Mathematical Induction and Arithmetic（3.1–3.5） | PMI/强归纳/良序、递归、递推关系、结构归纳、Peano 算术、整除 | **新 43/44/45 三章** |
| 4 Basic Set Theory and Combinatorics（4.1–4.5） | 集合运算、幂集、乘法/加法计数、组合、容斥、鸽笼 | **新 46 章** |
| 5 Set Theory and Infinity（5.1–5.3） | 可数无穷、对角线、Cantor、ZFC 公理一览、停机问题 | **新 47 章** |
| 6 Functions and Equivalence Relations（6.1–6.4） | 单满双、复合与逆、等价关系与划分、ℤ 与模算术 | **新 48 章** |
| 7 Posets, Lattices, Boolean Algebra（7.1–7.6） | 偏序、格、Boole 代数、对偶原理、逻辑电路、minterm/K-map 化简 | **新 49/50 两章** |
| 8 Topics in Graph Theory（8.1–8.4） | Euler 迹、Hamilton 路、平面图、着色 | **新 51 章** |

书 ch1–2 与已有章的关系在 spec 批次十的「收官对账」中写明（教程对 PL/FOL 的覆盖
比 Jongsma 更深：有矢列/表列/归结/不完备等元理论，而 Jongsma 只到 ND 应用层）。

## 新章设计（编号=示例号；通道 C=Coq L=Lean P=Prolog）

| 章 | 主题（书源） | 机器件（全部零公理或显式公理记账） | 通道 |
|---|---|---|---|
| 43 数学归纳与递归（3.1–3.2） | PMI 三位一体：弱归纳/强归纳/良序；递归定义为何合法（结构性终止）；Mod PMI；WOP | `pmi_trinity`：强归纳（辅助对定理 zero-axiom 手证）、WOP 可判定谓词版（线性搜索 first-from）、弱→强→良序的推导链；递归定义的机器形态=Fixpoint 结构递归；`Σk = n(n+1)/2` 等归纳样板 | C/L |
| 44 递推、结构归纳与 Peano 算术（3.3–3.4） | 递推关系（一阶线性闭式、Fibonacci 恒等式）；结构归纳（串/list 反演律、公式 AST）；PA 一阶公理表、定义方程、≤ 反对称 | `rev_invol`/`rev_append`（结构归纳样板）；`fib_sq_sum`（Σfib²=fib n·fib(n+1)）；PA 公理表（文档级展示+定义方程 rfl 对账）；`S` 单射、+ 交换/结合、≤ 反对称（归纳） | C/L |
| 45 整除性与初等数论（3.5） | 除法算式、gcd、Euclid、Bézout、素数、FTA、素数无穷 | `dmod` 除法算式（存在+唯一）；fuel 版 Euclid `gcdn` 可靠性；扩展 Euclid 的 Bézout（g·a+h·b=gcd）；`prime` 定义+素数无穷（有限素数表+1 构造）；Euclid 引理（素数∣ab ⇒ ∣a∨∣b，Bézout 驱动）；FTA 文档级 | C/L |
| 46 集合、幂集与计数（4.1–4.5） | 集合运算与幂集；乘法原理/排列/组合；加法原理/容斥/鸽笼；Pascal/二项式 | `powl` 幂集列表+`length(powl s)=2^n`+双向完备性；`prodl` 笛卡尔积+长度=乘积；容斥长度方程（filter 版归纳）；**鸽笼引理 `nodup+incl⇒length≤`（章旗舰）**；`choose` Pascal+`ΣC(n,k)=2^n`；二项式定文档级 | C/L |
| 47 无穷集合与停机问题（5.1–5.3） | 等势、可数、ℤ/ℕ×ℕ/ℚ 可数（对角线遍历）；Cantor 对角线；\|P(S)\|>\|S\|；ℝ 不可数；ZFC 一览；Russell；停机问题 | `diag` 对角遍历 nat→nat×nat 满射（dovetailing 机器面）；`cantor`：无满射 α→(α→bool)（零公理）；Russell=同一对角线的成员版；停机问题：**显式公理记账**（普遍性作公理 u，对角 q 推矛盾）；ℝ/CSB/ZFC 文档级 | C/L |
| 48 函数与等价关系（6.1–6.4） | 单/满/双射；复合保持；逆函数；等价关系↔划分互构；同余类与 ℤₙ | `pinv` fuel 搜索伪逆：单射⇒左逆、满射⇒右逆（可构造）；`partition_of`（可判定等价关系→划分）+类内同类；`sameClass`（划分→等价关系）；`cong`（复用 45 章 dmod）+ 加法/乘法良定义 | C/L |
| 49 偏序与格（7.1–7.2） | 偏序、Hasse、极值元四种、链/反链；格的序论定义⇔代数定义；分配格、有补格 | 整除偏序三律（反对称=乘法消去）；`lub_unique` 极值元唯一性；**双定义等价**：代数格⇒`x∧y=x` 序+glb 性质、序格(∃!)⇒吸收律（章旗舰）；gcd/lcm 作整除格的 meet/join（跨 45 章联动）；分配/有补 文档+反例 | C/L |
| 50 Boole 代数与逻辑电路（7.3–7.6） | Boole 格→Boole 代数公理；对偶原理；Boole 函数↔逻辑电路；minterm/maxterm 范式；K-map 与化简 | `dual` 对偶变换+`eval(dual e)v=¬eval e(¬v)`（结构归纳）⇒**对偶原理机器证明**；全加器 `sum/carry` 对 nat 算术正确+波纹进位；`dnf_of` minterm 展开恒等（filter 全指派版）；**QMC 可靠性**（蕴含+覆盖⇒等值）；K-map 文档级精讲 | C/L/P |
| 51 图论专题（8.1–8.4） | Euler 迹判定；Hamilton（必要条件）；平面图 Euler 公式与 K5/K3,3；着色与四色 | 度数定理 `Σdeg=2E`（边表归纳）；**Königsberg 由机器判定**（4 个奇度数 Compute）；Hamilton 删点必要条件+**Petersen 非哈密顿（部件计数 Compute 判定）**；K5/K3,3 边数界 Compute 判定；`greedy_color` 贪心着色正确+`χ≤Δ+1`；Euler 公式/四色 文档级；Prolog Euler 迹搜索 | C/L/P |

合计 20 个新验证单元（18 C/L + 2 P），120 → **140**。

## 教程标准（与 H&R/Ben-Ari 两轮一致，逐条可检验）

- 自包含：只读 docs 能学会；「对书：Jongsma §x.y」仅作溯源。
- 每章 ≥200 行且文字行数 > 代码行数；每段代码前后必有文字（证什么/为何这样写/关键一步）。
- 正文代码摘录自 examples/ 真实可编译文件并注明文件名。
- 章末坑位速记；Zig 式章末导航（42 章的「（完）」改为指向 43；51 章以「（完）」收尾）。
- 零公理或显式公理记账（47 章停机问题的普遍性公理是唯一显式公理新例）。
- 诚实止步：卡住的通道按惯例「止步+速记」，不许假装。

## 取材协议

- 主源：`G:\book\计算机\Introduction to Discrete Mathematics via Logic and Proof.pdf`。
  **PDF 页 = 书页 + 1**（实测：书 p.20 = PDF 21）。已按章提取到 `.scratch/jongsma/`
  （ch1_pl/ch2_fol/ch3_induction/ch4_sets/ch5_infinity/ch6_functions/ch7_boolean/
  ch8_graphs + preface），每批动笔前先读对应章文本再写。
- 文本层完好，**不用 OCR**（RapidOCR 预案不动用）。
- 公式以文本层为准；InDesign 断行碎片在阅读时人工拼接。

## 验收协议（每章）

```bash
cd /g/code/guide/mathlogic
pwsh -NoProfile -Command '& ./build.ps1 -Chapter NN'   # 新章全绿
wc -l docs/NN-x.md                                      # ≥200
awk '/^```/{f=!f;next} !f{n++} END{print "prose:",n}' docs/NN-x.md
awk '/^```/{f=!f;next} f{n++} END{print "code:",n}' docs/NN-x.md   # < prose
grep -n '自行\|见原书\|参见原书\|读者自己看' docs/NN-x.md           # 须无输出
```

既有 120 单元每批零回归（抽验相邻章）；批次十全量 `-All` 收官。

## 提交节奏

批次一～九各一章（`feat(mathlogic): 批次N——…`），批次十对账收官
（26 收官章 Jongsma 导读+账本、README/PLAN/CHEATSheet/导航链、全量回归）。
每条 commit 尾 `Co-Authored-By: Claude Code <noreply@anthropic.com>`。
