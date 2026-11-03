# 第 30 章 Stirling 公式与局部近似

## 30.1 从阶乘到概率

阶乘本身不是概率，却频繁出现在离散分布中：

$$
P(S_n=k)=\binom nk p^k(1-p)^{n-k}
$$

里有二项系数，Poisson 概率

$$
P(X=k)=e^{-\lambda}\frac{\lambda^k}{k!}
$$

里有阶乘，随机游走返回原点的概率也含中心二项系数。

当 $n$ 很大时，精确整数虽然存在，直接计算却既昂贵又不透明。

Stirling 公式把阶乘转成幂、指数和平方根，使我们能看清概率随 $n$ 的尺度。

本章分三层：

1. 用积分夹逼免费得到 $n!^{1/n}\sim n/e$；
2. 推导完整的 Stirling 主项与 $1/(12n)$ 修正；
3. 把公式用于中心二项系数、平票概率和格点局部近似。

## 30.2 第一层：严格的积分夹逼

函数 $\log x$ 在 $x>0$ 上递增。

对每个 $k\ge2$，在区间 $[k-1,k]$ 上有 $\log x\le\log k$，所以

$$
\int_{k-1}^{k}\log x\,dx\le\log k.
$$

对 $k=2,\ldots,n$ 求和：

$$
\int_1^n\log x\,dx\le\log n!.
$$

由于

$$
\int\log x\,dx=x\log x-x,
$$

得到

$$
n\log n-n+1\le\log n!.
$$

另一方面，在 $[k,k+1]$ 上有 $\log k\le\log x$，故

$$
\log k\le\int_k^{k+1}\log x\,dx.
$$

对 $k=1,\ldots,n-1$ 求和，再加上 $\log n$，得

$$
\log n!
\le \log n+\int_1^n\log x\,dx
=n\log n-n+1+\log n.
$$

取指数，得到完全初等且严格的夹逼：

$$
\boxed{
e\left(\frac ne\right)^n
\le n!
\le en\left(\frac ne\right)^n.
}
$$

Python 在对数域检查同一结论：

```python
for n in (10, 50, 200):
    lm = n * log(n) - n
    lf = lgamma(n + 1)
    assert lm + 1 <= lf <= lm + 1 + log(n)
```

这里使用 `lgamma(n+1)` 计算 $\log\Gamma(n+1)=\log n!$，避免大阶乘先溢出再取对数。

## 30.3 夹逼能推出什么，不能推出什么

对上述不等式取 $1/n$ 次幂：

$$
e^{1/n}\frac ne
\le n!^{1/n}
\le (en)^{1/n}\frac ne.
$$

因为 $e^{1/n}\to1$ 且 $(en)^{1/n}\to1$，所以

$$
\boxed{n!^{1/n}\sim\frac ne.}
$$

这已经给出阶乘几何平均的主项。

但夹逼两侧相差一个因子 $n$，因此它不能确定 Stirling 公式中的 $\sqrt{2\pi n}$。

尤其不能把下界中的常数 $e$ 与 $\sqrt{2\pi}$ 直接比较，然后声称完整常数已经由夹逼得到。

完整公式需要更精细的梯形误差分析。

Python 还直接检查几何平均与 $n/e$ 的有限 $n$ 比值：

```python
for n in (10, 100):
    lhs = factorial(n) ** (1 / n)
    assert lhs > n / exp(1) and lhs < n / exp(1) * (1 + 4 / n)
```

这里的 `4/n` 是这段有限范围测试的宽松界，不是渐近展开的最佳常数。

## 30.4 第二层：梯形和与收敛误差

考虑区间 $[k,k+1]$ 上的梯形近似

$$
T_k=\frac{\log k+\log(k+1)}2.
$$

因为 $\log x$ 是凹函数，梯形位于函数图像下方，所以

$$
\delta_k:=\int_k^{k+1}\log x\,dx-T_k>0.
$$

对 $k=1,\ldots,n-1$ 求和：

$$
\int_1^n\log x\,dx
=\log n!-\frac12\log n+\sum_{k=1}^{n-1}\delta_k.
$$

整理得

$$
\log n!
=n\log n-n+1+\frac12\log n
-\sum_{k=1}^{n-1}\delta_k.
$$

由带误差的梯形公式，存在 $\xi_k\in(k,k+1)$ 使

$$
\delta_k=-\frac{(\log)''(\xi_k)}{12}
=\frac1{12\xi_k^2}.
$$

因此

$$
0<\delta_k\le\frac1{12k^2}.
$$

级数 $\sum_k\delta_k$ 收敛。

令

$$
A=\sum_{k=1}^{\infty}\delta_k,
\qquad
C=1-A.
$$

则

$$
\log n!
=n\log n-n+\frac12\log n+C+R_n,
$$

其中

$$
R_n=\sum_{k=n}^{\infty}\delta_k.
$$

由 $\delta_k\asymp1/(12k^2)$，尾部主项为

$$
R_n\sim\frac1{12n}.
$$

于是存在常数 $C$，使

$$
\log n!
=n\log n-n+\frac12\log n+C+\frac1{12n}+O(n^{-3}).
$$

取指数：

$$
n!\sim e^C\sqrt n\left(\frac ne\right)^n.
$$

剩下唯一的问题是确定 $e^C$。

## 30.5 用 Wallis 公式确定常数

定义

$$
I_m=\int_0^{\pi/2}\sin^m x\,dx.
$$

分部积分得到递推

$$
I_m=\frac{m-1}{m}I_{m-2},
\qquad m\ge2.
$$

初值为

$$
I_0=\frac\pi2,
\qquad I_1=1.
$$

所以偶数阶与奇数阶积分分别是

$$
I_{2n}
=\frac{(2n-1)!!}{(2n)!!}\frac\pi2,
$$

$$
I_{2n+1}
=\frac{(2n)!!}{(2n+1)!!}.
$$

在 $[0,\pi/2]$ 上，

$$
\sin^{2n+1}x\le\sin^{2n}x\le\sin^{2n-1}x.
$$

积分后取比值，并用递推式，可得

$$
\frac{I_{2n}}{I_{2n+1}}\to1.
$$

代入上面的闭式，就得到 Wallis 极限，并可改写为中心二项系数形式：

$$
\boxed{
\frac1{4^n}\binom{2n}{n}\sim\frac1{\sqrt{\pi n}}.
}
$$

另一方面，将尚未确定常数的 Stirling 形式代入中心二项系数：

$$
\frac{(2n)!}{4^n(n!)^2}
\sim
\frac{e^C\sqrt{2n}(2n/e)^{2n}}
{4^n e^{2C}n(n/e)^{2n}}
=
\frac{\sqrt2}{e^C\sqrt n}.
$$

与 Wallis 结果比较：

$$
\frac{\sqrt2}{e^C}=\frac1{\sqrt\pi}.
$$

故

$$
e^C=\sqrt{2\pi}.
$$

常数不是凭空记住的，而是由 Wallis 积分唯一确定。

## 30.6 完整 Stirling 公式与修正项

代入 $C=\frac12\log(2\pi)$，得到

$$
\boxed{
n!\sim\sqrt{2\pi n}\left(\frac ne\right)^n.
}
$$

对数形式为

$$
\boxed{
\log n!
=n\log n-n+\frac12\log(2\pi n)
+\frac1{12n}+O(n^{-3}).
}
$$

因此一个常用的乘法修正是

$$
n!\approx
\sqrt{2\pi n}\left(\frac ne\right)^n
\left(1+\frac1{12n}\right).
$$

更精细的渐近级数常写为

$$
n!
=\sqrt{2\pi n}\left(\frac ne\right)^n
\left(1+\frac1{12n}+\frac1{288n^2}+O(n^{-3})\right).
$$

这是渐近级数，不应在固定 $n$ 时无限添加项并声称必然收敛。

对数值计算，对数形式通常最稳定：

$$
\log n!
\approx n\log n-n+\frac12\log(2\pi n)
+\log\left(1+\frac1{12n}\right).
$$

Python 正是这样实现（导入为 `from math import log, log1p, pi`）：

```python
def stirling(n, corrected=True):
    lv = n * log(n) - n + log(2 * pi * n) / 2
    if corrected:
        lv += log1p(1 / (12 * n))
    return lv
```

`log1p(x)` 在 $x$ 很小时比直接计算 `log(1+x)` 更稳定。

整个表达式仍在对数域，因而可以处理 $n=10^6$ 而不构造巨大的浮点阶乘。

## 30.7 相对误差的两条幂律

主式的对数误差主项为 $1/(12n)$，所以相对误差也近似为

$$
\frac{\sqrt{2\pi n}(n/e)^n-n!}{n!}
\approx\frac1{12n}
$$

（符号取决于用精确值还是近似值作分母，主阶不变）。

加入 $1/(12n)$ 后，一阶误差被抵消，下一项为 $O(n^{-2})$。

Python 用对数差构造相对误差：

```python
def relerr(n, corrected=True):
    return abs(exp(stirling(n, corrected) - lgamma(n + 1)) - 1)
```

然后检查

```python
assert e0 < 1.1 / (12 * n)
assert e1 < 1.1 / (288 * n * n)
```

这些数值断言只覆盖 $n=10,100,1000,10^6$。

真正的渐近结论来自前面的展开，不来自四次浮点比较。

Julia 进一步用首尾误差估计 log–log 斜率：

```julia
slope0 = log(errs0[end] / errs0[1]) / log(ns[end] / ns[1])
slope1 = log(errs1[end] / errs1[1]) / log(ns[end] / ns[1])
@assert abs(slope0 + 1) < 0.05
@assert abs(slope1 + 2) < 0.1
```

主式斜率约为 $-1$，修正后约为 $-2$。

当误差接近浮点精度地板时，不能继续扩大 $n$ 并期待斜率仍然准确。

## 30.8 小 $n$ 时的误差

Stirling 是渐近公式，但修正版在相当小的 $n$ 已经有用。

不过“小 $n$ 可用”必须靠误差账，而不是一句经验口号。

主式在 $n=1$ 时的相对误差仍有数个百分点；修正后明显改善，却不等于精确。

对概率计算，以下原则更可靠：

- 小 $n$ 直接精确枚举或使用 `lgamma`；
- 大 $n$ 用对数域 Stirling 防止上溢和下溢；
- 报告近似值时区分绝对误差与相对误差；
- 对极端尾部，微小的对数误差也可能放大成显著的相对概率误差。

主式和修正版的误差幂律并不意味着所有二项概率都自动达到同样精度。

还要考虑 $k$ 是否远离中心，以及 $p$ 是否接近边界。

## 30.9 中心二项系数的渐近

将 Stirling 公式代入

$$
\binom{2n}{n}=\frac{(2n)!}{(n!)^2},
$$

得到

$$
\binom{2n}{n}
\sim
\frac{\sqrt{2\pi\cdot2n}(2n/e)^{2n}}
{2\pi n(n/e)^{2n}}
=\frac{4^n}{\sqrt{\pi n}}.
$$

所以

$$
\boxed{
\frac1{4^n}\binom{2n}{n}
\sim\frac1{\sqrt{\pi n}}.
}
$$

修正项也可由对数展开计算。

若

$$
\log n!=L(n)+\frac1{12n}+O(n^{-3}),
$$

其中 $L(n)=n\log n-n+\frac12\log(2\pi n)$，则

$$
\log\binom{2n}{n}-2n\log2+\frac12\log(\pi n)
=
\frac1{24n}-\frac2{12n}+O(n^{-3})
=-\frac1{8n}+O(n^{-3}).
$$

取指数得

$$
\boxed{
\frac1{4^n}\binom{2n}{n}
=\frac1{\sqrt{\pi n}}
\left(1-\frac1{8n}+O(n^{-2})\right).
}
$$

Python 对精确大整数与主式比较：

```python
lhs = comb(2 * n, n) / 4 ** n
rhs = 1 / sqrt(pi * n)
assert abs(lhs / rhs - 1) < 1 / (8 * n)
```

这里 `comb` 先构造精确整数，再做一次浮点除法，适合本例的 $n$。

若 $n$ 极大，应改用 `lgamma` 在对数域计算，避免无必要的大整数成本。

## 30.10 平票概率：同一个组合数，不同的模型

假设有 $2n$ 个独立投票，每人以概率 $p$ 投给一方。

两方票数完全相等的概率是

$$
P(\text{tie})=\binom{2n}{n}p^n(1-p)^n.
$$

### 等可能模型

若 $p=1/2$，则

$$
P(\text{tie})
=\frac1{4^n}\binom{2n}{n}
\sim\frac1{\sqrt{\pi n}}.
$$

取 $n=6001$，即总票数 $12002$，Python 计算

```python
n = 6001
p_equal = comb(2 * n, n) / 2 ** (2 * n)
assert abs(p_equal - 0.0072829) < 1e-7
```

概率约为 $0.728\%$，不是旧稿中可能由小数点错位得到的数量级。

### 固定倾向模型

若 $p=0.57$，则

$$
P(\text{tie})
=\binom{2n}{n}(0.57\times0.43)^n.
$$

组合因子提供 $4^n/\sqrt{\pi n}$ 量级，而

$$
4p(1-p)=4\times0.57\times0.43=0.9804<1.
$$

所以概率还带有指数衰减因子 $0.9804^n$。

Python 在对数域计算：

```python
logp = (log(comb(2 * n, n)) + n * log(0.57) + n * log(0.43))
assert abs(logp - log(1.877e-54)) < 0.01
```

约为 $1.9\times10^{-54}$。

两个数字差异巨大，不是因为 Stirling 公式不稳定，而是因为概率模型不同。

$p=1/2$ 让平票位于分布中心；$p=0.57$ 让平票成为远离均值的极端事件。

现实中投票并不满足固定已知 $p$ 的独立同分布假设，这两个数只是模型计算，不是现实预测。

## 30.11 从中心二项系数到局部 Gaussian 公式

令 $K\sim\operatorname{Bin}(2n,1/2)$。

在中心附近写 $K=n+k$，其中 $k$ 相对 $n$ 较小。

对三个阶乘都使用带对数修正的 Stirling 公式，再展开

$$
\log(1+k/n),\qquad \log(1-k/n),
$$

可得到局部近似

$$
P(K=n+k)
\approx
\frac1{\sqrt{\pi n}}e^{-k^2/n}.
$$

这里 $\operatorname{Var}(K)=n/2$，标准正态密度在对应尺度上的结果与此一致。

更一般地，若 $S_{2n}$ 是 $2n$ 个独立 $\pm1$ 变量的和，则

$$
S_{2n}=2K-2n.
$$

当 $S_{2n}=2k$ 时，

$$
P(S_{2n}=2k)
\approx
\frac1{\sqrt{\pi n}}e^{-k^2/n}.
$$

标准差为 $\sqrt{2n}$，格距为 $2$，所以也可写为

$$
P(S_{2n}=2k)
\approx
\frac2{\sqrt{2n}}
\varphi\left(\frac{2k}{\sqrt{2n}}\right).
$$

这与第 27 章的格距规则完全一致。

## 30.12 Julia 中的局部概率与活动窗口

Julia 先用精确有理数构造中心附近各格点概率：

```julia
Ks = -30:30
probs = [binomial(big(2N), big(N + k)) // big(2)^(2N) for k in Ks]
```

这里 `N=100`，随机游走长度为 `2N=200`。

`big` 防止阶乘与 $2^{200}$ 在机器整数中溢出，`//` 保留精确有理数。

随后用固定种子模拟，并在中心区比较

```julia
dens = exp(-k^2 / N) / sqrt(pi * N)
@assert abs(emp - dens) < 0.002
```

这段断言比较的是每个格点的概率质量，不是把正态密度直接当成概率。

正态密度必须先乘以格距；这里推导后的 `dens` 已包含正确尺度。

Julia 还检查随 $n$ 增长的活动窗口：

```julia
abs(h - n) <= sqrt(2n) && (inside += 1)
```

对 $\operatorname{Bin}(2n,1/2)$，标准差为 $\sqrt{n/2}$，所以这是约 $\pm2$ 个标准差的窗口。

窗口在实数轴上越来越宽，包含越来越多格点，总概率保持约 $95\%$。

与此同时，中心单点概率按 $1/\sqrt{\pi n}$ 缩小。

“总质量稳定”与“单点质量摊薄”同时发生，并不矛盾。

## 30.13 精确计算、渐近展开与模拟的边界

本章出现三种不同证据。

**精确计算**：`comb`、`binomial(big(...))` 和有理数给出指定 $n$ 的精确组合账。

**渐近推导**：积分夹逼、梯形误差、Wallis 公式和 Taylor 展开给出定理与误差阶。

**固定种子模拟**：检查格点频率和活动窗口的有限样本形态。

模拟不会证明 Stirling 公式；Stirling 公式也不能替代对具体模型的假设审查。

尤其在极端尾部，中心附近的局部展开可能失效，应考虑大偏差工具，而不是无限外推 Gaussian 近似。

## 30.14 本章要点

1. 严格积分夹逼给出 $e(n/e)^n\le n!\le en(n/e)^n$，足以推出 $n!^{1/n}\sim n/e$。
2. 梯形误差级数给出 $\sqrt n$ 和 $1/(12n)$ 修正，Wallis 公式确定 $\sqrt{2\pi}$。
3. 主式相对误差约为 $1/(12n)$，加入一阶修正后降为 $O(n^{-2})$。
4. 中心二项系数满足 $\binom{2n}{n}/4^n\sim1/\sqrt{\pi n}$，下一阶为 $-1/(8n)$。
5. 平票概率对模型中的 $p$ 极敏感；等可能中心的幂律与偏离中心的指数衰减不能混为一谈。
6. 格点概率要乘格距，区间概率要考虑半格端点。
7. 小 $n$ 用精确计算，大 $n$ 用对数域；模拟只用于有限样本审计。

完整示例为 `examples/python/30_stirling.py` 与 `examples/julia/30_stirling.jl`。

---

上一章：[29 渐近拼接工具](29-asymptotic-tools.md) · 下一章：[31 参数模型、估计量与风险](31-estimation-models.md)
