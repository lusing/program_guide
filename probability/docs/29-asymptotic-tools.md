# 第 29 章 渐近拼接工具：\(O_p/o_p\)、Slutsky 与 Delta 方法

## 29.1 为什么需要“拼接”

中心极限定理通常只直接作用于样本均值或得分均值。

实际统计量却往往是均值的函数、两个统计量的比值，或者插入估计标准误后的标准化量。

例如

\[
\sqrt n(\bar X_n^2-\mu^2),
\qquad
\frac{\sqrt n(\bar X_n-\mu)}{S_n},
\qquad
\log\frac{\hat p}{1-\hat p}.
\]

它们都不是单独的 CLT 公式。

渐近工具的任务是把“已知某个统计量收敛”转化为“由它构造的新统计量也收敛”，并算出新极限的方差。

本章围绕三件工具展开：

1. \(O_p\) 与 \(o_p\) 记录随机序列的尺度；
2. 连续映射与 Slutsky 定理处理函数、和、积和商；
3. Delta 方法处理非线性变换后的渐近分布。

## 29.2 非随机 \(O\) 与 \(o\) 的复习

对数列 \(a_n,b_n\)，若存在常数 \(C\) 和 \(N\)，使 \(n\ge N\) 时

\[
|a_n|\le C|b_n|,
\]

则写 \(a_n=O(b_n)\)。

若

\[
\frac{a_n}{b_n}\to0,
\]

则写 \(a_n=o(b_n)\)。

例如

\[
\frac1n=o(1),
\qquad
2+\frac3n=O(1),
\qquad
\frac1n=o(1/\sqrt n).
\]

这些符号表达尺度，不表达某个固定 \(n\) 的精确值。

\(a_n=O(1)\) 只说有界，不说收敛。

\(a_n=o(1)\) 则明确说趋于零。

## 29.3 概率版本：\(O_p\) 与 \(o_p\)

随机序列 \(A_n\) 称为**依概率有界**，记作

\[
A_n=O_p(1),
\]

如果对每个 \(\varepsilon>0\)，存在有限常数 \(M\) 和 \(N\)，使 \(n\ge N\) 时

\[
P(|A_n|>M)<\varepsilon.
\]

等价地，对每个 \(\varepsilon>0\)，可以选择一个足够大的区间 \([-M,M]\)，使所有充分靠后的分布都把至少 \(1-\varepsilon\) 的概率放在其中。

这也称为该序列 tight。

更一般地，若 \(A_n/B_n=O_p(1)\)，就写 \(A_n=O_p(B_n)\)。

若

\[
A_n\xrightarrow{P}0,
\]

则写

\[
A_n=o_p(1).
\]

相应地，\(A_n/B_n=o_p(1)\) 表示 \(A_n/B_n\xrightarrow{P}0\)。

由依概率收敛的定义，\(o_p(1)\) 一定推出 \(O_p(1)\)，反向不成立。

例如非退化正态序列 \(Z_n\sim N(0,1)\) 是 \(O_p(1)\)，却不趋于零。

## 29.4 常见尺度从哪里来

若 \(E[A_n^2]=O(a_n^2)\)，Chebyshev 或 Markov 不等式通常给出

\[
A_n=O_p(a_n).
\]

例如有限方差 iid 样本满足

\[
\bar X_n-\mu=O_p(n^{-1/2}),
\]

因为

\[
\operatorname{Var}(\bar X_n)=\sigma^2/n.
\]

进一步，大数定律给出

\[
\bar X_n-\mu=o_p(1).
\]

同一序列因此有两个不同层次的描述：

- \(o_p(1)\) 说它最终消失；
- \(O_p(n^{-1/2})\) 说出更精确的数量级。

Python 和 Julia 都用确定性原型检查这些尺度：

```python
scales = [1 / sqrt(k) for k in (1, 10, 100, 1000)]
assert scales[0] > scales[1] > scales[2] > scales[3]
assert all(abs(2 + 3 * scale) <= 5 for scale in scales)
```

这个片段只是帮助区分“缩小”与“有界”；随机版本的结论仍须由概率定义或定理推出。

## 29.5 随机阶的运算法则

常用法则包括

\[
o_p(1)+o_p(1)=o_p(1),
\]

\[
O_p(1)+O_p(1)=O_p(1),
\]

\[
O_p(1)o_p(1)=o_p(1),
\]

以及

\[
O_p(a_n)O_p(b_n)=O_p(a_nb_n).
\]

这些法则的证明与非随机阶类似，只是把绝对值界改成以任意接近 \(1\) 的概率成立。

例如若 \(A_n=O_p(1)\)、\(B_n=o_p(1)\)，先在一个大概率事件上把 \(|A_n|\) 控制在 \(M\)，再利用 \(B_n\to0\) 依概率，即可得到 \(A_nB_n\to0\) 依概率。

在 Taylor 展开中，这些法则允许我们把余项从主要项中分离出去。

但不要把 \(O_p\) 当成几乎必然的一致常数界；它允许小概率的任意大偏差。

## 29.6 连续映射定理

若

\[
X_n\xrightarrow{d}X,
\]

且 \(g\) 在极限分布的支撑附近连续，则

\[
g(X_n)\xrightarrow{d}g(X).
\]

更精确的条件是：极限分布给 \(g\) 的不连续点集合赋零概率。

依概率和几乎必然版本也成立：

\[
X_n\xrightarrow{P}c
\quad\Longrightarrow\quad
g(X_n)\xrightarrow{P}g(c)
\]

只要 \(g\) 在 \(c\) 连续；

\[
X_n\xrightarrow{a.s.}X
\quad\Longrightarrow\quad
g(X_n)\xrightarrow{a.s.}g(X)
\]

只需逐条样本路径应用连续性。

依分布版本的证明可以通过 Skorokhod 表示理解：在一个新概率空间上，用同分布的 \(\widetilde X_n\overset d=X_n\)、\(\widetilde X\overset d=X\) 实现几乎必然收敛，再对每条收敛路径使用连续性。

连续映射定理并不要求 \(g\) 在所有点都连续。

若极限 \(X\) 以正概率落在不连续点，结论可能失败。

例如 \(g(x)=\mathbf1_{x\ge0}\)，且极限在 \(0\) 有点质量时，就必须单独检查边界。

## 29.7 Slutsky 定理：随机序列与常数极限可以拼接

设

\[
X_n\xrightarrow{d}X,
\qquad
Y_n\xrightarrow{P}c,
\]

其中 \(c\) 是常数。

则联合收敛成立：

\[
(X_n,Y_n)\xrightarrow{d}(X,c).
\]

于是由连续映射，

\[
\boxed{
X_n+Y_n\xrightarrow{d}X+c,
\qquad
X_nY_n\xrightarrow{d}cX.
}
\]

若 \(c\ne0\)，还有

\[
\boxed{
X_n/Y_n\xrightarrow{d}X/c.
}
\]

关键是第二项必须趋于**常数**。

若 \(Y_n\xrightarrow{d}Y\) 且 \(Y\) 非退化，仅凭两个边际收敛通常不能决定联合极限；相关结构会影响 \(X_nY_n\) 或 \(X_n/Y_n\)。

Slutsky 的证明思路是：\(Y_n\) 与常数 \(c\) 的差是 \(o_p(1)\)，先证明它不改变连续测试函数的极限，再把 \((X_n,c)\) 代入连续映射定理。

## 29.8 插入标准误为什么合法

设

\[
\sqrt n(\hat\theta_n-\theta)
\xrightarrow{d}N(0,v),
\]

并且 \(\hat v_n\xrightarrow{P}v>0\)。

则

\[
\sqrt{\hat v_n}\xrightarrow{P}\sqrt v
\]

由连续映射成立。

再由 Slutsky，

\[
\boxed{
\frac{\sqrt n(\hat\theta_n-\theta)}{\sqrt{\hat v_n}}
\xrightarrow{d}N(0,1).
}
\]

这就是插入估计标准误后仍可使用标准正态临界值的依据。

Lean 把约分核心写成精确代数：

```lean
theorem plugin_cancel (a b c : ℚ) (hb : b ≠ 0) (hc : c ≠ 0) :
    (a / b) * (b / c) = a / c := by
  field_simp
```

概率部分则由连续映射和 Slutsky 提供；两者缺一不可。

如果 \(\hat v_n\) 不一致，或者真方差为零，不能仅靠这个代数恒等式推出正态极限。

## 29.9 一阶 Delta 方法

设

\[
\sqrt n(T_n-\theta)\xrightarrow{d}N(0,v),
\]

且 \(g\) 在 \(\theta\) 可微。

则

\[
\boxed{
\sqrt n\{g(T_n)-g(\theta)\}
\xrightarrow{d}
N\left(0,[g'(\theta)]^2v\right).
}
\]

证明只需要一阶 Taylor 展开：

\[
g(T_n)-g(\theta)
=g'(\theta)(T_n-\theta)+R_n.
\]

可微性给出

\[
R_n=o(|T_n-\theta|).
\]

由于 \(T_n-\theta=O_p(n^{-1/2})\)，有

\[
R_n=o_p(n^{-1/2}).
\]

所以

\[
\sqrt nR_n=o_p(1).
\]

因此

\[
\sqrt n\{g(T_n)-g(\theta)\}
=g'(\theta)\sqrt n(T_n-\theta)+o_p(1).
\]

第一项趋于 \(N(0,[g'(\theta)]^2v)\)，第二项由 Slutsky 不影响极限。

Delta 方法不是神秘的近似公式，而是“局部线性化 + 随机阶余项 + Slutsky”。

## 29.10 例一：样本均值的平方

设 iid 样本均值为 \(\mu\)、方差为 \(\sigma^2\)，则

\[
\sqrt n(\bar X_n-\mu)\xrightarrow{d}N(0,\sigma^2).
\]

取 \(g(x)=x^2\)，有 \(g'(\mu)=2\mu\)。

若 \(\mu\ne0\)，Delta 方法给出

\[
\boxed{
\sqrt n(\bar X_n^2-\mu^2)
\xrightarrow{d}N(0,4\mu^2\sigma^2).
}
\]

Python 用 SymPy 计算导数和方差，避免手工抄错系数。符号 `mu`、`variance` 都声明为正数，后一例的 `p` 同理：

```python
import sympy as sp
mu, variance = sp.symbols("mu variance", positive=True)

def delta_variance(g, theta, base_variance):
    return sp.simplify(sp.diff(g, theta) ** 2 * base_variance)

assert delta_variance(mu ** 2, mu, variance) == 4 * mu ** 2 * variance
```

Lean 对同一系数提供独立的代数证明：

```lean
theorem delta_square (μ σ2 : ℚ) :
    deltaVariance (2 * μ) σ2 = 4 * μ ^ 2 * σ2 := by
  simp only [deltaVariance]
  ring
```

这里 SymPy 是符号计算，Lean 是定理证明；二者验证的是同一个代数结论，但形式化保证不同。

## 29.11 例二：Poisson 的方差稳定化

若单个观测来自均值为 \(\lambda\) 的 Poisson 分布，则样本均值满足

\[
\sqrt n(\bar X_n-\lambda)
\xrightarrow{d}N(0,\lambda).
\]

极限方差随 \(\lambda\) 改变。

取

\[
g(\lambda)=\sqrt\lambda,
\qquad
g'(\lambda)=\frac1{2\sqrt\lambda}.
\]

Delta 方差为

\[
[g'(\lambda)]^2\lambda
=\frac1{4\lambda}\lambda
=\frac14.
\]

所以

\[
\boxed{
\sqrt n(\sqrt{\bar X_n}-\sqrt\lambda)
\xrightarrow{d}N(0,1/4).
}
\]

变换后的渐近方差不再依赖 \(\lambda\)，这就是方差稳定化。

Python 中对应

```python
assert delta_variance(sp.sqrt(p), p, p) == sp.Rational(1, 4)
```

Lean 用 \(q=\sqrt p\) 避免在有理数中处理平方根：

```lean
theorem delta_poisson_sqrt (q : ℚ) (hq : q ≠ 0) :
    deltaVariance (1 / (2 * q)) (q ^ 2) = 1 / 4 := by
  simp only [deltaVariance]
  field_simp
  ring
```

有限样本中，若 \(\bar X_n=0\)，开方仍有定义；但对数或 logit 变换可能出现更严重的边界问题。

## 29.12 例三：Bernoulli logit 与标准化

设 \(\hat p_n\) 是 iid Bernoulli\((p)\) 样本均值，\(0<p<1\)。

CLT 给出

\[
\sqrt n(\hat p_n-p)
\xrightarrow{d}N(0,p(1-p)).
\]

取 logit 变换

\[
g(p)=\log\frac{p}{1-p},
\qquad
g'(p)=\frac1{p(1-p)}.
\]

Delta 方法得到

\[
\boxed{
\sqrt n\left(
\log\frac{\hat p_n}{1-\hat p_n}
-
\log\frac{p}{1-p}
\right)
\xrightarrow{d}
N\left(0,\frac1{p(1-p)}\right).
}
\]

Python 的符号断言是（`p = sp.symbols("p", positive=True)`）：

```python
logit_variance = delta_variance(sp.log(p / (1 - p)), p, p * (1 - p))
assert sp.simplify(logit_variance - 1 / (p * (1 - p))) == 0
```

若把分母 \(p(1-p)\) 换成一致估计 \(\hat p_n(1-\hat p_n)\)，由 Slutsky，

\[
\frac{\sqrt n\{g(\hat p_n)-g(p)\}}
{\sqrt{1/[\hat p_n(1-\hat p_n)]}}
\xrightarrow{d}N(0,1).
\]

这就是“估计量标准化”的完整链条：CLT 给未标准化极限，Delta 给变换方差，连续映射处理分母，Slutsky 完成插入。

模拟单元以 \(p=0.25,n=400\) 检查 logit 的样本方差：

```python
predicted = 1 / (n * true_p * (1 - true_p))
observed = statistics.variance(logits)
assert abs(observed / predicted - 1) < 0.08
```

另用 \(100\) 个正态观测构造插入样本标准差的 \(t\) 统计量，检查两个固定正态区间频率；这样可把 Slutsky 插入误差与 Bernoulli 的有限样本偏态分开观察。

随机种子固定为 `29`；这些数值只审计有限样本表现。

## 29.13 多元 Delta 方法

若 \(\mathbf T_n\in\mathbb R^k\) 满足

\[
\sqrt n(\mathbf T_n-\boldsymbol\theta)
\xrightarrow{d}N_k(\mathbf0,\Sigma),
\]

且 \(g:\mathbb R^k\to\mathbb R^m\) 在 \(\boldsymbol\theta\) 可微，则

\[
\sqrt n\{g(\mathbf T_n)-g(\boldsymbol\theta)\}
\xrightarrow{d}
N_m(\mathbf0,D\Sigma D^\top),
\]

其中

\[
D=\left.\frac{\partial g}{\partial\boldsymbol\theta^\top}
\right|_{\boldsymbol\theta}
\]

是 \(m\times k\) Jacobi 矩阵。

一维公式 \([g'(\theta)]^2v\) 是 \(m=k=1\) 的特例。

矩阵维数提供了检查公式是否写反的快速方法：

- \(D\) 是 \(m\times k\)；
- \(\Sigma\) 是 \(k\times k\)；
- \(D\Sigma D^\top\) 是 \(m\times m\)。

多元情形下不能只对每个分量分别求导后相加；交叉协方差由 \(D\Sigma D^\top\) 自动保留。

## 29.14 导数为零时，一阶 Delta 方法失效

回到 \(g(x)=x^2\)，但这次令 \(\mu=0\)。

此时

\[
g'(0)=0.
\]

一阶 Delta 公式只会给出渐近方差 \(0\)，无法描述非退化极限。

若单个样本来自 \(N(0,1)\)，则

\[
\bar X_n\sim N(0,1/n).
\]

因此

\[
n\bar X_n^2\sim\chi_1^2
\]

对每个 \(n\) 都精确成立，而不只是渐近成立。

注意尺度已经从 \(\sqrt n\) 改为 \(n\)。

一般地，若

\[
\sqrt n(T_n-\theta)\xrightarrow{d}\sigma Z,
\]

且 \(g'(\theta)=0\)、\(g''(\theta)\ne0\)，二阶 Taylor 展开给出

\[
g(T_n)-g(\theta)
=\frac12g''(\theta)(T_n-\theta)^2+o_p((T_n-\theta)^2).
\]

乘以 \(n\) 后，

\[
\boxed{
n\{g(T_n)-g(\theta)\}
\xrightarrow{d}
\frac12g''(\theta)\sigma^2Z^2.
}
\]

极限通常是非中心位置被缩放的 \(\chi_1^2\)，不是均值为零的 Gaussian。

Python 和 Julia 都检查 \(n\bar X_n^2\) 的均值接近 \(1\)、方差接近 \(2\)：

```julia
q = [size * (sum(randn() for _ in 1:size) / size)^2
     for _ in 1:20_000]
@assert abs(mean(q) - 1) < 0.05
@assert abs(var(q) - 2) < 0.12
```

这里 `size=1,10,100` 都满足同一精确分布；有限模拟误差不会随 `size` 的分布身份而改变。

## 29.15 参数边界与高阶退化

Delta 方法的可微性必须相对于参数空间中的正确方向理解。

若 \(p=0\) 或 \(p=1\)，Bernoulli 方差本身为零，普通 \(\sqrt n\) 正态极限退化，logit 也没有有限定义。

若参数位于约束边界，估计量可能频繁粘在边界上，渐近分布往往不是普通正态。

若 \(g'(\theta)=0\)、\(g''(\theta)=0\)，就需要继续展开到第一个非零项，尺度也会进一步改变。

因此“套 Delta 公式”之前应先检查：

1. 原统计量的标准化与极限分布是什么；
2. \(g\) 在真参数处是否可微；
3. 第一个非零导数是哪一阶；
4. 新方差是否退化；
5. 真参数是否在边界。

## 29.16 机器验证与有限样本警告

本章 Python、Julia 和 Lean 单元分别承担不同任务。

Python 使用 SymPy 推导三个 Delta 方差，使用固定种子模拟核对 logit 方差、插入标准误和二阶退化。

Julia 独立实现同样的数值实验，并用有理数检查 Bernoulli logit 的方差代数。

Lean 文件 `examples/lean/Probability/Ch29AsymptoticTools.lean` 证明方差系数和插入约分恒等式。

完整计算文件是 `examples/python/29_asymptotic_tools.py` 与 `examples/julia/29_asymptotic_tools.jl`。

模拟结果可能看起来很好，却不能证明收敛定理；反过来，定理给出渐近正态，也不保证 \(n=20\) 或边界附近的近似质量。

实际报告应同时给出样本量、标准误构造和必要的有限样本诊断。

## 29.17 本章要点

1. \(O_p(1)\) 表示依概率有界，\(o_p(1)\) 表示依概率趋于零。
2. 连续映射把收敛传递到连续函数，Slutsky 把依分布序列与趋于常数的序列拼接。
3. Delta 方法的证明是一阶 Taylor、随机阶余项和 Slutsky 的组合。
4. 一维渐近方差是 \([g'(\theta)]^2v\)，多元形式是 \(D\Sigma D^\top\)。
5. 样本均值平方、Poisson 开方和 Bernoulli logit 分别展示函数变换、方差稳定化和估计量标准化。
6. 导数为零时必须提高 Taylor 阶数，并把尺度从 \(\sqrt n\) 改为 \(n\) 或更高阶。
7. 模拟只检查有限样本；参数边界和退化方差必须另行分析。

---

上一章：[28 Fourier 分析与特征函数](28-fourier-clt.md) · 下一章：[30 Stirling 公式与局部近似](30-stirling.md)
