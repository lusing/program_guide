# 第 25 章 随机变量序列的收敛

## 25.1 为什么一个“收敛”不够

确定性数列 $x_n\to x$ 只有一种逐点意义；随机变量序列则同时带有样本路径和概率分布两层结构。说

$$
X_n\to X
$$

而不说明收敛模式，可能指完全不同的事情：

- 每条样本路径是否最终靠近；
- 大幅偏离的概率是否趋零；
- 均方误差是否趋零；
- 仅分布函数是否趋近。

本章使用四种主要模式：

$$
L^p\text{ 收敛},\qquad
\text{几乎必然收敛},\qquad
\text{依概率收敛},\qquad
\text{依分布收敛}.
$$

核心关系是

$$
\boxed{
X_n\xrightarrow{a.s.}X
\ \Longrightarrow\
X_n\xrightarrow{P}X
\ \Longrightarrow\
X_n\xrightarrow{d}X,
}
$$

以及对 $p\ge1$ 的

$$
\boxed{
X_n\xrightarrow{L^p}X
\ \Longrightarrow\
X_n\xrightarrow{P}X.
}
$$

除特别情形外，反向都不成立。理解这些箭头最好的方式不是背图，而是掌握反例。

## 25.2 四种收敛的定义

### 25.2.1 $L^p$ 收敛

设 $p\ge1$ ，且 $E|X_n|^p,E|X|^p<\infty$ 。若

$$
\boxed{E|X_n-X|^p\to0,}
$$

则称 $X_n$ 在 $L^p$ 中收敛到 $X$ 。$p=2$ 时称均方收敛：

$$
E|X_n-X|^2\to0.
$$

$L^p$ 收敛是范数收敛，关心误差整个分布的大小，尤其惩罚少见但极大的误差。

### 25.2.2 几乎必然收敛

若

$$
\boxed{
P\left(\left\{\omega:\lim_{n\to\infty}X_n(\omega)=X(\omega)\right\}\right)=1,
}
$$

则称 $X_n$ 几乎必然收敛到 $X$ ，记作 $X_n\xrightarrow{a.s.}X$ 。

也可以写成尾事件形式：对每个 $\varepsilon>0$ ，

$$
P\left(\bigcap_{N=1}^\infty\bigcup_{n\ge N}
\{|X_n-X|\ge\varepsilon\}\right)=0.
$$

即“任意大误差还会在未来出现”的事件概率为零。

几乎必然收敛不是“每个 $\omega$ 都收敛”。允许存在一个零概率的坏路径集合，而且坏集合可以随 $\varepsilon$ 改变，最后通过可数交集处理。

### 25.2.3 依概率收敛

若对每个 $\varepsilon>0$ ，

$$
\boxed{
P(|X_n-X|\ge\varepsilon)\to0,
}
$$

则称 $X_n$ 依概率收敛到 $X$ ，记作 $X_n\xrightarrow{P}X$ 。

它只要求每个固定 $n$ 上坏事件的概率变小，不要求坏事件沿同一条路径最终停止。因此“第 $n$ 项大多很好”与“从某个时刻起永远很好”之间仍有差距。

### 25.2.4 依分布收敛

设 $F_n,F$ 分别为 $X_n,X$ 的 CDF。若对 $F$ 的每个连续点 $x$ ，

$$
\boxed{F_n(x)\to F(x),}
$$

则称 $X_n$ 依分布收敛到 $X$ ，记作 $X_n\xrightarrow{d}X$ 。

注意定义只要求在连续点收敛。CDF 在不连续点可能保留与极限点质量不同的值，这不妨碍分布弱收敛。

依分布收敛甚至不要求 $X_n,X$ 定义在同一概率空间，因此它本身不谈逐路径距离 $X_n-X$ 。

## 25.3 箭头为什么成立

### 25.3.1 几乎必然蕴含依概率

若固定一条最终收敛的路径，则对任意 $\varepsilon>0$ ，从某个时刻起都有

$$
|X_n(\omega)-X(\omega)|<\varepsilon.
$$

所以事件

$$
A_N=\bigcup_{n\ge N}\{|X_n-X|\ge\varepsilon\}
$$

随 $N$ 下降，其交集只包含不收敛路径。几乎必然收敛给出

$$
P(A_N)\to0.
$$

而

$$
\{|X_N-X|\ge\varepsilon\}\subset A_N,
$$

故 $P(|X_N-X|\ge\varepsilon)\to0$ 。

这里真正多出来的信息是：几乎必然收敛控制的是整个未来尾部的并集，而依概率只控制每个单独时刻。

### 25.3.2 $L^p$ 蕴含依概率

由 Markov 不等式，

$$
P(|X_n-X|\ge\varepsilon)
\le\frac{E|X_n-X|^p}{\varepsilon^p}\to0.
$$

因此均方误差趋零足以推出偏离概率趋零。

### 25.3.3 依概率蕴含依分布

固定 $x$ 与 $\delta>0$ 。在 $\{|X_n-X|<\delta\}$ 上，

$$
X_n\le x\quad\Longrightarrow\quad X\le x+\delta.
$$

将坏事件的概率分出，再令 $\delta\downarrow0$ ，利用 CDF 在连续点的右连续和左侧极限，可得 $F_n(x)\to F(x)$ 。

这也说明为什么连续点重要：不连续点处的点质量会让左右夹逼保留一个正差。

## 25.4 移动区间：依概率且 $L^p$ ，但处处不收敛

在概率空间 $([0,1],\mathcal B,\mathrm{Leb})$ 上构造移动区间指标。第 $k$ 层有 $2^k$ 个小区间：

$$
I_{k,i}=\left[\frac i{2^k},\frac{i+1}{2^k}\right],
\qquad i=0,\dots,2^k-1.
$$

按层依次排列，记第 $n$ 项为 $Z_n=\mathbf1_{I_n}$ 。令

$$
k=\lfloor\log_2n\rfloor,\qquad i=n-2^k,
$$

则

$$
I_n=\left[\frac i{2^k},\frac{i+1}{2^k}\right].
$$

Python 用精确分数实现：

```python
def typewriter(n):
    k = int(floor(log2(n)))
    i = n - 2 ** k
    return F(i, 2 ** k), F(i + 1, 2 ** k), k
```

区间长度为 $2^{-k}$ ，所以

$$
P(Z_n=1)=2^{-k}\to0.
$$

因此对任意 $0<\varepsilon\le1$ ，

$$
P(|Z_n|\ge\varepsilon)=2^{-k}\to0,
$$

即 $Z_n\xrightarrow{P}0$ 。同时 $Z_n\in\{0,1\}$ ，故对任意 $p\ge1$ ，

$$
E|Z_n|^p=P(Z_n=1)=2^{-k}\to0,
$$

所以也有 $Z_n\xrightarrow{L^p}0$ 。

但对每个固定 $s\in[0,1]$ ，每一层都有一个小区间覆盖 $s$ ，也有小区间不覆盖 $s$ 。因此

$$
Z_n(s)=1\quad\text{无穷多次},
\qquad
Z_n(s)=0\quad\text{无穷多次}.
$$

于是

$$
\limsup_nZ_n(s)=1,\qquad
\liminf_nZ_n(s)=0.
$$

**每一个点都不收敛**，而不只是在一个零测集上不收敛。

Python 对多个有理点和十二层逐层检查：

```python
for K in range(0, 12):
    hits = [n for n in range(2 ** K, 2 ** (K + 1))
            if Z(n, s) == 1]
    assert len(hits) >= 1
for K in range(1, 12):
    misses = [n for n in range(2 ** K, 2 ** (K + 1))
              if Z(n, s) == 0]
    assert len(misses) >= 1
```

Prolog 同样使用有理数穷举每层命中与遗漏：

```prolog
forall(member(S, [0, 1 rdiv 3, 2 rdiv 3, 5 rdiv 7, 1]),
       forall(between(0, 9, K),
              (hits_in_level(K, S, H), H >= 1,
               (K >= 1 -> miss_in_level(K, S, Ms), Ms >= 1 ; true))))
```

Julia 用 `Rational` 给出同一构造，避免浮点端点误判：

```julia
function typewriter(n)
    k = floor(Int, log2(n)); i = n - 2^k
    return i // 2^k, (i + 1) // 2^k, k
end
Zn(n, s) = (lo_hi = typewriter(n);
            lo_hi[1] <= s <= lo_hi[2] ? 1 : 0)
```

`lo_hi[1] <= s <= lo_hi[2]` 是区间成员判定；程序随后分别用 `any` 检查每一层的命中与遗漏。

这个反例同时否定：

$$
L^p\nRightarrow a.s.,\qquad P\nRightarrow a.s.
$$

## 25.5 为什么第一 Borel–Cantelli 不能直接挽救移动区间

第一 Borel–Cantelli 引理说：若

$$
\sum_nP(A_n)<\infty,
$$

则

$$
P(A_n\ \text{无穷多次发生})=0.
$$

移动区间每一层的概率总和为

$$
\sum_{i=0}^{2^k-1}2^{-k}=1.
$$

因此前 $K+1$ 层总和为 $K+1$ ，整体级数发散。第一 Borel–Cantelli 的前提不满足，不能据此推出最终不再发生。

Lean 精确证明这两笔账：

```lean
theorem level_total (k : ℕ) :
    ∑ _i ∈ Finset.range (2 ^ k), (1 : ℚ) / 2 ^ k = 1 := by
  simp

theorem levels_sum (K : ℕ) :
    ∑ k ∈ Finset.range (K + 1),
      ∑ _i ∈ Finset.range (2 ^ k), (1 : ℚ) / 2 ^ k = K + 1 := by
  induction K with
  | zero => simp
  | succ K ih =>
    rw [Finset.sum_range_succ, ih, level_total]
    push_cast
    ring
```

概率逐项趋零不等于概率之和有限；前者是依概率收敛所需的，后者是常用几乎必然证明所需的更强条件。

## 25.6 尖峰序列：几乎必然收敛但不 $L^1$ 收敛

仍在 $[0,1]$ 均匀概率空间上，定义

$$
Z_n=e^n\mathbf1\{s>1-n^{-2}\}.
$$

非零概率为

$$
P(Z_n\ne0)=n^{-2}.
$$

因为

$$
\sum_{n=1}^\infty n^{-2}<\infty,
$$

第一 Borel–Cantelli 引理说明，几乎必然只有有限多个 $Z_n$ 非零。因此

$$
Z_n\xrightarrow{a.s.}0.
$$

然而

$$
E[Z_n]=e^n n^{-2}\to\infty.
$$

所以它不仅不 $L^1$ 收敛到 0，期望甚至发散到无穷。几乎必然收敛不排除零概率附近出现越来越高的尖峰。

本例的非零事件还随 $n$ 嵌套：

$$
\{s>1-(n+1)^{-2}\}\subset\{s>1-n^{-2}\}.
$$

从 $m$ 开始的并集就是第 $m$ 个事件，其概率恰为 $m^{-2}$ 。这给出比单纯级数收敛更直接的尾部描述。

Python 核对可求和尾界和期望增长：

```python
for m in (2, 10, 100, 1000):
    tail = sum(1.0 / (n * n) for n in range(m, 200000))
    assert tail <= 1.0 / (m - 1)
assert exp(30) / 900 > 1e10
```

这里使用望远镜界

$$
\frac1{n^2}\le\frac1{n-1}-\frac1n,
\qquad n\ge2,
$$

所以

$$
\sum_{n=m}^\infty\frac1{n^2}\le\frac1{m-1}.
$$

Lean 用归纳证明部分和统一有界：

```lean
theorem spike_sum_bounded (N : ℕ) :
    ∑ i ∈ Finset.range (N + 1),
      (1 : ℚ) / ((i : ℚ) + 1) ^ 2
      ≤ 2 - 1 / ((N : ℚ) + 1) := by
  induction N with
  | zero => norm_num
  | succ N ih =>
    rw [Finset.sum_range_succ]
    have hN : (0 : ℚ) < (N : ℚ) + 1 := by positivity
    have key : 1 / (((N + 1 : ℕ) : ℚ) + 1) ^ 2 ≤
        1 / ((N : ℚ) + 1) - 1 / (((N + 1 : ℕ) : ℚ) + 1) := by
      push_cast
      rw [div_sub_div _ _ (by positivity) (by positivity),
          div_le_div_iff₀ (by positivity) (by positivity)]
      nlinarith [sq_nonneg (N : ℚ), hN]
    push_cast at key ih ⊢
    linarith
```

`key` 是相邻项的望远镜界，`ih` 是前一段部分和界，二者相加完成归纳。这个例子给出

$$
a.s.\nRightarrow L^1.
$$

## 25.7 独立 Bernoulli：依概率但不几乎必然的另一机制

设事件 $A_n$ 相互独立，且

$$
P(A_n)=\frac1n.
$$

令 $Z_n=\mathbf1_{A_n}$ 。因为 $1/n\to0$ ，有

$$
Z_n\xrightarrow{P}0.
$$

但

$$
\sum_nP(A_n)=\sum_n\frac1n=\infty.
$$

第二 Borel–Cantelli 引理利用独立性说明

$$
P(A_n\ \text{无穷多次发生})=1.
$$

因此 $Z_n$ 几乎必然不收敛到 0。

不必引用完整第二引理也能算。对 $m\ge2$ ，

$$
P\left(\bigcap_{n=m}^NA_n^c\right)
=\prod_{n=m}^N\left(1-\frac1n\right)
=\prod_{n=m}^N\frac{n-1}{n}
=\frac{m-1}{N}\to0.
$$

因此从任意 $m$ 起全部不发生的概率为 0，未来仍会发生事件的概率为 1。

Prolog 用有理数核对望远镜乘积：

```prolog
noevent(M, N, P) :-
    numlist(M, N, L),
    foldl([X, A0, A]>>(A is A0*(1 - 1 rdiv X)),
          L, 1, P).
```

Lean 从 $n=2$ 起归纳：

```lean
theorem no_event_prod (N : ℕ) :
    ∏ i ∈ Finset.range N, (1 - 1 / ((i : ℚ) + 2)) =
      1 / ((N : ℚ) + 1) := by
  induction N with
  | zero => simp
  | succ N ih =>
    rw [Finset.prod_range_succ, ih]
    push_cast
    field_simp
    ring
```

移动区间和独立 Bernoulli 都否定依概率到几乎必然，但机制不同：

- 移动区间每层覆盖整个空间，事件高度依赖；
- Bernoulli 事件独立，靠第二 Borel–Cantelli 保证无限复发。

## 25.8 依概率收敛的子列定理

虽然依概率不蕴含几乎必然，但有重要补救：

$$
\boxed{
X_n\xrightarrow{P}X
\Longrightarrow
\text{存在子列 }X_{n_j}\xrightarrow{a.s.}X.
}
$$

构造方法：对每个 $j$ ，利用依概率收敛选择 $n_j$ ，使

$$
P\left(|X_{n_j}-X|>\frac1j\right)<2^{-j},
$$

并保证 $n_j$ 严格递增。因为

$$
\sum_j2^{-j}<\infty,
$$

第一 Borel–Cantelli 引理给出：几乎必然地，只有有限多个子列误差超过 $1/j$ ，故子列几乎必然收敛。

Python 把选择规则写成确定性算法：

```python
def choose_subsequence(prob_exceed, J):
    out, last = [], 0
    for j in range(1, J + 1):
        n = last + 1
        while prob_exceed(n, j) >= F(1, 2 ** j):
            n += 1
        out.append(n)
        last = n
    return out
```

对移动区间，直接取 $n_j=2^j$ 也可。此时区间固定为 $[0,2^{-j}]$ ，对每个固定 $s>0$ ，最终 $s$ 都在区间右侧，因此子列逐点趋于 0。

子列定理说明：依概率收敛不是“没有路径信息”，而是路径信息可能藏在适当子列中。

## 25.9 依分布收敛为何只看连续点

令

$$
Z_n\sim N(0,1/n).
$$

当 $n\to\infty$ ，分布越来越集中于 0，所以直觉上应依分布收敛到点质量 $\delta_0$ 。其极限 CDF 为

$$
F(x)=
\begin{cases}
0,&x<0,\\
1,&x\ge0.
\end{cases}
$$

对 $x>0$ ，

$$
F_n(x)=\Phi(\sqrt n\,x)\to1;
$$

对 $x<0$ ，

$$
F_n(x)=\Phi(\sqrt n\,x)\to0.
$$

但在 $x=0$ ，由对称性，

$$
F_n(0)=\frac12
$$

对所有 $n$ 成立，并不趋于 $F(0)=1$ 。

若定义要求所有点都收敛，这个最自然的“收缩到常数”例子反而会被排除。因此定义只要求连续点。

Lean 把不连续点的差异压缩成精确有理事实：

```lean
theorem cdf_at_discontinuity : (1 : ℚ) / 2 ≠ 1 := by
  norm_num
```

Python 检查不同 $n$ 的 CDF 方向：

```python
assert abs(Phi(sqrt(n) * 0.0) - 0.5) < 1e-15
assert Phi(sqrt(n) * 0.5) >= 1 - 2 * exp(-n / 8)
assert Phi(-sqrt(n) * 0.5) <= 2 * exp(-n / 8)
```

## 25.10 常数目标的特例

若 $c$ 是常数，则

$$
\boxed{
X_n\xrightarrow{d}c
\iff
X_n\xrightarrow{P}c.
}
$$

因为点质量 $\delta_c$ 的 CDF 在 $c-\varepsilon$ 和 $c+\varepsilon$ 都连续。依分布收敛给出

$$
F_n(c-\varepsilon)\to0,
\qquad
F_n(c+\varepsilon)\to1.
$$

所以

$$
P(|X_n-c|\le\varepsilon)
\ge F_n(c+\varepsilon)-F_n(c-\varepsilon)\to1.
$$

反向由一般的依概率蕴含依分布得到。

例如 $Z_n=X/\sqrt n$ ，其中 $X\sim N(0,1)$ 。则 $Z_n\sim N(0,1/n)$ ，依分布收敛到 0；同时

$$
P(|Z_n|>\varepsilon)
=2[1-\Phi(\varepsilon\sqrt n)]\to0,
$$

故也依概率收敛到 0。

这个等价只对常数目标成立。随机目标 $X$ 的分布本身含有不确定性，分布接近并不能迫使 $X_n-X$ 很小。

## 25.11 $-X$ 反例：同分布不等于路径接近

设 $X\sim N(0,1)$ ，令

$$
Z_n=-X\qquad\text{对所有 }n.
$$

由对称性，$-X$ 与 $X$ 同分布，所以

$$
Z_n\xrightarrow{d}X.
$$

但

$$
|Z_n-X|=2|X|,
$$

因此对任意 $\varepsilon>0$ ，

$$
P(|Z_n-X|>\varepsilon)=P(2|X|>\varepsilon)
$$

是不随 $n$ 改变的正常数，不趋于 0。所以 $Z_n$ 不依概率收敛到 $X$ 。

Python 取 $\varepsilon=1/2$ ，检查偏差概率超过 0.8：

```python
p_far = 2 * (1 - Phi(eps / 2))
assert p_far > 0.8
```

这个反例的关键是极限 $X$ 随机，而且 $Z_n$ 与 $X$ 的耦合方式固定为反号。依分布收敛只看见各自边际分布，完全看不见这种耦合。

## 25.12 一致可积与期望收敛

几乎必然或依概率收敛并不自动给出

$$
E[X_n]\to E[X].
$$

除控制收敛外，常用条件是一致可积。随机变量族 $\{X_n\}$ 一致可积，若

$$
\boxed{
\lim_{M\to\infty}\sup_n
E\left[|X_n|\mathbf1\{|X_n|>M\}\right]=0.
}
$$

在有限测度空间上，若 $X_n\xrightarrow{P}X$ 且族一致可积，则

$$
E|X_n-X|\to0,
\qquad E[X_n]\to E[X].
$$

典型反例是

$$
Z_n=n\mathbf1\{U<1/n\},\qquad U\sim U(0,1).
$$

对每个固定 $U>0$ ，最终 $1/n<U$ ，故

$$
Z_n\xrightarrow{a.s.}0.
$$

但

$$
E[Z_n]=n\cdot\frac1n=1.
$$

若 $5<M<n$ ，则

$$
E[Z_n\mathbf1\{Z_n>M\}]=1.
$$

故 supremum 不随 $M$ 消失，族不一致可积。

Python 精确检查：

```python
for n in (10, 100, 1000):
    assert n * F(1, n) == 1
M = 5
tail = n * F(1, n) if n > M else F(0)
assert tail == (1 if n > M else 0)
```

若族有统一 $L^2$ 界

$$
E[Z_n^2]\le C,
$$

则由 Cauchy–Schwarz 或 Markov 可控制高值尾部，例如

$$
E[|Z_n|\mathbf1\{|Z_n|>M\}]
\le\frac{C}{M}.
$$

所以统一二阶矩界是一致可积的充分条件，不是必要条件。

## 25.13 Skorokhod 表示与连续映射

依分布收敛看似最弱，但 Skorokhod 表示定理在常见 Polish 空间上给出强大翻译：若

$$
X_n\xrightarrow{d}X,
$$

则可以构造同一概率空间上的新变量 $\widetilde X_n,\widetilde X$ ，使

$$
\widetilde X_n\overset d=X_n,
\qquad
\widetilde X\overset d=X,
\qquad
\widetilde X_n\xrightarrow{a.s.}\widetilde X.
$$

新变量不是原变量，不能从表示定理反推原序列几乎必然收敛。

一维实变量可用分位数耦合。取 $U\sim U(0,1)$ ，令

$$
\widetilde X_n=F_n^{-1}(U),\qquad
\widetilde X=F^{-1}(U).
$$

Python 用指数分布演示。若

$$
F_n=\operatorname{Exp}(1+1/n),
\qquad F=\operatorname{Exp}(1),
$$

则

$$
F_n^{-1}(u)=-\frac{\log(1-u)}{1+1/n}
\longrightarrow-\log(1-u)=F^{-1}(u).
$$

程序对固定 $u$ 检查耦合变量逐点靠近：

```python
z = -log(1 - u)
d = [abs(-log(1 - u) / (1 + 1 / n) - z)
     for n in (10, 100, 1000)]
assert d[0] > d[1] > d[2] or z < 1e-12
```

### 25.13.1 连续映射定理

若 $X_n\xrightarrow{d}X$ ，$g$ 在 $X$ 的分布不连续点集之外连续，尤其 $P(X\in D_g)=0$ ，则

$$
\boxed{g(X_n)\xrightarrow{d}g(X).}
$$

同样结论对依概率和几乎必然收敛也成立，条件需相应解释。

例如 $g(x)=x^2$ 处处连续，所以 $X_n^2\xrightarrow{d}X^2$ 。指示函数 $g(x)=\mathbf1\{x>a\}$ 在 $a$ 不连续；若 $P(X=a)=0$ ，仍可使用。

## 25.14 Portmanteau：弱收敛的多个等价面孔

实值情形下，依分布收敛可等价地用多种集合或函数表述：

1. 对每个有界连续函数 $g$ ，
   $E[g(X_n)]\to E[g(X)];$
2. 对每个闭集 $F$ ，
   $\limsup_nP(X_n\in F)\le P(X\in F);$
3. 对每个开集 $G$ ，
   $\liminf_nP(X_n\in G)\ge P(X\in G);$
4. 对每个满足 $P(X\in\partial A)=0$ 的集合 $A$ ，
   $P(X_n\in A)\to P(X\in A).$

这些表述统称 Portmanteau 定理。边界条件不可省略，因为极限分布可能在边界上放点质量。

程序用二项到 Poisson 的极限作数值核对：

$$
\operatorname{Bin}(n,\lambda/n)
\xrightarrow{d}\operatorname{Poisson}(\lambda).
$$

Python 比较前十二个点的 pmf：

```python
errs = [max(abs(binom_pmf(n, k) - pois(k))
            for k in range(0, 12))
        for n in (10, 100, 1000)]
assert errs[0] > errs[1] > errs[2] and errs[2] < 2e-3
```

对闭集 $A=\{0,1,2\}$ ，边界不含极限点质量之外的额外问题，概率直接收敛。这里 pmf 逐点收敛比 CDF 连续点收敛更强，是该离散极限的额外性质，不是弱收敛定义的一般要求。

## 25.15 一个边界极值的依分布极限

设

$$
U_1,\dots,U_n\stackrel{iid}{\sim}U(0,\theta),
\qquad M_n=\max_iU_i.
$$

最大值本身依概率趋近 $\theta$ ，但若研究缩放后的差距

$$
Y_n=n(\theta-M_n),
$$

对固定 $x>0$ 且 $n$ 足够大，

$$
\begin{aligned}
P(Y_n>x)
&=P(M_n<\theta-x/n)\\
&=\left(1-\frac{x}{n\theta}\right)^n
\to e^{-x/\theta}.
\end{aligned}
$$

因此

$$
\boxed{
n(\theta-M_n)\xrightarrow{d}Y,
\qquad P(Y>x)=e^{-x/\theta}.
}
$$

极限是尺度为 $\theta$ 的指数分布。Python 同时检查精确尾概率和误差上界：

```python
exact = (1 - x / (n * theta)) ** n
assert abs(exact - exp(-x / theta)) < \
       (x * x / theta ** 2) / n + 1e-12
```

这个例子显示依分布定理需要正确缩放：未缩放的 $\theta-M_n\to0$ ，只有乘以 $n$ 才保留非退化随机波动。第 27 章的中心极限定理也使用同样思想，只是均值附近通常采用 $\sqrt n$ 缩放。

## 25.16 收敛模式关系总表

| 命题 | 是否一般成立 | 关键理由或反例 |
|---|---|---|
| $a.s.\Rightarrow P$ | 是 | 控制整个未来尾部 |
| $L^p\Rightarrow P$ | 是 | Markov 不等式 |
| $P\Rightarrow d$ | 是 | 在 CDF 连续点夹逼 |
| $P\Rightarrow a.s.$ | 否 | 移动区间、独立 Bernoulli(1/n) |
| $L^p\Rightarrow a.s.$ | 否 | 移动区间 |
| $a.s.\Rightarrow L^1$ | 否 | 尖峰 $e^n\mathbf1\{s>1-n^{-2}\}$ |
| $d\Rightarrow P$ | 否 | $Z_n=-X$ ，极限 $X$ 随机 |
| $d\Rightarrow P$ 且目标常数 | 是 | 点质量 CDF 的两侧连续点 |
| $P\Rightarrow$ 某子列 $a.s.$ | 是 | 选择可求和尾概率 |
| $P+UI\Rightarrow L^1$ | 是 | 控制高值尾部 |

另有两条常用但容易误读的关系：

- 若 $X_n\to X$ 几乎必然且都被同一可积变量控制，则控制收敛给出 $L^1$ ；
- 若 $X_n\xrightarrow{d}X$ ，并不自动有 $E[X_n]\to E[X]$ ，还需要矩或一致可积条件。

## 25.17 本章机器证据的边界

1. Lean 证明有限有理恒等式：移动区间每层总概率、尖峰级数界、独立无事件乘积及 CDF 不连续点差异。
2. Python 与 Prolog 对有限层和有限样本点做精确穷举，验证反例的构造没有索引错误。
3. Julia 独立实现相同构造，并检查子列选择、正态 CDF 和极值尾概率。
4. 固定随机数只用于分位数耦合等数值展示；反例的收敛结论来自解析证明，不来自有限运行。

特别是“前 255 项每层都覆盖并遗漏测试点”只是对无限构造的有限审计。无限结论由“每一层都有同样性质”的一般论证给出。

## 25.18 本章要点

1. $L^p$ 、几乎必然、依概率、依分布分别控制范数、路径尾部、单点概率和 CDF。
2. 几乎必然与 $L^p$ 都蕴含依概率，依概率蕴含依分布。
3. 移动区间指标依概率且 $L^p$ 收敛到 0，却在每个样本点振荡。
4. 尖峰序列几乎必然收敛到 0，但期望可发散，说明路径收敛不控制矩。
5. 独立 Bernoulli(1/n) 由第二 Borel–Cantelli 保证事件无限复发。
6. 依概率序列可抽出几乎必然收敛子列，关键是选择可求和尾概率。
7. 依分布收敛只要求极限 CDF 连续点；$N(0,1/n)$ 在 0 处恒为 1/2 并不妨碍极限为 $\delta_0$ 。
8. 常数目标下依分布与依概率等价；随机目标下不成立。
9. 一致可积控制高值尾部，使依概率收敛可以升级为期望和 $L^1$ 收敛。
10. Skorokhod 表示、连续映射和 Portmanteau 提供弱收敛的等价工作语言。

*对应示例：`examples/lean/Probability/Ch25Convergence.lean`、`examples/julia/25_convergence.jl`、`examples/python/25_convergence.py`、`examples/prolog/25_convergence.pl`。*

---

上一章：[24 差分方程与 Markov 链](24-markov-chains.md) · 下一章：[26 大数定律与 Monte Carlo](26-lln.md)
