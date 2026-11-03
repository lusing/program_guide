# 08 随机变量、分布函数与密度

随机试验的原始结果可以是牌、价格路径、订单序列或一封调查答卷。
概率论要进一步计算“收益超过多少”“等待时间多长的概率”，就需要把结果映成数。
本章统一离散、连续与混合型随机变量，并以累积分布函数作为三者共同的语言。

## 08.1 随机变量是把结果映成数的函数

给定概率空间 $(\Omega,\mathcal F,P)$ ，随机变量是函数

$$
X:\Omega\to\mathbb R.
$$

严格说，对任意实数 $x$ ，集合 $\{\omega:X(\omega)\le x\}$ 必须是事件，
即属于 $\mathcal F$ ；这就是可测性。有限样本空间上通常把每个子集都列为事件，
所以每个实值函数都自动可测。

例如三枚均匀硬币的样本空间有 8 个等可能结果。令 $X$ 为正面数，则

$$
X(HHT)=2,\qquad X(TTT)=0.
$$

随机性来自 $\omega$ ，而不是来自函数 $X$ 的神秘“随机输出”。
同一个样本空间可以承载许多随机变量：正面数、是否全正、第一枚是否为正面，
都是对同一结果的不同读数。

事件 $\{X\in B\}$ 是原像 $\{\omega:X(\omega)\in B\}$ 。
因此“$X=2$ 的概率”不是新公理，而是

$$
P(X=2)=P(\{\omega:X(\omega)=2\}).
$$

## 08.2 分布列：离散质量的完整账本

若 $X$ 只取有限个或可数个值，称其为离散随机变量。
其概率质量函数（pmf）为

$$
p_X(x)=P(X=x).
$$

pmf 必须满足

$$
p_X(x)\ge0,\qquad \sum_xp_X(x)=1.
$$

反过来，任意满足这两条的有限或可数表都能构造一个随机变量：
直接取样本空间为值域，并给点 $x$ 赋概率 $p_X(x)$ 。
所以 pmf 不依赖硬币、骰子等具体叙述；它已经完全决定离散分布。

三枚硬币中，恰有 $k$ 个正面的结果有 $\binom3k$ 个，因此

$$
p_X(k)=\frac{\binom3k}{8},\qquad k=0,1,2,3.
$$

完整表格为

| $k$ | 0 | 1 | 2 | 3 |
|---|---:|---:|---:|---:|
| $p_X(k)$ | $1/8$ | $3/8$ | $3/8$ | $1/8$ |

归一不是装饰性检查，而是在确认分类没有遗漏或重复。
两骰之和 $R$ 的 pmf 同理来自 36 个有序对：

$$
P(R=r)=\frac{6-|r-7|}{36},\qquad r=2,\ldots,12.
$$

和为 8 有 5 个有序对，故 $P(R=8)=5/36$ 。
这里不能先把点数和 2 到 12 当作 11 个等可能结果；
等可能的是原始有序对，而不是归并后的和值。

## 08.3 CDF：所有随机变量共有的分布函数

累积分布函数（CDF）定义为

$$
F_X(x)=P(X\le x),\qquad x\in\mathbb R.
$$

离散情形是累加

$$
F_X(x)=\sum_{t\le x}p_X(t),
$$

所以图像为阶梯；在每个有正质量的点跳高 $p_X(x)$ 。
三硬币例中 $F_X(2)=7/8$ ，而 $F_X(2^-)=1/2$ ，两者之差正是 $P(X=2)=3/8$ 。

CDF 有四条核心性质。

**第一，单调不减。**若 $a\le b$ ，则

$$
\{X\le a\}\subseteq\{X\le b\},
$$

由概率单调性得 $F_X(a)\le F_X(b)$ 。

**第二，两端极限为 0 与 1。**当 $x\downarrow-\infty$ 时，
事件 $\{X\le x\}$ 递降为空集；当 $x\uparrow+\infty$ 时，
事件递升为全空间。概率的上下连续性给出

$$
\lim_{x\to-\infty}F_X(x)=0,\qquad
\lim_{x\to+\infty}F_X(x)=1.
$$

**第三，右连续。**当 $x_n\downarrow x$ 时，
$\{X\le x_n\}\downarrow\{X\le x\}$ ，故

$$
F_X(x_n)\to F_X(x).
$$

右连续来自定义采用“$\le$ ”。
左极限则可能较小，其差额就是该点原子：

$$
P(X=x)=F_X(x)-F_X(x^-).
$$

**第四，区间概率由差值给出。**对 $a<b$ ，

$$
P(a<X\le b)=F_X(b)-F_X(a).
$$

这里左端点是否包含至关重要：减去 $F(a)$ 把 $X=a$ 的质量也减掉了。
若要求 $P(a\le X\le b)$ ，应写成 $F(b)-F(a^-)$ 。

反过来，任何单调不减、右连续且两端极限正确的函数，都是某个随机变量的 CDF。
这个构造性事实使 CDF 成为统一离散、连续和混合情形的标准接口。

## 08.4 连续分布：密度不是单点概率

若存在非负可积函数 $f_X$ ，使

$$
F_X(x)=\int_{-\infty}^{x}f_X(t)\,dt,
$$

则称 $X$ 有密度 $f_X$ （绝对连续分布）。归一条件为

$$
\int_{-\infty}^{\infty}f_X(x)\,dx=1.
$$

密度 $f_X(x)$ 不是 $P(X=x)$ 。
对有密度的分布，每个单点概率均为零；正确的局部读法是

$$
P(x<X\le x+\Delta x)\approx f_X(x)\Delta x
$$

（在密度连续且 $\Delta x$ 很小时）。密度可以有大于 1 的值，
因为它衡量的是“每单位长度的概率”，不是概率本身。

对均匀分布 $U[a,b]$ ，

$$
f(x)=\frac1{b-a}\mathbf1_{[a,b]}(x).
$$

落在子区间 $[c,d]\subset[a,b]$ 的概率是长度比 $(d-c)/(b-a)$ 。
另一个贯穿后文的例子是

$$
f(x)=2x\mathbf1_{[0,1]}(x),\qquad F(x)=x^2\quad(0\le x\le1).
$$

微积分基本定理告诉我们：在密度连续的点，$F'(x)=f(x)$ 。
因此 $P(1/4<X\le3/4)=(3/4)^2-(1/4)^2=1/2$ 。

归一化常数必须最后确定。形状 $2+3x-5x^2$ 在 $[0,1]$ 上非负，且

$$
\int_0^1(2+3x-5x^2)\,dx=2+\frac32-\frac53=\frac{11}{6},
$$

所以合法密度为

$$
f(x)=\frac6{11}(2+3x-5x^2),\qquad0\le x\le1.
$$

相应 CDF 为

$$
F(x)=\frac6{11}\left(2x+\frac32x^2-\frac53x^3\right).
$$

直接代入得 $F(1/2)=7/11$ 。
非负但整轴面积无限的函数，例如恒等于 1，无法通过乘常数变成密度。

## 08.5 混合型：跳点与斜坡必须分账

并非每个 CDF 都只属于前两类的某一种。考虑

$$
F(x)=
\begin{cases}
0,&x<0,\\
\frac12+\frac x2,&0\le x<1,\\
1,&x\ge1.
\end{cases}
$$

它在 0 处从 0 跳到 $1/2$ ，所以 $P(X=0)=1/2$ ；
在 $(0,1)$ 上斜率为 $1/2$ ，连续部分总质量也是 $1/2$ 。
于是

$$
P(0<X\le1/2)=F(1/2)-F(0)=3/4-1/2=1/4.
$$

对混合型变量，不能把全部概率写成一个 pmf，也不能把全部概率写成普通 pdf。
原子用跳高记录，绝对连续部分用密度积分记录。
后续多变量与测度论章节会进一步讨论奇异连续分布；本章先掌握“跳点加斜坡”的可计算模型。

## 08.6 机器通道：从样本点到统一 CDF

Python 文件 `examples/python/08_random_variables.py` 先枚举三枚硬币，再累加 CDF：

```python
outcomes = list(product("HT", repeat=3))
pmf3 = {}
for outcome in outcomes:
    k = outcome.count("H")
    pmf3[k] = pmf3.get(k, Fraction(0)) + Fraction(1, 8)
cdf3, acc = {}, Fraction(0)
for k in range(4):
    acc += pmf3[k]
    cdf3[k] = acc
assert cdf3[2] == Fraction(7, 8)
```

每个原始结果权重为 $1/8$ ，字典按键归并实现从样本空间到值域的推前分布。
这是有限空间精确穷举，不是随机模拟。

同一文件的连续与混合账使用精确多项式积分和分段 CDF：

```python
def Fmix(x):
    if x < 0:
        return Fraction(0)
    if x == 0:
        return Fraction(1, 2)
    if x <= 1:
        return Fraction(1, 2) + x / 2
    return Fraction(1)

assert Fmix(Fraction(1, 2)) - Fmix(0) == Fraction(1, 4)
```

该断言专门防止把原子 $1/2$ 再算进左开区间。

Julia 文件 `examples/julia/08_random_variables.jl` 用概率树折层和固定种子采样交叉检查。
多项式密度的拒绝采样核心是：

```julia
fpoly(x) = (6/11) * (2 + 3x - 5x^2)
x, u = rand(), rand()
u * 1.5 <= fpoly(x) && push!(out, x)
```

候选 $x$ 均匀落在 $[0,1]$ ，只有 $1.5u\le f(x)$ 才接受。
因为 $1.5$ 是密度上界，接受概率与 $f(x)$ 成正比。
模拟只核对 $F(1/2)=7/11$ 的数值实现；精确结论仍来自积分。

Prolog 文件 `examples/prolog/08_random_variables.pl` 穷举位串和骰子有序对：

```prolog
findall(R, (between(1, 6, A), between(1, 6, B), R is A + B), Rs),
length(Rs, 36),
forall(between(2, 12, R),
       (count_occ(R, Rs, N), N =:= 6 - abs(R - 7))).
```

`findall` 保留全部 36 个结果，`count_occ` 按和值计数。
它直接验证三角形 pmf，而不是用直方图逼近。

Lean 文件 `examples/lean/Probability/Ch08RandomVariables.lean` 同时固定离散和连续锚点：

```lean
example (x : ℝ) : HasDerivAt (fun y => y ^ 2) (2 * x) x := by
  simpa using hasDerivAt_pow 2 x

example : (3 / 4 : ℝ) ^ 2 - (1 / 4) ^ 2 = 1 / 2 := by norm_num
```

第一例由机器证明 $F(x)=x^2$ 的导数为 $2x$ ；第二例固定对应区间概率。
这些不是模拟，而是 Lean 内核检查的定理。

## 08.7 本章要点

1. 随机变量是样本空间上的实值可测函数；随机性来自样本点。
2. pmf 记录离散单点质量，pdf 通过积分给出区间概率，二者不能混读。
3. CDF $F(x)=P(X\le x)$ 统一所有分布，并满足单调、右连续和两端极限。
4. $P(a<X\le b)=F(b)-F(a)$ ，单点质量为 $F(x)-F(x^-)$ 。
5. 有密度的分布单点概率为零，但密度本身可以大于 1。
6. 混合型同时含原子和连续部分，必须分别记账。
7. 有限枚举、精确积分、固定种子模拟和机器证明是不同证据等级。

*对应示例：`examples/lean/Probability/Ch08RandomVariables.lean`、
`examples/julia/08_random_variables.jl`、
`examples/python/08_random_variables.py`、
`examples/prolog/08_random_variables.pl`。*

---

上一章：[07 计数实验](07-counting-lab.md) · 下一章：[09 数学期望、矩、分位数与风险](09-expectation.md)
