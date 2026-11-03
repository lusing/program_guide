# 第 27 章 中心极限定理：有限方差的特征函数证明

## 27.1 定理究竟说了什么

大数定律告诉我们，样本均值会靠近总体均值，却没有告诉我们偏差在 $1/\sqrt n$ 尺度上的形状。

中心极限定理补上的正是这一层。

设 $X_1,X_2,\ldots$ 独立同分布，记

$$
E[X_i]=\mu,\qquad \operatorname{Var}(X_i)=\sigma^2,
$$

并假设

$$
0<\sigma^2<\infty.
$$

令

$$
S_n=\sum_{i=1}^nX_i,
\qquad
Z_n=\frac{S_n-n\mu}{\sigma\sqrt n}.
$$

则对标准正态变量 $Z$，有

$$
\boxed{Z_n\xrightarrow{d}N(0,1).}
$$

等价地，对每个 $x\in\mathbb R$，

$$
P(Z_n\le x)\longrightarrow \Phi(x),
$$

其中

$$
\Phi(x)=\int_{-\infty}^x\frac1{\sqrt{2\pi}}e^{-u^2/2}\,du.
$$

这里只要求有限方差。

不要求密度存在，不要求分布对称，不要求矩生成函数存在，也不要求三阶矩存在。

Bernoulli、离散均匀、连续均匀、指数分布，以及只有二阶矩的某些重尾分布，都在定理覆盖范围内。

Cauchy 分布不在其中，因为它连一阶矩都没有。

若 $\sigma^2=0$，每个 $X_i$ 几乎必然等于常数，标准化分母为零；这个退化情形应单独处理，而不是硬套公式。

## 27.2 为什么偏偏除以 $\sqrt n$

独立性给出

$$
\operatorname{Var}(S_n)=n\sigma^2.
$$

因此 $S_n-n\mu$ 的典型尺度是 $\sigma\sqrt n$。

除以这个尺度后，

$$
E[Z_n]=0,
\qquad
\operatorname{Var}(Z_n)=1.
$$

如果除以 $n$，得到的是大数定律中的 $\bar X_n-\mu$，其方差为 $\sigma^2/n$，会缩到零。

如果只除以常数，方差会随 $n$ 发散。

$\sqrt n$ 是同时保持均值和方差非退化的尺度。

Lean 中把这一账写成可检查的有理数恒等式：

```lean
theorem mean_variance (s N : ℚ) (hN : N ≠ 0) :
    s ^ 2 * N / N ^ 2 = s ^ 2 / N := by
  field_simp
```

这里没有证明方差可加性本身；那一事实来自独立性。

Lean 验证的是一旦独立和方差为 $N\sigma^2$，再除以 $N^2$ 后的代数结果。

标准化与还原的关系也有精确锚：

```lean
theorem standardize_scale (x μ σ : ℚ) (hσ : σ ≠ 0) :
    (x - μ) / σ * σ = x - μ := by
  field_simp
```

非零假设不是形式化装饰：标准差为零时根本不能这样标准化。

## 27.3 为什么用特征函数，而不是矩生成函数

随机变量 $Y$ 的特征函数定义为

$$
\phi_Y(t)=E[e^{itY}],
\qquad t\in\mathbb R.
$$

因为 $|e^{itY}|=1$，期望总存在。

这与矩生成函数 $M_Y(s)=E[e^{sY}]$ 很不同。

矩生成函数可能在任何含零的开区间外都发散；特征函数却始终有定义。

所以，用特征函数证明 CLT，可以把假设降到本定理所需要的有限二阶矩，而不是额外要求指数矩。

证明路线有四步：

1. 在零点附近展开单个标准化变量的特征函数；
2. 用独立性把 $n$ 个变量的和变成特征函数的乘积；
3. 计算乘积极限，得到 $e^{-t^2/2}$；
4. 用 Lévy 连续性定理，把特征函数收敛翻译为依分布收敛。

第 28 章会系统证明第 4 步所依赖的 Fourier 工具。

本章先把它作为明确的接口使用，而不是把这一步藏在“显然”二字里。

## 27.4 有限二阶矩给出的二阶展开

先令

$$
Y_i=\frac{X_i-\mu}{\sigma}.
$$

于是

$$
E[Y_i]=0,\qquad E[Y_i^2]=1.
$$

固定实数 $u$，对 $e^{iuY}$ 作二阶 Taylor 展开：

$$
e^{iuY}=1+iuY-\frac{u^2Y^2}{2}+R(uY).
$$

取期望得

$$
\phi_Y(u)
=1+iuE[Y]-\frac{u^2}{2}E[Y^2]+E[R(uY)].
$$

利用标准化后的两阶矩，

$$
\phi_Y(u)=1-\frac{u^2}{2}+E[R(uY)].
$$

关键是：没有三阶矩时，为什么余项仍是 $o(u^2)$？

对实数 $x$，Taylor 积分余项给出可用的估计

$$
|R(x)|\le \min\left\{\frac{|x|^3}{6},x^2\right\}.
$$

因此

$$
\frac{|E[R(uY)]|}{u^2}
\le
E\left[
Y^2\min\left\{\frac{|u|\,|Y|}{6},1\right\}
\right].
$$

期望内的随机变量满足两条性质：

- 当 $u\to0$ 时，它逐点趋于零；
- 它被可积随机变量 $Y^2$ 控制。

由控制收敛定理，整个期望趋于零。

所以

$$
\boxed{
\phi_Y(u)=1-\frac{u^2}{2}+o(u^2)
\quad(u\to0).
}
$$

这一步是有限方差证明的核心。

如果只写 $|R(uY)|\le |uY|^3/6$，就会被迫要求 $E|Y|^3<\infty$；采用两条界的最小值，才避免了这条多余假设。

## 27.5 独立和为什么变成乘积

由 $S_n-n\mu=\sigma\sum_{i=1}^nY_i$，得

$$
Z_n=\frac1{\sqrt n}\sum_{i=1}^nY_i.
$$

因此

$$
\begin{aligned}
\phi_{Z_n}(t)
&=E\left[\exp\left(\frac{it}{\sqrt n}\sum_{j=1}^nY_j\right)\right]\\
&=E\left[\prod_{j=1}^n e^{itY_j/\sqrt n}\right]\\
&=\prod_{j=1}^nE[e^{itY_j/\sqrt n}]\\
&=\left[\phi_Y(t/\sqrt n)\right]^n.
\end{aligned}
$$

第三行使用独立性，第四行使用同分布。

代入上一节的展开：

$$
\phi_Y(t/\sqrt n)
=1-\frac{t^2}{2n}+o(1/n).
$$

于是

$$
\phi_{Z_n}(t)
=\left(1-\frac{t^2}{2n}+o(1/n)\right)^n.
$$

固定 $t$，令

$$
a_n=-\frac{t^2}{2n}+o(1/n).
$$

则 $n a_n\to-t^2/2$。

当 $n$ 足够大时，$1+a_n$ 落在复对数主支的定义域内，并且

$$
n\log(1+a_n)
=n a_n+O(n|a_n|^2)
\longrightarrow-\frac{t^2}{2}.
$$

取指数得到

$$
\boxed{
\phi_{Z_n}(t)\longrightarrow e^{-t^2/2}.
}
$$

注意这里先固定 $t$，再令 $n\to\infty$。

不能把 $t$ 也允许随 $n$ 任意增长，却仍照搬同一个余项结论。

Python 直接检查这个极限乘积的实数主项：

```python
for t in (0.5, 1.0):
    target = exp(-t * t / 2)
    values = [(1 - t * t / (2 * n)) ** n for n in (10, 100, 10_000)]
    errors = [abs(value - target) for value in values]
    assert errors[0] > errors[1] > errors[2]
    assert errors[-1] < 1e-5
```

这只是对数值极限的审计；一般证明中的 $o(1/n)$ 仍来自上一节的概率论证。

## 27.6 从特征函数极限到分布极限

标准正态的特征函数是

$$
E[e^{itZ}]=e^{-t^2/2}.
$$

我们已经得到

$$
\phi_{Z_n}(t)\to e^{-t^2/2}
\qquad\text{对每个固定的 }t.
$$

Lévy 连续性定理说：若一列概率分布的特征函数逐点收敛，并且极限函数在 $0$ 连续，那么这列分布依分布收敛到以该极限函数为特征函数的概率分布。

这里 $e^{-t^2/2}$ 显然在 $0$ 连续，所以

$$
Z_n\xrightarrow{d}N(0,1).
$$

证明至此完成。

整个论证没有使用矩生成函数，也没有使用所有阶矩。

“特征函数逐点收敛”本身还必须配上极限在零点的连续性；第 28 章会解释这个条件如何防止概率质量逃到无穷远。

## 27.7 一个完全展开的特例：Poisson

设 $X_\lambda\sim\operatorname{Poisson}(\lambda)$，则

$$
E[e^{itX_\lambda}]
=\exp\{\lambda(e^{it}-1)\}.
$$

标准化变量为

$$
Z_\lambda=\frac{X_\lambda-\lambda}{\sqrt\lambda}.
$$

其特征函数是

$$
\phi_{Z_\lambda}(t)
=e^{-it\sqrt\lambda}
\exp\{\lambda(e^{it/\sqrt\lambda}-1)\}.
$$

取对数，指数部分化为

$$
\lambda\left(e^{it/\sqrt\lambda}-1-\frac{it}{\sqrt\lambda}\right).
$$

展开到二阶：

$$
e^{iu}-1-iu=-\frac{u^2}{2}+O(u^3).
$$

令 $u=t/\sqrt\lambda$，得

$$
\log\phi_{Z_\lambda}(t)
=-\frac{t^2}{2}+O(\lambda^{-1/2}).
$$

所以 $\phi_{Z_\lambda}(t)\to e^{-t^2/2}$。

Python 使用以下公共定义；`erf` 来自标准库 `math`，不依赖外部数据：

```python
import cmath
from math import comb, erf, exp, pi, sqrt

def normal_cdf(x):
    return (1 + erf(x / sqrt(2))) / 2

def normal_pdf(x):
    return exp(-x * x / 2) / sqrt(2 * pi)
```

随后保留 Poisson 的完整复数表达式，而不是只比较实部：

```python
def poisson_standardized_cf(t, lam):
    """Z=(X-lam)/sqrt(lam) 的特征函数，X~Poisson(lam)。"""
    u = t / sqrt(lam)
    return cmath.exp(-1j * t * sqrt(lam)) * cmath.exp(
        lam * (cmath.exp(1j * u) - 1))
```

随后对 $\lambda=5,50,500$ 计算到 $e^{-t^2/2}$ 的复数距离：

```python
values = [poisson_standardized_cf(t, lam) for lam in (5, 50, 500)]
errors = [abs(value - target) for value in values]
assert errors[0] > errors[1] > errors[2]
assert errors[-1] < 0.006
```

这是一项精确的闭式函数求值，不是模拟。

它展示的是 Poisson 参数趋于无穷时的正态近似，也与一般 iid CLT 使用同一个二阶展开骨架。

## 27.8 三种分布的有限样本形态

Julia 单元对均匀、指数和骰子分布分别生成标准化和：

```julia
z = [(sum(sampler() for _ in 1:n) - n * mu) /
     (sigma * sqrt(n)) for _ in 1:reps]
```

这里 `mu` 和 `sigma` 是单个分量的理论均值与标准差，不是从同一批模拟结果再估计出来的数。

正态区间概率用 Simpson 积分直接计算：

```julia
function normal_bucket(lo, hi; steps=400)
    h = (hi - lo) / steps
    total = exp(-lo^2 / 2) + exp(-hi^2 / 2)
    for i in 1:steps-1
        x = lo + i * h
        total += (isodd(i) ? 4 : 2) * exp(-x^2 / 2)
    end
    total * h / (3 * sqrt(2 * pi))
end
```

然后比较四个固定区间上的经验频率：

```julia
empirical = count(x -> lo <= x < hi, z) / reps
@assert abs(empirical - normal_bucket(lo, hi)) < 0.015
```

随机种子固定为 `27`，所以结果可复现。

但这些断言只检查有限 $n$、有限区间和有限次重复。

它们不是 CLT 的证明，也不能凭“图形像钟形”推出逐点特征函数极限。

## 27.9 离散分布的连续性修正

设 $S\sim\operatorname{Bin}(n,p)$，要近似

$$
P(a\le S\le b),
$$

其中 $a,b$ 是整数。

整数 $a$ 到 $b$ 对应的实数桶是

$$
[a-\tfrac12,b+\tfrac12].
$$

所以应使用

$$
P(a\le S\le b)
\approx
\Phi\left(\frac{b+1/2-np}{\sqrt{np(1-p)}}\right)
-
\Phi\left(\frac{a-1/2-np}{\sqrt{np(1-p)}}\right).
$$

若直接用 $a,b$ 作为正态端点，就把两侧各半格的质量错误地删掉了。

Python 对 $S\sim\operatorname{Bin}(100,1/2)$ 精确求和：

```python
exact = sum(comb(100, k) for k in range(45, 56)) / 2 ** 100
raw = normal_cdf(1.0) - normal_cdf(-1.0)
corrected = normal_cdf(1.1) - normal_cdf(-1.1)
assert abs(corrected - exact) < abs(raw - exact)
```

这里 $np=50$，标准差为 $5$，所以原始端点是 $\pm1$，修正后是 $\pm1.1$。

连续性修正改善的是格点离散化误差，不会消除偏态、重尾或高阶项造成的误差。

## 27.10 单点概率与格距

若整数格点分布的标准差为 $\tau$，在中心附近，局部正态近似通常要写成

$$
P(S=k)\approx \frac{h}{\tau}
\varphi\left(\frac{k-m}{\tau}\right),
$$

其中 $h$ 是相邻可达点之间的距离，$\varphi$ 是标准正态密度。

因子 $h$ 表示一个离散点所代表的实数桶宽。

普通 Bernoulli 和的可达点是连续整数，$h=1$。

对称 $\pm1$ 随机游走在固定步数后只落在同奇偶性的格点上，相邻可达点距离为 $h=2$。

Python 对两种情况分别对账：

```python
center = comb(100, 50) / 2 ** 100
local = normal_pdf(0) / 5
assert abs(center / local - 1) < 0.003

walk_center = comb(200, 100) / 2 ** 200
walk_local = 2 * normal_pdf(0) / sqrt(200)
assert abs(walk_center / walk_local - 1) < 0.0015
```

若对 $\pm1$ 游走漏掉因子 $2$，近似值会恰好几近减半。

Lean 用整数恒等式固定这个格距：

```lean
example (k : ℤ) : (2 * k + 2) - 2 * k = 2 := by ring
```

区间概率使用连续性修正，单点概率使用格距；两者来自同一个“把离散点还原为实数桶”的思想。

## 27.11 误差、偏态与使用边界

CLT 是极限定理，不提供某个固定 $n$ 的统一误差数值。

若再假设 $E|X-\mu|^3<\infty$，Berry–Esseen 定理给出 Kolmogorov 距离的上界，量级为

$$
\frac{E|X-\mu|^3}{\sigma^3\sqrt n}.
$$

因此偏态越强、标准化三阶绝对矩越大，有限样本近似往往越差。

常见的“$n\ge30$”只是经验提醒，不是定理中的万能阈值。

对高度偏态、罕见事件或极端尾部概率，正态近似可能在中心尚可，却在尾部严重失真。

对格点分布还要加连续性修正或格距。

对 $\sigma^2=\infty$ 的分布，有限方差 CLT 根本不适用；某些重尾分布经别的标准化会收敛到非 Gaussian 稳定律。

## 27.12 机器通道的证据分工

本章有四类验证。

- Lean 验证标准化、方差尺度、Taylor 系数和格距的精确代数；
- Isabelle 的 `MT27/T27_CLT.thy` 验证有限两点分布与骰子方差的测度论积分账；
- Python 计算 Poisson 复特征函数、精确二项概率和两种格距；
- Julia 用固定种子检查三类有限样本标准化和。

这些通道互补，但证据等级不同。

代数证明可以无条件复用，精确枚举可以复算具体概率，固定种子模拟只提供数值审计。

完整示例分别为 `examples/lean/Probability/Ch27CLT.lean`、`examples/isabelle/MT27/T27_CLT.thy`、`examples/python/27_clt.py` 和 `examples/julia/27_clt.jl`。

## 27.13 本章要点

1. iid、均值存在且 $0<\sigma^2<\infty$，就有标准化和的 Gaussian 极限。
2. $\sqrt n$ 来自方差为 $n\sigma^2$，不是凭经验选择的标准化。
3. 有限二阶矩给出 $\phi_Y(u)=1-u^2/2+o(u^2)$，不需要三阶矩。
4. 独立性把特征函数变成乘积，极限为 $e^{-t^2/2}$。
5. Lévy 连续性定理完成从特征函数到分布的最后一步。
6. 连续性修正和格距处理离散化误差；它们不修复重尾或模型误设。
7. 数值实验展示有限样本形态，但不替代极限证明。

---

上一章：[26 大数定律与 Monte Carlo](26-lln.md) · 下一章：[28 Fourier 分析与特征函数](28-fourier-clt.md)
