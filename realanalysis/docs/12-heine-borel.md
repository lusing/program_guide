# 第 12 章 海涅–博雷尔定理

> 对应原书第 12 章。上一章证明了：紧集一定是闭的，也一定是有界的。
> 这一章证明反过来的方向，但只在 $\mathbb{R}^k$ 里成立。$\mathbb{R}^k$ 的子集
> 是紧集，当且仅当它既闭又有界。闭区间和 $k$ 维格子因此都是紧的。

## 12.1 定理 12.1：闭区间套

**定理.** 设 $I_n=[a_n,b_n]$，并且 $I_n\supset I_{n+1}$。则
$\bigcap_{n=1}^\infty I_n\neq\emptyset$。

嵌套写成三条：每段自己非空，$a_n\le b_n$；左端点越来越大；右端点越来越小。
这一步用的是实数的最小上界，紧性要等格子证明完才用得上。

取 $E=\{a_n:n\in\mathbb{N}\}$，$x=\sup E$。每个右端点都是 $E$ 的上界：
若某个 $a_m>b_n$，则 $[a_m,b_m]$ 与 $[a_n,b_n]$ 不相交，嵌套就被破坏了。
于是 $E$ 非空且有上界，$x$ 存在。$x$ 是上界，所以 $x\ge a_n$。$b_n$ 也是上界，
而 $x$ 是最小的，所以 $x\le b_n$。因此 $x$ 落在每一段里。

```lean
theorem nestedIcc (a b : ℕ → ℝ) (hab : ∀ n, a n ≤ b n) (ha : Monotone a) (hb : Antitone b) :
    (⋂ n, Icc (a n) (b n)).Nonempty := by
  have hne : (range a).Nonempty := range_nonempty a
  have hbu : BddAbove (range a) := by
    refine ⟨b 0, mem_upperBounds.2 ?_⟩
    rintro y ⟨n, rfl⟩
    exact (hab n).trans (hb (Nat.zero_le n))
  refine ⟨sSup (range a), mem_iInter.2 fun n => ?_⟩
  refine mem_Icc.2 ⟨le_csSup hbu (mem_range_self n), ?_⟩
  apply csSup_le hne
  rintro y ⟨m, rfl⟩
  rcases le_total m n with hmn | hnm
  · exact (ha hmn).trans (hab n)
  · exact (hab m).trans (hb hnm)
```

`Monotone a` 是 $m\le n\Rightarrow a_m\le a_n$，`Antitone b` 是
$m\le n\Rightarrow b_n\le b_m$。`range a` 是左端点的集合。
$b_0$ 是它的一个上界：对任意 $n$，$a_n\le b_n$，又因为 $0\le n$，
右端点递减给出 $b_n\le b_0$。

交集里的点就是 `sSup (range a)`。它不小于每一个左端点，因为上确界是上界。
它也不大于 $b_n$：任意左端点 $a_m$ 都 $\le b_n$。$m\le n$ 时，
$a_m\le a_n\le b_n$；$n\le m$ 时，$a_m\le b_m\le b_n$。

Isabelle 的 `nested_closed_intervals` 取同一个 `Sup (range a)`。
证明先让每个 $b_n$ 成为左端点集的上界，再用 `cSup_upper` 和 `cSup_least`
把上确界夹进 $[a_n,b_n]$。交集里有这个点，所以交集不是空集。

计算通道看一族具体的套：$[0,\,1+1/(n+1)]$。$0$ 和 $1$ 都在前二十段里。

```python
def in_nested(x, n):
    return 0 <= x <= 1 + Fraction(1, n + 1)

assert all(in_nested(0, n) for n in range(20))
assert all(in_nested(1, n) for n in range(20))
```

`Fraction` 避免二进制小数。$n$ 从 $0$ 到 $19$，右端点从 $2$ 降到 $1+1/20$，
始终不小于 $1$。

Agda 把同一件事缩成有限的两段。$0$ 不超过两个右端点的较小者，所以 $0$
同时属于 $[0,m]$ 和 $[0,n]$。左端点可以再增大一步，交出来的右端点同时
不超过原来的两个右端点。

```agda
zero-in-inter : ∀ m n → 0 ≤ m ⊓ n
zero-in-inter m n = z≤n

left-grows : ∀ n → n ≤ suc n
left-grows = n≤1+n

inter-right : ∀ m n → m ⊓ n ≤ m × m ⊓ n ≤ n
inter-right m n = m⊓n≤m m n , m⊓n≤n m n
```

`z≤n` 是 $0\le n$。`n≤1+n` 是左端点往右挪一格。`m ⊓ n` 是两段右端点的
较小者，`m⊓n≤m` 和 `m⊓n≤n` 把它分别和 $m$、$n$ 比较。

## 12.2 定义 12.2：$k$ 维格子

$k$ 维格子是 $\mathbb{R}^k$ 里的闭盒子：每个坐标 $x_j$ 各自落在一个闭区间
$[a_j,b_j]$ 里，并且 $a_j<b_j$。$k=1$ 时它就是闭区间，$k=2$ 时是闭矩形，
$k=3$ 时是闭的长方体。

## 12.3 定理 12.3：格子也可以套

一族 $k$ 维格子若 $I_n\supset I_{n+1}$，则总交非空。

第 $n$ 个格子在第 $j$ 个坐标上切出闭区间 $I_{n j}=[a_{n j},b_{n j}]$。
格子嵌套，所以每个固定的 $j$，这些区间也嵌套。定理 12.1 在每个坐标上
给出一点 $x_j^\ast$。向量 $(x_1^\ast,\ldots,x_k^\ast)$ 的每个坐标都落在
对应的区间里，所以这个向量属于每一个格子。

## 12.4 定理 12.4：格子是紧的

**定理.** 每个 $k$ 维格子都是紧集。

书上的论证是对分。假设开覆盖 $\{G_\alpha\}$ 没有有限子覆盖。把每条边
一分为二，格子被切成 $2^k$ 个小格子，其中至少有一个仍然没有有限子覆盖。
记下它，再切。得到嵌套的格子 $I\supset I_1\supset I_2\supset\cdots$，
每个都不能被有限覆盖。定理 12.3 给出公共点 $x^\ast$。$x^\ast$ 落在某个
$G_1$ 里，$G_1$ 是开集，所以有半径 $r>0$ 使邻域 $N_r(x^\ast)\subset G_1$。

原来格子的对角线长记为 $\delta$。第 $n$ 次对分之后，小格子里任意两点的
距离不超过 $2^{-n}\delta$。阿基米德性质给出 $n$，使 $2^{-n}\delta<r$。
于是整个小格子落进 $N_r(x^\ast)$，也就是落进单独一个开集 $G_1$。
这和“小格子没有有限子覆盖”矛盾。所以原来的格子是紧的。

三次对分把长度 $1$ 变成 $1/8$，已经小于 $1/2$。Coq 用倒数比较来写这一步：
$0<2\cdot 8$ 且 $2<8$，所以 $1/8<1/2$。

```coq
Lemma eighth_lt_half : / 8 < / 2.
Proof.
  apply Rinv_lt_contravar.
  - assert (H2 : 0 < 2) by lra.
    assert (H8 : 0 < 8) by lra.
    apply Rmult_lt_0_compat; assumption.
  - lra.
Qed.
```

`Rinv_lt_contravar` 要求两个正数的乘积为正，并且分子那边更大的那个，
倒数更小。这里 $8>2$，所以 $/8</2$。

对角线为 $4$ 的格子，对分六次后长度是 $4/64$，小于 $1/10$。

```python
def bisect_len(n):
    return Fraction(4, 2**n)

assert bisect_len(6) < Fraction(1, 10)
```

形式化的结论直接用闭区间的紧性。一维格子是 `Icc a b`。
二维格子 $[0,1]\times[0,1]$ 是函数类型 `Fin 2 → ℝ` 上的区间 `Icc 0 1`：
两个坐标各自落在 $[0,1]$ 里。

```lean
example (a b : ℝ) : IsCompact (Icc a b) := isCompact_Icc

example : IsCompact (Icc (0 : Fin 2 → ℝ) 1) := isCompact_Icc
```

Isabelle 里一维是 `compact_interval`，正方形是两个紧区间的乘积
`compact_Times`。

## 12.5 定理 12.5：有界集落进某个格子

**定理.** $\mathbb{R}^k$ 的有界子集包含在某个 $k$ 维格子里。

有界是说：存在 $q$ 和 $M$，使每个点 $p$ 都满足 $|p-q|\le M$。
每个坐标都满足 $|p_j-q_j|\le M$，所以
$p_j\in[q_j-M,\,q_j+M]$。这些区间围出的格子装下了整个集合。
圆内接于正方形，球内接于立方体，是同一件事。

在 $\mathbb{R}$ 上，以 $c$ 为心、$r$ 为半径的闭球就是闭区间 $[c-r,\,c+r]$。

```lean
example (E : Set ℝ) (hE : IsBounded E) (c : ℝ) : ∃ r, E ⊆ Icc (c - r) (c + r) := by
  obtain ⟨r, hr⟩ := hE.subset_closedBall c
  exact ⟨r, by simpa [Real.closedBall_eq_Icc] using hr⟩
```

`subset_closedBall` 给出一个半径，集合落进闭球。
`Real.closedBall_eq_Icc` 把闭球改写成闭区间。

Isabelle 把有界写成范数：存在 $a$，使每个点的范数不超过 $a$。
取 $M=\max(a,0)$，集合就落进 $[-M,M]$。`abs_le_iff` 把
$|x|\le M$ 拆成 $-M\le x$ 并且 $x\le M$。

样本 $\{-3,-1,0,2,3\}$ 都在 $[-3,3]$ 里，$4$ 在外面。

```python
def in_cell(x):
    return Fraction(-3) <= x <= 3

sample = [Fraction(k) for k in (-3, -1, 0, 2, 3)]
assert all(in_cell(x) for x in sample)
assert not in_cell(4)
```

Coq 用同一个边界：$2$ 不能同时满足 $0\le 2$ 和 $2\le 1$。

```coq
Lemma two_outside_unit : ~ (0 <= 2 /\ 2 <= 1).
Proof.
  lra.
Qed.
```

另一侧，$1$ 仍在放大了的右端点之内：$0\le 1$ 并且 $1\le 1+1/2$。
`/2` 先由 `Rinv_0_lt_compat` 得到正数，`lra` 才能把它加到 $1$ 上。

## 12.6 定理 12.6：海涅–博雷尔定理

**定理.** $E\subset\mathbb{R}^k$ 是紧集，当且仅当 $E$ 是 $\mathbb{R}^k$ 中的闭集，
并且是 $\mathbb{R}^k$ 中的有界集。

紧集必闭、必有界，是上一章的定理 11.7 和 11.10。反过来：有界集落进某个
格子，格子是紧的，闭子集在紧集里仍然紧，这是定理 11.8。所以有界闭集是紧的。

```lean
example (E : Set ℝ) : IsCompact E ↔ IsClosed E ∧ IsBounded E :=
  isCompact_iff_isClosed_bounded
```

Isabelle 的同一句话是 `compact_eq_bounded_closed`：

```isabelle
lemma heine_borel:
  fixes E :: "real set"
  shows "compact E \<longleftrightarrow> bounded E \<and> closed E"
  by (rule compact_eq_bounded_closed)
```

`\<longleftrightarrow>` 是当且仅当。`real` 属于 `heine_borel` 类型类，这条等价只在这类空间上成立。

$(0,1)$ 有界，端点 $0$ 在它的闭包里，却不在它自己里面，所以它不是闭集。
海涅–博雷尔因此说它不是紧集。

```lean
example : IsBounded (Ioo (0 : ℝ) 1) ∧ ¬ IsCompact (Ioo (0 : ℝ) 1) := by
  refine ⟨isBounded_Ioo 0 1, ?_⟩
  intro h
  have hmem : (0 : ℝ) ∈ closure (Ioo (0 : ℝ) 1) := by
    rw [closure_Ioo (by norm_num : (0 : ℝ) ≠ 1), mem_Icc]
    exact ⟨by norm_num, by norm_num⟩
  rw [h.isClosed.closure_eq] at hmem
  simp [mem_Ioo] at hmem
```

`closure_Ioo` 在两端不同时把 $(0,1)$ 的闭包写成 $[0,1]$，$0$ 在里面。
若 $(0,1)$ 紧，则它是闭集，闭包等于它自己，$0$ 就得属于 $(0,1)$。
`mem_Ioo` 把这件事写成 $0<0$，`simp` 得到矛盾。

Isabelle 用右端点做同一件事：$(0,1)\subset[0,1]$，$[0,1]$ 紧所以有界，
子集保持有界。若 $(0,1)$ 紧，则它是闭集，`closure_eq` 让闭包等于它自己，
而 $1$ 在闭包里，于是 $1\in(0,1)$，不可能。

这个反向蕴涵依赖所在的空间是 $\mathbb{R}^k$。在 $\mathbb{Q}$ 里，
$(-\pi,\pi)\cap\mathbb{Q}$ 是有界的；$\pm\pi$ 不是有理数，所以它在 $\mathbb{Q}$
中是闭的。上一章那个逃出端点的开覆盖仍然没有有限子覆盖，所以它不是紧集。

## 12.7 定理 12.7：无限子集的极限点

在 $\mathbb{R}^k$ 里，下面三句话等价。

1. $E$ 既闭又有界。
2. $E$ 是紧集。
3. $E$ 的每个无限子集都在 $E$ 里有一个极限点。

第 1 句和第 2 句是海涅–博雷尔定理。第 2 句推出第 3 句是上一章的定理 11.13。
闭区间现在是紧的，所以可以直接用在 $[0,1]$ 上。

```lean
example {E : Set ℝ} (hE : E.Infinite) (hsub : E ⊆ Icc 0 1) :
    ∃ x ∈ Icc (0 : ℝ) 1, AccPt x (𝓟 E) :=
  hE.exists_accPt_of_subset_isCompact isCompact_Icc hsub
```

`AccPt x (𝓟 E)` 是 $x$ 作为 $E$ 的极限点：每个邻域都含有 $E$ 中异于 $x$ 的点。
结论把这个点留在 $[0,1]$ 里面。Isabelle 的
`infinite_in_interval_has_limit` 是同一句：`infinite E`、`E ⊆ {0..1}`
推出 $\exists x\in\{0..1\}.\; x\ \mathrm{islimpt}\ E$。

第 3 句推出第 2 句，书上走逆否。若 $E$ 无界，则对每个 $n$ 都能找到
$x_n\in E$ 使 $|x_n|>n$。$S=\{x_n\}$ 是 $E$ 的无限子集。任何点 $p$ 附近，
下标足够大的 $x_n$ 都离 $p$ 至少有距离 $1$，有限个近处的点可以再把半径
缩小，于是 $p$ 不是 $S$ 的极限点。若 $E$ 不是闭集，则有极限点 $x_0\notin E$。
对每个 $n$ 取 $x_n\in E$ 使 $|x_n-x_0|<1/n$。这个 $S$ 的唯一极限点是 $x_0$，
它不在 $E$ 里。两种情形都给出一个在 $E$ 中没有极限点的无限子集。

后两句的等价在一般度量空间里也成立。第 3 句推出紧性的一般证明很长，
$\mathbb{R}^k$ 里有海涅–博雷尔定理，不必再走那条路。

嵌套的非空交并不能倒过来刻画紧性。$\bigcap_n(-1/n,1/n)=\{0\}$，
每一段却都不是紧的。

## 12.8 定理 12.8：魏尔斯特拉斯定理

**定理.** $\mathbb{R}^k$ 的无限子集若有界，则它在 $\mathbb{R}^k$ 中有一个极限点。

有界集的闭包仍然有界，而且闭包总是闭的。海涅–博雷尔定理让这个闭包成为紧集。
无限子集在这个紧集里有一个极限点，这个点属于 $\mathbb{R}^k$。
它不必属于原来的集合。

```lean
example (E : Set ℝ) (hE : E.Infinite) (hb : IsBounded E) : ∃ x, AccPt x (𝓟 E) := by
  obtain ⟨x, -, hx⟩ :=
    hE.exists_accPt_of_subset_isCompact hb.isCompact_closure (subset_closure (s := E))
  exact ⟨x, hx⟩
```

`isCompact_closure` 是“有界集的闭包是紧的”。`subset_closure` 是
$E\subset\overline{E}$。极限点定理把点放在闭包里，这里只保留“它是 $E$ 的极限点”。

Isabelle 先用 `compact_closure`：有界当且仅当闭包紧。再对 $E\subset\overline{E}$
使用 `Heine_Borel_imp_Bolzano_Weierstrass`，得到闭包中的一个极限点。

$\{1/n:n=1,\ldots,20\}$ 全部落在 $(0,1]$ 里，第 $20$ 项 $1/20<1/10$，
已经靠近不在这个正项集合里的 $0$。

```python
seq = [Fraction(1, n) for n in range(1, 21)]
assert all(0 < x <= 1 for x in seq)
assert seq[-1] < Fraction(1, 10)
```

## 12.9 七通道对照

| 主题 | Lean | Isabelle | Coq | Agda | 计算三通道 |
|------|------|----------|-----|------|------------|
| 闭区间套 | `nestedIcc`，上确界 | `Sup (range a)` | $1\le 1+1/2$ | $0\le m\sqcap n$ | $0,1$ 留在每一段 |
| 格子紧 | `isCompact_Icc` | `compact_interval`、`compact_Times` | $1/8<1/2$ | — | 对分六次后 $4/64<1/10$ |
| 有界落进格子 | 闭球 $=$ `Icc` | $[-M,M]$ | $2\notin[0,1]$ | — | 样本落进 $[-3,3]$ |
| 海涅–博雷尔 | `isCompact_iff_isClosed_bounded` | `compact_eq_bounded_closed` | — | — | — |
| 有界而不紧 | $(0,1)$ 的闭包多出端点 | 同一件事用端点 $1$ | — | — | — |
| 魏尔斯特拉斯 | 闭包紧 | `compact_closure` | — | — | $1/n$ 靠近 $0$ |

## 12.10 本章验证清单

- `examples/lean/Realanalysis/Ch12HeineBorel.lean`：闭区间套、闭区间与正方形、
  有界集落进区间、海涅–博雷尔、$(0,1)$、极限点、魏尔斯特拉斯。
- `examples/isabelle/RA12/HeineBorel.thy`：同一组命题，区间套用 `cSup`。
- `examples/coq/Ch12_heineborel.v`：$1$ 仍在右端点内，$1/8<1/2$，$2$ 在 $[0,1]$ 外。
- `examples/agda/Ch12_heineborel.agda`：两段区间的交，以及左端点可以增大。
- `examples/julia/12_heineborel.jl`、`examples/python/12_heineborel.py`、
  `examples/prolog/12_heineborel.pl`：公共点、对分长度、格子和 $1/n$。

复验：`pwsh -NoProfile -Command '& ./build.ps1 -Chapter 12'`。

## 12.11 接下来

$\mathbb{R}^k$ 里哪些集合是紧的，已经清楚了。下一章看完备集和连通集：
康托尔集是完备的，区间是连通的。
