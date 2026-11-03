# 第 22 章 随机样本与抽样分布

## 22.1 从总体到样本

统计推断的出发点不是一个随机变量，而是一组重复观测。设总体分布依赖于参数 $\theta$，随机样本为

$$
X_1,X_2,\dots,X_n.
$$

最常见的独立同分布样本满足：

1. 各 $X_i$ 相互独立；
2. 各 $X_i$ 有相同总体分布；
3. 该共同分布属于参数族 $\{P_\theta:\theta\in\Theta\}$。

简称 iid 样本。

**统计量**是样本的可测函数

$$
T=T(X_1,\dots,X_n),
$$

其中不能含有未知参数。例如样本均值和无偏样本方差是统计量：

$$
\bar X=\frac1n\sum_{i=1}^nX_i,
\qquad
S^2=\frac1{n-1}\sum_{i=1}^n(X_i-\bar X)^2.
$$

注意 $S^2$ 是统计量；而 $(\bar X-\mu)/\sigma$ 在 $\mu,\sigma$ 未知时不是统计量。

统计量本身也是随机变量，因为样本每次抽取都会改变。它的分布称为**抽样分布**。这和总体分布不同：

- 总体分布描述单个个体或一次观测；
- 抽样分布描述一个统计量在所有容量为 $n$ 的样本中的分布。

本章只在可精确推导的正态模型中建立主干，再用模拟检查公式和假设边界。固定种子模拟不替代证明；它用于审计实现是否与推导一致。

## 22.2 样本均值的分布

若

$$
X_i\stackrel{iid}{\sim}N(\mu,\sigma^2),
$$

独立正态变量的和仍为正态，所以

$$
\bar X\sim N\left(\mu,\frac{\sigma^2}{n}\right).
$$

标准化后

$$
\boxed{
Z=\frac{\bar X-\mu}{\sigma/\sqrt n}
=\frac{\sqrt n(\bar X-\mu)}{\sigma}\sim N(0,1).
}
$$

均值公式说明样本均值围绕总体均值居中；标准差公式说明均值的波动按 $1/\sqrt n$ 缩小。这是 z 检验和正态均值置信区间的基础。

正态假设在这里非常强。即使总体不是正态，独立样本均值的均值和方差仍为

$$
E[\bar X]=\mu,\qquad
\operatorname{Var}(\bar X)=\frac{\sigma^2}{n},
$$

因为这两个结论只使用期望线性性、独立性和有限方差。但 $\bar X$ 未必精确正态；大样本时才由中心极限定理得到近似正态。

## 22.3 平方和分解

先处理一个纯代数恒等式。对任意实数 $x_1,\dots,x_n$ 和 $\mu$，

$$
\boxed{
\sum_{i=1}^n(x_i-\mu)^2
=
\sum_{i=1}^n(x_i-\bar x)^2+n(\bar x-\mu)^2.
}
$$

证明只需展开：

$$
x_i-\mu=(x_i-\bar x)+(\bar x-\mu),
$$

于是

$$
\sum_i(x_i-\mu)^2
=\sum_i(x_i-\bar x)^2
+2(\bar x-\mu)\sum_i(x_i-\bar x)
+n(\bar x-\mu)^2.
$$

而样本均值的定义给出交叉项

$$
\sum_i(x_i-\bar x)=\sum_ix_i-n\bar x=0.
$$

Python 程序用精确分数核对这个恒等式：

```python
xs = [Fraction(3), Fraction(-1), Fraction(7, 2), Fraction(5, 3)]
mu = Fraction(2, 5)
xbar = sum(xs) / n
ss = sum((x - xbar) ** 2 for x in xs)
assert sum((x - mu) ** 2 for x in xs) == ss + n * (xbar - mu) ** 2
```

Lean 对 $n=3$ 给出机器证明：

```lean
example (x₁ x₂ x₃ μ : ℚ) :
    (x₁ - μ) ^ 2 + (x₂ - μ) ^ 2 + (x₃ - μ) ^ 2 =
      ((x₁ - (x₁ + x₂ + x₃) / 3) ^ 2 +
       (x₂ - (x₁ + x₂ + x₃) / 3) ^ 2 +
       (x₃ - (x₁ + x₂ + x₃) / 3) ^ 2) +
      3 * ((x₁ + x₂ + x₃) / 3 - μ) ^ 2 := by
  ring
```

左边是 $n$ 个独立标准正态平方，右边把“样本均值偏离 $\mu$”和“观测值围绕样本均值波动”分开。

## 22.4 Helmert 正交变换

平方和分解的几何意义是正交投影。以 $n=4$ 为例，取未归一 Helmert 行：

$$
\begin{pmatrix}
1&1&1&1\\
1&-1&0&0\\
1&1&-2&0\\
1&1&1&-3
\end{pmatrix}.
$$

各行两两正交，行长度平方分别为

$$
4,\quad 2,\quad 6,\quad 12.
$$

归一化后得到正交矩阵 $H$，满足

$$
HH^T=I,\qquad |\det H|=1.
$$

第一行是 $(1/\sqrt n,\dots,1/\sqrt n)$，所以

$$
Y_1=\sqrt n\,\bar X.
$$

其余 $n-1$ 个坐标恰好表示离差向量，且

$$
\sum_{i=1}^n(X_i-\bar X)^2=\sum_{j=2}^nY_j^2.
$$

Python 在 $n=4$ 时构造归一化矩阵：

```python
rows = [
    [1, 1, 1, 1],
    [1, -1, 0, 0],
    [1, 1, -2, 0],
    [1, 1, 1, -3],
]
Hu = sp.Matrix(rows)
Hn = sp.Matrix([[sp.Rational(r) / sp.sqrt(sum(c * c for c in row))
                 for r in row] for row in rows])
assert sp.simplify(Hn * Hn.T - sp.eye(n)) == sp.zeros(n, n)
assert sp.simplify(abs(Hn.det())) == 1
assert all(sp.simplify(Hn[0, j] - 1 / sp.sqrt(n)) == 0
           for j in range(n))
```

Julia 用一般 $n=6$ 的 Helmert 构造验证正交性：

```julia
H[1, :] .= 1 / sqrt(n)
for k in 2:n
    H[k, 1:k-1] .= 1 / sqrt(k * (k - 1))
    H[k, k] = -(k - 1) / sqrt(k * (k - 1))
end
@assert norm(H * H' - I) < 1e-12
@assert abs(abs(det(H)) - 1) < 1e-12
```

Lean 只验证有限有理矩阵的代数核心：

```lean
example : helmert4 * helmert4.transpose =
    Matrix.diagonal ![4, 2, 6, 12] := by
  ext i j
  fin_cases i <;> fin_cases j <;>
    simp [helmert4, Matrix.mul_apply,
          Fin.sum_univ_four, Matrix.diagonal] <;> norm_num
```

## 22.5 为什么正交变换保持标准正态向量独立同分布

若 $Z=(Z_1,\dots,Z_n)^T$ 的分量独立同分布于 $N(0,1)$，且 $H$ 为正交矩阵，令

$$
Y=HZ.
$$

则 $Y$ 仍为多元标准正态。用密度可以直接看出：

$$
f_Z(z)=(2\pi)^{-n/2}\exp\left(-\frac12z^Tz\right).
$$

因为 $H^TH=I$，正交变换保持内积：

$$
z^Tz=(H^Ty)^T(H^Ty)=y^Ty.
$$

又因为 $|\det H|=1$，Jacobian 不改变密度常数。因此

$$
f_Y(y)=(2\pi)^{-n/2}\exp\left(-\frac12y^Ty\right).
$$

所以 $Y_1,\dots,Y_n$ 仍相互独立且都为 $N(0,1)$。

这一步同时得到两个结论：

1. $\sqrt n\bar X=Y_1$ 是标准正态；
2. $\sum_{i=1}^n(X_i-\bar X)^2=\sum_{j=2}^nY_j^2$ 是 $n-1$ 个独立标准正态平方和。

因此均值方向和残差方向相互独立。

## 22.6 $\chi^2$ 分布：正态平方的族谱

若 $Z_1,\dots,Z_\nu$ 独立且都服从 $N(0,1)$，定义

$$
V=Z_1^2+\cdots+Z_\nu^2,
$$

则称 $V$ 服从自由度为 $\nu$ 的卡方分布，记作

$$
V\sim\chi^2(\nu).
$$

其密度为

$$
\boxed{
f_V(v)=
\frac{v^{\nu/2-1}e^{-v/2}}
{2^{\nu/2}\Gamma(\nu/2)},
\qquad v>0.
}
$$

也就是说，

$$
\chi^2(\nu)=\operatorname{Gamma}\left(\frac{\nu}{2},\text{scale}=2\right).
$$

一元情形 $Z^2\sim\chi^2(1)$ 来自双支反函数。对 $v>0$，

$$
P(Z^2\le v)=P(-\sqrt v\le Z\le\sqrt v),
$$

求导得到两个分支贡献之和：

$$
f_{Z^2}(v)
=\frac{1}{\sqrt{2\pi v}}e^{-v/2}
=\frac{v^{-1/2}e^{-v/2}}{2^{1/2}\Gamma(1/2)}.
$$

这里使用

$$
\Gamma(1/2)=\sqrt\pi.
$$

独立卡方变量具有可加性：

$$
V_1\sim\chi^2(\nu_1),\quad V_2\sim\chi^2(\nu_2),
\quad V_1\perp V_2
\Longrightarrow
V_1+V_2\sim\chi^2(\nu_1+\nu_2).
$$

从 Gamma 角度看，这是独立 Gamma 变量在相同尺度参数下形状参数相加；从标准正态平方角度看，这是把两组独立平方项接成一组。

Lean 记录常数和矩账：

```lean
example : (Real.sqrt 2 * Real.sqrt Real.pi) ^ 2 = 2 * Real.pi := by
  rw [mul_pow, Real.sq_sqrt (by positivity),
      Real.sq_sqrt (by positivity)]

example (ν : ℚ) : (ν ^ 2 + 2 * ν) - ν ^ 2 = 2 * ν := by ring
```

Python 逐点核对 $\chi^2$ 与 Gamma 密度、卷积可加性：

```python
for nu in (1, 2, 3, 7, 10):
    for y in (0.3, 1.0, 4.5, 12.0):
        assert abs(stats.chi2.pdf(y, nu) -
                   stats.gamma.pdf(y, a=nu / 2, scale=2)) < 1e-12

for z in (1.0, 5.0, 9.0):
    conv, _ = integrate.quad(
        lambda u: stats.chi2.pdf(u, 3) * stats.chi2.pdf(z - u, 4),
        0, z)
    assert abs(conv - stats.chi2.pdf(z, 7)) < 1e-9
```

其均值和方差为

$$
\boxed{E[V]=\nu,\qquad \operatorname{Var}(V)=2\nu.}
$$

## 22.7 正态样本方差的抽样分布

由 Helmert 变换，

$$
\frac1{\sigma^2}\sum_{i=1}^n(X_i-\bar X)^2
=\sum_{j=2}^n\left(\frac{Y_j}{\sigma}\right)^2.
$$

因为 $Y_j/\sigma\sim N(0,1)$ 且相互独立，所以

$$
\boxed{
\frac{(n-1)S^2}{\sigma^2}
=\frac1{\sigma^2}\sum_{i=1}^n(X_i-\bar X)^2
\sim\chi^2(n-1).
}
$$

自由度是 $n-1$，不是 $n$。样本均值吃掉了一个方向；残差向量落在

$$
\sum_i(x_i-\bar x)=0
$$

的 $n-1$ 维子空间中。

同时，

$$
\frac{\sqrt n(\bar X-\mu)}{\sigma}\sim N(0,1),
$$

并且它与 $S^2$ 独立。这个独立性是正态样本的特殊性质，来自正交变换后两个方向相互独立。

Python 用固定种子生成 $m=8$ 的正态样本并审计：

```python
m, mu0, sig = 8, 3.0, 2.0
X = rng.normal(mu0, sig, size=(N, m))
xb = X.mean(axis=1)
s2 = X.var(axis=1, ddof=1)
Q = (m - 1) * s2 / sig ** 2
ks = stats.kstest(Q, stats.chi2(m - 1).cdf)
assert ks.statistic < 0.004
assert abs(Q.mean() - (m - 1)) < 0.03
assert abs(Q.var() - 2 * (m - 1)) < 0.15
r_norm = np.corrcoef(xb, s2)[0, 1]
assert abs(r_norm) < 0.01
```

KS 统计量很小只说明模拟实现与 $\chi^2(7)$ 一致；真正的分布结论来自 Helmert 正交变换。

### 22.7.1 为什么除以 $n-1$

因为

$$
E\left[\frac{(n-1)S^2}{\sigma^2}\right]=n-1,
$$

所以

$$
E[S^2]=\sigma^2.
$$

除以 $n$ 的二阶矩估计量 $\widehat\sigma_n^2=n^{-1}\sum_i(X_i-\bar X)^2$ 满足

$$
E[\widehat\sigma_n^2]
=\frac{n-1}{n}\sigma^2,
$$

因而有偏。程序检查这一点：

```python
assert abs(np.mean(X.var(axis=1, ddof=0)) -
           sig ** 2 * (m - 1) / m) < 0.02
```

“$n-1$”不是神秘修正，而是残差子空间维数。

## 22.8 独立性不是所有总体的普遍性质

对非正态 iid 样本，$\bar X$ 与 $S^2$ 不一定独立，甚至可能明显相关。程序用指数总体作对照：

```python
Xe = rng.exponential(1.0, size=(N, m))
r_exp = np.corrcoef(Xe.mean(axis=1),
                    Xe.var(axis=1, ddof=1))[0, 1]
assert r_exp > 0.3
```

对指数分布，第三阶中心矩为正。一般地，

$$
\operatorname{Cov}(\bar X,S^2)=\frac{\mu_3}{n},
$$

而指数分布的偏度使该协方差为正。程序还检查

$$
\operatorname{Var}(S^2)
\approx \sigma^4\left(\frac{2}{n-1}+\frac{\kappa}{n}\right),
$$

其中 $\kappa$ 为超额峰度；指数分布的 $\kappa=6$。

离散 Bernoulli 样本更直观。当 $n=2$、$p=1/2$ 时，样本均值和样本方差相互决定：

- 样本为 $00$：$\bar X=0,S^2=0$；
- 样本为 $11$：$\bar X=1,S^2=0$；
- 样本为 $01$ 或 $10$：$\bar X=1/2,S^2=1/2$。

因此

$$
P(\bar X=1/2,S^2=1/2)=\frac12,
$$

而

$$
P(\bar X=1/2)P(S^2=1/2)=\frac12\cdot\frac12=\frac14.
$$

二者不独立。正态理论中的 $\bar X\perp S^2$ 绝不能随手推广。

## 22.9 Student $t$ 分布

设

$$
Z\sim N(0,1),\qquad V\sim\chi^2(\nu),
\qquad Z\perp V.
$$

定义

$$
\boxed{
T=\frac{Z}{\sqrt{V/\nu}}.
}
$$

则 $T$ 服从自由度为 $\nu$ 的 Student $t$ 分布。其密度为

$$
f_T(t)=
\frac{\Gamma((\nu+1)/2)}
{\sqrt{\nu\pi}\Gamma(\nu/2)}
\left(1+\frac{t^2}{\nu}\right)^{-(\nu+1)/2}.
$$

在正态样本中，当 $\sigma$ 未知时，用 $S$ 代替：

$$
\frac{\bar X-\mu}{S/\sqrt n}
=
\frac{\sqrt n(\bar X-\mu)/\sigma}
{\sqrt{(n-1)S^2/[\sigma^2(n-1)]}}.
$$

分子为 $N(0,1)$，分母根号内为独立的 $\chi^2(n-1)/(n-1)$，所以

$$
\boxed{
\frac{\bar X-\mu}{S/\sqrt n}\sim t(n-1).
}
$$

$t$ 分布比标准正态尾更厚，因为分母有随机波动。自由度增大时，$S^2$ 更集中于 $\sigma^2$，$t$ 分布趋于标准正态。

两个边界情形值得记住：

- $\nu=1$ 时，$t(1)$ 就是标准 Cauchy 分布；
- $\nu>2$ 时，$\operatorname{Var}(T)=\nu/(\nu-2)$；$\nu=1,2$ 时方差不存在或不为有限值。

程序用同一份正态样本同时构造 $Z$ 和 $T$，验证恒等关系：

```python
T = np.sqrt(m) * (xb - mu0) / np.sqrt(s2)
Z = np.sqrt(m) * (xb - mu0) / sig
assert np.allclose(T, Z / np.sqrt(Q / (m - 1)))
kst = stats.kstest(T, stats.t(m - 1).cdf)
assert kst.statistic < 0.004
assert abs(stats.t.cdf(1.7, 1) - stats.cauchy.cdf(1.7)) < 1e-12
assert abs(stats.t(7).var() - 7 / 5) < 1e-12
```

Julia 不依赖统计包，而用 Gamma 函数手写 $t$ 密度并做数值积分：

```julia
tpdf(x, ν) =
  exp(lgam((ν + 1) / 2) - lgam(ν / 2)) /
  sqrt(ν * pi) * (1 + x^2 / ν)^(-(ν + 1) / 2)
```

## 22.10 $F$ 分布及 $t^2=F$

设

$$
U\sim\chi^2(d_1),\qquad V\sim\chi^2(d_2),\qquad U\perp V.
$$

定义

$$
\boxed{
F=\frac{U/d_1}{V/d_2}.
}
$$

则 $F\sim F(d_1,d_2)$。其密度为

$$
f_F(x)=
\frac{\Gamma((d_1+d_2)/2)}
{\Gamma(d_1/2)\Gamma(d_2/2)}
\left(\frac{d_1}{d_2}\right)^{d_1/2}
x^{d_1/2-1}
\left(1+\frac{d_1}{d_2}x\right)^{-(d_1+d_2)/2},
\quad x>0.
$$

若 $T\sim t(\nu)$，则

$$
T^2=\frac{Z^2/1}{V/\nu}.
$$

因为 $Z^2\sim\chi^2(1)$，所以

$$
\boxed{T^2\sim F(1,\nu).}
$$

Lean 验证代数形式：

```lean
example (z v ν : ℝ) (hv : 0 < v) (hν : 0 < ν) :
    (z / Real.sqrt (v / ν)) ^ 2 = z ^ 2 / (v / ν) := by
  rw [div_pow, Real.sq_sqrt (by positivity)]
```

Python 检查分位数恒等式：对 $q>1/2$，

$$
F_{1,\nu}^{-1}(q)=\left(t_\nu^{-1}\left(\frac{1+q}{2}\right)\right)^2.
$$

```python
for nu in (1, 2, 5, 12, 40):
    for q in (0.5, 0.9, 0.95, 0.99):
        assert abs(stats.f.ppf(q, 1, nu) -
                   stats.t.ppf((1 + q) / 2, nu) ** 2) < 1e-8
```

$F$ 分布主要用于比较两个独立方差，也是回归和方差分析中常见检验统计量的抽样分布。

## 22.11 两个独立正态样本

设

$$
X_i\stackrel{iid}{\sim}N(\mu_X,\sigma_X^2),\quad i=1,\dots,n_X,
$$

$$
Y_j\stackrel{iid}{\sim}N(\mu_Y,\sigma_Y^2),\quad j=1,\dots,n_Y,
$$

且两组样本独立。

### 22.11.1 均值差

样本均值差服从

$$
\bar X-\bar Y
\sim N\left(
\mu_X-\mu_Y,
\frac{\sigma_X^2}{n_X}+\frac{\sigma_Y^2}{n_Y}
\right).
$$

方差已知时可直接构造标准正态统计量。

### 22.11.2 方差比

两个独立样本方差满足

$$
\frac{(n_X-1)S_X^2}{\sigma_X^2}\sim\chi^2(n_X-1),
\qquad
\frac{(n_Y-1)S_Y^2}{\sigma_Y^2}\sim\chi^2(n_Y-1),
$$

所以

$$
\boxed{
\frac{S_X^2/S_Y^2}{\sigma_X^2/\sigma_Y^2}
\sim F(n_X-1,n_Y-1).
}
$$

当 $\sigma_X^2=\sigma_Y^2$ 时，比值 $S_X^2/S_Y^2\sim F(n_X-1,n_Y-1)$。

### 22.11.3 合并方差与合并 $t$

若两个总体方差相同但未知，记共同方差为 $\sigma^2$，定义合并方差

$$
\boxed{
S_p^2=
\frac{(n_X-1)S_X^2+(n_Y-1)S_Y^2}
{n_X+n_Y-2}.
}
$$

这是自由度加权平均，不是普通算术平均。权重为

$$
\frac{n_X-1}{n_X+n_Y-2},
\qquad
\frac{n_Y-1}{n_X+n_Y-2}.
$$

Lean 验证权重之和为 1：

```lean
example (m n : ℚ) (h : m + n - 2 ≠ 0) :
    (m - 1) / (m + n - 2) +
    (n - 1) / (m + n - 2) = 1 := by
  field_simp
  ring
```

Python 对具体数据做精确分数核对：

```python
sp2 = ((nx - 1) * svar(xa) + (ny - 1) * svar(ya)) / (nx + ny - 2)
w = Fraction(nx - 1, nx + ny - 2)
assert sp2 == w * svar(xa) + (1 - w) * svar(ya)
assert sp2 != (svar(xa) + svar(ya)) / 2
```

在同方差正态模型下，

$$
T_p=
\frac{(\bar X-\bar Y)-(\mu_X-\mu_Y)}
{S_p\sqrt{1/n_X+1/n_Y}}
\sim t(n_X+n_Y-2).
$$

程序用固定种子模拟确认 KS 距离很小：

```python
tt = (((A.mean(axis=1) - B.mean(axis=1)) -
       (1.0 - (-2.0))) /
      np.sqrt(sp2n * (1 / nx + 1 / ny)))
assert stats.kstest(tt, stats.t(nx + ny - 2).cdf).statistic < 0.005
assert stats.kstest(va / vb, stats.f(nx - 1, ny - 1).cdf).statistic < 0.005
```

## 22.12 Welch 修正与异方差警示

如果两个总体方差不相等，合并方差就不再估计一个共同参数，合并 $t$ 也没有精确 $t(n_X+n_Y-2)$ 分布。Welch 方法使用

$$
T_W=\frac{\bar X-\bar Y}
{\sqrt{S_X^2/n_X+S_Y^2/n_Y}},
$$

并用近似自由度

$$
\boxed{
\nu_W=
\frac{(S_X^2/n_X+S_Y^2/n_Y)^2}
{\frac{(S_X^2/n_X)^2}{n_X-1}
+\frac{(S_Y^2/n_Y)^2}{n_Y-1}}.
}
$$

它满足

$$
\min(n_X-1,n_Y-1)\le\nu_W\le n_X+n_Y-2.
$$

程序对一组精确有理样本计算 Welch 自由度并检查该范围：

```python
nu_w = (vx / nx + vy / ny) ** 2 / (
    (vx / nx) ** 2 / (nx - 1) +
    (vy / ny) ** 2 / (ny - 1))
assert min(nx - 1, ny - 1) <= nu_w <= nx + ny - 2
```

更重要的是，模拟展示错误同方差假设的后果。若大方差落在样本量较大的一组，合并方差被高估，检验会偏保守；若大方差落在样本量较小的一组，检验会反保守：

```python
crit = stats.t.ppf(0.975, nx + ny - 2)
assert rej < 0.03     # 大样本组方差更大：名义 5%，实际更低
assert rej2 > 0.15   # 小样本组方差更大：名义 5%，实际远超 5%
```

这些拒绝率来自固定种子重复抽样，是假设失效时的数值警报，而不是名义显著性的证明。

### 22.12.1 非正态总体下 $F$ 检验尤其脆弱

正态理论中的方差比分布严重依赖四阶矩。对指数总体，程序发现双侧名义 5% 的 $F$ 方差比检验实际拒绝率超过 15%；单样本 $t$ 检验在该样本量下相对稳健但也有失真：

```python
assert rej_F > 0.15
assert 0.04 < rej_t < 0.12
```

因此，“$t$ 在中等样本量下较稳健”不能被误说成“所有正态抽样分布都稳健”。方差推断和 $F$ 检验对非正态性通常更敏感。

## 22.13 顺序统计量的抽样分布

样本统计量不限于均值和方差。令

$$
X_{(1)}\le X_{(2)}\le\cdots\le X_{(n)}
$$

为顺序统计量。若总体 CDF 为 $F$、密度为 $f$，则第 $k$ 顺序统计量的密度为

$$
\boxed{
f_{X_{(k)}}(x)
=
\frac{n!}{(k-1)!(n-k)!}
F(x)^{k-1}[1-F(x)]^{n-k}f(x).
}
$$

推导采用多项划分：在很小的区间 $[x,x+dx]$ 中放约一个观测，$k-1$ 个观测在 $x$ 左侧，其余在右侧。

对均匀分布 $U(0,1)$，$F(x)=x,f(x)=1$，所以

$$
U_{(k)}\sim\operatorname{Beta}(k,n-k+1).
$$

其均值和方差为

$$
E[U_{(k)}]=\frac{k}{n+1},
$$

$$
\operatorname{Var}(U_{(k)})
=\frac{k(n-k+1)}{(n+1)^2(n+2)}.
$$

CDF 的二项尾形式为

$$
P(U_{(k)}\le x)
=\sum_{j=k}^n\binom njx^j(1-x)^{n-j}.
$$

Python 精确比较二项尾和 Beta CDF：

```python
for k in (1, 3, 5, 9):
    for xv in (Fraction(1, 5), Fraction(1, 2), Fraction(7, 10)):
        exact = sum(comb(nn, j) * xv ** j *
                    (1 - xv) ** (nn - j)
                    for j in range(k, nn + 1))
        assert abs(float(exact) -
                   stats.beta.cdf(float(xv), k, nn - k + 1)) < 1e-12
```

Julia 模拟第 $k$ 顺序统计量的均值和方差：

```julia
for k in (1, 5, 9)
    @assert abs(mean(u[k] for u in Us) - k / (nn + 1)) < 0.004
    v = k * (nn - k + 1) / ((nn + 1)^2 * (nn + 2))
    @assert abs(var([u[k] for u in Us]) - v) < 0.0007
end
```

均匀样本极差 $R=U_{(n)}-U_{(1)}$ 的均值为 $(n-1)/(n+1)$。顺序统计量分布还会在第 23 章用于均匀模型中最大值的充分性。

## 22.14 抽样分布与证据等级

本章机器材料分成四个层级：

1. **精确代数与机器证明**：平方和分解、Helmert 行正交、$t^2$ 代数、合并方差权重由 Lean 检查。
2. **符号计算**：SymPy 验证正交矩阵、平方和坐标恒等式。
3. **精确有限/解析账**：分数数据、二项尾与 Beta CDF、Gamma/$\chi^2$ 密度一致性由 Python 精确或高精度核对。
4. **固定种子随机模拟**：Julia 和 Python 使用种子 22 审计 $\chi^2,t,F$ 的样本分布。KS 距离小只代表实现与理论相容。

特别不能用模拟替代以下三个关键定理步骤：

- 正交变换保持标准正态向量分布；
- 残差子空间维数为 $n-1$；
- 正态样本中 $\bar X$ 与 $S^2$ 独立。

这些步骤才是 $t,F$ 精确定理成立的原因。

## 22.15 本章要点

1. 抽样分布是统计量在所有同样本容量中的分布，不是总体分布。
2. 正态 iid 样本满足 $\bar X\sim N(\mu,\sigma^2/n)$。
3. 平方和分解把总偏差分成样本均值偏差和残差偏差。
4. Helmert 正交变换说明残差平方和是 $n-1$ 个独立标准正态平方和。
5. $(n-1)S^2/\sigma^2\sim\chi^2(n-1)$，且正态样本中 $\bar X$ 与 $S^2$ 独立。
6. $t$ 是标准正态除以独立根号卡方/自由度；$F$ 是两个独立卡方按自由度之比。
7. $T^2\sim F(1,\nu)$。
8. 合并方差是自由度加权平均；Welch 公式处理异方差近似，错误同方差假设可使检验失真。
9. $\bar X$ 与 $S^2$ 独立以及 $F$ 方差比检验都强依赖正态性，不能随意推广到非正态总体。
10. 均匀顺序统计量服从 Beta 分布，一般顺序统计量密度可由二项划分得到。

*对应示例：`examples/lean/Probability/Ch22SamplingDistributions.lean`、`examples/julia/22_sampling_distributions.jl`、`examples/python/22_sampling_distributions.py`。*

---

上一章：[21 二元与多元正态](21-multivariate-normal.md) · 下一章：[23 充分统计量与数据简化](23-sufficiency.md)
