# 概率论与数理统计：经济系统、计算与自动证明教程

以洪永淼《概率论与统计学》的经济统计主线与 Steven J. Miller
《The Probability Lifesaver》的计算证明传统为骨架的自包含中文教程。
全书面向研究生，贯通概率模型、随机变量、渐近理论、统计推断与计量方法；
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

| 章 | 标题 | 一句话 |
|---|---|---|
| [00](docs/00-intro.md) | 导言：经济随机系统与概率统计 | 数据生成过程、描述统计与推断统计 |

### 第一篇 概率模型与有限计数

从随机试验和公理出发，经条件概率、独立性与信息更新，进入组合计数、
容斥和有限实验；每个模型都明确等可能假设与证据等级。

| 章 | 标题 | 一句话 |
|---|---|---|
| [01](docs/01-events.md) | 随机试验、事件与 σ 代数 | 样本空间、事件运算与经济随机系统 |
| [02](docs/02-axioms.md) | 概率公理与基本定律 | Kolmogorov 三公理与补律、容斥、Boole 界 |
| [03](docs/03-conditional.md) | 条件概率与 Bayes | 信息更新、全概率、医学检验与 Monty Hall |
| [04](docs/04-independence.md) | 独立性、条件独立与信息 | 两两独立、共同原因、对撞量与零相关 |
| [05](docs/05-counting.md) | 计数原理、排列与组合 | 阶乘、二项系数、多项系数与四种抽样 |
| [06](docs/06-inclusion-exclusion.md) | 容斥与组合恒等式 | 错排、占位数、Vandermonde 与曲棍球棒 |
| [07](docs/07-counting-lab.md) | 计数实验 | 生日、扑克、桥牌与秘书问题 |

### 第二篇 一元随机变量与界限

统一离散、连续与混合分布，经期望、变换和概率不等式建立一元工具箱。

| 章 | 标题 | 一句话 |
|---|---|---|
| [08](docs/08-random-variables.md) | 随机变量、分布函数与密度 | pmf、pdf、CDF 与混合型 |
| [09](docs/09-expectation.md) | 数学期望、矩、分位数与风险 | 可积性、方差、效用与组合风险 |
| [10](docs/10-transformations.md) | 一元随机变量变换 | CDF 法、Jacobian、多支反函数与逆变换 |
| [11](docs/11-inequalities.md) | 概率不等式与矩的界限 | Markov、Chebyshev、Jensen 与 Boole |
### 第三篇 分布族与独立和工具

从常见离散、连续分布到稳定分布，再用生成函数、卷积和参数求导统一处理独立和与矩。

| 章 | 标题 | 一句话 |
|---|---|---|
| [12](docs/12-discrete-dists.md) | 离散分布族 | Bernoulli、二项、几何、负二项与 Poisson |
| [13](docs/13-continuous-dists.md) | 连续分布族 | 均匀、指数、Weibull、Γ、Beta 与 Laplace |
| [14](docs/14-normal-stable.md) | 正态、对数正态、柯西与稳定分布 | 尾部、矩、稳定性与尺度 |
| [15](docs/15-generating-functions.md) | 母函数、矩生成函数与特征函数 | PGF/MGF/CF、矩与唯一性 |
| [16](docs/16-convolutions.md) | 卷积与微分恒等式 | 独立和、分组与参数求导 |

### 第四篇 多元随机变量与信息更新

从联合分布走向条件期望、协方差矩阵和多元正态，强调零相关与独立的
边界、信息更新以及线性变换下的封闭性。

| 章 | 标题 | 一句话 |
|---|---|---|
| [17](docs/17-joint-distributions.md) | 联合、边际与条件分布 | 联合 pmf/pdf、归一化、Bayes 与多项分布 |
| [18](docs/18-multivariate-transformations.md) | 多元变换与 Jacobian | 行列式、和积商变换、极坐标与次序统计量 |
| [19](docs/19-covariance.md) | 协方差、相关与独立 | Cauchy–Schwarz、半正定矩阵与投资组合 |
| [20](docs/20-conditional-expectation.md) | 条件期望与条件方差 | 塔性质、全方差、L² 投影与鞅 |
| [21](docs/21-multivariate-normal.md) | 二元与多元正态 | Schur 补、条件正态、Cholesky 与反例 |

### 第五篇 抽样分布与统计信息

从 iid 样本和统计量出发，建立正态样本的 \(\chi^2,t,F\) 抽样分布，
再用条件分布和因子分解理解数据简化、最小充分性、完备性与 Rao–Blackwell 化。

| 章 | 标题 | 一句话 |
|---|---|---|
| [22](docs/22-sampling-distributions.md) | 随机样本与抽样分布 | Helmert 正交变换、\(\chi^2,t,F\)、双样本与顺序统计量 |
| [23](docs/23-sufficiency.md) | 充分统计量与数据简化 | 因子分解、最小充分、完备性、Basu 定理与 Rao–Blackwell |

### 第六篇 随机序列与极限定理 I

从时间齐次 Markov 链进入随机序列，区分四种收敛模式，再以弱律、强律和
Monte Carlo 误差公式建立大样本平均的基本理论。

| 章 | 标题 | 一句话 |
|---|---|---|
| [24](docs/24-markov-chains.md) | 差分方程与 Markov 链 | 转移矩阵、平稳分布、首达时间、Leslie 矩阵与遍历均值 |
| [25](docs/25-convergence.md) | 随机变量序列的收敛 | \(L^p\)、几乎必然、依概率、依分布及 Borel–Cantelli 反例 |
| [26](docs/26-lln.md) | 大数定律与 Monte Carlo | Chebyshev 弱律、Khinchin/Kolmogorov 强律、Cauchy 反例 |

### 第七篇 渐近定理与工具 II

以特征函数完成有限方差 CLT，再用 Fourier 反演与 Lévy 连续性定理补齐接口；
随后建立随机阶、Slutsky、Delta 方法和 Stirling 局部近似，把分布极限转化为可用的统计计算。

| 章 | 标题 | 一句话 |
|---|---|---|
| [27](docs/27-clt.md) | 中心极限定理 | iid 有限方差的特征函数证明、连续性修正与格距 |
| [28](docs/28-fourier-clt.md) | Fourier 分析与特征函数 | 反演、唯一性、卷积、Lévy 连续性与稳定律 |
| [29](docs/29-asymptotic-tools.md) | 渐近拼接工具 | \(O_p/o_p\)、连续映射、Slutsky 与 Delta 方法 |
| [30](docs/30-stirling.md) | Stirling 公式与局部近似 | 积分夹逼、Wallis 常数、中心二项系数与有限误差 |

旧 18 的不等式与大数定律材料仍作为历史稿保留，主体已迁入新 11、25、26 章。

### 第八篇 统计模型与估计

从参数识别与风险出发，建立极大似然、得分与 Fisher 信息；随后进入矩估计、有效性和渐近推断。

| 章 | 标题 | 一句话 |
|---|---|---|
| [31](docs/31-estimation-models.md) | 参数模型、估计量与风险 | 识别、模型误设、偏差—方差分解与风险比较 |
| [32](docs/32-mle.md) | 极大似然估计 | 似然、得分、Fisher 信息、Newton 优化与不变性 |
| [33](docs/33-gmm.md) | 矩估计与广义矩方法 | 恰好/过度识别、最优权重、两步 GMM 与 J 统计量 |
| [34](docs/34-efficiency.md) | UMVU 与信息下界 | Rao–Blackwell、Lehmann–Scheffé、Cramér–Rao 与等号条件 |
| [35](docs/35-asymptotic-estimation.md) | 一致性与渐近方差 | MLE/GMM 展开、伪真参数、sandwich 与稳健标准误 |

### 统计与专题历史稿（后续按 33–43 重排）

| 章 | 标题 | 一句话 |
|---|---|---|
| [23](docs/23-hypothesis-testing.md) | 假设检验 | 显著性的逻辑 |
| [24](docs/24-markov-least-squares.md) | Markov 与最小二乘 | 差分方程与拟合 |
| [25](docs/25-famous-problems.md) | 两个著名问题与编码 | 全书工具的合龙演练 |
| [26](docs/26-proof-techniques.md) | 证明十一式 | 概率实例中的证明技术 |

### 收官

| 章 | 标题 | 一句话 |
|---|---|---|
| [27](docs/27-cheatsheet.md) | 全书速查表 | 定理卡/锚点对照/坑总账 |

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

批次进度与逐章通道分配见 `PLAN.md`（工作文档）；收官对账
将登记在 `docs/27-cheatsheet.md`。
