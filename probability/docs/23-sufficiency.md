# 第 23 章 充分统计量与数据简化

## 23.1 为什么要简化数据

一个容量为 $n$ 的样本是

$$X=(X_1,\dots,X_n).$$

直接保留全部原始值当然信息最多，但统计分析通常希望用更少的数概括样本。例如：

- Bernoulli 试验中只记录成功次数；
- Poisson 样本中只记录总和；
- 正态样本中记录样本均值和样本方差；
- $U(0,\theta)$ 样本中只记录最大值。

问题是：这种简化是否丢失了关于未知参数的信息？

**充分统计量**给出的答案不是“压缩后完全等于原始数据”，而是一个更精确的条件：给定统计量后，样本的条件分布不再依赖未知参数。换句话说，一旦知道充分统计量，原始数据中剩余的随机性不能再提供关于该参数的参数族内信息。

本章按以下层级展开：

1. 用条件分布定义充分性；
2. 用 Neyman–Fisher 因子分解快速判定；
3. 在 Bernoulli、Poisson、正态、均匀模型中计算；
4. 引入最小充分、完备、辅助统计量和 Basu 定理；
5. 用 Rao–Blackwell 定理说明为什么充分性可降低估计量方差。

本章的机器材料包括 Lean 精确有限证明、Prolog 全枚举、Python 精确分数/固定种子模拟以及 Julia 独立审计。

## 23.2 统计模型

设样本 $X$ 的联合分布属于参数族

$$\mathcal P=\{P_\theta:\theta\in\Theta\}.$$

离散模型中写联合概率质量函数

$$p_\theta(x)=P_\theta(X=x);$$

连续模型中写联合密度

$$f_\theta(x).$$

二者可以统一写成关于公共参考测度的密度。若模型没有公共参考测度，或不同 $\theta$ 的支撑随参数剧烈变化，因子分解定理的严格表述需要额外注意；本章的均匀模型把支撑指标函数显式写入密度，正是为了避免这个坑。

统计量 $T(X)$ 是不依赖未知参数的可测函数。注意“有用”不是充分性的定义；充分性是一个关于整个条件分布的性质。

## 23.3 充分性的条件分布定义

称统计量 $T$ 对 $\theta$ 充分，如果对每个可观测样本 $x$ 和每个可能的统计量值 $t$ ，条件分布

$$P_\theta(X=x\mid T(X)=t)$$

都不依赖 $\theta$ （在条件事件有正概率时可逐点解释；一般模型中解释为条件分布的一个版本对所有 $\theta$ 相同）。

这个定义可以换一种信息语言：

- 观察到 $T=t$ 后，再知道完整样本 $X=x$ ；
- 若条件分布不含 $\theta$ ，则这部分额外数据不能帮助区分不同 $\theta$ ；
- 因而 $T$ 已包含样本中关于 $\theta$ 的全部信息。

这里的“信息”是相对于指定参数族而言的。同一个统计量可能：

- 对估计 $p$ 充分；
- 对检查模型是否为 Bernoulli 不充分；
- 对模型外的异常值检测不充分。

## 23.4 Bernoulli：成功次数为什么充分

设

$$X_i\stackrel{iid}{\sim}\operatorname{Bernoulli}(p),$$

样本和为

$$T=\sum_{i=1}^nX_i.$$

任取二进制向量 $x=(x_1,\dots,x_n)$ ，联合似然为

$$p_p(x) =\prod_{i=1}^np^{x_i}(1-p)^{1-x_i} =p^{T(x)}(1-p)^{n-T(x)}.$$

给定 $T=t$ ，共有 $\binom nt$ 个样本向量，每个向量的联合概率都相同：

$$p^t(1-p)^{n-t}.$$

因此

$$\boxed{ P_p(X=x\mid T=t)=\frac1{\binom nt}, \qquad T(x)=t. }$$

这是一个在所有 $t$ 个位置等可能放置成功数的均匀分布，完全不依赖 $p$ 。

Prolog 对 $n=4$ 穷举所有二进制样本，并对多个 $p$ 验证该条件概率：

```prolog
cond(N, P, X, T, C) :-
    bits(N, X), sum_(X, T),
    lik(X, P, L),
    findall(L2, (bits(N, Y), sum_(Y, T), lik(Y, P, L2)), Ls),
    sum_(Ls, Tot),
    C is L / Tot.

check_cond(N, P, T) :-
    forall((between(0, N, I), between(1, 2, K),
            pattern(N, I, K, X)),
           (cond(N, P, X, T2, C),
            T2 =:= T,
            C =:= 1 / binom(N, T))).
```

程序检查 $p\in\{1/3,1/2,3/4,1/97\}$ 。参数值变化很大，但给定成功次数后，每个模式的条件概率仍是 $1/\binom4t$ 。

Lean 对 $n=3$ 的 $T=1$ 情形做无小数证明。三个样本 $(1,0,0),(0,1,0),(0,0,1)$ 的似然都是

$$q=p(1-p)^2,$$

故条件概率为

$$\frac{q}{q+q+q}=\frac13.$$

对应代码为：

```lean
example (p : ℚ) (hp : p * (1 - p) ^ 2 ≠ 0) :
    lik3 p 1 0 0 / (lik3 p 1 0 0 + lik3 p 0 1 0 + lik3 p 0 0 1) = 1 / 3 := by
  set q : ℚ := p * (1 - p) ^ 2 with hq
  have hq' : q ≠ 0 := hp
  have h1 : lik3 p 1 0 0 = q := by simp only [hq, lik3, bern]; ring
  have h2 : lik3 p 0 1 0 = q := by simp only [hq, lik3, bern]; ring
  have h3 : lik3 p 0 0 1 = q := by simp only [hq, lik3, bern]; ring
  rw [h1, h2, h3]
  have hden : q + q + q = 3 * q := by ring
  rw [hden]
  field_simp [hq']
```

Python 用 `Fraction` 对 $n=4$ 全枚举，避免浮点掩盖参数约分：

```python
for p in (Fraction(1, 3), Fraction(1, 2),
          Fraction(3, 4), Fraction(1, 97)):
    for t in range(n + 1):
        support = [x for x in support if sum(x) == t]
        weights = [lik_bern(x, p) for x in support]
        total = sum(weights)
        for x, w in zip(support, weights):
            assert w / total == Fraction(1, comb(n, t))
```

### 23.4.1 部分和不充分

只看前两次试验的和

$$T'=X_1+X_2$$

并不充分，因为剩余试验仍携带关于 $p$ 的信息。例如

$$P_p(X_3=1\mid X_1=1)=p.$$

Lean 只验证这个比值：

```lean
example (p : ℚ) (hp : p ≠ 0) : (p * p) / p = p := by
  field_simp
```

而 Python 直接展示 $p=1/3$ 与 $p=3/4$ 下条件概率不同。知道前两次结果后，后两次并不是与参数无关的均匀噪声。

## 23.5 Neyman–Fisher 因子分解

若样本的联合密度或概率质量函数可以写成

$$\boxed{ f_\theta(x)=g_\theta(T(x))\,h(x), }$$

其中：

- $g_\theta(t)$ 可以依赖参数，但只能通过 $T(x)$ 依赖样本；
- $h(x)$ 可以依赖样本，但不能依赖 $\theta$ ；

则 $T$ 是 $\theta$ 的充分统计量。反过来，在通常正则条件下，充分统计量也给出这种分解。

离散情形最直观：给定 $T=t$ ，所有使 $T(x)=t$ 的样本有相同参数因子 $g_\theta(t)$ ，条件概率中它被约掉：

$$P_\theta(X=x\mid T=t) =\frac{g_\theta(t)h(x)} {\sum_{y:T(y)=t}g_\theta(t)h(y)} =\frac{h(x)} {\sum_{y:T(y)=t}h(y)}.$$

连续情形的严格证明需要条件密度和参考测度，但直觉相同：参数因子在条件密度的分子分母中约去。

Lean 对 $n=3$ Bernoulli 模型验证完整因子分解：

```lean
example (p : ℚ) (a b c : Fin 2) :
    lik3 p a b c =
      p ^ (a.val + b.val + c.val) *
        (1 - p) ^ (3 - (a.val + b.val + c.val)) := by
  fin_cases a <;> fin_cases b <;> fin_cases c <;>
    simp only [lik3, bern] <;> ring
```

这里 $h(x)\equiv1$ ，参数完全通过三元组中 1 的个数进入。

因子分解是最常用的充分性判定工具，但它要求把支撑集也写入因子。若某个 $\theta$ 下样本概率为零而另一个 $\theta$ 下非零，这个差异本身就携带强信息，不能漏写。

## 23.6 Poisson：总和条件分布是固定多项分布

设

$$X_i\stackrel{iid}{\sim}\operatorname{Poisson}(\lambda).$$

联合似然为

$$p_\lambda(x) =\prod_{i=1}^n\frac{e^{-\lambda}\lambda^{x_i}}{x_i!} =e^{-n\lambda}\lambda^{\sum_ix_i} \prod_{i=1}^n\frac1{x_i!}.$$

因此样本和

$$T=\sum_iX_i$$

充分。

更具体地，独立 Poisson 变量之和满足

$$T\sim\operatorname{Poisson}(n\lambda).$$

给定 $T=t$ ，条件概率为

$$\begin{aligned} P_\lambda(X_1=x_1,\dots,X_n=x_n\mid T=t) &= \frac{\prod_i e^{-\lambda}\lambda^{x_i}/x_i!} {e^{-n\lambda}(n\lambda)^t/t!}\\ &= \frac{t!}{x_1!\cdots x_n!} \left(\frac1n\right)^{x_1}\cdots \left(\frac1n\right)^{x_n}. \end{aligned}$$

这是

$$\operatorname{Multinomial}\left(t;\frac1n,\dots,\frac1n\right),$$

与 $\lambda$ 完全无关。

Python 对 $n=3,t=5$ 枚举所有非负整数三元组，并用精确分数验证：

```python
cells = [(a, b, 5 - a - b)
         for a in range(6) for b in range(6 - a)]
weights = [Fraction(prod(factorial(v) for v in c), 1)
           for c in cells]
denom = sum(Fraction(1, math.factorial(v)) for v in chain(*cells))
for c in cells:
    cond = (Fraction(1, prod(math.factorial(v) for v in c)) /
            (Fraction(1) / math.factorial(5))) / 3 ** 5
```

最终每个三元组的概率为

$$\frac{5!}{x_1!x_2!x_3!}\frac1{3^5}.$$

Julia 从另一方向审计：似然比只通过样本和依赖数据。若两个样本总和相同，它们的 Poisson 似然比为

$$\frac{p_\lambda(x)}{p_\lambda(y)} =\frac{\prod_i1/x_i!}{\prod_i1/y_i!},$$

不随 $\lambda$ 改变。

## 23.7 正态模型的两个充分统计量

### 23.7.1 方差已知时均值充分

若

$$X_i\stackrel{iid}{\sim}N(\mu,\sigma_0^2)$$

且 $\sigma_0^2$ 已知，则联合密度为

$$f_\mu(x) =(2\pi\sigma_0^2)^{-n/2} \exp\left[-\frac1{2\sigma_0^2}\sum_i(x_i-\mu)^2\right].$$

展开平方：

$$\sum_i(x_i-\mu)^2 =\sum_ix_i^2-2\mu\sum_ix_i+n\mu^2.$$

在固定已知 $\sigma_0^2$ 下，$\sum_ix_i^2$ 可进入 $h(x)$ ，参数只通过 $\sum_ix_i$ 或 $\bar X$ 进入。因此 $\bar X$ 对 $\mu$ 充分。

### 23.7.2 均值和方差都未知

若

$$X_i\stackrel{iid}{\sim}N(\mu,\sigma^2),\qquad(\mu,\sigma^2)\in\Theta,$$

联合密度为

$$f_{\mu,\sigma^2}(x) =(2\pi\sigma^2)^{-n/2} \exp\left[ -\frac1{2\sigma^2} \left(\sum_ix_i^2-2\mu\sum_ix_i+n\mu^2\right) \right].$$

此时一个数不够，因为需要同时确定位置和尺度。二维统计量

$$\boxed{ T(X)=\left(\sum_iX_i,\sum_iX_i^2\right) }$$

充分。等价地，也可使用

$$(\bar X,S^2)$$

作为充分统计量，因为这两个向量之间存在一一可测变换：

$$\bar X=\frac1n\sum_iX_i, \qquad S^2=\frac{\sum_iX_i^2-n\bar X^2}{n-1}.$$

Python 用两个不同样本 `[1,5,6]` 与 `[2,3,7]` 说明充分统计量相等意味着似然处处相等：

```python
assert (sum(a), sum(x * x for x in a)) == \
       (sum(b), sum(x * x for x in b))
for mu, var in [(0.0, 1.0), (2.5, 4.0), (-3.0, 0.4)]:
    assert loglik_normal(a, mu, var) == loglik_normal(b, mu, var)
```

它们的逐点排列不同，但在整个正态参数族中似然完全相同。

Julia 独立验证：只要两个样本的一阶和与二阶和相同，任意 $\mu$ 与 $\sigma^2$ 下对数似然差为零。

## 23.8 均匀模型：最大值与支撑指标

设

$$X_i\stackrel{iid}{\sim}U(0,\theta),\qquad \theta>0.$$

联合密度不能只写 $1/\theta^n$ ，还必须写支撑条件：

$$f_\theta(x) =\theta^{-n}\mathbf 1\{0\le x_i\le\theta,\ i=1,\dots,n\}.$$

因为所有 $x_i\le\theta$ 等价于

$$M(x)=\max_i x_i\le\theta,$$

所以

$$f_\theta(x) =\theta^{-n}\mathbf 1\{M(x)\le\theta\} \mathbf 1\{0\le\min_i x_i\}.$$

故最大值

$$X_{(n)}=\max_iX_i$$

对 $\theta$ 充分。

最大值的 CDF 为

$$P_\theta(X_{(n)}\le m) =P_\theta(X_1\le m,\dots,X_n\le m) =\left(\frac m\theta\right)^n, \qquad 0\le m\le\theta.$$

给定最大值 $M=m$ ，其余点在 $[0,m]$ 中；缩放为 $X_i/m$ 后，条件分布不再依赖 $\theta$ 。Python 比较不同 $\theta$ 下 $X_i/M$ 的经验分布：

```python
theta_alt = 17.0
A = rng.uniform(0, theta_alt, size=(N, n))
rA = A[:, :n - 1] / A[:, [n - 1]]
for q in (0.25, 0.5, 0.75):
    assert abs(np.mean(r0 <= q) - np.mean(rA <= q)) < 0.01
```

这只是模拟审计；条件分布不依赖 $\theta$ 的原因是尺度变换消去了参数。

### 23.8.1 样本均值不充分

若两个样本有相同均值但最大值不同，则存在 $\theta$ 使一个样本可能而另一个不可能。取

$$x=(1,5),\qquad y=(2,4),$$

二者均值均为 3，但最大值不同。当

$$5<\theta<6$$

时，$x$ 的似然为 $\theta^{-2}>0$ ，而含 6 的另一个样本似然为 0。仅知道均值无法区分这种支撑差异，所以均值不充分。

## 23.9 最小充分统计量

充分统计量可能包含冗余。对 Bernoulli 模型，$\sum_iX_i$ 充分；原始向量 $X$ 也充分，但显然没有做任何压缩。

称充分统计量 $T$ 为**最小充分统计量**，如果它是任何其他充分统计量的函数。它只保留充分性所必需的划分，不再多切分样本空间。

常用似然比准则：若关系

$$x\sim y \iff \frac{f_\theta(x)}{f_\theta(y)} \text{ 作为 }\theta\text{ 的函数为常数}$$

构成良好等价关系，则把样本映射到其等价类的统计量最小充分。直观地说：

- 两个样本在所有参数值下似然比都相同，就无法通过参数族区分它们；
- 若似然比随 $\theta$ 改变，它们必须被最小充分统计量分开。

对 Bernoulli，

$$\frac{p_p(x)}{p_p(y)} =p^{T(x)-T(y)}(1-p)^{(n-T(x))-(n-T(y))}.$$

只有 $T(x)=T(y)$ 时，该比值才对所有 $p$ 恒为常数。因此样本和最小充分。

Lean 用三个 $p$ 值做有限审计：

```lean
example : ∀ p ∈ ({1 / 5, 1 / 2, 4 / 5} : Finset ℚ),
    lik3 p 1 0 0 / lik3 p 0 1 0 = 1 := by
  intro p hp
  simp only [Finset.mem_insert, Finset.mem_singleton] at hp
  rcases hp with rfl | rfl | rfl <;> norm_num [lik3, bern]

example : lik3 (1 / 5) 1 0 0 / lik3 (1 / 5) 1 1 0 = 4 ∧
    lik3 (1 / 2) 1 0 0 / lik3 (1 / 2) 1 1 0 = 1 ∧
    lik3 (4 / 5) 1 0 0 / lik3 (4 / 5) 1 1 0 = 1 / 4 := by
  norm_num [lik3, bern]
```

同和样本的似然比恒为 1；不同和样本的比值 $(1-p)/p$ 随 $p$ 改变。

## 23.10 辅助统计量与完备性

### 23.10.1 辅助统计量

若统计量 $A(X)$ 的分布不依赖 $\theta$ ，称其为辅助统计量。辅助统计量不直接提供参数位置，但可能描述实验所提供的信息量。

典型例子是位置模型 $X_i=\theta+\varepsilon_i$ 中的样本极差

$$X_{(n)}-X_{(1)}.$$

平移 $\theta$ 不改变差值，因此其分布与 $\theta$ 无关。

“辅助”不等于“无用”。在条件推断中，辅助统计量常用来选择合适的条件参照系。

### 23.10.2 完备性

统计量 $T$ 称为完备的，如果对任意可测函数 $g$ ，

$$E_\theta[g(T)]=0\quad\text{对所有 }\theta\in\Theta$$

都蕴含

$$P_\theta(g(T)=0)=1\quad\text{对所有 }\theta\in\Theta.$$

换句话说，$T$ 的分布族中不存在非退化的零均值函数。

完备性不是充分性本身，也不是“统计量很好”的泛称；它是一个关于分布族线性跨度的性质。

Bernoulli 样本和 $T\sim\operatorname{Bin}(n,p)$ 是完备的。若对所有 $p\in[0,1]$ ，

$$E_p[g(T)] =\sum_{t=0}^n g(t)\binom nt p^t(1-p)^{n-t}=0,$$

乘以 $(1-p)^{-n}$ 后得到关于

$$r=\frac p{1-p}$$

的 $n$ 次多项式恒为零，因此所有系数 $g(t)\binom nt=0$ 。Python 构造从 $g(0),\dots,g(n)$ 到多项式系数的 Vandermonde 型矩阵并检查满秩：

```python
mat = np.array([[comb(t, j) * comb(n - t, n - j) / comb(n, j)
                 for j in range(n + 1)]
                for t in range(n + 1)], dtype=float)
assert abs(np.linalg.det(mat)) > 1e-10
```

### 23.10.3 充分但不完备的例子

$T=(X_1,X_2)$ 在 Bernoulli 模型中充分，因为它保留了完整样本的前两维——更准确地说，完整样本当然充分，而任意保留全部原始数据的表示也充分——但它不是最小且不完备。例如

$$g(T)=X_1-X_2$$

对所有 $p$ 都满足

$$E_p[X_1-X_2]=p-p=0,$$

但 $X_1-X_2$ 并非恒为零。

更微妙的是，最小充分统计量也不一定完备。在模型

$$X_i\stackrel{iid}{\sim}N(\theta,\theta^2)$$

中，似然通过 $(\sum_iX_i,\sum_iX_i^2)$ 依赖数据，因而二维统计量最小充分；但程序构造函数

$$g(T)=\frac{n}{n+1}\bar X^2-S^2,$$

其期望对所有 $\theta$ 为零。这说明“最小充分”和“完备”是两种不同性质。

## 23.11 Basu 定理

Basu 定理：若 $T$ 是完备充分统计量，$A$ 是辅助统计量，则在通常正则条件下，$T$ 与 $A$ 独立。

证明思想很简洁。对任意事件 $B$ ，令

$$g(t)=P_\theta(A\in B\mid T=t)-P_\theta(A\in B).$$

因为 $T$ 充分，条件概率不依赖 $\theta$ ，可定义固定函数 $g(T)$ 。又因为 $A$ 辅助，$P_\theta(A\in B)$ 不依赖 $\theta$ 。全期望公式给出

$$E_\theta[g(T)]=0$$

对所有 $\theta$ 成立。完备性说明 $g(T)=0$ 几乎必然，因此条件概率等于无条件概率，即独立。

正态模型

$$X_i\sim N(\mu,1)$$

中，$\bar X$ 是完备充分统计量，而 $S^2$ 的分布不依赖 $\mu$ ，故二者独立。这也从信息论角度解释了第 22 章 Helmert 证明的独立性。

均匀模型 $U(0,\theta)$ 中，最大值充分且完备，而最小值与最大值之比 $X_{(1)}/X_{(n)}$ 的分布不依赖尺度参数 $\theta$ ，因而二者独立。Python 用固定种子模拟检查：

```python
ind = stats.chi2_contingency(table)[1]
assert ind > 0.05
for a, b in bins_a:
    ratio_in_bin = ratio[(a <= mn) & (mn < b)] / M[(a <= mn) & (mn < b)]
    assert stats.epps_singleton_2samp(ratio, ratio_in_bin).pvalue > 0.01
```

模拟只用于展示；定理本身依赖完备充分性与辅助性。

## 23.12 Rao–Blackwell 化

设目标是估计参数函数 $\tau(\theta)$ ，统计量 $T$ 充分，而 $\delta(X)$ 是一个无偏估计量。定义条件期望估计量

$$\delta^*(T)=E_\theta[\delta(X)\mid T].$$

因为 $T$ 充分，这个条件期望不依赖 $\theta$ ，所以它确实是统计量。由塔性质，

$$E_\theta[\delta^*(T)] =E_\theta[E_\theta[\delta(X)\mid T]] =E_\theta[\delta(X)] =\tau(\theta).$$

因此无偏性保留。

由全方差公式，

$$\operatorname{Var}_\theta(\delta(X)) = E_\theta[\operatorname{Var}_\theta(\delta(X)\mid T)] + \operatorname{Var}_\theta(E_\theta[\delta(X)\mid T]).$$

右边第一项非负，所以

$$\boxed{ \operatorname{Var}_\theta(\delta^*(T)) \le \operatorname{Var}_\theta(\delta(X)). }$$

只要 $\delta$ 不是已经几乎必然等于 $T$ 的函数，通常严格改进。这就是 Rao–Blackwell 定理。

### 23.12.1 Bernoulli 估计 $p$

只用第一次试验估计 $p$ ：

$$\delta(X)=X_1.$$

它无偏，但给定成功总次数 $T=t$ ，

$$E_p[X_1\mid T=t]=\frac tn.$$

改进后的估计量为

$$\delta^*(T)=\frac{T}{n}=\bar X.$$

方差从

$$p(1-p)$$

降为

$$\frac{p(1-p)}n.$$

Lean 验证方差账：

```lean
example (p n : ℚ) (hn : n ≠ 0) :
    n * (p * (1 - p)) / n ^ 2 = p * (1 - p) / n := by
  field_simp
```

Julia 对 $n=5,p=1/5$ 做固定种子模拟：

```julia
X = rand(5, N) .< p
@assert abs(var(X[1, :]) - p * (1 - p)) < 0.003
@assert abs(var(mean(X, dims=1)) - p * (1 - p) / 5) < 0.001
```

### 23.12.2 Poisson 估计 $e^{-\lambda}$

估计量

$$\delta(X)=\mathbf 1\{X_1=0\}$$

无偏估计 $e^{-\lambda}$ 。给定总和 $T=t$ ，有

$$P_\lambda(X_1=0\mid T=t) =\left(1-\frac1n\right)^t.$$

因此 Rao–Blackwell 估计量为

$$\delta^*(T)=\left(1-\frac1n\right)^T.$$

### 23.12.3 均匀尺度估计

对 $U(0,\theta)$ ，矩估计 $2\bar X$ 无偏，但它不是充分统计量的函数。给定最大值 $X_{(n)}=m$ 条件化后得到

$$E[2\bar X\mid X_{(n)}=m] =\frac{n+1}{n}m.$$

该估计量仍无偏，方差从 $2\bar X$ 的

$$\frac{\theta^2}{3n}$$

降为

$$\frac{\theta^2}{n(n+2)}.$$

这说明数据简化不是为了“少存几个数”而已；在无偏估计问题中，对充分统计量条件化可严格降低方差。

## 23.13 为什么这一章为 UMVU 做准备

Rao–Blackwell 定理说明：任何无偏估计量都应对充分统计量条件化。但如果充分统计量还完备，则无偏估计量至多有一个是它的函数。

设 $h_1(T)$ 和 $h_2(T)$ 都无偏估计 $\tau(\theta)$ ，则

$$E_\theta[h_1(T)-h_2(T)]=0$$

对所有 $\theta$ 成立。完备性推出

$$h_1(T)=h_2(T)$$

几乎必然。因此在完备充分统计量存在时，Rao–Blackwell 化得到的无偏估计量是唯一的，并将在第 34 章与 Lehmann–Scheffé 定理、UMVU/UMVUE 理论连接。

本章只需先记住层级：

1. **充分**：条件分布不含参数；
2. **最小充分**：不保留可通过似然比合并的冗余；
3. **完备**：没有非退化零期望函数；
4. **Rao–Blackwell**：对充分统计量条件化不降劣无偏估计；
5. **Lehmann–Scheffé**：完备充分 + 无偏条件期望给出最优无偏估计。

## 23.14 常见误区

1. **误区：统计量维数低就充分。**
   均匀模型中均值也是一维，但不充分；它看不出支撑上界。

2. **误区：充分统计量等于原始数据。**
   Bernoulli 成功次数充分，是因为给定成功次数后各位置等可能，而不是因为成功次数逐点复原样本。

3. **误区：最小充分必然完备。**
   $N(\theta,\theta^2)$ 中最小充分二维统计量并不完备。

4. **误区：辅助统计量没有用处。**
   辅助统计量不提供参数位置，但可描述信息量、用于条件推断，并通过 Basu 定理帮助证明独立性。

5. **误区：因子分解可以忽略支撑。**
   支撑依赖参数时，指标函数往往是最关键的 $g_\theta(T(x))$ 。

6. **误区：模拟能证明充分性。**
   本章模拟只验证条件分布的实现或展示方差改进；定义、因子分解和条件概率代数才是证明。

## 23.15 本章要点

1. 充分统计量的定义是给定它以后样本的条件分布不依赖参数。
2. Neyman–Fisher 因子分解把联合密度写成参数因子 $g_\theta(T(x))$ 与无参数因子 $h(x)$ 。
3. Bernoulli 成功次数给定后的条件分布是所有成功位置上的均匀分布。
4. Poisson 总和给定后的条件分布是固定概率多项分布。
5. 正态双参数模型的充分统计量是 $(\sum X_i,\sum X_i^2)$ ，等价于 $(\bar X,S^2)$ 。
6. $U(0,\theta)$ 的最大值充分，支撑指标必须显式保留。
7. 最小充分统计量按“似然比是否随参数变化”合并样本。
8. 完备性表示不存在非退化零均值函数；它不同于充分性或最小充分性。
9. 完备充分统计量与辅助统计量独立，这是 Basu 定理。
10. Rao–Blackwell 化保留无偏性且通过全方差公式降低方差，是后续最优无偏估计理论的接口。

*对应示例：`examples/lean/Probability/Ch23Sufficiency.lean`、`examples/julia/23_sufficiency.jl`、`examples/python/23_sufficiency.py`、`examples/prolog/23_sufficiency.pl`。*

---

上一章：[22 随机样本与抽样分布](22-sampling-distributions.md) · 下一章：[24 差分方程与 Markov 链](24-markov-chains.md)
