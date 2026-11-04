# 15 母函数、矩生成函数与特征函数

生成函数把分布的信息编码进一个函数。概率质量变成幂级数系数，矩变成导数，独立和变成乘积。三种常用编码——PGF、MGF、CF——使用同一个思想，但适用范围不同：PGF 面向非负整数值变量，MGF 要求指数矩，CF 则对每个实分布都存在。

本章把“函数恒等式”“矩公式”和“分布唯一性”分开陈述。算出一个分布的前几阶矩，通常不能唯一确定分布；只有在相应唯一性定理的条件下，生成函数相等才能推出分布相等。

## 15.1 概率母函数 PGF

若 $X$ 取非负整数值，定义

$$G_X(s)=E[s^X]=\sum_{k=0}^{\infty}P(X=k)s^k.$$

当 $|s|\le1$ 时，

$$\sum_kP(X=k)|s|^k\le\sum_kP(X=k)=1,$$

所以级数至少单位圆盘上绝对收敛。对某些分布，收敛域可以更大。

PGF 的系数直接恢复 pmf：

$$P(X=k)=\frac{G_X^{(k)}(0)}{k!}.$$

因此若两个 PGF 在 0 的某个邻域内作为幂级数相等，则全部概率逐一相等。这里使用了解析函数系数唯一性，而不是只比较函数在某个点的值。

### 常见闭式

- Bernoulli：$G(s)=q+ps$ ；
- 二项：$G(s)=(q+ps)^n$ ；
- 几何（首次成功所需次数）：$G(s)=ps/(1-qs)$ ，$|s|<1/q$ ；
- Poisson：$G(s)=e^{\lambda(s-1)}$ 。

二项公式本身已经显示它是 $n$ 个独立 Bernoulli 变量之和。

在允许逐项求导的区域内，

$$G_X'(1)=E[X], \qquad G_X''(1)=E[X(X-1)].$$

更一般地，第 $r$ 阶导数给出阶乘矩 $E[X(X-1)\cdots(X-r+1)]$ 。若端点导数不直接存在，需要在适当条件下取 $s\uparrow1$ 的极限；不能无条件交换无穷求和与求导。

`examples/python/15_generating_functions.py` 的 ⑦ 节（原先独立的特征函数脚本已并入）对二项 PGF 用两条路径精确对账：

```python
direct = sum(Fraction(comb(n, k)) * p ** k * q ** (n - k) * s ** k
             for k in range(n + 1))
assert direct == (q + p * s) ** n
assert fact2_direct == n * (n - 1) * p ** 2
```

第一条是二项定理的有限和，第二条由完整 pmf 独立计算阶乘矩，均为有理数精确计算。

## 15.2 独立和：卷积变乘法

若 $X,Y$ 独立且都取非负整数值，则

$$\begin{aligned} G_{X+Y}(s) &=E[s^{X+Y}] =E[s^X]E[s^Y]\\ &=G_X(s)G_Y(s). \end{aligned}$$

期望可分解的关键是独立性。乘积级数中 $s^k$ 的系数为

$$\sum_{j=0}^kP(X=j)P(Y=k-j),$$

恰是独立和的卷积公式。这解释了为什么生成函数能把逐点卷积变成代数乘法。

对独立 Poisson 变量，

$$G_{X+Y}(s) =e^{\lambda_X(s-1)}e^{\lambda_Y(s-1)} =e^{(\lambda_X+\lambda_Y)(s-1)}.$$

由 PGF 唯一性，$X+Y\sim\operatorname{Poisson}(\lambda_X+\lambda_Y)$ 。这同时给出分布形状和参数，不只是均值相加。

`examples/python/15_generating_functions.py` 用有限卷积独立检查这一结论：

```python
for k in range(0, 25):
    conv = sum(pois_pmf(5, l) * pois_pmf(7, k - l)
               for l in range(0, k + 1))
    assert abs(conv - pois_pmf(12, k)) < 1e-12
```

对每个固定 $k$ ，这是精确的有限代数恒等式，浮点只带来舍入误差；没有通过截断一个无穷卷积来假装证明。

## 15.3 普通生成函数与 Fibonacci

PGF 是普通生成函数的概率特例。对数列 $a_0,a_1,\ldots$ ，定义

$$G_a(s)=\sum_{n\ge0}a_ns^n$$

（在其收敛域内）。生成函数不仅处理概率，也能把递推变成代数方程。

设 $F_0=0,F_1=1,F_n=F_{n-1}+F_{n-2}$ 。令 $G(s)=\sum_{n\ge0}F_ns^n$ 。递推给出

$$G(s)-s=sG(s)+s^2G(s),$$

所以

$$G(s)=\frac{s}{1-s-s^2}.$$

令

$$\phi=\frac{1+\sqrt5}{2},\qquad \psi=\frac{1-\sqrt5}{2}.$$

因 $1-s-s^2=(1-\phi s)(1-\psi s)$ ，部分分式和几何级数展开给出 Binet 公式

$$F_n=\frac{\phi^n-\psi^n}{\sqrt5}.$$

无理数表达式组合后仍是整数。推导中的级数等式先在 $|s|<1/\phi$ 内成立，保证收敛。

Python 通过递推恢复系数，避免把 Binet 浮点形式当成整数定义：

```python
c[0], c[1] = 1, 1
for k in range(2, n_terms + 1):
    c[k] = c[k - 1] + c[k - 2]
...
assert all(fib[n] == coeffs[n - 1] for n in range(1, 30))
```

多出的 $s$ 使系数下标平移一位：$s/(1-s-s^2)$ 的 $s^n$ 系数为 $F_n$ ，而 $1/(1-s-s^2)$ 的相应系数为 $F_{n+1}$ 。Prolog 文件也检查这个位移，并用多项式乘法展示骰子 pmf 的卷积。

## 15.4 矩生成函数 MGF

对一般实随机变量，定义

$$M_X(t)=E[e^{tX}]$$

于使期望有限的实数 $t$ 。由于 $e^{0X}=1$ ，总有 $M_X(0)=1$ 。但除 $t=0$ 外，期望可能为无穷。

若 MGF 在某个 $(-\delta,\delta)$ 内有限，则可以在该邻域展开

$$M_X(t)=E\left[\sum_{n=0}^{\infty}\frac{t^nX^n}{n!}\right] =\sum_{n=0}^{\infty}E[X^n]\frac{t^n}{n!}.$$

这里指数矩提供了交换期望与求和所需的控制。于是

$$M_X^{(n)}(0)=E[X^n], \qquad \operatorname{Var}(X)=M_X''(0)-M_X'(0)^2.$$

常见闭式包括

$$M_{N(\mu,\sigma^2)}(t)=e^{\mu t+\sigma^2t^2/2},$$

$$M_{\operatorname{Pois}(\lambda)}(t)=e^{\lambda(e^t-1)},$$

$$M_{\operatorname{Gamma}(k,\theta)}(t)=(1-\theta t)^{-k}, \qquad t<1/\theta.$$

若 $X,Y$ 独立，且相应 MGF 存在，则

$$M_{X+Y}(t)=M_X(t)M_Y(t).$$

**唯一性定理**：若两个分布在 0 的某个邻域内都有有限且相等的 MGF，则它们同分布。仅知道 MGF 在某个非零点相等，或只知道若干矩相等，不满足这个定理的条件。

Python 对正态和指数 MGF 分别用数值期望和闭式核对：

```python
num = simpson(lambda x: exp(t * x) * phi_pdf(x), -10, 10, 4000)
assert abs(num - exp(t * t / 2)) < 1e-9
...
m1 = (mgf(h) - mgf(-h)) / (2 * h)
m2 = (mgf(h) - 2 * mgf(0.0) + mgf(-h)) / h ** 2
```

中心差分只是对导数公式的数值审计；真正的矩提取依据是上面的级数定理。

## 15.5 Cauchy：没有 MGF，却有 CF

对标准 Cauchy，若 $t>0$ ，在正尾部 $e^{tx}/(1+x^2)$ 增长很快，因而

$$E[e^{tX}]=\infty.$$

若 $t<0$ ，负尾部同样使期望发散。所以其 MGF 只在 $t=0$ 有定义，根本不存在 0 的开邻域，不能使用 MGF 求矩或唯一性定理。

对数正态给出另一种边界情形：它的所有阶矩存在，但对任意 $t>0$ ，$E[e^{tX}]=\infty$ 。因此“各阶矩有限”弱于“原点附近 MGF 有限”。

这两个例子也说明，不能看到某个积分在选定数值窗口内有限，就断言 MGF 存在；存在性是全实线上的分析问题。

## 15.6 特征函数 CF：始终存在的工具

定义

$$\varphi_X(t)=E[e^{itX}] =E[\cos(tX)]+iE[\sin(tX)],\qquad t\in\mathbb R.$$

由于

$$|e^{itX}|=\sqrt{\cos^2(tX)+\sin^2(tX)}=1,$$

两个实部积分都绝对可积，所以每个实随机变量的 CF 都在整个实轴上存在。并且

$$\varphi_X(0)=1, \qquad |\varphi_X(t)|\le1, \qquad \varphi_X(-t)=\overline{\varphi_X(t)}.$$

若 $E|X^n|<\infty$ ，可在导数条件下得到

$$\varphi_X^{(n)}(0)=i^nE[X^n].$$

与 MGF 相比，矩不存在时 CF 依然存在，只是相应的零点导数公式不可用。

独立和仍满足

$$\varphi_{X+Y}(t)=\varphi_X(t)\varphi_Y(t).$$

例如

$$\varphi_{N(\mu,\sigma^2)}(t) =\exp(i\mu t-\sigma^2t^2/2), \qquad \varphi_{\operatorname{Cauchy}}(t)=e^{-|t|}.$$

两式立刻给出正态和 Cauchy 的独立和稳定性。同文件 ⑦ 节用实值闭式检查乘积：

```python
close(exp(-t * t / 2) * exp(-3 * t * t / 2), exp(-2 * t * t))
close(exp(-abs(t)) * exp(-2 * abs(t)), exp(-3 * abs(t)))
```

**CF 唯一性定理**：若两个分布在所有 $t\in\mathbb R$ 上特征函数相同，则它们同分布。反演公式和后续 Fourier 章节会把“函数相等”重新翻译成“分布相等”。这正是 CF 在 CLT 证明中比 MGF 更普遍的原因。

## 15.7 三种函数的选择

| 工具 | 定义 | 最少适用范围 | 主要收益 |
|---|---|---|---|
| PGF | $E[s^X]$ | 非负整数值，$\lvert s\rvert\le1$ | pmf 系数、阶乘矩、递推 |
| MGF | $E[e^{tX}]$ | 需要指数矩 | 实分析求矩、独立和 |
| CF | $E[e^{itX}]$ | 所有实分布、所有实 $t$ | 唯一性、独立和、弱收敛 |

选择顺序通常由问题决定：整数计数优先 PGF；轻尾分布求矩可用 MGF；重尾分布、一般唯一性和极限定理使用 CF。

## 15.8 Julia：模拟与三种 Fibonacci 算法

`examples/julia/15_generating_functions.jl` 先用 Knuth 乘法法手写 Poisson 采样，再把 $\mathrm{Pois}(5)+\mathrm{Pois}(7)$ 的样本直方图和 $\mathrm{Pois}(12)$ 的 pmf 对比，对应 15.2 的"参数相加"：

```julia
S = sim_poisson(5.0, 200_000) .+ sim_poisson(7.0, 200_000)
pois_pmf(l, k) = l ^ k * exp(-l) / factorial(k)
for k in 5:20
    emp = count(==(k), S) / length(S)
    @assert abs(emp - pois_pmf(12.0, k)) < 0.003
end
```

接着是 15.3 的实验：用递推、Binet 取整、矩阵幂三种方法算 $F_n$ 。`BigInt`/`BigFloat` 下三者一致；若改用 `Float64`，Binet 公式 $\varphi^n/\sqrt5$ 在 $n=80$ 附近因 53 位尾数不够而失真，这是"闭式正确不等于数值算法正确"的现场：

```julia
phi = (1 + sqrt(big(5))) / 2
fib_binet(n) = round(BigInt, phi ^ n / sqrt(big(5)))
fib_mat(n) = matpow(big.([1 1; 1 0]), n)[1, 2]
for n in (10, 40, 90)
    @assert fib_binet(n) == fib_rec(n) == fib_mat(n)
end
phi64 = (1 + sqrt(5)) / 2
@assert round(Int, phi64 ^ 80 / sqrt(5)) != Int(fib_rec(80))
```

后两段用 Simpson 积分验证 MGF 闭式 $e^{t^2/2}$ 、$1/(1-t)$ （后者要求 $t<1$ ，积分上限 60 对 $t\le0.5$ 已足够），并验证三个几何变量之和服从"数到第 3 次成功"的负二项分布 $P(S=s)=\binom{s-1}{2}p^3q^{s-3}$ 。负二项有"成功数"与"试验数"两种约定，支撑差一个平移，这里取后者。

## 15.9 Prolog：多项式乘法即卷积

`examples/prolog/15_generating_functions.pl` 用穷举而非符号推导检验母函数的代数性质。核心是把多项式系数表当作 pmf，乘法就是卷积：

```prolog
conv_sum(A, B, K, S) :-
    aggregate_all(sum(P), (nth0(I, A, Ai), nth0(J, B, Bj),
                           I + J =:= K, P is Ai * Bj), S).

poly_conv(A, B, C) :-
    length(A, LA), length(B, LB), L is LA + LB - 2,
    findall(S, (between(0, L, K), conv_sum(A, B, K, S)), C).

% 骰子 pmf（未归一化）自乘得到两骰和的三角形
check_conv :-
    D = [1,1,1,1,1,1],
    poly_conv(D, D, Tri),
    Tri = [1,2,3,4,5,6,5,4,3,2,1].
```

`conv_sum` 对每个次数 $K$ 枚举所有满足 $I+J=K$ 的下标对，正是 15.2 中 $\sum_jP(X=j)P(Y=k-j)$ 。同文件还用迭代式 `fib/2` 检验 $F_{30}=832040$ ，并验证 $1/(1-s-s^2)$ 的第 10 个系数等于 $F_{11}=89$ （平移一位）。朴素双递归 Fibonacci 在 $N=40$ 时指数爆炸，所以采用累加器版本。

## 15.10 本章要点

1. PGF 把 pmf 编成幂级数，导数给出阶乘矩，独立和对应乘积。
2. Fibonacci 生成函数为 $s/(1-s-s^2)$ ，部分分式给出 Binet 公式。
3. MGF 只有在原点邻域存在时才能使用标准展开和唯一性定理。
4. Cauchy 无原点邻域 MGF；对数正态有所有矩但同样无正侧 MGF。
5. CF 因 $|e^{itX}|=1$ 而总存在，且在全部 $t$ 上相等可唯一确定分布。
6. 生成函数乘积是独立和卷积的代数化；数值积分和模拟都不能替代唯一性定理的条件。

*对应示例：`examples/julia/15_generating_functions.jl`、`examples/python/15_generating_functions.py`、`examples/prolog/15_generating_functions.pl`。*

---

上一章：[14 正态、对数正态、柯西与稳定分布](14-normal-stable.md) · 下一章：[16 卷积与微分恒等式](16-convolutions.md)
