# 偏微分方程：三部合一教程

三部教材融合为一：

1. **理论篇**：Lawrence C. Evans《Partial Differential Equations》
   2nd ed（AMS GSM 19）——解是什么、何时存在、多光滑；
2. **数值篇**：陆金甫、关治《偏微分方程数值解法》第 3 版——怎么算、
   算多准、算多稳；
3. **习题篇**：A.C. 沙马耶夫《偏微分方程习题集》第 2 版（莫斯科大学
   试题汇编）——怎么解题、考什么。

全部自包含：只读 docs 即可学习，每章开头给"对应书 §x.y"定位锚。

四通道机器验证：

- **Lean 4 + mathlib4**（单 lake 工程：Evanspde + Pdenum 双命名空间）
- **Julia**（每章制造解对表）+ **Python**（交叉）
- **Prolog**（规则/分类库）+ **Fortran**（经典内核）

## 详细目录

### 理论篇（Evans，docs/，章 00-51）

#### 预备（书第 1 章）

| 章 | 一句话 |
|---|---|
| [00 导言](docs/00-intro.md) | 方程动物园、制造解对表、叠加原理完整机器证明 |
| [01 适定性与 Hadamard 反例](docs/01-wellposed.md) | 三判据、逆热放大、sin·sinh 边值趋零解爆炸 |

#### 四大线性方程（书第 2 章）

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

#### 非线性一阶（书第 3 章）

| 章 | 一句话 |
|---|---|
| [11 完全积分与包络](docs/11-complete-integrals.md) | Legendre 几何、梯度爆破 t* |
| [12 特征线](docs/12-characteristics.md) | 特征 ODE、拟线性/HJ 数值解 |
| [13 HJ I](docs/13-hopf-lax.md) | Legendre 配方（Lean）、Hopf-Lax = 特征线解 |
| [14 HJ II](docs/14-hj-weak.md) | 粘性消失收敛 Hopf-Lax、半凹性 |
| [15 守恒律](docs/15-shocks-entropy.md) | RH（Lean）、熵条件、Godunov、弱形式环量 |
| [16 守恒律 II](docs/16-lax-oleinik.md) | Lax-Oleinik（势的坑账）、Riemann、N 波 |

#### 解的表示（书第 4 章）

| 章 | 一句话 |
|---|---|
| [17 分离变量与 Turing](docs/17-separation-turing.md) | 谱、Bessel、Schnakenberg 失稳 |
| [18 行波、孤子、相似解](docs/18-waves-solitons.md) | KdV 双孤子（Hirota 三坑）、Barenblatt |
| [19 Fourier 变换法](docs/19-fourier.md) | Gauss 自对偶、反演、波/热模式对照 |
| [20 Radon 与 Laplace](docs/20-radon-laplace.md) | 切片定理逐位、erfc 解 |
| [21 Cole-Hopf 等](docs/21-cole-hopf.md) | 非线性⟺线性桥、粘性激波→熵激波 |
| [22 渐近方法](docs/22-asymptotics.md) | 边界层、Laplace/驻相、均匀化调和平均 |
| [23 幂级数与 CK](docs/23-power-series.md) | 收敛域 = 奇异特征距离、非特征条件 |

#### Sobolev 空间（书第 5 章）

| 章 | 一句话 |
|---|---|
| [24 弱导数](docs/24-sobolev-basics.md) | 分部积分定义、离散分部（Lean） |
| [25 逼近、延拓、迹](docs/25-approximation.md) | 磨光收敛、偶延拓、迹的边界层家族 |
| [26 Sobolev 不等式](docs/26-sobolev-inequalities.md) | GNS/Morrey、临界 loglog 反例 |
| [27 紧性、Poincaré](docs/27-compactness.md) | Rellich 签名、差商判据、Hardy |
| [28 H⁻¹ 与时空](docs/28-dual-spaces.md) | δ 进负空间、Bochner 框架 |

#### 二阶椭圆（书第 6 章）

| 章 | 一句话 |
|---|---|
| [29 弱解与 Lax-Milgram](docs/29-lax-milgram.md) | 有限元、Galerkin 正交、自由度坑账 |
| [30 能量估计与 Fredholm](docs/30-energy-fredholm.md) | 谱常数、二择一两面、病态=近谱 |
| [31 正则性](docs/31-regularity.md) | 差商方法、L 形域角奇性 r^{2/3} |
| [32 极值原理与 Harnack](docs/32-maximum-principle.md) | 弱/强/Hopf、Harnack 常数 |
| [33 特征值](docs/33-eigenvalues.md) | Rayleigh-Ritz、非对称主特征值、Weyl |

#### 线性发展方程（书第 7 章）

| 章 | 一句话 |
|---|---|
| [34 抛物弱解](docs/34-parabolic-weak.md) | Galerkin、模式 ODE、衰减估计 |
| [35 抛物性质](docs/35-parabolic-properties.md) | 解析半群、正性、唯一性 |
| [36 双曲弱解](docs/36-hyperbolic-weak.md) | 振子 Galerkin、能量守恒、正则性门槛 |
| [37 传播与双曲组](docs/37-hyperbolic-systems.md) | 特征不变量、对称双曲等距 |
| [38 半群理论](docs/38-semigroups.md) | Hille-Yosida、三大半群对照 |

#### 非线性理论（书第 8-9 章）

| 章 | 一句话 |
|---|---|
| [39 Euler-Lagrange](docs/39-euler-lagrange.md) | 牛顿解、一阶/二阶变分数值 |
| [40 直接方法](docs/40-direct-method.md) | 强制+凸、双阱多极小 |
| [41 正则性与约束](docs/41-constraints.md) | p-拉普拉斯、非线性特征值、障碍 |
| [42 山路与 Noether](docs/42-mountain-pass.md) | min-max 地形、守恒律 |
| [43 单调性与不动点](docs/43-fixed-points.md) | Banach/Schauder/单调三类收敛签名 |
| [44 上下解、非存在、梯度流](docs/44-subsupersolutions.md) | 夹逼迭代、blow-up、Pohozaev |

#### 前沿与总结（书第 10-12 章）

| 章 | 一句话 |
|---|---|
| [45 粘性解](docs/45-viscosity.md) | 子微分判据、一致性、比较原理 |
| [46 控制与 HJB](docs/46-control-hjb.md) | 动态规划、Riccati、Hopf-Lax 控制出身 |
| [47 守恒律组](docs/47-riemann-problem.md) | p-系统、Riemann 不变量、RH 相容性 |
| [48 熵准则](docs/48-entropy-systems.md) | 熵对、消失粘性、熵耗散 |
| [49 非线性波 I](docs/49-nonlinear-wave.md) | 能量守恒、负能量爆破 |
| [50 非线性波 II](docs/50-critical-power.md) | 符号条件、临界指标、散射 |
| [51 总结](docs/51-summary.md) | 三部分地图、方法选择树（Prolog）、坑账精粹 |

### 数值篇（陆金甫/关治，docs-numeric/，章 00-34）

#### 预备（书第 1 章）

| 章 | 一句话 |
|---|---|
| [00 导言](docs-numeric/00-intro.md) | 对表文化、方法效率（Jacobi→SOR 15×）、五通道 |
| [01 典型方程、定解问题与适定性](docs-numeric/01-prelim.md) | 分类判别式、d'Alembert、依赖区间 |
| [02 Fourier 变换与复矩阵](docs-numeric/02-fourier.md) | 高斯变换对、Parseval、正规矩阵与 Richardson 预告 |

#### 差分法基本概念（书第 2 章）

| 章 | 一句话 |
|---|---|
| [03 差分格式的构造](docs-numeric/03-scheme-construction.md) | Taylor/积分方法、显隐之别、追赶法、模板恒等式 |
| [04 相容性、收敛性与稳定性](docs-numeric/04-ccs.md) | Lax 等价定理、扰动传播实验、依赖域错配复盘 |
| [05 von Neumann 稳定性分析](docs-numeric/05-von-neumann.md) | 增长因子、四判例、Parseval 闭环（六位吻合） |
| [06 Hirt、矩阵法与能量法](docs-numeric/06-other-methods.md) | 修正方程定量对账、特征值闭式、凸性不等式 |

#### 双曲方程（书第 3 章）

| 章 | 一句话 |
|---|---|
| [07 迎风、LF 与 LW](docs-numeric/07-advection-schemes.md) | 特征线插值统一构造、耗散/色散性格表、BW λ≤2 |
| [08 CFL、特征线与蛙跳](docs-numeric/08-cfl-leapfrog.md) | 依赖域锥 2n+1、λ=1 退化线性增长、起步层精度 |
| [09 方程组与变系数](docs-numeric/09-systems-variable.md) | Riemann 不变量、特征形式迎风、RK4 特征线核对 |
| [10 波动方程](docs-numeric/10-wave-equation.md) | 二阶起步的共振账、aλ=1 特解逐字复现 |
| [11 初边值与数值边界](docs-numeric/11-boundary-treatment.md) | 加权隐式酉矩阵、外推边界慢性病、计数定律 |
| [12 二维与分数步长](docs-numeric/12-2d-hyperbolic.md) | λ²(a²+b²)≤1/2、LOD 回一维条件、\|G\|≡1 |
| [13 守恒律](docs-numeric/13-conservation-laws.md) | RH 速度对账（非守恒差 100 格）、熵条件、稀疏波 |

#### 抛物方程（书第 4 章）

| 章 | 一句话 |
|---|---|
| [14 显式、隐式与加权隐式](docs-numeric/14-diffusion-basic.md) | 表 4.1 复现（含勘误）、2r(1−2θ)≤1、CN 大 λ 失真 |
| [15 Richardson、DFF 与跳点](docs-numeric/15-three-layer.md) | DFF 条件相容（误差停在 0.75）、跳点≡DFF 逐位一致 |
| [16 边界处理、Saul'ev 与 GE](docs-numeric/16-ibvp-saulev.md) | 二阶边界好 137 倍、扫描式半隐、并行点对 |
| [17 对流扩散](docs-numeric/17-convection-diffusion.md) | λ²≤2μ≤1 双条件、网格 Peclet、迎风人工扩散 |
| [18 变系数、盒式与有限体积](docs-numeric/18-variable-coeff.md) | 通量形式、界面调和平均对分段线性解精确 |
| [19 多维：ADI 与 LOD](docs-numeric/19-multidim-parabolic.md) | r≤1/4、PR-ADI 二阶无条件稳、测阶/验稳分参数 |
| [20 非线性抛物](docs-numeric/20-nonlinear-parabolic.md) | Richtmyer 线性化、预估-校正、稳定裕度随 k(u) 缩水 |

#### 椭圆方程差分法（书第 5 章）

| 章 | 一句话 |
|---|---|
| [21 五点、九点与极坐标](docs-numeric/21-elliptic-five-nine.md) | 书例逐位复现、九点 O(h⁴)（残差对账抓两错）、守恒极坐标 |
| [22 极值原理](docs-numeric/22-maximum-principle.md) | 传播矛盾、特征值闭式全谱对账、闸函数收敛 |
| [23 边界、变系数、双调和、特征值](docs-numeric/23-elliptic-boundary-varcoeff.md) | 通量格式 O(h²)、13 点模板、λ_min→2π² |

#### 变分原理（书第 6 章）

| 章 | 一句话 |
|---|---|
| [24 古典变分](docs-numeric/24-variational-classical.md) | 最速降线三重对账、Euler 方程残差、能量直接法 |
| [25 两点边值变分](docs-numeric/25-twopoint-variational.md) | hat 基 D 闭式逐位、刚度正定、能量最优 |
| [26 高维变分](docs-numeric/26-multidim-variational.md) | 能量最小数值版、提升、界面吸收、Poincaré |
| [27 Ritz/Galerkin/权余量](docs-numeric/27-ritz-galerkin.md) | 正弦基谱收敛、同一性、配点对照、权家族 |

#### 有限元（书第 7 章）

| 章 | 一句话 |
|---|---|
| [28 一维线性元](docs-numeric/28-fem-1d.md) | 单元装配协议、Robin 项、O(h²)（Fortran 0 基映射坑） |
| [29 二维三角形线性元](docs-numeric/29-fem-2d-triangle.md) | 面积坐标闭式、零模式、P1 与五点差分同阶 |
| [30 高次元与等参元](docs-numeric/30-high-order-isoparametric.md) | 二次元 O(h³)（比值 16.2）、Hermite C¹、等参映射 |

#### 专题与总结（书第 8 章）

| 章 | 一句话 |
|---|---|
| [31 变分差分与抛物 FEM](docs-numeric/31-variational-diffusion-parabolic-fem.md) | Galerkin 列差分、CN-Galerkin 无条件稳定 |
| [32 特征值与变分不等方程](docs-numeric/32-eigenvalue-inequality.md) | Kc=λMc 从上方逼近、障碍问题投影 SOR |
| [33 边界元与多重网格](docs-numeric/33-bem-multigrid.md) | Green 降维、V 循环因子 0.014 vs Jacobi 0.994 |
| [34 总结](docs-numeric/34-summary.md) | 三条路交叉对账、方法选择树、坑账索引 |

### 习题篇（沙马耶夫，docs-problems/，章 P00-P07）

| 章 | 一句话 |
|---|---|
| [P00 广义函数与基本解](docs-problems/P00-distributions.md) | δ 演算、半平面为零的基本解（详解 1.5） |
| [P01 Sobolev 与 Friedrichs](docs-problems/P01-sobolev.md) | 对数成员资格（详解 1.12）、峰值反例 |
| [P02 分类与适定性](docs-problems/P02-classification.md) | 特征曲线、Tricomi、Hadamard |
| [P03 波动 Cauchy](docs-problems/P03-wave-cauchy.md) | d'Alembert、依赖区间、平行四边形 |
| [P04 弦与 Fourier](docs-problems/P04-string-fourier.md) | 延拓法、驻波、共振 |
| [P05 抛物](docs-problems/P05-heat.md) | erfc 解、模式衰减、逆问题 |
| [P06 椭圆](docs-problems/P06-elliptic.md) | 调和多项式、Harnack、Dirichlet 积分 |
| [P07 三线合一总对账](docs-problems/P07-unification.md) | 四问题三方一致的收官实验 |

## 构建与验证

    pwsh -NoProfile -Command '& ./build.ps1 -All'              # 全量
    pwsh -NoProfile -Command '& ./build.ps1 -Part theory'      # 理论篇
    pwsh -NoProfile -Command '& ./build.ps1 -Part numeric'     # 数值篇
    pwsh -NoProfile -Command '& ./build.ps1 -Part problems'    # 习题篇
