# 第 35 章 一致性、渐近正态与稳健方差

## 35.1 从“一个估计值”走向“样本量增大时发生什么”

第 31–34 章主要讨论固定样本量下的准则：偏差、方差、MSE、UMVU 和有限样本信息下界。

本章改问渐近问题：

- 样本越来越多时，估计量是否靠近某个确定的参数；
- 估计误差按什么速度缩小；
- 标准化后是否近似正态；
- 应该用哪一个方差公式计算标准误；
- 工作模型错误时，估计量和标准误分别还剩什么含义。

渐近理论不是“大样本时随便近似”。

每个近似都要指明：

1. 数据生成分布是什么；
2. 参数真值或伪真值是什么；
3. 使用了什么矩、得分和导数；
4. 哪些量依概率收敛，哪些量依分布收敛；
5. 余项以什么阶消失。

## 35.2 一致性、渐近正态和渐近有效性

### 一致性

估计量序列 $\hat\theta_n$ 对 $\theta_0$ 弱一致，是指

$$
\hat\theta_n\xrightarrow{p}\theta_0.
$$

即对任意 $\varepsilon>0$，

$$
P(\|\hat\theta_n-\theta_0\|>\varepsilon)\to0.
$$

若几乎必然收敛，则称强一致。

一致性不说明收敛速度，也不说明有限样本无偏。

一个估计量可以有小的有限样本偏差但仍一致，也可以渐近有偏而不一致。

### 渐近正态

若存在正定矩阵 $V$，使

$$
\boxed{
\sqrt n(\hat\theta_n-\theta_0)
\xrightarrow{d}N(0,V),
}
$$

则称估计量具有 $\sqrt n$ 渐近正态性。

这里的 $V$ 是标准化误差的渐近方差。

对估计量本身，常用近似是

$$
\hat\theta_n\approx N(\theta_0,V/n).
$$

把 $V$ 与 $V/n$ 混写，会让标准误相差 $\sqrt n$ 倍。

### 渐近有效性

在正则参数模型中，若某类一致渐近正态估计量的渐近方差达到信息矩阵下界

$$
V=I(\theta_0)^{-1},
$$

则称它渐近有效。

这里的 $I$ 是单个观测的信息矩阵，而不是整样本的 $nI$。

渐近有效不等于有限样本 UMVU，也不等于在所有非正则或任意有偏估计中 MSE 最小。

## 35.3 MLE 一致性的逻辑骨架

设单观测对数似然为 $\ell(X;\theta)=\log f(X;\theta)$。

MLE 最大化平均对数似然

$$
\hat\theta_n=\arg\max_{\theta\in\Theta}
\frac1n\sum_{i=1}^n\ell(X_i;\theta).
$$

在正确设定模型 $P_{\theta_0}$ 下，由 Jensen 不等式，

$$
E_{\theta_0}\left[
\log\frac{f(X;\theta)}{f(X;\theta_0)}
\right]
\le
\log E_{\theta_0}\left[
\frac{f(X;\theta)}{f(X;\theta_0)}
\right]\le0.
$$

所以总体对数似然在 $\theta_0$ 处最大。

若可识别，则其他参数不能产生同一分布，真参数是唯一的总体最大点。

要把这个总体事实转成估计一致性，还需要：

- 样本平均对数似然在参数空间上足够一致地逼近总体目标；
- 参数空间和目标函数使最大值点稳定；
- 识别不仅是一点可识别，还要防止远方参数任意接近真值的目标；
- 最大值存在，或近最大估计的选择足够规则。

常用条件包括紧参数空间、连续性与可积包络，或全局凹性与局部识别。

因此，不能把一致性证明简化成“对大数定律逐点取极限，然后交换 argmax 与极限”。

交换极值和极限正是需要额外条件的步骤。

## 35.4 从得分方程开始推导渐近正态

设 $\theta_0$ 是参数空间内点，MLE 最终以概率趋近 1 为内点并满足得分方程。

定义单观测得分

$$
s(X;\theta)=\nabla_\theta\ell(X;\theta),
$$

以及样本平均得分

$$
\bar s_n(\theta)=\frac1n\sum_{i=1}^ns(X_i;\theta).
$$

内点 MLE 满足

$$
\bar s_n(\hat\theta_n)=0.
$$

在真参数附近展开：

$$
\boxed{
0=\bar s_n(\hat\theta_n)
=\bar s_n(\theta_0)
+H_n(\tilde\theta_n)(\hat\theta_n-\theta_0),
}
$$

其中

$$
H_n(\theta)=\frac1n\sum_{i=1}^n
\nabla_{\theta\theta'}^2\ell(X_i;\theta),
$$

而 $\tilde\theta_n$ 位于 $\hat\theta_n$ 与 $\theta_0$ 之间。

若使用带余项的 Taylor 展开，也可写为

$$
0=\bar s_n(\theta_0)
+H_n(\theta_0)(\hat\theta_n-\theta_0)+r_n.
$$

“得分均值 + 导数项 + 余项”就是这一条。

后续推导的全部工作是证明：

1. 得分均值经 $\sqrt n$ 标准化后服从 CLT；
2. 导数项收敛到固定矩阵；
3. 余项乘以 $\sqrt n$ 后依概率趋于零。

## 35.5 得分均值的中心极限定理

在正确模型和正则条件下，

$$
E_{\theta_0}[s(X;\theta_0)]=0.
$$

定义得分协方差

$$
J=\operatorname{Var}_{\theta_0}(s(X;\theta_0))
=E_{\theta_0}[ss'].
$$

若得分有有限二阶矩，iid 多元 CLT 给出

$$
\sqrt n\,\bar s_n(\theta_0)
=\frac1{\sqrt n}\sum_{i=1}^ns(X_i;\theta_0)
\xrightarrow{d}N(0,J).
$$

这一步不要求信息矩阵等式。

即使模型误设，只要伪真参数处总体得分均值为零且二阶矩有限，仍有同样的得分 CLT，只是期望和方差都在真实分布下计算。

## 35.6 Hessian 的极限与 Slutsky 拼接

定义总体期望 Hessian

$$
A=E\left[\nabla_{\theta\theta'}^2
\ell(X;\theta_0)\right].
$$

在连续性、可积控制和一致性条件下，

$$
H_n(\tilde\theta_n)\xrightarrow{p}A.
$$

若 $A$ 非奇异，从估计方程展开得到

$$
\sqrt n(\hat\theta_n-\theta_0)
=(-H_n(\tilde\theta_n))^{-1}
\sqrt n\,\bar s_n(\theta_0).
$$

由连续映射和 Slutsky 定理，

$$
\boxed{
\sqrt n(\hat\theta_n-\theta_0)
\xrightarrow{d}
N(0,A^{-1}JA^{-1}),
}
$$

这里利用 $A$ 对称，将一般形式 $A^{-1}J(A^{-1})'$ 简写为 $A^{-1}JA^{-1}$。

这就是 MLE 的 sandwich 渐近方差：

$$
\boxed{V=A^{-1}JA^{-1}.}
$$

- 中间 $J$ 记录得分波动；
- 两侧 $A^{-1}$ 记录曲率如何把得分波动映射成参数波动；
- 曲率越平，参数对方程噪声越敏感。

## 35.7 正确设定时为什么化简为信息矩阵逆

在正确设定的正则模型中，信息矩阵等式为

$$
J=I,
\qquad
A=-I.
$$

代入 sandwich：

$$
V=A^{-1}JA^{-1}
=(-I)^{-1}I(-I)^{-1}
=I^{-1}.
$$

因此

$$
\boxed{
\sqrt n(\hat\theta_n-\theta_0)
\xrightarrow{d}N(0,I(\theta_0)^{-1}).
}
$$

MLE 在此意义下渐近达到信息下界。

这里用了两个不同事实：

- 得分的 CLT 只要求零均值和有限二阶矩；
- $A=-J$ 是正确模型下额外求导与积分交换得到的等式。

若模型误设，第一部分仍可能成立，第二部分通常不能保留。

## 35.8 误设模型中的伪真参数

假设真实数据分布为 $Q$，而工作模型是

$$
\mathcal P=\{P_\theta:\theta\in\Theta\},
\qquad Q\notin\mathcal P.
$$

准极大似然估计仍最大化工作对数似然。

在适当条件下，它收敛到

$$
\boxed{
\theta_*
=\arg\max_{\theta\in\Theta}E_Q[\ell(X;\theta)].
}
$$

等价地，若密度与 KL 散度定义良好，

$$
\theta_*=\arg\min_{\theta\in\Theta}
D_{\mathrm{KL}}(Q\|P_\theta).
$$

因此 $\theta_*$ 是 KL 意义下最接近真实分布的工作模型参数，称为伪真参数。

“伪真”不是说它是假的数据真值，而是说它是错误工作模型内部最合理的投影点。

在伪真参数的内点一阶条件下，

$$
E_Q[s(X;\theta_*)]=0.
$$

于是仍可用同样的展开，但矩阵改为

$$
A_Q=E_Q[\nabla^2\ell(X;\theta_*)],
\qquad
J_Q=\operatorname{Var}_Q(s(X;\theta_*)).
$$

渐近方差为

$$
\boxed{
V_Q=A_Q^{-1}J_QA_Q^{-1}.
}
$$

除非另有证明，不应假设 $A_Q=-J_Q$。

## 35.9 一个完全透明的误设例：固定方差正态工作模型

设工作模型为

$$
N(\mu,1),
$$

但真实分布 $Q$ 不一定是正态，也不要求方差为 1。

工作对数似然去掉常数后是

$$
\ell(X;\mu)=-\frac12(X-\mu)^2.
$$

得分与二阶导数为

$$
s(X;\mu)=X-\mu,
\qquad
\ell''(X;\mu)=-1.
$$

总体一阶条件

$$
E_Q[X-\mu_*]=0
$$

给出

$$
\mu_*=E_Q[X].
$$

准 MLE 仍是

$$
\hat\mu=\bar X.
$$

所以即使工作正态模型错误，只要关心的是总体均值，$\bar X$ 仍一致。

但现在

$$
A_Q=-1,
\qquad
J_Q=\operatorname{Var}_Q(X-\mu_*)=\operatorname{Var}_Q(X).
$$

故

$$
\boxed{
\sqrt n(\bar X-\mu_*)
\xrightarrow{d}N(0,\operatorname{Var}_Q(X)).
}
$$

若真实方差为 4，稳健渐近方差就是 4。

机械使用工作模型的信息等式却会给出 1。

Python 的精确代数检查为：

```python
def scalar_sandwich(a, j):
    assert a != 0
    return j / a ** 2

assert scalar_sandwich(F(-1), F(4)) == F(4)
assert scalar_sandwich(F(-1), F(1)) == F(1)
```

第二个断言对应模型与真实方差恰好相容的特例，第一个则说明一般情况下必须保留真实得分方差。

## 35.10 Poisson 伪似然：不要多除一次参数

考虑 Poisson 工作对数似然

$$
\ell(X;\lambda)=X\log\lambda-\lambda-\log(X!).
$$

即使真实分布不是 Poisson，准 MLE 仍满足

$$
\sum_i\left(\frac{X_i}{\hat\lambda}-1\right)=0,
$$

所以

$$
\hat\lambda=\bar X.
$$

伪真值为

$$
\lambda_*=E_Q[X].
$$

在伪真值处，

$$
A_Q
=E_Q\left[-\frac X{\lambda_*^2}\right]
=-\frac1{\lambda_*}.
$$

得分是

$$
s(X;\lambda_*)=\frac{X-\lambda_*}{\lambda_*},
$$

因此

$$
J_Q=\frac{\operatorname{Var}_Q(X)}{\lambda_*^2}.
$$

代入 sandwich：

$$
V_Q
=\frac{J_Q}{A_Q^2}
=\frac{\operatorname{Var}_Q(X)/\lambda_*^2}{1/\lambda_*^2}
=\boxed{\operatorname{Var}_Q(X)}.
$$

这与 $\hat\lambda=\bar X$ 的直接 CLT 完全一致。

若真实模型确实是 Poisson，则 $\operatorname{Var}(X)=\lambda_*$，于是 $V=\lambda_*$。

若真实方差为 5，稳健方差就是 5，不是 $5/\lambda_*^2$。

计算单元用 $\lambda_*=2,\operatorname{Var}_Q(X)=5$ 检查：

```python
a_pois = -1 / lam
j_pois = true_variance / lam ** 2
assert scalar_sandwich(a_pois, j_pois) == true_variance == F(5)
assert lam == F(2)
```

最后一个断言提醒：正确 Poisson 模型下方差才进一步化为 $\lambda$。

中间矩阵已经含 $\lambda_*^{-2}$，两侧曲率会把它抵消，不能再额外除一次。

## 35.11 模型误设不等于估计毫无意义，也不等于参数仍有原义

误设分析需要同时回答两件事。

### 估计什么

准 MLE 通常估计 $\theta_*$，不是不可知的“真实结构参数”。

若工作模型与真实分布共享某个矩意义，例如上面的 $\mu_*=E_QX$，伪真参数仍有清楚解释。

若工作模型的非线性形式错误，$\theta_*$ 可能只是 KL 投影坐标，未必具有研究者最初赋予的结构因果含义。

### 怎样计算不确定度

即使 $\theta_*$ 有一致估计，模型式标准误也可能错误。

稳健 sandwich 修正在适当条件下处理分布误设，但不会把错误参数 magically 变成真实因果参数。

“稳健标准误”中的“稳健”仅针对方差公式的一类假设放松，不代表估计量对任意模型错误都可靠。

## 35.12 GMM 的展开：从目标函数一阶条件开始

回到第 33 章的 GMM：

$$
Q_n(\theta;W)=\bar m_n(\theta)'W\bar m_n(\theta).
$$

为简化展示，先取固定权重 $W$。

内点一阶条件为

$$
\widehat G(\hat\theta)'W\bar m_n(\hat\theta)=0,
$$

其中

$$
\widehat G(\theta)
=\frac{\partial\bar m_n(\theta)}{\partial\theta'}
$$

是 $q\times p$ 矩阵。

在 $\theta_0$ 附近展开：

$$
\bar m_n(\hat\theta)
=\bar m_n(\theta_0)
+\widehat G(\tilde\theta)(\hat\theta-\theta_0).
$$

代入一阶条件并整理：

$$
\boxed{
\hat\theta-\theta_0
\approx
-(G'WG)^{-1}G'W\bar m_n(\theta_0).
}
$$

严格证明中，需要把 $\widehat G(\hat\theta)$、$\widehat G(\tilde\theta)$、$\widehat W$ 与极限 $G,G,W$ 的差全部纳入余项，并证明标准化后消失。

一致性保证展开局部化，导数一致收敛和秩条件保证矩阵可逆。

## 35.13 GMM sandwich 方差

在真参数处

$$
E[m(X,\theta_0)]=0.
$$

定义

$$
S=\operatorname{Var}(m(X,\theta_0)).
$$

由多元 CLT，

$$
\sqrt n\,\bar m_n(\theta_0)
\xrightarrow{d}N(0,S).
$$

把线性化映射

$$
\Psi=(G'WG)^{-1}G'W
$$

作用于该极限，得到

$$
\sqrt n(\hat\theta_W-\theta_0)
\xrightarrow{d}N(0,\Omega(W)),
$$

其中

$$
\boxed{
\Omega(W)
=\Psi S\Psi'
=(G'WG)^{-1}G'WSWG(G'WG)^{-1}.
}
$$

这与 MLE sandwich 的结构相同：

- 中间是原始矩或得分的协方差；
- 两侧是估计方程对参数的线性化映射；
- 最优性来自选择映射使最终方差最小。

若 $W=S^{-1}$，则

$$
\Psi_*=(G'S^{-1}G)^{-1}G'S^{-1},
$$

从而

$$
\boxed{
\Omega_*=(G'S^{-1}G)^{-1}.
}
$$

Python 用第 33 章的二维矩阵直接计算一般式和化简式：

```python
def gmm_asymptotic_variance(g, w, s):
    gwg = g.T @ w @ g
    return np.linalg.solve(
        gwg, g.T @ w @ s @ w @ g @ np.linalg.inv(gwg))
```

随后：

```python
omega_i = gmm_asymptotic_variance(g, np.eye(2), s)
omega_star = gmm_asymptotic_variance(g, np.linalg.inv(s), s)
assert np.allclose(omega_i, [[1.25]])
assert np.allclose(omega_star, [[0.8]])
```

这里 $G=(1,1)'$，$S=\operatorname{diag}(1,4)$。

结果与第 33 章的精确 $5/4$ 和 $4/5$ 一致。

## 35.14 最优 GMM 与渐近有效性的边界

最优 GMM 的“最优”限定在：

- 给定同一组矩条件；
- 使用满足正则条件的渐近线性 GMM 估计；
- 权重矩阵极限固定且正定；
- 比较 $\sqrt n$ 渐近协方差。

它不意味着：

- 任意增加矩条件都改善有限样本；
- 一定优于正确完整模型下的 MLE；
- 在弱识别或矩条件错误时仍有效；
- 两步随机权重在每个有限样本中降低方差。

若得分本身作为矩条件，正确模型下最优权重与信息结构相连，可恢复 MLE 的渐近效率。

若只使用少量低阶矩，最优 GMM 只是在该有限矩集合内最优。

## 35.15 矩条件也可能误设

GMM 不需要完整分布正确，但需要所依赖的矩条件在目标参数处正确。

若不存在任何 $\theta$ 使

$$
E_Q[m(X,\theta)]=0,
$$

那么固定权重 $W$ 下的 GMM 通常收敛到

$$
\theta_W^*
=\arg\min_\theta
\mu(\theta)'W\mu(\theta),
\qquad
\mu(\theta)=E_Q[m(X,\theta)].
$$

它是特定权重下的伪真参数，而不是自动具有结构解释的真参数。

此时还要区分：

- 完整似然模型误设，但所用 GMM 矩条件正确：GMM 仍可一致；
- 矩条件本身错误：换稳健方差不能修复一致性目标；
- 不同权重可能选出不同的伪真参数；
- 标准最优权重与 J 的卡方近似可能失效。

所以 sandwich 方差不是模型错误的万能保险。

## 35.16 J 统计量的渐近自由度再核对

若矩条件正确、参数恰好由 $\theta_0$ 识别、最优权重一致估计 $S^{-1}$，且常规正则条件成立，则

$$
J_n=n\bar m_n(\hat\theta)'\widehat S^{-1}\bar m_n(\hat\theta)
\xrightarrow{d}\chi^2_{q-p}.
$$

原因是：

1. 标准化后的 $q$ 维矩向量渐近正态；
2. 估计 $p$ 个参数相当于在 $p$ 个方向上拟合矩；
3. 白化后的剩余平方长度落在 $q-p$ 维正交方向上。

本章代码核对数值例的自由度：

```python
q, p = 2, 1
assert q - p == 1
```

恰好识别时 $q=p$，残差矩在理想解处为零，没有非平凡 J 检验。

若权重奇异或只有 $r<q$ 个独立矩方向，自由度不能照旧机械写成 $q-p$。

若使用次优权重，最小化目标的加权平方和一般不服从同一个标准 $\chi^2_{q-p}$ 极限。

## 35.17 稳健方差怎样从数据估计

在准 MLE 中，可构造

$$
\widehat A
=\frac1n\sum_i\nabla^2\ell(X_i;\hat\theta),
$$

$$
\widehat J
=\frac1n\sum_i
s(X_i;\hat\theta)s(X_i;\hat\theta)'.
$$

然后使用

$$
\widehat V=\widehat A^{-1}\widehat J\widehat A^{-1},
\qquad
\widehat{\operatorname{Var}}(\hat\theta)
=\frac1n\widehat V.
$$

在 GMM 中对应为

$$
\widehat\Omega
=(\widehat G'\widehat W\widehat G)^{-1}
\widehat G'\widehat W\widehat S\widehat W\widehat G
(\widehat G'\widehat W\widehat G)^{-1}.
$$

若已取 $\widehat W=\widehat S^{-1}$，可化简为

$$
\widehat\Omega_*
=(\widehat G'\widehat S^{-1}\widehat G)^{-1}.
$$

实际报告标准误时，取 $\widehat V/n$ 或 $\widehat\Omega/n$ 的对角元素再开平方。

不要对 $\sqrt n$ 渐近方差矩阵直接开平方后称为估计量标准误。

## 35.18 iid、异方差与时间相关不是同一本账

本章默认 iid，因此

$$
S=E[m_im_i'].
$$

若观测独立但不同分布，或存在条件异方差，得分与矩协方差要按相应结构估计。

若数据时间相关，则

$$
\operatorname{Var}\left(\frac1{\sqrt n}\sum_{i=1}^nm_i\right)
$$

还包含滞后协方差。

此时需要 HAC 等长期方差估计，而不是只把当前残差外积平均。

“用了 sandwich”并不自动说明它适用于任意相关结构；sandwich 的中间矩阵必须匹配数据依赖方式。

## 35.19 固定种子模拟：误设正态标准误的覆盖率

考虑真实数据

$$
X=1+2E,\qquad E\sim\operatorname{Exp}(1).
$$

于是

$$
E_QX=3,
\qquad
\operatorname{Var}_Q(X)=4.
$$

工作模型仍是 $N(\mu,1)$。

准 MLE 为 $\bar X$，伪真值为 3。

以样本量 $n=200$ 重复生成 20,000 组数据，比较：

- 工作模型标准误：$1/\sqrt n$；
- 稳健标准误：样本标准差除以 $\sqrt n$。

Python 使用固定种子：

```python
rng = np.random.default_rng(35)
reps, n = 20_000, 200
samples = 1 + 2 * rng.exponential(size=(reps, n))
estimates = samples.mean(axis=1)
robust_ses = samples.std(axis=1, ddof=1) / np.sqrt(n)
naive_ses = np.full(reps, 1 / np.sqrt(n))
```

随后计算双侧 95% 正态近似区间覆盖率：

```python
naive_coverage = np.mean(
    np.abs(estimates - pseudo_true) <= 1.96 * naive_ses)
robust_coverage = np.mean(
    np.abs(estimates - pseudo_true) <= 1.96 * robust_ses)
empirical_se = estimates.std(ddof=1)
```

本次固定种子的结果是：

| 指标 | 数值 |
|---|---:|
| 经验标准误 / 工作模型标准误 | 2.0035 |
| 工作模型区间经验覆盖率 | 0.6720 |
| 稳健区间经验覆盖率 | 0.9436 |

经验比值接近 2，与真实方差 4、工作模型方差 1 的比值一致。

工作模型区间明显过窄；稳健区间接近名义水平，但不是恰好 0.95。

Julia 用同样的种子值和模型运行独立实现：

```julia
Random.seed!(35)
samples = 1 .+ 2 .* randexp(reps, n)
estimates = vec(mean(samples, dims=2))
robust_ses = vec(std(samples, dims=2, corrected=true)) ./ sqrt(n)
```

广播表达式逐元素生成 $1+2E$，`dims=2` 表示对每行的 $n$ 个观测求均值和标准差。

得到经验比值约 1.9961、覆盖率约 0.6706 和 0.94415。

不同语言的随机数实现不同，所以逐位相同不是目标；理论比值和覆盖率的量级一致才是对账内容。

这些模拟只审计选定 $n$、分布和重复次数下的表现。

渐近结论由 CLT、Hessian 收敛与 Slutsky 拼接证明，不由覆盖率表格证明。

## 35.20 为什么稳健覆盖率仍不必恰好 95%

即使方差估计正确，也还有几层近似：

- $\sqrt n(\hat\theta-\theta_*)$ 的分布只是渐近正态；
- $\widehat A,\widehat J$ 本身是随机的；
- 真实分布可能偏斜，有限样本均值分布也偏斜；
- 临界值 1.96 来自渐近正态而非精确 t 分布；
- Monte Carlo 重复带来模拟误差。

因此 0.9436 不应被解释成“定理预测必须等于这个数”。

渐近理论给的是样本量增大时的极限，有限样本诊断则需要额外的误差界、 bootstrap 理论或模拟校准。

## 35.21 边界、多峰和弱识别会破坏哪些步骤

### 参数在边界

若真参数在边界，内点得分方程可能不成立，KKT 条件取代普通一阶条件。

渐近分布可能是截断正态或更复杂形式，不是直接套用普通对称正态区间。

### 多峰与局部根

求得一个得分零点不保证它是全局 MLE。

不同初始值可能收敛到不同根，各根的渐近行为需要分别分析。

### 弱识别

若 $A$ 或 $G'WG$ 接近奇异，小得分噪声会被大幅放大。

标准正态近似的收敛可能很慢，甚至需要弱工具变量或部分识别的专门理论。

### 重尾

若得分或矩没有有限二阶方差，普通 CLT 与 sandwich 方差可能不存在。

一致性仍可能成立，但收敛速度和极限分布都可能改变。

### 数值收敛

优化器报告收敛只说明满足某个数值停止规则。

它不证明统计识别、一致性、全局最优或渐近正态。

## 35.22 Lean 中的线性化与信息矩阵化简

Lean 文件把标量 sandwich 定义为：

```lean
def scalarSandwich (a j : ℚ) : ℚ := j / a ^ 2
```

正确模型下 $A=-I,J=I$ 的化简为：

```lean
theorem sandwich_information_equality (i : ℚ) (hi : i ≠ 0) :
    scalarSandwich (-i) i = 1 / i := by
  simp only [scalarSandwich]
  field_simp
```

`hi` 明确记录信息非零，避免零信息时把形式分式当成有效方差。

估计方程的局部误差表示也被单独证明：

```lean
theorem linearized_estimation_error
    (s h d r : ℚ) (hh : h ≠ 0)
    (hroot : s + h * d + r = 0) :
    d = -(s + r) / h := by
  field_simp
  linarith
```

这里 `s` 是得分项，`h*d` 是导数项，`r` 是余项。

形式化证明只处理解线性方程的代数，不会自动证明余项在渐近意义下可忽略。

误设正态例的数值断言 `scalarSandwich (-1) 4 = 4` 也由 `norm_num` 精确判决。

## 35.23 一张正确模型与误设模型对照表

| 问题 | 正确正则模型 | 误设工作模型 |
|---|---|---|
| 极限参数 | 真参数 $\theta_0$ | 伪真参数 $\theta_*$ |
| 总体一阶条件 | $E_{\theta_0}s=0$ | $E_Qs(\theta_*)=0$ |
| 曲率矩阵 | $A=E_{\theta_0}\ell''$ | $A_Q=E_Q\ell''(\theta_*)$ |
| 得分方差 | $J=\operatorname{Var}_{\theta_0}s$ | $J_Q=\operatorname{Var}_Qs$ |
| 一般渐近方差 | $A^{-1}JA^{-1}$ | $A_Q^{-1}J_QA_Q^{-1}$ |
| 信息等式 | 正则时 $A=-J$ | 一般不能假设 |
| 化简结果 | $I^{-1}$ | 通常保留 sandwich |
| 参数解释 | 模型中的真参数 | KL 投影或总体目标极值 |

这张表也说明，稳健推断不能只改最后一行。

必须先重新确定极限参数，再在同一真实分布 $Q$ 下计算 $A_Q,J_Q$。

## 35.24 常见误区

### 误区一：一致就是无偏

不是。一致性是样本量趋于无穷的极限性质，无偏性是每个固定样本量的均值性质。

### 误区二：渐近方差 $V$ 就是估计量方差

通常估计量近似方差是 $V/n$。

### 误区三：误设时 MLE 必然不一致

它可能对伪真参数一致；伪真参数是否有目标解释要另行分析。

### 误区四：稳健标准误能修复错误参数

不能。它修正方差估计，不改变估计量的概率极限。

### 误区五：信息矩阵等式永远成立

它依赖正确模型和正则求导条件；误设时必须回到 sandwich。

### 误区六：最优 GMM 比任何 MLE 都有效

最优性限定在给定矩条件和估计类内；正确完整模型中的正则 MLE 使用全部密度信息。

### 误区七：模拟覆盖率接近 95% 就证明渐近定理

模拟只审计指定设计，证明仍来自极限定理和余项控制。

## 35.25 本章要点

1. 一致性描述概率极限，渐近正态描述 $\sqrt n$ 标准化后的分布极限。
2. MLE 渐近展开由得分均值、Hessian 项和可忽略余项组成。
3. 一般 MLE 渐近方差为 $A^{-1}JA^{-1}$；正确正则模型下化为 $I^{-1}$。
4. 误设时估计量通常指向 KL 投影的伪真参数，标准误应在真实分布下计算。
5. 固定方差正态伪似然的均值估计方差是真实 $\operatorname{Var}_Q(X)$。
6. Poisson 伪似然中 $\hat\lambda=\bar X$ 的渐近方差也是真实方差，不多除 $\lambda^2$。
7. GMM 方差为 $(G'WG)^{-1}G'WSWG(G'WG)^{-1}$，最优权重下化为 $(G'S^{-1}G)^{-1}$。
8. J 的标准自由度为 $q-p$，但依赖正确矩条件、最优权重和非奇异有效秩。
9. 稳健方差修复的是不确定度账，不是错误模型的结构解释。
10. 固定种子模拟用于有限样本审计，Lean 与精确计算用于代数对账，二者都不能替代渐近证明。

完整示例为：

- `examples/python/35_asymptotic_estimation.py`；
- `examples/julia/35_asymptotic_estimation.jl`；
- `examples/lean/Probability/Ch35AsymptoticEstimation.lean`。

---

上一章：[34 UMVU 与信息下界](34-efficiency.md) · 下一章：[36 假设检验与 Neyman–Pearson 理论](36-hypothesis-testing.md)
