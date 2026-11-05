# 第 15 章 极限与子序列

> 收敛序列可以相加、相乘、取倒数，极限跟着做同样的运算。
> 向量序列收敛，就是每个分量收敛。子序列是下标严格递增地抽出来的一条新序列。
> 收敛序列的每条子序列都收敛到同一个点；紧集里的序列，以及 $\mathbb{R}^k$
> 里的有界序列，一定有一条收敛的子序列。

## 15.1 定理 15.1：$\mathbb{R}$ 上的代数运算

这些运算要用到加法和乘法，所以只在 $\mathbb{R}$、$\mathbb{R}^k$ 或 $\mathbb{C}$ 里谈。
一般度量空间只有距离。设 $s_n\to s$，$t_n\to t$。

**和.** 给定 $\varepsilon>0$，两边各让出 $\varepsilon/2$。存在 $N_1,N_2$，使 $n\ge N_1$ 时
$|s_n-s|<\varepsilon/2$，$n\ge N_2$ 时 $|t_n-t|<\varepsilon/2$。从 $N=\max\{N_1,N_2\}$ 起，

$$
|(s_n+t_n)-(s+t)|\le |s_n-s|+|t_n-t|<\varepsilon.
$$

```lean
theorem add_limits {s t : ℕ → ℝ} {a b : ℝ}
    (hs : Tendsto s atTop (nhds a)) (ht : Tendsto t atTop (nhds b)) :
    Tendsto (fun n => s n + t n) atTop (nhds (a + b)) :=
  hs.add ht
```

`hs.add ht` 就是这两条极限相加。常数序列 $t_n=c$ 是它的特例，所以 $c+s_n\to c+s$。

具体到调和序列：$1/(n+1)\to 0$，加上常数 $1$ 得到 $1/(n+1)+1\to 1$。
计算通道核对 $n=11$：$(1/11+1)-1$ 正好等于 $1/11$，误差全在调和项上。

**数乘.** $c=0$ 时，$cs_n$ 是零序列，距离是 $0$。$c\neq 0$ 时，把定义用在 $\varepsilon/|c|$ 上：

$$
|cs_n-cs|=|c|\,|s_n-s|<|c|\cdot\frac{\varepsilon}{|c|}=\varepsilon.
$$

```lean
theorem const_mul_limit {s : ℕ → ℝ} {a c : ℝ} (hs : Tendsto s atTop (nhds a)) :
    Tendsto (fun n => c * s n) atTop (nhds (c * a)) :=
  Filter.Tendsto.const_mul c hs
```

`const_mul` 把常数写在序列前面。$3/(n+1)\to 0$ 就是 $c=3$、$a=0$。
$n=11$ 时 $3/11<3/10$。

**积.** 目标是 $|s_nt_n-st|<\varepsilon$。展开后多出一个尾巴：

$$
|s_nt_n-st|\le |s_n-s|\,|t_n-t|+|st_n+ts_n-2st|.
$$

前半用 $\sqrt{\varepsilon/2}$：两个因子都小于这个数，乘积就小于 $\varepsilon/2$。
后半是 $st_n\to st$ 与 $ts_n\to ts$ 的和，再减去常数 $2st$，极限是 $0$。
再取一个 $N_3$，使这项也小于 $\varepsilon/2$。三个下标取最大。

```lean
theorem mul_limits {s t : ℕ → ℝ} {a b : ℝ}
    (hs : Tendsto s atTop (nhds a)) (ht : Tendsto t atTop (nhds b)) :
    Tendsto (fun n => s n * t n) atTop (nhds (a * b)) :=
  hs.mul ht
```

$n=10$ 时，$(1+1/10)(2+1/10)$ 到 $2$ 的距离小于 $1/2$。

**倒数.** 先要 $s\neq 0$，并且每一项 $s_n\neq 0$，这样 $1/s_n$ 全程有定义。
证明里真正用到的是尾部躲开 $0$。取 $N_1$ 使 $|s_n-s|<|s|/2$，于是

$$
|s_n|\ge |s|-|s_n-s|>|s|/2.
$$

再取 $N_2$ 使 $|s_n-s|<\frac12|s|^2\varepsilon$。从两者的最大下标起，

$$
\left|\frac1{s_n}-\frac1s\right|=\frac{|s_n-s|}{|s_n|\,|s|}<\varepsilon.
$$

```lean
theorem inv_limit {s : ℕ → ℝ} {a : ℝ} (hs : Tendsto s atTop (nhds a)) (ha : a ≠ 0) :
    Tendsto (fun n => (s n)⁻¹) atTop (nhds a⁻¹) :=
  hs.inv₀ ha
```

`inv₀` 的下标 $0$ 提醒极限不能是零。$1+1/(n+1)\to 1$，倒数趋于 $1$。
$n=10$ 时，$1/(1+1/10)=10/11$，到 $1$ 的距离是 $1/11$。

Isabelle 把同一组规则写成 `tendsto_add`、`tendsto_mult_left`、`tendsto_mult`、`tendsto_inverse`。
和式 $1+1/(n+1)$ 的极限先写成 $1+0$，再化成 $1$。

## 15.2 定理 15.2：向量按分量收敛

$x_n=(\alpha_{1n},\ldots,\alpha_{kn})$ 收敛到 $x=(\alpha_1,\ldots,\alpha_k)$，当且仅当每个分量
$\alpha_{jn}\to\alpha_j$。

一个方向：分量的绝对值不超过向量的范数，所以向量距离小于 $\varepsilon$ 时，每个分量也小于 $\varepsilon$。

另一个方向要先把 $\varepsilon$ 分给 $k$ 个分量。对每个 $j$，让 $|\alpha_{jn}-\alpha_j|<\varepsilon/\sqrt{k}$。
取这些下标的最大者，则

$$
|x_n-x|=\sqrt{\sum_{j=1}^k|\alpha_{jn}-\alpha_j|^2}<\sqrt{k\cdot\frac{\varepsilon^2}{k}}=\varepsilon.
$$

$(1/n,\ 3)\to(0,\ 3)$。$(1/n,\ 3,\ n^2)$ 不收敛，因为第三分量发散。
平面上的等价关系是：配对之后的序列收敛，恰好是两个实序列都收敛。

```lean
theorem pair_tendsto_iff {u v : ℕ → ℝ} {a b : ℝ} :
    Tendsto (fun n => (u n, v n)) atTop (nhds (a, b)) ↔
      Tendsto u atTop (nhds a) ∧ Tendsto v atTop (nhds b) := by
  constructor
  · intro h
    exact ⟨(continuous_fst.tendsto (a, b)).comp h, (continuous_snd.tendsto (a, b)).comp h⟩
  · rintro ⟨hu, hv⟩
    exact hu.prodMk_nhds hv
```

正向用连续的投影 $\mathrm{fst}$、$\mathrm{snd}$ 去复合整条极限。反向用 `prodMk_nhds` 把两条极限配回去。

```lean
theorem harmonic_pair :
    Tendsto (fun n : ℕ => (1 / ((n : ℝ) + 1), (3 : ℝ))) atTop (nhds ((0 : ℝ), 3)) :=
  tendsto_one_div_add_atTop_nhds_zero_nat.prodMk_nhds tendsto_const_nhds
```

第二个分量是常数 $3$，计算通道核对 $3-3=0$。Isabelle 用 `tendsto_Pair`。

## 15.3 定理 15.3：$\mathbb{R}^k$ 上的运算

分量都收敛之后，定理 15.1 可以用在每个坐标上，再用定理 15.2 装回向量。

1. $x_n+y_n\to x+y$，因为每个坐标的和收敛。
2. 若 $\beta_n\to\beta$，则 $\beta_n x_n\to\beta x$。常数 $c$ 是 $\beta_n=c$ 的特例。
3. 内积 $x_n\cdot y_n=\sum_j x_{jn}y_{jn}$。每一项乘积收敛，有限个和仍收敛，极限是 $x\cdot y$。

$k>1$ 时没有除法。$\mathbb{C}$ 有除法，那是另一套乘法。

二维内积就是两个乘积之和：

```lean
theorem dot_limit {u v : ℕ → ℝ × ℝ} {a b : ℝ × ℝ}
    (hu : Tendsto u atTop (nhds a)) (hv : Tendsto v atTop (nhds b)) :
    Tendsto (fun n => (u n).1 * (v n).1 + (u n).2 * (v n).2) atTop
      (nhds (a.1 * b.1 + a.2 * b.2)) := by
  have hu1 := (continuous_fst.tendsto (x := a)).comp hu
  have hu2 := (continuous_snd.tendsto (x := a)).comp hu
  have hv1 := (continuous_fst.tendsto (x := b)).comp hv
  have hv2 := (continuous_snd.tendsto (x := b)).comp hv
  exact (hu1.mul hv1).add (hu2.mul hv2)
```

先投影，再相乘，最后把两个坐标的乘积加起来。

## 15.4 定义 15.4：子序列

$\{n_k\}$ 是严格递增的自然数序列：$n_1<n_2<\cdots$。$\{p_{n_k}\}$ 是 $\{p_n\}$ 的子序列。
下标列表本身不是子序列，抽出来的项才是。

子序列必须无限。$p_1,p_3,p_{100}$ 只有三项，下标 $1,3,100$ 也不是一条序列。
若子序列收敛到 $p$，则 $p$ 是原序列的一个子序列极限。

## 15.5 例 15.5

1. 常数序列 $s_n=1$，取奇数下标 $n_k=2k-1$，抽出来仍是 $1,1,1,\ldots$。
2. $s_n=i^n$ 在四个值上打转，整条序列发散。取 $n_k=4k$，得到 $1,1,1,\ldots$，所以 $1$ 是子序列极限，却不是序列的极限。
3. $p_n=(-1)^n+(-1)^n/n$。偶数下标给出 $1+1/(2k)\to 1$，奇数下标给出趋于 $-1$ 的子序列。两个“准极限”都是子序列极限，序列本身发散。

形式化用更干净的 $(-1)^n$。偶数下标 $2k$ 严格递增，奇数下标 $2k+1$ 也是。
$(-1)^{2k}=((-1)^2)^k=1$，$(-1)^{2k+1}=-1$。

```lean
theorem even_strictMono : StrictMono (fun k : ℕ => 2 * k) := by
  intro a b hab
  simpa [two_mul] using Nat.add_lt_add hab hab
```

$a<b$ 时 $a+a<b+b$，而 $2k=k+k$。奇数下标再在右边加 $1$，不等号保持。

```lean
theorem even_alt : Tendsto (fun k : ℕ => (-1 : ℝ) ^ (2 * k)) atTop (nhds 1) := by
  have heq : (fun k : ℕ => (-1 : ℝ) ^ (2 * k)) = fun _ => (1 : ℝ) := by
    ext k
    rw [pow_mul]
    norm_num
  rw [heq]
  exact tendsto_const_nhds
```

`pow_mul` 把指数 $2k$ 拆成先平方再取 $k$ 次。奇数项先拆出最后一个因子 $-1$。
计算通道核对：$n=2,4,6$ 的符号都是 $+1$，$n=1,3,5$ 都是 $-1$，而且 $2<4<6$。

Isabelle 用 `power_mult` 得到同样的常数列，再交给 `tendsto_const`。

## 15.6 定理 15.6：收敛当且仅当每条子序列都收敛到同一点

若 $p_n\to p$，给定 $\varepsilon>0$ 有 $N$，使 $n\ge N$ 时 $d(p_n,p)<\varepsilon$。
下标 $n_k$ 随 $k$ 增大，所以 $k\ge N$ 推出 $n_k\ge N$，于是 $d(p_{n_k},p)<\varepsilon$。

```lean
theorem subseq_of_tendsto {s : ℕ → ℝ} {p : ℝ} {φ : ℕ → ℕ}
    (hs : Tendsto s atTop (nhds p)) (hφ : StrictMono φ) :
    Tendsto (s ∘ φ) atTop (nhds p) :=
  hs.comp hφ.tendsto_atTop
```

严格递增的 $\varphi:\mathbb{N}\to\mathbb{N}$ 自己趋向无穷，`tendsto_atTop` 记下这件事。
外层极限再复合上去。Isabelle 的名字是 `LIMSEQ_subseq_LIMSEQ`。

反过来：序列就是它自己的子序列，下标取 $n_k=k$。恒等函数严格递增。
若每条子序列都收敛到 $p$，把这条用上去就得到 $p_n\to p$。

```lean
theorem tendsto_of_all_subseq {s : ℕ → ℝ} {p : ℝ}
    (h : ∀ φ : ℕ → ℕ, StrictMono φ → Tendsto (s ∘ φ) atTop (nhds p)) :
    Tendsto s atTop (nhds p) := by
  simpa using h id strictMono_id
```

因此 $(-1)^n$ 不收敛。假如它收敛到某个 $p$，偶子序列和奇子序列都收敛到 $p$。
可是它们分别收敛到 $1$ 和 $-1$，极限唯一，于是 $1=-1$。

## 15.7 定理 15.7：紧空间里的序列有收敛子序列

推论 14.9 说的是紧集的无限子集里能找到一条收敛序列，那些点没有预先排好的顺序。
这里的对象是已经排好的序列，要找的是它的子序列，下标必须越来越大。

只知道一串点落在值域里，还不能把它叫子序列。$p_n=n^2$ 的值域含有常数序列 $1,1,1,\ldots$，
但 $1$ 在 $\{n^2\}$ 里只出现一次，抽不出无限多项等于 $1$。顺序也不一定还保持原来的先后。

证明分两种情形。

值域有限时，无限多项里至少有一个值 $p$ 出现无限次。把这些出现的下标按大小排成
$n_1<n_2<\cdots$，子序列是常数 $p$，收敛到 $p$。

值域无限时，紧集里有一个极限点 $p$。每个邻域含有值域的无限多个点，所以下标可以一直往后挑：

1. 在半径 $1$ 的邻域里取 $p_{n_1}$，$d(p_{n_1},p)<1$。
2. 已经取到 $n_i$ 之后，半径 $1/(i+1)$ 的邻域仍有无限多个值域中的点。小于 $n_i$ 的下标只有有限个，所以还能找到 $n_{i+1}>n_i$，使 $d(p_{n_{i+1}},p)<1/(i+1)$。

于是 $d(p_{n_i},p)<1/i$。仍取 $N=\lceil 1/\varepsilon\rceil+1$，这条子序列收敛到 $p\in X$。

闭区间 $[0,1]$ 是紧的，落在里面的序列就有这种子序列，极限还在区间里：

```lean
theorem unit_interval_subseq {s : ℕ → ℝ} (hs : ∀ n, s n ∈ Icc (0 : ℝ) 1) :
    ∃ a ∈ Icc (0 : ℝ) 1, ∃ φ : ℕ → ℕ, StrictMono φ ∧ Tendsto (s ∘ φ) atTop (nhds a) :=
  isCompact_Icc.tendsto_subseq hs
```

`StrictMono φ` 保证抽出来的是子序列。Isabelle 把这件事记成 `seq_compact {0..1}`：
紧区间在第一可数空间里序列紧，`compact_imp_seq_compact` 用在 `compact_interval` 上。

## 15.8 定理 15.8：波尔查诺–魏尔斯特拉斯

$\mathbb{R}^k$ 中的有界序列有一条收敛子序列。这和魏尔斯特拉斯定理（有界无限集有极限点）不是同一句话。

值域 $E$ 有界，所以落在某个 $k$ 维格子 $I$ 里。格子紧，序列落在紧集里，定理 15.7 给出收敛子序列，极限在 $I$ 里，因而在 $\mathbb{R}^k$ 里。

```lean
theorem bolzano_weierstrass {s : ℕ → ℝ} {E : Set ℝ}
    (hE : IsBounded E) (hs : ∀ n, s n ∈ E) :
    ∃ a ∈ closure E, ∃ φ : ℕ → ℕ, StrictMono φ ∧ Tendsto (s ∘ φ) atTop (nhds a) :=
  tendsto_subseq_of_bounded hE hs
```

这里把格子收成值域的闭包：有界集的闭包紧，极限在闭包里。它可能不在 $E$ 自己里面。

## 15.9 定理 15.9：子序列极限组成闭集

$E^\*$ 是 $\{p_n\}$ 的全部子序列极限。它在所在空间里是闭的。

若从某项起序列恒等于 $q$，则每条子序列都收敛到 $q$，$E^\*=\{q\}$，单点集是闭的。

否则 $q$ 是 $E^\*$ 的极限点时，要造一条收敛到 $q$ 的子序列。第一步只能保证挑到的 $p_{n_1}\neq q$，
距离是某个 $\delta>0$，未必小于 $1$。后面的半径就改用 $\delta/(i+1)$：在 $q$ 附近取另一个子序列极限 $x$，
再沿收敛到 $x$ 的那条子序列，把下标推到已经用过的 $n_i$ 之后。三角不等式把距离压到 $\delta/(i+1)$。
最后 $N=\lceil \delta/\varepsilon\rceil+1$ 仍然够用，因为 $\delta$ 只是一个固定的正数。

$(-1)^n$ 的两条子序列分别给出极限 $-1$ 和 $1$。这两个点的并是闭集：

```lean
theorem two_limits_closed : IsClosed ({(-1 : ℝ)} ∪ {1}) :=
  isClosed_singleton.union isClosed_singleton
```

两个单点都闭，有限并保持闭。一般的 $E^\*$ 要靠上面的 $\delta$ 构造，而不是只靠这两个点。

## 15.10 七通道对照

| 主题 | Lean | Isabelle | Coq | Agda | 计算三通道 |
|------|------|----------|-----|------|------------|
| 和 | `Tendsto.add` | `tendsto_add` | 误差等于 $1/11$ | — | $(1/11+1)-1=1/11$ |
| 数乘 | `const_mul` | `tendsto_mult_left` | $3/11<3/10$ | — | 同一对分数 |
| 积 | `Tendsto.mul` | `tendsto_mult` | $n=10$ 的距离 $<1/2$ | — | 同一处 |
| 倒数 | `inv₀` | `tendsto_inverse` | $10/11$ 到 $1$ 的距离 | — | 距离 $1/11$ |
| 分量 | `prodMk_nhds` 与投影 | `tendsto_Pair` | 第二分量距离 $0$ | — | $3-3=0$ |
| 子序列下标 | $2k$ 与 $2k+1$ | `strict_monoI` | $2<4<6$ | $2<4$，以及 $n<n+1$ | 偶数项为 $1$，奇数项为 $-1$ |
| 收敛传给子序列 | `Tendsto.comp` | `LIMSEQ_subseq_LIMSEQ` | — | — | — |
| 紧区间 | `isCompact_Icc.tendsto_subseq` | `seq_compact {0..1}` | — | — | — |
| 有界序列 | `tendsto_subseq_of_bounded` | — | — | — | — |
| 两个极限点的并 | 两个单点的并 | — | — | — | — |

## 15.11 本章验证清单

- `examples/lean/Realanalysis/Ch15Subsequences.lean`：四则运算、分量、内积、偶奇子序列、紧区间与有界序列。
- `examples/isabelle/RA15/Subsequences.thy`：同样的运算、平面上的点列、子序列保持极限、$(-1)^n$ 不收敛、区间序列紧。
- `examples/coq/Ch15_subsequences.v`：具体的误差、符号和递增下标。
- `examples/agda/Ch15_subsequences.agda`：下标严格前进，$2<4$。
- `examples/julia/15_subsequences.jl`、`examples/python/15_subsequences.py`、`examples/prolog/15_subsequences.pl`：同一组分数和偶奇分裂。

复验：`pwsh -NoProfile -Command '& ./build.ps1 -Chapter 15'`。

## 15.12 接下来

下一章看柯西序列：比的是项与项的距离，不再把极限写进定义。
单调序列的收敛也在那里。子序列极限的上、下确界，以及“发散”和“发散到无穷”的区分，还要再等一章。
