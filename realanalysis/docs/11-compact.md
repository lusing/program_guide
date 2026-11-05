# 第 11 章 紧集

> 对应原书第 11 章。开集、闭集讲的是一个点附近的样子。紧集讲的是整块
> 集合能不能被有限个开集盖住。这一章只证明紧集必闭、必有界，以及有限集、
> 闭子集、嵌套交这些性质。哪些集合是紧的，要到下一章的海涅–博雷尔定理。

## 11.1 定义 11.1 与 11.3：开覆盖

**定义.** $\{G_\alpha\}$ 是 $E$ 的开覆盖，若每个 $G_\alpha$ 都是开集，并且
$E\subset\bigcup_\alpha G_\alpha$。有限子覆盖是从中挑出有限个，并起来仍然盖住 $E$。

要紧的是集合的个数有限，不是每个开集里的点有限。一个邻域可以装进无限个点。

**例 11.2.** $\{(z-2,z+2):z\in\mathbb{Z}\}$ 盖住 $[-3,3]$，因为每个长度 $4$ 的
开区间都是开集，整数点又铺满了这段。
$\{(-4,0),(-1,3),(2,6)\}$ 是其中一个有限子覆盖。

```lean
example : Icc (-3 : ℝ) 3 ⊆ Ioo (-4) 0 ∪ Ioo (-1) 3 ∪ Ioo 2 6 := by
  intro x hx
  rcases lt_or_ge x 0 with h0 | h0
  · refine Or.inl (Or.inl ?_)
    constructor <;> linarith [hx.1, h0]
  · rcases lt_or_ge x 3 with h3 | h3
    · refine Or.inl (Or.inr ?_)
      constructor <;> linarith [h0, h3]
    · refine Or.inr ?_
      have hx3 : x = 3 := le_antisymm hx.2 h3
      constructor <;> linarith [hx3]
```

$x\in[-3,3]$。若 $x<0$，则 $-4<x<0$。若 $0\le x<3$，则 $-1<x<3$。若
$x\ge 3$，上界又是 $x\le 3$，所以 $x=3$，它落在 $(2,6)$ 里。三个开集的并
是左结合的，所以先 `Or.inl` 再 `Or.inl` 才是最左边那个区间。

给 $E$ 的每个点 $p$ 任取半径 $r_p>0$，则 $\{N_{r_p}(p):p\in E\}$ 是 $E$ 的
开覆盖：每个点落在以自己为心的邻域里，邻域本身是开集。若 $E$ 有限，这个
覆盖里开集的个数已经有限，它就是自己的有限子覆盖。

**定义 11.3.** $K$ 是紧集，若 $K$ 的每一个开覆盖都有有限子覆盖。

证明“是紧集”要检查所有开覆盖。证明“不是”只要举出一个没有有限子覆盖的
开覆盖。

```lean
example {K : Set ℝ} {ι : Type} {U : ι → Set ℝ} (hK : IsCompact K)
    (hU : ∀ i, IsOpen (U i)) (hcov : K ⊆ ⋃ i, U i) :
    ∃ t : Finset ι, K ⊆ ⋃ i ∈ t, U i :=
  hK.elim_finite_subcover U hU hcov
```

`Finset` 是有限指标集。结论是存在有限个下标，对应的开集之并仍盖住 $K$。

## 11.2 例 11.4：空集、单点、有限集

空集是紧的：任意开覆盖里随便取一个开集（若覆盖是空族，空集本来就被空并
盖住），$\emptyset$ 是任何集合的子集。

单点 $\{p\}$：开覆盖里至少有一个开集含有 $p$，取那一个就够了。

有限个点 $p_1,\ldots,p_n$：对每个 $p_i$ 从覆盖里挑一个含它的开集。已经挑过
的可以复用。最多 $n$ 步，得到有限子覆盖。

```lean
example : IsCompact (∅ : Set ℝ) := isCompact_empty
example (p : ℝ) : IsCompact ({p} : Set ℝ) := isCompact_singleton
example : IsCompact ({0, 1} : Set ℝ) := by
  have : ({0, 1} : Set ℝ).Finite := by simp
  exact this.isCompact
```

Isabelle 里 `compact {}`、`compact {p}` 是化简规则，`finite K ⟹ compact K`
是 `finite_imp_compact`。Agda 把这件事缩成两个点：每个点的“邻域”只含自己，
两条 `refl` 说明两个邻域一起盖住了两点。

## 11.3 定理 11.5：开区间不是紧集

**定理.** $a<b$ 时，$(a,b)$ 不是紧集。$(a,b)\cap\mathbb{Q}$ 也不是。

书上的覆盖是
$G_n=(a+1/n,\,b-1/n)$（退化成空区间的那些项丢掉）。对 $a<x<b$，阿基米德
性质给出足够大的 $N$，使 $x$ 落进 $G_N$，所以这族开集盖住 $(a,b)$。它们还
是嵌套的：$m>n$ 时 $G_m\supset G_n$，因此前 $N$ 个的并就是 $G_N$。而
$a+1/(2N)$ 仍在 $(a,b)$ 里，却不大于 $a+1/N$，所以不在 $G_N$ 里。任何有限
子覆盖的并都装不进这个点。

取 $a=0$、$b=1$、$N=4$：要比较的是 $1/8$ 和 $1/4$。

```coq
Lemma eighth_lt_fourth : / 8 < / 4.
Proof.
  apply Rinv_lt_contravar.
  - assert (H4 : 0 < 4) by lra.
    assert (H8 : 0 < 8) by lra.
    apply Rmult_lt_0_compat; assumption.
  - exact four_lt_eight.
Qed.
```

`Rinv_lt_contravar` 要求 $0<r_1 r_2$，然后 $r_1<r_2$ 推出 $1/r_2<1/r_1$。
这里 $4<8$，所以 $1/8<1/4$。于是 $1/8$ 在 $(0,1)$ 里，却不在 $(1/4,3/4)$ 里。
Julia、Python、Prolog 对 $N=1,\ldots,20$ 重复这件事：$1/(2N)$ 总在 $(0,1)$
里，总在 $(1/N,\,1-1/N)$ 的左边。

定理 11.7 给出一条更短的路。紧集一定是闭集，逆否命题是：在某个空间里不闭，
就在任何空间里都不紧。$(0,1)$ 在 $\mathbb{R}$ 里不闭，因为 $1$ 是极限点。
所以 $(0,1)$ 不是紧集。

```lean
example : ¬ IsCompact (Ioo (0 : ℝ) 1) := by
  intro h
  have hc : IsClosed (Ioo (0 : ℝ) 1) := h.isClosed
  have h1 : (1 : ℝ) ∈ closure (Ioo 0 1) := by
    rw [closure_Ioo (by norm_num : (0 : ℝ) ≠ 1)]
    simp
  rw [hc.closure_eq] at h1
  simp at h1
```

假设它紧，则它闭，闭包等于它自己。$(0,1)$ 的闭包是 $[0,1]$，$1$ 在闭包里，
于是 $1$ 得在 $(0,1)$ 里，也就是 $1<1$。

Agda 只保留“有限界外面还有更大的下标”这一步：`n < suc n`，并且
`suc n ≤ n` 是空的。任何有限的 $N$ 都被 $N+1$ 跨过去。

## 11.4 定理 11.6：紧不依赖所在的空间

开和闭是相对的。紧不是。$K$ 在某个包含它的度量空间里紧，就在每一个包含它
的度量空间里紧。因此可以说“紧度量空间”，不必交代它嵌在谁里面。任何度量
空间作为自己的子集既开又闭，所以“开度量空间”“闭度量空间”没有同样的意思。

**定理.** $K\subset Y\subset X$。$K$ 相对于 $X$ 紧，当且仅当相对于 $Y$ 紧。

一个方向：把 $Y$ 里的开覆盖 $V_\alpha=Y\cap G_\alpha$ 扩成 $X$ 里的开集
$G_\alpha$，取出有限子覆盖，再交回 $Y$。另一个方向把 $X$ 里的开集交上 $Y$，
得到 $Y$ 里的开覆盖。

Lean 里子类型的含入是嵌入。嵌入保持紧性：子空间里的 $K$ 紧，当且仅当它在
全空间里的像紧。

```lean
example {Y : Set ℝ} {K : Set Y} : IsCompact K ↔ IsCompact (Subtype.val '' K) :=
  Topology.IsEmbedding.subtypeVal.isCompact_iff
```

Isabelle 写成：若 $K\subset Y$，则
`compactin (top_of_set Y) K ⟷ compact K`。`top_of_set Y` 是 $Y$ 上的子空间
拓扑，`compactin euclidean` 就是全直线上的 `compact`。

## 11.5 定理 11.7–11.9：紧集是闭的，闭子集仍紧

**定理 11.7.** 紧子集是闭集。

证明补集是开集。取 $p\notin K$。对每个 $q\in K$ 令
$W_q=N_{d(p,q)/3}(q)$。这是 $K$ 的开覆盖。紧性给出有限个 $q_1,\ldots,q_n$。
令 $d$ 为 $d(p,q_i)$ 的最小值，$V=N_{d/3}(p)$。三角不等式让 $V$ 碰不到任何一个
$W_{q_i}$，所以 $V$ 碰不到 $K$，$V$ 落在补集里。有限在这里不能省：无限个距离
不一定有最小值。

```lean
example {K : Set ℝ} (h : IsCompact K) : IsClosed K := h.isClosed
```

**定理 11.8.** $K$ 紧，$F\subset K$ 且 $F$ 闭，则 $F$ 紧。

$F$ 在 $K$ 里的补集是 $K$ 的开集。把它添进 $F$ 的开覆盖，得到 $K$ 的开覆盖。
取出有限子覆盖，再丢掉那个补集，剩下的盖住 $F$。

**推论 11.9.** $K$ 紧、$F$ 闭，则 $F\cap K$ 紧。$K$ 自己是闭的，闭集的交仍闭，
再套定理 11.8。

```lean
example {K F : Set ℝ} (hK : IsCompact K) (hF : IsClosed F) (hsub : F ⊆ K) :
    IsCompact F :=
  hK.of_isClosed_subset hF hsub
example {K F : Set ℝ} (hK : IsCompact K) (hF : IsClosed F) : IsCompact (F ∩ K) :=
  hK.inter_left hF
```

有一段话看起来像矛盾，其实是用错了空间。设 $X=(-3,3)$，$F=X$，则 $F$ 在
$X$ 里闭。若 $K=[-5,5]$ 是紧的，推论似乎推出 $F\cap K=(-3,3)$ 紧，这和定理
11.5 冲突。错处是：$[-5,5]$ 不是 $X$ 的子集，$4$ 在 $[-5,5]$ 里，不在
$(-3,3)$ 里。推论要求紧集和闭集活在同一个空间里。换成 $K=[-2,2]\subset X$，
交集 $[-2,2]$ 确实紧，但那是下一章才证明的事实，这里还不能拿来用。

```lean
example : ¬ (Icc (-5 : ℝ) 5 ⊆ Ioo (-3) 3) := by
  intro h
  have h4 : (4 : ℝ) ∈ Icc (-5) 5 := by
    rw [mem_Icc]
    constructor <;> norm_num
  have hmem : (4 : ℝ) ∈ Ioo (-3) 3 := h h4
  simp [mem_Ioo] at hmem
  linarith
```

$4\le 5$ 而且 $-5\le 4$，所以 $4$ 在闭区间里。包含把它送进 $(-3,3)$，于是
$4<3$。

## 11.6 定理 11.10：紧集有界

**定理.** 紧集有界。

证逆否命题。若 $K$ 无界，半径 $1$ 的邻域族 $\{N_1(p):p\in K\}$ 是开覆盖。
若它有有限子覆盖 $N_1(p_1),\ldots,N_1(p_n)$，令
$r=\max_i d(p_1,p_i)$。则每个 $N_1(p_i)$ 都落在 $N_{r+1}(p_1)$ 里。无界说明
存在 $p\in K$ 使 $d(p,p_1)>r+1$，这个 $p$ 不在有限子覆盖里。

```lean
example {K : Set ℝ} (h : IsCompact K) : IsBounded K := h.isBounded
```

整条实直线无界：若所有点的范数都 $\le a$，则 $|a|+1$ 的范数是 $|a|+1$，它
大于 $a$。因此 $\mathbb{R}$ 不是紧集。Isabelle 先从 `bounded_iff` 取出这个
$a$，再用 `bspec` 把 $|a|+1$ 代进去。

## 11.7 定理 11.11–11.13：交集与极限点

**定理 11.11.** 一族非空紧集，若任意有限个的交都非空，则整个交非空。

无限交可以作怪。令 $B_n=(-1/n,0)\cup(0,1/n)$。$m>n$ 时 $B_m\subset B_n$，所以
任意有限交等于其中最小的那个，不是空集。全体的交是空的：非零点终会被某个
$1/n$ 甩掉，$0$ 从一开始就不在任何一个 $B_n$ 里。这些 $B_n$ 不闭，因此不紧。
紧集上这种事不会发生。

证明用反证法。若 $\bigcap_\alpha K_\alpha=\emptyset$，取其中一个紧集 $K_1$，则
$K_1$ 被其余集合的补集盖住。补集是开集，紧性给出有限子覆盖，于是 $K_1$ 与
那有限个 $K_{\alpha_i}$ 的交是空的，和假设矛盾。集合论上的钥匙是

$$
A\cap\bigcap_\alpha B_\alpha=\emptyset\iff A\subset\bigcup_\alpha B_\alpha^c.
$$

Isabelle 的 `compact_fip` 把这件事写成闭集族的有限交性质：每个有限子族与
$U$ 相交非空，则整个族与 $U$ 相交非空。

**推论 11.12.** 非空紧集 $K_1\supset K_2\supset K_3\supset\cdots$，则
$\bigcap_n K_n\neq\emptyset$。

嵌套保证任意有限交等于最里面的那个，已经非空，再套定理 11.11。

```lean
example {t : ℕ → Set ℝ} (htd : ∀ i, t (i + 1) ⊆ t i) (htn : ∀ i, (t i).Nonempty)
    (ht0 : IsCompact (t 0)) (htcl : ∀ i, IsClosed (t i)) : (⋂ i, t i).Nonempty :=
  IsCompact.nonempty_iInter_of_sequence_nonempty_isCompact_isClosed t htd htn ht0 htcl
```

假设从 $K_0$ 起逐个缩小，每一项非空、闭，而且 $K_0$ 紧。后面的项是紧集的
闭子集，所以也紧。交非空。计算通道用非紧的 $(0,1/n)$ 作对照：每个有限交
$(0,1/k)$ 仍含 $1/(2k)$，但样本 $0,1/20,\ldots,1$ 里没有任何一点能留在所有
$(0,1/n)$（$n\le 40$）里。

**定理 11.13.** 紧集 $K$ 的无限子集 $E$ 在 $K$ 里至少有一个极限点。

若没有，则每个 $q\in K$ 有邻域至多含 $E$ 的一个点。这是 $K$ 的开覆盖，有限
子覆盖只能装进 $E$ 的有限个点，盖不住无限的 $E$，也盖不住 $K$。

```lean
example {K E : Set ℝ} (hK : IsCompact K) (hE : E.Infinite) (hsub : E ⊆ K) :
    ∃ x ∈ K, AccPt x (𝓟 E) :=
  hE.exists_accPt_of_subset_isCompact hK hsub
```

`AccPt x (𝓟 E)` 是 $x$ 作为 $E$ 的极限点：每个邻域都含有 $E$ 中不同于 $x$
的点。`𝓟 E` 是由 $E$ 生成的主滤子。Isabelle 的结论是
$\exists x\in K.\; x\ \mathrm{islimpt}\ E$。

有限子集没有这个结论。有限集没有极限点，因为极限点的每个邻域都要含无限个
点。

## 11.8 七通道对照

| 主题 | Lean | Isabelle | Coq | Agda | 计算三通道 |
|------|------|----------|-----|------|------------|
| 有限子覆盖 | `elim_finite_subcover` | 三个区间盖住 $[-3,3]$ | — | 两点各一个邻域 | 半整数网格 |
| 有限集紧 | `Finite.isCompact` | `finite_imp_compact` | — | 同上 | — |
| 开区间不紧 | 不闭则不紧 | `compact_imp_closed` | $1/8<1/4$ | $n<\mathrm{suc}\,n$ | $1/(2N)$ 漏出 |
| 相对紧 | 嵌入保持紧 | `compactin (top_of_set Y)` | — | — | — |
| 闭且有界 | `IsClosed`、`IsBounded` | `compact_imp_closed/bounded` | — | — | — |
| 嵌套交 | `nonempty_iInter_of_sequence` | `compact_nest` | — | — | $(0,1/n)$ 的交是空的 |
| 极限点 | `AccPt` | `islimpt` | — | — | — |

## 11.9 本章验证清单

- `examples/lean/Realanalysis/Ch11Compact.lean`：有限子覆盖、三个区间的例子、
  有限集、开区间、相对紧、闭子集、有界、嵌套交、极限点。
- `examples/isabelle/RA11/CompactSets.thy`：同上，并证明全直线无界所以不紧。
- `examples/coq/Ch11_compact.v`：$1/8$ 落在第 $4$ 个区间的左边。
- `examples/agda/Ch11_compact.agda`：有限下标外面还有更大的下标，两点的覆盖。
- `examples/julia/11_compact.jl`、`examples/python/11_compact.py`、
  `examples/prolog/11_compact.pl`：有限子覆盖与漏点。

复验：`pwsh -NoProfile -Command '& ./build.ps1 -Chapter 11'`。

## 11.10 接下来

紧集的性质齐了，还不知道 $\mathbb{R}^k$ 里谁是紧的。下一章证明海涅–博雷尔
定理：$\mathbb{R}^k$ 的子集紧，当且仅当它既闭又有界。闭区间 $[a,b]$ 因此
是紧的。
