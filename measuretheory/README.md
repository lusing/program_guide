# 测度论：编程与自动证明教程

以严加安《测度论讲义》（第二版，科学出版社 2004）为纲、袁德美/
王学军《测度论基础与高等概率论》（上下册，科学出版社）为第二
底本、胡晓予《高等概率论》（科学出版社 2009）为第三底本的中文
教程——三书全谱覆盖：从集类、测度扩张、积分、乘积空间到拓扑
测度、鞅、特征函数与重对数律，再到 Hausdorff 维数、测度微分、
随机游动、布朗运动与高斯自由场；63 篇正文每章自包含（只读 docs
即可学习，不需要回看原书）；每章开头给"对应严书 §x.y / 袁书
chN / 胡书 §x.y"定位锚。

五通道机器验证（63 篇 × 230 单元）：

- **Lean 4 + mathlib4**（主证明：single lake 工程，mathlib 4.33.1
  锚点 40+——`strong_law_ae`/`tendstoInDistribution_inv_sqrt_mul_
  sum_sub`/`AnalyticSet`/`infinitePi` 等，另含正规数定理、
  Dé Moivre-Laplace、卷积幂分解等自制全证）
- **Isabelle2025-2**（二证：HOL-Probability，14 会话——
  `central_limit_theorem`/`nn_cond_exp`/`Helly_selection` 等 locale 锚）
- **Julia / Python**（数值：精确分数账与模拟轨道——Fraction/
  Binomial 速率、LIL 包络、LePage 表示、Panjer 递推等 56×2 件）
- **Prolog**（有限模型：SWI 有理数 `=:=` 判决——分解搜索、
  三级数判决、卷积根穷举等 29 件）

## 全书目录

### 导言

| 章 | 一句话 |
|---|---|
| [00 导言](docs/00-intro.md) | 测度论地图与工具链 |

### 第一篇 基础（严 §1-2 / 袁 ch1-2）

从集合运算到单调类定理——测度论的语法层：什么样的集合才"可测"，
什么样的函数才"可看"。

| 章 | 一句话 |
|---|---|
| [01 集合运算与集类](docs/01-setclasses.md) | 半环/环/σ-代数的层级与差分解 |
| [02 单调类定理](docs/02-monotone-class.md) | 小类生成大类：测度唯一性的引擎 |
| [03 测度与非负集函数](docs/03-measures.md) | σ-可加性的三付出的代价 |
| [04 外测度与测度的扩张](docs/04-extension.md) | Carathéodory：从半环到 σ-代数 |
| [05 欧氏空间中的 Lebesgue-Stieltjes 测度](docs/05-stieltjes.md) | 单调函数 ⟹ 测度的字典 |
| [06 测度的逼近](docs/06-approximation.md) | 有限交集半环上的账本收敛 |
| [07 可测映射](docs/07-measurable-maps.md) | σ(f) 与 Borel 的生成对应 |
| [08 函数形式的单调类定理](docs/08-functional-monotone-class.md) | 指示函数族到有界函数的封闭 |

### 第二篇 积分（严 §3 / 袁 ch3-8）

收敛模式、积分构造与三大极限定理；符号测度、Lᵖ 空间与 Bochner
的向量值推广——分析学的账本制度。

| 章 | 一句话 |
|---|---|
| [09 可测函数序列的收敛](docs/09-convergence-modes.md) | a.s./依测度/近一致/整体一致四模式互译 |
| [10 积分的构造与基本性质](docs/10-integral.md) | 从简单函数到一般函数的三段式 |
| [11 积分号下取极限](docs/11-limit-theorems.md) | 单调收敛 / Fatou / 控制收敛的分工 |
| [12 符号测度](docs/12-signed-measures.md) | Jordan-Hahn 分解与 Radon-Nikodym 定理 |
| [13 Lᵖ 空间](docs/13-lp-spaces.md) | 完备性、不等式与对偶 |
| [14 L∞ 的对偶与 ba 空间](docs/14-linfty-dual.md) | 有限可加荷的登场 |
| [15 Daniell 积分](docs/15-daniell.md) | 从泛函到测度 |
| [16 Bochner 积分](docs/16-bochner-integral.md) | 向量值的积分 |

### 第三篇 乘积空间（严 §4 / 袁 ch9-12）

联合观测的舞台：Fubini 换序执照、转移核与无穷维测度的存在驾照。

| 章 | 一句话 |
|---|---|
| [17 乘积可测空间](docs/17-product-sigma.md) | 联合观测的舞台 |
| [18 乘积测度与 Fubini 定理](docs/18-fubini.md) | 重积分的换序执照 |
| [19 转移核](docs/19-kernels.md) | 带参数的测度 |
| [20 无穷乘积测度](docs/20-infinite-products.md) | 无穷次随机试验的一致模型 |
| [21 Kolmogorov 相容性定理与 Tulcea 定理](docs/21-kolmogorov-tulcea.md) | 无穷维测度的存在驾照 |
| [22 投影极限与随机 Daniell 积分](docs/22-projective-limits.md) | 从局部到整体的三台机器合龙 |

### 第四篇 拓扑测度（严 §5-6 / 袁 ch11）

测度论安家拓扑：Riesz 表现、正则性、Lusin 拟合与 Polish 天堂；
弱收敛理论全套（Portmanteau/Prohorov/度量化/淡收敛）。

| 章 | 一句话 |
|---|---|
| [23 拓扑空间与 Borel σ-代数](docs/23-topology-borel.md) | 测度论安家拓扑 |
| [24 Riesz 表现定理](docs/24-riesz.md) | 从泛函到测量的翻译机 |
| [25 正则测度与 Radon 测度](docs/25-regular-measures.md) | 内外逼近的银行制度 |
| [26 C₀(X) 的对偶](docs/26-c0-dual.md) | 连续消逝函数与符号 Radon 测度 |
| [27 Lusin 定理](docs/27-lusin.md) | 可测函数的连续伪装 |
| [28 拓扑乘积上的测度](docs/28-product-topological.md) | Radon 乘积与拓扑 Fubini |
| [29 Polish 空间](docs/29-polish.md) | 测度论的天堂地址 |
| [30 欧氏空间上的测度收敛](docs/30-euclidean-convergence.md) | 分布函数的赛马场 |
| [31 弱收敛](docs/31-weak-convergence.md) | 有界连续函数的选举制 |
| [32 胎紧与 Prokhorov 定理](docs/32-tightness-prohorov.md) | 弱收敛的紧性货币 |
| [33 Lévy-Prokhorov 度量](docs/33-metrization.md) | 弱收敛的度量化 |
| [34 淡收敛](docs/34-vague-convergence.md) | C₀ 与 C_c 的两档检验 |

### 第五篇 概率选讲（袁 ch13/15/16）

独立性、条件期望、鞅三部曲——测度论语言下的概率论主干。

| 章 | 一句话 |
|---|---|
| [35 独立性](docs/35-independence.md) | 乘法公理与 Borel-Cantelli、0-1 律 |
| [36 条件期望](docs/36-conditional-expectation.md) | 投影与信息的市场 |
| [37 正则条件概率与条件分布](docs/37-regular-conditional.md) | 版本的统一装配 |
| [38 一致可积](docs/38-uniform-integrability.md) | L¹ 收敛的通行证制度 |
| [39 本性上确界](docs/39-esssup.md) | 忽略零测的最大值 |
| [40 解析集](docs/40-analytic-sets.md) | 投影下的可测性存亡 |
| [41 鞅与 Doob 不等式](docs/41-martingale-inequalities.md) | 公平游戏的纪律 |
| [42 鞅收敛定理](docs/42-martingale-convergence.md) | 公平游戏的长期命运 |
| [43 局部鞅](docs/43-local-martingales.md) | 放松全局公平的工程学 |

### 第六篇 极限定理（袁 ch14/16-22）

特征函数方法、不等式引擎与大数定律三部曲、CLT 与无穷可分——
古典概率论的完全体。

| 章 | 一句话 |
|---|---|
| [44 Bochner 定理](docs/44-bochner-theorem.md) | 正定函数与特征函数的完全等价 |
| [45 Minlos-Sazonov 定理](docs/45-minlos-sazonov.md) | 无穷维可加性的收费单 |
| [46 Minlos 定理](docs/46-minlos.md) | 核空间上的测度论 |
| [47 Hilbert 空间上的 Gauss 测度](docs/47-gaussian-measures.md) | 无穷维正态世界 |
| [48 概率不等式工具箱](docs/48-prob-inequalities.md) | 尾概率的四代引擎 |
| [49 特征函数](docs/49-characteristic-functions.md) | 分布的调和护照 |
| [50 大数定律](docs/50-lln.md) | 频率稳定性的完全谱系 |
| [51 强大数定律](docs/51-slln.md) | a.s. 收敛的三级数引擎 |
| [52 中心极限定理](docs/52-clt.md) | Lindeberg-Feller 完全体 |
| [53 无穷可分分布](docs/53-infinitely-divisible.md) | Lévy-Khinchin 三表示 |

### 第七篇 边疆（袁 ch23-25）

普遍极限、稳定分布与重对数律——极限定理的元问题与精确包络。

| 章 | 一句话 |
|---|---|
| [54 普遍极限定理](docs/54-universal-limits.md) | 极限族 = 无穷可分全体 |
| [55 稳定分布](docs/55-stable-laws.md) | α ≤ 2 的标度不变性 |
| [56 重对数律](docs/56-lll.md) | √(2n log log n) 的精确包络 |

### 第八篇 测度的几何与实分析应用（胡书 §1.5、§2.3）

Carathéodory 流水线的两条支线：分形尺度的测度（Hausdorff/填充）
与 Radon–Nikodym 定理的实分析兑现（测度导数、变差与绝对连续）。

| 章 | 一句话 |
|---|---|
| [57 Hausdorff 测度、填充测度与分形维数](docs/57-hausdorff-packing.md) | 预测度机器、测度函数 φ、Cantor 维数与整数证书、dim_H ≤ dim_P |
| [58 测度的导数](docs/58-differentiation.md) | Lebesgue 微分定理、有界变差与绝对连续、牛顿–莱布尼茨的 Lebesgue 版 |

### 第九篇 随机过程选讲（胡书 §8）

第 21 章相容性定理的三次落地：格子上的游动、连续时间的布朗运动、
区域上的高斯自由场——一以贯之的等距构造与能量语言。

| 章 | 一句话 |
|---|---|
| [59 随机游动与马氏链](docs/59-random-walks.md) | 转移阵、首中与 Polya 常返判别、强马氏性、遍历极限与赌徒破产 |
| [60 布朗运动](docs/60-brownian-motion.md) | Fourier/K-L 构造、乘量与反射、极大不等式、首中时与连续 LIL |
| [61 高斯自由场](docs/61-gaussian-free-field.md) | Gauss–Hilbert 等距、能量内积、格林函数与狄利克雷原理、乘性混沌 |

### 收官

| 章 | 一句话 |
|---|---|
| [62 全书速查表](docs/62-cheatsheet.md) | 定理卡/锚点对照/证明十式/五通道哲学 |

## 构建与验证

```powershell
pwsh -NoProfile -Command '& ./build.ps1 -All'        # 全量对账（230 单元）
pwsh -NoProfile -Command '& ./build.ps1 -Chapter 04' # 只验一章
pwsh -NoProfile -Command '& ./build.ps1 -Lang lean'  # 只验一通道
pwsh -NoProfile -Command '& ./build.ps1 -List'       # 列出验证单元
```

通道判定与工具链版本见 `build.ps1` 头注释。Lean 依赖本地钉版
mathlib（`H:/Lang/lean4/mathlib4-4.33.1`）；Isabelle 经自带
Cygwin bash 调用。各章正文页脚登记该章全部示例文件。

## 纪律

1. 严书为扫描件（OCR 只作取材骨架）；袁书两册有文字层——
   取材直读 PDF 页面。数学公式一律按领域知识重建。
2. 无机器基础设施的专题（ba 空间、随机 Daniell 积分、Choquet
   容度、Minlos 定理、离散局部鞅、无穷可分、稳定分布、LIL）
   按"通道分工"处理：由数值/有限通道承载并在正文如实标注，
   不硬造形式化。
3. 数值实验一律钉随机种子；恒等式用精确分数判 `=:=`，渐近
   定理只断言理论量级与方向（有限 n 修正如实记录）。
4. 教程正文自包含：只读 docs 即可学会；examples 是可选验证物。

## 收官对账

终态 `-All 230/230`（Lean 60 / Isabelle 14 / Julia 61 / Python 61 /
Prolog 34）。全书速查与实测坑总账见 `docs/62-cheatsheet.md`；
逐章通道分配与 85 条坑账见 `PLAN.md`（工作文档）；批次提交
历史即进度日志。
