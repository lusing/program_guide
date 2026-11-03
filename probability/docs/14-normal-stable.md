# 14 正态、对数正态、柯西与稳定分布

正态、对数正态和 Cauchy 代表三种完全不同的尾部世界。正态的指数平方衰减使所有矩和 MGF 都存在；对数正态有所有阶矩，却没有原点右侧的 MGF；Cauchy 连均值都不存在。把它们放在一起，可以避免把“钟形”“厚尾”“稳定”混成同义词。

本章还区分两种稳定性：一个分布族在线性变换下封闭，与独立同分布之和在适当标准化后保持同一分布，不是同一件事。后者才是严格稳定分布的含义。

## 14.1 正态密度与归一化

若 $\mu\in\mathbb R$、$\sigma>0$，正态分布 $N(\mu,\sigma^2)$ 的密度为

$$
f(x)=\frac1{\sqrt{2\pi\sigma^2}}
\exp\left(-\frac{(x-\mu)^2}{2\sigma^2}\right).
$$

先考虑标准正态

$$
\varphi(x)=\frac1{\sqrt{2\pi}}e^{-x^2/2}.
$$

要证明归一化常数，令

$$
I=\int_{-\infty}^{\infty}e^{-x^2/2}\,dx.
$$

被积函数为正，可以把 $I^2$ 写成平面上的二重积分：

$$
I^2=\iint_{\mathbb R^2}e^{-(x^2+y^2)/2}\,dx\,dy.
$$

改用极坐标，面积元为 $r\,dr\,d\theta$，所以

$$
I^2=\int_0^{2\pi}\int_0^\infty e^{-r^2/2}r\,dr\,d\theta
=2\pi[-e^{-r^2/2}]_0^\infty=2\pi.
$$

因为 $I>0$，故 $I=\sqrt{2\pi}$。这里 Jacobian 中的 $r$ 使径向积分具有初等原函数，这是极坐标方法有效的关键。

Python 文件 `examples/python/14_normal_stable.py` 不只用大矩形逼近这个等式，还直接审计径向原函数：

```python
for R in (3.0, 5.0):
    polar = 2 * pi * simpson(
        lambda r: exp(-r * r / 2) / (2 * pi) * r,
        0, R, 4000)
    assert abs(polar - (1 - exp(-R * R / 2))) < 1e-9
```

有限半径圆盘外的质量恰为 $e^{-R^2/2}$，所以截断误差有解析表达，而不是“窗口看起来够大”。

## 14.2 标准化、矩与经验区间

若 $Z\sim N(0,1)$，则

$$
X=\mu+\sigma Z\sim N(\mu,\sigma^2).
$$

反之 $Z=(X-\mu)/\sigma$。标准正态关于 0 对称，所以所有存在的奇数阶中心矩均为 0。由分部积分，

$$
E[Z^{2m}]=(2m-1)E[Z^{2m-2}],
$$

从而

$$
E[Z^{2m}]=(2m-1)!!,
\qquad m=0,1,2,\ldots.
$$

前几项为 $1,1,3,15,105,945$。第 16 章会用对尺度参数求导再次得到这条链。

常用区间概率为

$$
P(|Z|\le1)\approx0.6827,
$$

$$
P(|Z|\le2)\approx0.9545,
\qquad
P(|Z|\le3)\approx0.9973.
$$

这些是数值积分结果，不是恰好等于 68%、95%、99.7% 的定义。Python 代码同时检查归一化、均值、方差和双阶乘：

```python
M = 1.0
for m in range(1, 7):
    val = simpson(lambda t: t ** (2 * m) * phi(t), -12, 12, 6000)
    M *= (2 * m - 1)
    assert abs(val - M) < 1e-5 * M
```

正态尾部使 $[-12,12]$ 外的这些矩贡献极小，但偶矩证明仍来自递推，不来自数值网格。

## 14.3 正态的独立和稳定性

设 $X\sim N(\mu_X,\sigma_X^2)$、$Y\sim N(\mu_Y,\sigma_Y^2)$ 且独立，则

$$
X+Y\sim N(\mu_X+\mu_Y,\sigma_X^2+\sigma_Y^2).
$$

先看两个独立标准正态。其和密度的卷积指数为

$$
t^2+(z-t)^2=2(t-z/2)^2+\frac{z^2}{2}.
$$

配方后，依赖 $t$ 的部分仍是一个高斯积分，剩下关于 $z$ 的因子恰为 $N(0,2)$ 的密度。一般情形可经标准化和平移归到这一计算；第 15 章也会用特征函数一行证明。

“均值相加、方差相加”只要求相应矩和独立性；“和仍为正态”则是更强的形状闭合性质。均匀分布之和不均匀，指数分布之和也不是指数。

代码在两个不同方差的正态上检查一般公式：

```python
fsum = lambda z: exp(-(z - 3) ** 2 / 10) / sqrt(10 * pi)
for z in (-2, -1, 0, 1, 2, 3, 4, 5, 8):
    assert abs(conv_at(z) - fsum(z)) < 2e-7
```

这里 $N(0,1)+N(3,4)=N(3,5)$。注意第二个分布的参数 4 是方差，不是标准差。

## 14.4 对数正态：乘法和偏态

若 $X\sim N(\mu,\sigma^2)$，则

$$
Y=e^X
$$

服从参数为 $(\mu,\sigma^2)$ 的对数正态分布。因为 $Y>0$，它常用于价格、规模和收入等正变量模型，但是否合适必须检查数据生成机制。

对 $y>0$，$X=\log Y$ 的 Jacobian 为 $1/y$，故密度为

$$
f_Y(y)=\frac1{y\sigma\sqrt{2\pi}}
\exp\left(-\frac{(\log y-\mu)^2}{2\sigma^2}\right).
$$

由正态 MGF 或配方，

$$
E[Y^r]=E[e^{rX}]
=\exp\left(r\mu+\frac12r^2\sigma^2\right).
$$

所以

$$
E[Y]=e^{\mu+\sigma^2/2},
$$

$$
\operatorname{Var}(Y)
=(e^{\sigma^2}-1)e^{2\mu+\sigma^2}.
$$

中位数却是 $e^\mu$，因为单调变换保持中位数。于是

$$
\operatorname{median}(Y)=e^\mu<E[Y],
$$

右偏分布的均值被右尾拉高。不能把对数尺度的 $\mu$ 直接当作原尺度均值的对数。

`examples/python/14_normal_stable.py` 的 ⑥ 节（原先独立的稳定分布脚本已并入）检查这些闭式：

```python
mean_ln = exp(mu + sigma * sigma / 2)
second_ln = exp(2 * mu + 2 * sigma * sigma)
close(second_ln - mean_ln ** 2,
      (exp(sigma * sigma) - 1) * exp(2 * mu + sigma * sigma))
assert mean_ln > exp(mu)
```

对数正态虽然所有阶矩都存在，但对任意 $t>0$，

$$
E[e^{tY}]=E[\exp(te^X)]=\infty,
$$

因为 $te^x$ 最终远大于 $x^2$ 的线性量级不足以抵消高斯指数。故其 MGF 不存在。这是“所有矩存在”与“矩生成函数存在”之间的重要区别。

## 14.5 Cauchy：均值不存在的标准例子

标准 Cauchy 密度为

$$
f(x)=\frac1{\pi(1+x^2)},\qquad x\in\mathbb R.
$$

归一化来自

$$
\int_{-\infty}^{\infty}\frac{dx}{\pi(1+x^2)}
=\frac1\pi[\arctan x]_{-\infty}^{\infty}=1.
$$

CDF 与中位数分别为

$$
F(x)=\frac12+\frac1\pi\arctan x,
\qquad \operatorname{median}(X)=0.
$$

但

$$
E|X|=\int_{-\infty}^{\infty}\frac{|x|}{\pi(1+x^2)}dx=\infty,
$$

因为当 $|x|$ 大时，被积函数与 $1/(\pi|x|)$ 同阶。因此 $E[X]$ 不存在，而不是“均值为 0”。密度关于 0 对称只说明柯西主值为 0：

$$
\lim_{A\to\infty}\int_{-A}^A\frac{x}{\pi(1+x^2)}dx=0.
$$

对称窗口的特殊抵消不能代替绝对可积条件。

同文件使用原函数显示截断绝对一阶矩的增长：

```python
primitive = (log1p(B * B) - log(2.0)) / (2 * pi)
p10 = (log1p(10000.0) - log1p(100.0)) / (2 * pi)
close(p10, log(10) / pi, 3e-3)
```

在 $[1,B]$ 上，$x/(\pi(1+x^2))$ 的积分是
$[\log(1+x^2)]_1^B/(2\pi)$，随 $B$ 对数发散。窗口从 10 增到 100 时，增量接近 $\log(10)/\pi$。这个闭式账比在大区间上朴素 Simpson 更准确地揭示了问题。

## 14.6 稳定分布：为什么 Cauchy 不走普通 CLT

称非退化随机变量 $X$ 的分布为**严格稳定分布**，若对任意独立同分布副本 $X_1,\ldots,X_n$，存在 $a_n>0$ 和 $b_n$，使得

$$
X_1+\cdots+X_n\overset d=a_nX+b_n.
$$

通常还要求适当对称或中心化为严格稳定；更一般的稳定分布定义允许中心项。常见例子有：

- 标准正态：$S_n\overset d=\sqrt nX$，稳定指数 $\alpha=2$；
- 标准 Cauchy：$S_n\overset d=nX$，稳定指数 $\alpha=1$。

Cauchy 的特征函数是

$$
\varphi_X(t)=E[e^{itX}]=e^{-|t|}.
$$

独立和的特征函数为

$$
\varphi_{S_n}(t)=e^{-n|t|}
=\varphi_X(nt),
$$

这正是 $S_n\overset d=nX$。同文件对两个独立 Cauchy 检查同一闭式：

```python
for t in (-1.3, -0.2, 0.5, 2.0):
    close(exp(-2 * abs(t)), exp(-abs(2 * t)))
```

普通 CLT 的标准化尺度是 $\sqrt n$，并要求有限方差。Cauchy 没有有限方差，其和的自然尺度是 $n$，所以样本均值 $S_n/n$ 仍与单个 Cauchy 同分布，不会收敛到常数，也不会被 $\sqrt n$ 标准化成普通正态极限。

一般稳定分布由稳定指数 $0<\alpha\le2$ 等参数刻画；正态对应 $\alpha=2$，Cauchy 对应 $\alpha=1$。“稳定”不表示尾部薄，也不表示均值存在。

## 14.7 三种分布的对照

| 分布 | 所有阶矩 | 原点邻域 MGF | 典型独立和尺度 | 主要结构 |
|---|---|---|---|---|
| 正态 | 有 | 全实轴存在 | $\sqrt n$ | 指数平方尾部 |
| 对数正态 | 有 | $t>0$ 不存在 | 不具有正态式稳定闭合 | 乘法、右偏 |
| 标准 Cauchy | 无一阶绝对矩 | $t\ne0$ 不存在 | $n$ | 幂尾、稳定 |

表格中的“MGF 不存在”与“特征函数不存在”绝不能混淆。三者的特征函数都存在；第 15 章将系统说明原因。

## 14.8 Julia：大样本频率与稳定性

`examples/julia/14_normal_stable.jl` 用固定种子的两百万个 `randn` 样本核对矩与区间概率。偶矩用累积乘积生成 $(2m-1)!!=3,15,105,945$，再与样本矩比较：

```julia
Z = randn(2_000_000)
dfs = cumprod(2 .* (1:4) .- 1)          # [3, 15, 105, 945]
for m in 1:4
    sm = mean(z -> z ^ (2m), Z)
    @assert abs(sm - dfs[m]) < 0.02 * dfs[m]
end
```

稳定性一节取 $X\sim N(1,4)$、$Y\sim N(3,9)$，检查和的均值 4、方差 13，并且标准化三阶矩（偏度）接近 0。只比较前两阶矩不足以确认"仍是正态"，偏度是一个廉价的形状附加检验：

```julia
X = 1 .+ 2 .* randn(1_000_000)
Y = 3 .+ 3 .* randn(1_000_000)
S = X .+ Y
@assert abs(mean(S) - 4) < 0.02
@assert abs(var(S) - 13) < 0.06
sk = mean(((S .- 4) ./ sqrt(13)) .^ 3)
@assert abs(sk) < 0.02
```

最后两段对应 14.4 与 14.5：对数正态样本均值接近 $e^{\mu+\sigma^2/2}$ 且高于中位数 $e^\mu$；Cauchy 的运行均值在不同样本量处差异悬殊，没有大数定律：

```julia
LN = exp.(0.4 .+ 0.7 .* randn(2_000_000))
@assert abs(mean(LN) - exp(0.4 + 0.7^2 / 2)) < 0.02
@assert mean(LN) > median(LN)
cauchy() = tan(pi * (rand() - 0.5))
Cs = cumsum([cauchy() for _ in 1:200_000])
m1, m2 = Cs[50_000] / 50_000, Cs[200_000] / 200_000
```

对 Cauchy，这里故意不写断言：运行均值本身就是一个同分布的 Cauchy 随机变量，样本量增大不会让 `m1`、`m2` 靠近，输出仅作展示。

## 14.9 Lean：常数账与对称性

`examples/lean/Probability/Ch14NormalStable.lean` 把"配方后常数对得上"一类语句交给 `ring` 与 `norm_num`：

```lean
-- 密度只依赖 (x−μ)²：f(μ+a) = f(μ−a) 的指数账
example (μ a : ℚ) : (μ + a - μ) ^ 2 = (μ - a - μ) ^ 2 := by ring

-- (2m−1)!! 链：M(2k+2) = (2k+1)·M(2k)
example : (105 : ℚ) = 7 * 15 := by norm_num

-- 和稳定性：(μ, σ²) = (1,4) 与 (3,9) 相加得 (4,13)
example : ((1 : ℚ) + 3 = 4 ∧ 4 + 9 = 13) := by norm_num

-- 极坐标技巧的常数残迹
example : (Real.sqrt (Real.pi)) ^ 2 = Real.pi := by
  exact Real.sq_sqrt (by positivity)
```

这些都是具体的代数事实：第一条是均值 $\mu$ 作为对称中心的结构原因，第二条是偶矩递推，第三条是独立正态相加时参数的账，最后一条是 $\sqrt\pi$ 的主权恒等式。高斯积分与卷积的分析推导仍由 14.1 与 14.3 的正文承担。

## 14.10 本章要点

1. 正态归一化由二重积分和极坐标 Jacobian 证明；标准化使一般正态回到 $N(0,1)$。
2. 正态偶矩为 $(2m-1)!!$，独立正态之和仍为正态。
3. 对数正态均值 $e^{\mu+\sigma^2/2}$ 大于中位数 $e^\mu$，所有矩存在但没有正侧 MGF。
4. Cauchy 的对称性不推出均值为 0；$E|X|=\infty$，所以均值不存在。
5. 正态与 Cauchy 都是稳定分布，但稳定指数分别为 2 和 1，标准化尺度不同。
6. 重尾积分应使用原函数、变量代换或显式尾界，而不是用大窗口数值逼近冒充无穷结论。

*对应示例：`examples/lean/Probability/Ch14NormalStable.lean`、`examples/julia/14_normal_stable.jl`、`examples/python/14_normal_stable.py`。*

---

上一章：[13 连续分布族](13-continuous-dists.md) · 下一章：[15 母函数、矩生成函数与特征函数](15-generating-functions.md)
