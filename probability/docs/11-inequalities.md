# 11 概率不等式与矩的界限

完整分布往往未知，但均值、方差或少量矩可以估计。
概率不等式把这些有限信息转成尾部上界、事件并的界和平均值的收敛结论。
本章证明 Markov、Chebyshev、Jensen 与 Boole 不等式，并用反例说明每个假设为何不可省。

## 11.1 只知道均值通常不够

想控制 \(P(X\ge a)\)，仅知道 \(E[X]=0\) 并不能给出非平凡上界。
对 \(0<p<1\)，构造两点分布

\[
P(X=2)=p,\qquad P(X=-b)=1-p,
\qquad b=\frac{2p}{1-p}.
\]

均值恰为

\[
2p-b(1-p)=0,
\]

但 \(P(X\ge2)=p\) 可以任意接近 1。
负尾部可以无限向左延伸，从而用很小概率平衡很大的正概率。

非负性排除这种机制。另一条路是掌握二阶矩，限制偏离均值的总体成本。
这就是 Markov 与 Chebyshev 的分工。

## 11.2 Markov：非负变量的均值控制尾部

**定理。**若 \(X\ge0\)、\(E[X]<\infty\)，则对任意 \(a>0\)，

\[
\boxed{P(X\ge a)\le\frac{E[X]}a}.
\]

证明用指示变量。若 \(X\ge a\)，则 \(X/a\ge1\)，所以逐点有

\[
\mathbf1_{\{X\ge a\}}\le\frac Xa.
\]

两边取期望：

\[
P(X\ge a)=E[\mathbf1_{\{X\ge a\}}]
\le E[X/a]=E[X]/a.
\]

非负性保证 \(X/a\) 在整个样本空间非负，因而不等式放缩合法。
若 \(X=\pm1\) 等概率，则均值为 0，而 \(P(X\ge1/2)=1/2\)，
直接说明去掉非负假设后结论失败。

Markov 界可以取等号。固定 \(0<\mu<a\)，令

\[
P(X=a)=\mu/a,\qquad P(X=0)=1-\mu/a.
\]

则 \(E[X]=\mu\)，且 \(P(X\ge a)=\mu/a\)。
因此在没有额外分布信息时，这个界不能整体改进。
不过对指数等具体分布，它可能很松；紧度必须相对假设类而言。

## 11.3 Chebyshev：二阶矩给出平方衰减

设 \(E[X]=\mu\)、\(\operatorname{Var}(X)=\sigma^2<\infty\)。
对任意 \(t>0\)，

\[
\boxed{P(|X-\mu|\ge t)\le\frac{\sigma^2}{t^2}}.
\]

证明只需对非负变量 \((X-\mu)^2\) 使用 Markov：

\[
P(|X-\mu|\ge t)
=P((X-\mu)^2\ge t^2)
\le\frac{E[(X-\mu)^2]}{t^2}
=\frac{\sigma^2}{t^2}.
\]

若 \(\sigma>0\)，取 \(t=k\sigma\)，得到常见形式

\[
P(|X-\mu|\ge k\sigma)\le1/k^2.
\]

从 Markov 的 \(1/a\) 到 Chebyshev 的 \(1/t^2\)，代价是多知道一个二阶矩。
在 \(t\) 很大时平方衰减通常更强，但小 \(t\) 时右端可能大于 1，仍然只是平凡界。

### 标准差与方差不可混淆

若 \(X\sim U[0,1]\)，则 \(\mu=1/2\)、\(\sigma^2=1/12\)。
对事件 \(X\ge0.95\)，偏离均值至少 \(0.45\)，正确参数是

\[
k^2=\frac{0.45^2}{1/12}=2.43,
\qquad P(|X-\mu|\ge0.45)\le\frac1{2.43}=\frac{100}{243}\approx0.4115.
\]

真实单侧尾概率是 0.05。
若误把 \(1/12\) 当成标准差，就会得到假界 \(25/729\approx0.0343<0.05\)，
立即与事实矛盾。出现“上界小于真值”时，应先检查单位和参数化。

### 与 Markov 的比较

对均值为 1 的指数分布，\(P(X\ge4)=e^{-4}\approx0.0183\)。
Markov 给 \(1/4\)；由于 \(\sigma=1\)，Chebyshev 给

\[
P(X\ge4)\le P(|X-1|\ge3)\le1/9.
\]

两者都正确，Chebyshev 在此更紧，但离真值仍远。
通用界利用的信息少，不能期待它替代精确尾分布。

## 11.4 Jensen：凸函数的期望顺序

若 \(g\) 是凸函数，且 \(X\) 与 \(g(X)\) 可积，则

\[
\boxed{g(E[X])\le E[g(X)]}.
\]

证明利用凸函数在 \(\mu=E[X]\) 处存在一条支撑线：
存在斜率 \(m\)，使对所有 \(x\)，

\[
g(x)\ge g(\mu)+m(x-\mu).
\]

代入 \(X\) 并取期望，右边成为 \(g(\mu)+m(E[X]-\mu)=g(\mu)\)，即得结论。
若 \(g\) 严格凸且 \(X\) 非退化，通常不等式严格。

最重要的例子是 \(g(x)=x^2\)：

\[
E[X]^2\le E[X^2],
\]

差额 \(E[X^2]-E[X]^2\) 正是方差。
例如 \(X\) 等可能取 0、2，则 \(E[X]=1\)、\(E[X^2]=2\)，Jensen 间隙为 1。

对凹函数，方向反过来：\(E[g(X)]\le g(E[X])\)。
若效用函数 \(u\) 严格凹，则

\[
E[u(W)]<u(E[W])
\]

对非退化财富 \(W\) 成立。这表示在相同均值下，确定财富比风险财富有更高效用，
为风险厌恶提供了精确表述。

## 11.5 Boole 与 Bonferroni：并事件的截断界

对任意事件 \(A_1,\ldots,A_n\)，

\[
\boxed{P\left(\bigcup_{i=1}^nA_i\right)\le\sum_{i=1}^nP(A_i)}.
\]

这叫 Boole 不等式或次可加性。
证明可用首次出现分解：把并集拆成互斥事件

\[
B_i=A_i\setminus(A_1\cup\cdots\cup A_{i-1}).
\]

由于 \(B_i\subset A_i\)，

\[
P(\cup A_i)=\sum_iP(B_i)\le\sum_iP(A_i).
\]

不需要独立性。重叠越多，直接相加重复计数越多，上界就越松。

令 \(S_1=\sum_iP(A_i)\)、\(S_2=\sum_{i<j}P(A_i\cap A_j)\)。
容斥截断还给出 Bonferroni 下界

\[
S_1-S_2\le P(\cup A_i)\le S_1.
\]

四骰至少一个 6 的例子中，

\[
S_1=4/6,\qquad S_2=\binom42/36=1/6,
\]

精确概率为 \(1-(5/6)^4\)，确实位于 \(1/2\) 与 \(2/3\) 之间。
若截断下界为负，应把它裁成 0，因为概率天然非负。

## 11.6 从 Chebyshev 到弱大数定律

设 \(X_1,X_2,\ldots\) 独立同分布，均值为 \(\mu\)，方差为 \(\sigma^2<\infty\)。
样本均值

\[
\bar X_n=\frac1n\sum_{i=1}^nX_i
\]

满足

\[
E[\bar X_n]=\mu,
\qquad \operatorname{Var}(\bar X_n)=\sigma^2/n.
\]

第二式使用独立性消除交叉协方差。对任意 \(\varepsilon>0\)，Chebyshev 给出

\[
P(|\bar X_n-\mu|\ge\varepsilon)
\le\frac{\sigma^2}{n\varepsilon^2}\to0.
\]

因此 \(\bar X_n\) 依概率收敛到 \(\mu\)，这就是有限方差版本的弱大数定律。

样本均值标准差为 \(\sigma/\sqrt n\)。
若要把典型统计误差减半，样本量需增至四倍。
这个 \(1/\sqrt n\) 律是模拟与抽样精度的基础，但 Chebyshev 上界通常远松于实际误差，
不能把它当作最优置信区间。

第 25–26 章会系统比较依分布、依概率和几乎必然收敛，并讨论更强的大数定律。
本章只需掌握证明链：非负性给 Markov，平方给 Chebyshev，方差缩放给弱律。

## 11.7 机器通道：紧度、假界与精确夹逼

Python 文件 `examples/python/11_inequalities.py` 用有理数检查 Markov 等号分布：

```python
mu, a = Fraction(2), Fraction(4)
p = mu / a
assert p * a == mu
assert p == mu / a
```

这里 \(P(X=a)=p\)、\(P(X=0)=1-p\)，所以均值与尾概率都恰为 \(\mu/a\)。
等号验证说明该通用界没有无损改进空间。

标准差陷阱的检查为：

```python
bad_k = Fraction(45, 100) / Fraction(1, 12)
bad_bound = 1 / bad_k**2
assert bad_bound == Fraction(25, 729) < Fraction(5, 100)
```

程序不是验证错误公式“可用”，而是验证它确实低于真值，从而形成可执行的反例警报。

Julia 文件 `examples/julia/11_inequalities.jl` 用固定种子观察两点分布贴近 Markov 等号：

```julia
p = mu / a
X = [rand() < p ? a : 0.0 for _ in 1:300_000]
@assert abs(mean(X) - mu) < 0.03
@assert abs(count(>=(a), X) / length(X) - p) < 0.004
```

等号本身由两点分布的代数给出，模拟仅检查实现和数量级。
文件另对弱大数界做固定种子频率审计，不把有限试验当成收敛证明。

Lean 文件 `examples/lean/Probability/Ch11Inequalities.lean` 固定精确界和 Jensen 间隙：

```lean
example : (25 : ℚ) / 729 < 5 / 100 := by norm_num
example : (2 : ℚ) - 1 ^ 2 = 1 := by norm_num
example : (1 : ℚ) / (10 ^ 5 * (1 / 10) ^ 2) = 1 / 1000 := by norm_num
```

三例分别是假界反例、二次 Jensen 间隙和弱律上界的数值实例。
一般不等式证明在正文完成，Lean 负责防止数值锚点写错。

## 11.8 本章要点

1. 仅知均值不能控制一般变量的尾部；非负性或二阶矩提供额外杠杆。
2. Markov 界 \(P(X\ge a)\le E[X]/a\) 可由两点分布取等号。
3. Chebyshev 界以 \(\sigma^2/t^2\) 衰减，代入时必须区分标准差和方差。
4. Jensen 来自凸函数支撑线；二次情形的间隙就是方差。
5. Boole 不需要独立性；Bonferroni 是容斥的截断夹逼。
6. 弱大数定律由 \(\operatorname{Var}(\bar X_n)=\sigma^2/n\) 与 Chebyshev 直接得到。
7. 通用上界不等于精确概率，固定种子模拟也不等于收敛证明。

*对应示例：`examples/lean/Probability/Ch11Inequalities.lean`、
`examples/julia/11_inequalities.jl`、
`examples/python/11_inequalities.py`。*

---

上一章：[10 一元随机变量变换](10-transformations.md) · 下一章：[12 微分恒等式](12-differentiating.md)
