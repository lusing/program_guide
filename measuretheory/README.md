# 测度论：编程与自动证明教程

以严加安《测度论讲义》（第二版，科学出版社 2004）为纲、袁德美/
王学军《测度论基础与高等概率论》（上下册，科学出版社）为第二
底本的中文教程——两书全谱覆盖：从集类、测度扩张、积分、乘积
空间到拓扑测度、鞅、特征函数与重对数律，58 篇正文每章自包含
（只读 docs 即可学习，不需要回看原书）；每章开头给"对应严书
§x.y / 袁书 chN"定位锚。

五通道机器验证（58 篇 × 210 单元）：

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

| 章 | 标题 | 一句话 |
|---|---|---|
| [00](docs/00-intro.md) | 导言 | 测度论地图与工具链 |

### 第一篇 基础（严 §1-2 / 袁 ch1-2）

从集合运算到单调类定理——测度论的语法层：什么样的集合才"可测"，
什么样的函数才"可看"。

| 章 | 标题 | 一句话 |
|---|---|---|
| [01](docs/01-setclasses.md) | 集合运算与集类 | 半环/环/σ-代数的层级与差分解 |
| [02](docs/02-monotone-class.md) | 单调类定理 | 小类生成大类：测度唯一性的引擎 |
| [03](docs/03-measures.md) | 测度与非负集函数 | σ-可加性的三付出的代价 |
| [04](docs/04-extension.md) | 外测度与测度的扩张 | Carathéodory：从半环到 σ-代数 |
| [05](docs/05-stieltjes.md) | 欧氏空间中的 Lebesgue-Stieltjes 测度 | 单调函数 ⟹ 测度的字典 |
| [06](docs/06-approximation.md) | 测度的逼近 | 有限交集半环上的账本收敛 |
| [07](docs/07-measurable-maps.md) | 可测映射 | σ(f) 与 Borel 的生成对应 |
| [08](docs/08-functional-monotone-class.md) | 函数形式的单调类定理 | 指示函数族到有界函数的封闭 |

### 第二篇 积分（严 §3 / 袁 ch3-8）

收敛模式、积分构造与三大极限定理；符号测度、Lᵖ 空间与 Bochner
的向量值推广——分析学的账本制度。

| 章 | 标题 | 一句话 |
|---|---|---|
| [09](docs/09-convergence-modes.md) | 可测函数序列的收敛 | a.s./依测度/近一致/整体一致四模式互译 |
| [10](docs/10-integral.md) | 积分的构造与基本性质 | 从简单函数到一般函数的三段式 |
| [11](docs/11-limit-theorems.md) | 积分号下取极限 | 单调收敛 / Fatou / 控制收敛的分工 |
| [12](docs/12-signed-measures.md) | 符号测度 | Jordan-Hahn 分解与 Radon-Nikodym 定理 |
| [13](docs/13-lp-spaces.md) | Lᵖ 空间 | 完备性、不等式与对偶 |
| [14](docs/14-linfty-dual.md) | L∞ 的对偶与 ba 空间 | 有限可加荷的登场 |
| [15](docs/15-daniell.md) | Daniell 积分 | 从泛函到测度 |
| [16](docs/16-bochner-integral.md) | Bochner 积分 | 向量值的积分 |

### 第三篇 乘积空间（严 §4 / 袁 ch9-12）

联合观测的舞台：Fubini 换序执照、转移核与无穷维测度的存在驾照。

| 章 | 标题 | 一句话 |
|---|---|---|
| [17](docs/17-product-sigma.md) | 乘积可测空间 | 联合观测的舞台 |
| [18](docs/18-fubini.md) | 乘积测度与 Fubini 定理 | 重积分的换序执照 |
| [19](docs/19-kernels.md) | 转移核 | 带参数的测度 |
| [20](docs/20-infinite-products.md) | 无穷乘积测度 | 无穷次随机试验的一致模型 |
| [21](docs/21-kolmogorov-tulcea.md) | Kolmogorov 相容性定理与 Tulcea 定理 | 无穷维测度的存在驾照 |
| [22](docs/22-projective-limits.md) | 投影极限与随机 Daniell 积分 | 从局部到整体的三台机器合龙 |

### 第四篇 拓扑测度（严 §5-6 / 袁 ch11）

测度论安家拓扑：Riesz 表现、正则性、Lusin 拟合与 Polish 天堂；
弱收敛理论全套（Portmanteau/Prohorov/度量化/淡收敛）。

| 章 | 标题 | 一句话 |
|---|---|---|
| [23](docs/23-topology-borel.md) | 拓扑空间与 Borel σ-代数 | 测度论安家拓扑 |
| [24](docs/24-riesz.md) | Riesz 表现定理 | 从泛函到测量的翻译机 |
| [25](docs/25-regular-measures.md) | 正则测度与 Radon 测度 | 内外逼近的银行制度 |
| [26](docs/26-c0-dual.md) | C₀(X) 的对偶 | 连续消逝函数与符号 Radon 测度 |
| [27](docs/27-lusin.md) | Lusin 定理 | 可测函数的连续伪装 |
| [28](docs/28-product-topological.md) | 拓扑乘积上的测度 | Radon 乘积与拓扑 Fubini |
| [29](docs/29-polish.md) | Polish 空间 | 测度论的天堂地址 |
| [30](docs/30-euclidean-convergence.md) | 欧氏空间上的测度收敛 | 分布函数的赛马场 |
| [31](docs/31-weak-convergence.md) | 弱收敛 | 有界连续函数的选举制 |
| [32](docs/32-tightness-prohorov.md) | 胎紧与 Prokhorov 定理 | 弱收敛的紧性货币 |
| [33](docs/33-metrization.md) | Lévy-Prokhorov 度量 | 弱收敛的度量化 |
| [34](docs/34-vague-convergence.md) | 淡收敛 | C₀ 与 C_c 的两档检验 |

### 第五篇 概率选讲（袁 ch13/15/16）

独立性、条件期望、鞅三部曲——测度论语言下的概率论主干。

| 章 | 标题 | 一句话 |
|---|---|---|
| [35](docs/35-independence.md) | 独立性 | 乘法公理与 Borel-Cantelli、0-1 律 |
| [36](docs/36-conditional-expectation.md) | 条件期望 | 投影与信息的市场 |
| [37](docs/37-regular-conditional.md) | 正则条件概率与条件分布 | 版本的统一装配 |
| [38](docs/38-uniform-integrability.md) | 一致可积 | L¹ 收敛的通行证制度 |
| [39](docs/39-esssup.md) | 本性上确界 | 忽略零测的最大值 |
| [40](docs/40-analytic-sets.md) | 解析集 | 投影下的可测性存亡 |
| [41](docs/41-martingale-inequalities.md) | 鞅与 Doob 不等式 | 公平游戏的纪律 |
| [42](docs/42-martingale-convergence.md) | 鞅收敛定理 | 公平游戏的长期命运 |
| [43](docs/43-local-martingales.md) | 局部鞅 | 放松全局公平的工程学 |

### 第六篇 极限定理（袁 ch14/16-22）

特征函数方法、不等式引擎与大数定律三部曲、CLT 与无穷可分——
古典概率论的完全体。

| 章 | 标题 | 一句话 |
|---|---|---|
| [44](docs/44-bochner-theorem.md) | Bochner 定理 | 正定函数与特征函数的完全等价 |
| [45](docs/45-minlos-sazonov.md) | Minlos-Sazonov 定理 | 无穷维可加性的收费单 |
| [46](docs/46-minlos.md) | Minlos 定理 | 核空间上的测度论 |
| [47](docs/47-gaussian-measures.md) | Hilbert 空间上的 Gauss 测度 | 无穷维正态世界 |
| [48](docs/48-prob-inequalities.md) | 概率不等式工具箱 | 尾概率的四代引擎 |
| [49](docs/49-characteristic-functions.md) | 特征函数 | 分布的调和护照 |
| [50](docs/50-lln.md) | 大数定律 | 频率稳定性的完全谱系 |
| [51](docs/51-slln.md) | 强大数定律 | a.s. 收敛的三级数引擎 |
| [52](docs/52-clt.md) | 中心极限定理 | Lindeberg-Feller 完全体 |
| [53](docs/53-infinitely-divisible.md) | 无穷可分分布 | Lévy-Khinchin 三表示 |

### 第七篇 边疆（袁 ch23-25）

普遍极限、稳定分布与重对数律——极限定理的元问题与精确包络。

| 章 | 标题 | 一句话 |
|---|---|---|
| [54](docs/54-universal-limits.md) | 普遍极限定理 | 极限族 = 无穷可分全体 |
| [55](docs/55-stable-laws.md) | 稳定分布 | α ≤ 2 的标度不变性 |
| [56](docs/56-lll.md) | 重对数律 | √(2n log log n) 的精确包络 |

### 收官

| 章 | 标题 | 一句话 |
|---|---|---|
| [57](docs/57-cheatsheet.md) | 全书速查表 | 定理卡/锚点对照/证明十式/五通道哲学 |

## 构建与验证

```powershell
pwsh -NoProfile -Command '& ./build.ps1 -All'        # 全量对账（210 单元）
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

终态 `-All 210/210`（Lean 55 / Isabelle 14 / Julia 56 / Python 56 /
Prolog 29）。全书速查与实测坑总账见 `docs/57-cheatsheet.md`；
逐章通道分配与 85 条坑账见 `PLAN.md`（工作文档）；批次提交
历史即进度日志。
