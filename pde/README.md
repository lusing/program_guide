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

## 总目录

### 理论篇（Evans，docs/，章 00-51）

- [00-01 预备](docs/00-intro.md)：方程动物园、适定性、Hadamard 反例
- [02-10 四大线性方程](docs/02-transport.md)：传输/Laplace×3/热×3/波×2
- [11-16 非线性一阶](docs/11-complete-integrals.md)：特征线、Hopf-Lax、激波、熵
- [17-23 解的表示](docs/17-separation-turing.md)：分离、孤子、变换、渐近、CK
- [24-28 Sobolev 空间](docs/24-sobolev-basics.md)：弱导数、逼近、GNS、紧性、对偶
- [29-33 二阶椭圆](docs/29-lax-milgram.md)：Lax-Milgram、Fredholm、正则性、极值原理、谱
- [34-38 线性发展](docs/34-parabolic-weak.md)：Galerkin、双曲组、半群
- [39-44 非线性](docs/39-euler-lagrange.md)：变分、山路、不动点、上下解
- [45-51 前沿与总结](docs/45-viscosity.md)：粘性解、HJB、守恒律组、非线性波、总结

### 数值篇（陆金甫/关治，docs-numeric/，章 00-34）

- [00-02 预备](docs-numeric/00-intro.md)：对表文化、模型方程、Fourier
- [03-06 差分基础](docs-numeric/03-scheme-construction.md)：构造、CCS、von Neumann
- [07-13 双曲](docs-numeric/07-advection-schemes.md)：迎风/LF/LW、CFL、守恒律
- [14-20 抛物](docs-numeric/14-diffusion-basic.md)：显隐式、DFF、ADI、非线性
- [21-23 椭圆差分](docs-numeric/21-elliptic-five-nine.md)：五点/九点、极值原理、双调和
- [24-27 变分](docs-numeric/24-variational-classical.md)：古典变分、Ritz/Galerkin
- [28-30 有限元](docs-numeric/28-fem-1d.md)：一维/二维/高阶元
- [31-34 专题](docs-numeric/31-variational-diffusion-parabolic-fem.md)：变分差分、特征值、BEM/多重网格、总结

### 习题篇（沙马耶夫，docs-problems/，章 P00-P07）

- [P00 广义函数与基本解](docs-problems/P00-distributions.md)：δ 演算、半平面为零的基本解（详解 1.5）
- [P01 Sobolev 与 Friedrichs](docs-problems/P01-sobolev.md)：对数成员资格（详解 1.12）、峰值反例
- [P02 分类与适定性](docs-problems/P02-classification.md)：特征曲线、Tricomi、Hadamard
- [P03 波动 Cauchy](docs-problems/P03-wave-cauchy.md)：d'Alembert、依赖区间、平行四边形
- [P04 弦与 Fourier](docs-problems/P04-string-fourier.md)：延拓法、驻波、共振
- [P05 抛物](docs-problems/P05-heat.md)：erfc 解、模式衰减、逆问题
- [P06 椭圆](docs-problems/P06-elliptic.md)：调和多项式、Harnack、Dirichlet 积分
- [P07 三线合一总对账](docs-problems/P07-unification.md)：四问题三方一致的收官实验

## 构建与验证

    pwsh -NoProfile -Command '& ./build.ps1 -All'              # 全量
    pwsh -NoProfile -Command '& ./build.ps1 -Part theory'      # 理论篇
    pwsh -NoProfile -Command '& ./build.ps1 -Part numeric'     # 数值篇
    pwsh -NoProfile -Command '& ./build.ps1 -Part problems'    # 习题篇
