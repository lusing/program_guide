# 概率论与数理统计：经济系统、计算与自动证明教程

以洪永淼《概率论与统计学》的经济统计主线与 Steven J. Miller
《The Probability Lifesaver》的计算证明传统为骨架的自包含中文教程。
全书面向研究生，共 44 章：概率模型、渐近推断、GMM 与经典回归，
核心定义、定理条件、推导和代码均在正文中讲清，不需要回看原书。

五通道机器验证：

- **Lean 4 + mathlib4**（主证明：本科概率的主干锚——计数、
  分布、不等式、SLLN/CLT；`decide`/`norm_num` 的精确算术判决）
- **Isabelle2025-2**（二证：HOL-Probability 的公理与 CLT locale 锚）
- **Julia**（数值实验：确定性数值审计与固定种子随机模拟；模拟不冒充证明）
- **Python**（精确：`fractions.Fraction` 让概率账全是精确分数）
- **Prolog**（穷举：有限样本空间的完全枚举——悖论的终极溶解剂）

## 全书目录

### 导言

| 章 | 一句话 |
|---|---|
| [00 导言：经济随机系统与概率统计](docs/00-intro.md) | 数据生成过程、描述统计与推断统计 |

### 第一篇 概率模型与有限计数

从随机试验和公理出发，经条件概率、独立性与信息更新，进入组合计数、
容斥和有限实验；每个模型都明确等可能假设与证据等级。

| 章 | 一句话 |
|---|---|
| [01 随机试验、事件与 σ 代数](docs/01-events.md) | 样本空间、事件运算与经济随机系统 |
| [02 概率公理与基本定律](docs/02-axioms.md) | Kolmogorov 三公理与补律、容斥、Boole 界 |
| [03 条件概率与 Bayes](docs/03-conditional.md) | 信息更新、全概率、医学检验与 Monty Hall |
| [04 独立性、条件独立与信息](docs/04-independence.md) | 两两独立、共同原因、对撞量与零相关 |
| [05 计数原理、排列与组合](docs/05-counting.md) | 阶乘、二项系数、多项系数与四种抽样 |
| [06 容斥与组合恒等式](docs/06-inclusion-exclusion.md) | 错排、占位数、Vandermonde 与曲棍球棒 |
| [07 计数实验](docs/07-counting-lab.md) | 生日、扑克、桥牌与秘书问题 |

### 第二篇 一元随机变量与界限

统一离散、连续与混合分布，经期望、变换和概率不等式建立一元工具箱。

| 章 | 一句话 |
|---|---|
| [08 随机变量、分布函数与密度](docs/08-random-variables.md) | pmf、pdf、CDF 与混合型 |
| [09 数学期望、矩、分位数与风险](docs/09-expectation.md) | 可积性、方差、效用与组合风险 |
| [10 一元随机变量变换](docs/10-transformations.md) | CDF 法、Jacobian、多支反函数与逆变换 |
| [11 概率不等式与矩的界限](docs/11-inequalities.md) | Markov、Chebyshev、Jensen 与 Boole |
### 第三篇 分布族与独立和工具

从常见离散、连续分布到稳定分布，再用生成函数、卷积和参数求导统一处理独立和与矩。

| 章 | 一句话 |
|---|---|
| [12 离散分布族](docs/12-discrete-dists.md) | Bernoulli、二项、几何、负二项与 Poisson |
| [13 连续分布族](docs/13-continuous-dists.md) | 均匀、指数、Weibull、Γ、Beta 与 Laplace |
| [14 正态、对数正态、柯西与稳定分布](docs/14-normal-stable.md) | 尾部、矩、稳定性与尺度 |
| [15 母函数、矩生成函数与特征函数](docs/15-generating-functions.md) | PGF/MGF/CF、矩与唯一性 |
| [16 卷积与微分恒等式](docs/16-convolutions.md) | 独立和、分组与参数求导 |

### 第四篇 多元随机变量与信息更新

从联合分布走向条件期望、协方差矩阵和多元正态，强调零相关与独立的
边界、信息更新以及线性变换下的封闭性。

| 章 | 一句话 |
|---|---|
| [17 联合、边际与条件分布](docs/17-joint-distributions.md) | 联合 pmf/pdf、归一化、Bayes 与多项分布 |
| [18 多元变换与 Jacobian](docs/18-multivariate-transformations.md) | 行列式、和积商变换、极坐标与次序统计量 |
| [19 协方差、相关与独立](docs/19-covariance.md) | Cauchy–Schwarz、半正定矩阵与投资组合 |
| [20 条件期望与条件方差](docs/20-conditional-expectation.md) | 塔性质、全方差、L² 投影与鞅 |
| [21 二元与多元正态](docs/21-multivariate-normal.md) | Schur 补、条件正态、Cholesky 与反例 |

### 第五篇 抽样分布与统计信息

从 iid 样本和统计量出发，建立正态样本的 $\chi^2,t,F$ 抽样分布，
再用条件分布和因子分解理解数据简化、最小充分性、完备性与 Rao–Blackwell 化。

| 章 | 一句话 |
|---|---|
| [22 随机样本与抽样分布](docs/22-sampling-distributions.md) | Helmert 正交变换、$\chi^2,t,F$ 、双样本与顺序统计量 |
| [23 充分统计量与数据简化](docs/23-sufficiency.md) | 因子分解、最小充分、完备性、Basu 定理与 Rao–Blackwell |

### 第六篇 随机序列与极限定理 I

从时间齐次 Markov 链进入随机序列，区分四种收敛模式，再以弱律、强律和
Monte Carlo 误差公式建立大样本平均的基本理论。

| 章 | 一句话 |
|---|---|
| [24 差分方程与 Markov 链](docs/24-markov-chains.md) | 转移矩阵、平稳分布、首达时间、Leslie 矩阵与遍历均值 |
| [25 随机变量序列的收敛](docs/25-convergence.md) | $L^p$ 、几乎必然、依概率、依分布及 Borel–Cantelli 反例 |
| [26 大数定律与 Monte Carlo](docs/26-lln.md) | Chebyshev 弱律、Khinchin/Kolmogorov 强律、Cauchy 反例 |

### 第七篇 渐近定理与工具 II

以特征函数完成有限方差 CLT，再用 Fourier 反演与 Lévy 连续性定理补齐接口；
随后建立随机阶、Slutsky、Delta 方法和 Stirling 局部近似，把分布极限转化为可用的统计计算。

| 章 | 一句话 |
|---|---|
| [27 中心极限定理](docs/27-clt.md) | iid 有限方差的特征函数证明、连续性修正与格距 |
| [28 Fourier 分析与特征函数](docs/28-fourier-clt.md) | 反演、唯一性、卷积、Lévy 连续性与稳定律 |
| [29 渐近拼接工具](docs/29-asymptotic-tools.md) | $O_p/o_p$ 、连续映射、Slutsky 与 Delta 方法 |
| [30 Stirling 公式与局部近似](docs/30-stirling.md) | 积分夹逼、Wallis 常数、中心二项系数与有限误差 |

### 第八篇 统计模型与估计

从参数识别与风险出发，建立极大似然、得分与 Fisher 信息；随后进入矩估计、有效性和渐近推断。

| 章 | 一句话 |
|---|---|
| [31 参数模型、估计量与风险](docs/31-estimation-models.md) | 识别、模型误设、偏差—方差分解与风险比较 |
| [32 极大似然估计](docs/32-mle.md) | 似然、得分、Fisher 信息、Newton 优化与不变性 |
| [33 矩估计与广义矩方法](docs/33-gmm.md) | 恰好/过度识别、最优权重、两步 GMM 与 J 统计量 |
| [34 UMVU 与信息下界](docs/34-efficiency.md) | Rao–Blackwell、Lehmann–Scheffé、Cramér–Rao 与等号条件 |
| [35 一致性与渐近方差](docs/35-asymptotic-estimation.md) | MLE/GMM 展开、伪真参数、sandwich 与稳健标准误 |

### 第九篇 假设检验与置信推断

从两类错误和 Neyman–Pearson 最优性出发，建立 Wald、LM、LR
三大渐近检验，并以检验—置信集对偶统一 p 值、功效与区间解释。

| 章 | 一句话 |
|---|---|
| [36 假设检验与 Neyman–Pearson 理论](docs/36-hypothesis-testing.md) | 两类错误、size/power、UMP、p 值与经典 z/t/χ² 检验 |
| [37 Wald、LM、LR 检验与置信区间](docs/37-asymptotic-tests.md) | 渐近卡方、局部功效、检验—区间对偶与多重比较 |

### 第十篇 线性回归模型

从投影几何与正规方程建立 OLS，经平方和分解、拟合优度与模型选择，
到无偏性、协方差公式、Gauss–Markov、正态精确推断与广义最小二乘。

| 章 | 一句话 |
|---|---|
| [38 经典线性回归与普通最小二乘](docs/38-ols.md) | 假设分层、投影/正规方程、P 与 M、误差度量对质 |
| [39 拟合优度、模型选择与 Gauss–Markov](docs/39-ols-properties.md) | TSS/ESS/RSS、调整 R²、无偏性、s² 迹账与 BLUE |
| [40 OLS 抽样分布、t 检验与 F 检验](docs/40-ols-inference.md) | 正态精确推断、单约束 F=t²、联合显著 vs 单个不显著 |
| [41 误设、受约束回归与 GLS](docs/41-gls.md) | 受约束闭式、遗漏偏误、方差膨胀与 Aitken |

### 第十一篇 收官综合

一条公开 DGP 的合成劳动力市场贯通估计、检验与回归工具链；
证明方法六族收束全书方法。

| 章 | 一句话 |
|---|---|
| [42 综合案例与概率证明方法](docs/42-synthesis.md) | 合成数据全程：OLS/MLE/IV/WLS + 证明方法地图与名题 |

### 第十二篇 高等概率论专题（胡晓予）

异质和极限定理的充要边界：什么时候"大样本自动正态"是真的。

| 章 | 一句话 |
|---|---|
| [43 Lindeberg 条件：CLT 的充要边界](docs/43-lindeberg.md) | 民主条款、u.a.n./Feller、Lindeberg–Feller 定理与三族机器账 |
| [44 无穷可分分布：任意切分的分布族](docs/44-infinitely-divisible.md) | Lévy–Khintchine 三元组、稳定律、小数律与不可分判决 |
| [45 级数收敛与三级数定理](docs/45-three-series.md) | Kolmogorov 不等式、方差账证书、三级数、Kronecker 与 Feller 弱律 |

### 收官速查

| 章 | 一句话 |
|---|---|
| [49 全书速查与定理地图](docs/49-cheatsheet.md) | 假设→定理→结论→误用总表、公式速查、坑账与验证状态 |

## 构建与验证

```powershell
pwsh -NoProfile -Command '& ./build.ps1 -All'        # 全量对账
pwsh -NoProfile -Command '& ./build.ps1 -Chapter 02' # 只验一章
pwsh -NoProfile -Command '& ./build.ps1 -Lang lean'  # 只验一通道
pwsh -NoProfile -Command '& ./build.ps1 -List'       # 列出验证单元
```

通道判定与工具链版本见 `build.ps1` 头注释。Lean 依赖本地钉版
mathlib（`H:/Lang/lean4/mathlib4-4.33.1`）；Isabelle 经自带
Cygwin bash 调用。

## 纪律

1. 原书有文字层——取材直接读 PDF 页面（免 OCR）；数学内容
   全部自包含重建，不让读者回看原书。
2. 教程正文 ≥200 行/章、讲解为主、所有代码在正文引用；
   数值实验钉随机种子；恒等式用精确分数判 `=:=`。
3. 与 `../measuretheory/` 的关系：那本系统展开测度论基础，
   这本以经济统计与计算证明为纲；两本独立可读。

## 进度

全书 44 章（00–43）已按洪永淼主线融合完成；批次过程与逐章
通道分配见 `PLAN.md`，收官对账与验证状态登记在
`docs/49-cheatsheet.md`。
