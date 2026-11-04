# 第 32 章 极大似然估计：似然、得分与 Fisher 信息

## 32.1 基本思想

设观察到数据 $x=(x_1,\ldots,x_n)$ 。

参数模型给出每个候选参数 $\theta$ 下的联合概率质量或联合密度。

极大似然估计选择使这份已观察数据最“可能”的参数：

$$\hat\theta\in\arg\max_{\theta\in\Theta}L(\theta\mid x).$$

这里 $L(\theta\mid x)$ 是似然函数。

对离散模型，它通常就是观察到 $x$ 的概率；对连续模型，它是联合密度在 $x$ 处的值。

连续点的概率为零，所以不能把连续似然直接解释为“这个点的概率”。

密度仍可用于比较参数：同一数据、同一参考测度下，密度越大，模型在该邻域赋予的相对概率越集中。

## 32.2 概率函数与似然函数：同一公式，两种视角

对固定参数 $\theta$ ，联合 PMF 或 PDF

$$f_X(x;\theta)$$

被看成数据 $x$ 的函数，用来描述抽样分布。

数据观察以后，把它固定为 $x$ ，改把 $\theta$ 看成变量：

$$\boxed{ L(\theta\mid x)=f_X(x;\theta). }$$

公式相同，角色不同。

概率函数对 $x$ 求和或积分等于 $1$ ；似然函数对 $\theta$ 通常既不归一，也不需要归一。

因此

$$\int_\Theta L(\theta\mid x)\,d\theta=1$$

一般不成立。

“给定数据后参数的后验密度”是另一个概念，需要额外的先验与归一化，不能直接把似然当作后验。

## 32.3 独立样本与对数似然

若 $X_1,\ldots,X_n$ 独立，且第 $i$ 个观测的密度为 $f_i(x_i;\theta)$ ，则

$$L(\theta\mid x)=\prod_{i=1}^n f_i(x_i;\theta).$$

iid 时进一步写成

$$L(\theta\mid x)=\prod_{i=1}^n f(x_i;\theta).$$

当似然为正时，定义对数似然

$$\ell(\theta\mid x)=\log L(\theta\mid x) =\sum_{i=1}^n\log f(x_i;\theta).$$

因为对数严格递增，最大化 $L$ 与最大化 $\ell$ 给出相同极大点。

对数把乘积变成和，既方便求导，也减小大量小数连乘造成的下溢。

在概率为零或密度为零的点，对数似然可记为 $-\infty$ ，但实现时要处理零次幂和边界，不能机械计算 $0\log0$ 的浮点表达式。

## 32.4 MLE 的定义、存在与唯一

极大似然估计量定义为

$$\hat\theta(X)\in \arg\max_{\theta\in\Theta}L(\theta\mid X).$$

代入观察数据后得到估计值。

这里有两个不同问题：

- **存在**：参数空间上是否至少有一个点达到最大值；
- **唯一**：达到最大值的点是否只有一个。

若 $\Theta$ 是紧集，且 $L(\theta\mid x)$ 关于 $\theta$ 连续，Weierstrass 定理保证最大值存在。

但存在不推出唯一，也不推出容易计算。

若参数空间是开集，或者似然无界，MLE 可能不存在。

若似然有多个相同高度的峰值，MLE 可以不唯一。

所以“写出一阶条件”永远排在“明确参数空间和全局最大值”之后。

## 32.5 Bernoulli 似然的完整推导

设

$$X_1,\ldots,X_n\overset{\mathrm{iid}}{\sim} \operatorname{Bernoulli}(p), \qquad 0<p<1.$$

单观测 PMF 为

$$f(x;p)=p^x(1-p)^{1-x}, \qquad x\in\{0,1\}.$$

令成功数

$$k=\sum_{i=1}^n x_i.$$

联合概率为

$$L(p\mid x)=p^k(1-p)^{n-k}.$$

对数似然为

$$\ell(p)=k\log p+(n-k)\log(1-p).$$

这里组合数 $\binom nk$ 不出现，因为数据是**有序观测向量**；若只观察到总成功数 $K\sim\operatorname{Bin}(n,p)$ ，似然才会多出与 $p$ 无关的 $\binom nk$ 。

两种数据的似然只差一个与参数无关的因子，所以给出相同 MLE。

## 32.6 Bernoulli 得分与闭式 MLE

对内点 $0<p<1$ ，求导得

$$\ell'(p)=\frac kp-\frac{n-k}{1-p}.$$

通分：

$$\boxed{ \ell'(p)=\frac{k-np}{p(1-p)}. }$$

若 $0<k<n$ ，置零得到唯一候选点

$$\hat p=\frac kn=\bar x.$$

二阶导数为

$$\ell''(p)=-\frac k{p^2}-\frac{n-k}{(1-p)^2}<0.$$

因此 $\ell$ 在 $(0,1)$ 上严格凹，$\hat p=k/n$ 是唯一全局最大点。

Lean 把通分恒等式写成

```lean
theorem bernoulli_score_numerator (k n p : ℚ) (hp : p ≠ 0) (hp1 : 1 - p ≠ 0) :
    bernoulliScore k n p = (k - n * p) / (p * (1 - p)) := by
  simp only [bernoulliScore]
  field_simp
  ring
```

这个证明固定了分子 $k-np$ 。

全局凹性和边界处理仍由上面的数学分析给出，不能由一个有理数恒等式自动推出。

## 32.7 全失败或全成功：边界必须单独处理

若 $k=0$ ，则

$$L(p)=(1-p)^n,$$

它在 $p\ge0$ 上递减。

在闭参数空间 $[0,1]$ 上，MLE 是 $\hat p=0$ 。

若 $k=n$ ，则 $L(p)=p^n$ ，MLE 是 $\hat p=1$ 。

这两种情况下，内部一阶条件公式含除以零，不能直接使用。

若参数空间被规定为开区间 $(0,1)$ ，全失败时上确界在 $0$ 处、全成功时上确界在 $1$ 处，但都不在参数空间内，因此 MLE 不存在。

这说明“样本均值总是 MLE”需要补充参数空间约定：在闭区间上边界 MLE 成立，在开区间上最大值可能不达到。

## 32.8 Poisson 似然与 MLE

设

$$X_i\overset{\mathrm{iid}}{\sim}\operatorname{Poisson}(\lambda), \qquad \lambda>0.$$

单观测 PMF 是

$$f(x;\lambda)=e^{-\lambda}\frac{\lambda^x}{x!}, \qquad x=0,1,2,\ldots$$

记 $s=\sum_i x_i$ 。

联合似然为

$$L(\lambda)= e^{-n\lambda}\lambda^s \left(\prod_{i=1}^n x_i!\right)^{-1}.$$

对数似然为

$$\ell(\lambda)=-n\lambda+s\log\lambda -\sum_{i=1}^n\log(x_i!).$$

最后一项与 $\lambda$ 无关，求导时消失：

$$\ell'(\lambda)=\frac{s}{\lambda}-n, \qquad \ell''(\lambda)=-\frac{s}{\lambda^2}.$$

若 $s>0$ ，唯一内点解为

$$\boxed{\hat\lambda=\frac sn=\bar x.}$$

当 $\lambda\to0$ 或 $\lambda\to\infty$ 时，对数似然都趋于 $-\infty$ ，所以该驻点是全局最大点。

若 $s=0$ ，则 $L(\lambda)=e^{-n\lambda}$ 。

在 $[0,\infty)$ 上若允许退化的 Poisson(0)，MLE 为 $0$ ；若坚持 $\lambda>0$ ，上确界在零处但不达到。

## 32.9 正态双参数 MLE

设

$$X_i\overset{\mathrm{iid}}{\sim}N(\mu,v), \qquad v=\sigma^2>0.$$

把 $v$ 本身当作参数，比把 $\sigma$ 当作参数求导更整齐。

联合对数似然为

$$\boxed{ \ell(\mu,v) =-\frac n2\log(2\pi) -\frac n2\log v -\frac1{2v}\sum_{i=1}^n(x_i-\mu)^2. }$$

分别求偏导：

$$\frac{\partial\ell}{\partial\mu} =\frac1v\sum_{i=1}^n(x_i-\mu),$$

$$\frac{\partial\ell}{\partial v} =-\frac n{2v} +\frac1{2v^2}\sum_{i=1}^n(x_i-\mu)^2.$$

第一式给出

$$\hat\mu=\bar x.$$

令

$$q=\sum_{i=1}^n(x_i-\bar x)^2.$$

若 $q>0$ ，第二式给出

$$\boxed{ \hat v=\frac qn =\frac1n\sum_{i=1}^n(x_i-\bar x)^2. }$$

注意分母是 $n$ ，不是无偏样本方差的 $n-1$ 。

所以 MLE 通常有偏差：

$$E_\theta[\hat v]=\frac{n-1}{n}v.$$

上一章已经看到，这个有偏 MLE 在平方误差风险上还可以优于无偏 $S^2$ 。

## 32.10 正态解为什么是全局最大

对任意固定 $v>0$ ，平方和满足

$$\sum_i(x_i-\mu)^2 =q+n(\mu-\bar x)^2\ge q.$$

因此对数似然在 $\mu=\bar x$ 处最大。

代入后得到 profile 对数似然：

$$\ell(\bar x,v) =C-\frac n2\log v-\frac q{2v}.$$

当 $q>0$ 时，它对 $v$ 的唯一驻点为 $v=q/n$ 。

并且当 $v\to0$ 或 $v\to\infty$ 时，它都趋于 $-\infty$ ，故该点是全局最大。

在 $(\hat\mu,\hat v)$ 处 Hessian 为

$$\begin{pmatrix} -n/\hat v&0\\ 0&-n/(2\hat v^2) \end{pmatrix},$$

负定，与上述全局论证一致。

“二阶导数负”常能快速检查局部最大，但本例的两端极限分析进一步排除了其他全局竞争者。

## 32.11 所有观测相同时，普通正态 MLE 不存在

若所有 $x_i$ 都等于同一个数 $c$ ，则 $\bar x=c$ 且 $q=0$ 。

代入后，

$$\ell(c,v)=C-\frac n2\log v.$$

当 $v\downarrow0$ 时，它趋于 $+\infty$ 。

所以在 $v>0$ 的普通正态密度模型中，没有有限最大值，不能简单说“$\hat v=0$ 是正态密度的 MLE”。

退化分布把所有质量放在 $c$ ，但它对 Lebesgue 测度没有普通密度。

这是一个典型的似然无界问题。

类似问题也出现在允许方差任意缩小的混合正态模型中。

数值优化器若返回极小方差，不应被误读为找到了一个良好定义的有限 MLE。

## 32.12 得分函数

对数似然关于参数的梯度称为**得分**：

$$S_n(\theta)= \nabla_\theta\ell_n(\theta\mid X).$$

iid 样本中，

$$S_n(\theta)=\sum_{i=1}^n s(X_i;\theta), \qquad s(x;\theta)=\nabla_\theta\log f(x;\theta).$$

内点且可微的最大值必须满足

$$S_n(\hat\theta)=0.$$

这只是必要条件。

得分零点可以是局部最大、局部最小或鞍点；最大值也可能在边界，或者根本不存在。

在多参数模型中，得分是一个向量，Hessian 是一个矩阵。

把每个分量分别求导只是计算方式，不能忽视参数之间的耦合。

## 32.13 得分在真参数处的零均值

在正确设定且正则的模型中，对

$$\int f(x;\theta)\,dx=1$$

关于 $\theta$ 求导。

若可以交换求导和积分，得到

$$\int \nabla_\theta f(x;\theta)\,dx=0.$$

由于

$$\nabla_\theta\log f =\frac{\nabla_\theta f}{f},$$

所以

$$E_\theta[s(X;\theta)] =\int s(x;\theta)f(x;\theta)\,dx =0.$$

因此

$$\boxed{E_{\theta_0}[s(X;\theta_0)]=0.}$$

下标非常重要：得分在参数 $\theta$ 处构造，期望也在同一个 $P_\theta$ 下计算。

若真实分布是 $P_0$ ，而我们在别的 $\theta$ 处评估得分，一般没有

$$E_0[s(X;\theta)]=0.$$

正则条件包括适当的可微性、可积控制，以及通常要求支撑不随参数作会破坏求导的变化。

## 32.14 Bernoulli 得分的精确核对

单观测得分为

$$s(x;p)=\frac{x}{p}-\frac{1-x}{1-p}.$$

因为 $E_p[X]=p$ ，直接有

$$E_p[s(X;p)] =\frac pp-\frac{1-p}{1-p}=0.$$

Python 在 $p=1/3$ 时保留全部有理数：

```python
def bernoulli_score(x, p):
    return x / p - (1 - x) / (1 - p)

p = Fraction(1, 3)
scores = {0: bernoulli_score(0, p), 1: bernoulli_score(1, p)}
assert (1 - p) * scores[0] + p * scores[1] == 0
```

这里精确枚举的是只有两个点的分布，不是 Monte Carlo。

Poisson 的同一结论也由 $E_\lambda[X]=\lambda$ 得到：

$$E_\lambda\left[\frac X\lambda-1\right]=0.$$

这些恒等式说明总体得分在真参数处平均为零；一个具体样本的得分通常不为零，MLE 正是在样本总得分为零的参数处寻找拟合。

## 32.15 Fisher 信息与信息等式

单观测 Fisher 信息定义为得分方差：

$$I(\theta) =\operatorname{Var}_\theta[s(X;\theta)].$$

由于真参数处得分均值为零，也可写成

$$I(\theta)=E_\theta[s(X;\theta)s(X;\theta)^\top].$$

标量情形就是 $E_\theta[s(X;\theta)^2]$ 。

对 iid 样本，独立性和零均值给出

$$\operatorname{Var}_\theta[S_n(\theta)] =nI(\theta).$$

在更强的二阶正则条件下，还有**信息矩阵等式**

$$\boxed{ I(\theta)=-E_\theta[ \nabla_\theta^2\log f(X;\theta)]. }$$

它把“得分波动”与“对数似然平均曲率”联系起来。

曲率绝对值越大，通常表示参数附近的对数似然越尖，样本携带的局部参数信息越多。

## 32.16 信息等式的证明

从

$$0=\int \nabla_\theta f(x;\theta)\,dx =\int s(x;\theta)f(x;\theta)\,dx$$

再次求导。

标量情形，被积函数的导数为

$$\frac{\partial}{\partial\theta} \left[ \frac{\partial\log f}{\partial\theta}f \right] = \frac{\partial^2\log f}{\partial\theta^2}f + \frac{\partial\log f}{\partial\theta} \frac{\partial f}{\partial\theta}.$$

利用 $\partial_\theta f=(\partial_\theta\log f)f$ ，积分后得到

$$0=E_\theta[\ell''(X;\theta)] +E_\theta[s(X;\theta)^2].$$

移项即 $I(\theta)=-E_\theta[\ell'']$ 。

向量情形逐分量求导，得到矩阵形式

$$E_\theta[SS^\top] =-E_\theta[\nabla^2_\theta\log f].$$

证明中使用两次交换求导与积分。

若这些正则条件失败，信息等式也可能失败。

在模型误设下，即使分别计算得分协方差 $J$ 与期望负 Hessian $H$ ，一般也只得到渐近三明治公式中的两个不同矩阵，不能强行令 $J=H$ 。

## 32.17 三个模型的 Fisher 信息

### Bernoulli

由

$$s(x;p)=\frac{x-p}{p(1-p)}$$

以及 $\operatorname{Var}(X)=p(1-p)$ ，得到

$$\boxed{I(p)=\frac1{p(1-p)}.}$$

样本量为 $n$ 时，总信息为 $n/[p(1-p)]$ 。

Python 同时核对得分方差与期望负曲率：

```python
score_variance = (1 - p) * scores[0] ** 2 + p * scores[1] ** 2
expected_negative_curvature = (
    (1 - p) / (1 - p) ** 2 + p / p ** 2)
assert score_variance == expected_negative_curvature == bernoulli_information(p)
```

三项精确相等，直接体现信息等式。

### Poisson

由 $s(x;\lambda)=x/\lambda-1$ ，得

$$I(\lambda) =\frac{\operatorname{Var}(X)}{\lambda^2} =\frac1\lambda.$$

另一方面，$\ell''=-X/\lambda^2$ ，所以

$$-E_\lambda[\ell'']=1/\lambda.$$

### 正态 $(\mu,v)$

单观测信息矩阵为

$$\boxed{ I(\mu,v)= \begin{pmatrix} 1/v&0\\ 0&1/(2v^2) \end{pmatrix}. }$$

非对角元为零，因为正态奇中心矩为零。

这不意味着有限样本的 $\hat\mu$ 与 $\hat v$ 在所有模型中都无关；它说的是这个正则正态模型中的得分信息结构。

## 32.18 固定数据上的 Newton 优化

闭式解应当优先使用，但数值优化仍需通过一个能独立对账的例子理解。

固定数据为

```python
data = [1, 0, 1, 1, 0, 1, 0, 1, 1, 1]
```

有 $n=10,k=7$ ，所以真 MLE 已知为 $0.7$ 。

Newton 法求得分方程 $\ell'(p)=0$ ，迭代为

$$p_{m+1} =p_m-\frac{\ell'(p_m)}{\ell''(p_m)}.$$

Python 单元完整实现如下；对数似然单独避免空项求对数：

```python
def bernoulli_loglik(p, observations):
    k, n = sum(observations), len(observations)
    value = 0.0
    if k:
        value += k * log(p)
    if n - k:
        value += (n - k) * log(1 - p)
    return value


def bernoulli_newton(observations, start=0.2, tolerance=1e-12):
    p = start
    history = [p]
    for _ in range(30):
        k, n = sum(observations), len(observations)
        score = k / p - (n - k) / (1 - p)
        curvature = -k / p ** 2 - (n - k) / (1 - p) ** 2
        candidate = p - score / curvature
        if not 0 < candidate < 1:
            raise ValueError("unconstrained Newton left (0,1)")
        history.append(candidate)
        if abs(candidate - p) < tolerance:
            return candidate, history
        p = candidate
    raise RuntimeError("Newton did not converge")
```

这段代码求的是根，不自带“每步必提高似然”的保证。

它明确检查候选点是否离开 $(0,1)$ ，并限制最大迭代次数。

## 32.19 逐步检查 Newton 历史

从 $p_0=0.2$ 出发，实际历史约为

$$0.2, 0.37391304, 0.61523376, 0.70762474, 0.70011493, 0.70000003, 0.7.$$

迭代在第三步略超过 $0.7$ ，随后回到精确解附近。

这说明 Newton 迭代不必单调，也不等于沿似然面持续上升。

程序用两条断言对账：

```python
phat, history = bernoulli_newton(data)
assert abs(phat - sum(data) / len(data)) < 1e-12
assert bernoulli_loglik(phat, data) >= bernoulli_loglik(0.2, data)
```

第一条比较数值解和闭式解，第二条至少排除最终结果比起点更差。

第二条并不证明途中每步都提高似然，也不证明一般问题的全局最优。

本例的全局性已经由严格凹性独立证明。

Julia 实现使用相同更新公式，并产生同样的迭代序列；这不是两套随机实验，而是同一确定性算法在两种语言中的复算。

## 32.20 参数变换不变性

设 $g:\Theta\to\Gamma$ 是一一映射，$\tau=g(\theta)$ ，反函数为 $h=g^{-1}$ 。

新参数下的似然定义为

$$L^*(\tau\mid x)=L(h(\tau)\mid x).$$

若 $\hat\theta$ 使 $L$ 达到全局最大，则对任意 $\tau$ ，

$$L^*(g(\hat\theta)) =L(\hat\theta) \ge L(h(\tau)) =L^*(\tau).$$

所以

$$\boxed{\widehat{g(\theta)}=g(\hat\theta).}$$

例如正态模型先得到方差 MLE $\hat v$ ，标准差 MLE 就是

$$\hat\sigma=\sqrt{\hat v}.$$

Bernoulli 模型中，odds 参数为

$$\tau=\frac p{1-p}, \qquad p=\frac\tau{1+\tau}.$$

固定数据给出 $\hat p=0.7$ ，所以 $\hat\tau=0.7/0.3=7/3$ 。

Python 直接核对逆变换：

```python
odds_hat = phat / (1 - phat)
assert abs(odds_hat / (1 + odds_hat) - phat) < 1e-12
```

这里不需要对参数密度乘 Jacobian，因为参数没有被当作随机变量做密度变换；只是同一个最优化问题换了坐标。

## 32.21 非一一变换与 profile 解释

若 $g$ 不是一一映射，仍可用诱导似然定义

$$\widetilde L(\eta) =\sup_{\theta:g(\theta)=\eta}L(\theta).$$

若 $\hat\theta$ 是原问题的全局最大点，则 $g(\hat\theta)$ 最大化这个诱导似然。

原因是每个纤维上的上确界都不超过全局最大值，而 $\eta=g(\hat\theta)$ 的纤维包含 $\hat\theta$ ，能够达到该最大值。

这就是不变性的一般表述。

如果只把原似然写成 $L(h(\eta))$ ，却忽略 $h$ 不是唯一反函数，就可能漏掉其他原参数。

实际使用时要区分“单值代入”与“对同一 $\eta$ 下所有原参数取上确界”。

## 32.22 Lean：不变性的抽象证明

Lean 单元先定义极大点，再证明互逆坐标变换保持最大性：

```lean
def IsMax {α : Type} (L : α → ℚ) (s : Set α) (a : α) : Prop :=
  a ∈ s ∧ ∀ b ∈ s, L b ≤ L a
```

核心定理为

```lean
theorem mle_invariance {Θ Γ : Type} (g : Θ → Γ) (h : Γ → Θ)
    (L : Θ → ℚ) (thetaHat : Θ)
    (hg : ∀ theta, h (g theta) = theta)
    (hmax : IsMax L Set.univ thetaHat) :
    IsMax (fun eta => L (h eta)) Set.univ (g thetaHat) := by
  refine ⟨Set.mem_univ _, ?_⟩
  intro eta _
  have bound := hmax.2 (h eta) (Set.mem_univ _)
  dsimp
  rw [hg thetaHat]
  exact bound
```

证明没有使用 Bernoulli 或正态公式。

它只依赖“原参数点优于所有点”和“逆变换还原原参数”。

因此这是一条可复用的最优化定理，不是对某个数值例的硬编码。

## 32.23 MLE 与充分统计量

若 $T(X)$ 是充分统计量，Neyman–Fisher 因子分解给出

$$L(\theta\mid x) =g_\theta(T(x))h(x),$$

其中 $h(x)$ 不依赖 $\theta$ 。

所以

$$\ell(\theta\mid x) =\log g_\theta(T(x))+\log h(x).$$

最大化时，最后一项可以删去。

因此 MLE 只通过充分统计量依赖数据；若 MLE 存在且可按规则选取，它可以写成充分统计量的函数。

Bernoulli 中的 $k$ 、Poisson 中的 $s$ 、正态中的 $(\sum x_i,\sum x_i^2)$ 都体现这一点。

这也解释了为什么仅观察到成功总数的二项数据与观察到完整 0–1 序列给出相同 MLE：两者关于 $p$ 的似然只相差与参数无关的因子。

## 32.24 支撑依赖参数：一阶条件为何失灵

考虑

$$X_i\overset{\mathrm{iid}}{\sim}U(0,\theta), \qquad \theta>0.$$

联合密度为

$$L(\theta)= \theta^{-n}\mathbf1_{\{\theta\ge x_{(n)}\}},$$

其中 $x_{(n)}=\max_i x_i$ ，并假设所有观测非负。

在 $\theta\ge x_{(n)}$ 上，$\theta^{-n}$ 随 $\theta$ 递减，所以

$$\boxed{\hat\theta=x_{(n)}.}$$

内部导数为

$$\ell'(\theta)=-\frac n\theta<0,$$

永远没有零点。

最大值发生在指示约束开始生效的边界，而不是驻点。

同时，模型支撑 $[0,\theta]$ 随参数变化，前面直接对积分区域求导的正则论证不再适用。

这个例子把“MLE 存在”“得分不为零”“正则得分恒等式失效”放在了一起。

## 32.25 多峰、不可识别与局部最优

一阶条件只列出候选点，不保证全局最优。

例如对称混合模型

$$f(x;\mu)=\tfrac12\varphi(x-\mu) +\tfrac12\varphi(x+\mu)$$

满足 $f(x;\mu)=f(x;-\mu)$ 。

在 $\mu\in\mathbb R$ 上，正负参数不可区分；某些数据的似然还会出现对称双峰。

若限制 $\mu\ge0$ ，可消除这种标签式对称，但仍要检查是否存在多个局部峰。

常用数值策略包括：

- 从多个初值出发，而不是只报告一次收敛；
- 比较所有候选点和边界上的似然；
- 检查 Hessian、参数约束和梯度尺度；
- 绘制一维或 profile 似然，而不是只看优化器状态码。

“算法收敛”通常只表示满足停止规则，不等于“找到全局 MLE”。

## 32.26 数值失败的常见来源

### 下溢与上溢

数千个密度直接连乘可能变成零。

应使用对数似然；混合模型还常用 log-sum-exp 稳定计算。

### 离开参数空间

普通 Newton 可能给出负方差或超出 $[0,1]$ 的概率。

可使用参数变换、约束优化、阻尼或线搜索，但每种方法都需检查边界解。

### 平坦方向与病态曲率

不可识别或弱识别会使 Hessian 奇异或接近奇异。

增加迭代次数不能解决信息不足。

### 局部最优与无界似然

多峰模型需要多起点；方差趋于零造成的无界似然则不是换初值能修复的问题。

### 停止标准误导

步长很小可能只因尺度不合适，梯度很小也可能处于鞍点。

应同时报告对数似然、梯度、参数位置、约束状态和必要的曲率诊断。

## 32.27 固定数据上的正态与 Poisson 对账

Python 用有理数据检查正态双参数解：

```python
xs = [Fraction(x) for x in (1, 2, 4, 5)]
n = len(xs)
mu_hat = sum(xs) / n
q = sum((x - mu_hat) ** 2 for x in xs)
v_hat = q / n
assert (mu_hat, q, v_hat) == (3, 10, Fraction(5, 2))
normal_score_mu = sum(x - mu_hat for x in xs) / v_hat
normal_score_v = -n / (2 * v_hat) + q / (2 * v_hat ** 2)
assert normal_score_mu == normal_score_v == 0
```

这里 $\bar x=3,q=10,\hat v=5/2$ 。

两条得分精确为零，不只是浮点近似。

Julia 对 Poisson 固定数据 $[0,2,1,3,1,2]$ 得到

```julia
poisson_data = [0, 2, 1, 3, 1, 2]
lambda_hat = sum(poisson_data) // length(poisson_data)
@assert lambda_hat == 3 // 2
@assert sum(poisson_data) / lambda_hat - length(poisson_data) == 0
```

这些单元验证的是导数代入和闭式结果，不是模拟估计量的分布。

## 32.28 MLE 的抽样性质应与优化正确性分开

“这份数据上是否最大化似然”和“重复抽样时估计量怎样分布”是两个问题。

对 Bernoulli，$K\sim\operatorname{Bin}(n,p)$ ，而 $\hat p=K/n$ 。

因此可以精确得到

$$E_p[\hat p]=p, \qquad \operatorname{Var}_p(\hat p)=\frac{p(1-p)}n.$$

Python 对 $n=8,p=1/4$ 枚举全部九个成功数：

```python
n, p = 8, Fraction(1, 4)
weights = [(k, Fraction(comb(n, k)) * p ** k * (1 - p) ** (n - k))
           for k in range(n + 1)]
assert sum(weight for _, weight in weights) == 1
mean_phat = sum(Fraction(k, n) * weight for k, weight in weights)
second_moment = sum(Fraction(k, n) ** 2 * weight for k, weight in weights)
assert mean_phat == p
assert second_moment - mean_phat ** 2 == p * (1 - p) / n
```

这是精确有限样本计算，比用随机模拟估计均值更强。

但它仍只覆盖这个特定模型的有限样本矩，不证明 MLE 的一般一致性或渐近正态性。

一般渐近结论需要识别、正则性和一致大数定律等条件，将在第 35 章展开。

## 32.29 似然、KL 散度与模型误设

若真实分布为 $P_0$ ，单个观测的总体平均对数似然为

$$Q(\theta)=E_0[\log f(X;\theta)].$$

当模型包含真实密度 $f_{\theta_0}=f_0$ 时，

$$Q(\theta_0)-Q(\theta) =E_0\left[\log\frac{f_0(X)}{f(X;\theta)}\right] =D_{\mathrm{KL}}(P_0\Vert P_\theta)\ge0.$$

所以真参数最大化总体对数似然。

若模型误设，最大化者是对应最小 KL 投影的伪真参数。

样本 MLE 用样本平均代替这个总体期望。

这一联系解释了 MLE 的方向，却不能省略从样本目标到总体目标所需的收敛条件。

同样，正确设定下的信息等式来自对同一模型密度求导；误设时不应继续使用 $I=-H$ 来替代更一般的协方差—曲率关系。

## 32.30 本章机器单元与使用清单

本章新增：

- `examples/python/32_mle.py`：精确 Bernoulli 信息、Newton、正态与 Poisson 对账、二项抽样矩；
- `examples/julia/32_mle.jl`：独立复算相同固定数据和精确有理数；
- `examples/lean/Probability/Ch32MLE.lean`：得分通分、零均值、信息及抽象不变性证明。

实际做一次 MLE，应按以下顺序检查：

1. 写出联合分布和参数空间；
2. 检查识别与支撑是否依赖参数；
3. 使用对数似然并删去与参数无关的项；
4. 求所有内点候选，同时检查边界和不存在情形；
5. 用凹性、Hessian、profile 或全局比较确认最大值；
6. 数值优化时报告初值、停止规则和多起点诊断；
7. 最后才研究估计量的有限样本或渐近抽样性质。

这套顺序能避免把“一次求导成功”误当成完整统计推断。

## 32.31 本章要点

1. 似然是固定数据后对参数的函数，不是参数上的归一化概率密度。
2. 对数似然与原似然有相同极大点，并且更适合求导和数值计算。
3. Bernoulli 与 Poisson 的内部 MLE 都是样本均值；正态方差 MLE 使用分母 $n$ 。
4. 边界上不必满足零得分，开参数空间或无界似然会使 MLE 不存在。
5. 正则且正确设定时，真参数处得分均值为零，且 $I=-E[\ell'']$ 。
6. Newton 是求根算法，不自动保证全局最优或逐步增似然。
7. 双射重参数化保持 MLE；一般参数函数要用诱导或 profile 似然解释。
8. 优化正确性、有限样本风险、识别和模型误设是四个不同层次的问题。

---

上一章：[31 参数模型、估计量与风险](31-estimation-models.md) · 下一章：[33 矩估计与广义矩方法](33-gmm.md)
