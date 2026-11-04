# 第 20 章 条件期望与条件方差

## 20.1 条件期望首先是一个随机变量

第 17 章把条件分布定义为“知道 $X=x$ 后，$Y$ 的概率分布如何更新”。条件期望则是这个更新后的分布的均值。关键在于：条件的值 $x$ 可以变化，所以条件期望不是一个固定数，而是条件的函数。

离散情形下，若 $P(X=x)>0$ ，

$$
\boxed{
g(x)=E[Y\mid X=x]
=\sum_y y\,P(Y=y\mid X=x)
=\frac{\sum_y yP(X=x,Y=y)}{P(X=x)}.
}
$$

把观测到的随机量 $X$ 代回，得到随机变量

$$
\boxed{E[Y\mid X]=g(X).}
$$

这就是条件期望最重要的类型：给定一个随机变量的条件期望。更一般的研究生写法是 $E[Y\mid\mathcal G]$ ，其中 $\mathcal G$ 是已知信息组成的 $\sigma$ -代数；本章先从 $X$ 和有限路径建立直观，最后再过渡到信息族。

## 20.2 一张有限联合表

考虑 $X\in\{0,1,2\}$ 、$Y\in\{0,1,3\}$ 的联合分布，所有概率分母为 24：

| $X\backslash Y$ | 0 | 1 | 3 | 行和 |
|---:|---:|---:|---:|---:|
| 0 | $2/24$ | $3/24$ | $1/24$ | $6/24$ |
| 1 | $1/24$ | $4/24$ | $3/24$ | $8/24$ |
| 2 | $4/24$ | $2/24$ | $4/24$ | $10/24$ |

逐行计算：

$$
E[Y\mid X=0]
=\frac{0\cdot2+1\cdot3+3\cdot1}{6}=1,
$$

$$
E[Y\mid X=1]
=\frac{0\cdot1+1\cdot4+3\cdot3}{8}=\frac{13}{8},
$$

$$
E[Y\mid X=2]
=\frac{0\cdot4+1\cdot2+3\cdot4}{10}=\frac75.
$$

因此

$$
E[Y\mid X]=g(X),\qquad
g(0)=1,\quad g(1)=\frac{13}{8},\quad g(2)=\frac75.
$$

Python 用 `Fraction` 精确做这套计算：

```python
P = {
    (0, 0): F(2, 24), (0, 1): F(3, 24), (0, 3): F(1, 24),
    (1, 0): F(1, 24), (1, 1): F(4, 24), (1, 3): F(3, 24),
    (2, 0): F(4, 24), (2, 1): F(2, 24), (2, 3): F(4, 24),
}
...
def cond_exp(h):
    return {x: sum(h(x, y) * P[(x, y)] for y in ys) / pX[x]
            for x in xs}

m = cond_exp(lambda x, y: y)
assert m == {0: F(1), 1: F(13, 8), 2: F(7, 5)}
```

Prolog 的谓词 `cexp/3` 做同样的事。它先求行和 $P(X=x)$ ，再把该行的 $yP(x,y)$ 相加：

```prolog
cexp(H, X, M) :-
    px(X, PX),
    aggregate_all(sum(V),
                  ( p(X, Y, P), call(H, X, Y, F),
                    V is F * P ), S),
    M is S / PX.
```

Lean 不构造一般概率空间，而是把每个关键分数交给 `norm_num` 检查：

```lean
example : ((0 : ℚ) * 1 + 1 * 4 + 3 * 3) / 8 = 13 / 8 := by
  norm_num
```

三种工具分工很明确：Python/Prolog 展示完整算法，Lean 对关键数值和代数恒等式做机器证明。

## 20.3 全期望公式：塔性质

因为 $E[Y\mid X]$ 是 $X$ 的函数，对 $X$ 再取平均会得到无条件期望：

$$
\boxed{
E[Y]=E\!\left[E[Y\mid X]\right].
}
$$

离散情形中这只是交换求和次序：

$$
\sum_xP(X=x)\sum_y y\frac{P(X=x,Y=y)}{P(X=x)}
=\sum_{x,y}yP(X=x,Y=y)=E[Y].
$$

上表的边际概率为 $(6,8,10)/24$ ，所以

$$
E\!\left[E[Y\mid X]\right]
=\frac6{24}\cdot1+\frac8{24}\cdot\frac{13}{8}
+\frac{10}{24}\cdot\frac75
=\frac{11}{8}.
$$

直接按联合表计算 $E[Y]$ 也等于 $11/8$ 。

在更一般的理论中，若 $\mathcal H\subseteq\mathcal G$ ，则

$$
E[E[Y\mid\mathcal G]\mid\mathcal H]=E[Y\mid\mathcal H].
$$

这条性质称为塔性质（tower property）。把外层信息取到最小的平凡信息族，就得到全期望公式。

程序精确断言：

```python
EY = E(lambda x, y: y)
assert sum(pX[x] * m[x] for x in xs) == EY == F(11, 8)
```

塔性质是条件期望的核心。它说明：先在较细信息下形成一个预测，再站在较粗信息上平均这个预测，结果等于直接在较粗信息下预测。

## 20.4 条件方差与全方差公式

给定 $X=x$ ，条件方差定义为

$$
\operatorname{Var}(Y\mid X=x)
=E\!\left[(Y-E[Y\mid X=x])^2\mid X=x\right].
$$

它也是 $x$ 的函数。随机变量 $\operatorname{Var}(Y\mid X)$ 衡量“在每个已知条件内部，还剩多少波动”。

上表三个条件方差为

$$
1,\qquad \frac{79}{64},\qquad \frac{46}{25}.
$$

例如第一行中 $Y$ 的条件分布为 $(2,3,1)/6$ ，均值为 1，故方差为 1。

全方差公式是

$$
\boxed{
\operatorname{Var}(Y)
=E\!\left[\operatorname{Var}(Y\mid X)\right]
+\operatorname{Var}\!\left(E[Y\mid X]\right).
}
$$

第一项是组内平均方差，表示条件分布内部的不可解释波动；第二项是条件均值自身的波动，表示知道 $X$ 后能通过均值变化解释的部分。

对上表：

$$
E[\operatorname{Var}(Y\mid X)]=\frac{457}{320},
$$

$$
\operatorname{Var}(E[Y\mid X])=\frac9{160},
$$

二者相加：

$$
\frac{457}{320}+\frac9{160}=\frac{475}{320}=\frac{95}{64}.
$$

而直接计算 $\operatorname{Var}(Y)=E[Y^2]-(E[Y])^2$ 也得到 $95/64$ 。

Lean 的证明是有理数恒等式：

```lean
example : (457 / 320 : ℚ) + 9 / 160 = 95 / 64 := by
  norm_num
```

公式的一般代数内核是混合分布恒等式。若两个组权重为 $w,1-w$ ，组均值为 $m_1,m_2$ ，组方差为 $v_1,v_2$ ，则总方差可拆成组内和组间：

```lean
example (w m₁ m₂ v₁ v₂ : ℚ) :
    (w * (v₁ + m₁ ^ 2) + (1 - w) * (v₂ + m₂ ^ 2))
      - (w * m₁ + (1 - w) * m₂) ^ 2
    = (w * v₁ + (1 - w) * v₂)
      + (w * m₁ ^ 2 + (1 - w) * m₂ ^ 2
         - (w * m₁ + (1 - w) * m₂) ^ 2) := by
  ring
```

## 20.5 为什么全方差公式成立

令

$$
m(X)=E[Y\mid X],\qquad \varepsilon=Y-m(X).
$$

则

$$
Y-m= \varepsilon,
$$

无条件中心化也可写成

$$
Y-E[Y]=\varepsilon+(m(X)-E[Y]).
$$

平方后取期望：

$$
\operatorname{Var}(Y)
=E[\varepsilon^2]
+E[(m(X)-E[Y])^2]
+2E[\varepsilon(m(X)-E[Y])].
$$

条件期望的残差性质保证交叉项为 0。逐条件看，

$$
E[\varepsilon\mid X]=E[Y-m(X)\mid X]=0.
$$

由于 $m(X)-E[Y]$ 在给定 $X$ 后是常数，可以把它拿出条件期望：

$$
E[\varepsilon(m(X)-E[Y])\mid X]
=(m(X)-E[Y])E[\varepsilon\mid X]=0.
$$

再取期望，交叉项为 0。于是：

- $E[\varepsilon^2]=E[\operatorname{Var}(Y\mid X)]$ ；
- $E[(m(X)-E[Y])^2]=\operatorname{Var}(E[Y\mid X])$ 。

这就证明了全方差公式。

### 20.5.1 拿出已知量

若 $h(X)$ 的二阶矩足够，条件期望满足

$$
\boxed{
E[h(X)Y\mid X]=h(X)E[Y\mid X].
}
$$

因为在给定 $X=x$ 的条件分布中，$h(x)$ 是常数。Python 对联合表检查：

```python
mxy = cond_exp(lambda x, y: x * y)
assert all(mxy[x] == x * m[x] for x in xs)
assert E(lambda x, y: x * y) == sum(pX[x] * x * m[x] for x in xs)
```

Prolog 进一步检查残差不仅与 $X$ 正交，还与 $X$ 的若干函数正交：

```prolog
forall(member(Hc, [1, x, x2, cube]),
       ( aggregate_all(sum(V),
           ( p(X, Y, P), cm(X, M), hfun(Hc, X, HX),
             V is (Y - M) * HX * P ), Z),
         Z =:= 0 ))
```

这里的 `cube` 表示任意测试函数 $(X-1)^3+7$ ，不是只测试线性项。

## 20.6 条件期望是 $L^2$ 最优预测

假设我们要用 $X$ 的某个函数 $g(X)$ 预测 $Y$ ，并用均方误差

$$
\operatorname{MSE}(g)=E[(Y-g(X))^2]
$$

衡量预测质量。那么在所有可测且平方可积的预测函数中，最优者正是

$$
g^*(X)=E[Y\mid X].
$$

证明使用勾股分解。令 $m(X)=E[Y\mid X]$ ，则

$$
Y-g(X)=(Y-m(X))+(m(X)-g(X)).
$$

平方展开并取期望，交叉项为 0，所以

$$
\boxed{
E[(Y-g(X))^2]
=E[(Y-m(X))^2]+E[(m(X)-g(X))^2].
}
$$

第二项非负，并且当 $g=m$ 时为 0。Lean 验证逐点代数展开：

```lean
example (y m g : ℚ) :
    (y - g) ^ 2
    = (y - m) ^ 2
      + 2 * (y - m) * (m - g)
      + (m - g) ^ 2 := by
  ring
```

条件期望把交叉项消掉，因此得到投影几何中的勾股定理。$L^2$ 空间以内积

$$
\langle U,V\rangle=E[UV]
$$

成为内积空间；所有 $X$ 的函数组成一个子空间，条件期望就是 $Y$ 到这个子空间的正交投影。

### 20.6.1 正规方程

有限表中，子空间的一组基可以取为示性函数

$$
\mathbf 1_{\{X=a\}},\qquad a\in\{0,1,2\}.
$$

最优预测满足残差与每个基函数正交：

$$
E[(Y-g(X))\mathbf 1_{\{X=a\}}]=0.
$$

左边除以 $P(X=a)$ ，得到

$$
g(a)=E[Y\mid X=a].
$$

Python 用正规方程重新求出预测函数：

```python
g = {}
for a in xs:
    g[a] = Ew(lambda x, y: y * (1 if x == a else 0)) / pX[a]
assert g == m
```

这说明“条件均值”不是人为规定的预测规则，而是最小二乘问题的唯一最优解。

## 20.7 条件期望比线性回归更强

第 19 章的最优线性预测只允许

$$
a+bX
$$

形式；条件期望允许任意函数 $m(X)$ 。因此条件期望的均方误差不大于最优线性预测。

令 $X$ 在 $\{-1,0,1\}$ 上等概率，$Y=X^2$ 。分布关于 0 对称，所以

$$
\operatorname{Cov}(X,Y)=E[X^3]=0.
$$

最优线性预测是常数 $E[Y]=2/3$ ，均方误差为 $\operatorname{Var}(Y)=2/9$ 。但条件期望为

$$
E[Y\mid X]=X^2,
$$

它完全预测 $Y$ ，均方误差为 0。

```python
mse_lin = sum((x * x - EYv) ** 2 * p for x, p in Xv.items())
mse_cond = sum((x * x - x * x) ** 2 * p for x, p in Xv.items())
assert mse_lin == F(2, 9) and mse_cond == 0
```

Julia 的固定种子模拟给出同样的数值审计：

```julia
Xq = rand(-1:1, N)
Yq = Xq .^ 2
β = cov(Xq, Yq) / var(Xq)
@assert abs(β) < 0.01
@assert abs(mean((Yq .- mean(Yq)) .^ 2) - 2 / 9) < 0.01
@assert mean((Yq .- Xq .^ 2) .^ 2) == 0
```

样本斜率接近 0 只是数值审计；真正的结论来自精确分布和 $L^2$ 投影定理。

还要注意：误差与预测变量零相关，并不足以保证它在条件意义下均值为零。程序构造

$$
\varepsilon=(X^2-1)+U,
$$

其中 $U\in\{-1,1\}$ 等概率且与 $X$ 独立。可以有

$$
E[X\varepsilon]=0,
$$

但在 $X=0$ 时，

$$
E[\varepsilon\mid X=0]=-1.
$$

因此线性回归的一阶正交条件比条件期望要求的“对 $X$ 的所有函数正交”弱得多。

## 20.8 独立、均值独立与条件期望

若 $X,Y$ 独立，则给定 $X$ 不会改变 $Y$ 的分布：

$$
P(Y\in A\mid X=x)=P(Y\in A),
$$

因而

$$
\boxed{E[Y\mid X]=E[Y].}
$$

程序用因子分解 $P(X=x,Y=y)=q_X(x)q_Y(y)$ 检查每个条件均值都等于同一个 $E[Y]=4/3$ 。

但反向不成立：$E[Y\mid X]$ 是常数只称为**均值独立**，它不保证整个条件分布相同，也不保证独立。

取如下联合分布：

$$
P(X=0,Y=0)=\frac13,
$$

并且当 $X\in\{-1,1\}$ 时，$Y\in\{-1,1\}$ 的四个格点各有概率 $1/6$ 。给定任意 $X=x$ ，$Y$ 的条件均值都是 0，所以

$$
E[Y\mid X]=0.
$$

然而

$$
P(X=0,Y=0)=\frac13,
$$

而

$$
P(X=0)P(Y=0)=\frac13\cdot\frac13=\frac19.
$$

因此不独立。Prolog 精确比较这两个数：

```prolog
P00 = 1 rdiv 3,
P00 =\= PX0 * PY0
```

逻辑层级应记清楚：

$$
\text{独立}\Longrightarrow\text{均值独立}
\Longrightarrow\text{零相关},
$$

但反向一般都不成立。只有在联合正态等特殊结构下，零相关才会强到等价于独立。

## 20.9 连续例子：三角支撑上的联合密度

令 $(X,Y)$ 的密度为

$$
f_{X,Y}(x,y)=e^{-y},\qquad 0<x<y<\infty.
$$

先求 $X$ 的边际密度：

$$
f_X(x)=\int_x^\infty e^{-y}\,dy=e^{-x},\qquad x>0.
$$

所以 $X\sim\operatorname{Exp}(1)$ 。条件密度为

$$
f_{Y\mid X}(y\mid x)
=\frac{e^{-y}}{e^{-x}}
=e^{-(y-x)},\qquad y>x.
$$

令 $E=Y-x$ ，则给定 $X=x$ 时 $E\sim\operatorname{Exp}(1)$ 。因此

$$
\boxed{
E[Y\mid X=x]=x+1,\qquad
\operatorname{Var}(Y\mid X=x)=1.
}
$$

SymPy 直接积分：

```python
fXY = sp.exp(-y)
fX = sp.integrate(fXY, (y, x, sp.oo))
fY_given = fXY / fX
EYgx = sp.simplify(sp.integrate(y * fY_given, (y, x, sp.oo)))
EY2gx = sp.simplify(sp.integrate(y ** 2 * fY_given,
                                 (y, x, sp.oo)))
assert sp.simplify(EYgx - (1 + x)) == 0
assert sp.simplify(EY2gx - EYgx ** 2 - 1) == 0
```

由全期望公式，

$$
E[Y]=E[1+X]=1+1=2.
$$

由全方差公式，

$$
\operatorname{Var}(Y)
=E[1]+\operatorname{Var}(1+X)=1+1=2.
$$

事实上 $Y\sim\operatorname{Gamma}(2,1)$ 。这个例子展示了连续条件期望的生成机制：先抽 $X$ ，再令

$$
Y=X+E,
$$

其中未来增量 $E$ 与 $X$ 独立。

Julia 用固定种子 20 模拟这一机制，并按 $X$ 的区间分组审计：

```julia
Xc = -log.(rand(N))
Yc = Xc .+ (-log.(rand(N)))
for (lo, hi) in ((0.0, 0.5), (0.5, 1.5), (1.5, 3.0))
    sel = (Xc .>= lo) .& (Xc .< hi)
    xm = mean(Xc[sel])
    @assert abs(mean(Yc[sel]) - (1 + xm)) < 0.03
    @assert abs(var(Yc[sel] .- Xc[sel]) - 1) < 0.05
end
```

连续情形涉及零概率事件 $X=x$ ，条件密度不是用 $P(X=x)$ 定义的。严格理论使用正则条件分布；在密度存在时，公式 $f_{Y\mid X}=f_{X,Y}/f_X$ 给出其密度。第 17 章的零测集反例说明，不能脱离给定的极限条件过程随意指定单点上的条件分布。

## 20.10 Poisson–二项层次模型与随机个数和

设

$$
N\sim\operatorname{Poisson}(\lambda),
$$

给定 $N=n$ ，令

$$
Y\mid N=n\sim\operatorname{Binomial}(n,p).
$$

这可解释为：先有 $N$ 个潜在事件，每个事件独立以概率 $p$ 被保留。

条件期望和条件方差为

$$
E[Y\mid N]=pN,\qquad
\operatorname{Var}(Y\mid N)=Np(1-p).
$$

因为 $E[N]=\operatorname{Var}(N)=\lambda$ ，全期望公式给出

$$
E[Y]=E[pN]=p\lambda.
$$

全方差公式给出

$$
\begin{aligned}
\operatorname{Var}(Y)
&=E[Np(1-p)]+\operatorname{Var}(pN)\\
&=\lambda p(1-p)+p^2\lambda\\
&=\lambda p.
\end{aligned}
$$

均值和方差都为 $\lambda p$ ，而 Poisson 稀疏化定理表明 $Y\sim\operatorname{Poisson}(\lambda p)$ 。Lean 只验证全方差中的关键代数：

```lean
example (lam p : ℚ) :
    lam * p * (1 - p) + p ^ 2 * lam = lam * p := by
  ring
```

更一般地，若随机和

$$
S=\sum_{i=1}^N Z_i
$$

中 $N$ 与 $Z_i$ 独立，$E[Z_i]=m$ 、$\operatorname{Var}(Z_i)=v$ ，且 $E[N]=\mu_N$ 、$\operatorname{Var}(N)=\sigma_N^2$ ，则

$$
\boxed{
E[S]=m\mu_N,\qquad
\operatorname{Var}(S)=\mu_Nv+\sigma_N^2m^2.
}
$$

第一项是随机个数内部波动，第二项是个数本身不确定带来的波动。

## 20.11 条件异方差

条件期望为常数并不意味着条件方差也为常数。设 $X,Z$ 独立，$E[Z]=0$ 、$\operatorname{Var}(Z)=1$ ，并令

$$
Y=Z\sqrt{1+X^2}.
$$

给定 $X=x$ ，尺度因子 $\sqrt{1+x^2}$ 是常数，因此

$$
E[Y\mid X=x]=0,
$$

而

$$
\operatorname{Var}(Y\mid X=x)=1+x^2.
$$

Python 用 $Z\in\{-1,1\}$ 等概率精确验证：

```python
E_Y = sum(z * s * pz for z, pz in Zs.items())
E_Y2 = sum((z * s) ** 2 * pz for z, pz in Zs.items())
assert sp.simplify(E_Y) == 0
assert sp.simplify(E_Y2 - s ** 2) == 0
```

若 $X$ 在 $\{-1,0,1,2\}$ 上等概率，则

$$
\operatorname{Var}(Y)
=E[1+X^2]
=1+\frac{1+0+1+4}{4}
=\frac52,
$$

而 $\operatorname{Var}(E[Y\mid X])=0$ 。所有波动都来自条件方差。

这种均值恒定但方差随观测变量变化的现象称为条件异方差，是金融收益率建模中的核心现象：预测价格变化的条件均值可能接近零，但风险水平会随市场状态显著变化。

## 20.12 信息更新与鞅

令 $X_1,\dots,X_n$ 为独立公平 Bernoulli(1/2) 变量，

$$
S_k=X_1+\cdots+X_k.
$$

若已经观测前 $k$ 次，则总和 $S_n$ 的条件期望为

$$
\boxed{
E[S_n\mid X_1,\dots,X_k]
=S_k+\frac{n-k}{2}.
}
$$

因为前 $k$ 次已经确定，未来 $n-k$ 次每次平均贡献 $1/2$ 。条件方差为

$$
\boxed{
\operatorname{Var}(S_n\mid X_1,\dots,X_k)=\frac{n-k}{4}.
}
$$

Python 枚举 $n=4$ 的全部 $2^4=16$ 条路径，对每个前缀精确验证：

```python
paths = list(product((0, 1), repeat=n))

def M(k, path):
    return S(path, k) + F(n - k, 2)

for k in range(n + 1):
    for prefix in product((0, 1), repeat=k):
        assert cond_given_prefix(lambda p: S(p), k, prefix) \
            == S(prefix) + F(n - k, 2)
```

定义

$$
M_k=E[S_n\mid\mathcal F_k]
=S_k+\frac{n-k}{2},
$$

其中 $\mathcal F_k$ 表示前 $k$ 次结果提供的信息。塔性质给出

$$
E[M_{k+1}\mid\mathcal F_k]=M_k.
$$

这就是鞅性：当前信息对未来条件期望的最佳预测就是当前值。程序逐前缀检查这条性质。

Lean 验证一步更新的算术。设当前和为 $s$ ，剩余次数为 $r$ ，则下一枚硬币取 0 或 1 各一半：

```lean
example (s r : ℚ) :
    (1 / 2 : ℚ) * ((s + 0) + (r - 1) / 2)
      + (1 / 2) * ((s + 1) + (r - 1) / 2)
    = s + r / 2 := by
  ring
```

随着信息增加，剩余未知硬币数减少，条件方差从 $n/4$ 逐步降到 0。这里应小心：并不是任意“知道更多”都保证每个具体条件方差数值单调下降；全方差公式保证的是平均组内方差不超过总方差。在硬币模型中，由于每个长度为 $k$ 的前缀对应完全相同的未来分布，剩余方差才整齐地等于 $(n-k)/4$ 。

另一个有用的更新方向是给定总和。对公平可交换硬币，

$$
E[X_1\mid S_n=s]=\frac{s}{n}.
$$

知道总和为 $s$ 后，成功在各次试验间对称分布，每次平均承担 $s/n$ 。当 $n=4,s=2$ 时，共有 $\binom42=6$ 条路径，第一位为 1 的有 3 条，所以条件均值为 $1/2$ 。

## 20.13 总协方差公式

条件化也给出协方差分解。对任意 $U,V$ ，

$$
\boxed{
\operatorname{Cov}(U,V)
=E[\operatorname{Cov}(U,V\mid X)]
+\operatorname{Cov}(E[U\mid X],E[V\mid X]).
}
$$

它是全方差公式的双变量版本。第二项衡量条件均值共同运动产生的协方差，第一项衡量各条件内部的平均协方差。

在有限表中取 $U=Y$ 、$V=Y^2$ ，Python 分别计算：

```python
cond_cov = {a: cuv[a] - cu[a] * cv2[a] for a in xs}
Ecc = sum(pX[a] * cond_cov[a] for a in xs)
cov_of_cond = sum(pX[a] * cu[a] * cv2[a] for a in xs) - EU * EV
cov_uv = Ew(lambda x, y: y * y * y) - EU * EV
assert cov_uv == Ecc + cov_of_cond
```

这个公式在时间序列和计量经济学中经常使用：控制 $X$ 后，变量间的关系可分为组内关系和组均值之间的关系，两者不必同向。

## 20.14 条件期望的存在性与解释

离散情形的条件期望很直接；密度情形可用条件密度定义。但一般概率空间中，单点概率可能为零，也可能没有普通密度。现代概率论通过 Radon–Nikodym 定理定义 $E[Y\mid\mathcal G]$ ，要求它满足：

1. $E[Y\mid\mathcal G]$ 是 $\mathcal G$ -可测的；
2. 对每个 $A\in\mathcal G$ ，
   $\int_A E[Y\mid\mathcal G]\,dP=\int_A Y\,dP.$

第二条对所有信息事件 $A$ 写成积分形式的正交条件。它只在几乎处处意义下唯一：在概率为零的事件上改变条件期望不影响定义。

这也是为什么连续条件分布需要正则条件分布，并且为什么在零测集上随意指定条件密度可能制造矛盾。本章的连续例子都有明确的极限过程或密度版本，因此不存在这种歧义。

## 20.15 模拟在本章中的位置

Julia 程序使用固定种子 `Random.seed!(20)` 做三类审计：

1. 从有限表的边际分布和条件分布分层抽样，检查组均值接近精确条件均值；
2. 从 $Y=X+E$ 的连续模型抽样，检查 $E[Y\mid X]\approx1+X$ ；
3. 从 Poisson–二项层次模型抽样，检查样本均值和方差接近 $\lambda p$ 。

例如分层模拟中：

```julia
for x in xs
    sel = Ysim[Xs .== x]
    @assert abs(mean(sel) - Float64(m[x])) < 0.02
    @assert abs(var(sel; corrected=false) - Float64(v[x])) < 0.04
end
```

这些结果不是证明。它们验证抽样代码与精确公式一致，并展示有限样本误差的规模。证明来自：

- 有限表的精确分数枚举；
- SymPy 的符号积分和代数化简；
- Lean 对关键恒等式的机器证明；
- 条件期望的定义和塔性质。

## 20.16 本章要点

1. $E[Y\mid X=x]$ 是条件分布的均值；$E[Y\mid X]$ 是 $X$ 的随机函数。
2. 塔性质为 $E[E[Y\mid X]]=E[Y]$ 。
3. 已知 $X$ 的函数可以拿出条件期望。
4. 全方差公式把总方差分为组内方差和组间方差。
5. 条件期望是所有 $X$ 的函数中使均方误差最小的 $L^2$ 投影。
6. 条件期望允许非线性关系，因而通常强于最优线性预测。
7. 独立推出条件期望常数，但条件期望常数只表示均值独立，不表示独立。
8. 条件均值恒定不代表条件方差恒定；条件异方差是独立的现象。
9. 硬币序列展示了信息更新、鞅性和剩余不确定性的逐步下降。

*对应示例：`examples/lean/Probability/Ch20ConditionalExpectation.lean`、`examples/julia/20_conditional_expectation.jl`、`examples/python/20_conditional_expectation.py`、`examples/prolog/20_conditional_expectation.pl`。*

---

上一章：[19 协方差、相关与独立](19-covariance.md) · 下一章：[21 二元与多元正态](21-multivariate-normal.md)
