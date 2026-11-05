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

| 章 | 一句话 |
|---|---|
| [00 导言](docs/00-intro.md) | 方程动物园、制造解对表、叠加原理完整机器证明 |
| [01 适定性与 Hadamard 反例](docs/01-wellposed.md) | 三判据、逆热放大、sin·sinh 边值趋零解爆炸 |

### 第二篇 四大线性方程（书第 2 章）

| 章 | 一句话 |
|---|---|
| [02 传输方程](docs/02-transport.md) | 特征线、弱解首现、Duhamel |
| [03 Laplace I](docs/03-laplace-fundamental.md) | 基本解、平均值公式（Lean 完整证明） |
| [04 Laplace II](docs/04-laplace-green.md) | 调和性质、镜像法恒等式（Lean）、Poisson 核 |
| [05 Laplace III](docs/05-laplace-energy.md) | 能量方法、Dirichlet 原理（配方法 Lean） |
| [06 热 I](docs/06-heat-fundamental.md) | 热核、阶梯磨光、无穷传播、Duhamel |
| [07 热 II](docs/07-heat-properties.md) | 半群律、正性、能量恒等式（Lean 单模式） |
| [08 热 III](docs/08-heat-energy.md) | 能量单调、衰减率 2λ₁、长时第一模式 |
| [09 波 I](docs/09-wave-kirchhoff.md) | d'Alembert（Lean 行波）、Kirchhoff、Huygens 对照 |
| [10 波 II](docs/10-wave-duhamel.md) | Duhamel、有限传播 vs 无穷传播对表 |

### 第三篇 非线性一阶（书第 3 章）

| 章 | 一句话 |
|---|---|
| [11 完全积分与包络](docs/11-complete-integrals.md) | Legendre 几何、梯度爆破 t* |
| [12 特征线](docs/12-characteristics.md) | 特征 ODE、拟线性/HJ 数值解 |
| [13 HJ I](docs/13-hopf-lax.md) | Legendre 配方（Lean）、Hopf-Lax = 特征线解 |
| [14 HJ II](docs/14-hj-weak.md) | 粘性消失收敛 Hopf-Lax、半凹性 |
| [15 守恒律](docs/15-shocks-entropy.md) | RH（Lean）、熵条件、Godunov、弱形式环量 |
| [16 守恒律 II](docs/16-lax-oleinik.md) | Lax-Oleinik（势的坑账）、Riemann、N 波 |

### 第四篇 解的表示（书第 4 章）

| 章 | 一句话 |
|---|---|
| [17 分离变量与 Turing](docs/17-separation-turing.md) | 谱、Bessel、Schnakenberg 失稳 |
| [18 行波、孤子、相似解](docs/18-waves-solitons.md) | KdV 双孤子（Hirota 三坑）、Barenblatt |
| [19 Fourier 变换法](docs/19-fourier.md) | Gauss 自对偶、反演、波/热模式对照 |
| [20 Radon 与 Laplace](docs/20-radon-laplace.md) | 切片定理逐位、erfc 解 |
| [21 Cole-Hopf 等](docs/21-cole-hopf.md) | 非线性⟺线性桥、粘性激波→熵激波 |
| [22 渐近方法](docs/22-asymptotics.md) | 边界层、Laplace/驻相、均匀化调和平均 |
| [23 幂级数与 CK](docs/23-power-series.md) | 收敛域 = 奇异特征距离、非特征条件 |

### 第五篇 Sobolev 空间（书第 5 章）

| 章 | 一句话 |
|---|---|
| [24 弱导数](docs/24-sobolev-basics.md) | 分部积分定义、离散分部（Lean） |
| [25 逼近、延拓、迹](docs/25-approximation.md) | 磨光收敛、偶延拓、迹的边界层家族 |
| [26 Sobolev 不等式](docs/26-sobolev-inequalities.md) | GNS/Morrey、临界 loglog 反例 |
| [27 紧性、Poincaré](docs/27-compactness.md) | Rellich 签名、差商判据、Hardy |
| [28 H^{-1} 与时空](docs/28-dual-spaces.md) | δ 进负空间、Bochner 框架 |

### 第六篇 二阶椭圆（书第 6 章）

| 章 | 一句话 |
|---|---|
| [29 弱解与 Lax-Milgram](docs/29-lax-milgram.md) | 有限元、Galerkin 正交、自由度坑账 |
| [30 能量估计与 Fredholm](docs/30-energy-fredholm.md) | 谱常数、二择一两面、病态=近谱 |
| [31 正则性](docs/31-regularity.md) | 差商方法、L 形域角奇性 r^{2/3} |
| [32 极值原理与 Harnack](docs/32-maximum-principle.md) | 弱/强/Hopf、Harnack 常数 |
| [33 特征值](docs/33-eigenvalues.md) | Rayleigh-Ritz、非对称主特征值、Weyl |

### 第七篇 线性发展方程（书第 7 章）

| 章 | 一句话 |
|---|---|
| [34 抛物弱解](docs/34-parabolic-weak.md) | Galerkin、模式 ODE、衰减估计 |
| [35 抛物性质](docs/35-parabolic-properties.md) | 解析半群、正性、唯一性 |
| [36 双曲弱解](docs/36-hyperbolic-weak.md) | 振子 Galerkin、能量守恒、正则性门槛 |
| [37 传播与双曲组](docs/37-hyperbolic-systems.md) | 特征不变量、对称双曲等距 |
| [38 半群理论](docs/38-semigroups.md) | Hille-Yosida、三大半群对照 |

### 第八篇 非线性理论（书第 8-9 章）

| 章 | 一句话 |
|---|---|
| [39 Euler-Lagrange](docs/39-euler-lagrange.md) | 牛顿解、一阶/二阶变分数值 |
| [40 直接方法](docs/40-direct-method.md) | 强制+凸、双阱多极小 |
| [41 正则性与约束](docs/41-constraints.md) | p-拉普拉斯、非线性特征值、障碍 |
| [42 山路与 Noether](docs/42-mountain-pass.md) | min-max 地形、守恒律 |
| [43 单调性与不动点](docs/43-fixed-points.md) | Banach/Schauder/单调三类收敛签名 |
| [44 上下解、非存在、梯度流](docs/44-subsupersolutions.md) | 夹逼迭代、blow-up、Pohozaev |

### 第九篇 前沿（书第 10-12 章）

| 章 | 一句话 |
|---|---|
| [45 粘性解](docs/45-viscosity.md) | 子微分判据、一致性、比较原理 |
| [46 控制与 HJB](docs/46-control-hjb.md) | 动态规划、Riccati、Hopf-Lax 控制出身 |
| [47 守恒律组](docs/47-riemann-problem.md) | p-系统、Riemann 不变量、RH 相容性 |
| [48 熵准则](docs/48-entropy-systems.md) | 熵对、消失粘性、熵耗散 |
| [49 非线性波 I](docs/49-nonlinear-wave.md) | 能量守恒、负能量爆破 |
| [50 非线性波 II](docs/50-critical-power.md) | 符号条件、临界指标、散射 |
| [51 总结](docs/51-summary.md) | 三部分地图、方法选择树（Prolog）、坑账精粹 |

## 构建与验证

    pwsh -NoProfile -Command '& ./build.ps1 -All'        # 全量验证
    pwsh -NoProfile -Command '& ./build.ps1 -Chapter 03' # 单章
    pwsh -NoProfile -Command '& ./build.ps1 -Lang lean'  # 单通道

**收官：76 单元全绿**（lean 12 / julia 51 / python 3 / prolog 7 / fortran 3——lean 含 00-07/09/13/15/24 共 12 章），十批提交（B0 预备、B1a/B1b 四大方程、B2 非线性一阶、
B3 解的表示、B4 Sobolev、B5 椭圆、B6 发展、B7 非线性、B8 前沿
+ B9 总结），覆盖 Evans 第二版 ch1-ch12 全部核心内容。

