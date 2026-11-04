# 偏微分方程数值解法：差分·有限元与机器验证教程

以 陆金甫、关治《偏微分方程数值解法》第 3 版（清华大学出版社，
2016）为纲的中文教程——全书核心自包含：只读 docs 即可学习，不需要
回看原书；每章开头给"对应书 §x.y"定位锚。

五通道机器验证：

- **Lean 4 + mathlib4**（主证明：单 lake 工程，mathlib 4.33.1 钉版
  路径依赖——增长因子恒等式、离散极值原理、三对角特征向量、FEM
  刚度矩阵精确装配等）
- **Julia / Python (scipy)**（数值：差分格式实现与收敛阶测量、
  谱半径、FEM 装配、多重网格、边界元——双实现交叉验证）
- **Prolog (SWI)**（符号：Taylor 截断误差引擎、von Neumann 增长因子
  求解器、CFL 知识库、FEM 装配索引映射、方法选择树）
- **Fortran (flang)**（经典数值内核：Lax-Wendroff、Crank-Nicolson、
  ADI、五点 SOR、多重网格）

## 全书目录

### 第一篇 预备（书第 1 章，B0 批次）

科学计算为何是第三种科学方法；模型方程谱与定解问题；二阶方程
分类与特征线；Fourier 变换与复矩阵——差分法分析的全部弹药。

| 章 | 标题 | 一句话 |
|---|---|---|
| [00](docs/00-intro.md) | 导言 | 对表文化、方法效率（Jacobi→SOR 15×）、五通道 |
| [01](docs/01-prelim.md) | 典型方程、定解问题与适定性 | 分类判别式、d'Alembert、依赖区间 |
| [02](docs/02-fourier.md) | Fourier 变换与复矩阵 | 高斯变换对、Parseval、正规矩阵与 Richardson 预告 |

### 第二篇 差分法基本概念（书第 2 章，B1 批次）

| 章 | 标题 | 一句话 |
|---|---|---|
| [03](docs/03-scheme-construction.md) | 差分格式的构造 | Taylor/积分方法、显隐之别、追赶法、模板恒等式 |
| [04](docs/04-ccs.md) | 相容性、收敛性与稳定性 | Lax 等价定理、扰动传播实验、依赖域错配复盘 |
| [05](docs/05-von-neumann.md) | von Neumann 稳定性分析 | 增长因子、四判例、Parseval 闭环（六位吻合） |
| [06](docs/06-other-methods.md) | Hirt、矩阵法与能量法 | 修正方程定量对账、特征值闭式、凸性不等式 |

### 第三篇 双曲方程（书第 3 章，B2 批次）

| 章 | 标题 | 一句话 |
|---|---|---|
| [07](docs/07-advection-schemes.md) | 迎风、LF 与 LW | 特征线插值统一构造、耗散/色散性格表、BW λ≤2 |
| [08](docs/08-cfl-leapfrog.md) | CFL、特征线与蛙跳 | 依赖域锥 2n+1、λ=1 退化线性增长、起步层精度 |
| [09](docs/09-systems-variable.md) | 方程组与变系数 | Riemann 不变量、特征形式迎风、RK4 特征线核对 |
| [10](docs/10-wave-equation.md) | 波动方程 | 二阶起步的共振账、aλ=1 特解逐字复现 |
| [11](docs/11-boundary-treatment.md) | 初边值与数值边界 | 加权隐式酉矩阵、外推边界慢性病、计数定律 |
| [12](docs/12-2d-hyperbolic.md) | 二维与分数步长 | λ²(a²+b²)≤1/2、LOD 回一维条件、|G|≡1 |
| [13](docs/13-conservation-laws.md) | 守恒律 | RH 速度对账（非守恒差 100 格）、熵条件、稀疏波 |

### 第四篇 抛物方程（书第 4 章，B3 批次）

| 章 | 标题 | 一句话 |
|---|---|---|
| [14](docs/14-diffusion-basic.md) | 显式、隐式与加权隐式 | 表 4.1 复现（含勘误）、2r(1−2θ)≤1、CN 大 λ 失真 |
| [15](docs/15-three-layer.md) | Richardson、DFF 与跳点 | DFF 条件相容（误差停在 0.75）、跳点≡DFF 逐位一致 |
| [16](docs/16-ibvp-saulev.md) | 边界处理、Saul'ev 与 GE | 二阶边界好 137 倍、扫描式半隐、并行点对 |
| [17](docs/17-convection-diffusion.md) | 对流扩散 | λ²≤2μ≤1 双条件、网格 Peclet、迎风人工扩散 |
| [18](docs/18-variable-coeff.md) | 变系数、盒式与有限体积 | 通量形式、界面调和平均对分段线性解精确 |
| [19](docs/19-multidim-parabolic.md) | 多维：ADI 与 LOD | r≤1/4、PR-ADI 二阶无条件稳、测阶/验稳分参数 |
| [20](docs/20-nonlinear-parabolic.md) | 非线性抛物 | Richtmyer 线性化、预估-校正、稳定裕度随 k(u) 缩水 |

### 第五篇 椭圆方程差分法（书第 5 章，B4 批次）

| 章 | 标题 | 一句话 |
|---|---|---|
| [21](docs/21-elliptic-five-nine.md) | 五点、九点与极坐标 | 书例逐位复现、九点 O(h⁴)（残差对账抓两错）、守恒极坐标 |
| [22](docs/22-maximum-principle.md) | 极值原理 | 传播矛盾、特征值闭式全谱对账、闸函数收敛 |
| [23](docs/23-elliptic-boundary-varcoeff.md) | 边界、变系数、双调和、特征值 | 通量格式 O(h²)、13 点模板、λ_min→2π² |

### 第六篇 变分原理（书第 6 章，B5 批次）

| 章 | 标题 | 一句话 |
|---|---|---|
| [24](docs/24-variational-classical.md) | 古典变分 | 最速降线三重对账、Euler 方程残差、能量直接法 |
| [25](docs/25-twopoint-variational.md) | 两点边值变分 | hat 基 D 闭式逐位、刚度正定、能量最优 |
| [26](docs/26-multidim-variational.md) | 高维变分 | 能量最小数值版、提升、界面吸收、Poincaré |
| [27](docs/27-ritz-galerkin.md) | Ritz/Galerkin/权余量 | 正弦基谱收敛、同一性、配点对照、权家族 |

### 第七篇 有限元（书第 7 章，B6 批次）

| 章 | 标题 | 一句话 |
|---|---|---|
| [28](docs/28-fem-1d.md) | 一维线性元 | 单元装配协议、Robin 项、O(h²)（Fortran 0 基映射坑） |
| [29](docs/29-fem-2d-triangle.md) | 二维三角形线性元 | 面积坐标闭式、零模式、P1 与五点差分同阶 |
| [30](docs/30-high-order-isoparametric.md) | 高次元与等参元 | 二次元 O(h³)（比值 16.2）、Hermite C¹、等参映射 |

（后续批次随构建展开：31–34 专题与总结。）

## 构建与验证

    pwsh -NoProfile -Command '& ./build.ps1 -All'        # 全量验证
    pwsh -NoProfile -Command '& ./build.ps1 -Chapter 03' # 单章
    pwsh -NoProfile -Command '& ./build.ps1 -Lang lean'  # 单通道
