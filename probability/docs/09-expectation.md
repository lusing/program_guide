# 09 数学期望、矩、分位数与风险

分布给出完整概率账，但实际决策常需要少数汇总量：平均收益、波动、尾部位置和效用。
本章定义数学期望，说明何时它存在，推导线性与方差公式，并比较均值、分位数和风险的不同含义。

## 09.1 期望是概率加权平均，先要检查可积性

离散随机变量的期望定义为

$$
E[X]=\sum_xxp_X(x),
$$

连续有密度时定义为

$$
E[X]=\int_{-\infty}^{\infty}xf_X(x)\,dx.
$$

只要 $E|X|<\infty$ ，称 $X$ 可积，此时期望存在且为有限实数。
这个绝对收敛条件不是技术洁癖：若正部和负部都为无穷，
“净均值”会因求和或积分路径不同而改变。

更一般地，对函数 $g$ ，无意识统计学家公式（LOTUS）给出

$$
E[g(X)]=\sum_xg(x)p_X(x)
$$

或

$$
E[g(X)]=\int g(x)f_X(x)\,dx,
$$

前提是 $E|g(X)|<\infty$ 。
它的意义是：不必先求 $g(X)$ 的分布，直接在原分布上加权即可。
第 10 章的变换密度与这里的原空间计算必须互相一致。

期望的线性性为

$$
E[aX+bY+c]=aE[X]+bE[Y]+c.
$$

证明只需展开求和或积分；不需要 $X,Y$ 独立。
例如任何可积随机变量都有 $E[3X+2]=3E[X]+2$ 。

## 09.2 矩、均值和方差

$r$ 阶矩为 $E[X^r]$ ，$r$ 阶中心矩为 $E[(X-\mu)^r]$ ，其中 $\mu=E[X]$ 。
一阶矩是重心，二阶中心矩是方差：

$$
\operatorname{Var}(X)=E[(X-\mu)^2].
$$

展开平方并使用线性性：

$$
\begin{aligned}
\operatorname{Var}(X)
&=E[X^2-2\mu X+\mu^2]\\
&=E[X^2]-2\mu E[X]+\mu^2\\
&=E[X^2]-\mu^2.
\end{aligned}
$$

所以

$$
\boxed{\operatorname{Var}(X)=E[X^2]-E[X]^2}.
$$

方差非负，因此也得到 $E[X^2]\ge E[X]^2$ 。
标准差 $\sigma=\sqrt{\operatorname{Var}(X)}$ 与 $X$ 同单位，
方差则带平方单位；比较实际波动尺度时通常用标准差。

平移伸缩满足

$$
E[aX+b]=a\mu+b,\qquad
\operatorname{Var}(aX+b)=a^2\operatorname{Var}(X).
$$

常数 $b$ 只搬动整体，不改变围绕均值的散布；
系数 $a$ 在平方后进入方差。

公平骰子的账为

$$
E[X]=\frac{1+\cdots+6}{6}=\frac72,
\qquad E[X^2]=\frac{91}{6},
$$

故

$$
\operatorname{Var}(X)=\frac{91}{6}-\frac{49}{4}=\frac{35}{12}.
$$

两骰之和 $R$ 的 pmf 关于 7 对称，所以 $E[R]=7$ ；
直接求和得 $\operatorname{Var}(R)=35/6$ ，恰是两颗独立骰子的方差之和。

## 09.3 多项式密度的完整矩账

继续使用第 08 章的密度

$$
f(x)=\frac6{11}(2+3x-5x^2),\qquad0\le x\le1.
$$

对非负整数 $r$ ，

$$
\begin{aligned}
E[X^r]
&=\frac6{11}\int_0^1x^r(2+3x-5x^2)\,dx\\
&=\frac6{11}\left(\frac2{r+1}+\frac3{r+2}-\frac5{r+3}\right)\\
&=\frac6{11}\frac{7r+11}{(r+1)(r+2)(r+3)}.
\end{aligned}
$$

代入 $r=1$ 得

$$
E[X]=\frac9{22}.
$$

代入 $r=2$ 得 $E[X^2]=5/22$ ，所以

$$
\operatorname{Var}(X)=\frac5{22}-\left(\frac9{22}\right)^2
=\frac{29}{484}.
$$

这里“有密度”只保证总质量可积，不保证任意函数都可积。
例如

$$
E[1/X]=\frac6{11}\int_0^1\frac{2+3x-5x^2}{x}\,dx
$$

不存在，因为靠近 0 时被积函数的主项为 $2/x$ ，而

$$
\int_\varepsilon^1\frac{2}{x}\,dx=-2\log\varepsilon\to\infty.
$$

同一随机变量的均值有限，但 $1/X$ 的期望为 $+\infty$ 。
任何涉及倒数、对数或高次幂的期望，都应重新检查尾部与奇点。

## 09.4 Cauchy：对称不等于均值存在

标准 Cauchy 密度为

$$
f(x)=\frac1{\pi(1+x^2)},\qquad x\in\mathbb R.
$$

它合法归一，但

$$
E|X|=\frac2\pi\int_0^\infty\frac{x}{1+x^2}\,dx=\infty,
$$

因为原函数是 $\log(1+x^2)/2$ 。
所以 Cauchy 均值不存在。

有人会用奇函数对称性写成

$$
\lim_{A\to\infty}\int_{-A}^{A}\frac{x}{\pi(1+x^2)}\,dx=0.
$$

这只是对称主值，不是期望。改取不对称区间：

$$
\int_{-A}^{2A}\frac{x}{\pi(1+x^2)}\,dx
=\frac1{2\pi}\log\frac{1+4A^2}{1+A^2}
\to\frac{\log2}{\pi}\ne0.
$$

积分路径改变，极限就改变，正是绝对可积条件要排除的情况。
“分布关于 0 对称”与“均值为 0”不是同一命题。

## 09.5 分位数：按累计质量定位

对 $0<u<1$ ，下分位数定义为

$$
q_u=F^-(u)=\inf\{x:F(x)\ge u\}.
$$

若 $F$ 连续且严格增，这就是通常反函数 $F^{-1}(u)$ 。
中位数是 $q_{1/2}$ 。它只要求一半质量在左侧、一半在右侧，
不要求随机变量可积，因此 Cauchy 的中位数仍为 0。

对密度 $2x$ （$0<x<1$ ），$F(x)=x^2$ ，所以

$$
q_u=\sqrt u,\qquad q_{1/2}=1/\sqrt2\approx0.7071.
$$

均值为 $2/3$ ，中位数却更大：分布的质量向 1 端集中，
但左尾把加权平均拉低。均值、中位数和众数回答不同问题，不应相互替代。

分位数也是风险管理中的位置指标。若 $L$ 表示损失，
给定置信水平 $u$ 的 VaR 常写为 $q_u(L)$ 。
它说明某个累计概率对应的损失阈值，却不说明超过阈值后的平均损失；
尾部形状仍需另外分析。

## 09.6 期望效用与组合风险

若财富为 $W$ ，效用函数为 $u$ ，期望效用准则是比较 $E[u(W)]$ ，
而不是只比较 $E[W]$ 。例如 $u$ 凹时表示边际效用递减：
同样增加一元财富，在贫穷时的价值高于富裕时。
第 11 章的 Jensen 不等式将把这种“凹函数下风险厌恶”写成严格数学结论。

组合风险则展示方差如何进入决策。设两个独立收益 $X_1,X_2$
均有均值 3、方差 2，组合

$$
S_w=wX_1+(1-w)X_2.
$$

均值恒为 3。独立性使交叉协方差为零，故

$$
\operatorname{Var}(S_w)=2\bigl(w^2+(1-w)^2\bigr)
=4\left(w-\frac12\right)^2+1.
$$

因此 $w=1/2$ 时方差最小，为 1。
等权分散把方差减半而不改变均值，但这个结论使用了独立性与有限二阶矩；
若收益完全正相关，就没有同样的分散效果。

这里需要区分三件事：

- 线性期望不需要独立；
- 独立乘积期望 $E[XY]=E[X]E[Y]$ 需要相应可积条件；
- 和方差可加来自独立或更一般的零协方差条件。

完整的联合分布、协方差和条件期望将在第 17–20 章展开。

## 09.7 机器通道：精确矩账与风险对照

Python 文件 `examples/python/09_expectation.py` 用 `Fraction` 同时计算定义式与捷径：

```python
E = lambda pairs: sum(Fraction(x) * p for x, p in pairs)
Var_def = lambda pairs: sum(
    (Fraction(x) - E(pairs)) ** 2 * p for x, p in pairs)
Var_short = lambda pairs: (
    sum(Fraction(x) ** 2 * p for x, p in pairs) - E(pairs) ** 2)

assert Var_def(die) == Var_short(die) == Fraction(35, 12)
```

`pairs` 是“取值、概率”的有限分布表。两种算法结果完全相同，
既验证方差公式，也检查实现没有漏掉均值项。

多项式矩的核心断言是：

```python
integrand = [Fraction(0)] * r + shape
num = poly_integral(integrand, Fraction(0), Fraction(1))
closed = Fraction(7 * r + 11) / ((r + 1) * (r + 2) * (r + 3))
assert num == closed
assert E1 == Fraction(9, 22)
```

在系数列表前补 $r$ 个零，就把多项式乘以 $x^r$ 。
程序对 $r=1,\ldots,5$ 精确核对闭式。

Julia 文件 `examples/julia/09_expectation.jl` 使用固定种子模拟投资组合：

```julia
S = w .* X1 .+ (1 .- w) .* X2
target = σ2 * (w^2 + (1 - w)^2)
@assert abs(var(S) - target) < 0.05
```

解析抛物线给出最优点，模拟只检查数值采样与目标公式相容。
文件还对拍正态与 Cauchy 的滚动样本均值；Cauchy 的震荡是均值不存在的数值表现，
不是对不存在性的证明，证明仍是 09.4 的积分路径反例。

Lean 文件 `examples/lean/Probability/Ch09Expectation.lean` 固定精确矩账：

```lean
example : (91 / 6 : ℚ) - (7 / 2) ^ 2 = 35 / 12 := by norm_num
example : (((1 : ℚ) / 2) ^ 2 + (1 - 1 / 2) ^ 2) * 2 = 1 := by norm_num
```

第一例是骰子方差捷径，第二例是等权组合方差减半。
它们是可复查的精确算术定理。

Isabelle 文件 `examples/isabelle/MT09/T09_Expectation.thy` 用区间积分验证密度 $2x$ 的期望：

```isabelle
lemma two_x_expect:
  "(LBINT x=(0::real)..(1::real). x * (2 * x)) = (2/3::real)"
```

证明先给反导数 $(2/3)x^3$ ，再应用区间积分的基本定理。
数值界显式写成 `0::real` 与 `1::real`，避免把积分端点误推成扩展实数。

## 09.8 本章要点

1. 期望存在要求绝对可积；对称主值不等于期望。
2. LOTUS 允许在原分布上计算 $E[g(X)]$ ，但必须检查 $g(X)$ 的可积性。
3. 期望线性不需要独立；方差可加需要零协方差等额外条件。
4. $\operatorname{Var}(X)=E[X^2]-E[X]^2$ ，标准差才与原变量同单位。
5. Cauchy 均值不存在，但中位数存在；均值与分位数不可混用。
6. 合法密度不保证 $E[1/X]$ 存在，奇点和尾部必须逐例检查。
7. 期望效用与组合方差连接概率模型和经济决策，结论依赖明确假设。

*对应示例：`examples/lean/Probability/Ch09Expectation.lean`、
`examples/isabelle/MT09/T09_Expectation.thy`、
`examples/julia/09_expectation.jl`、
`examples/python/09_expectation.py`。*

---

上一章：[08 随机变量、分布函数与密度](08-random-variables.md) · 下一章：[10 一元随机变量变换](10-transformations.md)
