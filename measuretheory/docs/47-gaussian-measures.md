# 47 Hilbert 空间上的 Gauss 测度：无穷维正态世界

**对应严书 §9.4-9.5（pp. 209-215 / PDF p289-297）。
mathlib `Probability/Distributions/Gaussian/Real.lean`（gaussianReal）+
BrownianMotion 文件族 ✓。**

---

## 47.1 定义与第一性质

**Gauss 测度（柱面定义，严书 9.4）**：H 可分 Hilbert 上
Borel 概率 μ 使每个连续线性泛函 ⟨·, h⟩ 的像是一维正态
（或退化）——**一切一维投影正态 ⟹ 一切有限维投影联合
正态**（第 16 章多元正态的无穷维延伸）。等价刻画：

- **特征泛函**：φ_μ(h) = exp(i⟨m, h⟩ − ⟨Ah, h⟩/2)，其中
  m ∈ H（均值）、A 为正对称**迹类算子**（协方差，Sazonov
  收费的必然：Tr A < ∞）；
- **矩刻画**：E⟨X, h⟩ = ⟨m, h⟩、Cov(⟨X,h⟩,⟨X,k⟩) =
  ⟨Ah, k⟩。

**第一性质**：Gauss 测度由 (m, A) 完全决定（特征泛函唯一
性）；线性变换保持 Gauss（A' = TAT* 的迹类传递）；**独立
⟺ 不相关**（联合 Gauss 的红利在无穷维保持）。

## 47.1.4b 定义的三种等价形态（判据速查）

Gauss 测度在无穷维的三种定义路线（互相等价，各有所长）：

| 形态 | 陈述 | 长处 |
|---|---|---|
| 一维投影 | 一切 ⟨·,h⟩ 一维正态（含退化） | 概率直觉最直 |
| 有限维联合 | 一切有限维投影联合正态 | 验证可局部化 |
| 特征泛函 | φ = exp(i⟨m,·⟩ − ⟨A·,·⟩/2)，A 迹类 | 调和分析最强 |

**迹类强制**：第三形态的 A 迹类不是可选项——Sazonov
（45 章）的直接推论（特征泛函必须 *-连续 ⟹ 协方差
迹收敛）。**独立的充要**（联合 Gauss 红利）：X, Y 联合
Gauss ⟹ 独立 ⟺ Cov(X,Y) = 0——第 35 章"不相关 ≠ 独立"
的例外区正是 Gauss 世界（第 16 章袁书四元组封闭性的
无穷维延续：线性变换/独立和/弱极限/条件分布全保 Gauss）。

## 47.1.5 有限维影子与一维对拍（数值的锚）

无穷维 Gauss 的一切性质在有限维截断上有精确影子（数值
通道的合法性来源）：

1. **坐标分布**：zₙ ~ N(0,1) i.i.d.，X = Σ√λₙzₙeₙ——
   第 k 坐标 X_k = √λₖzₖ ~ N(0, λₖ)（一维正态的精确
   对拍，44 章 charFun_gaussianReal 的数值版）；
2. **能量收敛**：‖X‖² = Σλₙzₙ²——部分和收敛 a.s. 于
   Σλₙ < ∞（第 50 章 SLLN 的级数版：E‖X‖² = Tr A <
   ∞ + 单调收敛）；
3. **Cameron-Martin 范数**：h ∈ H_A ⟺ ‖h‖_A² :=
   Σhₙ²/λₙ < ∞——比 ‖h‖² = Σhₙ² 更严的门槛（λₙ → 0
   使分母惩罚高坐标）——**CM 空间的"会员费"**。

第 3 条的数值显影：h = e₁（第一坐标单位向量）时
‖h‖_A² = 1/λ₁（有限 ✓——e₁ 是 CM 会员）；h = Σeₙ/n
时 ‖h‖² = Σ1/n² < ∞ 但 ‖h‖_A² = Σ1/(n²λₙ)（λₙ = e^{-n}
时爆炸）——**H 的成员未必是 CM 会员**：两空间的差距
正是平移绝对连续性的分界（47.3 主定理的定量内容）。

**历史注记**：Cameron-Martin（1944，芝加哥）在积分方程
背景发现平移公式；其"拟不变性"的深远意义由 Gel'fand-
Vilenkin 与 Segal（1950-60s）发掘。Fernique（1970）的
指数平方可积是无穷维 Gauss 分析的"工程许可证"。Borell
等周（1975）与 Sudakov-Tsirelson 的同步发现开启 Gauss
集中时代——现代高维统计（Vershynin 教材的传统）从这里
出发。本章四定理（支撑/CM/Fernique/等集中）构成"Gauss
四柱"，支撑第 52 章（CLT 的函数 delta 方法）与后现代
高维概率的全部上层建筑。

## 47.2 结构定理与支撑

**谱定理（结构完全体）**：A 迹类正对称 ⟹ A = Σλₙ⟨·, eₙ⟩eₙ（λₙ ≥ 0、
Σλₙ < ∞）。**支撑定理**：μ 的支撑 = m + **A^{1/2}H 的闭包**
——Gauss 测度住在**真子空间**（除非 A 有界逆，但迹类
恒等不可能在无穷维）：

  **支撑 = m + H_A（Cameron-Martin 空间）**，且
  H_A ⊆ H **紧嵌入**（迹类 ⟹ 嵌入算子 Hilbert-Schmidt
  ⟹ 紧）——μ(H_A) = 0（支撑比空间本身薄一层："Gauss
  测度把质量放在比 H 更瘦的 CM 空间的紧集上"）。

## 47.3 Cameron-Martin 定理：平移的绝对连续性

**Cameron-Martin 定理（严书 9.4.x）**：μ = N(0, A) 的
Gauss 测度、h ∈ H。则

- **h ∈ H_A（CM 空间）**：μ_h := μ(· + h) ≪ μ，Radon-
  Nikodym 导数 **dμ_h/dμ = exp(⟨A^{-1/2}h, ·⟩_H −
  ‖A^{-1/2}h‖²/2)**（指数倾斜——一维正态平移公式的无穷
  维移植，RN 定理的荣耀应用）；
- **h ∉ H_A**：μ_h ⊥ μ（**奇异**！平移超出 CM 空间时新
  旧测度互斥）。

**读法**：无穷维 Gauss 世界里，"可平移"的方向只有 CM
空间——**H 的大多数方向平移都会毁掉绝对连续性**。这是
无穷维与有限维的分水岭（ℝⁿ 上一切平移等价）。应用：
Cameron-Martin 公式是** Malliavin calculus（随机变分学）**
与 Gauss 测度上的分析（Feynman 积分、无穷维 Oxford 计算）
的基石。

## 47.4 Fernique 定理与二阶结构

**Fernique 定理（严书 9.4 邻域）**：μ Gauss（Radon）⟹
∃α > 0 使 E[e^{α‖X‖²}] < ∞——**指数平方可积**。推论：
一切多项矩有限、Gauss 测度 UI（38 章）、矩确定分布。
证明思想：独立对称化 X−Y 的尾不等式 + 尺度迭代（数学侧
由 docs 骨架 + 数值验证）。

**无穷维无 Lebesgue（Bochner-Sazonov 定理，45 章反例的
正式化）**：若 H 上有平移不变 σ-有限 Borel 测度 λ，单位球
的账在紧性下崩溃（无穷维单位球可被无穷多个不交的等半径
球覆盖）——**Gauss 测度是无穷维的"Lebesgue 替身"**（非
平移不变但 CM-平移拟不变）。

## 47.4.5 Fernique 与等周（两条深水定理的导览）

**Fernique 定理的证明思想**（数学骨架，数值验证尾矩）：
对称化 X − Y 的 Gauss 性 + 尺度不等式

  P(‖X − Y‖ > 2t) ≥ (1/2)·P(‖X‖ > t + s)·P(‖Y‖ > t − s)

迭代压缩尾概率的指数平方衰减——E[e^{α‖X‖²}] < ∞（某
α > 0）。数值通道验证：截断 Gauss 的 e^{α‖X‖²} 采样均值
在 α < α₀ 时稳定（α₀ = 迹的倒数型阈值）。

**等周不等式（Borell，导览）**：Gauss 测度的"半空间最优"
——μ(A_ε) ≥ Φ(Φ⁻¹(μ(A)) + ε)（A 的 ε-膨胀的下界由半
空间达成）。推论：**Gauss 集中的铁路**——无穷维 Gauss
的 Lipschitz 函数集中在一维（E exp(λ|f − Ef|) ≤ e^{λ²/2}）
——**维数灾难的 Gauss 免疫**（高维统计（第 52 章 Delta
方法的深水）与机器学习理论的数学根基）。等周的机器件
（Borell 型）在 mathlib 尚无——docs 导览 + 数值半空间
对拍。

## 47.5 数值实验（白噪声的能源账补遗）

**Julia（`47_gaussian_measures.jl`）**：① 标准无穷维 Gauss 的
截断实现（λₙ = 1/n² 的坐标采样 zₙ·√λₙ——‖X‖² = Σλₙzₙ²
的收敛与 Fernique 型尾）；② CM 平移的 RN 密度数值
（h = √λ₁e₁ vs h = e₁（∉ CM 空间，导数发散的显影））；
③ 有限维对拍（n = 20 的 Gauss 与一维投影正态性的
Kolmogorov-Smirnov）；④ Brown 运动的实现（白噪声积分的
数值路径）。

**Python（`47_gaussian_measures.py`）**：Fraction 精确的
λₙ 部分和收敛账（π²/6 型）；CM 范数 ‖A^{-1/2}h‖² =
Σhₙ²/λₙ 的发散对照（h = e₁ 时 = ∞）。

## 47.5.5 实验断言清单

1. **坐标账**：X_k ~ N(0,λₖ) 的 KS 对拍（λₖ = 1/k² 的
   三档坐标）；
2. **能量收敛**：‖Xₙ‖² = Σ_{k≤n}λₖzₖ² → 稳定值（Tr A
   附近；1000 次采样的均值与方差账）；
5. **CM 门槛**：h = e₁ 的 ‖h‖_A² 有限 vs h = Σeₙ/n 的
   发散（Fraction 精确 + 数值双账）；
3. **平移密度**：h ∈ CM 时 dμ_h/dμ 的显式公式在采样均值
   下的验证（1 的期望 = 1 的归一账）；
4. **Fernique**：E[e^{α‖X‖²}] 在 α < 阈值时有限（采样
   平均稳定 vs α > 阈值时爆炸）；
6. **Brown**：白噪声积分的增量独立 + 方差正比账。

## 47.6 Lean：gaussianReal 与 BrownianMotion

`Ch47GaussianMeasures.lean`：`#check` gaussianReal/
charFun_gaussianReal（一维正态的调和刻画——机器版）+
`Measure.ext_of_charFun`（指纹定理）+ BrownianMotion 文件
族的锚点正名（Brownian 构造 = 本章理论的最大应用，mathlib
已形式化——与第 43 章轨道装修预告的合龙）。

## 47.6.5 习题账单

1. 验证三种定义形态的等价（一维 → 有限维的 Cramér-Wold；
   有限维 → 特征泛函的多维正态公式）；
2. 支撑定理：H_A 的闭包 = supp μ 的证明（外测度 + 紧
   集中）；
3. Cameron-Martin 公式的完整计算（一维情形手算 + 无穷
   维的 RN 论证）；
4. Fernique 的尾矩验证：E‖X‖² = Tr A、E‖X‖⁴ 的显式
  （Gauss 积分表）；
5. 等集中的半空间最优性：一维情形的 Φ(Φ⁻¹(p)+ε) 手算
   对照（数值实验的理论锚）。

## 47.7 要点回顾

1. Gauss = (m, A) 迹类；支撑 = m + H_A（CM 空间，紧嵌入）
   且 μ(H_A) = 0——测度比空间薄。
2. Cameron-Martin：CM 内平移 ≪ μ（显式 RN 密度），CM 外
   平移 ⊥ μ——无穷维分水岭；Malliavin 的基石。
3. Fernique：指数平方可积——矩齐全、UI 免费。
4. 无穷维无 Lebesgue；Gauss 测度是替身（CM-拟不变）。
5. 机器侧：gaussianReal + charFun + BrownianMotion 锚点；
   数值通道谱截断与 CM 发散对照。

*对应示例：`examples/lean/Measuretheory/Ch47GaussianMeasures.lean`、
`examples/julia/47_gaussian_measures.jl`、
`examples/python/47_gaussian_measures.py`。*

---

上一章：[46 Minlos 定理：核空间上的测度论](46-minlos.md) · 下一章：[48 概率不等式工具箱：尾概率的四代引擎](48-prob-inequalities.md)
