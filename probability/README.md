# 概率论：编程与自动证明教程（The Probability Lifesaver 为纲）

以 Steven J. Miller《The Probability Lifesaver》（Princeton UP
2017）为纲的自包含中文概率论教程——本科入门向：从计数、公理、
条件概率到分布族、极限定理、假设检验与最小二乘，无测度论前置。
全部核心内容在正文中讲清，不需要回看原书；每章开头给
"对应 Miller chN（页码）"定位锚。

五通道机器验证：

- **Lean 4 + mathlib4**（主证明：本科概率的主干锚——计数、
  分布、不等式、SLLN/CLT；`decide`/`norm_num` 的精确算术判决）
- **Isabelle2025-2**（二证：HOL-Probability 的公理与 CLT locale 锚）
- **Julia**（模拟：每个手算答案配一次百万次模拟——Miller 全书
  Numerical Test 传统的放大）
- **Python**（精确：`fractions.Fraction` 让概率账全是精确分数）
- **Prolog**（穷举：有限样本空间的完全枚举——悖论的终极溶解剂）

## 全书目录

### 导言

| 章 | 标题 | 一句话 |
|---|---|---|
| [00](docs/00-intro.md) | 导言 | 救生圈的书、五通道与学习路线 |

### 第一篇 一般理论（Miller ch1-6）

三个招牌问题建立直觉；公理三行生出全部定律；计数四连（二项
系数/扑克桥牌/Bayes/容斥/高级组合）把"概率 = 计数"练成本能。

| 章 | 标题 | 一句话 |
|---|---|---|
| [01](docs/01-signature-problems.md) | 三个招牌问题 | 生日/投篮/对冲——计数、级数与期望的预告 |
| [02](docs/02-axioms.md) | 概率公理与基本定律 | Kolmogorov 三行的免费午餐 |
| [03](docs/03-counting.md) | 计数基础 | 阶乘与二项系数 |
| [04](docs/04-cards.md) | 扑克与桥牌实验室 | 牌型概率的计数实战 |
| [05](docs/05-conditional.md) | 条件概率与 Bayes | 信息的代数 |
| [06](docs/06-inclusion-exclusion.md) | 容斥原理 | 重叠的会计学 |
| [07](docs/07-combinatorics.md) | 高级组合 | 枚举与二项恒等式 |

### 第二篇 随机变量（Miller ch7-11）

把随机性变成函数：离散与连续两大类、期望工具箱、卷积换元与
微分恒等式三大变换技术。

| 章 | 标题 | 一句话 |
|---|---|---|
| [08](docs/08-discrete-rv.md) | 离散随机变量 | pmf、CDF 与质量的语言 |
| [09](docs/09-continuous-rv.md) | 连续随机变量 | 密度与积分的语言 |
| [10](docs/10-expectation.md) | 期望工具箱 | 线性性、方差与协方差 |
| [11](docs/11-convolutions.md) | 卷积与换元 | 和的分布与变量替换 |
| [12](docs/12-differentiating.md) | 微分恒等式 | 求导数出无穷级数的机器 |

### 第三篇 分布族（Miller ch12-16）

概率论的元素周期表：离散五族与连续四大件，Γ 函数贯穿其中。

| 章 | 标题 | 一句话 |
|---|---|---|
| [13](docs/13-discrete-dists.md) | 离散分布族 | Bernoulli/二项/几何/负二项/Poisson |
| [14](docs/14-uniform-exponential.md) | 均匀与指数 | 无记忆性与最大值账 |
| [15](docs/15-normal.md) | 正态分布 | 万能极限的身世 |
| [16](docs/16-gamma.md) | Γ 函数与分布 | Γ/Beta/χ² 一家亲 |
| [17](docs/17-chi-square.md) | 卡方分布 | 样本方差的分布 |

### 第四篇 极限定理（Miller ch17-21）

大数世界的定律：不等式、Stirling、母函数、CLT 的完整证明与
Fourier 视角。

| 章 | 标题 | 一句话 |
|---|---|---|
| [18](docs/18-inequalities-lln.md) | 不等式与大数定律 | Markov/Chebyshev 与频率的收敛 |
| [19](docs/19-stirling.md) | Stirling 公式 | n! 的渐近完全体 |
| [20](docs/20-generating-functions.md) | 母函数与卷积 | 卷积的代数机器 |
| [21](docs/21-clt.md) | 中心极限定理的证明 | 截尾-收敛-拼接三幕剧 |
| [22](docs/22-fourier-clt.md) | Fourier 分析与 CLT | 特征函数的入门版 |

### 第五篇 统计与专题（Miller ch22-25 + 附录 A）

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
3. 与 `../measuretheory/` 的关系：那本是研究生向（测度论
   语言），这本是本科向（Miller 纲）；两本独立可读。

## 进度

批次进度与逐章通道分配见 `PLAN.md`（工作文档）；收官对账
将登记在 `docs/27-cheatsheet.md`。
