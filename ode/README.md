# 常微分方程：解析方法与机器验证教程

以 Henner, Nepomnyashchy, Belozerova, Khenner,
*Ordinary Differential Equations: Analytical Methods and Applications*
（Springer 2023）为纲的中文教程——全书核心自包含：只读 docs 即可
学习，不需要回看原书；每章开头给"对应书 §x.y"定位锚。

五通道机器验证：

- **Lean 4 + mathlib4**（主证明：单 lake 工程，mathlib 4.33.1 钉版
  路径依赖——`IsPicardLindelof` 存在唯一性、`ODE_solution_unique`、
  解的逐字 `HasDerivAt` 核对、势函数偏导、Clairut 包络等）
- **Julia / Python (scipy)**（数值：RK4/收敛阶/相线轨道/模型账——
  公式解与数值解交叉验证）
- **Prolog (SWI)**（符号：表达式树微分 + 项表化简内核 + 规则引擎
  ——分离/线性/恰当/Clairut 求解器、相线分类器）
- **Fortran (flang)**（经典数值：Picard 迭代、收敛阶测量、模型账）

## 全书目录

### 第一篇 一阶方程（书 §1–§2）

从"解是什么"出发：存在唯一性定理与 Picard 迭代（反例与爆破）、方
向场与等斜线、可分离方程与齐次化归、一阶线性方程的三件变装、恰当
方程与积分因子、未解出导数的方程与包络、自治方程的相线、一阶模型
合集。

| 章 | 一句话 |
|---|---|
| [00 导言](docs/00-intro.md) | ODE 的语言、解的核对、五通道分工 |
| [01 存在唯一性与 Picard 迭代](docs/01-existence-uniqueness.md) | Lipschitz 条件、反例、压缩映射 |
| [02 方向场与等斜线](docs/02-direction-fields.md) | 几何读法 + Euler/Heun/RK4 收敛阶 |
| [03 可分离方程](docs/03-separable.md) | 分离积分、丢解纪律、齐次化归 |
| [04 一阶线性方程](docs/04-linear-first.md) | 参数变易、积分因子、Bernoulli/Riccati |
| [05 恰当方程与积分因子](docs/05-exact.md) | P_y = Q_x 判据、求势协议、找 μ |
| [06 未解出导数的方程](docs/06-unresolved.md) | 分支解、Clairut 包络与换轨 |
| [07 自治方程的相线](docs/07-phase-line.md) | 平衡点分类、导数判据的盲区 |
| [08 一阶模型合集](docs/08-models.md) | 摩擦/火箭/冷却/衰变/复利/盐水/RL |

### 第二篇 二阶与高阶（书 §3，B1 批次）

| 章 | 一句话 |
|---|---|
| [09 一般理论与降阶法](docs/09-reduction.md) | 四类可积型、已知一解降阶 |
| [10 线性二阶理论](docs/10-linear-theory.md) | Wronskian、Abel 恒等式、参数变易 |
| [11 常系数二阶方程](docs/11-constant-coeff.md) | 特征方程三情形、待定系数、共振 |
| [12 周期系数：Hill 与 Mathieu](docs/12-mathieu.md) | Floquet 矩阵、参数共振带 |
| [13 高阶与 Euler 方程](docs/13-higher-order.md) | 算子因式分解、x^k 型试探 |
| [14 振动应用](docs/14-oscillations.md) | 机械振动、RLC、浮体 |

### 第三篇 方程组（书 §4）

| 章 | 一句话 |
|---|---|
| [15 方程组一般理论](docs/15-systems-intro.md) | 高阶⟺一阶组、线性理论 |
| [16 特征值方法](docs/16-systems-eigen.md) | 三种特征值情形、非齐次 |
| [17 矩阵指数](docs/17-matrix-exp.md) | e^{At}、Putzer、变易常数 |
| [18 方程组应用](docs/18-systems-apps.md) | 带电粒子、磁矩进动、互感 |

### 第四篇 定性理论与稳定性（书 §5）

| 章 | 一句话 |
|---|---|
| [19 相平面与奇点](docs/19-phase-plane.md) | 迹–行列式图、六类奇点 |
| [20 Lyapunov 稳定性](docs/20-stability.md) | 线性化、Lyapunov 函数、轨道稳定 |
| [21 分岔](docs/21-bifurcations.md) | 鞍结/跨临界/叉式/Hopf |
| [22 非线性振动与极限环](docs/22-limit-cycles.md) | van der Pol、Poincaré–Bendixson |

### 第五篇 级数与变换（书 §6–§8）

| 章 | 一句话 |
|---|---|
| [23 幂级数解法](docs/23-power-series.md) | 常点、正则奇点、Frobenius |
| [24 Laplace 变换](docs/24-laplace.md) | 变换表、部分分式、卷积 |
| [25 Fourier 级数](docs/25-fourier.md) | 系数、Gibbs、Parseval、复形式 |

### 第六篇 边值问题与特殊函数（书 §9–§10）

| 章 | 一句话 |
|---|---|
| [26 Sturm–Liouville 与 Green 函数](docs/26-sturm-liouville.md) | 自伴算子、特征值、可解性 |
| [27 Γ 函数与 Bessel 函数](docs/27-bessel.md) | J/Y/修正/Airy、Fourier–Bessel |
| [28 Legendre、Hermite 与椭圆积分](docs/28-legendre.md) | Rodrigues、正交性、单摆周期 |

### 第七篇 积分方程、变分法与展望（书 §11–§13）

| 章 | 一句话 |
|---|---|
| [29 积分方程](docs/29-integral-equations.md) | Fredholm/Volterra、逐次逼近 |
| [30 变分法](docs/30-calculus-of-variations.md) | Euler 方程、brachistochrone、Ritz |
| [31 分离变量与三大方程](docs/31-pde-separation.md) | 热传导/波动/Laplace 方程 |
| [32 总结](docs/32-summary.md) | 方法地图与通道速查 |

## 构建与验证

    pwsh -NoProfile -Command '& ./build.ps1 -All'        # 全量验证
    pwsh -NoProfile -Command '& ./build.ps1 -Chapter 03' # 单章
    pwsh -NoProfile -Command '& ./build.ps1 -Lang lean'  # 单通道

**收官：117/117 单元全绿**（lean 16 / julia 33 / python 33 /
prolog 28 / fortran 7），七批提交（B0 基建+一阶篇、B1 二阶篇、
B2 方程组篇、B3 定性篇、B4 级数变换篇、B5 边值特殊函数篇、
B6 收官篇），覆盖原书 ch1–ch13 全部核心内容。
