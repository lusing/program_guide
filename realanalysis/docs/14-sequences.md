# 第 14 章 序列与收敛

> 度量空间里的序列是从自然数出发的函数。它收敛到 $p$ ，是说每个
> $\varepsilon>0$ 都有一个下标 $N$ ，从那里往后，所有项到 $p$ 的距离都小于 $\varepsilon$ 。
> 极限若存在就只有一个，而且收敛序列的值域有界。极限点则可以排成一条
> 收敛到它的序列。四则运算留到下一章。

## 14.1 定义 14.1：序列与值域

度量空间 $X$ 中的序列是函数 $f:\mathbb{N}\to X$ ，第 $n$ 项记作 $p_n$ 。
值域是这些项组成的集合。值域有界时，称序列有界。

序列作为函数总是无限的。值域可以有限：常值序列 $1,1,1,\ldots$ 的值域是 $\{1\}$ 。
可数集都能排成序列，$\mathbb{Q}$ 可以，$\mathbb{R}$ 不行。

书上的下标从 $1$ 起。下面的形式化里 $\mathbb{N}$ 含有 $0$ ，所以调和序列写成
$1/(n+1)$ ，项的集合仍是 $\{1,1/2,1/3,\ldots\}$ 。单独比较 $1/n$ 时，要求 $n\ge 1$ 。

## 14.2 例 14.2：五条序列的值域

1. $s_n=1/n$ 的值域无限，任意两项距离不超过 $1$ ，所以有界。
2. $s_n=n^2$ 的值域无限，而且无界。
3. $s_n=1+(-1)^n/n$ 在 $1$ 的两侧来回跳，值域无限，任意两项距离不超过 $3/2$ ，所以有界。
4. $s_n=1$ 的值域是 $\{1\}$ ，有界。
5. 在 $\mathbb{C}$ 里 $s_n=i^n$ 只取 $i,-1,-i,1$ 四个值，任意两项距离不超过 $2$ ，所以有界。

有界和收敛是两回事。$i^n$ 有界，下一节会看到它发散。

## 14.3 定义 14.3：$\varepsilon$-$N$

$\{p_n\}$ 收敛到 $p\in X$ ，是说

$$
\forall\varepsilon>0,\ \exists N\in\mathbb{N},\ n\ge N\implies d(p_n,p)<\varepsilon.
$$

记作 $\lim_{n\to\infty}p_n=p$ ，或 $p_n\to p$ 。没有任何 $p\in X$ 满足这句话时，序列在 $X$ 中发散。

$N$ 可以跟着 $\varepsilon$ 变。证明收敛，就是给出一个由 $\varepsilon$ 算出 $N$ 的规则。
大于这个 $N$ 的任何自然数也都合格。

形式化里，这句话是滤子极限：$\mathrm{Tendsto}\,s\,\mathrm{atTop}\,(\mathcal{N}\,p)$ 。
在度量空间里它等价于上面的 $\varepsilon$-$N$ 。

## 14.4 例 14.4

**调和序列.** $s_n=1/n$ 收敛到 $0$ 。对 $\varepsilon>0$ ，取

$$
N=\left\lceil\frac{1}{\varepsilon}\right\rceil+1.
$$

上取整保证 $N$ 是自然数，加 $1$ 保证 $n\ge N$ 时 $n>1/\varepsilon$ ，于是

$$
\left|\frac{1}{n}\right|\le\frac{1}{N}<\varepsilon.
$$

只取 $N=\lceil 1/\varepsilon\rceil$ 时，$n=N$ 可能得到 $1/n=\varepsilon$ ，严格不等式还差一步。
$\varepsilon=1/10$ 时，$N=11$ ：$n\ge 11$ 推出 $1/n<1/10$ ，而 $1/10$ 本身并不更小。

```lean
theorem harmonic_past_ten (n : ℕ) (hn : 11 ≤ n) : (1 : ℝ) / n < 1 / 10 := by
  have h10 : (0 : ℝ) < 10 := by norm_num
  have h10n : (10 : ℝ) < n := by
    exact_mod_cast (show 10 < n by omega)
  exact one_div_lt_one_div_of_lt h10 h10n
```

`omega` 从 $n\ge 11$ 得到 $10<n$ ，`exact_mod_cast` 把自然数不等式送进实数。
`one_div_lt_one_div_of_lt` 说：两个正数里较小的那个，倒数更大。所以 $10<n$ 给出 $1/n<1/10$ 。

整条序列的极限用 $1/(n+1)$ ，从 $n=0$ 起分母就不是 $0$ ：

```lean
theorem harmonic_to_zero :
    Tendsto (fun n : ℕ => 1 / ((n : ℝ) + 1)) atTop (nhds 0) :=
  tendsto_one_div_add_atTop_nhds_zero_nat
```

Isabelle 的同一条定理是 `LIMSEQ_inverse_real_of_nat`：$\lambda n.\,1/(n+1)\longrightarrow 0$ 。
每一项都是正的，而且不超过 $1$ 。证明把 $1\le n+1$ 乘上正数 $1/(n+1)$ ，右边变成 $1$ 。

**平方发散.** 假设 $n^2\to p$ 。取 $\varepsilon>0$ ，尾部满足 $|n^2-p|<\varepsilon$ ，于是
$n^2<|p|+\varepsilon$ 。一个实数加一个正数盖不住所有自然数的平方。

形式化先用“收敛则值域有界”，再让平方逃出任何一个以 $0$ 为心的闭球。

```lean
theorem squares_not_convergent :
    ¬ ∃ p : ℝ, Tendsto (fun n : ℕ => (n : ℝ) ^ 2) atTop (nhds p) := by
  intro h
  obtain ⟨p, hp⟩ := h
  have hb : IsBounded (range fun n : ℕ => (n : ℝ) ^ 2) :=
    isBounded_range_of_tendsto _ hp
  obtain ⟨r, hr⟩ := hb.subset_closedBall (0 : ℝ)
  have hr0 : 0 ≤ r := by
    have h0 : (fun n : ℕ => (n : ℝ) ^ 2) 0 ∈ closedBall (0 : ℝ) r :=
      hr (mem_range_self (0 : ℕ))
    simp [mem_closedBall, dist_self, pow_two] at h0
    exact h0
  obtain ⟨n, hn⟩ := exists_nat_gt (r + 1)
  have hn1 : (1 : ℝ) ≤ n := by
    have : (1 : ℝ) ≤ r + 1 := by linarith
    exact this.trans hn.le
  have hle : (n : ℝ) ≤ (n : ℝ) ^ 2 := by
    have hmul : (n : ℝ) * 1 ≤ (n : ℝ) * n :=
      mul_le_mul_of_nonneg_left hn1 (Nat.cast_nonneg n)
    simpa [pow_two, mul_one] using hmul
  have hmem : (n : ℝ) ^ 2 ∈ closedBall (0 : ℝ) r := hr (mem_range_self n)
  have habs : |(n : ℝ) ^ 2| ≤ r := by
    simpa [mem_closedBall, dist_zero_right, Real.norm_eq_abs] using hmem
  rw [abs_of_nonneg (by positivity : 0 ≤ (n : ℝ) ^ 2)] at habs
  have : (n : ℝ) ^ 2 < (n : ℝ) ^ 2 :=
    calc
      (n : ℝ) ^ 2 ≤ r := habs
      _ < r + 1 := by linarith
      _ < n := hn
      _ ≤ (n : ℝ) ^ 2 := hle
  exact lt_irrefl _ this
```

$0^2$ 落在闭球里，所以半径 $r\ge 0$ 。阿基米德性质给出自然数 $n>r+1$ ，于是 $n\ge 1$ ，从而 $n\le n^2$ 。
$n^2$ 又在同一个闭球里，所以 $n^2\le r$ 。连起来是 $n^2\le r<r+1<n\le n^2$ 。

Isabelle 不走闭球。`bounded_iff` 给出 $M$ ，使每个平方的范数不超过 $M$ 。
`reals_Archimedean2` 取出 $n>M+1$ 。$n\ge 1$ 时 $n\le n^2$ ，于是 $M+1<n^2\le M$ 。
因此平方的值域无界。收敛会迫使值域有界（`convergent_imp_bounded`），所以平方序列发散。

计算通道只核对一个具体的逃逸：$20^2=400>100$ 。

**交错序列.** $s_n=1+(-1)^n/n$ 收敛到 $1$ 。它在 $1$ 的左右来回跳，距离却是

$$
|s_n-1|=\left|\frac{(-1)^n}{n}\right|=\frac{1}{n},
$$

和调和序列用同一个 $N$ 。形式化写成 $1+(-1)^n/(n+1)$ 。$\varepsilon$-$N$ 从 $1/(n+1)\to 0$ 搬过来，因为 $|(-1)^n|=1$ ：

```lean
  have habs :
      |(-1 : ℝ) ^ n / ((n : ℝ) + 1)| = |(1 : ℝ) / ((n : ℝ) + 1)| := by
    rw [abs_div, abs_div, abs_neg_one_pow, abs_one]
  rw [Real.dist_eq, add_sub_cancel_left, habs]
```

`add_sub_cancel_left` 把 $d(1+a_n,\,1)$ 收成 $|a_n|$ 。`abs_neg_one_pow` 把分子的绝对值收成 $1$ 。

**常数序列.** $s_n=1$ 时，$d(s_n,1)=0$ 。任意 $\varepsilon>0$ 都可以取 $N=1$ 。

```lean
theorem const_to_one : Tendsto (fun _ : ℕ => (1 : ℝ)) atTop (nhds 1) :=
  tendsto_const_nhds
```

Isabelle 用 `tendsto_const`。计算通道核对 $|1-1|=0$ 。

**$i^n$ 发散.** 在 $\mathbb{C}$ 里这项只在 $i,-1,-i,1$ 上循环。若它收敛到某个 $p$ ，对 $\varepsilon/2$ 用定义，尾部相邻两项满足

$$
d(s_n,s_{n+1})\le d(s_n,p)+d(p,s_{n+1})<\varepsilon.
$$

取 $\varepsilon=1$ 。尾部里总有一项等于 $i$ ，下一项等于 $1$ ，而 $d(i,1)=\sqrt2>1$ 。矛盾。
这条序列有界，所以“有界”推不出“收敛”。

**极限依赖所在的空间.** $1/n$ 在 $\mathbb{R}$ 里收敛到 $0$ 。把同一条序列放进 $X=\mathbb{R}\setminus\{0\}$ ，它不收敛到 $X$ 的任何点：唯一的候选已经被挖掉了。所以“在 $X$ 中收敛”要把 $X$ 说清楚。

## 14.5 极限和极限点；定理 14.5

序列的极限是序列的性质。集合的极限点是拓扑的性质：每个邻域里还有集合的另一个点。

常数序列收敛到 $1$ ，值域 $\{1\}$ 的每个邻域里都只有这一个点，所以 $1$ 不是 $\{1\}$ 的极限点。

```lean
theorem not_accPt_singleton (x : ℝ) : ¬ AccPt x (𝓟 ({x} : Set ℝ)) := by
  rw [accPt_iff_nhds]
  intro h
  obtain ⟨y, hy, hne⟩ := h (ball x (1 / 2)) (ball_mem_nhds x (by norm_num))
  rw [mem_inter_iff, mem_singleton_iff] at hy
  exact hne hy.2
```

`AccPt` 要求每个邻域都提供一个不同的点。半径 $1/2$ 的球是 $x$ 的邻域。球与 $\{x\}$ 的交只有 $x$ ，它提供不了 $y\neq x$ 。

反过来，值域可以有极限点，序列本身却发散。取

$$
p_n=(-1)^n+\frac{(-1)^n}{n}.
$$

相邻两项距离大于 $2$ ：偶下标落在 $1$ 的右侧，奇下标落在 $-1$ 的左侧，中间隔着长度 $2$ 的空档。任何候选极限的小邻域都装不下整个尾部。值域的极限点却是 $1$ 和 $-1$ 。偶数项是 $1+1/n$ ，阿基米德性质让它落进 $1$ 的任意邻域；奇数项同样逼近 $-1$ 。

计算通道核对 $n=2$ 与 $n=3$ ：$3/2$ 和 $-4/3$ 的距离是 $17/6>2$ 。

定理 14.5 把收敛改写成邻域语言。$p_n\to p$ ，当且仅当 $p$ 的每个邻域外面只有有限多项。

正向：给定 $\varepsilon>0$ ，从 $N$ 起所有项都在半径 $\varepsilon$ 的球里。落在球外的下标都小于 $N$ ，只有有限个。开邻域都含有这样一个球，所以每个邻域外面也只有有限多项。

反向：给定 $\varepsilon>0$ ，球外只有有限多项。取这些项里最大的下标 $N$ ，则 $n\ge N+1$ 时 $d(p_n,p)<\varepsilon$ 。

## 14.6 定理 14.6：极限唯一

若 $p_n\to p$ 并且 $p_n\to p'$ ，则 $p=p'$ 。

对任意 $\varepsilon>0$ ，把定义用在 $\varepsilon/2$ 上，得到 $N$ 和 $N'$ 。从 $\max\{N,N'\}$ 起，

$$
d(p,p')\le d(p,p_n)+d(p_n,p')<\frac{\varepsilon}{2}+\frac{\varepsilon}{2}=\varepsilon.
$$

每个正数都是 $d(p,p')$ 的上界，所以距离为 $0$ ，从而 $p=p'$ 。三个候选极限就改用 $\varepsilon/3$ 。

$\mathbb{R}$ 是豪斯多夫空间，两个邻域滤子的极限相同：

```lean
theorem limit_unique {s : ℕ → ℝ} {p q : ℝ}
    (hp : Tendsto s atTop (nhds p)) (hq : Tendsto s atTop (nhds q)) : p = q :=
  tendsto_nhds_unique hp hq
```

Isabelle 在 `t2_space` 里有同名事实 `LIMSEQ_unique`，两条序列极限直接推出端点相等。

## 14.7 定理 14.7：收敛推出有界

取 $\varepsilon=1$ 。存在 $N$ ，使 $n\ge N$ 时 $d(p_n,p)<1$ 。前 $N-1$ 项只有有限个，令

$$
r=\max\{d(p_1,p),\ldots,d(p_{N-1},p),1\}.
$$

每一项到 $p$ 的距离都不超过 $r$ ，序列有界。

逆否命题：值域无界的序列发散。$n^2$ 就是这样。逆命题不成立：$i^n$ 有界且发散。

```lean
theorem convergent_range_bounded {s : ℕ → ℝ} {p : ℝ}
    (h : Tendsto s atTop (nhds p)) : IsBounded (range s) :=
  isBounded_range_of_tendsto s h
```

`isBounded_range_of_tendsto` 把尾部收进一个球，再把有限的头部并进去。Isabelle 的 `convergent_imp_bounded` 先从收敛得到柯西，再由柯西得到值域有界。

## 14.8 定理 14.8：极限点上的序列

设 $p$ 是 $E$ 的极限点。$p$ 可以在 $E$ 里，也可以在外面。对每个 $n\ge 1$ ，邻域 $N_{1/n}(p)$ 里有一个点 $p_n\in E$ ，于是 $d(p_n,p)<1/n$ 。仍取 $N=\lceil 1/\varepsilon\rceil+1$ ，则 $n\ge N$ 时

$$
d(p_n,p)<\frac{1}{n}\le\frac{1}{N}<\varepsilon.
$$

所以 $p_n\to p$ 。若 $p\notin E$ ，这条序列在大空间里收敛，在 $E$ 里不收敛。

具体例子是 $E=(0,1]$ ，$p=0$ 。$0$ 的每个邻域都含有这个半开区间里的点，所以 $0$ 是极限点，而且 $0$ 不在 $E$ 里。序列 $1/(n+1)$ 的每一项都在 $(0,1]$ 中，并且收敛到 $0$ 。

```lean
theorem harmonic_in_unit (n : ℕ) :
    1 / ((n : ℝ) + 1) ∈ Ioc (0 : ℝ) 1 := by
  refine ⟨?_, ?_⟩
  · positivity
  · rw [div_le_one (by positivity : (0 : ℝ) < (n : ℝ) + 1)]
    linarith
```

`Ioc` 是 $(0,1]$ 。`positivity` 给出 $1/(n+1)>0$ 。`div_le_one` 把 $1/(n+1)\le 1$ 收成 $1\le n+1$ 。极限本身是上一节的 `harmonic_to_zero`。

一般的选点要在每个邻域里挑一个元素，形式化依赖选择。这里把选择做成这条显式的调和序列，距离估计和例 14.4 是同一次 $N_\varepsilon$ 挑战。

## 14.9 推论 14.9 与 14.10

紧集 $K$ 的无限子集 $E$ 在 $K$ 里有一个极限点。这是紧集的无限子集必有极限点。定理 14.8 再把这个极限点写成 $E$ 中一条序列的极限。极限可以落在 $E$ 外面，但一定在 $K$ 里。所以序列在 $K$ 中收敛；它是否在 $E$ 中收敛，取决于极限是否属于 $E$ 。

$\mathbb{R}^k$ 的有界无限子集 $E$ 也含有一条收敛序列。魏尔斯特拉斯定理说这样的 $E$ 在 $\mathbb{R}^k$ 里有极限点，再调用定理 14.8。极限可以在 $E$ 外面。

闭区间 $[0,1]$ 是紧的。它的任何无限子集都有极限点，因而含有一条收敛序列。有界无限集先把极限点放在整个 $\mathbb{R}$ 里，再同样抽出序列。这两条推论的极限点部分已经在海涅–博雷尔那一章写过；这一章补上的是从极限点走到序列的那一步。

## 14.10 七通道对照

| 主题 | Lean | Isabelle | Coq | Agda | 计算三通道 |
|------|------|----------|-----|------|------------|
| $\varepsilon=1/10$ 的下标 | $n\ge 11\Rightarrow 1/n<1/10$ | — | `1/11 < 1/10` | $10<11$ | $1/11<1/10$ ，且 $1/10$ 并不更小 |
| $1/(n+1)\to 0$ | `tendsto_one_div_add_atTop_nhds_zero_nat` | `LIMSEQ_inverse_real_of_nat` | — | — | — |
| 交错项到 $1$ 的距离 | $\|(-1)^n/(n+1)\|=1/(n+1)$ | — | 把差先收成 $-1/11$ ，再用 `Rabs_left` | — | $\|s_{11}-1\|=1/11$ |
| 常数序列 | `tendsto_const_nhds` | `tendsto_const` | `Rabs_R0` | — | 值域 $\{1\}$ ，距离 $0$ |
| 单点不是极限点 | 半径 $1/2$ 的球 | — | — | — | — |
| 平方发散 | 值域有界则逃出闭球 | `reals_Archimedean2` 后 $M+1<M$ | $100<20\cdot 20$ | $4\le 4\cdot 4$ | $20^2=400>100$ |
| 极限唯一 | `tendsto_nhds_unique` | `LIMSEQ_unique` | — | — | — |
| 收敛则有界 | `isBounded_range_of_tendsto` | `convergent_imp_bounded` | — | — | — |
| 两个极限点的发散序列 | — | — | — | — | $3/2$ 与 $-4/3$ 距离 $17/6>2$ |

## 14.11 本章验证清单

- `examples/lean/Realanalysis/Ch14Sequences.lean`：$N=11$ 、调和序列、交错序列、常数序列、单点、唯一、有界、平方发散。
- `examples/isabelle/RA14/Sequences.thy`：$1/(n+1)\to 0$ 且项落在 $(0,1]$ 、常数序列、唯一、有界、平方无界因而发散。
- `examples/coq/Ch14_sequences.v`：$1/11<1/10$ ，$20^2$ 越过 $100$ ，交错距离与常数距离。
- `examples/agda/Ch14_sequences.agda`：下标 $11$ 已经越过 $10$ ，以及 $4\le 4\cdot 4$ 。
- `examples/julia/14_sequences.jl`、`examples/python/14_sequences.py`、`examples/prolog/14_sequences.pl`：同一个 $\varepsilon$-$N$ 、平方逃逸、交错距离、常数序列，以及相邻项距离大于 $2$ 。

复验：`pwsh -NoProfile -Command '& ./build.ps1 -Chapter 14'`。

## 14.12 接下来

下一章处理收敛序列的和、差、积、商，以及子序列。平方发散和 $i^n$ 发散的样子并不相同，那种区分也放在那里。

上一章：[13 完备集与连通集](13-perfect-connected.md) · 下一章：[15 极限与子序列](15-subsequences.md) · [返回目录](../README.md)
