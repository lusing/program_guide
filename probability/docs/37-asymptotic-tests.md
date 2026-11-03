# 第 37 章 Wald、LM、LR 检验与置信区间

## 37.1 同一个约束，可以问三个不同问题

第 36 章在两个简单假设之间寻找有限样本最优检验。

应用统计更常见的是复合约束：

$$
H_0:g(\theta_0)=0,
\qquad
H_A:g(\theta_0)\ne0,
$$

其中 $\theta\in\mathbb R^p$，$g:\mathbb R^p\to\mathbb R^q$。

这时通常不存在对所有备择都有限样本最优的统一规则。

渐近理论提供三种经典构造：

- **Wald 检验**：无约束估计离约束有多远；
- **LM/score 检验**：在受约束估计处，似然还想往哪个方向上升；
- **LR 检验**：加上约束后，最大对数似然下降了多少。

三者看的是同一个约束，却分别测量位移、斜率和高度差。

在正确设定的正则模型中，它们在原假设下渐近等价，并有相同的卡方极限。

在有限样本、强非线性、边界或模型误设下，它们可能明显不同。

## 37.2 正则设定与两个估计量

设单观测对数似然为 $\ell(X_i;\theta)=\log f(X_i;\theta)$。

本章采用平均对数似然

$$
\bar\ell_n(\theta)=\frac1n\sum_{i=1}^n\ell(X_i;\theta).
$$

无约束 MLE 为

$$
\hat\theta=\arg\max_{\theta\in\Theta}\bar\ell_n(\theta).
$$

受约束 MLE 为

$$
\tilde\theta
=\arg\max_{\theta\in\Theta,\,g(\theta)=0}\bar\ell_n(\theta).
$$

记约束的 Jacobian 为

$$
G(\theta)=\frac{\partial g(\theta)}{\partial\theta'},
$$

它是 $q\times p$ 矩阵。

常规推导要求：

1. 真参数是参数空间内点并满足约束；
2. 似然有足够阶导数，期望求导可以交换；
3. 单观测信息矩阵 $I(\theta_0)$ 正定；
4. $G(\theta_0)$ 满行秩 $q$；
5. 无约束和受约束估计都一致，并有适当的渐近展开；
6. 中间矩阵和余项可以按第 35 章的方式控制。

这些条件不是装饰。

卡方自由度和三种统计量的渐近等价都依赖它们。

## 37.3 Wald：无约束估计离约束有多远

第 35 章给出

$$
\sqrt n(\hat\theta-\theta_0)\xrightarrow{d}N(0,V).
$$

在 $H_0$ 下，$g(\theta_0)=0$。

由 Delta 方法，

$$
\sqrt n\,g(\hat\theta)
\xrightarrow{d}
N\left(0,G(\theta_0)VG(\theta_0)'\right).
$$

因此定义 Wald 统计量

$$
\boxed{
W=n\,g(\hat\theta)'
\left[\widehat G\widehat V\widehat G'\right]^{-1}
g(\hat\theta),
}
$$

其中 $\widehat G,\widehat V$ 是一致估计。

若 $Z\xrightarrow{d}N(0,\Sigma)$ 且 $\Sigma$ 正定，则

$$
Z'\Sigma^{-1}Z\xrightarrow{d}\chi^2_q.
$$

所以在原假设下，

$$
\boxed{W\xrightarrow{d}\chi^2_q.}
$$

自由度等于独立约束的个数 $q$，不是参数总维数 $p$。

Wald 的优点是只需要无约束估计及其方差。

缺点是强非线性时，结果可能依赖参数化；有限样本中还可能出现方差估计很不稳定的问题。

## 37.4 LM：受约束点的得分为什么还应接近零

在无约束最大值点，内点一阶条件为

$$
\nabla\bar\ell_n(\hat\theta)=0.
$$

受约束最大化引入 Lagrange 函数

$$
\mathcal L(\theta,\lambda)
=\bar\ell_n(\theta)+\lambda'g(\theta).
$$

一阶条件为

$$
\nabla\bar\ell_n(\tilde\theta)+G(\tilde\theta)'\tilde\lambda=0,
\qquad
g(\tilde\theta)=0.
$$

若约束与数据相容，受约束估计附近的平均得分应很小，乘子也接近零。

若得分在约束允许的方向之外仍然很大，就说明放松约束能显著提高似然。

这就是 LM（Lagrange multiplier）或 score 检验的几何含义。

对完全约束 $\theta=\theta_0$，单观测信息矩阵为 $I(\theta_0)$，常用 score 统计量为

$$
\boxed{
LM=n\,\bar s_n(\theta_0)'I(\theta_0)^{-1}\bar s_n(\theta_0),
}
$$

其中

$$
\bar s_n(\theta)=\nabla\bar\ell_n(\theta).
$$

在一般的 $q$ 个约束下，可用乘子形式

$$
LM=n\tilde\lambda'
\left[\tilde G\tilde I^{-1}\tilde G'\right]
\tilde\lambda.
$$

实际软件也可能使用观测信息、外积信息或稳健协方差。

这些版本的有限样本数值不必相同，必须先确认所用公式。

LM 的突出优点是只需要受约束模型。

当无约束模型难以估计，而原假设模型很简单时，它尤其方便。

## 37.5 LR：约束造成的最大似然损失

定义广义似然比统计量

$$
\boxed{
LR=2n\left[\bar\ell_n(\hat\theta)-\bar\ell_n(\tilde\theta)\right].
}
$$

因为无约束可行集包含受约束可行集，

$$
\bar\ell_n(\hat\theta)\ge\bar\ell_n(\tilde\theta),
$$

所以 $LR\ge0$。

约束造成的对数似然下降越大，数据越不支持该约束。

在正则条件下，Wilks 定理给出

$$
\boxed{LR\xrightarrow{d}\chi^2_q.}
$$

证明骨架是在无约束 MLE 附近作二阶展开。

由于无约束得分为零，

$$
\bar\ell_n(\tilde\theta)-\bar\ell_n(\hat\theta)
\approx
\frac12(\tilde\theta-\hat\theta)'
H_n(\hat\theta)
(\tilde\theta-\hat\theta),
$$

其中 $H_n$ 是 Hessian，且 $H_n\to-I$。

所以

$$
LR\approx
n(\hat\theta-\tilde\theta)'I(\theta_0)
(\hat\theta-\tilde\theta).
$$

再用受约束与无约束估计的一阶展开，可把右侧化为一个 $q$ 维标准正态向量的平方长度。

LR 只需要两个最大对数似然值，并且对标量光滑重参数化保持自然的不变性。

代价是通常要分别拟合受约束和无约束模型。

## 37.6 三者为什么渐近等价

在原假设下，$\hat\theta$ 和 $\tilde\theta$ 都以 $1/\sqrt n$ 的速度靠近 $\theta_0$。

约束函数局部近似为线性：

$$
g(\hat\theta)
\approx G(\theta_0)(\hat\theta-\theta_0).
$$

Hessian 局部近似为固定信息矩阵。

于是：

- Wald 用无约束位移形成二次型；
- LM 的得分通过 $H^{-1}$ 转成同一类位移；
- LR 的高度差通过二阶 Taylor 展开转成同一类二次型。

三者的差在原假设标准化后为 $o_p(1)$，所以共享 $\chi^2_q$ 极限。

这个结论不意味着它们在每个样本中接近。

它也不意味着在固定备择下数值接近：固定备择下三者通常都随 $n$ 发散。

所谓渐近等价是原假设或适当局部备择下的标准化陈述。

## 37.7 Bernoulli 例：完整推导三种统计量

设 $X_1,\ldots,X_n$ iid 服从 Bernoulli$(p)$，检验

$$
H_0:p=p_0,
\qquad
H_A:p\ne p_0.
$$

令 $K=\sum_iX_i$，$\hat p=K/n$。

平均对数似然为

$$
\bar\ell_n(p)
=\hat p\log p+(1-\hat p)\log(1-p).
$$

无约束 MLE 是 $\hat p$，受约束 MLE 是 $p_0$。

### Wald

单个 Bernoulli 观测的信息为

$$
I(p)=\frac1{p(1-p)}.
$$

均值 $\hat p$ 的 $\sqrt n$ 渐近方差是 $p(1-p)$。

在 $\hat p$ 处估计方差，得到

$$
\boxed{
W=\frac{n(\hat p-p_0)^2}{\hat p(1-\hat p)}.
}
$$

### LM/score

平均得分为

$$
\bar s_n(p)=\frac{\hat p}{p}-\frac{1-\hat p}{1-p}
=\frac{\hat p-p}{p(1-p)}.
$$

在 $p_0$ 处使用期望信息 $I(p_0)$，得到

$$
\boxed{
LM=\frac{n(\hat p-p_0)^2}{p_0(1-p_0)}.
}
$$

它与 Wald 的唯一差别是分母使用原假设方差还是无约束估计方差。

若使用观测信息或其他信息估计，还可能出现其他有限样本形式。

### LR

直接代入两个最大平均对数似然：

$$
\boxed{
LR=2n\left[
\hat p\log\frac{\hat p}{p_0}
+(1-\hat p)\log\frac{1-\hat p}{1-p_0}
\right].
}
$$

方括号是 Bernoulli$(\hat p)$ 相对 Bernoulli$(p_0)$ 的 KL 散度。

因此 LR 也在衡量两个分布之间的信息距离。

当 $\hat p=0$ 或 1 时，按连续延拓 $0\log0=0$ 处理 LR；Wald 的估计方差则会退化为零，需要另外处理边界。

## 37.8 同一数据的精确数值对照

取

$$
n=20,\qquad K=12,\qquad p_0=1/2,
\qquad \hat p=3/5.
$$

Wald 统计量为

$$
W=\frac{20(3/5-1/2)^2}{(3/5)(2/5)}
=\boxed{\frac56}.
$$

LM 统计量为

$$
LM=\frac{20(1/10)^2}{1/4}
=\boxed{\frac45}.
$$

LR 为

$$
LR=2\left[12\log\frac65+8\log\frac45\right]
\approx\boxed{0.8054205420}.
$$

三者不同，但都很小。

在渐近 $\chi^2_1$ 参考下：

| 统计量 | 数值 | 渐近右尾 p 值 |
|---|---:|---:|
| Wald | 0.8333333333 | 0.3613104285 |
| LM | 0.8000000000 | 0.3710933695 |
| LR | 0.8054205420 | 0.3694776420 |

5% 临界值为 3.8414588207，三者都不拒绝。

若改为 $K=16$，则 $\hat p=4/5$，并且

$$
W=\frac{45}{4}=11.25,
\qquad LM=\frac{36}{5}=7.2,
$$

$$
LR\approx7.7097902809.
$$

此时三者都拒绝，但数值差异已经很明显。

有限样本中不能根据“三者渐近等价”就期待它们给出相同统计量或 p 值。

## 37.9 Python：精确代数与连续尾概率分开处理

文件 `examples/python/37_asymptotic_tests.py` 把 Wald 和 LM 保留为分数：

```python
def bernoulli_wald(n, k, p0):
    phat = F(k, n)
    return n * (phat - p0) ** 2 / (phat * (1 - phat))

def bernoulli_score(n, k, p0):
    phat = F(k, n)
    return n * (phat - p0) ** 2 / (p0 * (1 - p0))
```

由于 `phat` 和 `p0` 都是 `Fraction`，返回值精确为 $5/6$ 和 $4/5$。

LR 含对数，使用浮点：

```python
def bernoulli_lr(n, k, p0):
    phat = k / n
    return 2 * (k * log(phat / p0) +
                (n - k) * log((1 - phat) / (1 - p0)))
```

程序不把对数结果伪装成精确分数，而是验证它等于显式公式，并用 `chi2.sf` 计算右尾。

对 $K=16$ 还断言：

```python
assert w16 == F(45, 4) and s16 == F(36, 5)
assert w16 > lr16 > s16 > critical
```

这个大小顺序是该固定数据的结果，不是对任意 Bernoulli 样本都成立的通用排序定理。

## 37.10 Julia：有理数统计量与正态平方尾

`examples/julia/37_asymptotic_tests.jl` 独立复算：

```julia
phat = k // n
wald = n * (phat - p0)^2 / (phat * (1 - phat))
score = n * (phat - p0)^2 / (p0 * (1 - p0))
@assert wald == 5 // 6
@assert score == 4 // 5
```

$\chi^2_1$ 是标准正态的平方，所以一自由度右尾可由正态尾计算：

```julia
chi2_1_sf(x) = 2 * (1 - Phi(sqrt(x)))
p_wald = chi2_1_sf(Float64(wald))
p_score = chi2_1_sf(Float64(score))
p_lr = chi2_1_sf(lr)
```

这里 `Phi` 仍是第 36 章说明的 Simpson 数值积分实现。

三种 p 值与 Python/SciPy 通道一致到数值积分精度。

这说明对一自由度卡方，直接使用正态平方恒等式比再引入一个特殊函数依赖更透明。

## 37.11 Lean：Wald 与 LM 的方差比值关系

`examples/lean/Probability/Ch37AsymptoticTests.lean` 定义：

```lean
def scalarQuadratic (g v : ℚ) : ℚ := g ^ 2 / v

def bernoulliWald (n phat p0 : ℚ) : ℚ :=
  scalarQuadratic (phat - p0) (phat * (1 - phat) / n)

def bernoulliScore (n phat p0 : ℚ) : ℚ :=
  scalarQuadratic (phat - p0) (p0 * (1 - p0) / n)
```

定义把共同的“约束偏差平方除以方差”提取出来，避免两式抄写时发生口径错位。

当 $p_0=1/2$ 时，Lean 证明：

$$
LM=
\frac{\hat p(1-\hat p)}{p_0(1-p_0)}W.
$$

对应形式化为：

```lean
theorem bernoulli_wald_score_relation (n phat : ℚ)
    (hn : n ≠ 0) (hp : phat ≠ 0) (hp1 : 1 - phat ≠ 0) :
    bernoulliScore n phat (1 / 2) =
      (phat * (1 - phat) / ((1 / 2 : ℚ) * (1 - 1 / 2))) *
        bernoulliWald n phat (1 / 2) := by
  simp only [bernoulliScore, bernoulliWald, scalarQuadratic]
  field_simp
```

非零假设保证分母有意义。

`field_simp` 已清理分式并完成这一有理恒等式。

固定数据 $W=5/6$、$LM=4/5$ 也由 `norm_num` 判决。

这些证明核对统计量的代数关系，不自动证明卡方极限；极限来自前面的 Delta 方法和 Taylor 推导。

## 37.12 固定备择、局部备择与渐近功效

若真参数固定满足 $g(\theta_*)\ne0$，在适当条件下

$$
g(\hat\theta)\xrightarrow{p}g(\theta_*).
$$

于是 Wald 统计量通常满足

$$
\frac Wn\xrightarrow{p}
g(\theta_*)'[G V G']^{-1}g(\theta_*)>0.
$$

所以 $W\to\infty$，固定临界值下的拒绝概率趋于一。

LR 和 LM 在相应条件下也具有一致性。

但“功效趋于一”没有描述大偏差附近的行为。

为了研究靠近原假设的备择，取局部序列

$$
\theta_n=\theta_0+\frac{h}{\sqrt n}.
$$

此时约束偏差是 $O(1/\sqrt n)$，标准化统计量不会简单退化为原假设下的中心卡方。

在正则局部渐近正态模型中，极限通常是非中心卡方。

例如标量约束且 $V$ 是 $\sqrt n$ 误差的渐近方差时，

$$
W\Rightarrow\chi^2_1(\lambda),
\qquad
\lambda=h^2/V.
$$

第 36 章的正态功效曲线是这一思想的精确有限样本版本：功效随非中心位移增加，而不是只由 p 值决定。

## 37.13 检验与置信集对偶：一个 iff

对每个候选参数值 $\theta_0$，构造检验

$$
H_0:\theta=\theta_0.
$$

设水平为 $\alpha$ 的不拒绝域由统计量 $T(X;\theta_0)\le c_\alpha(\theta_0)$ 给出。

定义置信集

$$
\boxed{
C_{1-\alpha}(X)
=\{\theta_0:T(X;\theta_0)\le c_\alpha(\theta_0)\}.
}
$$

则由定义立即有

$$
\boxed{
\theta_0\in C_{1-\alpha}(X)
\iff
\text{在水平 }\alpha\text{ 下不拒绝 }H_0:\theta=\theta_0.
}
$$

这不是数值近似，而是同一个不等式的两种读法。

若每个 $\theta_0$ 的检验都精确校准，则

$$
P_{\theta_0}\{\theta_0\in C_{1-\alpha}(X)\}
=1-P_{\theta_0}(\text{拒绝 }\theta_0)
=1-\alpha.
$$

若检验只有渐近水平，则得到的是渐近覆盖率。

若候选检验还估计了 nuisance 参数，置信集构造也必须使用同一套 profile、条件或边际处理。

## 37.14 正态均值：反演双侧 z 检验

设正态样本的 $\sigma$ 已知。

对候选值 $\mu_0$，双侧检验不拒绝当且仅当

$$
\left|\frac{\bar X-\mu_0}{\sigma/\sqrt n}\right|
\le z_{\alpha/2}.
$$

整理关于 $\mu_0$ 的不等式：

$$
\bar X-z_{\alpha/2}\frac\sigma{\sqrt n}
\le\mu_0\le
\bar X+z_{\alpha/2}\frac\sigma{\sqrt n}.
$$

因此

$$
\boxed{
\bar X\pm z_{\alpha/2}\frac\sigma{\sqrt n}
}
$$

就是所有不被双侧 z 检验拒绝的候选均值。

继续第 36 章的数值：$n=16,\sigma=4,\bar x=11.5$，标准误为 1，所以 95% 区间为

$$
(9.5400360155,\ 13.4599639845).
$$

$\mu_0=10$ 和 12 都在区间内，因此不被拒绝；$\mu_0=14$ 在区间外，因此被双侧 5% 检验拒绝。

“区间包含”与“不拒绝”不是两个相似结论，而是完全相同的判定。

## 37.15 未知方差：反演 t 检验

若正态样本方差未知，候选 $\mu_0$ 的双侧 t 检验不拒绝当且仅当

$$
|\bar X-\mu_0|
\le t_{n-1,1-\alpha/2}\frac{S}{\sqrt n}.
$$

反演得到

$$
\boxed{
\bar X\pm t_{n-1,1-\alpha/2}\frac{S}{\sqrt n}.
}
$$

出餐时间例中，$n=20,\bar x=48,s=8$，且

$$
t_{19,0.975}=2.0930240544.
$$

区间半宽为

$$
2.0930240544\frac8{\sqrt{20}}\approx3.74411525.
$$

所以 95% 区间为

$$
(44.25588475,\ 51.74411525).
$$

它包含 45，与双侧 5% t 检验不拒绝 $H_0:\mu=45$ 一致。

第 36 章的 0.054954 是右侧 p 值；这里区间对应双侧检验，不能混用两侧临界值作数值比较。

## 37.16 Lean：把对偶写成逻辑等价

Lean 文件用绝对值距离表达同一个判定：

```lean
def insideAbsoluteSet (estimate center halfWidth : ℚ) : Prop :=
  |estimate - center| ≤ halfWidth

def rejectAbsolute (estimate center halfWidth : ℚ) : Prop :=
  halfWidth < |estimate - center|

theorem confidence_test_duality (estimate center halfWidth : ℚ) :
    insideAbsoluteSet estimate center halfWidth ↔
      ¬ rejectAbsolute estimate center halfWidth := by
  simp only [insideAbsoluteSet, rejectAbsolute, not_lt]
```

`insideAbsoluteSet` 表示候选参数进入置信集。

`rejectAbsolute` 表示检验拒绝。

证明只需使用 $a\le b\iff\neg(b<a)$，这正显示对偶不是额外的统计近似。

具体数值 $\bar x=23/2$ 与中心 10、14 的包含和拒绝例也由 `norm_num` 检查。

## 37.17 Python 与 Julia：直接检查区间成员关系

Python 把区间和检验写成同一个函数接口：

```python
def normal_mean_interval(xbar, sigma, n, level=0.95):
    half_width = float(norm.ppf((1 + level) / 2)) * sigma / sqrt(n)
    return xbar - half_width, xbar + half_width

def not_rejected(xbar, sigma, n, mu0, level=0.95):
    lower, upper = normal_mean_interval(xbar, sigma, n, level)
    return lower <= mu0 <= upper
```

程序验证 10、12 不拒绝，而 14 拒绝。

它没有另写一套方向可能不一致的 p 值规则，因而区间与检验共享同一个实现。

Julia 对应代码为：

```julia
normal_mean_interval(xbar, sigma, n) =
    (xbar - z95 * sigma / sqrt(n), xbar + z95 * sigma / sqrt(n))

not_rejected(xbar, sigma, n, mu0) =
    normal_mean_interval(xbar, sigma, n)[1] <= mu0 <=
    normal_mean_interval(xbar, sigma, n)[2]
```

两种实现得到完全相同的区间端点，因为都使用固定的 0.975 正态分位数。

## 37.18 覆盖率模拟：检验反演之后的频率审计

置信区间的 95% 不是“本次区间有 95% 概率包含固定真值”的频率后验解释。

在频率学派构造中，随机的是区间；重复抽样时，构造程序约有 95% 的次数覆盖固定真值。

Python 固定种子 37，生成 20,000 组正态样本：

```python
samples = 10 + 4 * rng.standard_normal((reps, n))
means = samples.mean(axis=1)
standard_deviations = samples.std(axis=1, ddof=1)
z_coverage = np.mean(np.abs(means - 10) <= z95 * 4 / sqrt(n))
t_coverage = np.mean(
    np.abs(means - 10) <= tcrit15 * standard_deviations / sqrt(n))
```

其中 $n=16$，z 区间使用已知 $\sigma=4$，t 区间使用每次样本自己的标准差。

结果为：

- z 区间经验覆盖率 0.95135；
- t 区间经验覆盖率 0.94990。

Julia 把循环封装为 `coverage_audit`，避免顶层循环变量作用域歧义：

```julia
z_covered += abs(xbar - 10) <= z95 * 4 / sqrt(n)
t_covered += abs(xbar - 10) <=
    tcrit15 * std(sample, corrected=true) / sqrt(n)
```

Julia 得到 0.94790 和 0.95015。

不同随机数实现带来正常的 Monte Carlo 波动。

精确覆盖率来自正态与 t 抽样分布，模拟只是对实现和有限样本频率的独立审计。

## 37.19 多重比较与 Bonferroni 校正

设同时检验 $m$ 个原假设，第 $j$ 个假拒绝事件为 $A_j$。

若每个检验在相应原假设下的水平为 $\alpha/m$，Boole 不等式给出

$$
P\left(\bigcup_{j=1}^m A_j\right)
\le\sum_{j=1}^mP(A_j)
\le m\frac\alpha m=\alpha.
$$

这就是 Bonferroni 校正。

它不要求各检验独立，也不要求 p 值之间具有某种相关结构。

若 20 个独立真原假设各用 0.05 水平，至少一个假拒绝的概率为

$$
1-0.95^{20}=0.6415140776.
$$

若改用 Bonferroni，每个检验使用

$$
\alpha_j=0.05/20=0.0025.
$$

Python 和 Julia 都对这两个数值作了断言。

Bonferroni 简单且保守，但检验很多或高度相关时可能损失功效。

更精细的逐步校正或 FDR 控制属于另外的错误率目标，不能把 FDR 与 familywise error rate 混为一谈。

置信区间同样存在多重性：20 个各自 95% 的区间，不等于它们同时覆盖的概率仍为 95%。

## 37.20 模型误设时，三种检验不再天然同极限

第 35 章已经说明，误设模型下 MLE 可能收敛到伪真参数，而得分方差与 Hessian 不再满足信息等式。

这会影响三大检验：

- Wald 可以使用 sandwich 方差构造稳健版本；
- score/LM 也需要用真实得分协方差进行稳健校准；
- 朴素 LR 的“二倍对数似然差”不自动具有普通 $\chi^2_q$ 极限。

所以不能只把 Wald 的标准误换成稳健形式，就默认 LR 的临界值也得到修复。

若检验的是伪真参数的约束，还要先说明这个约束在科学问题中意味着什么。

稳健方差可以修正不确定度计算，不能自动把错误模型中的参数变成目标结构参数。

## 37.21 边界、弱识别与数据驱动选择

### 参数在边界

若原假设把参数放在边界，普通内点 Taylor 展开失效。

LR 可能具有卡方混合等极限，而不是直接服从一个普通卡方。

### 约束秩下降

若 $G(\theta_0)$ 不满秩，名义约束数 $q$ 不等于有效独立约束数，二次型中的逆矩阵也可能不存在。

### 弱识别

信息矩阵接近奇异时，估计量的正态近似可能很差，三种统计量的有限样本分歧会加剧。

### 数据驱动选择

先看数据选择模型、变量或检验方向，再按固定流程计算 p 值和区间，会破坏原来的校准。

选择后的推断需要把选择过程本身纳入分析。

### 数值优化失败

无约束或受约束优化没有真正收敛时，三个统计量可能比较的是错误极点。

软件输出一个数值不等于 Wilks 定理的条件已经满足。

## 37.22 三种检验如何选择

| 情形 | 自然选择 | 原因 |
|---|---|---|
| 已拟合无约束模型 | Wald | 只需估计值和协方差 |
| 无约束模型难拟合 | LM/score | 只需原假设下的受约束拟合 |
| 两个模型都可稳定拟合 | LR | 直接比较最大似然，重参数化自然 |
| 非线性约束且强非线性 | 谨慎比较 | 有限样本差异可能很大 |
| 模型可能误设 | 稳健 Wald/score | 朴素 LR 卡方校准不自动成立 |
| 参数在边界或弱识别 | 专门理论 | 常规卡方近似可能失效 |

实际研究中可以同时报告三者，但不能挑选最显著的一个而隐去检验选择过程。

更重要的是报告效应估计、置信区间、模型假设和研究设计，而不是只比较三个 p 值谁更小。

## 37.23 常见误区

### 误区一：三大检验在每个样本中相等

它们只在正则原假设下渐近等价；本章固定数据已经给出三个不同数值。

### 误区二：自由度总是参数个数

自由度是有效独立约束数； nuisance 参数通过受约束估计处理。

### 误区三：Wald、LM、LR 都只需要无约束模型

Wald 主要用无约束拟合，LM 主要用受约束拟合，LR 通常两者都需要。

### 误区四：95% 区间包含的参数就是真参数

区间包含的是当前数据和规则下不被拒绝的候选值。

### 误区五：渐近区间天然具有精确 95% 覆盖率

覆盖率依赖分布、样本量、方差估计和模型设定。

### 误区六：做很多检验仍可按单次错误率解释

多重检验需要另外控制族系错误率或其他明确目标。

### 误区七：稳健标准误让朴素 LR 也稳健

LR 的参考分布需要单独校准，不能沿用信息等式下的普通卡方而不加论证。

## 37.24 本章要点

1. Wald 测无约束位移，LM 测受约束点得分，LR 测最大似然高度差。
2. 在正确设定的正则内点模型中，三者于原假设下都渐近服从 $\chi^2_q$，$q$ 是有效约束数。
3. Bernoulli 例给出 $W=n(\hat p-p_0)^2/[\hat p(1-\hat p)]$、$LM=n(\hat p-p_0)^2/[p_0(1-p_0)]$ 和二倍 KL 形式的 LR。
4. 固定备择下检验通常一致；局部备择下常出现非中心卡方极限。
5. 置信集由不拒绝域反演，参数入集当且仅当相应检验不拒绝。
6. 正态已知方差反演 z 检验，未知方差反演 t 检验，二者不要混用临界值。
7. 多重检验用 Boole 不等式即可导出 Bonferroni 校正，无需独立假设。
8. 模型误设、边界、弱识别和选择后推断都会破坏朴素卡方与覆盖率解释。

---

上一章：[36 假设检验与 Neyman–Pearson 理论](36-hypothesis-testing.md) · 下一章：[38 经典线性回归与普通最小二乘](38-ols.md)
