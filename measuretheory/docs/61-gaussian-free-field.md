# 61 高斯自由场：Gauss–Hilbert 构造、狄利克雷能量与乘性混沌

**对应胡晓予《高等概率论》§8.3（pp. 168-170）。数学上接第 47 章
（Gauss 测度）、第 60 章（布朗运动的等距构造）与第 13 章（$L^2$ 的
几何）。**

---

## 61.1 从"运动"到"场"

布朗运动把随机性安装在**时间轴** $\mathbb R_+$ 上：每个时刻一个
高斯值，协方差 $\min(s,t)$ 。数学与物理的下一个问题是：把随机性安装
在**空间区域** $D\subseteq\mathbb R^2$ 的每个点上——随机场。统计物理
的界面涨落（界面高度函数）、量子场论的玻色场、图像处理与空间统计
的空间相关噪声，理论模型都是同一个对象：**高斯自由场**（GFF）。

胡书 §8.3 的路线极为经济：先用一个概念（Gauss–Hilbert 空间 + 等距）
同时制造布朗运动与 GFF，再在平面上展开 GFF 的能量语言，最后给出
乘性混沌（Liouville 量子引力的体积测度）。本章照此展开，并补上
GFF 最直观的有限模型——**离散 GFF**（有限图上的 pinned 高斯），
它让"协方差 = 格林函数""场不是函数""狄利克雷原理"全部变成
精确可算的账。

## 61.2 Gauss–Hilbert 空间与等距构造

**定义 8.3.1** $L^2(\Omega,\mathcal F,P)$ 中由**零均值正态随机变量**
张成的完备线性子空间 $H$ 称为 **Gauss–Hilbert 空间**（内积继承
$(X,Y)=E[XY]$ ）。

$H$ 中任何有限个元素联合正态（线性组合正态），协方差 = 内积——
**Gauss–Hilbert 空间就是"穿着概率外衣的 Hilbert 空间"**。核心引理
（等距提升）：设 $T:L^2(\mathbb R)\to H$ 是到 $H$ 的线性等距
（$\|Tf\|^2=\|f\|^2_{L^2}$ ），定义

$$\boxed{\ W(t):=T\big(\mathbf 1_{(0,t]}\big)\ }$$

则 $\{W(t)\}$ 是布朗运动：增量 $W(t)-W(s)=T(\mathbf 1_{(s,t]})$ 的
内积 $\|\mathbf 1_{(s,t]}\|²=t−s$ 给出正确的协方差结构，等距保持
正交（独立增量）。第 60 章的 Fourier 构造正是把 $T$ 在标准正交基上
显式化：$T(\mathbf 1_{(0,t]})$ 的级数展开（式 8.3.2）。mathlib 的
`IsGaussianProcess`（零均值高斯过程结构）+ 协方差引理承载这一层。

**观点升级**：布朗运动不是"一列随机变量"，而是**一个线性等距**
$T$——把 $L^2$ 的每个向量送到一个高斯变量。换个来源空间，就换一
种场。

## 61.3 平面 GFF：能量内积与特征基

设 $D\subseteq\mathbb R^2$ 是区域。取 $H_0^1(D)$ ：紧支撑于 $D$ 的
$C^1$ 函数按**梯度内积**

$$\langle f,g\rangle_\nabla=\int_D\nabla f\cdot\nabla g\,da$$

完备化的空间。分部积分（无边界项，紧支撑）给

$$\langle f,g\rangle_\nabla=\langle f,-\Delta g\rangle_{L^2}$$

——梯度内积 = 用 $-\Delta$ 加权的 $L^2$ 内积。**定义 8.3.2** 取
$\{f_i\}$ 为 $H_0^1(D)$ 的标准正交基、$\{Z_i\}$ iid $N(0,1)$ ，
$h=\sum_iZ_if_i$ （$L^2$ 意义下），称 Gauss–Hilbert 空间

$$\mathfrak g(D)=\overline{\mathrm{span}}\big\{h(f):=\textstyle\sum_iZ_i\langle f,f_i\rangle_\nabla,\ f\in H_0^1(D)\big\}$$

为由 $h$ 产生的**高斯自由场**。协方差结构：

$$E\big[h(f)\,h(g)\big]=\langle f,g\rangle_\nabla .$$

**特征基的账**（注 8.3.1）：设 $e_i$ 是 Dirichlet 边界条件下 $-\Delta$
的特征函数（$\Delta e_i=\lambda_ie_i$ ，$\lambda_i<0$ ），则
$f_i=e_i/\sqrt{-\lambda_i}$ 是 $H_0^1(D)$ 的正交基
（$\langle e_i,e_j\rangle_\nabla=-\langle e_i,\Delta e_j\rangle
=-\lambda_j\delta_{ij}$ ）。此时

$$h(f)=\int_D h(x)f(x)\,da\quad(\text{当 }f\in L^2\text{ 可读出})$$

GFF 作用于"测试函数" $f$ 的规则：**拿 $f$ 的能量展开系数与独立
高斯配对**。正方形上 $\lambda_{m,n}\propto-(m^2+n^2)$ ，$f_{m,n}\propto
\sin(m\pi x)\sin(n\pi y)/\sqrt{m^2+n^2}$ ——与布朗运动的 K-L 基
（$\propto1/n$ ）只差一维的谱。

## 61.4 为什么 GFF 不是函数

一维（布朗运动）：点值 $B(t)$ 有定义，方差有限。谱账：
$\sum_n1/\lambda_n\sim\sum1/n^2<\infty$ 。二维：$\lambda_{m,n}\propto
m^2+n^2$ ，满足 $m^2+n^2\le R^2$ 的特征值约 $\pi R^2$ 个，故

$$\sum_{m,n}\frac{1}{m^2+n^2}\ \sim\ \int_1^\infty\frac{\pi\,d(r^2)}{r^2}\ =\ \infty\qquad(\text{对数发散}).$$

点方差 = $\sum 1/\lambda_i=\infty$ ：**二维 GFF 在任何单点都没有
定义**——它是随机**广义函数**（分布），只通过 $h(f)$ 对测试函数
$=$（$H_0^1$ 能量空间）的作用存在。指示函数 $\mathbf 1_A\notin H_0^1$
（能量无穷），所以"$h$ 在集合 $A$ 上的质量"不能直接读出——61.6 的
乘性混沌就是绕开这一禁令的合法化工程。协方差的形态：两点作用
$h(f_x^\varepsilon),h(f_y^\varepsilon)$（$\varepsilon$ 尺度平均）的
协方差 $\sim-\log(|x-y|\vee\varepsilon)$ ——**对数相关场**，
这是二维 GFF 的指纹（一维是 $\min$ 相关 = 布朗桥）。

## 61.5 离散 GFF：有限图上的精确世界

把 $D$ 换成有限图 $G=(V,E)$ ，取定"钉住零"的边界 $\partial V$ 。
**离散 GFF** 是 $\{X_v:v\in V^\circ\}$ 的中心高斯，协方差 = **格林
函数** $G=L^{-1}$ （$L$ = pinned 图拉普拉斯：对角 $\deg v$ 、边
$-1$ ，边界点接地消去）：

$$E[X_uX_v]=G(u,v)\iff\ \text{密度}\ \propto\exp\Big(-\tfrac12\sum_{(u,v)\in E}w_{uv}(x_u-x_v)^2\Big)$$

（能量指数 = 离散 Dirichlet 能量——GFF 是"能量约束下最随机的场"，
最大熵高斯。）三个可精确结算的性质：

1. **协方差 = 格林函数**：$L\,G=I$ 是纯线性代数。路径图
   $V=\{1,\dots,n\}$ （端点 $0,n+1$ 接地）有闭式

   $$\boxed{\ G(i,j)=\frac{\min(i,j)\,\big(n+1-\max(i,j)\big)}{n+1}\ }$$

   ——一维离散 GFF 的协方差就是**布朗桥**的协方差
   $\min(i,j)-ij/(n+1)$ 加一条"地线"账：布朗运动桥与离散 GFF 在
   一维是同一个对象（第 60 章 $\min(s,t)$ 的有限差分版）。

2. **Markov 性（域独立性）**：给定环 $\Gamma$ 上的值，内部与外部
   条件独立——高斯条件化把能量二次型块对角化（第 36 章条件期望的
   高斯显式解）。有限图上这就是线性代数：Schur 补 $G_{II}-G_{I\Gamma}
   G_{\Gamma\Gamma}^{-1}G_{\Gamma I}$ 给条件协方差，精确可算。

3. **狄利克雷原理**：边界值给定时，内部的最可能构型（条件均值）
   = **调和延拓** = 离散能量 $\sum(x_u-x_v)^2$ 的最小化点——逐点
   均值方程 $\Delta u=0$ 。有限格子上可用消元精确求解，最大值原理
   （极值在边界）随解免费附赠。

## 61.6 乘性混沌：给场一个"体积"

对数相关的场没有点值，但可以造**随机测度**。形式上

$$d\mu_{h,D}(x)=e^{\gamma h(x)-\frac{\gamma^2}2E(x)}\,dx ,$$

其中补偿项抵消指数放大（书定义在定理 8.3.1 前：把 $h$ 用特征基
展开、$\mu$ 定义为部分和的极限）。合法化路径：对 $\varepsilon$ 尺度
的磨光场 $h_\varepsilon$ ，总质量

$$M_\varepsilon=\int_De^{\gamma h_\\varepsilon(x)-\frac{\gamma^2}2\mathrm{Var}(h_\varepsilon(x))}\,dx$$

满足 $E[M_\varepsilon]=1$ 对每个 $\varepsilon$ 成立（逐点：高斯矩
母函数 $Ee^{tZ}=e^{t^2\sigma^2/2}$ 与补偿项精确对消），且
$\{M_\varepsilon\}$ 随磨光变细是**正鞅**——极限测度存在且期望为 1
（次临界 $\gamma<\sqrt2$ 时非退化）。**定理 8.3.1**（书引文献
[24][25]，作者自己的研究线）：对光滑 Jordan 域 $U$ 中典型的 $z$ ，
混沌测度的球体积有几乎必然的幂律包络——小球的 $\mu$-质量按
$r$ 的一个由 $\gamma$ 决定的幂次衰减。这是 Liouville 量子引力
（LQG）度量的测度论起点：**Gauss 自由场 + 指数重整化 = 随机几何**。

机器通道不模拟极限，而是精确结算鞅的**均值账**：$\varepsilon$ 磨光
的方差 $=\sum_{k\le n}1/k$ （对数发散的另一面）与补偿项作为精确分数
逐项对消——"期望 1"在每一层截断上都是可判定的等式。

## 61.7 机器通道

### 61.7.1 Lean：格林函数恒等式的精确全证

本章 Lean 的主件是纯线性代数：路径图（$n=3$ 与 $n=4$ ）的 pinned
拉普拉斯 $L$ 与闭式格林矩阵
$G(i,j)=\min(i,j)(n{+}1-\max(i,j))/(n{+}1)$ 的恒等式 $L\cdot G=I$
用 `Matrix.mul` + `norm_num` 在 $\mathbb Q$ 上完全证明——"协方差 =
格林函数"的代数核心不带任何概率库依赖。`IsGaussianProcess` 与
`IsGaussianProcess` 协方差引理作为等距层的锚点登记。

### 61.7.2 Julia：离散 GFF 的采样对账

(1) 路径图（$n=8$ ）离散 GFF：对格林矩阵 $G$ 做 Cholesky 采样
$X=KZ$ （$K^\top K=G$ ，固定种子 $10^4$ 条），经验协方差与闭式
$G(i,j)$ 的逐项对账（容差按 $1/\sqrt{\text{样本数}}$ ）；(2) 布朗桥
身份：$X_i-\frac{i}{n+1}X_{n+1\text{ 线性组合}}$ 的协方差与桥公式
对照；(3) 对数相关场的鞅账：圆环模型 $h_n(\theta)=\sum_{k\le n}
(Z_{1k}\cos k\theta+Z_{2k}\sin k\theta)/\sqrt k$ 的总质量
$M_n=\frac1{2\pi}\int e^{\gamma h_n-\gamma^2H_n/2}$ 在
$\gamma\in\{0.5,1.0\}$ 、$n=30$ 的经验均值 vs 理论 1（鞅均值不变）。

### 61.7.3 Python：精确格林账与狄利克雷原理

`Fraction` 全程：(1) 路径图 $n=3..6$ 的 $L\cdot G=I$ 逐项判定、$G$
对称性、$\min$-$\max$ 闭式核对；(2) $4\times4$ 格子（内部
$2\t2$ ）狄利克雷问题：边界一角置 1 其余置 0，消元精确求解调和解，
验证逐点均值性与最大值原理（极值在边界）；(3) 鞅均值账：
$\mathrm{Var}(h_n)=H_n=\sum_{k\le n}1/k$ 的精确分数与补偿项逐层
对消判定。

### 61.7.4 Prolog：$4\times4$ 格子的调和解与最大值原理

同一狄利克雷问题在 Prolog 里重解：内部点均值方程写成线性方程组，
以 $rdiv$ 消元求解；解的唯一性用"两解之差在内部调和且边界为零
$\Rightarrow$ 最大值原理 $\Rightarrow$ 恒零"的有限穷举版（全部
$4^4$ 内部候选解空间中逐一检查：满足均值方程者恰一个）。条件独立
（Markov 性）的有限侧影：给定环值后内部均值 = 调和延拓的账目核对。

## 61.8 与全书的接口

- 第 13 章：$L^2$ 内积几何 → Gauss–Hilbert 空间；
- 第 36 章：高斯条件期望 = 线性回归 → GFF 的 Markov 性；
- 第 47 章：协方差算子的谱 → K-L/特征基；$\sum1/\lambda_i$ 的敛散
  = "是不是函数"的判据；
- 第 60 章：一维 GFF = 布朗桥；等距构造统一两章。

## 61.9 要点回顾

1. Gauss–Hilbert 空间 + 线性等距 $T$：布朗运动 = $T(\mathbf 1_{(0,t]})$ ，
   GFF = 同一台机器换能量空间 $H_0^1(D)$ 。
2. 平面 GFF 协方差 = 梯度内积；特征基 $f_i=e_i/\sqrt{-\lambda_i}$ 。
3. 谱账 $\sum1/\lambda_i$ 对数发散 ⟹ 二维 GFF 不是函数而是随机
   分布；对数相关是它的指纹。
4. 离散 GFF：协方差 = pinned 拉普拉斯的逆（格林函数）；路径图闭式
   与布朗桥同源；Markov 性 = 高斯条件化的 Schur 补。
5. 狄利克雷原理：条件均值 = 调和延拓 = 能量最小化（有限格子上
   精确可解）。
6. 乘性混沌 $e^{\gamma h-\gamma^2\mathrm{Var}/2}$：总质量是期望 1
   的正鞅（每层截断上均值账精确可判）；次临界极限给出 LQG 测度
   （书定理 8.3.1 的球体积幂律）。

*对应示例（可选）：`examples/lean/Measuretheory/Ch61GFF.lean`、
`examples/julia/61_gaussian_free_field.jl`、
`examples/python/61_gaussian_free_field.py`、
`examples/prolog/61_gaussian_free_field.pl`。*

---

上一章：[60 布朗运动：构造、反射与重对数律](60-brownian-motion.md) · 下一章：[62 全书速查表](62-cheatsheet.md)
