# measuretheory 教程工程设计（2026-10-19）

## 0. 目标与定位

以严加安《测度论讲义》第二版（科学出版社，2004；9 章 48 节，正文约 287 页）
为纲的中文测度论教程，落盘 `G:\code\guide\measuretheory\`。要求：

- **自包含**：提炼原书全部核心内容并讲清，读者不需要回看原书；每章开头给
  "对应严书 §x.y（pp. a-b）"定位锚，仅作索引不作依赖。
- **教程而非代码罗列**：讲解为主体（tutorial-prose-over-code 纪律），每章
  ≥200 行、文字多于代码，所有要讲的代码在正文中引用并解释，"对应示例：
  examples/..."指路放章末可选项。
- **五通道机器验证**：Lean 4+mathlib4 主证 / Isabelle HOL-Analysis 二证 /
  Julia 数值 / Python(scipy) 数值 / Prolog 有限模型。

原书特有、通常教材少见的 内容必须保留并讲透：L∞(Ω,ℱ) 与
L∞(Ω,ℱ,m) 的对偶（ba 空间）、Daniell 积分、Bochner/Pettis 积分、
Kolmogorov 相容性定理及 Tulcea 定理的推广、概率测度序列的投影极限、
随机 Daniell 积分及其核表示（作者研究成果）、解析集与 Choquet 容度、
离散时间局部鞅、Minlos-Sazonov/Minlos 定理、Hilbert 空间上的 Gauss 测度。

## 1. 底书与取材

### 1.1 严书结构（OCR 目录已核）

PDF：`G:\book\数学\测度论讲义 (严加安) (...).pdf`，304 页，无文字层扫描。
**每个 PDF 页是一摊对页，且每摊重复出现两次**（实测 p11≡p12、p17≡p18、
p19≡p20）。书页 N（N≥2）位于 PDF 奇数页 `2·ceil((N+15)/2) − 1`；书 p.1
在 PDF p15/16 右半。正文第 1 章起于书 p.1（PDF p17 摊）。

| 书章 | 节 | 书页 |
|---|---|---|
| 1 集类与测度 | 1.1 集合运算与集类 / 1.2 单调类定理(集合形式) / 1.3 测度与非负集函数 / 1.4 外测度与测度的扩张 / 1.5 欧氏空间中的 Lebesgue-Stieltjes 测度 / 1.6 测度的逼近 | 1-26 |
| 2 可测映射 | 2.1 定义及基本性质 / 2.2 单调类定理(函数形式) / 2.3 可测函数序列的几种收敛 | 27-43 |
| 3 积分和空间 Lp | 3.1 积分的基本性质 / 3.2 积分号下取极限 / 3.3 不定积分与符号测度 / 3.4 空间 Lp 及其对偶 / 3.5 空间 L∞(Ω,ℱ) 和 L∞(Ω,ℱ,m) 的对偶 / 3.6 Daniell 积分 / 3.7 Bochner 积分和 Pettis 积分 | 44-92 |
| 4 乘积可测空间上的测度与积分 | 4.1 乘积可测空间 / 4.2 乘积测度与 Fubini 定理 / 4.3 由 σ 有限核产生的测度 / 4.4 无穷乘积空间上的概率测度 / 4.5 Kolmogorov 相容性定理及 Tulcea 定理的推广 / 4.6 概率测度序列的投影极限 / 4.7 随机 Daniell 积分及其核表示 | 93-121 |
| 5 Hausdorff 空间上的测度与积分 | 5.1 拓扑空间 / 5.2 局部紧 Hausdorff 空间上的测度与 Riesz 表现定理 / 5.3 Hausdorff 空间上的正则测度 / 5.4 空间 C₀(X) 的对偶 / 5.5 用连续函数逼近可测函数 / 5.6 乘积拓扑空间上的测度与积分 / 5.7 波兰空间上有限测度的正则性 | 122-164 |
| 6 测度的收敛 | 6.1 欧氏空间上 Borel 测度的收敛 / 6.2 距离空间上有限测度的弱收敛 / 6.3 胎紧与 Prohorov 定理 / 6.4 可分距离空间上概率测度的弱收敛 / 6.5 局部紧 Hausdorff 空间上 Radon 测度的淡收敛 | 165-185 |
| 7 概率论基础选讲 | 7.1 独立性、0-1律 / 7.2 条件数学期望与条件独立性 / 7.3 正则条件概率 / 7.4 一致可积性 / 7.5 本性上确界 / 7.6 解析集与 Choquet 容度 | 186-234 |
| 8 离散时间鞅 | 8.1 鞅不等式 / 8.2 鞅收敛定理及其应用 / 8.3 局部鞅 | 235-256 |
| 9 Hilbert/Banach 空间上的测度 | 9.1 ℝⁿ 上 Borel 测度的 Fourier 变换和 Bochner 定理 / 9.2 Minlos-Sazanov 定理 / 9.3 Minlos 定理 / 9.4 Hilbert 空间上的 Gauss 测度 | 257-283 |

参考文献 p.284，名词索引 p.286。

### 1.2 OCR 方案

- 工具：`tools/ocr_yan.py`（已建，render/ocr 两命令），rapidocr GPU
  **单进程串行**（双进程 cudnn FE 显存必炸——前科），PATH 前置
  `G:\cudnn\9.24\bin\12.9\x64`，python = G:/scoop/apps/python313。
- 范围：PDF 奇数页 17-303（约 144 页，对页重复故只跑一半）。
  B0 一次跑完，断点续扫（缺页补跑）。
- **纪律：OCR 只作取材骨架**（定理编号、陈述顺序、习题素材、书特有的
  记号与约定）。数学公式一律按领域知识重建，扫描数学 OCR 不可信。
- 袁书（袁德美/王学军《测度论基础与高等概率论》上/下册，同目录）：仅
  B10 选讲取材。B10 前 OCR 下册特征函数/CLT/大数定律相关章（先查有无
  文字层，有则免 OCR）。

## 2. 章节总表（51 篇）

docs 命名 `NN-slug.md`。通道列：L=Lean，I=Isabelle，J=Julia，P=Python，
R=Prolog；★=该章主力通道。批次 B0-B10。

| 章 | 主题 | 书节 | L | I | J | P | R | 批 |
|---|---|---|---|---|---|---|---|---|
| 00 | 导言：测度论地图、本书定位、工具链 | — | | | | | | B0 |
| 01 | 集合运算与集类（半环/环/σ环/代数，π 系） | 1.1 | ✓ | | ✓ | ✓ | ★ | B1 |
| 02 | 单调类定理（集合形式） | 1.2 | ✓ | | ✓ | ✓ | ★ | B1 |
| 03 | 测度与非负集函数 | 1.3 | ★ | | ✓ | ✓ | ✓ | B1 |
| 04 | 外测度与测度扩张（Carathéodory、完备化） | 1.4 | ★ | | ✓ | ✓ | ✓ | B1 |
| 05 | Lebesgue-Stieltjes 测度 | 1.5 | ★ | | ✓ | ✓ | | B1 |
| 06 | 测度的逼近 | 1.6 | ★ | | ✓ | ✓ | ✓ | B1 |
| 07 | 可测映射 | 2.1 | ✓ | | ✓ | ✓ | ★ | B2 |
| 08 | 单调类定理（函数形式） | 2.2 | ✓ | | ✓ | ✓ | ★ | B2 |
| 09 | 可测函数序列的收敛（Egorov/Riesz 子列） | 2.3 | ★ | | ✓ | ✓ | ✓ | B2 |
| 10 | 积分的基本性质 | 3.1 | ★ | ✓ | ✓ | ✓ | ✓ | B3 |
| 11 | 积分号下取极限（MCT/Fatou/DCT） | 3.2 | ★ | ✓ | ✓ | ✓ | | B3 |
| 12 | 不定积分与符号测度（Hahn/Jordan/RN） | 3.3 | ★ | ✓ | ✓ | ✓ | | B3 |
| 13 | 空间 Lp 及其对偶 | 3.4 | ★ | ✓ | ✓ | ✓ | | B3 |
| 14 | L∞ 的对偶与 ba 空间 | 3.5 | 通道分工 | | ★ | ✓ | ✓ | B3 |
| 15 | Daniell 积分 | 3.6 | 通道分工 | | ★ | ✓ | ★ | B3 |
| 16 | Bochner 积分与 Pettis 积分 | 3.7 | ★ | ✓ | ✓ | ✓ | | B3 |
| 17 | 乘积可测空间 | 4.1 | ✓ | | ✓ | ✓ | ★ | B4 |
| 18 | 乘积测度与 Fubini 定理 | 4.2 | ★ | ✓ | ✓ | ✓ | | B4 |
| 19 | 由 σ 有限核产生的测度 | 4.3 | ★ | | ✓ | ✓ | ✓ | B4 |
| 20 | 无穷乘积空间上的概率测度 | 4.4 | ★ | ✓ | ✓ | ✓ | | B4 |
| 21 | Kolmogorov 相容性定理及 Tulcea 定理 | 4.5 | 通道分工 | | ★ | ✓ | ★ | B4 |
| 22 | 投影极限与随机 Daniell 积分（4.6+4.7 合并） | 4.6-4.7 | 通道分工 | | ✓ | ✓ | | B4 |
| 23 | 拓扑空间：预备与 Borel 构造 | 5.1 | ✓ | | ✓ | ✓ | ✓ | B5 |
| 24 | 局部紧空间与 Riesz 表现定理 | 5.2 | 视侦察 | | ★ | ✓ | | B5 |
| 25 | Hausdorff 空间上的正则测度 | 5.3 | ✓ | | ✓ | ✓ | | B5 |
| 26 | 空间 C₀(X) 的对偶 | 5.4 | 视侦察 | | ✓ | ✓ | | B5 |
| 27 | 用连续函数逼近可测函数（Lusin） | 5.5 | ✓ | | ★ | ✓ | | B5 |
| 28 | 乘积拓扑空间上的测度与积分 | 5.6 | ✓ | | ✓ | ✓ | | B5 |
| 29 | 波兰空间上有限测度的正则性 | 5.7 | ★ | | ✓ | ✓ | | B5 |
| 30 | 欧氏空间上 Borel 测度的收敛 | 6.1 | ✓ | | ★ | ✓ | | B6 |
| 31 | 距离空间上有限测度的弱收敛（Portmanteau） | 6.2 | ★ | ✓ | ✓ | ✓ | | B6 |
| 32 | 胎紧与 Prohorov 定理 | 6.3 | ★ | | ✓ | ✓ | | B6 |
| 33 | 可分空间上概率测度的弱收敛度量化 | 6.4 | 视侦察 | | ★ | ✓ | | B6 |
| 34 | 淡收敛 | 6.5 | 通道分工 | | ★ | ✓ | | B6 |
| 35 | 独立性与 0-1 律 | 7.1 | ★ | | ✓ | ✓ | ✓ | B7 |
| 36 | 条件数学期望与条件独立性 | 7.2 | ★ | ✓ | ✓ | ✓ | | B7 |
| 37 | 正则条件概率 | 7.3 | ★ | | ✓ | ✓ | | B7 |
| 38 | 随机变量族的一致可积性 | 7.4 | ★ | ✓ | ✓ | ✓ | | B7 |
| 39 | 本性上确界 | 7.5 | ★ | | ✓ | ✓ | ✓ | B7 |
| 40 | 解析集与 Choquet 容度 | 7.6 | 视侦察 | | ✓ | ✓ | ✓ | B7 |
| 41 | 鞅不等式（Doob） | 8.1 | ★ | | ✓ | ✓ | ✓ | B8 |
| 42 | 鞅收敛定理及其应用 | 8.2 | 视侦察 | | ★ | ✓ | ✓ | B8 |
| 43 | 离散时间局部鞅 | 8.3 | 通道分工 | | ★ | ✓ | ✓ | B8 |
| 44 | ℝⁿ Borel 测度的 Fourier 变换与 Bochner 定理 | 9.1 | 视侦察 | ✓ | ✓ | ★ | | B9 |
| 45 | Minlos-Sazonov 定理 | 9.2 | 通道分工 | | ★ | ✓ | | B9 |
| 46 | Minlos 定理 | 9.3 | 通道分工 | | ★ | ✓ | | B9 |
| 47 | Hilbert 空间上的 Gauss 测度 | 9.4 | 视侦察 | | ★ | ✓ | | B9 |
| 48 | 选讲：特征函数与中心极限定理（袁下册） | — | 视侦察 | ★ | ✓ | ✓ | | B10 |
| 49 | 选讲：大数定律（袁下册） | — | 视侦察 | | ★ | ✓ | | B10 |
| 50 | 收官：CHEATSheet（定理地图+两书对照+坑账） | — | | | | | | B10 |

"视侦察"= B0 或该批开工前 grep mathlib/Isabelle 源码定锚点后再定 Lean
是否承载；"通道分工"= 无机器基础设施，按 funanalysis vN 代数先例由数值/
有限通道承载并在文档如实标注（不硬造形式化）。

预计验证单元约 175-185。

## 3. 通道架构

### 3.1 目录结构

```
measuretheory/
  README.md            入口：定位、通道、构建、章表
  PLAN.md              逐章通道分配 + 批次进度表（工作文档）
  build.ps1            五通道对账（pwsh）
  docs/00..50-*.md     教程正文
  examples/lean/       单一 lake 工程（Measuretheory/ChNN_*.lean）
  examples/isabelle/   ROOT + TNN_*.thy（每章一个 session MTNN）
  examples/julia/      NN_*.jl（标记 ==== NN / END ====）
  examples/python/     NN_*.py（python -I + PYTHONIOENCODING=utf-8）
  examples/prolog/     NN_*.pl（swipl -q -f F -g main -t halt）
  tools/ocr_yan.py     OCR 流水线（已建）
  build/               产物（gitignore）
```

### 3.2 工具链与判定（沿 funanalysis 协议）

- **Lean**：mathlib 依赖 `require mathlib from
  "H:/Lang/lean4/mathlib4-4.33.1"`，toolchain `leanprover/lean4:v4.33.1`，
  `lake exe cache get`。整工程一次 `lake build`，退出码 0 且输出无
  error:/warning:；报告时逐章点亮 ChNN*.lean。**注意：该钉版树实为 2026
  master 快照**（funanalysis 前科：integrable_zero 显式参、sq_abs 方向、
  Filter.Tendsto 需 open、Set.mem_setOf_eq 弃用、λ 保留字等）——每批
  grep 源码正名，不凭记忆。
- **Isabelle**：Isabelle2025-2 经 pwsh 调 `contrib/cygwin/bin/bash.exe
  -lc "isabelle build -d <dir> MTNN"`（Git Bash 直调被 MSYS 路径转换弄坏）。
  HOL-Analysis 首建 ~8 分钟（用户堆已在 ~/.isabelle/Isabelle2025-2/heaps），
  B0 冒烟验证。ROOT 一律手写/Edit 工具（python 写盘 CRLF 前科）。text
  \<open> 里禁 \<^sup> 控制符号。
- **Julia**：`julia --startup-file=no`，退出码 0 + 标记。前科：全角标点
  紧跟 $var 须 $(var)；顶层 for 软作用域封装函数；随机实验必须
  Random.seed!。
- **Python**：`python -I`，PYTHONIOENCODING=utf-8；文件头 UTF-8 wrapper
  （GBK 控制台前科）；scoop 3.15 numpy 坏则回落 3.13。
- **Prolog**：swipl 主通道；WSL gprolog 为 -ExtraProlog 抽查通道。前科：
  format/2 必带 []；main 尾部 ! 消 choice point；原子名全库一致；
  MSYS_NO_PATHCONV=1。

### 3.3 数值实验纪律

- 断言前先心算理论值；理论等值点上的严格不等断言留余量（前科：1/√m
  恰减半翻车）；无种子随机断言随机翻车——一律钉种子。
- 采样网格注意右端点排除、频率约定（fftfreq 第二参是采样率）等数值坑。

## 4. B0 侦察清单（grep 两库源码正名，产出锚点表进 PLAN.md）

mathlib（H:/Lang/lean4/mathlib4-4.33.1）候选锚点，逐个验证存在性+精确名：
外测度/Carathéodory（OuterMeasure、caratheodory、Measure.completion）、
Stieltjes（measureStieltjes）、测度扩张唯一性（Measure.ext 族）、
Egorov（Function/Egorov?）、单调类（MonotoneClass? 函数形式
MeasurableSpace.induction_on?）、lintegral/integral 构造与极限定理
（lintegral_monotone、integral_dominated_convergence、Fatou）、
SignedMeasure/Hahn/Jordan/rnDeriv/haveLebesgueDecomposition、Lp 空间
（MeasureTheory.Lp、对偶）、essSup、condexp、condKernel、
UniformIntegrable、Measure.prod/Fubini-Tonelli（lintegral_prod）、
Kernel（Kernel.comp/prod/deterministic）、Measure.pi、Portmanteau/
WeakConvergence、Tight/Prohorov、cdf/Stieltjes、Kolmogorov 0-1
（Probability/KolmogorovZeroOne?）、Indep 族、Submartingale 族
（submartingale_max_mul_le、Doob 分解、收敛定理有无、上穿不等式有无）、
bochnerIntegral/SimpleFunc.bintegral/Pettis 可测性（StronglyMeasurable/
AEStronglyMeasurable）、charFun/CLT 有无、gaussMeasure、BorelSpace/
Regular（Measure.Regular）、波兰正则性、Lusin（Function/Lusin?）、
Riesz 表现（RieszRepresentation 有无）、解析集（IsAnalytic 有无）、
Birkhoff 遍历（birkhoff）。

Isabelle（HOL-Analysis/HOL-Probability）候选：has_integral_lebesgue/
lebesgue_integral、integral_fubini/Fubini、RN_deriv、conditional_
expectation、weak_convergence（Weak_Convergence.thy）、central_limit_
theorem（CLT 有无）、characteristic 函数、Bochner_Integration、
PiM/无穷乘积、LPspace（Lp 有无）。

侦察结论写进 PLAN.md 锚点表；"视侦察"章据此定案。

## 5. 质量门

1. `build.ps1 -All` 全绿（章×通道矩阵，退出码+标记对账）。
2. docs 每章 wc -l ≥ 200，且文字行多于代码行。
3. Julia/Python 每实验文件 wc -l ≥ 40 且含实质数值断言（防占位符——
   funanalysis B9.5 事故教训：协议绿灯 ≠ 质量合格）。
4. 每批收官抽 2 章人工核对 docs↔examples 引用路径存在、代码与讲解一致。
5. 数学正确性双保险：OCR 公式不可信（按领域知识重建）+ 机器通道当纠错器
   （funanalysis 两次机器抓错先例：先怀疑陈述为假再怀疑证明）。

## 6. 批次计划

- **B0 基建**：OCR 全书（奇数页 17-303）；四侦察（mathlib/Isabelle 锚点
  正名 → PLAN.md）；lean/isabelle 工程骨架+冒烟；build.ps1；README/PLAN；
  docs/00。提交 1-2 笔。
- **B1**（01-06）→ **B2**（07-09）→ **B3**（10-16）→ **B4**（17-22）→
  **B5**（23-29）→ **B6**（30-34）→ **B7**（35-40）→ **B8**（41-43）→
  **B9**（44-47）→ **B10**（48-50 + 袁书 OCR + 收官对账）。
- 每批：该批章 docs + 全部通道文件 + 该批全绿 + 收官对账 → 提交一笔。

## 7. 风险与预案

| 风险 | 预案 |
|---|---|
| mathlib 4.33 快照 API 漂移 | 每批 grep 源码正名；坑即时入册（docs/50 坑账） |
| 高级专题无机器支撑（ba/投影极限/随机 Daniell/容度/Minlos/局部鞅/淡收敛） | 通道分工如实标注；不硬造形式化 |
| Isabelle 会话/堆损坏 | 不强杀（poly 强杀 → 53 分钟级重建前科）；ROOT 手写 |
| OCR 显存炸 | 单进程串行 + 断点续扫 |
| CLT/SLLN 在 mathlib 缺位 | Isabelle HOL-Probability 扛 CLT；SLLN 走 Birkhoff 或数值+全文证明 |
| 章数多工期长 | 按批提交，每批独立可用；PLAN.md 记进度，断点可续 |

## 8. 写作纪律落地（每章模板）

1. 开门：本章讲什么、为什么需要它（直觉/动机/历史一笔）。
2. "对应严书 §x.y（pp. a-b）"锚。
3. 概念→定义（形式化合同）→定理→证明（关键步骤讲透，不跳步）→例子
   与反例→机器视角（该章各通道做了什么、输出说明什么）→常见坑。
4. 所有代码段前后有讲解；示例输出逐行解释。
5. 章末：要点回顾 + "对应示例：examples/...（可选）"。
