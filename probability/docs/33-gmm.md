# 第 33 章 矩估计与广义矩方法

## 33.1 从“分布长什么样”转向“哪些矩必须为零”

极大似然估计要求写出完整的数据分布。

矩方法换一个起点：即使不知道完整分布，经济理论、守恒关系或测量结构也可能告诉我们，在真参数处某些随机函数的平均值必须为零。

例如：

- 若总体均值为 $\mu$，则 $E[X-\mu]=0$；
- 若总体二阶矩为 $\mu^2+\sigma^2$，则 $E[X^2-\mu^2-\sigma^2]=0$；
- 若工具变量 $Z$ 与结构误差 $\varepsilon$ 正交，则 $E[Z\varepsilon]=0$；
- 若资产定价误差在信息集下条件均值为零，则它与该信息集中任何可测工具的乘积都有无条件零均值。

这些陈述只约束分布的一部分。

因此，矩估计与 GMM 的核心不是“把一个公式代入样本均值”，而是：

> 把关于总体的可检验约束转化为样本中的估计准则，并明确这些约束是否足以识别参数。

本章依次解决四个问题：

1. 总体矩怎样变成样本矩估计；
2. 矩条件多于参数时怎样折中；
3. 为什么最优权重是矩条件协方差矩阵的逆；
4. 两步 GMM、J 统计量和奇异权重分别意味着什么。

## 33.2 总体矩、样本矩与经典矩估计

设 $X_1,\ldots,X_n$ 是 iid 样本。

若理论模型给出第 $r$ 阶总体矩

$$
M_r(\theta)=E_\theta[X^r],
$$

相应样本矩是

$$
\widehat M_r=\frac1n\sum_{i=1}^nX_i^r.
$$

经典矩估计选择 $\theta$，使若干总体矩与样本矩匹配：

$$
M_r(\hat\theta)=\widehat M_r,
\qquad r=1,\ldots,p.
$$

这里默认参数是 $p$ 维，并选了足够多的独立矩方程。

“独立”不是概率独立，而是这些方程不能把同一个约束重复包装，否则方程数目看似足够，实际仍不能确定参数。

### 指数分布的均值参数化

若 $X_i$ iid 服从均值为 $\theta>0$ 的指数分布，则

$$
E_\theta[X]=\theta.
$$

匹配一阶矩立即得到

$$
\hat\theta_{\mathrm{MME}}=\bar X.
$$

在这个模型中，它也恰好是 MLE。

原因不是“矩法通常等于似然法”，而是指数模型的对数似然只通过 $\sum_iX_i$ 依赖数据，样本均值已经包含该参数的全部充分信息。

### 正态双参数

若 $X_i\sim N(\mu,\sigma^2)$，匹配前两阶矩：

$$
\hat\mu=\bar X,
\qquad
\frac1n\sum_iX_i^2=\hat\sigma^2+\hat\mu^2.
$$

所以

$$
\hat\mu=\bar X,
\qquad
\hat\sigma^2=\frac1n\sum_i(X_i-\bar X)^2.
$$

这里的方差估计除以 $n$，不是除以 $n-1$。

这与第 32 章的正态 MLE 一致，却与无偏样本方差不同。

矩估计并不自动无偏；样本矩本身无偏，不意味着它的非线性反函数也无偏。

## 33.3 更一般的矩条件

经典矩法通常写成“理论矩等于样本矩”。

GMM 则统一写成零均值条件。

令

- $\theta\in\Theta\subseteq\mathbb R^p$ 是未知参数；
- $m(X,\theta)\in\mathbb R^q$ 是矩函数；
- $X_1,\ldots,X_n$ 是 iid 观测。

假设存在真参数 $\theta_0$，使

$$
\boxed{E[m(X,\theta_0)]=0.}
$$

这里 $0$ 是 $q$ 维零向量。

样本矩向量是

$$
\bar m_n(\theta)=\frac1n\sum_{i=1}^nm(X_i,\theta).
$$

对每个固定的 $\theta$，大数定律在适当可积条件下给出

$$
\bar m_n(\theta)\xrightarrow{p}E[m(X,\theta)].
$$

但“对每个固定参数收敛”并不自动推出整个最小化问题的一致性。

一致性还需要参数空间、连续性、可积包络、权重极限和识别等条件；第 35 章会回到这一点。

## 33.4 工具变量为什么也是矩条件

考虑线性结构方程

$$
Y=X'\beta_0+\varepsilon.
$$

若解释变量与误差满足

$$
E[X\varepsilon]=0,
$$

就有

$$
E[X(Y-X'\beta_0)]=0.
$$

此时矩函数可以取

$$
m((Y,X),\beta)=X(Y-X'\beta).
$$

若某些解释变量与误差相关，而另有工具变量 $Z$ 满足外生性和相关性，则可使用

$$
m((Y,X,Z),\beta)=Z(Y-X'\beta).
$$

外生性给出

$$
E[m(\beta_0)]=0;
$$

相关性则用于保证矩条件确实包含关于 $\beta_0$ 的方向信息。

只有外生性而没有相关性，工具变量不会 magically 识别参数。

例如 $Z$ 恒等于零时，矩条件对任何 $\beta$ 都成立，却没有估计价值。

## 33.5 恰好识别、过度识别与欠识别

矩条件数 $q$ 与参数维数 $p$ 的相对大小给出第一层分类。

### 恰好识别：$q=p$

若 $q=p$，常尝试直接解

$$
\bar m_n(\hat\theta)=0.
$$

但方程数等于未知数并不保证解存在或唯一。

还要检查非线性、边界、Jacobi 矩阵秩和参数空间。

若解唯一，权重矩阵通常不改变恰好识别估计量，因为样本矩已经能被同时置零，目标函数的最小值就是零。

### 过度识别：$q>p$

一般不能要求所有样本矩同时为零。

这是因为抽样噪声会让 $q$ 个方程在 $p$ 个未知数下不相容。

GMM 改为让加权后的矩向量尽量接近零。

过度识别还提供额外的矩限制检验自由度，但检验有功效不等于模型已被证明为真。

### 欠识别：有效约束不足

即使 $q\ge p$，也可能欠识别。

真正关键的是 Jacobi 矩阵

$$
G(\theta)=E\left[\frac{\partial m(X,\theta)}{\partial\theta'}\right]
$$

在真参数附近是否具有列满秩 $p$。

若存在非零方向 $d$，使 $Gd=0$，那么局部地沿 $d$ 改参数不会改变矩条件的一阶近似。

所以“矩比参数多”只是计数条件，不是充分识别证明。

## 33.6 GMM 目标函数与矩阵维数

选择一个对称半正定的 $q\times q$ 权重矩阵 $W$。

GMM 估计量定义为

$$
\boxed{
\hat\theta_W
=\arg\min_{\theta\in\Theta}
Q_n(\theta;W),
\qquad
Q_n(\theta;W)
=\bar m_n(\theta)'W\bar m_n(\theta).
}
$$

本书把权重矩阵记为 $W$，最优时再取 $W=S^{-1}$。

有些教材直接把目标写成 $\bar m'\widehat W^{-1}\bar m$，那里的 $\widehat W$ 相当于本书的 $W^{-1}$。

读公式时必须先看作者究竟把“权重”还是“协方差”命名为 $W$。

维数账如下：

| 对象 | 维数 |
|---|---:|
| $\theta$ | $p\times1$ |
| $m(X,\theta)$ | $q\times1$ |
| $\bar m_n$ | $q\times1$ |
| $W$ | $q\times q$ |
| $G=E[\partial m/\partial\theta']$ | $q\times p$ |
| $G'WG$ | $p\times p$ |

若 $W$ 正定，$Q_n\ge0$，且 $Q_n=0$ 当且仅当 $\bar m_n=0$。

若只知 $W$ 半正定，则目标可能忽略某些矩方向，必须额外检查这些被忽略的方向是否导致识别损失。

## 33.7 线性矩条件的闭式解

设矩函数关于参数线性：

$$
m(X_i,\theta)=a(X_i)-G_i\theta.
$$

为突出矩阵结构，先考虑 $G_i=G$ 不随观测变化的简单情形。

记

$$
\bar a=\frac1n\sum_i a(X_i),
\qquad
\bar m_n(\theta)=\bar a-G\theta.
$$

目标为

$$
Q_n(\theta)=(\bar a-G\theta)'W(\bar a-G\theta).
$$

对 $\theta$ 求梯度：

$$
\nabla_\theta Q_n
=-2G'W(\bar a-G\theta).
$$

内点解满足正规方程

$$
G'WG\hat\theta=G'W\bar a.
$$

若 $G'WG$ 可逆，则

$$
\boxed{
\hat\theta_W=(G'WG)^{-1}G'W\bar a.
}
$$

这个公式与加权最小二乘相似，但对象是“样本矩向量”，不是直接把每条原始观测都等权处理。

Python 单元把同一条公式写成一般矩阵接口：

```python
def linear_gmm(a_array, g_array, w_array):
    return np.linalg.solve(
        g_array.T @ w_array @ g_array,
        g_array.T @ w_array @ a_array)
```

这里用 `solve` 解线性方程，而不是显式计算逆矩阵。

前者通常更稳定，也避免把“数学上的逆矩阵公式”机械翻译成“数值上先求逆再相乘”。

## 33.8 一个完全手算的两矩一例

为看清每一步，考虑三个成对观测

$$
(X_{i1},X_{i2})=(1,2),(3,6),(2,1).
$$

假设真参数 $\theta_0$ 满足

$$
E[X_1-\theta_0]=0,
\qquad
E[X_2-\theta_0]=0.
$$

于是

$$
m(X_i,\theta)=
\begin{pmatrix}X_{i1}-\theta\\X_{i2}-\theta\end{pmatrix},
\qquad
G=\begin{pmatrix}1\\1\end{pmatrix}.
$$

样本均值向量是

$$
\bar a=\begin{pmatrix}2\\3\end{pmatrix}.
$$

参数只有一个，而矩有两个，所以 $q=2,p=1$，属于过度识别。

Python 先用有理数保存样本均值：

```python
pairs = [(F(1), F(2)), (F(3), F(6)), (F(2), F(1))]
n = len(pairs)
a = [sum(pair[j] for pair in pairs) / n for j in range(2)]
g = [F(1), F(1)]
assert a == [F(2), F(3)]
```

有理数使后面的 $5/2$、$11/5$ 和 J 统计量都是精确值，不受浮点舍入影响。

### 一步等权 GMM

取 $W=I$，即最小化

$$
(2-\theta)^2+(3-\theta)^2.
$$

直接求导，或代入线性公式，得到

$$
\hat\theta_I=\frac{2+3}{2}=\frac52.
$$

等权目标的直觉很清楚：两个矩方向的样本偏差平方和最小。

但若两个矩的噪声尺度不同，等权就没有充分利用这个差异。

## 33.9 已知协方差下的最优权重

假设在真参数处

$$
S=\operatorname{Var}(m(X,\theta_0))
=\begin{pmatrix}1&0\\0&4\end{pmatrix}.
$$

也就是第二个矩的噪声方差为 4，是第一个的 4 倍，且两者不相关。

取

$$
W_*=S^{-1}=
\begin{pmatrix}1&0\\0&1/4\end{pmatrix}.
$$

线性 GMM 公式给出

$$
\hat\theta_*
=\frac{1\cdot2+\frac14\cdot3}{1+\frac14}
=\frac{11}{5}.
$$

Python 的标量精确计算对应为：

```python
identity = [[F(1), F(0)], [F(0), F(1)]]
known_s = [[F(1), F(0)], [F(0), F(4)]]
known_precision = [[F(1), F(0)], [F(0), F(1, 4)]]
theta_one = scalar_linear_gmm(a, g, identity)
theta_star = scalar_linear_gmm(a, g, known_precision)
assert theta_one == F(5, 2)
assert theta_star == F(11, 5)
```

`scalar_linear_gmm` 计算的就是 $G'W\bar a/(G'WG)$。

它没有使用任何迭代算法，因为这个例子有闭式解。

Julia 单元用同样的有理数独立复算：

```julia
theta_one = scalar_linear_gmm(a, g, identity)
theta_star = scalar_linear_gmm(a, g, known_precision)
@assert theta_one == 5 // 2
@assert theta_star == 11 // 5
```

这里 `//` 构造 Julia 有理数，避免 `1/4` 先变成二进制浮点。

两个实现的函数名相同，但各自从矩阵公式重新计算，不读取另一语言的输出。

最优估计比等权估计更靠近第一组均值，不是因为第一组数据“更真实”，而是因为其矩条件方差更小。

## 33.10 用渐近方差验证权重选择

定义

$$
G=E\left[\frac{\partial m(X,\theta_0)}{\partial\theta'}\right],
\qquad
S=\operatorname{Var}(m(X,\theta_0)).
$$

第 35 章将推导一般公式：

$$
\sqrt n(\hat\theta_W-\theta_0)
\xrightarrow{d}N(0,\Omega(W)),
$$

其中

$$
\boxed{
\Omega(W)=
(G'WG)^{-1}G'WSWG(G'WG)^{-1}.
}
$$

若 $W=S^{-1}$，中间的三明治收缩为

$$
\boxed{
\Omega_*=(G'S^{-1}G)^{-1}.
}
$$

本例中

$$
G'G=2,
\qquad
G'SG=1+4=5,
$$

所以等权权重的渐近方差为

$$
\Omega(I)=\frac5{2^2}=\frac54.
$$

而

$$
G'S^{-1}G=1+\frac14=\frac54,
$$

故最优权重给出

$$
\Omega_*=\frac45.
$$

计算单元同时检查这两个值和最优权重的化简：

```python
omega_one = scalar_sandwich(g, identity, known_s)
omega_star = scalar_sandwich(g, known_precision, known_s)
assert omega_one == F(5, 4)
assert omega_star == F(4, 5)
```

注意这些是 $\sqrt n(\hat\theta-\theta_0)$ 的渐近方差。

若讨论 $\hat\theta$ 本身的近似方差，应分别除以 $n$。

把 $5/4$ 直接写成 $\hat\theta$ 的方差，会漏掉样本量尺度。

## 33.11 为什么逆协方差权重最优

先看本例对应的两个独立测量。

设两个无偏测量分别为 $T_1,T_2$，方差为 $s_1,s_2$。

归一化线性组合

$$
T_a=aT_1+(1-a)T_2
$$

仍无偏，其方差为

$$
V(a)=a^2s_1+(1-a)^2s_2.
$$

令

$$
a_*=\frac{s_2}{s_1+s_2}.
$$

它对应的两个权重比例为

$$
a_*:1-a_*
=\frac{s_2}{s_1+s_2}:\frac{s_1}{s_1+s_2}
=s_1^{-1}:s_2^{-1}.
$$

直接展开可得完全平方恒等式

$$
\boxed{
V(a)-V(a_*)=(s_1+s_2)(a-a_*)^2.
}
$$

只要方差为正，就有 $V(a)\ge V(a_*)$，等号仅在 $a=a_*$ 时成立。

最优值为

$$
V(a_*)=\frac{s_1s_2}{s_1+s_2}.
$$

代入 $s_1=1,s_2=4$，得到 $a_*=4/5$ 和 $V(a_*)=4/5$。

### 一般矩阵形式

对一般 $W$，定义线性化矩到参数的映射

$$
\Psi_W=(G'WG)^{-1}G'W.
$$

它满足 $\Psi_WG=I$。

最优映射为 $\Psi_*=\Psi_{S^{-1}}$。

利用 $\Psi_*S(\Psi_W-\Psi_*)'=0$，可分解

$$
\boxed{
\Omega(W)-\Omega_*
=(\Psi_W-\Psi_*)S(\Psi_W-\Psi_*)'
\succeq0.
}
$$

所以最优不是“数值上看起来更小”，而是在 Loewner 半正定序下最小。

这意味着对任何参数线性组合 $c'\theta$，最优权重给出的渐近方差都不更大。

## 33.12 两步 GMM：未知 $S$ 时的可行算法

实际中 $S$ 通常未知。

标准两步法如下。

### 第一步：固定正定权重

常取 $W^{(1)}=I$，得到初步一致估计 $\hat\theta^{(1)}$。

在异方差或工具变量尺度差异明显时，也可取对角归一化权重。

第一步的目标主要是得到一致的残差，而不是声称已经有效。

### 第二步：估计矩协方差

在 iid 且真矩均值为零时，常用非中心估计

$$
\widehat S
=\frac1n\sum_{i=1}^n
m(X_i,\hat\theta^{(1)})m(X_i,\hat\theta^{(1)})'.
$$

然后取

$$
W^{(2)}=\widehat S^{-1},
\qquad
\hat\theta^{(2)}
=\arg\min_\theta\bar m_n(\theta)'\widehat S^{-1}\bar m_n(\theta).
$$

本例的一步估计为 $5/2$，逐观测矩向量构成

$$
(X_{i1}-5/2,X_{i2}-5/2).
$$

精确计算得到

$$
\widehat S=
\begin{pmatrix}
11/12&13/12\\
13/12&59/12
\end{pmatrix}.
$$

其行列式为 $10/3$，所以可逆。

Python 从残差逐项构造它：

```python
moment_vectors = [
    [pair[j] - theta_one for pair in pairs]
    for j in range(2)]
s_hat = [[sum(moment_vectors[i][t] * moment_vectors[j][t]
              for t in range(n)) / n
          for j in range(2)] for i in range(2)]
```

再求第二步解：

```python
w_two = [[s_hat[1][1] / det, -s_hat[0][1] / det],
         [-s_hat[1][0] / det, s_hat[0][0] / det]]
theta_two = scalar_linear_gmm(a, g, w_two)
assert theta_two == F(43, 22)
```

这个只有三个观测的小例子给出 $\hat\theta^{(2)}=43/22$。

它与使用已知 $S$ 时的 $11/5$ 不同，完全正常：

- $11/5$ 使用已知的总体最优权重；
- $43/22$ 使用三个观测估计出的随机权重；
- 两步 GMM 的“最优”是渐近意义，不保证每个小样本都等于假想已知权重解。

也不能因为两步结果不同，就擅自挑选更接近主观预期的那个报告。

## 33.13 连续更新与迭代 GMM

两步法不是唯一可行版本。

**迭代 GMM**：在得到新参数后重新估计 $\widehat S$，再最小化，直到收敛。

**连续更新 GMM（CU-GMM）**：把权重也看成参数的函数，直接最小化

$$
\bar m_n(\theta)'S_n(\theta)^{-1}\bar m_n(\theta).
$$

三者共享同一总体最优权重思想，但有限样本目标并不相同。

连续更新形式可能改善某些弱识别或高度非线性问题，也可能带来更难的数值优化。

“多迭代几次”不自动意味着更一致或更有效；仍要检查收敛、识别和权重矩阵条件数。

## 33.14 J 统计量与过度识别限制

在矩条件正确、最优权重一致估计 $S^{-1}$、参数内点且满足常规正则条件时，

$$
\boxed{
J=nQ_n(\hat\theta;\widehat S^{-1})
=n\bar m_n(\hat\theta)'\widehat S^{-1}\bar m_n(\hat\theta)
\xrightarrow{d}\chi^2_{q-p}.
}
$$

自由度是

$$
q-p,
$$

不是 $q$，也不是 $p$。

估计 $p$ 个自由参数会消耗 $p$ 个独立矩方向，剩下 $q-p$ 个方向用于检查过度识别限制。

### 本章数值例的 J 账

使用已知最优权重和 $\hat\theta_*=11/5$，残差样本矩为

$$
\bar a-G\hat\theta_*
=\begin{pmatrix}-1/5\\4/5\end{pmatrix}.
$$

因此

$$
Q_*=
\left(-\frac15\right)^2
+\frac14\left(\frac45\right)^2
=\frac15,
\qquad
J=3Q_*=\frac35.
$$

Python 精确核对：

```python
residual = [a[j] - g[j] * theta_star for j in range(2)]
q_star = sum(residual[i] * known_precision[i][j] * residual[j]
             for i in range(2) for j in range(2))
assert q_star == F(1, 5)
assert n * q_star == F(3, 5)
```

这里 $q-p=1$。

但样本量只有 3，这个 $3/5$ 只是公式演算，不能据此声称渐近卡方近似已经准确。

两步估计所得随机权重下，代码还得到 $J=9/11$。

两个 J 数值使用不同权重，不能把它们当作同一目标函数上的“前后下降量”。

### J 检验不做什么

- 不拒绝矩条件，不证明完整经济模型为真；
- 恰好识别时 $q-p=0$，没有非平凡 J 检验；
- 权重不是最优或方差估计不适合相关数据时，标准卡方结论可能失效；
- 工具变量整体都很弱时，常规渐近近似可能很差；
- 矩条件错误时，估计量可能收敛到伪真值，J 的分布也会改变。

## 33.15 奇异或病态权重矩阵

若 $\widehat S$ 奇异，直接写 $\widehat S^{-1}$ 没有定义。

这在以下情形常见：

- 样本量小于或接近矩条件数；
- 一个矩是另一个矩的精确线性组合；
- 某些工具变量完全共线；
- 数值舍入使理论上的微小特征值变成零或负数。

处理顺序应是：

1. **检查重复和构造错误**：先删除真正冗余的矩条件；
2. **重新检查识别**：确认剩余 $G$ 仍有列满秩；
3. **改善估计与尺度**：标准化量纲差异巨大的矩；
4. **必要时正则化**：例如岭修正，但明确它改变了权重和有限样本目标；
5. **谨慎使用伪逆**：伪逆只处理可辨识子空间，不能假装奇异方向仍被估计。

若使用秩为 $r<q$ 的权重或矩协方差，J 的有效自由度通常应按实际独立矩方向重新核算，而不是机械写 $q-p$。

Python 用一个全 1 矩阵检查秩亏：

```python
assert np.linalg.matrix_rank(np.ones((2, 2))) == 1
```

这个断言只识别矩阵秩，不会替研究者决定哪些经济矩应该删除。

矩阵求逆能返回数值，也不代表结果可靠；条件数极大时，微小样本扰动就可能导致权重和估计剧烈变化。

## 33.16 Lean 中的最优权重代数证明

本章的 Lean 文件把两个独立测量的方差定义为：

```lean
def twoMeasurementVariance (a s1 s2 : ℚ) : ℚ :=
  a ^ 2 * s1 + (1 - a) ^ 2 * s2

def optimalFirstWeight (s1 s2 : ℚ) : ℚ :=
  s2 / (s1 + s2)
```

核心定理不是枚举某几个权重，而是证明所有有理权重下的完全平方差：

```lean
theorem two_measurement_variance_gap
    (a s1 s2 : ℚ) (hs : s1 + s2 ≠ 0) :
    twoMeasurementVariance a s1 s2 -
        twoMeasurementVariance (optimalFirstWeight s1 s2) s1 s2 =
      (s1 + s2) * (a - optimalFirstWeight s1 s2) ^ 2 := by
  simp only [twoMeasurementVariance, optimalFirstWeight]
  field_simp
  ring
```

`field_simp` 清除分母，`ring` 完成多项式恒等式。

这条机器证明覆盖的是最优权重的代数部分。

它没有替代对独立性、无偏性、方差为正以及 GMM 渐近展开的数学假设。

另一个定理把最优值化简为 $s_1s_2/(s_1+s_2)$，并对 $1,4$ 的数值例做精确判决。

## 33.17 GMM 与 MLE 的关系

若完整参数模型正确，单个观测的得分满足

$$
E_\theta[\nabla_\theta\log f(X;\theta)]=0.
$$

因此得分方程本身就是一组矩条件。

以这些得分为矩函数、在适当条件下取最优权重，可以得到与 MLE 渐近等价的估计。

反过来，只使用少数低阶矩通常会丢弃分布中的其他信息，所以在完整模型正确且 MLE 正则时，低阶矩估计一般不如 MLE 有效。

但 GMM 的优势是：

- 不必指定完整密度；
- 可以直接表达条件矩和工具变量约束；
- 能处理完整似然难以写出的结构模型；
- 能把多个来源的正交条件放入同一框架。

因此不能简单说“MLE 总是优于 GMM”。

正确的问题是：完整分布假设是否可信、使用了哪些矩、权重是否适当、参数是否识别，以及推断是否需要对误设稳健。

## 33.18 常见误区

### 误区一：样本矩匹配后估计量必然无偏

错。样本均值无偏，不意味着 $1/\bar X$、$\bar X^2$ 等变换无偏。

### 误区二：矩条件多于参数就过度识别且识别良好

错。有效秩和总体矩映射同样重要，重复矩不会增加信息。

### 误区三：最优权重是 $S$

错。本书约定目标为 $\bar m'W\bar m$，最优 $W=S^{-1}$。

### 误区四：两步估计在有限样本一定优于一步估计

错。最优性是渐近的；估计权重本身会增加有限样本噪声。

### 误区五：J 很大只说明某个工具不好

不一定。J 拒绝的是整组矩限制与估计结构的联合相容性，不能仅凭 J 定位哪一个工具错误。

### 误区六：奇异矩阵加一个很小的数就解决了统计问题

数值可逆不等于识别恢复。正则化是额外选择，必须披露并检查敏感性。

## 33.19 本章要点

1. 矩法把总体约束 $E[m(X,\theta_0)]=0$ 转成样本矩条件。
2. 恰好识别看解的存在唯一；过度识别需要加权折中；有效识别最终取决于秩。
3. GMM 最小化 $\bar m'W\bar m$，其中 $W$ 是 $q\times q$ 矩阵。
4. 线性矩条件下，$\hat\theta_W=(G'WG)^{-1}G'W\bar a$。
5. 最优权重是 $S^{-1}$，最优渐近方差是 $(G'S^{-1}G)^{-1}$。
6. 两步法先用固定权重取得一致估计，再用残差估计 $S$ 并重新最小化。
7. 最优权重下 $J\xrightarrow{d}\chi^2_{q-p}$，但小样本、奇异权重和误设都需要额外审查。
8. Lean 的完全平方证明与 Python/Julia 的精确有理数账共同核对代数；它们不替代总体识别与渐近条件。

完整示例为：

- `examples/python/33_gmm.py`；
- `examples/julia/33_gmm.jl`；
- `examples/lean/Probability/Ch33GMM.lean`。

---

上一章：[32 极大似然估计](32-mle.md) · 下一章：[34 UMVU 与信息下界](34-efficiency.md)
