# 偏微分方程：Evans 理论全景与机器验证教程

以 Lawrence C. Evans《Partial Differential Equations》第 2 版
（AMS Graduate Studies in Mathematics 19，高教社影印，775 页扫描
件 rapidocr 取材）为纲的中文教程——全书核心自包含：只读 docs 即
可学习，不需要回看原书；每章开头给"对应书 §x.y"定位锚。

与姊妹篇《偏微分方程数值解法》（pdenum，陆金甫/关治）互补：那本
讲"怎么算"，这本讲"解是什么、何时存在、多光滑"。

四通道机器验证：

- **Lean 4 + mathlib4**（主证明：单 lake 工程，mathlib 4.33.1 钉版
  路径依赖——叠加原理、调和性、平均值公式、镜像法恒等式、配方法
  Dirichlet 原理、离散分部积分、RH 条件、Legendre 配方等代数核）
- **Julia**（数值对表：制造解残差、谱方法、Godunov/粘性消失、
  Hopf-Lax/Lax-Oleinik、有限元、磨光、优化——每章主力）
- **Python（scipy）**（交叉通道：与 Julia 双实现互审）
- **Prolog / Fortran**（规则库与经典内核：方程分类、适定性、方法
  选择树；热核卷积、波能量、Poisson 球核）

## 全书目录

### 第一篇 预备（书第 1 章）

| 章 | 标题 | 一句话 |
|---|---|---|
| [00](docs/00-intro.md) | 导言 | 方程动物园、制造解对表、叠加原理完整机器证明 |
| [01](docs/01-wellposed.md) | 适定性与 Hadamard 反例 | 三判据、逆热放大、sin·sinh 边值趋零解爆炸 |

### 第二篇 四大线性方程（书第 2 章）

| 章 | 标题 | 一句话 |
|---|---|---|
| [02](docs/02-transport.md) | 传输方程 | 特征线、弱解首现、Duhamel |
| [03](docs/03-laplace-fundamental.md) | Laplace I | 基本解、平均值公式（Lean 完整证明） |
| [04](docs/04-laplace-green.md) | Laplace II | 调和性质、镜像法恒等式（Lean）、Poisson 核 |
| [05](docs/05-laplace-energy.md) | Laplace III | 能量方法、Dirichlet 原理（配方法 Lean） |
| [06](docs/06-heat-fundamental.md) | 热 I | 热核、阶梯磨光、无穷传播、Duhamel |
| [07](docs/07-heat-properties.md) | 热 II | 半群律、正性、能量恒等式（Lean 单模式） |
| [08](docs/08-heat-energy.md) | 热 III | 能量单调、衰减率 2λ₁、长时第一模式 |
| [09](docs/09-wave-kirchhoff.md) | 波 I | d'Alembert（Lean 行波）、Kirchhoff、Huygens 对照 |
| [10](docs/10-wave-duhamel.md) | 波 II | Duhamel、有限传播 vs 无穷传播对表 |

### 第三篇 非线性一阶（书第 3 章）

| 章 | 标题 | 一句话 |
|---|---|---|
| [11](docs/11-complete-integrals.md) | 完全积分与包络 | Legendre 几何、梯度爆破 t* |
| [12](docs/12-characteristics.md) | 特征线 | 特征 ODE、拟线性/HJ 数值解 |
| [13](docs/13-hopf-lax.md) | HJ I | Legendre 配方（Lean）、Hopf-Lax = 特征线解 |
| [14](docs/14-hj-weak.md) | HJ II | 粘性消失收敛 Hopf-Lax、半凹性 |
| [15](docs/15-shocks-entropy.md) | 守恒律 | RH（Lean）、熵条件、Godunov、弱形式环量 |
| [16](docs/16-lax-oleinik.md) | 守恒律 II | Lax-Oleinik（势的坑账）、Riemann、N 波 |

### 第四篇 解的表示（书第 4 章）

| 章 | 标题 | 一句话 |
|---|---|---|
| [17](docs/17-separation-turing.md) | 分离变量与 Turing | 谱、Bessel、Schnakenberg 失稳 |
| [18](docs/18-waves-solitons.md) | 行波、孤子、相似解 | KdV 双孤子（Hirota 三坑）、Barenblatt |
| [19](docs/19-fourier.md) | Fourier 变换法 | Gauss 自对偶、反演、波/热模式对照 |
| [20](docs/20-radon-laplace.md) | Radon 与 Laplace | 切片定理逐位、erfc 解 |
| [21](docs/21-cole-hopf.md) | Cole-Hopf 等 | 非线性⟺线性桥、粘性激波→熵激波 |
| [22](docs/22-asymptotics.md) | 渐近方法 | 边界层、Laplace/驻相、均匀化调和平均 |
| [23](docs/23-power-series.md) | 幂级数与 CK | 收敛域 = 奇异特征距离、非特征条件 |

### 第五篇 Sobolev 空间（书第 5 章）

| 章 | 标题 | 一句话 |
|---|---|---|
| [24](docs/24-sobolev-basics.md) | 弱导数 | 分部积分定义、离散分部（Lean） |
| [25](docs/25-approximation.md) | 逼近、延拓、迹 | 磨光收敛、偶延拓、迹的边界层家族 |
| [26](docs/26-sobolev-inequalities.md) | Sobolev 不等式 | GNS/Morrey、临界 loglog 反例 |
| [27](docs/27-compactness.md) | 紧性、Poincaré | Rellich 签名、差商判据、Hardy |
| [28](docs/28-dual-spaces.md) | H^{-1} 与时空 | δ 进负空间、Bochner 框架 |

### 第六篇 二阶椭圆（书第 6 章）

| 章 | 标题 | 一句话 |
|---|---|---|
| [29](docs/29-lax-milgram.md) | 弱解与 Lax-Milgram | 有限元、Galerkin 正交、自由度坑账 |
| [30](docs/30-energy-fredholm.md) | 能量估计与 Fredholm | 谱常数、二择一两面、病态=近谱 |
| [31](docs/31-regularity.md) | 正则性 | 差商方法、L 形域角奇性 r^{2/3} |
| [32](docs/32-maximum-principle.md) | 极值原理与 Harnack | 弱/强/Hopf、Harnack 常数 |
| [33](docs/33-eigenvalues.md) | 特征值 | Rayleigh-Ritz、非对称主特征值、Weyl |

### 第七篇 线性发展方程（书第 7 章）

| 章 | 标题 | 一句话 |
|---|---|---|
| [34](docs/34-parabolic-weak.md) | 抛物弱解 | Galerkin、模式 ODE、衰减估计 |
| [35](docs/35-parabolic-properties.md) | 抛物性质 | 解析半群、正性、唯一性 |
| [36](docs/36-hyperbolic-weak.md) | 双曲弱解 | 振子 Galerkin、能量守恒、正则性门槛 |
| [37](docs/37-hyperbolic-systems.md) | 传播与双曲组 | 特征不变量、对称双曲等距 |
| [38](docs/38-semigroups.md) | 半群理论 | Hille-Yosida、三大半群对照 |

### 第八篇 非线性理论（书第 8-9 章）

| 章 | 标题 | 一句话 |
|---|---|---|
| [39](docs/39-euler-lagrange.md) | Euler-Lagrange | 牛顿解、一阶/二阶变分数值 |
| [40](docs/40-direct-method.md) | 直接方法 | 强制+凸、双阱多极小 |
| [41](docs/41-constraints.md) | 正则性与约束 | p-拉普拉斯、非线性特征值、障碍 |
| [42](docs/42-mountain-pass.md) | 山路与 Noether | min-max 地形、守恒律 |
| [43](docs/43-fixed-points.md) | 单调性与不动点 | Banach/Schauder/单调三类收敛签名 |
| [44](docs/44-subsupersolutions.md) | 上下解、非存在、梯度流 | 夹逼迭代、blow-up、Pohozaev |

### 第九篇 前沿（书第 10-12 章）

| 章 | 标题 | 一句话 |
|---|---|---|
| [45](docs/45-viscosity.md) | 粘性解 | 子微分判据、一致性、比较原理 |
| [46](docs/46-control-hjb.md) | 控制与 HJB | 动态规划、Riccati、Hopf-Lax 控制出身 |
| [47](docs/47-riemann-problem.md) | 守恒律组 | p-系统、Riemann 不变量、RH 相容性 |
| [48](docs/48-entropy-systems.md) | 熵准则 | 熵对、消失粘性、熵耗散 |
| [49](docs/49-nonlinear-wave.md) | 非线性波 I | 能量守恒、负能量爆破 |
| [50](docs/50-critical-power.md) | 非线性波 II | 符号条件、临界指标、散射 |
| [51](docs/51-summary.md) | 总结 | 三部分地图、方法选择树（Prolog）、坑账精粹 |

## 构建与验证

    pwsh -NoProfile -Command '& ./build.ps1 -All'        # 全量验证
    pwsh -NoProfile -Command '& ./build.ps1 -Chapter 03' # 单章
    pwsh -NoProfile -Command '& ./build.ps1 -Lang lean'  # 单通道

**收官：76 单元全绿**（lean 12 / julia 51 / python 3 / prolog 7 / fortran 3——lean 含 00-07/09/13/15/24 共 12 章），十批提交（B0 预备、B1a/B1b 四大方程、B2 非线性一阶、
B3 解的表示、B4 Sobolev、B5 椭圆、B6 发展、B7 非线性、B8 前沿
+ B9 总结），覆盖 Evans 第二版 ch1-ch12 全部核心内容。

