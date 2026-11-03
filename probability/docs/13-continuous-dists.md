# 13 连续分布族：均匀、指数、Γ 与 Beta

连续分布族的公式看似繁多，实际主要由三种机制生成：区间上的等密度、等待时间与指数衰减、正次数变量的幂律形状。理解参数的位置比背公式更重要：位置参数平移分布，尺度参数拉伸分布，形状参数改变尾部或峰形。

本章把密度写成 $f$，分布函数写成 $F$。所有密度都默认为在支撑集之外取 0。数值积分用于核对已经推出的归一化和矩，不用有限窗口的计算代替无穷区间上的证明。

## 13.1 均匀分布：位置与尺度

若 $a<b$，$X\sim U[a,b]$ 的密度为

$$
f(x)=\frac1{b-a},\qquad a\le x\le b.
$$

它的分布函数是

$$
F(x)=
\begin{cases}
0,&x<a,\\
(x-a)/(b-a),&a\le x\le b,\\
1,&x>b.
\end{cases}
$$

直接积分得到

$$
E[X]=\frac{a+b}{2},
\qquad
\operatorname{Var}(X)=\frac{(b-a)^2}{12}.
$$

若 $U\sim U[0,1]$，则 $X=a+(b-a)U\sim U[a,b]$。因此 $a$ 是位置参数，$b-a$ 是尺度参数；整个族都可以由标准均匀分布生成。

两个独立 $U[0,1]$ 变量之和不再均匀。第 16 章将完整推出其三角密度

$$
f_{X+Y}(z)=
\begin{cases}
z,&0\le z\le1,\\
2-z,&1\le z\le2.
\end{cases}
$$

这提醒我们：“矩能相加”不表示“分布形状保持不变”。

Python 文件 `examples/python/13_continuous_dists.py` 对分段 CDF 使用精确有理数：

```python
tri_cdf = lambda z: z * z / 2 if z <= 1 else 1 - (2 - z) ** 2 / 2
assert tri_cdf(Fraction(1, 2)) == Fraction(1, 8)
assert tri_cdf(Fraction(3, 2)) == Fraction(7, 8)
assert tri_cdf(1) == Fraction(1, 2)
```

正文中的公式给出证明，程序则防止分段端点和系数在实现中被写错。Julia 同章文件用固定种子样本检查均匀和的频率形状；模拟不承担公式证明。

## 13.2 指数分布：无记忆的连续等待时间

本章采用**尺度参数** $\theta>0$：

$$
X\sim\operatorname{Exp}(\theta),\qquad
f(x)=\frac1\theta e^{-x/\theta},\quad x\ge0.
$$

有些资料采用速率 $\lambda=1/\theta$，密度写成 $\lambda e^{-\lambda x}$。比较公式前必须统一参数化。这里

$$
F(x)=1-e^{-x/\theta},\qquad
P(X>x)=e^{-x/\theta},\qquad x\ge0.
$$

由分部积分或第 16 章的参数求导，

$$
E[X^r]=r!\theta^r\quad(r\in\mathbb N),
$$

特别地

$$
E[X]=\theta,\qquad \operatorname{Var}(X)=\theta^2.
$$

### 无记忆性

对 $s,t\ge0$，

$$
P(X>s+t\mid X>s)
=\frac{e^{-(s+t)/\theta}}{e^{-s/\theta}}
=e^{-t/\theta}=P(X>t).
$$

指数分布因此适合描述“下一个事件在任意短区间内的风险率恒定”的模型。它不适合必然老化的部件：已知已经使用很久仍不改变剩余寿命，正是模型假设，不是自然定律。

风险率为

$$
h(x)=\frac{f(x)}{P(X>x)}=\frac1\theta.
$$

反之，若连续非负随机变量具有正常数风险率，解微分方程便回到指数生存函数。恒定风险率与无记忆性是同一件事的两面。

由 $F(x)=u$ 反解得到逆变换采样公式

$$
x=-\theta\log(1-u).
$$

因为 $1-U$ 与 $U$ 同分布，也常写成 $-\theta\log U$。Python 检查的核心是解析尾部比：

```python
F = lambda x: 1 - exp(-x / lam)
assert abs((1 - F(6)) / (1 - F(3)) - (1 - F(3))) < 1e-12
```

这段代码对应 $P(X>60)/P(X>30)=P(X>30)$；它不能反向证明所有具有此样本特征的分布都是指数分布。

## 13.3 Γ 函数：指数衰减下的统一矩账户

对 $s>0$，定义

$$
\Gamma(s)=\int_0^\infty x^{s-1}e^{-x}\,dx.
$$

必须先检查两个端点。在 0 附近，$e^{-x}$ 有正上下界，可积性由 $x^{s-1}$ 决定，因此需要 $s>0$。在无穷端，指数衰减快于任何多项式增长，所以积分收敛。

分部积分给出函数方程

$$
\begin{aligned}
\Gamma(s+1)
&=\int_0^\infty x^s e^{-x}\,dx\\
&=[-x^se^{-x}]_0^\infty+s\int_0^\infty x^{s-1}e^{-x}\,dx
=s\Gamma(s).
\end{aligned}
$$

由 $\Gamma(1)=1$ 归纳得到

$$
\Gamma(n+1)=n!,\qquad n=0,1,2,\ldots.
$$

另一个关键值是

$$
\Gamma(1/2)=\sqrt\pi.
$$

在积分中令 $x=u^2$，就把 $\Gamma(1/2)$ 化为高斯积分。于是

$$
\Gamma(3/2)=\frac{\sqrt\pi}{2},\qquad
\Gamma(5/2)=\frac{3\sqrt\pi}{4},\qquad
\Gamma(7/2)=\frac{15\sqrt\pi}{8}.
$$

同一 Python 文件 `examples/python/13_continuous_dists.py` 的 ⑥ 节（原先独立的 Γ 函数脚本已并入）在 0 端采用变量代换，而不是直接把奇异点塞给 Simpson：

```python
m = max(2, ceil(1 / s)) if s < 1 else 1
if s < 1:
    low = simpson(
        lambda t: m * t ** (m * s - 1) * exp(-t ** m),
        0, 1, n // 2)
```

这里 $x=t^m$，所以 $dx=mt^{m-1}dt$，原被积函数变为 $mt^{ms-1}e^{-t^m}$。选择 $ms\ge1$ 后，0 端不再奇异。这是变量代换改善数值问题条件的实例。

程序还检查

```python
for s in range(1, 9):
    g = gamma_num(s)
    assert abs(g - factorial(s - 1)) < 1e-4 * factorial(s - 1)
```

数值结果与阶乘一致并不构成函数方程的证明；函数方程已由分部积分证明，数值只是独立审计。

## 13.4 Gamma 分布与 Erlang 分布

对形状 $k>0$、尺度 $\theta>0$，定义

$$
X\sim\operatorname{Gamma}(k,\theta),\qquad
f(x)=\frac{x^{k-1}e^{-x/\theta}}{\Gamma(k)\theta^k},\quad x\ge0.
$$

令 $t=x/\theta$，归一化立即化成 $\Gamma(k)$ 的定义。用同一代换，

$$
E[X^r]
=\theta^r\frac{\Gamma(k+r)}{\Gamma(k)}
=\theta^r k(k+1)\cdots(k+r-1)
$$

（最后一式对整数 $r\ge1$ 成立）。因此

$$
E[X]=k\theta,\qquad
\operatorname{Var}(X)=k\theta^2.
$$

当 $k=1$ 时就是指数分布。当 $k=n$ 为正整数时称为 Erlang 分布；它也是 $n$ 个独立同尺度指数变量之和。独立 Gamma 变量若尺度相同，形状参数相加，这一点在第 15 章用 MGF 证明最简洁。

同文件对 $k=2,\theta=3$ 检查均值 6、方差 18：

```python
fk = lambda x: x ** (k - 1) * exp(-x / sig) / (gamma_num(k) * sig ** k)
assert abs(simpson(fk, 1e-9, 80, 20000) - 1) < 1e-4
assert abs(simpson(lambda x: x * fk(x), 1e-9, 80, 20000) - k * sig) < 5e-3
```

这里被积函数指数衰减，有限窗口外有显式小尾量；窗口数值不是重尾积分的通用替代品。

## 13.5 Weibull 与广义 Gamma：把形状放进指数

Weibull 分布由指数分布的幂变换生成。若 $E\sim\operatorname{Exp}(1)$，令

$$
X=\theta E^{1/p},\qquad \theta>0,\ p>0,
$$

则

$$
P(X>x)=P(E>(x/\theta)^p)=e^{-(x/\theta)^p},
$$

所以

$$
f(x)=\frac p\theta\left(\frac x\theta\right)^{p-1}
e^{-(x/\theta)^p},\qquad x\ge0.
$$

风险率与 $(x/\theta)^{p-1}$ 成正比：$p>1$ 时递增，$0<p<1$ 时递减，$p=1$ 时回到指数分布。矩为

$$
E[X^r]=\theta^r\Gamma(1+r/p).
$$

广义 Gamma 进一步允许幂外再乘一个 Gamma 形状参数：

$$
f(x)=\frac{p}{\Gamma(k)\theta^{kp}}x^{kp-1}
e^{-(x/\theta)^p},\qquad x\ge0,
$$

其中 $k,p,\theta>0$。作 $t=(x/\theta)^p$，得到

$$
E[X^r]=\theta^r\frac{\Gamma(k+r/p)}{\Gamma(k)}.
$$

它包含 Gamma（$p=1$）和 Weibull（$k=1$）。同文件 ⑦ 节先作同一代换，再对变换后的积分作确定性数值审计：

```python
numerical = theta ** r * quad(
    lambda t: t ** (k + r / p - 1) * exp(-t), 0, 40,
    epsabs=1e-11, epsrel=1e-11)[0] / gamma(k)
closed = theta ** r * gamma(k + r / p) / gamma(k)
close(numerical, closed, 1e-9)
```

这里数值积分与闭式使用同一变换后的变量，但计算路径不同：一个积分，一个调用 Γ 函数。关键数学步骤仍是上面的换元证明。

## 13.6 Beta 函数与 Beta 分布

对 $a,b>0$，定义

$$
B(a,b)=\int_0^1t^{a-1}(1-t)^{b-1}\,dt
=\frac{\Gamma(a)\Gamma(b)}{\Gamma(a+b)}.
$$

第二个等式可从 $\Gamma(a)\Gamma(b)$ 的二重积分出发，作

$$
u=x+y,\qquad t=x/(x+y)
$$

得到；Jacobian 分离出 $u^{a+b-1}$ 与 $t^{a-1}(1-t)^{b-1}$。当 $a<1$ 或 $b<1$ 时，积分在端点奇异但仍可积。

Beta 分布的密度为

$$
f(x)=\frac{x^{a-1}(1-x)^{b-1}}{B(a,b)},\qquad0<x<1.
$$

利用 $E[X^r]=B(a+r,b)/B(a,b)$ 与 Γ 函数方程，

$$
E[X]=\frac a{a+b},
$$

$$
\operatorname{Var}(X)
=\frac{ab}{(a+b)^2(a+b+1)}.
$$

同文件对 $B(1/2,1/2)$ 采用 $t=\sin^2\theta$。此时 $dt=2\sin\theta\cos\theta\,d\theta$，两端奇异性被消去，积分化为

$$
B(1/2,1/2)=2\int_0^{\pi/2}d\theta=\pi.
$$

对应代码 deliberately 积分常数 2，而不是在 0、1 附近硬切小区间：

```python
B_half = simpson(lambda x: 2.0, 0, pi / 2, 1000)
rhs_half = gamma_num(0.5) * gamma_num(0.5) / gamma_num(1)
assert abs(B_half - rhs_half) < 2e-4 * rhs_half
```

## 13.7 Laplace：双侧指数与重尾对照

位置 $\mu\in\mathbb R$、尺度 $b>0$ 的 Laplace 密度是

$$
f(x)=\frac1{2b}e^{-|x-\mu|/b}.
$$

把 $X-\mu$ 看成随机符号乘以独立指数变量，立得

$$
E[X]=\mu,\qquad \operatorname{Var}(X)=2b^2.
$$

当 $x\ge\mu$ 时，

$$
F(x)=1-\frac12e^{-(x-\mu)/b}.
$$

它关于 $\mu$ 对称，但在 $\mu$ 处密度不可导；绝对值也使样本均值的似然分析与正态模型不同。其尾部是指数级，仍有所有阶矩，不能称为 Cauchy 那种均值不存在的重尾。

同文件 ⑦ 节通过对称密度和闭式 CDF 检查这些结构：

```python
left = exp(-abs((mu - x) - mu) / scale) / (2 * scale)
right = exp(-abs((mu + x) - mu) / scale) / (2 * scale)
close(left, right)
close(2 * scale ** 2, 8.0)
```

## 13.8 Julia：用固定种子样本审计连续模型

`examples/julia/13_continuous_dists.jl` 用模拟对拍，不替代上面的推导。第一段按逆变换公式生成指数样本，检验均值 $\theta$、方差 $\theta^2$ 与"半场无球"的概率 $e^{-3/2}$：

```julia
myexp(λ) = -λ * log(rand())
X = [myexp(2.5) for _ in 1:500_000]
@assert abs(mean(X) - 2.5) < 0.02
@assert abs(var(X) - 6.25) < 0.15

goals = [myexp(30.0) for _ in 1:500_000]
emp = count(>(45), goals) / length(goals)
@assert abs(emp - exp(-1.5)) < 0.004
```

整数形状的 Gamma 就是独立指数之和，因此可以直接"累加"来验证 $\operatorname{Gamma}(2,3)$ 的 $k\theta=6$、$k\theta^2=18$；Weibull 用 $X=\sigma(-\log U)^{1/k}$ 生成，并核对分位数公式：

```julia
sim_gamma(k, σ) = sum(myexp(σ) for _ in 1:k)
G = [sim_gamma(2, 3.0) for _ in 1:400_000]
@assert abs(mean(G) - 6) < 0.04
@assert abs(var(G) - 18) < 0.4

sim_weibull(k, σ) = σ * (-log(rand())) ^ (1 / k)
for k in (1.0, 2.0)
    W = [sim_weibull(k, 3.0) for _ in 1:300_000]
    for q in (0.5, 0.9)
        xq = 3.0 * (-log(1 - q)) ^ (1 / k)
        @assert abs(quantile(W, q) - xq) < 0.05 * xq
    end
end
```

最后一段是第 14 章的预告：标准 Cauchy 变量的平均 $(X+Y)/2$ 仍是 Cauchy，经验区间概率都等于 $\frac2\pi\arctan(\text{thr})$，而运行均值并不收敛：

```julia
cauchy() = tan(pi * (rand() - 0.5))
Ch = [(cauchy() + cauchy()) / 2 for _ in 1:200_000]
for thr in (1.0, 5.0, 20.0)
    e2 = count(t -> abs(t) <= thr, Ch) / length(Ch)
    @assert abs(e2 - 2 / pi * atan(thr)) < 0.005
end
```

这三段说明了模拟的角色：它能发现参数化写错（把速率当尺度），但不能证明无穷区间上的积分收敛。

## 13.9 Lean：函数方程与 Γ(1/2)

`examples/lean/Probability/Ch13ContinuousDists.lean` 把本章的算术锚点交给 `norm_num` 与 `ring`，并直接调用 mathlib 的 Γ 函数：

```lean
example (n : ℕ) : Real.Gamma (n + 1) = n.factorial := Real.Gamma_nat_eq_factorial n

example (s : ℝ) (hs : s ≠ 0) : Real.Gamma (s + 1) = s * Real.Gamma s :=
  Real.Gamma_add_one s hs

example : Real.Gamma (3 / 2) = Real.sqrt Real.pi / 2 := by
  have h := Real.Gamma_add_one (1 / 2 : ℝ) (by norm_num)
  rw [show (3 / 2 : ℝ) = 1 / 2 + 1 by norm_num, h, Real.Gamma_one_half_eq]
  ring
```

第一条是 $\Gamma(n+1)=n!$，第二条是 13.3 的分部积分结论，第三条是半整数链的一步。Gamma 方差 $k\theta^2$ 的参数账同样固定为有理数等式（如 $2\cdot3^2=18$）。机器证明的是这些具体事实，Gamma 密度归一化的积分推导仍以正文为准。

## 13.10 本章要点

1. 均匀分布由位置和尺度确定；指数分布的速率与尺度参数化不能混用。
2. 指数无记忆性等价于常风险率，真实系统是否满足该假设必须另行论证。
3. $\Gamma(s+1)=s\Gamma(s)$ 统一了阶乘、Gamma 矩、Beta 归一化和正态偶矩。
4. Weibull 与广义 Gamma 通过幂变换改变风险率和形状；换元 $t=(x/\theta)^p$ 是统一入口。
5. Beta 分布的矩来自 Beta 函数比值；Laplace 是双侧指数，方差为 $2b^2$。
6. 端点奇异的积分优先换元；固定窗口数值计算只在尾部有解析控制时才有意义。

*对应示例：`examples/lean/Probability/Ch13ContinuousDists.lean`、`examples/julia/13_continuous_dists.jl`、`examples/python/13_continuous_dists.py`。*

---

上一章：[12 离散分布族](12-discrete-dists.md) · 下一章：[14 正态、对数正态、柯西与稳定分布](14-normal-stable.md)
