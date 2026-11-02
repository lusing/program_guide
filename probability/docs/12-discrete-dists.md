# 12 离散分布族

离散分布不是一张需要背诵的 pmf 表。每个分布都在回答一种计数问题：一次试验是否成功、固定次数中成功几次、首次成功要等多久、第 \(r\) 次失败前积累多少成功，以及大量独立稀有事件共发生几次。抓住试验机制，pmf、矩和极限关系就会一起出现。

本章统一约定：求和范围没有写出时，就是该分布的整个支撑集；\(0<p<1\)，\(q=1-p\)。“截断和接近 1”只是数值审计，不是无穷级数归一化的证明。

## 12.1 Bernoulli：一次试验的最小模型

若一次试验只有成功和失败两种结果，令成功时 \(X=1\)，失败时 \(X=0\)，且 \(P(X=1)=p\)，则

\[
X\sim\operatorname{Bernoulli}(p),\qquad
P(X=x)=p^x(1-p)^{1-x},\quad x\in\{0,1\}.
\]

直接由定义得到

\[
E[X]=0(1-p)+1p=p,
\]

\[
E[X^2]=p,\qquad
\operatorname{Var}(X)=p-p^2=p(1-p).
\]

这里用了 \(X^2=X\)，因为 \(X\) 只取 0 和 1。方差在 \(p=1/2\) 时最大，在 \(p\to0\) 或 \(p\to1\) 时趋于 0：结果越确定，波动越小。

Python 文件 `examples/python/12_discrete_dists.py` 用有理数检查这两笔账：

```python
p = Fraction(1, 3)
assert 1 * p + 0 * (1 - p) == p
assert (1 - p) ** 2 * p + p ** 2 * (1 - p) == p * (1 - p)
```

这不是用程序定义 Bernoulli 分布，而是把定义求和化简后的恒等式固定成回归测试。

## 12.2 二项分布：固定次数中的成功数

进行 \(n\) 次独立试验，每次成功概率都是 \(p\)。一个有 \(k\) 次成功的指定序列，其概率为 \(p^kq^{n-k}\)；成功位置有 \(\binom nk\) 种，所以

\[
X\sim\operatorname{Bin}(n,p),\qquad
P(X=k)=\binom nkp^kq^{n-k},\quad k=0,\ldots,n.
\]

二项定理立即给出归一化：

\[
\sum_{k=0}^nP(X=k)=\sum_{k=0}^n\binom nkp^kq^{n-k}=(p+q)^n=1.
\]

### 用示性变量求矩

把 \(X\) 写成

\[
X=I_1+\cdots+I_n,
\]

其中 \(I_j\) 是第 \(j\) 次试验成功的指示变量。期望线性性不需要独立性，故

\[
E[X]=np.
\]

计算方差时才使用独立性：独立随机变量之和的方差等于方差之和，因此

\[
\operatorname{Var}(X)=np(1-p).
\]

这条分解路线比直接求 \(\sum k^2P(X=k)\) 更能说明公式来自哪里。第 16 章还会用参数求导独立推出相同结果。

Python 对 \(n=6,p=1/3\) 同时计算 pmf 求和与闭式：

```python
n = 6
pmf_bin = {k: Fraction(comb(n, k)) * p ** k * (1 - p) ** (n - k)
           for k in range(n + 1)}
assert sum(pmf_bin.values()) == 1
assert sum(k * pmf_bin[k] for k in range(n + 1)) == n * p == 2
assert sum(k * k * pmf_bin[k] for k in range(n + 1)) - (n * p) ** 2 \
    == n * p * (1 - p)
```

三个断言分别审计归一化、均值和方差；所有计算均为精确有理数。

### 多项分布与二项边际

若每次试验有 \(m\) 种互斥结果，概率为 \(p_1,\ldots,p_m\)，在 \(n\) 次独立试验中第 \(i\) 类出现 \(x_i\) 次，则

\[
P(X_1=x_1,\ldots,X_m=x_m)
=\frac{n!}{x_1!\cdots x_m!}\prod_{i=1}^mp_i^{x_i},
\qquad \sum_i x_i=n.
\]

系数记录同一计数模式对应多少条有顺序的试验序列。只观察第 \(i\) 类，把其余类别合并为“非 \(i\)”，便有 \(X_i\sim\operatorname{Bin}(n,p_i)\)。不同分量一般不独立，因为它们受 \(\sum_iX_i=n\) 约束。

## 12.3 几何分布：首次成功的等待时间

设 \(T\) 是首次成功所需的试验次数。第 \(t\) 次才首次成功，意味着前 \(t-1\) 次失败、最后一次成功，故

\[
P(T=t)=q^{t-1}p,\qquad t=1,2,\ldots.
\]

由几何级数，

\[
\sum_{t=1}^{\infty}q^{t-1}p=p\frac1{1-q}=1.
\]

尾部尤其简单：

\[
P(T>t)=P(\text{前 }t\text{ 次全失败})=q^t.
\]

### 无记忆性

对非负整数 \(s,t\)，

\[
P(T>s+t\mid T>s)
=\frac{q^{s+t}}{q^s}=q^t=P(T>t).
\]

已知前 \(s\) 次失败后，剩余等待时间的分布不变。这不表示各次试验“会补偿坏运气”，而恰恰是独立试验的结果：过去失败不改变下一次成功概率。

用首步分解求均值。设 \(\mu=E[T]\)，首次成功则以 1 次结束；首次失败则已经花去 1 次，剩余期望仍为 \(\mu\)：

\[
\mu=p\cdot1+q(1+\mu).
\]

所以 \(\mu=1/p\)。类似地对二阶矩作首步分解，或利用第 16 章的微分恒等式，可得

\[
\operatorname{Var}(T)=\frac{q}{p^2}.
\]

Python 截断到 60 项审计 \(p=1/3\) 的归一化和均值：

```python
N = 60
pmf_geo = [p * (1 - p) ** (m - 1) for m in range(1, N + 1)]
assert abs(float(sum(pmf_geo)) - 1.0) < 1e-10
mu_geo = sum(m * pmf_geo[m - 1] for m in range(1, N + 1))
assert abs(float(mu_geo) - 3.0) < 5e-9
```

被舍去的归一化尾部恰为 \(q^{60}\)。这里容差用于截断近似，真正的均值结论由上一步代数证明给出。

### 方差的完整推导

对二阶矩同样做首步分解。设 \(m_2=E[T^2]\)。首次成功（概率 \(p\)）时 \(T=1\)；首次失败（概率 \(q\)）时 \(T=1+T'\)，其中 \(T'\) 与 \(T\) 同分布且与首步独立。于是

\[
m_2=p\cdot1+q\,E[(1+T')^2]=p+q\,(1+2\mu+m_2).
\]

移项得 \(p\,m_2=p+q+2q\mu=1+2q/p\)，故 \(m_2=(p+2q)/p^2=(2-p)/p^2\)。因此

\[
\operatorname{Var}(T)=m_2-\mu^2=\frac{2-p}{p^2}-\frac1{p^2}=\frac{1-p}{p^2}=\frac q{p^2}.
\]

一个数值感受：\(p=1/4\) 时均值 4、方差 \(0.75/0.0625=12\)，标准差约 3.46，与均值同量级——等待时间的波动非常大，“平均 4 次”远不等于“差不多 4 次”。

### 几何分布是唯一的离散无记忆分布

反过来，设 \(T\) 取值于 \(\{1,2,\dots\}\)，并满足 \(P(T>s+t)=P(T>s)P(T>t)\)（\(s,t\ge0\) 整数）。记 \(G(t)=P(T>t)\)，则 \(G(s+t)=G(s)G(t)\)。取 \(s=1\) 反复递推得 \(G(t)=G(1)^t\)。令 \(q=G(1)\)，便有 \(P(T>t)=q^t\)，恰好是几何分布。所以“离散时间的无记忆性”与“几何分布”是同一件事；第 13 章会看到连续时间的对应物是指数分布。

### Julia：用模拟审计均值与方差

`examples/julia/12_discrete_dists.jl` 的第一节直接按定义模拟等待：

```julia
function sim_geometric(p, trials)
    waits = zeros(Int, trials)
    for t in 1:trials
        n = 1
        while rand() > p
            n += 1
        end
        waits[t] = n
    end
    waits
end
G = sim_geometric(0.25, 200_000)
@assert abs(mean(G) - 4.0) < 0.02
@assert abs(var(G) - 0.75 / 0.25^2) < 0.2
```

`while rand() > p` 就是“这一次失败了，继续等”；跳出循环时成功，计数 \(n\) 即为 \(T\)。两条断言对拍 \(1/p=4\) 与 \(q/p^2=12\)；\(0.2\) 的方差容差考虑了 20 万样本下四阶矩较大带来的抽样误差。模拟只是证明实现没有写错，均值方差公式的依据是上面的首步分解。

## 12.4 负二项分布：等待第 \(r\) 次失败

不同资料会交换“成功/失败”以及“计数/等待次数”的口径。本章明确采用：**\(X\) 表示第 \(r\) 次失败出现前的成功次数，成功概率为 \(p\)**。

若 \(X=k\)，最后一次试验必须是第 \(r\) 次失败；此前 \(k+r-1\) 次中恰有 \(k\) 次成功和 \(r-1\) 次失败。因此

\[
P(X=k)=\binom{k+r-1}{k}p^kq^r,
\qquad k=0,1,2,\ldots.
\]

把过程分成 \(r\) 段：每段记录一次失败前的成功数。各段独立且同分布，均值均为 \(p/q\)，于是

\[
E[X]=\frac{rp}{q},
\qquad
\operatorname{Var}(X)=\frac{rp}{q^2}.
\]

当 \(r=1\) 时，\(X=T-1\)，其中 \(T\) 是上节的几何等待时间；这也解释了两种常见负二项参数化之间只差一个平移。

代码在 \(r=2,p=1/3\) 时得到 \(E[X]=1\)：

```python
r = 2
pmf_nb = [Fraction(comb(k + r - 1, k)) * p ** k * (1 - p) ** r
          for k in range(N)]
assert abs(float(sum(pmf_nb)) - 1.0) < 5e-9
mu_nb = sum(k * pmf_nb[k] for k in range(N))
assert abs(float(mu_nb) - 1.0) < 1e-7
```

负二项尾部比同参数几何尾部衰减慢，所以截断矩使用更宽的容差。

### 归一化与矩的另一条路：负指数的二项级数

归一化可由广义二项级数得到：对 \(|x|<1\)，\((1-x)^{-r}=\sum_{k\ge0}\binom{k+r-1}{k}x^k\)。取 \(x=p\)，则
\(\sum_k\binom{k+r-1}{k}p^kq^r=q^r(1-p)^{-r}=1\)。这个恒等式把“负二项”的名字解释清楚了：系数 \(\binom{k+r-1}{k}=(-1)^k\binom{-r}{k}\) 正是负指数 \(-r\) 的二项系数。

把 \(r\) 段拆开的做法也可以严格化。设 \(Y_1,\dots,Y_r\) 为各段的成功数，则 \(Y_j=T_j-1\)，\(T_j\) 是几何等待时间（成功/失败角色互换后，“成功”的概率为 \(q\)）：\(E[Y_j]=1/q-1=p/q\)，\(\operatorname{Var}(Y_j)=p/q^2\)（几何方差 \((1-q)/q^2\)）。各段独立，所以 \(X=\sum Y_j\) 的均值为 \(rp/q\)、方差为 \(rp/q^2\)。例如 \(r=3,p=0.7\) 时均值 \(3\cdot0.7/0.3=7\)，方差 \(3\cdot0.7/0.09\approx23.3\)，方差明显大于均值——这与 Poisson 的“方差等于均值”形成对比，是计数数据“过度离散”时选负二项而不是 Poisson 的原因。

### Julia：按定义模拟负二项

```julia
function sim_negbin(r, p, trials)
    ks = zeros(Int, trials)
    for t in 1:trials
        succ, fail = 0, 0
        while fail < r
            if rand() < p; succ += 1; else; fail += 1; end
        end
        ks[t] = succ
    end
    ks
end
NB = sim_negbin(3, 0.7, 200_000)
@assert abs(mean(NB) - 3 * 0.7 / 0.3) < 0.06
```

循环条件 `fail < r` 正是“直到第 \(r\) 次失败才停”；返回的 `succ` 是停止前累计的成功数，即本章定义的 \(X\)。断言核对均值 \(rp/q=7\)。注意模拟没有用 pmf，所以它独立地验证了 pmf 与矩公式所对应的试验机制。

## 12.5 Poisson：稀有事件的极限计数

若

\[
X\sim\operatorname{Poisson}(\lambda),\qquad \lambda>0,
\]

则

\[
P(X=k)=e^{-\lambda}\frac{\lambda^k}{k!},
\qquad k=0,1,2,\ldots.
\]

指数级数给出归一化：

\[
\sum_{k=0}^{\infty}e^{-\lambda}\frac{\lambda^k}{k!}
=e^{-\lambda}e^\lambda=1.
\]

均值可直接提出一项：

\[
E[X]=e^{-\lambda}\sum_{k=1}^{\infty}\frac{\lambda^k}{(k-1)!}
=\lambda e^{-\lambda}\sum_{j=0}^{\infty}\frac{\lambda^j}{j!}
=\lambda.
\]

同理 \(E[X(X-1)]=\lambda^2\)，所以

\[
E[X^2]=\lambda^2+\lambda,
\qquad
\operatorname{Var}(X)=\lambda.
\]

均值等于方差是 Poisson 模型的重要诊断线索，但实测数据中“样本均值接近样本方差”本身并不证明数据服从 Poisson。

### 从二项分布严格取极限

固定 \(\lambda>0\)，令 \(p_n=\lambda/n\)，\(X_n\sim\operatorname{Bin}(n,p_n)\)。对固定 \(k\)，

\[
\begin{aligned}
P(X_n=k)
&=\binom nk\left(\frac\lambda n\right)^k
  \left(1-\frac\lambda n\right)^{n-k}\\
&=\frac{\lambda^k}{k!}
  \frac{n(n-1)\cdots(n-k+1)}{n^k}
  \left(1-\frac\lambda n\right)^{-k}
  \left(1-\frac\lambda n\right)^n.
\end{aligned}
\]

当 \(n\to\infty\) 时，中间两个因子分别趋于 1，最后一个因子趋于 \(e^{-\lambda}\)。因此

\[
P(X_n=k)\longrightarrow e^{-\lambda}\frac{\lambda^k}{k!}.
\]

这里 \(n\) 增大而 \(np_n=\lambda\) 固定：单次事件越来越稀有，但总期望发生数不变。这就是 Poisson 近似的准确含义，不是笼统一句“\(n\) 大、\(p\) 小”。

Python 计算 \(P(X\le3)\) 时使用有限和：

```python
lam = 0.5
pmf_pois = [lam ** k * exp(-lam) / factorial(k) for k in range(N)]
assert abs(sum(pmf_pois) - 1.0) < 1e-12
ikea = sum((1 / 2) ** k * exp(-1 / 2) / factorial(k) for k in range(4))
assert abs(ikea - 0.998) < 5e-4
```

第 15 章将用概率母函数一行证明独立 Poisson 之和仍为 Poisson，参数相加。这里先给一个不用母函数的直接证明：若 \(X\sim\operatorname{Poi}(\lambda)\)、\(Y\sim\operatorname{Poi}(\mu)\) 独立，则

\[
P(X+Y=n)=\sum_{k=0}^n e^{-\lambda}\frac{\lambda^k}{k!}\,e^{-\mu}\frac{\mu^{n-k}}{(n-k)!}
=\frac{e^{-(\lambda+\mu)}}{n!}\sum_{k=0}^n\binom nk\lambda^k\mu^{n-k}
=e^{-(\lambda+\mu)}\frac{(\lambda+\mu)^n}{n!}.
\]

最后一步就是二项定理。另一个常用事实是“稀疏化”：把 \(\operatorname{Poi}(\lambda)\) 个事件各以概率 \(p\) 独立保留，则保留下来的个数仍是 Poisson，参数为 \(\lambda p\)。

### 极限的速度：总变差距离

“\(n\to\infty\) 时 pmf 逐点收敛”并没有说近似有多好。Le Cam 不等式给出一致的定量界：若 \(X=\sum_{i=1}^n I_i\)，\(I_i\) 独立 Bernoulli\((p_i)\)，则对 \(\lambda=\sum p_i\)，

\[
d_{TV}\big(X,\operatorname{Poi}(\lambda)\big)=\tfrac12\sum_k\big|P(X=k)-P(\operatorname{Poi}(\lambda)=k)\big|\le\sum_i p_i^2.
\]

对 \(\operatorname{Bin}(n,\lambda/n)\)，右端是 \(\lambda^2/n\)，误差以 \(1/n\) 速度趋零。Julia 单元的第四节用 pmf 递推把总变差算出来：

```julia
function binom_pmf(n, p)
    b = zeros(n + 1)
    b[1] = (1 - p)^n
    for k in 0:n-1
        b[k + 2] = b[k + 1] * (n - k) / (k + 1) * p / (1 - p)
    end
    b
end
lam = 2.0
for n in (10, 100, 1000)
    b = binom_pmf(n, lam / n)
    π_ = pois_pmf(lam, n)
    tail = 1 - sum(π_)          # Poisson 落在 k > n 的质量
    push!(tv, 0.5 * (sum(abs.(b .- π_)) + tail))
end
@assert all(tv .< lam^2 ./ [10, 100, 1000])
```

递推 \(b(k+1)=b(k)\frac{n-k}{k+1}\frac p{1-p}\) 避免了直接计算巨大的组合数；Poisson 的递推是 \(\pi(k+1)=\pi(k)\lambda/(k+1)\)。二项在 \(k>n\) 上概率为 0，所以 Poisson 在该区域的总质量要单独加进总变差里（变量 `tail`）。实际输出为 \(0.0522,\ 0.00457,\ 0.000452\)：每当 \(n\) 放大 10 倍，距离缩小约 10 倍，且始终小于界 \(\lambda^2/n=0.4,\,0.04,\,0.004\)。这是确定性计算，不含随机抽样。

### Julia：Poisson 的指纹与邮局例子

```julia
function sim_poisson2(lam, trials)
    out = zeros(Int, trials)
    for t in 1:trials
        L, k, p = exp(-lam), 0, 1.0
        while true
            p *= rand()
            if p < L
                break
            end
            k += 1
        end
        out[t] = k
    end
    out
end
P = sim_poisson2(2.0, 300_000)
@assert abs(mean(P) - 2.0) < 0.02
@assert abs(var(P) - 2.0) < 0.05
```

这是 Knuth 的乘法抽样：不断把 \(U(0,1)\) 随机数连乘，直到乘积降到 \(e^{-\lambda}\) 以下，所需乘法次数减一就是 Poisson 变量。原因是 \(-\ln U\) 是标准指数变量，连乘到阈值等价于“指数间隔累加超过 \(\lambda\)”，而单位时间内速率为 1 的点过程的点数即 \(\operatorname{Poi}(\lambda)\)（这一点在第 13 章讲指数分布时会证明）。两条断言检验均值与方差都等于 \(\lambda\)。

邮局例子取 \(\lambda=1/3\)：

```julia
PO = sim_poisson2(1 / 3, 300_000)
emp = count(>(0), PO) / length(PO)
@assert abs(emp - (1 - exp(-1 / 3))) < 0.003
```

\(P(X\ge1)=1-e^{-\lambda}=1-e^{-1/3}\approx0.2835\)。频率与这个闭式相符，说明“至少一次”的概率应由补事件 \(e^{-\lambda}\) 一步算出，而不是对无穷级数逐项相加。

## 12.6 离散均匀与德国坦克问题

从编号 \(1,\ldots,N\) 中无放回抽取 \(k\) 个，令最大编号为 \(M\)。事件 \(M=m\) 要求 \(m\) 被抽中，其余 \(k-1\) 个来自 \(1,\ldots,m-1\)，所以

\[
P(M=m)=\frac{\binom{m-1}{k-1}}{\binom Nk},
\qquad m=k,\ldots,N.
\]

先验证它是 pmf：\(\sum_{m=k}^N\binom{m-1}{k-1}=\binom Nk\)（hockey-stick 恒等式，等价于按最大值对全部 \(k\)-子集分类计数）。再算期望，关键是吸收恒等式 \(m\binom{m-1}{k-1}=k\binom mk\)：

\[
E[M]=\frac1{\binom Nk}\sum_{m=k}^N m\binom{m-1}{k-1}
=\frac{k}{\binom Nk}\sum_{m=k}^N\binom mk
=\frac{k\binom{N+1}{k+1}}{\binom Nk}
=\frac{k}{k+1}(N+1).
\]

第三个等号再次用 hockey-stick：\(\sum_{m=k}^N\binom mk=\binom{N+1}{k+1}\)；最后一步由 \(\binom{N+1}{k+1}=\frac{N+1}{k+1}\binom Nk\)。

直觉：在 \(0,1,\ldots,N+1\) 这条线上放 \(k\) 个随机点，它们与两端点一起把线段切成 \(k+1\) 个空隙，由对称性每个空隙平均长度相同（\((N+1)/(k+1)\)）；最大值等于总长减去最右空隙，所以平均为 \((N+1)\,k/(k+1)\)。反解上式，基于观测最大值 \(m\) 的估计量为

\[
\widehat N=\frac{k+1}{k}m-1.
\]

代入 \(E[M]\) 可得 \(E[\widehat N]=N\)，所以它在该抽样模型下无偏。

Python 完整枚举 \(N=12,k=3\) 的 220 个组合：

```python
for S in combinations(range(1, Nt + 1), kt):
    total += max(S)
    cnt += 1
assert cnt == comb(Nt, kt)
assert Fraction(total, cnt) == Fraction(kt, kt + 1) * (Nt + 1)
```

精确均值是 \(3\cdot13/4=39/4=9.75\)，不是 9。若一次观测到 \(m=9\)，估计值 \(\widehat N=11\)；这不等于声称真实 \(N\) 必为 11。Prolog 的另一组完整枚举为 \(N=8,k=3\)，56 个组合给出 \(E[M]=27/4\)。

### Julia：大样本下的无偏性与中位数偏高

```julia
N_true, k_obs, reps = 200, 5, 50_000
ests = zeros(reps)
for i in 1:reps
    m = maximum(randperm(N_true)[1:k_obs])
    ests[i] = (k_obs + 1) / k_obs * m - 1
end
@assert abs(mean(ests) - N_true) < 3
```

`randperm(N_true)[1:k_obs]` 是无放回地抽出 \(k=5\) 个编号；取最大值后代入估计量 \(\widehat N=\frac{k+1}kM-1\)。重复五万次，估计量的平均值落在 \(200\) 附近（运行输出约 200.1），这就是“无偏”的含义：对大量重复样本取平均才等于真值。输出同时打印中位数（约 209），说明单次估计的分布是左偏的——多数时候估计略高，偶尔大幅低估把平均拉回真值。“无偏”不等于“典型值准确”。

### Prolog：把期望变成穷举

`examples/prolog/12_discrete_dists.pl` 不使用任何公式，直接枚举。德国坦克一节：

```prolog
combo3(N, [A,B,C]) :- between(1,N,A), A1 is A + 1, between(A1, N, B),
                      B1 is B + 1, between(B1, N, C).

check_tank :-
    findall(M, (combo3(8, S), max_list(S, M)), Ms),
    length(Ms, 56),
    sum_list(Ms, Sum),
    E is Sum rdiv 56,
    E =:= 27 rdiv 4,
    format("german tank N=8,k=3: E[M]=27/4 ... : OK~n").
```

`combo3` 用严格递增的三重 `between` 生成全部 \(\binom83=56\) 个三元子集；`findall` 收集每个子集的最大值；`rdiv` 保证有理数精确运算，所以 `E =:= 27 rdiv 4` 是严格相等而不是浮点近似。它对应上面的 \(E[M]=\frac34\cdot9=\frac{27}4\)。

同一文件的另外两个检查也值得读懂。其一是“四骰赌局”：押定数字 1，出现 \(j\) 次赢 \(j\) 元，一次也不出现输 1 元。

```prolog
check_die_game :-
    findall(W, (between(1,6,A), between(1,6,B), between(1,6,C),
                between(1,6,D), count_1s([A,B,C,D], K),
                (K == 0 -> W = -1 ; W = K)), Ws),
    length(Ws, 1296),
    sum_list(Ws, S),
    S =:= 239.
```

1296 个等可能局面的总收益为 239，期望收益 \(239/1296\approx0.184\)，对赌徒有利。用二项分布验证：\(K\sim\operatorname{Bin}(4,1/6)\)，\(E[W]=\sum_{j\ge1}jP(K=j)-P(K=0)=E[K]-P(K=0)=\frac46-\left(\frac56\right)^4=\frac{864-625}{1296}=\frac{239}{1296}\)，与枚举吻合。这里的要点是：Prolog 的穷举给出的是与二项公式完全独立的第二条证据。

其二是饼干抽样：三色权重 45/30/25，抽 6 次恰得 3-2-1 型的概率。枚举 \(3^6=729\) 个序列，筛选出 \(\binom63\binom32=60\) 个满足的序列，权重相加除以 \(100^6\)，得到 \(0.123019\)，即多项分布 \(\frac{6!}{3!2!1!}0.45^3\,0.30^2\,0.25=60\cdot0.45^3\cdot0.3^2\cdot0.25\)。这直接对应 12.2 节的多项分布公式：系数 60 就是满足条件的有序序列数。

最后 `check_geometric` 做 \(p=1/2\) 的截断归一：\(\sum_{n=1}^8 2^{-n}=255/256\)，缺失的 \(1/256\) 恰为尾部 \(q^8\)。

## 12.7 机器证明与有限枚举的分工

Lean 文件 `examples/lean/Probability/Ch12DiscreteDists.lean` 固定若干完全确定的算术锚点，例如

```lean
example : ((3 : ℚ) / 4) * 13 = 39 / 4 := by norm_num
example : ((4 : ℚ) / 3) * 9 - 1 = 11 := by norm_num
```

它们证明的是具体有理数等式，不是代替上面的分布推导。Isabelle 文件 `examples/isabelle/MT12/T12_DiscreteDists.thy` 则直接调用 PMF 库核对 Bernoulli、几何和 Poisson 的形式化定义。Prolog 负责小规模全枚举，Julia 负责固定种子频率检查。

## 12.8 本章要点

1. Bernoulli 是基本构件；二项均值与方差最自然的推导是示性变量分解。
2. 几何分布描述首次成功等待时间，尾部为 \(q^t\)，具有离散无记忆性。
3. 负二项分布必须先声明计数口径；本章均值 \(rp/q\)、方差 \(rp/q^2\)。
4. Poisson 的均值和方差均为 \(\lambda\)；二项到 Poisson 的极限要求 \(np_n\to\lambda\)。
5. Poisson 近似的误差有定量界 \(d_{TV}\le\sum p_i^2\)；独立 Poisson 之和仍为 Poisson（卷积+二项定理）。
6. 德国坦克问题给出 \(E[M]=k(N+1)/(k+1)\)，旧注释中的 9 已校正为 \(39/4\)。
7. 无穷分布的截断程序只是近似审计；有限全枚举和机器算术证明各自承担不同证据角色。

*对应示例：`examples/lean/Probability/Ch12DiscreteDists.lean`、`examples/isabelle/MT12/T12_DiscreteDists.thy`、`examples/julia/12_discrete_dists.jl`、`examples/python/12_discrete_dists.py`、`examples/prolog/12_discrete_dists.pl`。*

---

上一章：[11 概率不等式与矩的界限](11-inequalities.md) · 下一章：[13 连续分布族](13-continuous-dists.md)
