# 第 28 章 Fourier 分析与特征函数

## 28.1 把分布放到频率域

第 27 章把 CLT 的证明压缩成一句特征函数极限：

$$
\phi_{Z_n}(t)\to e^{-t^2/2}.
$$

本章补齐这句话背后的分析工具。

对实随机变量 $X$ ，定义

$$
\boxed{\phi_X(t)=E[e^{itX}],\qquad t\in\mathbb R.}
$$

若 $X$ 有密度 $f$ ，则

$$
\phi_X(t)=\int_{-\infty}^{\infty}e^{itx}f(x)\,dx.
$$

若 $X$ 是离散变量，则

$$
\phi_X(t)=\sum_x e^{itx}P(X=x).
$$

特征函数是分布的 Fourier 变换。

它不是对某一条样本路径作变换，而是对整个概率分布作变换。

由于

$$
|e^{itX}|=1,
$$

特征函数对每个实随机变量、每个实数 $t$ 都存在，并且

$$
|\phi_X(t)|\le E|e^{itX}|=1.
$$

这正是它比矩生成函数更适合一般分布的原因。

## 28.2 核函数 $e^{itx}$ 在做什么

Euler 公式给出

$$
e^{itx}=\cos(tx)+i\sin(tx).
$$

所以

$$
\phi_X(t)=E[\cos(tX)]+iE[\sin(tX)].
$$

固定 $t$ 时，$e^{itx}$ 是 $x$ 的周期波。

$E[e^{itX}]$ 测量分布在这个频率上的复振幅。

若分布关于零对称，则 $\sin(tX)$ 的期望为零，特征函数为实值。

一般情况下虚部不能随意丢掉，因为它记录分布的位置与不对称性。

例如 $X+a$ 的特征函数为

$$
\phi_{X+a}(t)=e^{ita}\phi_X(t).
$$

平移只改变相位，不改变模长。

尺度变换满足

$$
\phi_{aX}(t)=\phi_X(at).
$$

此外

$$
\phi_X(0)=1,
\qquad
\phi_X(-t)=\overline{\phi_X(t)}.
$$

这些基本性质常用于检查闭式公式是否写错。

## 28.3 连续性、矩与原点展开

由 $|e^{itX}|=1$ 和控制收敛定理，

$$
t\mapsto\phi_X(t)
$$

在全实线上连续，实际上还是一致连续的。

若 $E|X|<\infty$ ，可以对期望求导：

$$
\phi_X'(0)=iE[X].
$$

若 $E[X^2]<\infty$ ，则

$$
\phi_X''(0)=-E[X^2].
$$

一般地，若 $E|X|^k<\infty$ ，则

$$
\phi_X^{(k)}(0)=i^kE[X^k].
$$

导数公式反过来也提醒我们：没有相应矩时，不能机械地对特征函数反复求导。

Cauchy 分布的特征函数是 $e^{-|t|}$ ，它在零点左右导数不相等，正对应均值不存在。

有限方差下最重要的展开是

$$
\phi_X(t)
=1+itE[X]-\frac{t^2}{2}E[X^2]+o(t^2).
$$

第 27 章已经用积分余项和控制收敛证明了这一点。

特征函数把“均值与二阶矩”翻译成“原点处的一阶与二阶系数”。

## 28.4 常见分布的特征函数

下面六个公式覆盖了本书反复出现的模型。

### 点质量

若 $P(X=a)=1$ ，则

$$
\phi_X(t)=e^{iat}.
$$

其模恒为 $1$ ，说明全部质量集中在一个相位轨道上。

### Bernoulli

若 $P(X=1)=p$ 、$P(X=0)=1-p$ ，则

$$
\phi_X(t)=1-p+pe^{it}.
$$

二项分布 $\operatorname{Bin}(n,p)$ 是 $n$ 个独立 Bernoulli 之和，所以

$$
\phi(t)=(1-p+pe^{it})^n.
$$

### Poisson

若 $X\sim\operatorname{Poisson}(\lambda)$ ，则

$$
\begin{aligned}
\phi_X(t)
&=\sum_{k=0}^{\infty}e^{itk}e^{-\lambda}\frac{\lambda^k}{k!}\\
&=\exp\{\lambda(e^{it}-1)\}.
\end{aligned}
$$

### 均匀分布

若 $X\sim U(0,1)$ ，则

$$
\phi_X(t)
=\int_0^1e^{itx}\,dx
=\frac{e^{it}-1}{it}.
$$

也可写成

$$
\phi_X(t)=e^{it/2}\frac{\sin(t/2)}{t/2},
$$

其中 $t=0$ 处按连续极限取 $1$ 。

### 指数分布

若 $X$ 的密度为 $\lambda e^{-\lambda x}\mathbf1_{x\ge0}$ ，则

$$
\boxed{\phi_X(t)=\frac1{1-it/\lambda}.}
$$

这里 $\lambda$ 是 rate。

写成 $1/(1-i\lambda t)$ 会把 rate 与 scale 混淆。

Python 用模长公式检查参数位置：

```python
phi_exp = 1 / (1 - 1j * t / rate)
assert abs(abs(phi_exp) - 1 / sqrt(1 + (t / rate) ** 2)) < 1e-12
```

### 正态与 Cauchy

标准正态为

$$
\phi_Z(t)=e^{-t^2/2}.
$$

标准 Cauchy 为

$$
\phi_C(t)=e^{-|t|}.
$$

两者模长都随 $|t|$ 衰减，但原点附近的正则性完全不同。

## 28.5 Gaussian 的自反性

标准正态密度为

$$
f(x)=\frac1{\sqrt{2\pi}}e^{-x^2/2}.
$$

其特征函数可以用微分方程简洁地推导。

先写

$$
\phi(t)=\int_{\mathbb R}e^{itx}f(x)\,dx.
$$

对 $t$ 求导，再对 $xf(x)=-f'(x)$ 使用分部积分：

$$
\begin{aligned}
\phi'(t)
&=\int ix e^{itx}f(x)\,dx\\
&=-i\int e^{itx}f'(x)\,dx\\
&=-t\phi(t).
\end{aligned}
$$

结合 $\phi(0)=1$ ，得到

$$
\phi(t)=e^{-t^2/2}.
$$

所以非归一化函数 $e^{-x^2/2}$ 的 Fourier 形状仍是 $e^{-t^2/2}$ 。

这就是 Gaussian 的自反性。

但“形状相同”不代表任何 Fourier 约定下系数都相同。

本教程采用

$$
\widehat f(t)=\int e^{itx}f(x)\,dx,
\qquad
f(x)=\frac1{2\pi}\int e^{-itx}\widehat f(t)\,dt.
$$

若使用角频率或单位化 Fourier 变换，$2\pi$ 的位置会改变；推导时必须固定约定。

## 28.6 独立和：卷积变成乘法

设 $X,Y$ 独立，$S=X+Y$ 。

则

$$
\begin{aligned}
\phi_S(t)
&=E[e^{it(X+Y)}]\\
&=E[e^{itX}e^{itY}]\\
&=E[e^{itX}]E[e^{itY}]\\
&=\phi_X(t)\phi_Y(t).
\end{aligned}
$$

在密度语言中，$X+Y$ 的密度是卷积

$$
f_{X+Y}(s)=\int f_X(x)f_Y(s-x)\,dx.
$$

所以上式就是 Fourier 分析的卷积定理：

$$
\boxed{\widehat{f_X*f_Y}=\widehat f_X\,\widehat f_Y.}
$$

这条性质解释了为什么独立和在原空间中可能很复杂，在频率域中却只是普通乘法。

两个独立 $U(0,1)$ 的和具有三角密度

$$
f(s)=
\begin{cases}
s,&0\le s\le1,\\
2-s,&1<s\le2,\\
0,&\text{其他}.
\end{cases}
$$

Python 对这个密度直接积分，并与均匀特征函数平方的实部比较：

```python
tri = lambda x: x if 0 <= x <= 1 else (2 - x if 1 < x <= 2 else 0.0)
lhs = simpson(lambda x: cos(t * x) * tri(x), 0, 2, 4000)
h = t / 2
sinc = sin(h) / h
rhs = cos(t) * sinc ** 2
assert abs(lhs - rhs) < 1e-9
```

这里只比较实部，因为三角密度关于 $1$ 对称，但关于 $0$ 并不对称，完整特征函数仍有相位 $e^{it}$ 。

## 28.7 Fourier 反演：从频率回到密度

若 $X$ 有密度 $f$ ，且 $\phi_X$ 在实线上可积，则 $f$ 可取连续版本，并满足

$$
\boxed{
f(x)=\frac1{2\pi}\int_{-\infty}^{\infty}e^{-itx}\phi_X(t)\,dt.
}
$$

指数符号与正向变换相反，外面的 $1/(2\pi)$ 来自本教程的 Fourier 约定。

对标准正态，$\phi(t)=e^{-t^2/2}$ 可积，反演公式直接成立。

Python 在截断区间 $[-20,20]$ 上数值积分。所用的 Simpson 求积器和正态密度为：

```python
def simpson(f, a, b, n):
    h = (b - a) / n
    s = f(a) + f(b)
    for i in range(1, n):
        s += (4 if i % 2 else 2) * f(a + i * h)
    return s * h / 3

pdf_norm = lambda x: exp(-x * x / 2) / sqrt(2 * pi)
```

`n` 必须为偶数；本章所有调用都取 `4000`。反演检查是：

```python
inverted = simpson(
    lambda t: cos(t * x) * exp(-t * t / 2) / (2 * pi),
    -20, 20, 4000)
assert abs(inverted - pdf_norm(x)) < 1e-9
```

正态密度和特征函数都是实偶函数，所以正弦部分的积分为零，代码只保留余弦项。

一般复特征函数不能随意这样省略虚部。

数值反演还要注意截断误差与振荡误差：截断区间控制遗漏的尾部，积分网格控制振荡波形的解析精度。

## 28.8 没有可积特征函数时怎么办

许多分布的特征函数并不绝对可积。

例如 $U(0,1)$ 的特征函数只有 $1/|t|$ 量级衰减，Cauchy 的 $e^{-|t|}$ 则可积，但对应密度公式需要按上述反演计算。

对一般分布函数 $F$ ，可以使用区间反演公式。

若 $a<b$ 且 $a,b$ 都是 $F$ 的连续点，则

$$
F(b)-F(a)
=
\lim_{T\to\infty}
\frac1{2\pi}
\int_{-T}^{T}
\frac{e^{-ita}-e^{-itb}}{it}
\phi(t)\,dt.
$$

端点排除原子是为了避免半质量归属问题。

在单点 $a$ ，还可通过平均小区间恢复原子质量：

$$
P(X=a)
=
\lim_{T\to\infty}\frac1{2T}
\int_{-T}^{T}e^{-ita}\phi(t)\,dt.
$$

例如点质量 $a$ 的特征函数为 $e^{iat}$ ，代入后积分为 $2T$ ，结果恰为 $1$ 。

这些公式说明：即便没有普通密度，特征函数仍保留足够信息恢复分布。

## 28.9 唯一性定理

**若两个概率分布的特征函数处处相等，则两个分布相同。**

理由可以从区间反演公式看出。

对所有连续点 $a<b$ ，区间概率都由同一个 $\phi$ 决定。

分布函数的连续点在实线上稠密，而分布函数右连续，所以所有点的 $F(x)$ 都被决定。

于是两个分布函数处处相等。

唯一性是很多特征函数证明的终点。

如果算出某变量的特征函数为 $e^{-t^2/2}$ ，就不必再寻找其他可能分布：它只能是标准正态。

同样，若独立和的特征函数等于某个已知分布的特征函数，就可以识别独立和的分布。

## 28.10 Lévy 连续性定理

设 $X_n$ 的特征函数为 $\phi_n$ 。

若对每个 $t$ ，

$$
\phi_n(t)\to\phi(t),
$$

并且 $\phi$ 在 $0$ 连续，则存在随机变量 $X$ ，使得

$$
X_n\xrightarrow{d}X,
\qquad
\phi_X=\phi.
$$

反向也成立：若 $X_n\xrightarrow{d}X$ ，则由有界连续函数期望的定义，

$$
\phi_n(t)=E[e^{itX_n}]
\to E[e^{itX}]=\phi_X(t).
$$

因此特征函数提供了一套与依分布收敛相匹配的频率语言。

极限在零点的连续性不可省略。

逐点收敛本身可能允许质量向无穷远逃逸；零点连续性排除了这种逃逸，并使极限成为真正的概率分布特征函数。

证明思路是先用零点附近的连续性控制尾部，得到 tightness，再提取依分布收敛子列，最后用唯一性识别所有子列极限。

第 27 章中，极限 $e^{-t^2/2}$ 在零点连续，所以 CLT 的最后一步完全合法。

## 28.11 连续映射与测试函数

依分布收敛的定义是：对所有有界连续函数 $h$ ，

$$
E[h(X_n)]\to E[h(X)].
$$

对每个固定 $t$ ，函数

$$
x\mapsto e^{itx}
$$

正是有界连续函数，只是取复值。

分别考虑实部和虚部即可。

所以依分布收敛立即推出特征函数逐点收敛。

难的是反向：仅靠这一族三角测试函数，是否足以推出所有有界连续测试函数的收敛？

Lévy 连续性定理给出肯定回答，但前提是极限在零点连续。

这也是 Fourier 方法在概率论中强大的原因：它把无限多个分布问题转化为可计算的复函数问题，同时保留恢复分布的能力。

## 28.12 Cauchy 稳定性：没有矩也有严格规律

设 $C_1,C_2$ 独立标准 Cauchy，则

$$
\phi_{C_1+C_2}(t)
=e^{-|t|}e^{-|t|}
=e^{-2|t|}.
$$

右边是 $2C$ 的特征函数，所以

$$
C_1+C_2\overset d=2C.
$$

进一步，

$$
\frac{C_1+C_2}{2}\overset d=C.
$$

归纳可得，iid Cauchy 样本均值仍与单个 Cauchy 同分布。

这解释了为什么增大样本量不会让 Cauchy 样本均值收紧。

Python 检查特征函数代数：

```python
phi_half = exp(-abs(t / 2)) ** 2
assert abs(phi_half - exp(-abs(t))) < 1e-12
```

Julia 还直接生成 Cauchy 变量，并估计 $100$ 个样本均值的特征函数：

```julia
Cbar = [sum(cauchy() for _ in 1:100) / 100 for _ in 1:200_000]
@assert abs(ecf(Cbar, t) - exp(-abs(t))) < 0.015
```

这里固定种子的结果是对稳定性公式的数值复核，不是大数定律失败的证明；真正的证明就是上面的特征函数恒等式。

## 28.13 为什么 Cauchy 的特征函数反而容易模拟

Cauchy 原始样本具有极重尾，估计 $E[C]$ 根本没有意义。

但对固定 $t$ ，

$$
\cos(tC),\qquad \sin(tC)
$$

都被限制在 $[-1,1]$ 。

因此经验特征函数

$$
\widehat\phi_n(t)=\frac1n\sum_{j=1}^n e^{itC_j}
$$

始终是有界随机变量的平均，方差至多按 $1/n$ 缩小。

Python 和 Julia 都利用这一点，用大量 Cauchy 样本估计 $e^{-|t|}$ 。

重尾并不妨碍有界变换后的 Monte Carlo。

相反，若直接对未变换的 Cauchy 样本求平均，就不会得到同样的稳定性。

## 28.14 两条数值通道的分工

Python 侧重闭式与确定性积分：

- Simpson 积分核对正态特征函数；
- Fourier 反演恢复正态密度；
- 检查指数分布 rate 参数的位置；
- 检查 Cauchy 稳定性与均匀卷积乘法；
- 用有界三角函数 Monte Carlo 估计 Cauchy 特征函数。

Julia 侧重复数经验特征函数：

```julia
ecf(Z, t) = sum(exp(im * t * z) for z in Z) / length(Z)
```

对正态、均匀和 Cauchy 样本，`ecf` 同时保留实部和虚部。

随后把它用于标准化指数和、Cauchy 平均与 Box–Muller 正态样本。

所有随机实验固定种子为 `28`。

完整代码在 `examples/python/28_fourier_clt.py` 与 `examples/julia/28_fourier_clt.jl`；正文已经解释了其中的核心公式与数值对象，不需要脱离正文阅读源码。

## 28.15 本章要点

1. 特征函数对所有实随机变量存在，模长不超过 $1$ 。
2. 有限矩对应原点的导数；没有矩时不能机械求导。
3. 独立和在分布空间是卷积，在频率空间是乘法。
4. Gaussian 的自反性来自微分方程 $\phi'=-t\phi$ 。
5. 反演公式恢复密度、区间概率和原子，因而推出唯一性。
6. Lévy 连续性定理把特征函数极限翻译为依分布收敛。
7. Cauchy 稳定性说明重尾分布可以有严格的独立和规律，却不服从普通大数定律或有限方差 CLT。
8. 数值积分与模拟只核验具体公式；唯一性和连续性定理才是分布结论的依据。

---

上一章：[27 中心极限定理](27-clt.md) · 下一章：[29 渐近拼接工具](29-asymptotic-tools.md)
