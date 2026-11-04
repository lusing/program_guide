# 第 17 章 联合、边际与条件分布

## 17.1 为什么一元分布不够

到第 16 章为止，我们已经能处理一个随机变量的分布、矩、变换和独立和。经济数据却几乎总是多维的：收入与教育、资产收益之间、宏观冲击与政策变量都同时变化。只研究每个变量的一元分布，会丢失它们之间最关键的信息。例如两个随机变量可以都有标准正态边际，但可以独立、完全函数相依，或者具有其他完全不同的联合结构。

本章把概率质量函数和概率密度函数推广到多维情形，并围绕三件事展开：

1. **联合分布**描述整个随机向量落在各区域中的概率；
2. **边际分布**通过“把其他变量积掉或求和掉”恢复单个变量；
3. **条件分布**描述已知一个变量后，另一个变量的分布如何改变。

这三者由归一化、乘法公式和全概率公式连接。下一章将把第 10 章的一元变量变换推广为多元 Jacobian；本章先把分布对象本身建立清楚。

## 17.2 离散联合分布

设 $X$ 和 $Y$ 都是离散随机变量。联合概率质量函数为

$$
p_{X,Y}(x,y)=P(X=x,Y=y).
$$

若两个变量的取值集分别为 $\mathcal X,\mathcal Y$ ，则归一化条件是

$$
\sum_{x\in\mathcal X}\sum_{y\in\mathcal Y}p_{X,Y}(x,y)=1.
$$

两个边际质量函数分别为

$$
p_X(x)=\sum_{y\in\mathcal Y}p_{X,Y}(x,y),\qquad
p_Y(y)=\sum_{x\in\mathcal X}p_{X,Y}(x,y).
$$

当 $p_X(x)>0$ 时，给定 $X=x$ ，$Y$ 的条件质量函数是

$$
p_{Y|X}(y|x)=\frac{p_{X,Y}(x,y)}{p_X(x)}.
$$

它自动归一，因为

$$
\sum_y p_{Y|X}(y|x)
=\frac{\sum_y p_{X,Y}(x,y)}{p_X(x)}
=\frac{p_X(x)}{p_X(x)}=1.
$$

同理，$p_{X|Y}(x|y)=p_{X,Y}(x,y)/p_Y(y)$ 。

### 17.2.1 一张边际均匀却不独立的表

本章所有有限程序都使用下面这张 $3\times3$ 表：

$$
\begin{array}{c|ccc|c}
 &Y=0&Y=1&Y=2&p_X\\\hline
X=0&1/12&1/12&1/6&1/3\\
X=1&1/12&1/6&1/12&1/3\\
X=2&1/6&1/12&1/12&1/3\\\hline
p_Y&1/3&1/3&1/3&1
\end{array}
$$

九格之和为 1，两个边际都均匀。但边际均匀并不意味着独立。例如

$$
p_{X,Y}(0,2)=\frac16,\qquad p_X(0)p_Y(2)=\frac13\cdot\frac13=\frac19.
$$

因此 $p_{X,Y}(0,2)\ne p_X(0)p_Y(2)$ 。另一方面，给定 $X=0$ ，

$$
P(Y=2\mid X=0)=\frac{1/6}{1/3}=\frac12.
$$

这与无条件概率 $P(Y=2)=1/3$ 不同，正说明 $Y$ 的预测会随 $X$ 的信息改变。

`examples/python/17_joint_distributions.py` 用 `Fraction` 做精确分数运算，避免浮点打印造成“看起来相等”：

```python
table = {
    (0, 0): F(1, 12), (0, 1): F(1, 12), (0, 2): F(1, 6),
    (1, 0): F(1, 12), (1, 1): F(1, 6),  (1, 2): F(1, 12),
    (2, 0): F(1, 6),  (2, 1): F(1, 12), (2, 2): F(1, 12),
}
assert sum(table.values()) == 1
pX = {x: sum(table[x, y] for y in range(3)) for x in range(3)}
pY = {y: sum(table[x, y] for x in range(3)) for y in range(3)}
assert pX == {0: F(1, 3), 1: F(1, 3), 2: F(1, 3)}
for x in range(3):
    cond = {y: table[x, y] / pX[x] for y in range(3)}
    assert sum(cond.values()) == 1
assert table[0, 2] / pX[0] == F(1, 2)
assert any(table[x, y] != pX[x] * pY[y] for x, y in table)
```

这些断言的含义依次是：联合表归一、边际正确、每行条件分布归一、指定条件概率为 $1/2$ ，以及独立因子分解失败。

`examples/prolog/17_joint_distributions.pl` 用同一组事实做有限穷举：

```prolog
p(0,0, 1 rdiv 12). p(0,1, 1 rdiv 12). p(0,2, 1 rdiv 6).
p(1,0, 1 rdiv 12). p(1,1, 1 rdiv 6).  p(1,2, 1 rdiv 12).
p(2,0, 1 rdiv 6).  p(2,1, 1 rdiv 12). p(2,2, 1 rdiv 12).

marg_x(X, M) :- aggregate_all(sum(P), pr(X, _, P), M).
marg_y(Y, M) :- aggregate_all(sum(P), pr(_, Y, P), M).
cond_y_given_x(Y, X, C) :- pr(X, Y, P), marg_x(X, M), C is P / M.
```

Prolog 的价值不在于数值规模，而在于把“对所有格点检查”写成显式的 `forall` 和 `aggregate_all`。如果有一个格点不满足边际积，程序就能抓到它。

Lean 锚点在 `examples/lean/Probability/Ch17JointDistributions.lean`。它把同一张表定义成 `Fin 3 → Fin 3 → ℚ` 上的矩阵，并用 `fin_cases` 逐行、逐列判决：

```lean
def jt : Fin 3 → Fin 3 → ℚ :=
  ![![1/12, 1/12, 1/6], ![1/12, 1/6, 1/12], ![1/6, 1/12, 1/12]]

example : ∑ y : Fin 3, jt 0 y / (∑ y' : Fin 3, jt 0 y') = 1 := by
  simp [jt, Fin.sum_univ_three]; norm_num
```

Prolog 和 Python 是可执行枚举；Lean 这里是关于有限表的形式化断言。二者都不是模拟。

## 17.3 联合密度、边际密度与条件密度

若随机向量 $(X,Y)$ 有联合概率密度 $f_{X,Y}$ ，则对平面上可测区域 $A$ ，

$$
P((X,Y)\in A)=\iint_A f_{X,Y}(x,y)\,dx\,dy,
$$

且

$$
\int_{\mathbb R^2}f_{X,Y}(x,y)\,dx\,dy=1.
$$

边际密度由积分得到：

$$
f_X(x)=\int_{\mathbb R}f_{X,Y}(x,y)\,dy,\qquad
f_Y(y)=\int_{\mathbb R}f_{X,Y}(x,y)\,dx.
$$

当 $f_X(x)>0$ 时，给定 $X=x$ 的条件密度定义为

$$
f_{Y|X}(y|x)=\frac{f_{X,Y}(x,y)}{f_X(x)}.
$$

这里的“给定 $X=x$ ”在连续情形中是一个概率为零的事件，不能机械地代入初等条件概率公式。严格理解需要正则条件分布或极限族；在密度存在且 $f_X(x)>0$ 的点，上式给出标准版本。

条件密度的归一化仍然成立：

$$
\int f_{Y|X}(y|x)\,dy
=\frac{1}{f_X(x)}\int f_{X,Y}(x,y)\,dy=1.
$$

### 17.3.1 单位圆盘上的均匀分布

令 $(X,Y)$ 在单位圆盘 $D=\{(x,y):x^2+y^2\le1\}$ 上均匀。圆盘面积是 $\pi$ ，所以

$$
f_{X,Y}(x,y)=
\begin{cases}
1/\pi,&x^2+y^2\le1,\\
0,&\text{其他}.
\end{cases}
$$

固定 $x\in[-1,1]$ ，$y$ 的合法范围是
$-\sqrt{1-x^2}\le y\le\sqrt{1-x^2}$ ，故

$$
f_X(x)=\int_{-\sqrt{1-x^2}}^{\sqrt{1-x^2}}\frac1\pi\,dy
=\frac{2}{\pi}\sqrt{1-x^2}.
$$

其积分为圆盘面积除以 $\pi$ ：

$$
\int_{-1}^1\frac2\pi\sqrt{1-x^2}\,dx=1.
$$

给定 $X=x$ ，条件密度为

$$
f_{Y|X}(y|x)
=\frac{1/\pi}{(2/\pi)\sqrt{1-x^2}}
=\frac1{2\sqrt{1-x^2}},
\quad |y|\le\sqrt{1-x^2}.
$$

所以 $Y|X=x$ 在长度为 $2\sqrt{1-x^2}$ 的区间上均匀。但 $X,Y$ 并不独立：圆盘外点 $(0.9,0.9)$ 的联合密度为 0，而两个边际密度在这些点都为正。

Python 符号积分精确核对了边际、归一化和条件密度：

```python
fXY = 1 / sp.pi
fX = sp.integrate(fXY, (y, -sp.sqrt(1 - x**2), sp.sqrt(1 - x**2)))
assert sp.simplify(fX - 2 * sp.sqrt(1 - x**2) / sp.pi) == 0
assert sp.simplify(sp.integrate(fX, (x, -1, 1)) - 1) == 0
fcond = fXY / fX
assert sp.simplify(fcond - 1 / (2 * sp.sqrt(1 - x**2))) == 0
```

`examples/julia/17_joint_distributions.jl` 用固定种子拒绝采样从圆盘取样。它把样本直方图与解析边际比较，但这只是模拟审计：

```julia
while length(xs) < N
    a = 2rand() - 1; b = 2rand() - 1
    if a^2 + b^2 <= 1
        push!(xs, a); push!(ys, b)
    end
end
fX(x) = 2 * sqrt(1 - x^2) / pi
emp = count(x -> 0.4 <= x < 0.5, xs) / N
@assert abs(emp - simpson(fX, 0.4, 0.5)) < 0.004
```

拒绝采样持续到收集到固定数量样本，因此样本数量确定；随机种子为 17。它验证实现与公式相符，却不替代上面的符号积分。

### 17.3.2 三角支撑：指数边际与条件无记忆性

令

$$
f_{X,Y}(x,y)=e^{-y},\qquad 0<x<y<\infty.
$$

先验归一化：

$$
\int_0^\infty\int_x^\infty e^{-y}\,dy\,dx
=\int_0^\infty e^{-x}\,dx=1.
$$

两个边际密度是

$$
f_X(x)=\int_x^\infty e^{-y}\,dy=e^{-x},\qquad x>0,
$$

$$
f_Y(y)=\int_0^y e^{-y}\,dx=ye^{-y},\qquad y>0.
$$

因此 $X\sim\operatorname{Exp}(1)$ ，而 $Y\sim\Gamma(2,1)$ 。条件密度为

$$
f_{Y|X}(y|x)=e^{-(y-x)},\quad y>x,
$$

以及

$$
f_{X|Y}(x|y)=\frac1y,\quad 0<x<y.
$$

第一个条件分布表示 $Y-X\mid X=x\sim\operatorname{Exp}(1)$ ，所以它具有无记忆性；第二个条件分布表示 $X\mid Y=y\sim U(0,y)$ 。

还能用两种方法算 $E[Y]$ ：

$$
E[Y]=\int_0^\infty y\,ye^{-y}\,dy=\Gamma(3)=2,
$$

或者使用全期望公式：

$$
E[Y]=E[E[Y|X]]=E[X+1]=2.
$$

Python 对这两个条件密度及无记忆尾概率做符号积分：

```python
fY_given_X = sp.simplify(fxy / fXm)       # e^{-(y-x)}, y>x
fX_given_Y = sp.simplify(fxy / fYm)       # 1/y, 0<x<y
tail = sp.integrate(fY_given_X.subs(y, x + t), (t, s, sp.oo))
assert sp.simplify(tail - sp.exp(-s)) == 0
assert sp.integrate(y * fYm, (y, 0, sp.oo)) == 2
```

Julia 则按等价生成机制 $X=E_1$ 、$Y=X+E_2$ ，其中 $E_1,E_2$ 独立且均为 $\operatorname{Exp}(1)$ ，模拟核对条件均值：

```julia
X = -log.(rand(N)); E = -log.(rand(N)); Y = X .+ E
@assert abs(mean(X) - 1) < 0.02 && abs(mean(Y) - 2) < 0.03
selY = Y[abs.(X .- 1) .< 0.02] .- 1
@assert abs(mean(selY) - 1) < 0.08
selX = X[abs.(Y .- 2) .< 0.05]
@assert abs(mean(selX) - 1) < 0.08
```

条件 $X\approx1$ 是一个窄条带，而不是单点；模拟结果应理解为对连续条件密度的有限带宽近似。

## 17.4 独立性与因子分解

离散随机变量 $X,Y$ 独立，当且仅当对所有 $x,y$ ，

$$
p_{X,Y}(x,y)=p_X(x)p_Y(y).
$$

对有密度的随机变量，独立当且仅当

$$
f_{X,Y}(x,y)=f_X(x)f_Y(y)
$$

几乎处处成立。由此可得两个重要结论。

第一，独立时条件分布等于边际分布：

$$
p_{Y|X}(y|x)=\frac{p_X(x)p_Y(y)}{p_X(x)}=p_Y(y),
$$

连续情形同理有 $f_{Y|X}(y|x)=f_Y(y)$ 。

第二，矩形概率可以分解。离散情形中，

$$
P(a<X\le b,c<Y\le d)
=P(a<X\le b)P(c<Y\le d).
$$

连续情形中，联合 CDF 为

$$
F_{X,Y}(x,y)=F_X(x)F_Y(y),
$$

矩形概率为二阶差分

$$
P(a<X\le b,c<Y\le d)
=F(b,d)-F(a,d)-F(b,c)+F(a,c).
$$

### 17.4.1 独立指数与 $P(X<Y)$

设 $X\sim\operatorname{Exp}(\lambda)$ 、$Y\sim\operatorname{Exp}(\mu)$ 且独立，则

$$
f_{X,Y}(x,y)=\lambda\mu e^{-\lambda x-\mu y},\qquad x,y>0.
$$

事件 $X<Y$ 的概率为

$$
\begin{aligned}
P(X<Y)
&=\int_0^\infty\int_x^\infty
\lambda\mu e^{-\lambda x-\mu y}\,dy\,dx\\
&=\int_0^\infty \lambda e^{-(\lambda+\mu)x}\,dx
=\frac{\lambda}{\lambda+\mu}.
\end{aligned}
$$

对称地，$P(Y<X)=\mu/(\lambda+\mu)$ ，两者之和为 1。连续独立变量满足 $P(X=Y)=0$ 。

Python 同时核对二重积分和联合 CDF 的矩形公式：

```python
f_ind = lam * mu * sp.exp(-lam * x - mu * y)
p_less = sp.integrate(sp.integrate(f_ind, (y, x, sp.oo)), (x, 0, sp.oo))
assert sp.simplify(p_less - lam / (lam + mu)) == 0
Fxy = (1 - sp.exp(-lam * x)) * (1 - sp.exp(-mu * y))
```

Julia 用 $(\lambda,\mu)=(1,3)$ 的固定种子样本核对 $1/4$ ：

```julia
λ, μ = 1.0, 3.0
Xe = -log.(rand(N)) ./ λ; Ye = -log.(rand(N)) ./ μ
@assert abs(mean(Xe .< Ye) - λ / (λ + μ)) < 0.005
```

解析推导给证明，模拟只检查实现和采样误差范围内的数值一致性。

## 17.5 混合型联合分布与 Bayes 密度

设 $Z\in\{0,1\}$ 是离散潜变量，而 $Y$ 在给定 $Z$ 后连续。若

$$
P(Z=1)=\pi,\quad f_{Y|Z}(y|1)=f_1(y),\quad
f_{Y|Z}(y|0)=f_0(y),
$$

则 $Y$ 的边际密度是混合密度

$$
f_Y(y)=(1-\pi)f_0(y)+\pi f_1(y).
$$

连续形式的 Bayes 公式为

$$
P(Z=1\mid Y=y)=\frac{\pi f_1(y)}
{(1-\pi)f_0(y)+\pi f_1(y)}.
$$

这不是“除以概率 $P(Y=y)$ ”，因为 $P(Y=y)=0$ ；它来自密度层面的乘法公式和正则条件分布。

程序取 $\pi=1/3$ 、$f_0(y)=e^{-y}$ 、$f_1(y)=3e^{-3y}$ 。于是

$$
f_Y(y)=\frac23e^{-y}+\frac13\cdot3e^{-3y}
=\frac23e^{-y}+e^{-3y},
$$

且

$$
P(Z=1\mid Y=y)
=\frac{e^{-3y}}{\frac23e^{-y}+e^{-3y}}.
$$

当 $y\to0^+$ 时，后验概率为

$$
\frac{1}{2/3+1}=\frac35,
$$

而当 $y\to\infty$ 时，因 $e^{-3y}$ 比 $e^{-y}$ 下降更快，后验趋于 0。Python 精确检查这两个极限和全概率积分：

```python
post1 = sp.simplify(pz1 * f1 / fY)
assert sp.limit(post1, y, 0) == sp.Rational(3, 5)
assert sp.limit(post1, y, sp.oo) == 0
assert sp.simplify(sp.integrate(post1 * fY, (y, 0, sp.oo)) - pz1) == 0
```

最后一个等式是连续全概率公式：

$$
\int P(Z=1\mid Y=y)f_Y(y)\,dy=P(Z=1).
$$

## 17.6 条件化在零概率事件上的陷阱

同一个零概率集合，如果用不同的随机变量或不同的极限族逼近，可能得到不同的条件分布。程序展示了一对独立指数变量 $X,Y$ 的两种条件化。

第一种使用 $V=Y-X$ 并条件化 $V=0$ 。从 $(x,v)$ 到 $(x,y)$ 的变换为 $y=x+v$ ，Jacobian 绝对值为 1，所以

$$
f_{X,V}(x,v)=e^{-2x-v},\qquad x>0,\ v>-x.
$$

在 $v=0$ 的切片上，$f_{X|V=0}(x|0)\propto e^{-2x}$ ，即 $\operatorname{Exp}(2)$ 。

第二种使用 $W=Y/X$ 并条件化 $W=1$ 。由 $y=xw$ 得 Jacobian 绝对值为 $x$ ，所以

$$
f_{X,W}(x,w)=x e^{-x(1+w)},\qquad x,w>0.
$$

在 $w=1$ 的切片上，$f_{X|W=1}(x|1)\propto xe^{-2x}$ ，即形状为 2、速率为 2 的 Gamma 分布。

二者不同：

$$
X\mid(Y-X=0)\sim\operatorname{Exp}(2),\qquad
X\mid(Y/X=1)\sim\Gamma(2,2).
$$

这并不矛盾。事件 $\{Y-X=0\}$ 与 $\{Y/X=1\}$ 作为集合相同，但条件分布不是只由一个抽象的零概率集合决定；它依赖把该集合嵌入哪一族邻近事件。下一章学会 Jacobian 后，这个计算会更加自然。

Python 的关键代码是：

```python
f_xv = sp.exp(-2 * xp - 0)
cond_v = sp.simplify(f_xv / sp.integrate(f_xv, (xp, 0, sp.oo)))
assert sp.simplify(cond_v - 2 * sp.exp(-2 * xp)) == 0

f_xw = xp * sp.exp(-xp * (1 + wv))
f_at1 = f_xw.subs(wv, 1)
cond_w = sp.simplify(f_at1 / sp.integrate(f_at1, (xp, 0, sp.oo)))
assert sp.simplify(cond_w - 4 * xp * sp.exp(-2 * xp)) == 0
```

这个例子也提醒我们：条件密度公式虽然形式简单，但“条件在曲线或低维集合上”的含义必须说清楚。

## 17.7 多项分布：边际与条件分布

设一次试验有三个类别，概率为 $p_1,p_2,p_3$ ，和为 1。独立重复 $n$ 次，计数向量 $(N_1,N_2,N_3)$ 服从多项分布：

$$
P(N_1=k_1,N_2=k_2,N_3=k_3)
=
\frac{n!}{k_1!k_2!k_3!}
p_1^{k_1}p_2^{k_2}p_3^{k_3},
\qquad k_1+k_2+k_3=n.
$$

把第 2、3 类合并成“非第 1 类”，立即得到

$$
N_1\sim\operatorname{Bin}(n,p_1).
$$

给定 $N_2=k_2$ ，剩余 $n-k_2$ 次试验只可能落入第 1、3 类。在原来“不是第 2 类”的条件下，第 1 类的条件概率是

$$
\frac{p_1}{p_1+p_3}=\frac{p_1}{1-p_2}.
$$

因此

$$
N_1\mid N_2=k_2
\sim
\operatorname{Bin}\left(n-k_2,\frac{p_1}{1-p_2}\right).
$$

虽然边际计数可以写成二项分布，但 $N_1,N_2$ 并不独立：约束 $N_1+N_2\le n$ 使 $(4,4)$ 在 $n=4$ 时不可能，即使两个边际积为正。

程序取 $n=4$ 、$(p_1,p_2,p_3)=(1/2,1/3,1/6)$ ，枚举全部非负整数三元组：

```python
cells = [(k1, k2, n - k1 - k2)
         for k1 in range(n + 1) for k2 in range(n + 1 - k1)]
assert sum(multinom(k) for k in cells) == 1
for k1 in range(n + 1):
    marg = sum(multinom(k) for k in cells if k[0] == k1)
    assert marg == comb(n, k1) * probs[0]**k1 * (1 - probs[0])**(n - k1)
```

条件二项分布由下式检查：

```python
for k2 in range(n + 1):
    pk2 = sum(multinom(k) for k in cells if k[1] == k2)
    q = probs[0] / (1 - probs[1])
    for k1 in range(n - k2 + 1):
        cond = multinom((k1, k2, n - k1 - k2)) / pk2
        assert cond == comb(n - k2, k1) * q**k1 * (1 - q)**(n - k2 - k1)
```

Prolog 也枚举多项格点并核对 $N_1$ 的二项边际：

```prolog
cell(K1, K2, K3) :-
    between(0, 4, K1), between(0, 4, K2),
    K3 is 4 - K1 - K2, K3 >= 0.
```

Julia 的固定种子重复抽样则检查条件均值公式

$$
E[N_1\mid N_2=k_2]=(n-k_2)\frac{p_1}{1-p_2}.
$$

有限枚举和多项公式是精确账；Julia 抽样是对采样器的审计。

## 17.8 联合 CDF 与矩形概率

对任意随机向量，可以先定义联合分布函数

$$
F_{X,Y}(x,y)=P(X\le x,Y\le y).
$$

离散和连续随机变量都能使用这个函数。矩形 $(a,b]\times(c,d]$ 的概率为

$$
F(b,d)-F(a,d)-F(b,c)+F(a,c).
$$

这个公式来自平面区域的包含—排除：先加上右上角，减去两个被多算的条带，再把减了两次的左下角加回来。它也是第 18 章多元变量变换和第 22 章从联合分布积分求抽样分布的基础。

Python 用有限表实现联合 CDF：

```python
def cdf(a, b):
    return sum(p for (x, y), p in table.items() if x <= a and y <= b)
rect = cdf(1, 2) - cdf(0, 2) - cdf(1, 0) + cdf(0, 0)
assert rect == sum(table[1, y] for y in (1, 2))
```

连续独立指数情形则使用
$F(x,y)=(1-e^{-\lambda x})(1-e^{-\mu y})$ ，并把矩形闭式与二重积分逐项比较。

## 17.9 证据等级小结

本章有意混用四种验证方式，它们的强度不同：

1. **符号积分和有理数断言**：Python 的 SymPy 与 `Fraction`、Lean 中的有限维算术用于核对指定公式；在给定符号规则和有限范围内，它们是精确的。
2. **有限全枚举**：Prolog 枚举联合表或多项格点，给出该有限模型中的完整证明。
3. **固定种子模拟**：Julia 从圆盘、三角分布、指数和多项分布中抽样，只能说明采样器与公式在容差内一致，不是定理证明。
4. **极限族论证**：零概率事件条件化的反例不是数值误差，而是条件概率定义层面的数学事实。

读输出时应看到程序的哨兵 `==== 17 ...` 与 `END ====`，但更重要的是分清每个断言在证明什么。

## 17.10 本章要点

1. 联合分布包含变量之间的相依信息；仅看边际分布不能重构联合分布。
2. 边际化对离散变量求和、对连续变量积分；条件分布是联合分布除以边际分布。
3. 条件分布在每一行或每个切片上归一；连续情形应理解为正则条件分布或极限族。
4. 独立等价于联合分布因子分解，此时条件分布等于边际分布，矩形概率可分离。
5. 单位圆盘展示了“边际对称但不独立”；三角支撑展示了条件无记忆性和 $X|Y=y$ 的均匀分布。
6. 多项分布的边际和条件分布都是二项分布，但计数分量因总和固定而不独立。
7. 对零概率事件条件化时，必须说明条件分布所依赖的随机变量或极限族。

*对应示例：`examples/lean/Probability/Ch17JointDistributions.lean`、`examples/julia/17_joint_distributions.jl`、`examples/python/17_joint_distributions.py`、`examples/prolog/17_joint_distributions.pl`。*

---

上一章：[16 卷积与微分恒等式](16-convolutions.md) · 下一章：[18 多元变换与 Jacobian](18-multivariate-transformations.md)
