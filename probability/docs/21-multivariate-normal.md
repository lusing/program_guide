# 第 21 章 二元与多元正态

## 21.1 为什么多元正态值得单独讨论

正态分布在一元概率论中已经很重要；在多元统计、计量经济学、滤波和机器学习中，真正被反复使用的是多元正态。它有三个其他分布很少同时具备的性质：

1. 均值向量和协方差矩阵完全决定分布；
2. 线性变换后仍为多元正态；
3. 在联合正态前提下，零相关等价于独立，条件分布仍为正态。

第三点尤其容易被误用到非联合正态变量上。本章会先推导标准理论，再用两个“边际正态但非联合正态”的反例限定结论边界。

## 21.2 多元正态的定义

设 $Z=(Z_1,\dots,Z_r)^T$ ，其中各 $Z_i$ 相互独立且都服从 $N(0,1)$ 。若

$$
\boxed{X=\mu+AZ}
$$

是某个固定向量 $\mu\in\mathbb R^p$ 和固定 $p\times r$ 矩阵 $A$ 的仿射变换，则称 $X$ 服从多元正态分布。

此时

$$
E[X]=\mu,\qquad \operatorname{Cov}(X)=AA^T=:\Sigma.
$$

协方差矩阵 $\Sigma$ 半正定。若 $\Sigma$ 正定，则 $X$ 有 $p$ 维密度

$$
\boxed{
f_X(x)
=\frac1{(2\pi)^{p/2}\sqrt{\det\Sigma}}
\exp\left[-\frac12(x-\mu)^T\Sigma^{-1}(x-\mu)\right].
}
$$

若 $\Sigma$ 只是半正定而非正定，则随机向量被限制在某个低维仿射子空间上，不存在通常的 $p$ 维 Lebesgue 密度，但仿射变换定义仍然有效。

矩阵 $\Sigma^{-1}$ 称为精度矩阵，二次型

$$
D^2(x)=(x-\mu)^T\Sigma^{-1}(x-\mu)
$$

称为 Mahalanobis 平方距离。密度等高线不是圆，而是由 $D^2(x)=\text{常数}$ 给出的椭球。

## 21.3 矩母函数

多元正态的矩母函数为

$$
\boxed{
M_X(t)=E[e^{t^TX}]
=\exp\left(t^T\mu+\frac12t^T\Sigma t\right).
}
$$

这个公式也可作为协方差矩阵为 $\Sigma$ 的非退化多元正态定义；在奇异情形使用特征函数版本即可。

下面给出密度情形的配方。由

$$
(x-\mu)^T\Sigma^{-1}(x-\mu)-2t^Tx
$$

配成

$$
\begin{aligned}
&(x-\mu-\Sigma t)^T\Sigma^{-1}(x-\mu-\Sigma t)\\
&\qquad -2t^T\mu-t^T\Sigma t.
\end{aligned}
$$

把与 $x$ 无关的因子提出积分号，剩下的是一个平移后的正态密度积分，等于 1，于是得到上述 MGF。

Python 的 SymPy 程序在二维情形符号核对配方恒等式：

```python
lhs = ((X - mu).T * Sinv * (X - mu))[0] - 2 * (tt.T * X)[0]
rhs = ((X - mu - Sigma * tt).T * Sinv
       * (X - mu - Sigma * tt))[0] \
      - 2 * (tt.T * mu)[0] - (tt.T * Sigma * tt)[0]
assert sp.simplify(lhs - rhs) == 0
```

MGF 显示分布只依赖 $\mu,\Sigma$ ，也解释了为什么多元正态的均值和协方差不只是两个数值摘要，而是完整参数。

## 21.4 二元正态密度

二元正态有五个参数：

$$
\mu_1,\quad \mu_2,\quad \sigma_1>0,\quad \sigma_2>0,\quad -1<\rho<1.
$$

协方差矩阵为

$$
\Sigma=
\begin{pmatrix}
\sigma_1^2 & \rho\sigma_1\sigma_2\\
\rho\sigma_1\sigma_2 & \sigma_2^2
\end{pmatrix}.
$$

其行列式为

$$
\det\Sigma=\sigma_1^2\sigma_2^2(1-\rho^2).
$$

令

$$
a=\frac{x-\mu_1}{\sigma_1},\qquad
b=\frac{y-\mu_2}{\sigma_2}.
$$

密度指数中的二次型为

$$
q=\frac{a^2-2\rho ab+b^2}{1-\rho^2}.
$$

密度写成

$$
f_{X,Y}(x,y)
=\frac1{2\pi\sigma_1\sigma_2\sqrt{1-\rho^2}}
e^{-q/2}.
$$

参数 $\rho$ 正是 $X,Y$ 的相关系数。

## 21.5 二元正态的配方与条件分布

条件分布推导的关键恒等式是

$$
\boxed{
\frac{a^2-2\rho ab+b^2}{1-\rho^2}
=a^2+\frac{(b-\rho a)^2}{1-\rho^2}.
}
$$

Lean 对该恒等式做机器检查：

```lean
example (a b ρ : ℚ) (h : 1 - ρ ^ 2 ≠ 0) :
    (a ^ 2 - 2 * ρ * a * b + b ^ 2) / (1 - ρ ^ 2)
    = a ^ 2 + (b - ρ * a) ^ 2 / (1 - ρ ^ 2) := by
  field_simp
  ring
```

而

$$
b-\rho a
=\frac{(y-\mu_2)-\rho\frac{\sigma_2}{\sigma_1}(x-\mu_1)}
{\sigma_2}.
$$

因此联合密度可以分解为边际密度乘条件密度：

$$
f_{X,Y}(x,y)=f_X(x)f_{Y\mid X}(y\mid x),
$$

其中

$$
f_X(x)=\frac1{\sqrt{2\pi}\sigma_1}
\exp\left[-\frac{(x-\mu_1)^2}{2\sigma_1^2}\right],
$$

且

$$
\boxed{
Y\mid X=x\sim N\left(
\mu_2+\rho\frac{\sigma_2}{\sigma_1}(x-\mu_1),
\sigma_2^2(1-\rho^2)
\right).
}
$$

条件均值是 $x$ 的仿射函数：

$$
E[Y\mid X=x]
=\mu_2+\beta(x-\mu_1),
\qquad
\beta=\frac{\rho\sigma_2}{\sigma_1}.
$$

这正是一元线性回归中的回归系数；在二元正态模型中，最优条件期望恰好是直线。

条件方差为

$$
\boxed{
\operatorname{Var}(Y\mid X=x)
=\sigma_2^2(1-\rho^2).
}
$$

它不依赖 $x$ 。相关性越强，知道 $X$ 后剩余的方差越小；$|\rho|\to1$ 时条件方差趋于 0。

SymPy 程序构造 $f_X$ 和条件正态密度 $f_{Y\mid X}$ ，并符号验证二者乘积等于联合密度：

```python
q = (a ** 2 - 2 * rho * a * b + b ** 2) / (1 - rho ** 2)
f_xy = sp.exp(-q / 2) / (
    2 * sp.pi * s1 * s2 * sp.sqrt(1 - rho ** 2))
f_x = sp.exp(-a ** 2 / 2) / (sp.sqrt(2 * sp.pi) * s1)
mu_c = m2 + rho * s2 / s1 * (x - m1)
var_c = s2 ** 2 * (1 - rho ** 2)
f_cond = sp.exp(-(y - mu_c) ** 2 / (2 * var_c)) / sp.sqrt(
    2 * sp.pi * var_c)
ratio = sp.simplify(sp.powsimp(
    sp.expand_power_exp(f_xy / (f_x * f_cond))))
assert sp.simplify(ratio - 1) == 0
```

### 21.5.1 数值例子

取

$$
\sigma_1=2,\qquad \sigma_2=3,\qquad \rho=\frac12.
$$

则

$$
\Sigma=
\begin{pmatrix}
4&3\\3&9
\end{pmatrix},
\qquad \det\Sigma=36-9=27.
$$

条件方差为

$$
9\left(1-\frac14\right)=\frac{27}{4},
$$

回归斜率为

$$
\beta=\frac{3}{4}.
$$

Prolog 用有理数精确检查：

```prolog
Schur is S2 * S2 - C12 * C12 / (S1 * S1),
Schur =:= S2 * S2 * (1 - Rho * Rho),
Schur =:= 27 rdiv 4,
Beta is C12 / (S1 * S1),
Beta =:= Rho * S2 / S1,
Beta =:= 3 rdiv 4
```

Lean 的对应数值断言为：

```lean
example : (4 : ℚ) * 9 - 3 * 3 = 27
    ∧ (9 : ℚ) - 3 * 3 / 4 = 27 / 4
    ∧ (9 : ℚ) * (1 - (1 / 2) ^ 2) = 27 / 4 := by
  norm_num
```

条件均值解释了一部分方差：

$$
\beta^2\sigma_1^2+\sigma_2^2(1-\rho^2)
=\sigma_2^2.
$$

这正是第 20 章全方差公式在正态模型中的形式。

## 21.6 一般分块公式与 Schur 补

把随机向量分成两块：

$$
X=
\begin{pmatrix}
X_A\\X_B
\end{pmatrix},
\qquad
\Sigma=
\begin{pmatrix}
\Sigma_{AA}&\Sigma_{AB}\\
\Sigma_{BA}&\Sigma_{BB}
\end{pmatrix}.
$$

假设 $\Sigma_{BB}$ 可逆。则

$$
\boxed{
X_A\mid X_B=x_B
\sim N\left(
\mu_A+\Sigma_{AB}\Sigma_{BB}^{-1}(x_B-\mu_B),
\Sigma_{AA}-\Sigma_{AB}\Sigma_{BB}^{-1}\Sigma_{BA}
\right).
}
$$

矩阵

$$
\boxed{
\Sigma_{A\mid B}
=\Sigma_{AA}-\Sigma_{AB}\Sigma_{BB}^{-1}\Sigma_{BA}
}
$$

称为 Schur 补。它是条件协方差矩阵。

考虑

$$
\Sigma=
\begin{pmatrix}
4&2&1\\
2&3&\frac12\\
1&\frac12&2
\end{pmatrix}.
$$

给定 $X_3$ 后，$(X_1,X_2)$ 的条件协方差为

$$
\begin{pmatrix}
4&2\\2&3
\end{pmatrix}
-
\begin{pmatrix}1\\1/2\end{pmatrix}
\frac12
\begin{pmatrix}1&1/2\end{pmatrix}
=
\begin{pmatrix}
7/2&7/4\\
7/4&23/8
\end{pmatrix}.
$$

条件均值对 $X_3$ 的回归系数为

$$
\Sigma_{AB}\Sigma_{BB}^{-1}
=
\begin{pmatrix}1/2\\1/4\end{pmatrix}.
$$

Prolog 逐个元素计算 Schur 补：

```prolog
schur(I, J, V) :-
    sigma(I, J, Aij),
    sigma(I, 3, Bi),
    sigma(J, 3, Bj),
    sigma(3, 3, C),
    V is Aij - Bi * Bj / C.
```

Python 用精确有理数矩阵进一步验证了精度矩阵关系：若 $\Lambda=\Sigma^{-1}$ ，则

$$
\Sigma_{A\mid B}=(\Lambda_{AA})^{-1},
$$

且回归系数满足

$$
\Sigma_{AB}\Sigma_{BB}^{-1}
=-(\Lambda_{AA})^{-1}\Lambda_{AB}.
$$

Schur 补与原协方差矩阵之差为

$$
\Sigma_{AB}\Sigma_{BB}^{-1}\Sigma_{BA}\succeq0,
$$

所以条件协方差矩阵在半正定序意义下不大于原协方差矩阵。对上述例子，条件方差 $7/2\le4$ 、$23/8\le3$ 。这与第 20 章的全方差公式一致：条件信息不会增加最优预测的最小均方误差。

## 21.7 Cholesky 生成

任何正定矩阵都可分解为

$$
\Sigma=LL^T,
$$

其中 $L$ 是下三角矩阵，且对角元为正。若 $Z$ 是独立标准正态向量，则

$$
\boxed{X=\mu+LZ}
$$

有均值 $\mu$ 和协方差

$$
\operatorname{Cov}(X)=LIL^T=LL^T=\Sigma.
$$

这给出多元正态的标准生成算法。Julia 程序使用

```julia
μ = [1.0, -2.0, 0.5]
Σ = [4.0 2.0 1.0; 2.0 3.0 0.5; 1.0 0.5 2.0]
L = cholesky(Symmetric(Σ)).L
Z = randn(N, 3)
X = μ' .+ Z * L'
```

并检查

```julia
@assert maximum(abs.(L * L' - Σ)) < 1e-12
@assert maximum(abs.(vec(mean(X; dims=1)) - μ)) < 0.03
@assert maximum(abs.(cov(X) - Σ)) < 0.06
```

Python 的固定种子版本同样先验证 `L @ L.T = Sigma`，再生成样本。样本均值和样本协方差接近参数是数值审计；分布正确的理由来自仿射变换定义与协方差计算。

## 21.8 Mahalanobis 距离服从 $\chi^2_p$

若 $X\sim N(\mu,\Sigma)$ ，且 $\Sigma$ 正定，则

$$
\boxed{
D^2=(X-\mu)^T\Sigma^{-1}(X-\mu)\sim\chi^2_p.
}
$$

证明使用 Cholesky 分解。令

$$
Z=L^{-1}(X-\mu).
$$

则 $Z$ 的各分量独立且为标准正态，所以

$$
D^2=Z^TZ=\sum_{j=1}^pZ_j^2.
$$

按定义，这就是 $\chi_p^2$ 随机变量。因此

$$
E[D^2]=p,\qquad \operatorname{Var}(D^2)=2p.
$$

Lean 文件只保留最基本的矩恒等式：

```lean
example : (1 : ℚ) + 1 = 2 := by norm_num
example : (3 : ℚ) - 1 ^ 2 = 2 := by norm_num
```

它们分别对应二维时均值为维数、单个 $Z_j^2$ 的方差为 $E[Z_j^4]-(E[Z_j^2])^2=3-1=2$ 。

在三维模拟中，Julia 检查均值约为 3、方差约为 6，中位数约为 2.366，95% 分位数约为 7.815：

```julia
d2 = [dot(D[i, :], Σ \ D[i, :]) for i in 1:N]
@assert abs(mean(d2) - 3) < 0.03
@assert abs(var(d2) - 6) < 0.15
@assert abs(median(d2) - 2.3660) < 0.04
@assert abs(mean(d2 .<= 7.8147) - 0.95) < 0.003
```

Python 还对经验分布做 Kolmogorov–Smirnov 检查。该检验只用于捕捉生成代码的明显错误，不构成定理证明。

## 21.9 线性变换、边际分布与和

若

$$
X\sim N(\mu,\Sigma)
$$

且 $A$ 是 $q\times p$ 固定矩阵，$b\in\mathbb R^q$ ，则

$$
\boxed{
AX+b\sim N(A\mu+b,A\Sigma A^T).
}
$$

由仿射定义最容易证明：若 $X=\mu+LZ$ ，则

$$
AX+b=(A\mu+b)+(AL)Z,
$$

它仍是独立标准正态变量的仿射变换，协方差为

$$
(AL)(AL)^T=A(LL^T)A^T=A\Sigma A^T.
$$

取选择矩阵即可得到：多元正态的任意子向量仍为多元正态；因此每个边际分量都是一元正态。

程序用

$$
A=
\begin{pmatrix}
1&-1&0\\
1/2&1/2&2
\end{pmatrix}
$$

生成两个线性组合，并检查样本协方差接近 $A\Sigma A^T$ ：

```julia
A = [1.0 -1.0 0.0; 0.5 0.5 2.0]
Y = X * A'
@assert maximum(abs.(cov(Y) - A * Σ * A')) < 0.12
```

对两个联合正态变量，

$$
X_1+X_2
\sim N(\mu_1+\mu_2,
\sigma_1^2+\sigma_2^2+2\rho\sigma_1\sigma_2).
$$

独立时交叉项为零，又回到独立正态变量和的公式。

要特别注意方向：**联合正态可以推出边际正态，但边际正态不能推出联合正态**。这是本章后半部分的重点。

## 21.10 联合正态下零相关等价独立

若 $X,Y$ 联合正态且 $\rho=0$ ，二元密度的二次型变成

$$
a^2+b^2,
$$

归一化常数也分解：

$$
2\pi\sigma_1\sigma_2
=\sqrt{2\pi\sigma_1^2}\sqrt{2\pi\sigma_2^2}.
$$

于是

$$
f_{X,Y}(x,y)=f_X(x)f_Y(y),
$$

所以 $X,Y$ 独立。

一般多元正态中，若两个分块的交叉协方差矩阵为零，

$$
\Sigma_{AB}=0,
$$

则密度或 MGF 按分块因子分解，两个分块独立。

反向方向对任何具有有限二阶矩的独立随机变量都成立：独立意味着零协方差。因此在**联合正态**前提下，

$$
\boxed{
\operatorname{Cov}(X_A,X_B)=0
\iff X_A\perp\!\!\!\perp X_B.
}
$$

Lean 检查 $\rho=0$ 时二次型分裂的代数核心：

```lean
example (a b : ℚ) :
    (a ^ 2 - 2 * 0 * a * b + b ^ 2) / (1 - 0 ^ 2)
    = a ^ 2 + b ^ 2 := by
  norm_num
```

这个结论不能推广为“两个正态变量零相关就独立”。前提必须是它们**联合**正态。

## 21.11 反例一：随机符号翻转

令

$$
X\sim N(0,1),
$$

令 $S\in\{-1,1\}$ 等概率且与 $X$ 独立，定义

$$
Y=SX.
$$

### 21.11.1 $Y$ 的边际仍是标准正态

对任意 Borel 集 $B$ ，由全概率公式，

$$
P(Y\in B)
=\frac12P(X\in B)+\frac12P(-X\in B).
$$

因为 $X\stackrel d=-X$ ，所以

$$
P(Y\in B)=P(X\in B).
$$

故 $Y\sim N(0,1)$ 。

### 21.11.2 协方差为零

由于 $E[S]=0$ ，

$$
E[XY]=E[SX^2]=E[S]E[X^2]=0.
$$

两者均值都为 0，所以

$$
\operatorname{Cov}(X,Y)=0.
$$

### 21.11.3 但二者不独立

总有

$$
|Y|=|X|,
$$

所以 $X$ 与 $Y$ 强烈相依。并且当 $S=-1$ 时，

$$
X+Y=X-X=0.
$$

因此

$$
P(X+Y=0)=\frac12.
$$

若 $(X,Y)$ 是二元正态，则 $X+Y$ 作为线性组合应是一元正态连续变量，在任意单点概率为 0。这与 $P(X+Y=0)=1/2$ 矛盾。故 $(X,Y)$ 不是联合正态。

还可看平方：

$$
E[X^2Y^2]=E[X^4]=3,
$$

而独立时应为

$$
E[X^2]E[Y^2]=1\cdot1=1.
$$

Python 使用固定种子 21 模拟并审计这些事实：

```python
rng = np.random.default_rng(21)
Xs = rng.standard_normal(n)
Ss = rng.choice([-1.0, 1.0], size=n)
Ys = Ss * Xs
assert abs(np.mean(Xs * Ys)) < 0.01
assert stats.kstest(Ys, "norm").pvalue > 1e-3
assert np.mean(np.abs(Xs + Ys) < 1e-12) > 0.49
assert abs(np.mean(Xs ** 2 * Ys ** 2) - 3) < 0.08
```

Julia 还检查 $X^2$ 与 $Y^2$ 的样本相关几乎为 1：

```julia
@assert abs(cor(Xr .^ 2, Yr .^ 2) - 1) < 1e-9
```

### 21.11.4 有限类比

连续反例依赖正态对称性；为了用精确枚举展示同样逻辑，Prolog 和 Lean 使用有限版本：令 $X$ 在 $\{-1,0,1\}$ 上等概率，$S$ 在 $\{-1,1\}$ 上等概率且独立，$Y=SX$ 。

此时

$$
P(X=0,Y=0)=\frac13,
$$

但

$$
P(X=0)P(Y=0)=\frac13\cdot\frac13=\frac19.
$$

Prolog 枚举六个等概率结果：

```prolog
findall(X-Y-P,
        ( member(X, [-1, 0, 1]), member(S, [-1, 1]),
          Y is S * X, P is 1 rdiv 6 ), Tab)
...
P00 =:= 1 rdiv 3,
PX0 * PY0 =:= 1 rdiv 9,
P00 =\= PX0 * PY0
```

这个有限分布本身不是正态，但它精确展示了“边际对称、零协方差、却不独立”的符号翻转机制。

## 21.12 反例二：限支撑的联合密度

设 $\phi$ 为标准正态密度，定义

$$
f_{X,Y}(x,y)=2\phi(x)\phi(y)\mathbf 1_{\{xy>0\}}.
$$

即密度只在第一、第三象限非零，且在这两个象限中的密度是独立标准正态密度的两倍。

### 21.12.1 边际仍为标准正态

固定 $x>0$ ，只对 $y>0$ 积分：

$$
f_X(x)=\int_0^\infty 2\phi(x)\phi(y)\,dy
=2\phi(x)\cdot\frac12=\phi(x).
$$

固定 $x<0$ ，只对 $y<0$ 积分，结果相同。因此 $X\sim N(0,1)$ 。由对称性，$Y\sim N(0,1)$ 。

Python 对 $x=0.7$ 和 $x=-1.3$ 做确定性数值积分：

```python
fx_num = integrate.quad(
    lambda v: 2 * phi(0.7) * phi(v), 0, np.inf)[0]
assert abs(fx_num - phi(0.7)) < 1e-10
fx_neg = integrate.quad(
    lambda v: 2 * phi(-1.3) * phi(v), -np.inf, 0)[0]
assert abs(fx_neg - phi(-1.3)) < 1e-10
```

### 21.12.2 联合分布不是二元正态

该密度在第二、第四象限完全为零，而任何非退化二元正态密度在整个 $\mathbb R^2$ 上都为正。因此它不可能是二元正态密度。

其协方差不为零。由第一、第三象限的对称性，

$$
E[XY]
=4\left(\int_0^\infty x\phi(x)\,dx\right)
\left(\int_0^\infty y\phi(y)\,dy\right).
$$

又因为

$$
\int_0^\infty x\phi(x)\,dx=\frac1{\sqrt{2\pi}},
$$

所以

$$
\operatorname{Cov}(X,Y)=E[XY]=\frac2\pi.
$$

程序数值核对该精确值：

```python
cov_num = 2 * 2 * integrate.quad(
    lambda v: v * phi(v), 0, np.inf)[0] ** 2
assert abs(cov_num - 2 / np.pi) < 1e-10
```

这个反例与符号翻转反例各强调一点：

- 符号翻转：两个边际正态、零相关，却不独立；错误在于不是联合正态。
- 限支撑密度：两个边际正态，联合密度甚至明显相依且相关不为零；同样不是联合正态。

## 21.13 条件残差与独立

在一般分块条件公式中，定义条件残差

$$
R_A=X_A-\mu_A-\Sigma_{AB}\Sigma_{BB}^{-1}(X_B-\mu_B).
$$

它与 $X_B$ 的协方差为

$$
\begin{aligned}
\operatorname{Cov}(R_A,X_B)
&=\Sigma_{AB}
-\Sigma_{AB}\Sigma_{BB}^{-1}\Sigma_{BB}\\
&=0.
\end{aligned}
$$

在线性回归中，残差与解释变量零相关通常只是投影性质；由于这里整个向量联合正态，$(R_A,X_B)$ 也联合正态，所以该零相关进一步推出独立。这就是为什么正态线性模型中的回归残差与回归项独立（在固定设计之外的随机正态设计情形中），而一般模型通常只能得到不相关。

Julia 用 Schur 补模拟检查残差与 $X_3$ 的样本协方差接近零：

```julia
res = X[:, A_idx] .-
      (X[:, B_idx] .- μ[B_idx]') * βc'
@assert maximum(abs.(cov(res, X[:, 3]))) < 0.02
```

Python 同时检查样本相关接近零。再次强调：这里的独立结论依赖联合正态；第 19、20 章的 $Y=X^2$ 反例中，非线性相依不会因为零相关而消失。

## 21.14 奇异多元正态

并非所有多元正态都有密度。例如令 $Z\sim N(0,1)$ ，定义

$$
(X_1,X_2)=(Z,Z).
$$

二者是同一个随机变量，协方差矩阵为

$$
\Sigma=
\begin{pmatrix}
1&1\\1&1
\end{pmatrix},
$$

其行列式为 0。随机向量全落在直线 $x_1=x_2$ 上，二维密度不存在，但它完全符合仿射定义。

奇异情形仍可使用 MGF：

$$
M(t)=\exp\left(t^T\mu+\frac12t^T\Sigma t\right),
$$

也可以使用线性变换性质。条件公式则需要被条件的分块协方差可逆；若 $\Sigma_{BB}$ 奇异，应先去掉确定性线性关系，或使用广义逆并额外注意可识别条件。

## 21.15 机器证据的层级

本章示例使用四种不同强度的证据：

1. **Lean 代数证明**：配方、条件方差、回归斜率、Schur 补数值和反例的有限有理版本，均由 `ring`、`field_simp`、`norm_num` 等检查。
2. **SymPy 符号推导**：二元密度因子分解、矩阵逆、MGF 配方和三维 Schur 补使用精确符号化简。
3. **确定性数值积分**：限支撑密度的边际和 $2/\pi$ 协方差由 SciPy 积分核对，误差阈值很小，但它仍是数值验证。
4. **固定种子随机模拟**：Cholesky 生成、Mahalanobis 分位数、条件残差和符号翻转使用种子 21；样本误差用于审计代码，不用于证明定理。

这种区分在多元统计中尤其重要。图上的椭圆样本看起来“很像正态”，但不能证明联合正态；反之，联合正态的许多结论来自密度因子分解和矩阵代数，可以完全精确地推导。

## 21.16 本章要点

1. 多元正态由均值向量 $\mu$ 和协方差矩阵 $\Sigma$ 完全决定；正定时才有密度。
2. 其 MGF 为 $\exp(t^T\mu+\frac12t^T\Sigma t)$ 。
3. 二元正态配方给出条件均值直线和条件方差 $\sigma_2^2(1-\rho^2)$ 。
4. 一般条件协方差是 Schur 补 $\Sigma_{AA}-\Sigma_{AB}\Sigma_{BB}^{-1}\Sigma_{BA}$ 。
5. Cholesky 分解把一般多元正态化为独立标准正态变量的仿射变换。
6. Mahalanobis 平方距离服从 $\chi_p^2$ 。
7. 线性变换保持多元正态，均值和协方差分别变为 $A\mu+b$ 和 $A\Sigma A^T$ 。
8. 联合正态下零相关等价独立；但两个边际正态变量未必联合正态。
9. 符号翻转和限支撑密度两个反例表明：必须检查联合分布，而不能只看边际和相关系数。

*对应示例：`examples/lean/Probability/Ch21MultivariateNormal.lean`、`examples/julia/21_multivariate_normal.jl`、`examples/python/21_multivariate_normal.py`、`examples/prolog/21_multivariate_normal.pl`。*

---

上一章：[20 条件期望与条件方差](20-conditional-expectation.md) · 下一章：[22 随机样本与抽样分布](22-sampling-distributions.md)
