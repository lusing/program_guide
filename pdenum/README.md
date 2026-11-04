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

（后续批次随构建展开：07–13 双曲、14–20 抛物、21–23 椭圆差分、
24–27 变分、28–30 有限元、31–34 专题与总结。）

## 构建与验证

    pwsh -NoProfile -Command '& ./build.ps1 -All'        # 全量验证
    pwsh -NoProfile -Command '& ./build.ps1 -Chapter 03' # 单章
    pwsh -NoProfile -Command '& ./build.ps1 -Lang lean'  # 单通道
