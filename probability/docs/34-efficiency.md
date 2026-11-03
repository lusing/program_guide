# 第 34 章 UMVU、Rao–Blackwell 与信息下界

## 34.1 三种“最优”不能混为一谈

前面已经看到，最小 MSE 的有偏估计可能优于无偏估计。

本章缩小比较范围：先只在无偏估计量中寻找方差最小者，再用 Fisher 信息给出正则模型下的方差下界。

这里有三条相关但不同的路线：

1. **Rao–Blackwell 化**：给定充分统计量，把任一估计量条件化，保持均值并降低方差；
2. **Lehmann–Scheffé 思想**：若充分统计量还完备，其无偏函数给出 UMVU；
3. **Cramér–Rao 下界**：在允许对参数求导并交换积分与求导的模型中，用得分信息限制估计方差。

它们回答的问题不同：

- Rao–Blackwell 不依赖参数可微性；
- 完备性用于保证无偏条件化的唯一性；
- Cramér–Rao 下界依赖模型正则性；
- 达到下界足以判定有效，但未达到下界不等于不是 UMVU。

最后一条将在正态方差例子中成为核心。

## 34.2 无偏性与 UMVU

设参数为 $\theta$，关心的参数函数为 $\tau(\theta)$。

估计量 $T$ 无偏，是指

$$
E_\theta[T]=\tau(\theta),
\qquad \text{对所有 }\theta\in\Theta.
$$

无偏性是整个参数空间上的约束，不是只在某一个 guessed 真值处成立。

若 $\mathcal U_\tau$ 是所有具有有限二阶矩的无偏估计量之集合，而 $T^*\in\mathcal U_\tau$ 满足

$$
\operatorname{Var}_\theta(T^*)
\le \operatorname{Var}_\theta(T)
$$

对所有 $\theta$ 和所有 $T\in\mathcal U_\tau$ 成立，则称 $T^*$ 为一致最小方差无偏估计量，简称 UMVU。

“一致”指同一个估计量在每个参数值处都不更差。

只在某一个 $\theta_0$ 处方差最小，不足以称为全参数空间上的 UMVU。

### 有偏估计不在比赛中

UMVU 不排除某个有偏估计具有更小 MSE。

第 31 章的正态方差缩放已经展示，无偏准则和 MSE 准则可以给出不同答案。

因此报告“最优”时必须同时报告：

- 比较集合是什么；
- 损失或准则是什么；
- 是否要求对所有参数一致成立。

## 34.3 Rao–Blackwell：为什么条件化不会变差

设 $S=S(X)$ 是充分统计量，$T$ 是 $\tau(\theta)$ 的无偏估计量。

定义条件化估计量

$$
U=E[T\mid S].
$$

充分性保证给定 $S$ 后数据条件分布不依赖 $\theta$，所以 $U$ 可以作为不依赖未知参数的统计量实际计算。

若没有充分性，$E_\theta[T\mid S]$ 可能仍含 $\theta$，就不是合法估计量。

### 均值不变

由塔性质，

$$
E_\theta[U]
=E_\theta[E[T\mid S]]
=E_\theta[T]
=\tau(\theta).
$$

所以条件化保持无偏。

### 方差不增

由全方差公式，

$$
\operatorname{Var}_\theta(T)
=\operatorname{Var}_\theta(E[T\mid S])
+E_\theta[\operatorname{Var}_\theta(T\mid S)].
$$

即

$$
\boxed{
\operatorname{Var}_\theta(T)
=\operatorname{Var}_\theta(U)
+E_\theta[\operatorname{Var}_\theta(T\mid S)]
\ge \operatorname{Var}_\theta(U).
}
$$

减少的部分恰是“给定充分统计量后仍残留的随机性”。

若该条件方差以正概率严格为正，改进就是严格的。

若 $T$ 已经是 $S$ 的函数，则 $E[T\mid S]=T$，再次条件化不会改变它。

## 34.4 Bernoulli 样本：从单个观测到样本均值

设 $X_1,\ldots,X_n$ iid 服从 Bernoulli$(p)$。

要估计 $\tau(p)=p$。

最简单的无偏估计量是

$$
T=X_1.
$$

它满足 $E_p[T]=p$，但完全丢弃了其余 $n-1$ 个观测。

令

$$
K=\sum_{i=1}^nX_i.
$$

$K$ 是充分统计量。

由交换对称性，给定 $K=k$ 时，所有恰有 $k$ 个 1 的序列等可能，因此

$$
E[X_1\mid K=k]=\frac kn.
$$

于是 Rao–Blackwell 化得到

$$
U=E[X_1\mid K]=\frac Kn=\bar X.
$$

两者的方差分别为

$$
\operatorname{Var}_p(X_1)=p(1-p),
$$

$$
\operatorname{Var}_p(\bar X)=\frac{p(1-p)}n.
$$

Python 通过完整枚举 $2^4$ 个样本点验证这条改进，而不是模拟近似：

```python
n, p = 4, F(1, 3)
raw, improved = [], []
for bits in product((0, 1), repeat=n):
    weight = p ** sum(bits) * (1 - p) ** (n - sum(bits))
    raw.append((F(bits[0]), weight))
    improved.append((F(sum(bits), n), weight))
```

这里 `raw` 记录 $X_1$ 的取值和概率，`improved` 记录 $K/n$ 的取值和概率。

随后：

```python
raw_mean, raw_variance = mean_and_variance(raw)
rb_mean, rb_variance = mean_and_variance(improved)
assert raw_mean == rb_mean == p
assert raw_variance == p * (1 - p)
assert rb_variance == p * (1 - p) / n
```

在 $p=1/3,n=4$ 时，方差由 $2/9$ 降为 $1/18$。

精确枚举证明了这个有限样本分布中的账；条件方差公式则给出一般 $p,n$ 的证明。

## 34.5 完备性为什么提供唯一性

充分性让我们能够条件化，但不同的无偏估计量条件化后是否一定相同，还需要完备性。

统计量 $S$ 完备，是指对任意满足可积条件的函数 $h$，

$$
E_\theta[h(S)]=0
\quad\text{对所有 }\theta
\quad\Longrightarrow\quad
h(S)=0
\quad\text{几乎必然，对每个 }\theta.
$$

完备性不是说“数据被完整记录”，而是说该统计量的分布族没有非平凡的、在所有参数下均值为零的函数。

### Lehmann–Scheffé 论证

设 $S$ 完备充分，且存在 $\tau(\theta)$ 的无偏估计量 $T_0$。

定义

$$
U^*=E[T_0\mid S].
$$

对任意另一个无偏估计量 $T$，定义

$$
U_T=E[T\mid S].
$$

两者都无偏，所以

$$
E_\theta[U^*-U_T]=0
\qquad \forall\theta.
$$

而 $U^*-U_T$ 是 $S$ 的函数。

由完备性，

$$
U^*=U_T\quad\text{几乎必然}.
$$

Rao–Blackwell 又给出

$$
\operatorname{Var}_\theta(U^*)
=\operatorname{Var}_\theta(U_T)
\le \operatorname{Var}_\theta(T).
$$

因此 $U^*$ 是 UMVU。

实际应用中，如果能直接找到完备充分统计量的无偏函数 $g(S)$，就不必从每个候选估计量重新条件化：

> 完备充分统计量的无偏函数，就是相应参数函数的 UMVU。

前提是它确实无偏且二阶矩有限。

## 34.6 Bernoulli 的完备充分性结论

Bernoulli 样本中

$$
K=\sum_iX_i\sim\operatorname{Bin}(n,p).
$$

若

$$
E_p[h(K)]=\sum_{k=0}^n h(k)\binom nk p^k(1-p)^{n-k}=0
$$

对所有 $0<p<1$ 成立，除以 $(1-p)^n$，可知一个关于 $p/(1-p)$ 的多项式恒为零。

所以每个系数都为零，进而 $h(k)=0$。

因此 $K$ 完备充分。

由于 $\bar X=K/n$ 无偏，它是 $p$ 的 UMVU。

这个结论不需要先计算 Cramér–Rao 下界。

后面计算下界，会进一步看到 $\bar X$ 恰好达到它；两种方法在此相合。

## 34.7 正态方差的重要预告

设 $X_1,\ldots,X_n$ iid 服从 $N(\mu,v)$，其中 $v=\sigma^2$，且 $\mu,v$ 都未知，$n\ge2$。

完整双参数正态族给出完备充分统计量

$$
\left(\bar X,\sum_i(X_i-\bar X)^2\right).
$$

无偏样本方差

$$
S^2=\frac1{n-1}\sum_i(X_i-\bar X)^2
$$

是第二个分量的函数，并满足 $E[S^2]=v$。

因此 $S^2$ 是 $v$ 的 UMVU。

然而后面的信息计算会给出

$$
\operatorname{Var}(S^2)=\frac{2v^2}{n-1}
>
\frac{2v^2}{n}
=\text{Cramér–Rao 下界}.
$$

这不是矛盾。

CR 下界只是所有正则无偏估计的一个下界，可能不可达。

完备充分性给出的是实际可达估计量中的最小方差。

## 34.8 得分与 Fisher 信息：联合样本版本

设联合样本 $X=(X_1,\ldots,X_n)$ 的密度或概率质量函数为 $f_n(x;\theta)$。

先考虑标量 $\theta$。

得分为

$$
S_n(\theta)
=\frac{\partial}{\partial\theta}\log f_n(X;\theta)
=\frac{\partial_\theta f_n(X;\theta)}{f_n(X;\theta)}.
$$

联合 Fisher 信息定义为

$$
I_n(\theta)=E_\theta[S_n(\theta)^2].
$$

若 $E_\theta[S_n]=0$，这也等于 $\operatorname{Var}_\theta(S_n)$。

离散模型中，下文的积分全部替换为求和；所需可微与可积条件同样保留。

## 34.9 正则条件究竟用在哪里

Cramér–Rao 推导不是纯代数。

至少需要以下条件：

1. 在考虑的参数邻域内，密度对 $\theta$ 可微；
2. 密度在相关点为正，或适当处理零测集；
3. 支撑不随 $\theta$ 以破坏求导的方式变化；
4. 对常数函数 $1$，可以交换参数求导与积分；
5. 对估计量 $T$，也可以交换参数求导与积分；
6. 得分二阶矩有限且 $0<I_n(\theta)<\infty$；
7. $E_\theta[T]=\psi(\theta)$ 可微，相关协方差存在。

最关键的两个等式是

$$
\frac{d}{d\theta}\int f_n(x;\theta)\,dx
=\int \partial_\theta f_n(x;\theta)\,dx
$$

和

$$
\frac{d}{d\theta}\int T(x)f_n(x;\theta)\,dx
=\int T(x)\partial_\theta f_n(x;\theta)\,dx.
$$

它们不是由“函数看起来光滑”自动保证。

常见充分条件涉及局部可积控制函数、指数族自然参数形式或离散有限和的稳定性。

本章把这些条件写进定理，而不是把推导写成无条件恒等式。

## 34.10 得分零均值

由于密度总质量为 1，

$$
\int f_n(x;\theta)\,dx=1.
$$

对参数求导并交换顺序：

$$
0
=\frac{d}{d\theta}\int f_n(x;\theta)\,dx
=\int\partial_\theta f_n(x;\theta)\,dx.
$$

利用

$$
\partial_\theta f_n
=\left(\partial_\theta\log f_n\right)f_n,
$$

得到

$$
\boxed{E_\theta[S_n(\theta)]=0.}
$$

这一步也解释了为什么支撑不能随意依赖参数。

例如 $U(0,\theta)$ 的密度积分的区域本身就是 $[0,\theta]$。

若只对被积函数形式求导而忘记移动边界，就漏掉了边界项。

所以均匀支撑的 MLE 不能直接套用这个正则推导。

## 34.11 估计量均值的导数等于协方差

令

$$
\psi(\theta)=E_\theta[T].
$$

在第二个交换条件下，

$$
\psi'(\theta)
=\int T(x)\partial_\theta f_n(x;\theta)\,dx
=E_\theta[T S_n].
$$

由于 $E_\theta[S_n]=0$，

$$
\boxed{
\psi'(\theta)=\operatorname{Cov}_\theta(T,S_n).
}
$$

若 $T$ 无偏估计 $\tau(\theta)$，则 $\psi=\tau$，所以左边就是 $\tau'(\theta)$。

若 $T$ 有偏，下界仍然可用，只是分子要换成其实际均值函数 $\psi$ 的导数。

因此“CR 只适用于无偏估计”并不准确；无偏版本只是最常用的特例。

## 34.12 Cauchy–Schwarz 一步得到下界

对 $T$ 与 $S_n$ 使用 Cauchy–Schwarz：

$$
\operatorname{Cov}_\theta(T,S_n)^2
\le
\operatorname{Var}_\theta(T)
\operatorname{Var}_\theta(S_n).
$$

代入前两节结果：

$$
[\psi'(\theta)]^2
\le
\operatorname{Var}_\theta(T)I_n(\theta).
$$

因为 $I_n>0$，得到一般信息不等式

$$
\boxed{
\operatorname{Var}_\theta(T)
\ge
\frac{[\psi'(\theta)]^2}{I_n(\theta)},
\qquad
\psi(\theta)=E_\theta[T].
}
$$

若 $T$ 无偏估计 $\tau(\theta)$，则

$$
\boxed{
\operatorname{Var}_\theta(T)
\ge
\frac{[\tau'(\theta)]^2}{I_n(\theta)}.
}
$$

特别地，直接估计标量参数 $\theta$ 且无偏时，$\tau'=1$，下界为 $1/I_n$。

## 34.13 IID 样本中的 $n$ 倍信息

若样本 iid，则

$$
f_n(x;\theta)=\prod_{i=1}^nf(x_i;\theta),
\qquad
S_n(\theta)=\sum_{i=1}^ns(X_i;\theta).
$$

各观测得分均值为零且相互独立，所以

$$
I_n(\theta)
=\operatorname{Var}_\theta\left(\sum_i s(X_i;\theta)\right)
=nI_1(\theta).
$$

因此无偏估计 $\tau(\theta)$ 的下界为

$$
\boxed{
\operatorname{Var}_\theta(T)
\ge\frac{[\tau'(\theta)]^2}{nI_1(\theta)}.
}
$$

这解释了正则估计通常具有 $1/n$ 方差尺度。

但“通常”不包括所有非正则问题。

例如 $U(0,\theta)$ 的最大次序统计量以更快的 $1/n$ 误差尺度接近边界，不能套用上述结论。

## 34.14 等号条件：估计量必须是得分的仿射函数

Cauchy–Schwarz 取等号，当且仅当两个中心化变量几乎必然成比例。

因此在固定 $\theta$ 处，达到 CR 下界等价于存在常数 $a(\theta)$，使

$$
\boxed{
T-\psi(\theta)=a(\theta)S_n(\theta)
\quad\text{几乎必然}.
}
$$

由协方差计算，非退化时

$$
a(\theta)=\frac{\psi'(\theta)}{I_n(\theta)}.
$$

所以等号不是“方差公式碰巧相等”的神秘事件，而是估计误差与得分完全线性对齐。

对无偏估计 $\tau(\theta)$，这写为

$$
T-\tau(\theta)=a(\theta)S_n(\theta).
$$

指数族之所以经常达到下界，是因为其自然形式使得分是充分统计量的仿射函数。

反之，若某个估计量达不到下界，也可能只是下界不可达，并不能据此否定它的 UMVU 地位。

## 34.15 Bernoulli 均值达到下界

单个 Bernoulli 观测的对数概率为

$$
\ell(X;p)=X\log p+(1-X)\log(1-p).
$$

得分为

$$
s(X;p)=\frac Xp-\frac{1-X}{1-p}
=\frac{X-p}{p(1-p)}.
$$

所以

$$
I_1(p)
=E\left[\frac{(X-p)^2}{p^2(1-p)^2}\right]
=\frac1{p(1-p)}.
$$

对 $n$ 个 iid 观测，

$$
I_n(p)=\frac{n}{p(1-p)}.
$$

无偏估计 $p$ 的 CR 下界为

$$
\frac1{I_n(p)}=\frac{p(1-p)}n.
$$

而样本均值的方差恰好就是 $p(1-p)/n$，所以等号成立。

从等号条件也能直接看：

$$
S_n(p)=\frac{\sum_iX_i-np}{p(1-p)}
=\frac{n(\bar X-p)}{p(1-p)}.
$$

所以

$$
\bar X-p=\frac{p(1-p)}n S_n(p),
$$

完全符合得分的仿射形式。

Python 用 $n=8,p=1/4$ 的二项分布精确求和：

```python
information = F(n, 1) / (p * (1 - p))
cr_bound = 1 / information
assert mean_phat == p
assert var_phat == cr_bound == p * (1 - p) / n
```

此时下界和方差都为 $3/128$。

这里不是用 Monte Carlo 判断两个小数接近，而是精确有理数相等。

Julia 单元用另一条实现复核同一个二项枚举：

```julia
information = n / (p * (1 - p))
cr_bound = 1 / information
@assert mean_phat == p
@assert var_phat == cr_bound == p * (1 - p) / n
```

Julia 的 `p`、`n` 和 `cr_bound` 在此均为有理数，所以 `==` 是精确相等判断。

这与 Python 的 `Fraction` 对账，不需要容差。

## 34.16 Poisson 均值同样达到下界

若 $X_i$ iid 服从 Poisson$(\lambda)$，单观测得分为

$$
s(X;\lambda)=\frac X\lambda-1
=\frac{X-\lambda}{\lambda}.
$$

所以

$$
I_1(\lambda)
=\frac{\operatorname{Var}(X)}{\lambda^2}
=\frac1\lambda.
$$

无偏估计 $\lambda$ 的 CR 下界是

$$
\frac1{nI_1(\lambda)}=\frac\lambda n.
$$

样本均值满足

$$
E[\bar X]=\lambda,
\qquad
\operatorname{Var}(\bar X)=\frac\lambda n.
$$

因此 $\bar X$ 达到下界。

同时 $\sum_iX_i$ 是 Poisson 族的完备充分统计量，所以 Lehmann–Scheffé 也给出同一结论。

## 34.17 正态均值：已知方差时

若 $X_i\sim N(\mu,v)$，且 $v$ 已知，则单观测关于 $\mu$ 的得分为

$$
\frac{\partial}{\partial\mu}
\left[-\frac{(X-\mu)^2}{2v}\right]
=\frac{X-\mu}{v}.
$$

因此

$$
I_1(\mu)=\frac{\operatorname{Var}(X)}{v^2}=\frac1v.
$$

样本均值无偏，且

$$
\operatorname{Var}(\bar X)=\frac vn
=\frac1{nI_1(\mu)}.
$$

所以 $\bar X$ 达到 CR 下界。

当 $v$ 也未知时，$\mu$ 与 $v$ 的信息矩阵在该参数化下是对角的，$\bar X$ 仍是 $\mu$ 的 UMVU，并达到相应的单参数方向下界。

## 34.18 正态方差：未达到下界却仍是 UMVU

现在估计 $v=\sigma^2$，且 $\mu$ 未知。

正态双参数模型关于 $v$ 的单观测信息为

$$
I_{vv,1}=\frac1{2v^2}.
$$

参数函数 $\tau(\mu,v)=v$ 对 $v$ 的导数为 1，因此样本下界是

$$
B_n=\frac{2v^2}{n}.
$$

另一方面，

$$
\frac{(n-1)S^2}{v}\sim\chi^2_{n-1},
$$

而卡方变量方差为自由度的 2 倍，所以

$$
\operatorname{Var}(S^2)=\frac{2v^2}{n-1}.
$$

两者差为

$$
\boxed{
\operatorname{Var}(S^2)-B_n
=\frac{2v^2}{n(n-1)}>0.
}
$$

因此 $S^2$ 未达到 CR 下界。

但第 34.7 节已经由完备充分性证明它是 UMVU。

这正说明：

$$
\boxed{
\text{未达到 CR 下界}\not\Longrightarrow\text{不是 UMVU}.
}
$$

若把“下界不可达”误判为“还有另一个无偏估计能达到”，就会去寻找不存在的估计量。

### 若均值已知

若 $\mu$ 已知，模型变成一个单参数族。

此时

$$
T_\mu=\frac1n\sum_{i=1}^n(X_i-\mu)^2
$$

无偏，且

$$
\operatorname{Var}(T_\mu)=\frac{2v^2}{n}.
$$

它达到已知均值模型的下界。

但 $\mu$ 未知时，$T_\mu$ 不是可计算统计量，不能把它放进同一个估计量集合比较。

### 数值账

取 $n=10,v=3$，则

$$
\operatorname{Var}(S^2)=2,
\qquad
B_n=\frac95,
\qquad
\operatorname{Var}(S^2)-B_n=\frac15.
$$

Python 和 Julia 都精确检查：

```python
var_s2 = 2 * v ** 2 / (n - 1)
cr_v = 2 * v ** 2 / n
assert var_s2 == 2
assert cr_v == F(9, 5)
assert var_s2 - cr_v == F(1, 5)
```

下界与实际方差之比为

$$
\frac{B_n}{\operatorname{Var}(S^2)}
=\frac{n-1}{n}=\frac9{10}.
$$

这只是有限样本 CR 效率比，不是对 UMVU 结论的否定。

## 34.19 向量参数与矩阵下界

若 $\theta\in\mathbb R^p$，得分是列向量

$$
S_n=\nabla_\theta\log f_n(X;\theta),
$$

信息矩阵为

$$
I_n=E[S_nS_n'].
$$

设 $T$ 估计 $r$ 维参数函数 $\tau(\theta)$，且 $E[T]=\psi(\theta)$。

令

$$
D=\frac{\partial\psi(\theta)}{\partial\theta'}
$$

为 $r\times p$ Jacobi 矩阵。

在相应正则条件下，矩阵信息不等式为

$$
\boxed{
\operatorname{Cov}_\theta(T)
\succeq D I_n(\theta)^{-1}D'.
}
$$

这里 $A\succeq B$ 表示 $A-B$ 半正定。

等价地，对任意 $c\in\mathbb R^r$，

$$
\operatorname{Var}(c'T)
\ge c'DI_n^{-1}D'c.
$$

矩阵下界不是把每个分量分别下界后就结束；它还包含不同估计分量之间的协方差约束。

若信息矩阵奇异，不能机械求逆，应改用可识别方向、伪逆或重新参数化，并重新解释参数函数。

## 34.20 非正则模型：为什么均匀支撑不能直接套公式

设 $X_i$ iid 服从 $U(0,\theta)$。

密度为

$$
f(x;\theta)=\frac1\theta\mathbf 1\{0<x<\theta\}.
$$

支撑随 $\theta$ 移动。

考虑 $T=\max_iX_i$，其分布集中在 $\theta$ 下方，并且误差尺度为 $1/n$。

若忽略指示函数的边界，只对 $1/\theta$ 求导，就遗漏了 $x=\theta$ 附近密度进入或离开样本支撑所造成的项。

所以常规得分零均值与 CR 推导不能直接适用。

这不是说所有支撑依赖参数的模型都毫无信息下界，而是说必须改用适合非正则模型的分析，不能引用本章定理。

## 34.21 Lean 中的信息不等式代数

Lean 文件先定义标量下界：

```lean
def cramerRaoBound (psiPrime information : ℚ) : ℚ :=
  psiPrime ^ 2 / information
```

Cauchy–Schwarz 的概率证明在正文中完成后，最后一个“除以正信息”的代数步骤可以写成：

```lean
theorem cramer_rao_from_cauchy (v i c : ℚ) (hi : 0 < i)
    (hcs : c ^ 2 ≤ v * i) : c ^ 2 / i ≤ v := by
  exact (div_le_iff₀ hi).2 hcs
```

这里 `v` 对应方差，`i` 对应信息，`c` 对应均值函数的导数。

机器定理明确记录了必须除以正信息，避免把 $I=0$ 或负值当作合法除数。

正态方差的差距也被形式化为：

```lean
theorem normal_variance_gap (n v : ℚ)
    (hn : n ≠ 0) (hn1 : n - 1 ≠ 0) :
    2 * v ^ 2 / (n - 1) - 2 * v ^ 2 / n =
      2 * v ^ 2 / (n * (n - 1)) := by
  field_simp
```

这条证明只负责有理代数；卡方方差、完备性和充分性仍是正文中分别证明的统计内容。

把几层证据分开，比用一个巨大的黑盒自动化调用更能看清结论依赖什么。

## 34.22 有效性的几个口径

本章的“有效”至少可能有三种含义：

1. **达到 CR 下界**：在指定正则模型与参数点达到等号；
2. **UMVU**：在所有无偏估计中一致最小方差，即使下界不可达；
3. **渐近有效**：第 35 章讨论的渐近方差达到信息下界。

同一个估计量可能在一种口径下有效，在另一种口径下不达到某个数值界限。

正态 $S^2$ 是 UMVU，但有限样本 CR 效率为 $(n-1)/n$，不是 1。

当 $n\to\infty$ 时该比值趋于 1，这才连接到渐近有效性。

报告效率时必须写清分母、参数函数和样本量，避免只给一个“95% 有效”却没有定义。

## 34.23 常见误区

### 误区一：Rao–Blackwell 每次都会产生不同改进

若估计量已是充分统计量的函数，条件化就是它本身。

### 误区二：对任意统计量条件化都能降低方差

全方差公式可以形式化，但若条件分布依赖未知参数，结果可能不是合法估计量；充分性保证这一点。

### 误区三：完备性表示充分统计量包含全部数据

不是。完备性是零均值函数的唯一性，充分性才是参数信息的数据简化。

### 误区四：CR 下界是任意估计量的普遍下界

不是。非正则支撑、不可微模型、不可交换求导或零信息情形都可能越界或使公式无意义。

### 误区五：没达到下界就不是 UMVU

正态方差的 $S^2$ 是直接反例。

### 误区六：有偏估计不能讨论信息不等式

可以使用一般形式，只是分子是 $dE_\theta[T]/d\theta$，不是自动写 1。

## 34.24 本章要点

1. Rao–Blackwell 化保持均值，并通过全方差公式降低或保持方差。
2. 完备充分统计量的无偏函数是 UMVU，核心是无偏条件化的唯一性。
3. CR 推导依赖两次“参数求导与积分交换”，分别给出得分零均值和协方差恒等式。
4. 一般标量下界为 $[\psi'(\theta)]^2/I_n(\theta)$，其中 $\psi=E_\theta[T]$。
5. 等号要求估计误差与得分几乎必然成比例。
6. Bernoulli、Poisson 和正态均值例子达到下界。
7. 正态方差 $S^2$ 未达到下界，却因完备充分性仍是 UMVU。
8. 有限样本有效、UMVU 和渐近有效是不同概念，不能混用。

完整示例为：

- `examples/python/34_efficiency.py`；
- `examples/julia/34_efficiency.jl`；
- `examples/lean/Probability/Ch34Efficiency.lean`。

---

上一章：[33 矩估计与广义矩方法](33-gmm.md) · 下一章：[35 一致性与渐近方差](35-asymptotic-estimation.md)
