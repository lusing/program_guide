# 第 31 章 参数模型、估计量与风险

## 31.1 从随机样本到统计决策

前面各章研究的是：已知概率分布，怎样计算事件概率、矩和极限。

统计推断把方向反过来：数据已经观察到，产生数据的分布却未知。

我们不能只说“让模型拟合数据”，因为拟合可以有很多目标，也必须付出代价。

本章先把问题说完整：

1. 哪些分布被认为可能，也就是统计模型是什么；
2. 不同参数是否能由分布区分，也就是参数是否可识别；
3. 什么叫一个估计量，什么叫一次估计值；
4. 用什么损失衡量错误；
5. 怎样用偏差、方差和风险比较估计量。

下一章再研究一种具体的构造方法：极大似然。

## 31.2 统计模型是一族分布

一个参数化统计模型写成

\[
\mathcal P=\{P_\theta:\theta\in\Theta\}.
\]

这里 \(\Theta\) 称为**参数空间**，每个 \(\theta\) 对应样本空间上的一个概率分布。

若数据为 \(X=(X_1,\ldots,X_n)\)，则每个 \(P_\theta\) 给出的是整个随机向量的联合分布，而不只是单个分量的边际分布。

在 iid 情形下，

\[
X_1,\ldots,X_n\overset{\mathrm{iid}}{\sim}F_\theta,
\]

所以联合分布由共同边际分布和独立性一起确定。

离散模型常写

\[
P_\theta(X=x)=\prod_{i=1}^n f(x_i;\theta),
\]

连续模型则用联合密度

\[
f_X(x;\theta)=\prod_{i=1}^n f(x_i;\theta).
\]

这里密度必须相对于同一个参考测度理解。

“模型”因此包含两部分：

- 分布族怎样随参数变化；
- 观测之间有什么依赖结构。

只说“数据来自正态分布”没有完整指定模型；独立、同分布、均值和方差是否未知，都是模型的一部分。

## 31.3 总体、真参数与参数空间

在频率派推断中，通常把数据看成来自一个固定但未知的分布 \(P_0\)。

若存在 \(\theta_0\in\Theta\) 使

\[
P_0=P_{\theta_0},
\]

就称模型**正确设定**，并称 \(\theta_0\) 为真参数。

参数空间不是纯数学装饰，而是模型假设的一部分。

例如 Bernoulli 成功概率必须满足 \(0\le p\le1\)；正态方差参数若使用普通密度，必须满足 \(v>0\)。

把 \(p=1\) 排除在外，还是把它纳入参数空间，会直接影响全成功样本的极大似然估计是否存在。

因此，在写出估计量之前，必须先写清楚：

\[
\text{样本是什么，}\quad
\text{参数是什么，}\quad
\text{参数允许取什么值。}
\]

## 31.4 参数、参数函数与估计目标

有时整个 \(\theta\) 都是研究对象，有时只关心它的某个函数

\[
\psi=g(\theta).
\]

例如：

- Bernoulli 模型中关心成功概率 \(p\)；
- 正态模型中可能只关心均值 \(\mu\)，方差是 nuisance parameter；
- Logit 模型中可能关心优势比，而不是线性预测子中的回归系数；
- 持续时长模型中可能关心风险率，而不是完整生存分布。

估计目标不同，合理的损失和风险也可能不同。

估计整个分布的参数，与只估计总体均值，并不是同一个决策问题。

一个模型对完整分布误设，并不自动意味着它对每一个低维参数都毫无价值；但必须重新说明那个参数在模型外代表什么。

## 31.5 识别：分布能否区分参数

**可识别性**是统计推断的逻辑起点。

称参数 \(\theta\) 可识别，如果对任意 \(\theta_1,\theta_2\in\Theta\)，

\[
P_{\theta_1}=P_{\theta_2}
\quad\Longrightarrow\quad
\theta_1=\theta_2.
\]

等价地，不同参数必须产生不同的抽样分布。

若两个参数产生完全相同的分布，那么无论收集多少数据，都不能仅凭数据区分它们。

增加样本量可以减少随机波动，却不能创造模型中本来没有的信息。

更一般地，参数函数 \(\psi=g(\theta)\) 可识别，如果

\[
P_{\theta_1}=P_{\theta_2}
\quad\Longrightarrow\quad
g(\theta_1)=g(\theta_2).
\]

所以整个参数向量不可识别时，它的某些函数仍然可能可识别。

## 31.6 两个不可识别例子

### 只出现参数之和

设

\[
X\mid a,b\sim\operatorname{Bernoulli}
\left(\frac1{1+e^{-(a+b)}}\right).
\]

参数 \((a,b)=(0.2,0.3)\) 与 \((0.5,0)\) 给出同一个分布。

因此 \(a\) 和 \(b\) 单独都不可识别，而 \(a+b\) 可识别。

Python 单元直接比较两个概率：

```python
def linked_bernoulli_probability(a, b):
    return 1 / (1 + np.exp(-(a + b)))

assert linked_bernoulli_probability(0.2, 0.3) == linked_bernoulli_probability(0.5, 0.0)
assert linked_bernoulli_probability(0.2, 0.3) != linked_bernoulli_probability(0.2, 0.4)
```

第一条断言是分布恒等的数值实例，不是一般识别定理的证明。

一般结论来自模型公式：分布只通过 \(a+b\) 依赖参数。

### 混合模型的标签交换

两分量混合模型

\[
\tfrac12N(\mu_1,1)+\tfrac12N(\mu_2,1)
\]

在交换 \((\mu_1,\mu_2)\) 后不变。

如果两个分量没有额外标签含义，那么有序参数对和交换后的参数对代表同一分布。

可以通过规定 \(\mu_1\le\mu_2\) 消除标签自由度，但这不是数据自己提供的约束。

识别问题应先于优化算法处理；优化器在某个点收敛，并不能证明参数唯一。

## 31.7 正确设定、误设与伪真参数

若真实分布不在模型族中，模型就是误设的。

误设不等于所有计算都无意义，但估计结果的解释会改变。

在适当条件下，极大似然往往靠近使 Kullback–Leibler 散度最小的参数：

\[
\theta_*=
\arg\min_{\theta\in\Theta}
D_{\mathrm{KL}}(P_0\Vert P_\theta).
\]

这个 \(\theta_*\) 称为**伪真参数**。

它是模型族中对真实分布的最佳投影，不必使 \(P_{\theta_*}=P_0\)。

例如真实数据具有过度离散的计数分布，而我们只用 Poisson 模型拟合。

样本均值仍可能提供均值参数的有用估计，但 Poisson 模型强制均值等于方差，这个方差结论就可能错误。

因此必须区分：

- **抽样波动**：模型固定时，有限样本使估计量围绕目标波动；
- **模型误差**：即使样本无限增大，模型投影也未必等于真实分布或真实目标。

前者通常随样本增加而减小，后者不能靠增加同一类数据自动消失。

## 31.8 统计量、估计量与估计值

**统计量**是数据的已知函数，不依赖未知参数。

例如

\[
\bar X_n=\frac1n\sum_{i=1}^nX_i,
\qquad
S_n^2=\frac1{n-1}\sum_{i=1}^n(X_i-\bar X_n)^2.
\]

当统计量被用来估计参数 \(\theta\) 时，称为估计量，记作 \(\hat\theta_n(X)\)。

估计量是随机变量，因为它随样本变化。

代入一次已经观察到的数据 \(x\) 后，得到

\[
\hat\theta_n(x),
\]

称为估计值，是一个确定的数或向量。

“估计量的方差”说的是抽样实验中的随机性；“这份数据的估计值”说的是一次实现。

两者不能混用。

## 31.9 损失函数把错误变成决策问题

设动作 \(a\) 是对参数的估计，损失函数为

\[
L(\theta,a)\ge0.
\]

常见例子有：

\[
L(\theta,a)=(a-\theta)^2
\]

的平方误差，

\[
L(\theta,a)=|a-\theta|
\]

的绝对误差，以及分类问题中的零一损失。

平方误差强调大偏差，绝对误差对极端偏差的惩罚较温和，零一损失只关心分类是否准确。

不存在脱离问题的“最佳损失”。

估计桥梁载荷、筛选疾病和预测概率，对不同类型错误的代价并不相同。

统计量只有在目标和损失明确后，才有可比较的优劣。

## 31.10 风险是抽样平均损失

估计量 \(\hat\theta\) 在参数 \(\theta\) 处的风险定义为

\[
R(\theta,\hat\theta)
=E_\theta[L(\theta,\hat\theta(X))].
\]

期望对数据的抽样分布计算，不是把参数当作随机变量。

平方误差下的风险又叫均方误差：

\[
\operatorname{MSE}_\theta(\hat\theta)
=E_\theta[(\hat\theta-\theta)^2].
\]

一个估计量在不同 \(\theta\) 处可以有不同表现。

所以“估计量 A 优于 B”必须说明：

- 在哪些参数值上比较；
- 使用什么损失；
- 是比较逐点风险、最大风险，还是某种平均风险。

## 31.11 偏差与方差

估计量的偏差为

\[
\operatorname{Bias}_\theta(\hat\theta)
=E_\theta[\hat\theta]-\theta.
\]

若偏差恒为零，就称估计量无偏。

方差为

\[
\operatorname{Var}_\theta(\hat\theta)
=E_\theta\left[(\hat\theta-E_\theta\hat\theta)^2\right].
\]

偏差描述抽样分布的中心偏离目标多少，方差描述它围绕自己的中心波动多大。

二者都不是一次估计值的属性，而是估计量在某个参数模型下的抽样属性。

“这次估计偏差为多少”通常无法由一份数据直接知道，因为真参数未知。

## 31.12 偏差—方差分解

记

\[
m=E_\theta[\hat\theta],
\qquad
B=m-\theta.
\]

加入并减去 \(m\)：

\[
\hat\theta-\theta=(\hat\theta-m)+B.
\]

平方并取期望：

\[
\begin{aligned}
\operatorname{MSE}_\theta(\hat\theta)
&=E_\theta[(\hat\theta-m)^2]
+2BE_\theta[\hat\theta-m]+B^2\\
&=\operatorname{Var}_\theta(\hat\theta)
+\operatorname{Bias}_\theta(\hat\theta)^2.
\end{aligned}
\]

交叉项为零，因为 \(E_\theta[\hat\theta-m]=0\)。

所以

\[
\boxed{
\operatorname{MSE}
=\operatorname{Bias}^2+\operatorname{Var}.
}
\]

这条恒等式解释了为什么有偏估计可能优于无偏估计：少量偏差有时能换来更大的方差下降。

对向量估计量，相应分解为

\[
E_\theta\|\hat{\boldsymbol\theta}-\boldsymbol\theta\|^2
=\|\operatorname{Bias}_\theta(\hat{\boldsymbol\theta})\|^2
+\operatorname{tr}\operatorname{Cov}_\theta(\hat{\boldsymbol\theta}).
\]

## 31.13 一个完全算清的有偏估计例

设 \(\bar X_n\) 的均值为 \(\mu\)、方差为 \(\sigma^2/n\)，考虑

\[
\hat\mu=a\bar X_n.
\]

则

\[
\operatorname{Bias}(\hat\mu)=(a-1)\mu,
\qquad
\operatorname{Var}(\hat\mu)=a^2\sigma^2/n.
\]

因此

\[
\operatorname{MSE}(\hat\mu)
=(a-1)^2\mu^2+\frac{a^2\sigma^2}{n}.
\]

Python 用有理数检查 \(\mu=2,\sigma^2=5,n=10,a=3/4\)：

```python
a, mu, sigma2, size = Fraction(3, 4), Fraction(2), Fraction(5), 10
bias = (a - 1) * mu
variance = a ** 2 * sigma2 / size
direct_risk = (a - 1) ** 2 * mu ** 2 + a ** 2 * sigma2 / size
assert bias ** 2 + variance == direct_risk == Fraction(17, 32)
```

无偏的 \(a=1\) 方差项最小系数为 \(1\)，但其他 \(a\) 可能在某些 \(\mu\) 处有更低总风险。

这不是说随意缩小都好；若参数范围或损失改变，结论也会改变。

## 31.14 正态方差：三个估计量的精确风险

设

\[
X_1,\ldots,X_n\overset{\mathrm{iid}}{\sim}N(\mu,\sigma^2),
\]

并令 \(\nu=n-1\)。

第 22 章已经证明

\[
Q:=\frac{\nu S^2}{\sigma^2}\sim\chi^2_\nu,
\qquad
E[Q]=\nu,
\qquad
\operatorname{Var}(Q)=2\nu.
\]

考虑一族估计量

\[
\hat\sigma_c^2=cS^2.
\]

因为 \(S^2=\sigma^2Q/\nu\)，有

\[
E[\hat\sigma_c^2]=c\sigma^2,
\qquad
\operatorname{Bias}(\hat\sigma_c^2)=(c-1)\sigma^2.
\]

并且

\[
\operatorname{Var}(\hat\sigma_c^2)
=\frac{2c^2\sigma^4}{\nu}.
\]

由偏差—方差分解，标准化风险为

\[
\boxed{
\frac{E[(\hat\sigma_c^2-\sigma^2)^2]}{\sigma^4}
=(c-1)^2+\frac{2c^2}{\nu}
=\left(1+\frac2\nu\right)c^2-2c+1.
}
\]

这是 \(c\) 的严格凸二次函数。

配方可得最优系数

\[
\boxed{c_*=\frac{\nu}{\nu+2}=\frac{n-1}{n+1}.}
\]

对应最小标准化风险为

\[
R(c_*)=\frac2{\nu+2}=\frac2{n+1}.
\]

这个“最优”仅指正态模型、平方误差和 \(cS^2\) 这一族，不是对所有可能估计量的无条件宣称。

## 31.15 无偏、MLE 与风险最优并不相同

三个常见选择是

\[
c_{\mathrm U}=1,
\qquad
c_{\mathrm{MLE}}=\frac{n-1}{n},
\qquad
c_*=\frac{n-1}{n+1}.
\]

分别对应：

- \(S^2\)：无偏样本方差；
- \(\hat\sigma_{\mathrm{MLE}}^2=n^{-1}\sum_i(X_i-\bar X)^2\)：下一章推导的 MLE；
- \((n-1)S^2/(n+1)\)：本族平方误差风险最优者。

标准化风险依次为

\[
R_{\mathrm U}=\frac2{n-1},
\qquad
R_{\mathrm{MLE}}=\frac{2n-1}{n^2},
\qquad
R_*=\frac2{n+1}.
\]

在 \(n=10\) 时，

\[
R_{\mathrm U}=\frac29\approx0.2222,
\quad
R_{\mathrm{MLE}}=\frac{19}{100}=0.19,
\quad
R_*=\frac2{11}\approx0.1818.
\]

Python 的精确账与文件中的实现一致：

```python
def scaled_variance_risk(c, n):
    """正态模型中 E[(c*S^2-sigma^2)^2]/sigma^4，nu=n-1。"""
    nu = n - 1
    return (1 + Fraction(2, nu)) * c ** 2 - 2 * c + 1

n = 10
coefficients = {
    "unbiased": Fraction(1),
    "mle": Fraction(n - 1, n),
    "risk_optimal": Fraction(n - 1, n + 1),
}
risks = {name: scaled_variance_risk(c, n)
         for name, c in coefficients.items()}
assert risks["risk_optimal"] < risks["mle"] < risks["unbiased"]
```

这里的 `Fraction` 让 \(2/9\)、\(19/100\)、\(2/11\) 保持精确有理数，不发生二进制浮点舍入。

无偏性是中心位置条件，MLE 是一种构造原则，风险最优是特定决策准则；三者没有理由总是重合。

## 31.16 Lean：用完全平方证明风险最优

只把风险函数求导并置零，还需要说明为什么得到全局最小值。

Lean 单元直接证明风险差的完全平方恒等式：

```lean
theorem risk_gap (c ν : ℚ) (hν : ν ≠ 0) (hν2 : ν + 2 ≠ 0) :
    scaledVarianceRisk c ν - scaledVarianceRisk (ν / (ν + 2)) ν =
      (1 + 2 / ν) * (c - ν / (ν + 2)) ^ 2 := by
  simp only [scaledVarianceRisk]
  field_simp
  ring
```

当 \(\nu>0\) 时，右侧系数 \(1+2/\nu>0\)，平方项非负。

因此任何 \(c\) 的风险都不低于 \(c_*\) 的风险，并且只有 \(c=c_*\) 时等号成立。

同一文件还证明

```lean
theorem normal_mle_risk (n : ℚ) (hn : n ≠ 0) (hn1 : n - 1 ≠ 0) :
    scaledVarianceRisk ((n - 1) / n) (n - 1) = (2 * n - 1) / n ^ 2 := by
  simp only [scaledVarianceRisk]
  field_simp
  ring
```

这些证明只处理精确代数。

卡方矩来自第 22 章的概率推导，Lean 文件没有把一个代数恒等式冒充整个抽样分布定理。

## 31.17 风险随参数变化：三种比较原则

若 \(R(\theta,\hat\theta)\) 随 \(\theta\) 改变，逐点比较可能出现交叉。

常见决策原则有：

### 限制估计量类别

例如只在无偏估计量中寻找最小方差者。

第 34 章的 Cramér–Rao 下界和最优无偏估计就属于这一思路。

限制类别会改变最优答案，也会排除某些低风险有偏估计。

### 最坏情形风险

定义

\[
R_{\max}(\hat\theta)=\sup_{\theta\in\Theta}R(\theta,\hat\theta).
\]

最小化最大风险给出 minimax 原则。

它关注最不利参数，可能比较保守。

### 平均风险

给定参数上的权重或先验 \(\pi\)，定义 Bayes 风险

\[
r_\pi(\hat\theta)=\int R(\theta,\hat\theta)\,\pi(d\theta).
\]

这与前面的频率派风险不同：这里额外对参数平均。

三种原则回答三个不同问题，不应把其中一个的答案包装成绝对最优。

## 31.18 绝对误差与不同的中心

若损失改为绝对误差，风险为

\[
E_\theta|\hat\theta-\theta|.
\]

对直接预测一个随机变量 \(Y\) 的问题，平方损失的最优常数预测是均值 \(E[Y]\)，绝对损失的最优常数预测是中位数。

证明绝对损失结论可比较候选点 \(a\) 左右移动时两侧概率质量的变化；最优条件在平滑情形下为

\[
P(Y\le a)\ge\frac12,
\qquad
P(Y\ge a)\ge\frac12.
\]

所以损失函数不仅改变风险数值，也可能改变最优统计动作。

均值无偏并不自动意味着在绝对损失、非对称损失或分类损失下最优。

## 31.19 模拟怎样审计风险

对正态方差例，理论风险已经完全算出。

模拟的作用是检查实现、展示有限样本频率，并帮助形成直觉。

Python 使用固定种子和 \(n=10\)：

```python
rng = np.random.default_rng(31)
reps, sigma = 100_000, 2.0
samples = rng.normal(loc=3.0, scale=sigma, size=(reps, n))
s2 = np.var(samples, axis=1, ddof=1)
for name, c in coefficients.items():
    estimates = float(c) * s2
    simulated = np.mean((estimates - sigma ** 2) ** 2) / sigma ** 4
    assert abs(simulated - float(risks[name])) < 0.012
```

`ddof=1` 使 `s2` 对应无偏样本方差。

三个估计量随后使用不同系数 \(c\)，模拟风险除以 \(\sigma^4\) 与理论标准化风险比较。

阈值只用于这次固定规模实验的回归检查，不是普遍误差界。

Julia 单元独立执行同一审计，核心累加为：

```julia
for _ in 1:reps
    s2 = var(3.0 .+ sigma .* randn(n), corrected=true)
    for (name, c) in coefficients
        simulated[name] += (Float64(c) * s2 - sigma^2)^2 / sigma^4
    end
end
```

随机种子固定为 `31`。

模拟通过不增加数学定理的强度；精确风险公式已经给出排序，模拟只是有限次抽样的可复现核对。

## 31.20 模型诊断与估计量评价不能互相替代

一个估计量可以在假定模型中有很小风险，但模型本身错误。

反过来，一个较灵活的模型可能更接近真实分布，却因参数更多而产生更大的估计方差。

这就是模型选择与偏差—方差权衡的联系。

实际分析应分别追问：

1. 数据生成机制是否支持独立、同分布或其他依赖假设；
2. 参数是否可识别；
3. 参数在模型外还有什么解释；
4. 使用什么损失，风险在哪个参数区域重要；
5. 有限样本波动和系统性模型误差各占什么位置。

仅凭残差图不能证明模型绝对正确，仅凭较小训练误差也不能证明风险更小。

## 31.21 本章机器单元与证据边界

本章新增：

- `examples/python/31_estimation_models.py`：精确风险、识别数值例和固定种子风险模拟；
- `examples/julia/31_estimation_models.jl`：独立实现相同风险账与模拟；
- `examples/lean/Probability/Ch31EstimationModels.lean`：偏差—方差、风险公式和最优缩放的代数证明。

三者的职责不同。

Python 和 Julia 的有理数计算验证具体代数，Lean 验证一般恒等式，随机模拟只观察有限样本。

识别、误设和损失选择则需要分布层面的定义与建模判断，不能由一次数值运行替代。

## 31.22 本章要点

1. 参数模型是一族联合分布，参数空间和依赖结构都是假设的一部分。
2. 可识别要求不同参数产生不同分布；不可识别不能靠增加样本量治愈。
3. 估计量是随机变量，估计值是代入数据后的实现。
4. 损失衡量一次错误，风险衡量该参数下的抽样平均损失。
5. 均方误差严格分解为偏差平方加方差，无偏不等于低风险。
6. 正态方差族 \(cS^2\) 的风险最优系数是 \((n-1)/(n+1)\)，不同于无偏系数和 MLE 系数。
7. 模型误设与抽样波动来源不同；风险比较必须说明参数范围、损失和限制类别。

---

上一章：[30 Stirling 公式与局部近似](30-stirling.md) · 下一章：[32 极大似然估计](32-mle.md)
