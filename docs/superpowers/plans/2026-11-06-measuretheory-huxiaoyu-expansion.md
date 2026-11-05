# 测度论教程 · 胡晓予《高等概率论》扩充轮（H 轮）

日期：2026-11-06 起。参考书：胡晓予《高等概率论》（科学出版社 2009，
G:\book\数学\概率论与数理统计\高等概率论-胡晓予.pdf，178 页 PDF，
书页 = PDF 页 − 6）。正文文本层为 CID 乱码，已整页 OCR 到
`measuretheory/build/ocr/huxiaoyu/pNNN.txt`（工具
`measuretheory/tools/ocr_huxiaoyu.py`，cudnn PATH 前置
G:/cudnn/9.24/bin/12.9/x64）。OCR 只作取材骨架，数学内容按领域知识
自包含重建——项目纪律。

## 背景

本轮最初拟扩充 probability/ 教程，用户改向：撤回全部 probability/
改动（已完成：git reset 回 3fe8db74，OCR 资产移入 measuretheory/），
改为扩充**测度论教程**（G:\code\guide\measuretheory\，57 章 + 速查
= 58 篇，210/210 全绿，严加安+袁德美双书全谱）。

## 缺口分析（胡书 8 章 × 现有 57 章）

| 胡书 | 现有覆盖 | 结论 |
|---|---|---|
| 1 测度与积分 1.1-1.4, 1.6-1.7 | 01-11 全覆盖 | 仅取角度补充 |
| 1.5 Hausdorff+填充测度 | 仅 04 提及产品名 | **新章** |
| 2 测度分解 2.1-2.2 | 12 符号测度 | 已覆盖 |
| 2.3 RN 实分析应用（测度导数/BV/AC） | 无 | **新章** |
| 3 乘积空间 | 17-22 | 已覆盖 |
| 4 概率基础（条件期望/BC/0-1） | 35-36 | 已覆盖 |
| 5 CLT、6 LLN/LIL | 31-34, 44-56 | 已覆盖 |
| 7 离散鞅（含选样定理） | 41-43（含停时/可选停止） | 已覆盖 |
| 8.1 随机游动与马氏链 | 无专章 | **新章** |
| 8.2 布朗运动 | 无专章（21 提及） | **新章** |
| 8.3 高斯自由场 | 无 | **新章** |

## 新结构（追加式，速查表 57→62）

第八篇 测度的几何与实分析应用（胡书 §1.5、§2.3）
- 57 hausdorff-packing Hausdorff 测度、填充测度与分形维数
  （预测度→外测度机器 Method II、测度函数 φ、Cantor 集完整账、
  φ-m ≤ φ-p、dim_H ≤ dim_p；定位：紧接 04/05 测度构造线）
- 58 differentiation 测度的导数：Lebesgue 微分定理、有界变差与
  绝对连续（上下导数、5-区间覆盖引理、奇导引理 2.3.1、AC⟺积分
  定理 2.3.5、Lebesgue 点；定位：紧接 12 符号测度/RN）

第九篇 随机过程选讲（胡书 §8）
- 59 random-walks 随机游动与马氏链：转移阵、首中、常返与遍历
  （Chapman–Kolmogorov、f*/g* 生成函数、Polya 判别、强马氏性
  定理 8.1.2、遍历极限定理 8.1.4、通信系统例、赌徒破产；定位：
  21 相容性的应用 + 41 停时）
- 60 brownian-motion 布朗运动：构造、乘量、反射与 LIL
  （定义 8.2.1、游动极限动机、K-L/Fourier 构造 8.3.2、四基本性质、
  极大不等式定理 8.2.3、首中时、重对数律 8.2.1/一致连续模 8.2.2；
  定位：56 LIL 的连续版对读）
- 61 gaussian-free-field 高斯自由场：Gauss–Hilbert 构造与狄利克雷能量
  （定义 8.3.1/8.3.2、等距场、布朗运动=区间场、平面 GFF、特征基
  fᵢ=eᵢ/√(−λᵢ)、格林函数与离散 GFF、乘性混沌与定理 8.3.1；定位：
  47 Gauss 测度的场论 cousin）

收官
- 62 cheatsheet（原 57 顺移）

## 批次

- H0 计划 + 速查表 57→62（docs 改名 + 56 章尾导航 + README 最小
  修补 + commit）
- H1 57 Hausdorff · H2 58 微分定理 · H3 59 随机游动 ·
  H4 60 布朗运动 · H5 61 GFF
- H6 收官：README 全表重写（第八/九篇）、00-intro 三书底本、
  62 速查增补、build -All 全绿、PLAN 坑账 #86+、memory

每章：docs/NN-slug.md（≥200 行、讲解为主、代码全部正文内引用、
页脚登记示例）+ examples（Lean 主证明 / Julia 数值 / Python 精确
Fraction / Prolog 有限穷举；Isabelle 本轮不新增——按通道分工纪律）+
build.ps1 -Chapter NN 绿后提交。

## Lean/mathlib 4.33 锚点候选（写作时核实真名）

- Hausdorff：`Mathlib/MeasureTheory/Measure/Hausdorff.lean`
  （`hausdorffMeasure μH[d]`、`dimH`、Cantor 相关）
- 微分定理：`Mathlib/MeasureTheory/Covering/`（Besicovitch/Vitali）、
  `Measure.rnDeriv`、单调函数可微（`MeasureTheory/...`）
- 随机游动：转移阵幂 `Matrix.mul` 精确 ℚ 账；破产概率归纳证明
- 布朗运动：`Mathlib/Probability/BrownianMotion/Basic.lean`
  + `GaussianProjectiveFamily.lean`（已确认存在）
- GFF：路径图拉普拉斯格林函数 `G(i,j)=min(i,j)(n+1−max(i,j))/(n+1)`
  的精确矩阵代数（Finset/ring 全证——无需概率库）
- 前科提醒：定向导入（禁 import Mathlib 全量）、`open scoped NNReal`、
  `native_decide` 对 Rat 链式求和、警告=失败（unusedSimpArgs 等）。
