# 第 26 章 大数定律与 Monte Carlo

## 26.1 从频率稳定到数学定理

重复独立试验中，样本均值

\[
\bar X_n=\frac1n\sum_{i=1}^nX_i
\]

为什么会靠近总体均值 \(\mu\)？大数定律把“长期频率趋于稳定”变成两类精确命题：

- **弱大数定律（WLLN）**：\(\bar X_n\xrightarrow{P}\mu\)；
- **强大数定律（SLLN）**：\(\bar X_n\xrightarrow{a.s.}\mu\)。

由第 25 章，强律蕴含弱律，反向一般不成立。两者都在说样本均值的收敛，但弱律只控制固定 \(n\) 的偏差概率，强律控制整条样本路径的最终行为。

本章从有限方差下最短的 Chebyshev 证明出发，再比较 Khinchin 与 Kolmogorov 强律，解释 Monte Carlo 的 \(1/\sqrt n\) 误差，并用 Cauchy 样本说明有限一阶矩条件不是可有可无的装饰。

## 26.2 样本均值的两行矩账

设 \(X_1,\dots,X_n\) 独立，均值都为 \(\mu\)，方差都为 \(\sigma^2<\infty\)。期望线性性不需要独立性：

\[
E[\bar X_n]
=\frac1n\sum_iE[X_i]
=\mu.
\]

方差计算中，独立性使交叉协方差消失：

\[
\operatorname{Var}(\bar X_n)
=\frac1{n^2}\operatorname{Var}\left(\sum_iX_i\right)
=\frac1{n^2}\sum_i\operatorname{Var}(X_i)
=\frac{\sigma^2}{n}.
\]

因此

\[
\boxed{
E[\bar X_n]=\mu,\qquad
\operatorname{Var}(\bar X_n)=\frac{\sigma^2}{n}.
}
\]

只两两不相关也足以得到方差公式；完整独立性在后续强律或精确分布计算中才发挥更多作用。

Lean 用有理数记录一个具体实例：\(n=12,\sigma^2=3\) 时，

```lean
example : ((3 : ℚ)) / 12 = 1 / 4 := by norm_num
```

标准差则是

\[
\operatorname{SD}(\bar X_n)=\frac{\sigma}{\sqrt n}.
\]

Lean 检查“精度翻倍需四倍样本”的方差形式：

```lean
example (v n : ℚ) : v / (4 * n) = (v / n) / 4 := by ring
```

这个 \(1/\sqrt n\) 尺度是 Monte Carlo 收敛速度的来源，也是第 27 章中心极限定理采用 \(\sqrt n\) 标准化的原因。

## 26.3 Chebyshev 证明弱大数定律

Chebyshev 不等式为

\[
P(|Y-EY|\ge\varepsilon)
\le\frac{\operatorname{Var}(Y)}{\varepsilon^2}.
\]

代入 \(Y=\bar X_n\)：

\[
\boxed{
P(|\bar X_n-\mu|\ge\varepsilon)
\le\frac{\sigma^2}{n\varepsilon^2}.
}
\]

固定 \(\varepsilon>0\)，令 \(n\to\infty\)，右端趋零，所以

\[
\boxed{\bar X_n\xrightarrow{P}\mu.}
\]

这就是有限方差 iid 样本的弱大数定律。证明链为

\[
\text{Markov}\Longrightarrow
\text{Chebyshev}\Longrightarrow
\text{WLLN}.
\]

Lean 检查 \(\sigma^2=1,\varepsilon=1/10\) 时，\(n=10^5\) 与 \(10^6\) 的上界：

```lean
example : ((1 : ℚ)) / (10 ^ 5 * (1 / 10) ^ 2) = 1 / 1000 := by norm_num
example : ((1 : ℚ)) / (10 ^ 6 * (1 / 10) ^ 2) = 1 / 10000 := by norm_num
example : ((1 : ℚ)) / 10000 < 1 / 1000 := by norm_num
```

这些只是界值的精确算术，不把有限数值检查冒充极限证明；真正的极限来自 \(\sigma^2/(n\varepsilon^2)\) 的一般表达式。

## 26.4 Chebyshev 界与精确二项尾

对公平 Bernoulli 样本，

\[
X_i\in\{0,1\},\qquad p=\frac12,
\qquad \operatorname{Var}(X_i)=\frac14.
\]

Chebyshev 给出

\[
P\left(\left|\bar X_n-\frac12\right|\ge\varepsilon\right)
\le\frac1{4n\varepsilon^2}.
\]

而 \(n\bar X_n\sim\operatorname{Bin}(n,1/2)\)，所以精确尾概率为

\[
\sum_{\substack{0\le k\le n\\
|k/n-1/2|\ge\varepsilon}}
\frac{\binom nk}{2^n}.
\]

Python 用 `Fraction` 精确枚举：

```python
def exact_tail(n, eps):
    tot = F(0)
    for k in range(n + 1):
        if abs(F(k, n) - F(1, 2)) >= eps:
            tot += F(comb(n, k), 2 ** n)
    return tot

cheb = F(1, 4) / (n * eps * eps)
assert t <= min(F(1), cheb)
```

对 \(\varepsilon=1/10\) 和 \(n=10,50,100,400\)，精确尾均不超过 Chebyshev 界，并随 \(n\) 严格下降。\(n=400\) 时，Chebyshev 上界为

\[
\frac1{4\cdot400\cdot0.1^2}=0.0625,
\]

而精确尾远小于它。

Julia 用 `BigInt` 二项系数和有理数独立核对同一关系。这说明 Chebyshev 的优点是只需二阶矩，代价是通常很松；精确分布可给出更小的真实尾概率，但计算和模型假设更多。

## 26.5 弱律的准确含义

弱律

\[
P(|\bar X_n-\mu|\ge\varepsilon)\to0
\]

是对每个固定 \(n\) 的概率陈述。它允许某些坏事件在不同 \(n\) 上反复出现，只要它们各自的概率趋零。

若把不同 \(n\) 的实验完全分开重复，弱律说明：大样本下观察到显著偏差的实验比例很小。但它不直接说一条无限延伸的样本路径最终永远保持在 \(\mu\) 附近。

因此：

- 固定 \(n\)、重复许多次实验，是检验弱律偏差的自然方式；
- 固定一条路径、观察所有后续 \(m\ge n\)，才触及强律的尾部要求。

强律的形式化尾事件为

\[
P\left(\bigcap_{n=1}^\infty\bigcup_{m\ge n}
\{|\bar X_m-\mu|\ge\varepsilon\}\right)=0.
\]

弱律只处理内层事件的单项概率，强律处理整个并集。

## 26.6 Khinchin 强大数定律

Khinchin 强律只需 iid 和有限一阶矩：

\[
\boxed{
X_1,X_2,\dots\ \text{iid},\quad E|X_1|<\infty,\quad E[X_1]=\mu
\Longrightarrow
\bar X_n\xrightarrow{a.s.}\mu.
}
\]

它不要求有限方差。因此 Chebyshev 的证明虽然简单，却不是最强结论。

有限一阶矩既保证均值有意义，又通过截断技术控制大值。其证明思路是：

1. 在随 \(i\) 增长的截断水平定义
   \[
   Y_i=X_i\mathbf1\{|X_i|\le i\};
   \]
2. 用有限一阶矩证明原变量与截断变量最终几乎必然相同；
3. 对截断变量使用独立序列的方差估计和 Kolmogorov 型工具；
4. 处理截断均值的偏移并拼接极限。

本章后面只验证截断条件的一笔核心账，不把整个证明压缩成一句“由定理显然”。

## 26.7 Kolmogorov 强大数定律

Kolmogorov 强律允许独立但不同分布的变量。设 \(X_i\) 独立、各均值和方差有限，若

\[
\boxed{
\sum_{i=1}^\infty\frac{\operatorname{Var}(X_i)}{i^2}<\infty,
}
\]

则

\[
\boxed{
\frac1n\sum_{i=1}^n(X_i-E[X_i])
\xrightarrow{a.s.}0.
}
\]

对 iid 有限方差变量，条件变为

\[
\sum_i\frac{\sigma^2}{i^2}
=\sigma^2\sum_i\frac1{i^2}<\infty,
\]

所以立即得到 iid 有限方差强律。

两者比较：

| 定理 | 同分布要求 | 主要矩条件 | 结论 |
|---|---|---|---|
| Khinchin | iid | \(E|X_1|<\infty\) | \(\bar X_n\to\mu\) a.s. |
| Kolmogorov | 只需独立 | \(\sum_i\operatorname{Var}(X_i)/i^2<\infty\) | 中心化平均趋于 0 a.s. |

Kolmogorov 的版本更灵活，但方差级数条件可能比有限一阶矩更强。不能把“有限方差”误写成所有大数定律的必要条件。

## 26.8 四阶矩证明：一条可完整展开的强律路线

若 iid 变量中心化后有有限四阶矩，可以给强律一个较短证明。令

\[
E[X_i]=0,\qquad S_n=\sum_{i=1}^nX_i,
\]

并记

\[
\sigma^2=E[X_i^2],\qquad m_4=E[X_i^4].
\]

展开 \(S_n^4\) 后，含单次或三次某个独立因子的项期望为零。只剩：

- \(n\) 个 \(E[X_i^4]\) 项；
- \(3n(n-1)\) 个 \(E[X_i^2X_j^2]\) 项，\(i\ne j\)。

因此

\[
\boxed{
E[S_n^4]=n m_4+3n(n-1)\sigma^4.
}
\]

由 \(\sigma^4\le m_4\)（Jensen 或 Cauchy–Schwarz），若 \(m_4\le M\)，则

\[
E[S_n^4]\le3n^2M.
\]

对 \(|S_n/n|\ge\varepsilon\) 使用四阶 Markov：

\[
P(|S_n/n|\ge\varepsilon)
\le\frac{E[S_n^4]}{n^4\varepsilon^4}
\le\frac{3M}{n^2\varepsilon^4}.
\]

右端关于 \(n\) 可求和，第一 Borel–Cantelli 引理给出

\[
S_n/n\xrightarrow{a.s.}0.
\]

### 26.8.1 对称 \(\pm1\) 变量的精确账

若 \(X_i\) 等概率取 \(\pm1\)，则 \(m_4=\sigma^2=1\)，所以

\[
E[S_n^4]=n+3n(n-1)=3n^2-2n.
\]

Python 对 \(n\le12\) 穷举所有符号向量：

```python
for signs in product((-1, 1), repeat=n):
    tot += F(sum(signs) ** 4, 2 ** n)
assert tot == 3 * n * n - 2 * n
assert tot <= 3 * n * n
```

Julia 改用位掩码枚举同一件事：

```julia
for mask in 0:(2^n - 1)
    s = 2 * count_ones(mask) - n
    tot += s^4 // 2^n
end
@assert tot == 3n^2 - 2n
```

这两种实现都精确验证展开系数；一般四阶矩公式则由独立性和期望线性性得到。

## 26.9 固定路径与重复试验：两种模拟视角

Python 和 Julia 都用固定种子 2026 生成 8 条指数分布路径，每条长度 \(10^5\)。指数分布均值为 1，程序计算累计均值：

```python
paths = rng.exponential(1.0, size=(8, 100000))
means = np.cumsum(paths, axis=1) / np.arange(1, 100001)
assert np.all(np.abs(means[:, -1] - 1) < 0.02)
```

进一步计算每条路径从第 \(n\) 项往后的最大偏差：

```python
dev = np.abs(means - 1)
sup_tail = np.maximum.accumulate(dev[:, ::-1], axis=1)[:, ::-1]
assert sup_tail[:, 1000].max() > sup_tail[:, 50000].max()
```

`sup_tail[:, n]` 对应

\[
\sup_{m\ge n}|\bar X_m-1|
\]

在已生成长度内的截断版本。它比只报告最后一个均值更接近强律的尾部语言。

但必须强调：

- 8 条路径不是连续不可数样本空间的证明；
- 长度 \(10^5\) 不是无限未来；
- 固定种子只保证可复现；
- 尾部 supremum 在有限窗口内下降不等于无限尾事件概率为零。

这些模拟是审计和直观展示，不是 SLLN 证明。

## 26.10 Monte Carlo 与 \(1/\sqrt n\) 误差

设要估计

\[
I=E[g(X)]
\]

且 \(\sigma_g^2=\operatorname{Var}(g(X))<\infty\)。取 iid 样本 \(X_1,\dots,X_n\)，估计量

\[
\widehat I_n=\frac1n\sum_{i=1}^ng(X_i)
\]

满足

\[
E[\widehat I_n]=I,
\qquad
\operatorname{Var}(\widehat I_n)=\frac{\sigma_g^2}{n},
\qquad
\operatorname{RMSE}(\widehat I_n)=\frac{\sigma_g}{\sqrt n}.
\]

大数定律给一致性，方差公式给误差尺度。两者不是同一件事：WLLN 只说误差概率趋零，\(1/\sqrt n\) 进一步说明典型误差如何随样本量下降。

### 26.10.1 用单位圆估计 \(\pi\)

在正方形 \([0,1]^2\) 均匀取点，令

\[
B=\mathbf1\{U^2+V^2\le1\}.
\]

因为四分之一单位圆面积为 \(\pi/4\)，

\[
p=E[B]=\frac\pi4,
\qquad \pi=4E[B].
\]

估计量为

\[
\widehat\pi_n=4\bar B_n.
\]

其标准误差为

\[
\sigma_{\widehat\pi}
=\frac{4\sqrt{p(1-p)}}{\sqrt n}.
\]

Python 对 \(n=100,10^4,10^6\) 重复实验并比较 RMSE：

```python
sig = 4 * sqrt(p * (1 - p))
est = np.array([4 * np.mean(
    (lambda u: u[:, 0] ** 2 + u[:, 1] ** 2 <= 1)(
        rng.random((n, 2)))) for _ in range(reps)])
rmse = sqrt(np.mean((est - pi) ** 2))
assert 0.6 * sig / sqrt(n) < rmse < 1.5 * sig / sqrt(n)
```

样本量扩大 100 倍，标准误差约缩小 10 倍；想让有效数字增加一位，通常要约 100 倍计算量。这是朴素 Monte Carlo 的基本成本约束。

模拟 RMSE 接近理论值不证明大数定律，它核对估计器实现与理论方差相容。

## 26.11 Cauchy 样本均值不收敛

标准 Cauchy 分布密度为

\[
f(x)=\frac1{\pi(1+x^2)}.
\]

它不满足 \(E|X|<\infty\)，因为尾部按 \(x^{-2}\) 衰减，\(|x|f(x)\) 的积分呈对数发散。

其特征函数为

\[
\varphi_X(t)=E[e^{itX}]=e^{-|t|}.
\]

若 \(X_1,\dots,X_n\) 为独立标准 Cauchy，样本均值的特征函数为

\[
\begin{aligned}
\varphi_{\bar X_n}(t)
&=E\left[e^{it(X_1+\cdots+X_n)/n}\right]\\
&=\prod_{i=1}^n\varphi_X(t/n)\\
&=\left(e^{-|t|/n}\right)^n
=e^{-|t|}.
\end{aligned}
\]

由特征函数唯一性，

\[
\boxed{\bar X_n\overset d=X_1}
\]

对每个 \(n\) 成立。样本均值的分布完全没有收缩，因此不可能依概率或几乎必然收敛到常数。

特别地，

\[
P(|\bar X_n|>1)=P(|X_1|>1)
=2\left(1-\left(\frac12+\frac{\arctan1}{\pi}\right)\right)
=\frac12.
\]

Python 对 \(n=10\) 与 \(1000\) 做固定种子模拟：

```python
p10 = np.mean(np.abs(m10) > 1)
p1000 = np.mean(np.abs(m1000) > 1)
assert abs(p10 - 0.5) < 0.05 and abs(p1000 - 0.5) < 0.05
```

Julia 用逆变换

\[
X=\tan(\pi(U-1/2))
\]

生成 Cauchy 变量，独立检查同一结论。这个反例直接对应 Khinchin 强律的一阶矩条件。

## 26.12 从均值收敛到经验分布一致收敛

样本均值只估计一个期望。经验分布函数则试图恢复整个 CDF：

\[
F_n(x)=\frac1n\sum_{i=1}^n\mathbf1\{X_i\le x\}.
\]

对每个固定 \(x\)，指示变量 iid 且均值为 \(F(x)\)，强律给出

\[
F_n(x)\xrightarrow{a.s.}F(x).
\]

Glivenko–Cantelli 定理进一步加强为一致收敛：

\[
\boxed{
D_n=\sup_{x\in\mathbb R}|F_n(x)-F(x)|
\xrightarrow{a.s.}0.
}
\]

“逐点收敛”到“一致收敛”不是自动升级；定理需要同时控制所有 \(x\)。连续分布下常用顺序统计量和网格把问题化为有限多个点的控制。

Python 对 \(U(0,1)\) 样本计算 KS 距离：

```python
x = np.sort(rng.random(n))
i = np.arange(1, n + 1)
ds.append(max(np.max(i / n - x),
              np.max(x - (i - 1) / n)))
```

对 \(n=50,500,5000,50000\)，程序检查平均 \(D_n\) 缩小且 \(\sqrt nD_n\) 保持有界。后者是更精细的涨落尺度，不能由 Glivenko–Cantelli 的“趋于 0”单独推出。

## 26.13 Kolmogorov 最大不等式

强律证明常需要控制一段部分和路径的最大值，而不只是终点。设 \(X_i\) 独立、均值为 0、方差有限，令

\[
S_k=X_1+\cdots+X_k.
\]

Kolmogorov 不等式为

\[
\boxed{
P\left(\max_{1\le k\le n}|S_k|\ge\lambda\right)
\le\frac{\operatorname{Var}(S_n)}{\lambda^2}
=\frac{\sum_{i=1}^n\operatorname{Var}(X_i)}{\lambda^2}.
}
\]

若只控制终点，Chebyshev 只给

\[
P(|S_n|\ge\lambda)\le\frac{\operatorname{Var}(S_n)}{\lambda^2}.
\]

Kolmogorov 把左侧换成整个路径最大值，而右侧不增加因子，是强收敛证明的重要工具。

Python 对简单对称随机游走穷举所有路径：

```python
for signs in product((-1, 1), repeat=n):
    s, mx = 0, 0
    for e in signs:
        s += e
        mx = max(mx, abs(s))
    cnt += mx >= lam
prob = F(cnt, 2 ** n)
assert prob <= F(n, lam * lam)
```

同时检查

\[
P\left(\max_{k\le n}|S_k|\ge\lambda\right)
\ge P(|S_n|\ge\lambda),
\]

因为终点越界本身就是路径最大值越界的一种情况。这里的有限枚举验证实现，不是一般独立非对称情形的证明。

## 26.14 截断条件：有限一阶矩如何控制大值

Khinchin 强律的核心截断为

\[
Y_i=X_i\mathbf1\{|X_i|\le i\}.
\]

若原变量与截断变量不同，则必有 \(|X_i|>i\)。要使二者最终几乎必然相同，由第一 Borel–Cantelli 引理，只需

\[
\sum_{i=1}^\infty P(|X_i|>i)<\infty.
\]

iid 时，这个级数为

\[
\sum_{i=1}^\infty P(|X_1|>i).
\]

对任意非负随机变量 \(W\)，

\[
\sum_{i=1}^\infty P(W>i)
\le E[W].
\]

可以用指示函数和 Tonelli 定理看出：

\[
\sum_{i=1}^\infty\mathbf1\{W>i\}\le W,
\]

逐项取期望即可。因此有限一阶矩给出可求和条件。

对形状 \(\alpha=1.5\)、下界 1 的 Pareto 分布，

\[
P(X>i)=i^{-1.5}\quad(i\ge1),
\qquad E[X]=\frac\alpha{\alpha-1}=3.
\]

所以

\[
\sum_{i=1}^\infty P(X>i)=\zeta(1.5)\approx2.612<3.
\]

Python 计算长有限和并检查上界：

```python
EX = alpha / (alpha - 1)
tail_sum = sum(i ** (-alpha) for i in range(1, 2 * 10 ** 6))
assert tail_sum <= EX
```

有限求和只是数值审计；一般不等式来自 Tonelli，而不是因为某个分布的级数碰巧小于 3。

## 26.15 强弱律与 Monte Carlo 的常见误区

1. **误区：弱律说每条路径最终稳定。**
   这是强律的内容；弱律只控制每个固定 \(n\) 的偏差概率。

2. **误区：强律要求有限方差。**
   Khinchin 只要求 iid 和 \(E|X_1|<\infty\)。

3. **误区：样本均值的标准差是 \(\sigma/n\)。**
   正确为 \(\sigma/\sqrt n\)，方差才是 \(\sigma^2/n\)。

4. **误区：Chebyshev 界等于真实尾概率。**
   它只是弱假设下的上界，二项精确尾可小很多。

5. **误区：Monte Carlo 收敛证明来自模拟图。**
   一致性来自大数定律，RMSE 尺度来自方差公式，模拟只审计实现。

6. **误区：样本越多，Cauchy 均值越集中。**
   标准 Cauchy 样本均值始终同分布，没有任何收缩。

7. **误区：经验 CDF 每个点收敛就自动一致收敛。**
   一致收敛是 Glivenko–Cantelli 的额外结论。

8. **误区：强律可以靠生成几条长路径来验证为定理。**
   路径图无法覆盖零概率坏集合和无限未来。

## 26.16 本章要点

1. 弱大数定律是依概率收敛，强大数定律是几乎必然收敛。
2. 独立或两两不相关同方差样本满足 \(E[\bar X_n]=\mu\)、\(\operatorname{Var}(\bar X_n)=\sigma^2/n\)。
3. Chebyshev 给出 \(P(|\bar X_n-\mu|\ge\varepsilon)\le\sigma^2/(n\varepsilon^2)\)，直接证明有限方差 WLLN。
4. Khinchin 强律只需 iid 有限一阶矩；Kolmogorov 版本处理独立不同分布并要求方差级数收敛。
5. 有限四阶矩时，\(E[S_n^4]\le3n^2M\) 与 Borel–Cantelli 给出一条完整强律证明路线。
6. 固定路径和重复试验分别适合展示强律尾部与弱律偏差，但都不是证明。
7. Monte Carlo 无偏估计的 RMSE 为 \(\sigma_g/\sqrt n\)，样本量扩大 100 倍只把误差约缩小 10 倍。
8. 标准 Cauchy 均值始终同分布，是有限一阶矩条件失效的反例。
9. Glivenko–Cantelli 把经验 CDF 的逐点强收敛提升为一致强收敛。
10. Kolmogorov 最大不等式控制整段路径，截断级数 \(\sum P(|X|>i)\le E|X|\) 连接有限一阶矩与强律证明。

*对应示例：`examples/lean/Probability/Ch18InequalitiesLLN.lean`（原不等式与大数定律模块）、`examples/julia/26_lln.jl`、`examples/python/26_lln.py`。*

---

上一章：[25 随机变量序列的收敛](25-convergence.md) · 下一章：[27 中心极限定理](27-clt.md)
