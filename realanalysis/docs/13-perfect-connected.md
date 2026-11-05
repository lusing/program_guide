# 第 13 章 完备集与连通集

> 对应原书第 13 章。完备集是闭集，而且它的每个点都是它自己的极限点。
> 这样的非空集合在 $\mathbb{R}^k$ 里一定不可数。康托尔集是完备的，却不含
> 任何开区间。这一章的后半段改看连通：在直线上，连通就是“两点之间的
> 点全都在里面”。

## 13.1 定理 13.1：实完备集不可数

**定义.** $P$ 是完备集，若 $P$ 是闭集，并且每个 $x\in P$ 都是 $P$ 的极限点。

闭区间 $[a,b]$ （$a<b$ ）就是这样。它是闭的。端点也是极限点：任意邻域里
都还有区间中的另一个点。

书上的一般证明先说明 $P$ 无限：一个极限点的每个邻域都含有无穷多个点。
再假设 $P=\{x_1,x_2,\ldots\}$ 可数。从 $x_1$ 的一个闭邻域 $V_1$ 出发，
因为 $x_1$ 是极限点，邻域里还有另一个点 $x_2$ 。把半径取得足够小，使新的
闭邻域 $V_2$ 含在 $V_1$ 里，并且把 $x_1$ 留在外面。照此做下去，
$K_n=V_n\cap P$ 是嵌套的非空紧集（$V_n$ 是有界闭集，由海涅–博雷尔定理是紧的；
$P$ 是闭集，闭集与紧集的交仍紧）。交集非空，但每个 $x_n$ 都被排除在
$K_{n+1}$ 之外，所以交集里的点不在这张可数名单上。矛盾。因此 $P$ 不可数。

闭区间是这个定理的直接例子。$(0,1)$ 已经不可数，它又是 $[0,1]$ 的子集，
子集若可数，母集可数，所以 $[0,1]$ 不可数。

```lean
example : ¬ (Icc (0 : ℝ) 1).Countable := by
  intro h
  have hsub : Ioo (0 : ℝ) 1 ⊆ Icc 0 1 := Ioo_subset_Icc_self
  exact (by simp : ¬ (Ioo (0 : ℝ) 1).Countable) (h.mono hsub)
```

`Countable` 在这里是至多可数。`Ioo_subset_Icc_self` 是 $(0,1)\subset[0,1]$ 。
`h.mono` 把 $[0,1]$ 的可数性传给子集。`simp` 否掉 $(0,1)$ 可数。

端点 $0$ 是极限点。任给邻域 $U$ ，里面有一个半径 $\varepsilon>0$ 的球。
取 $y=\min(\varepsilon/2,\,1/2)$ 。它比 $0$ 大，又不超过 $1$ ，所以在 $[0,1]$ 里；
它到 $0$ 的距离不超过 $\varepsilon/2$ ，所以在球里，也就在 $U$ 里。

```lean
example : AccPt (0 : ℝ) (𝓟 (Icc (0 : ℝ) 1)) := by
  rw [accPt_iff_nhds]
  intro U hU
  obtain ⟨ε, hε, hsub⟩ := Metric.mem_nhds_iff.mp hU
  set y : ℝ := min (ε / 2) (1 / 2)
  have hypos : 0 < y := by
    exact lt_min (by linarith) (by norm_num)
  refine ⟨y, ⟨?_, ?_⟩, ne_of_gt hypos⟩
  · apply hsub
    rw [mem_ball, Real.dist_eq, sub_zero, abs_of_pos hypos]
    have : y ≤ ε / 2 := min_le_left _ _
    linarith
  · rw [mem_Icc]
    exact ⟨hypos.le, (min_le_right _ _).trans (by norm_num)⟩
```

`AccPt` 说每个邻域都含有集合里另一个点。`mem_nhds_iff` 把邻域换成一个球。
`min_le_left` 保证 $y\le\varepsilon/2<\varepsilon$ ，`min_le_right` 保证 $y\le 1/2\le 1$ 。
`ne_of_gt` 说明 $y\neq 0$ 。

Isabelle 用同一句包含关系：开区间不可数，它含在闭区间里，所以闭区间不可数。
`countable_subset` 要求子集写在前面。

## 13.2 定义 13.2：康托尔集

从 $E_0=[0,1]$ 开始。删掉每个闭区间正中间的三分之一开区间。
$E_1=[0,1/3]\cup[2/3,1]$ ，$E_2$ 是四段长度为 $1/9$ 的闭区间，第 $n$ 步有
$2^n$ 段，每段长 $3^{-n}$ 。康托尔集是 $P=\bigcap_n E_n$ 。

每一步都是有限个闭区间的并，所以是闭集，又有界，于是紧。它们嵌套，
交集非空。$P$ 是闭集的交，所以是闭集，也有界，所以紧。

```lean
example : (0 : ℝ) ∈ cantorSet := zero_mem_cantorSet

example : (1 / 4 : ℝ) ∈ cantorSet := quarter_mem_cantorSet

example : cantorSet ⊆ Icc (0 : ℝ) 1 := cantorSet_subset_unitInterval

example : IsClosed cantorSet := isClosed_cantorSet

example : IsCompact cantorSet := isCompact_cantorSet
```

`cantorSet` 是所有 `preCantorSet n` 的交。第 $0$ 步是 $[0,1]$ ，后面每一步
是把上一步分别压到 $[0,1/3]$ 和 $[2/3,1]$ 。$0$ 和 $1/4$ 每次都还在。

自相似把这件事写成等式：康托尔集等于它自己的左三分之一，并上它自己的
右三分之一。

```lean
example :
    cantorSet = (· / 3) '' cantorSet ∪ (fun x : ℝ => (2 + x) / 3) '' cantorSet :=
  cantorSet_eq_union_halves
```

`(· / 3) '' cantorSet` 是把集合里每个点除以 $3$ 。`(2 + x) / 3` 是先加 $2$
再除以 $3$ ，也就是平移到右半段。

## 13.3 定理 13.4：不含开区间

$1/2$ 落在第一步删掉的 $(1/3,2/3)$ 里，所以不在康托尔集里。

```lean
example : (1 / 2 : ℝ) ∉ cantorSet := by
  intro h
  have h1 : (1 / 2 : ℝ) ∈ preCantorSet 1 := mem_iInter.mp h 1
  rw [preCantorSet_succ, preCantorSet_zero, mem_union] at h1
  rcases h1 with ⟨x, hx, hxeq⟩ | ⟨x, hx, hxeq⟩
  · rw [mem_Icc] at hx
    have hle : x / 3 ≤ (1 : ℝ) / 3 := by
      rw [div_le_div_iff_of_pos_right (by norm_num : (0 : ℝ) < 3)]
      linarith [hx.2]
    have hx' : x / 3 = 1 / 2 := hxeq
    rw [hx'] at hle
    norm_num at hle
  · rw [mem_Icc] at hx
    have hge : (2 : ℝ) / 3 ≤ (2 + x) / 3 := by
      rw [div_le_div_iff_of_pos_right (by norm_num : (0 : ℝ) < 3)]
      linarith [hx.1]
    have hx' : (2 + x) / 3 = 1 / 2 := hxeq
    rw [hx'] at hge
    norm_num at hge
```

$1/2$ 若在交集里，就在第一步里。第一步是两段的并。左段里的点不超过 $1/3$ ，
右段里的点至少是 $2/3$ 。$1/2$ 比 $1/3$ 大，又比 $2/3$ 小，两边都进不去。

一般的开区间 $(a,b)$ 也进不去。第 $n$ 步每段闭区间的长度是 $3^{-n}$ 。
$P$ 是每一段的子集，所以装不下比 $3^{-n}$ 更长的区间。阿基米德性质让
$3^{-n}<b-a$ 。第二步的长度已经是 $1/9$ ，而 $1/2>1/9$ 。

```coq
Lemma half_in_middle_third : 1 / 3 < 1 / 2 /\ 1 / 2 < 2 / 3.
Proof.
  lra.
Qed.

Lemma half_longer_than_ninth : 1 / 9 < 1 / 2.
Proof.
  lra.
Qed.
```

计算通道把前两步的区间写出来：$0$ 、$1/4$ 、$1$ 留在 $E_1$ 里，$1/2$ 被删掉；
$1/4$ 仍落在 $E_2$ 的 $[2/9,1/3]$ 里。$E_2$ 有 $2^2=4$ 段。

```python
def in_e1(x):
    return (0 <= x <= Fraction(1, 3)) or (Fraction(2, 3) <= x <= 1)

assert in_e1(0) and in_e1(Fraction(1, 4)) and in_e1(1)
assert not in_e1(Fraction(1, 2))
assert Fraction(1, 2) > Fraction(1, 9)
```

康托尔集不是这些闭区间的并，而是它们的无限交。无限交可以比每一段都小，
小到不含任何开区间。$P$ 仍然是闭集，每个点都是极限点：点 $x$ 落在某一步
的一段 $I_n$ 里，把 $n$ 取得使这段的长度小于邻域的直径，$I_n$ 就整个落进
邻域，而 $I_n$ 还有另一个端点。于是 $P$ 完备。再由定理 13.1，$P$ 不可数。

Agda 把“中间被挖掉”收成两个严格不等式，并把“段数不会变少”收成
$n\le n+n$ 。

```agda
gap : 0 < 1 × 1 < 2
gap = n<1+n 0 , n<1+n 1

pieces-grow : ∀ n → n ≤ n + n
pieces-grow n = m≤m+n n n
```

`n<1+n` 是 $n<\mathrm{suc}\,n$ 。$0<1$ 和 $1<2$ 说明 $1$ 夹在两段之间。
`m≤m+n` 是把段数加上一段至少同样多的段。

## 13.4 定义 13.6：分离

$A$ 与 $B$ 分离，是指 $A$ 碰不到 $B$ 的闭包，并且 $B$ 碰不到 $A$ 的闭包。
这比不相交更强。不相交只要求没有公共点；分离还要求谁都不是对方的极限点。

$[-3,0)$ 与 $(0,3]$ 分离。左边的闭包是 $[-3,0]$ ，它和 $(0,3]$ 不相交。
右边的闭包是 $[0,3]$ ，它和 $[-3,0)$ 不相交。

```lean
example :
    (Ico (-3 : ℝ) 0 ∩ closure (Ioc (0 : ℝ) 3) = ∅) ∧
      (closure (Ico (-3 : ℝ) 0) ∩ Ioc (0 : ℝ) 3 = ∅) := by
  constructor
  · rw [closure_Ioc (by norm_num : (0 : ℝ) ≠ 3), eq_empty_iff_forall_notMem]
    intro x hx
    simp [mem_Ico, mem_Icc] at hx
    linarith
  · rw [closure_Ico (by norm_num : (-3 : ℝ) ≠ 0), eq_empty_iff_forall_notMem]
    intro x hx
    simp [mem_Icc, mem_Ioc] at hx
    linarith
```

`closure_Ioc` 在两端不同时把 $(0,3]$ 的闭包写成 $[0,3]$ 。交里的点必须
同时满足 $x<0$ 和 $0\le x$ ，`linarith` 排除这种点。

$[-3,0]$ 与 $(0,3]$ 不相交，但 $0$ 在右边的闭包里，又在左边，所以不分离。

```lean
example : Icc (-3 : ℝ) 0 ∩ Ioc 0 3 = ∅ := by
  rw [eq_empty_iff_forall_notMem]
  intro x hx
  simp [mem_Icc, mem_Ioc] at hx
  linarith

example : (0 : ℝ) ∈ Icc (-3) 0 ∩ closure (Ioc 0 3) := by
  rw [closure_Ioc (by norm_num : (0 : ℝ) ≠ 3)]
  refine ⟨?_, ?_⟩ <;> simp [mem_Icc]
```

第一段：交里的点要 $x\le 0$ 并且 $x>0$ 。第二段：$0$ 同时属于 $[-3,0]$
和 $[0,3]$ 。

四种邻接可以记成一张表。$[a,b)$ 与 $(b,c]$ 既不相交也分离。$[a,b)$ 与
$[b,c]$ 不相交，但 $b$ 是左边的极限点，所以不分离。$[a,b]$ 与 $(b,c]$
同样不分离。$[a,b]$ 与 $[b,c]$ 连公共点都有。

**定理 13.8.** 分离集的子集仍然分离。闭包保持包含：$A_1\subset A$ 推出
$\overline{A_1}\subset\overline{A}$ 。于是 $A_1\cap\overline{B_1}$ 含在
已经是空集的 $A\cap\overline{B}$ 里。

```lean
example {A B A1 B1 : Set ℝ} (hAB : A ∩ closure B = ∅) (hBA : closure A ∩ B = ∅)
    (hA : A1 ⊆ A) (hB : B1 ⊆ B) : A1 ∩ closure B1 = ∅ ∧ closure A1 ∩ B1 = ∅ := by
  constructor
  · rw [eq_empty_iff_forall_notMem]
    intro x hx
    have hxA : x ∈ A := hA hx.1
    have hxB : x ∈ closure B := closure_mono hB hx.2
    have : x ∈ (∅ : Set ℝ) := by
      rw [← hAB]
      exact ⟨hxA, hxB⟩
    exact this
  · rw [eq_empty_iff_forall_notMem]
    intro x hx
    have hxA : x ∈ closure A := closure_mono hA hx.1
    have hxB : x ∈ B := hB hx.2
    have : x ∈ (∅ : Set ℝ) := by
      rw [← hBA]
      exact ⟨hxA, hxB⟩
    exact this
```

`closure_mono` 是“子集的闭包更小”。空集的成员就是矛盾，所以交集是空的。

## 13.5 定义 13.9 与定理 13.12：连通

$E$ 不连通，若它是两个非空分离集的并。否则 $E$ 连通。

空集连通：两个非空集合的并不会是空集。开区间和闭区间都连通。
$[-3,0)\cup(0,3]$ 不连通，因为它就是例 13.7 里那两个分离集的并。
康托尔集也不连通：落在 $1/2$ 左边的部分含在 $[0,1/3]$ 里，右边的部分含在
$[2/3,1]$ 里，这两段分离，子集仍然分离，而 $0$ 和 $1$ 分别落在两边。

另一种说法等价：存在开集 $U,V$ ，盖住 $E$ ，两边都碰到 $E$ ，但
$E\cap U\cap V$ 是空的。取补集就回到分离的定义。

在 $\mathbb{R}$ 上可以看得更直接。

**定理 13.12.** $E\subset\mathbb{R}$ 连通，当且仅当只要 $x,y\in E$ 并且
$x<z<y$ ，就有 $z\in E$ 。

缺一个中间点时，把 $E$ 切成小于这个点的部分和大于这个点的部分。两边都
非空，又分别含在 $(-\infty,z)$ 和 $(z,\infty)$ 里，而这两条射线分离，
所以子集分离。反过来，若 $E$ 是两个非空分离集的并，取 $x$ 在一边、$y$
在另一边，它们之间的上确界会落在缺口上，那个点不在 $E$ 里。

```lean
example (E : Set ℝ) : IsPreconnected E ↔ OrdConnected E := isPreconnected_iff_ordConnected

example : IsPreconnected (∅ : Set ℝ) := isPreconnected_empty

example : IsConnected (Icc (0 : ℝ) 1) := isConnected_Icc (by norm_num)

example : IsConnected (Ioo (0 : ℝ) 1) := isConnected_Ioo (by norm_num)
```

`OrdConnected` 就是“含有任意两点之间的全部点”。`IsPreconnected` 是
开覆盖切不开。定理 13.12 说二者在直线上相同。空集满足这个条件。
`IsConnected` 再要求非空，所以 $[0,1]$ 和 $(0,1)$ 在 $0<1$ 时都用得上。

缺口集合不满足这个条件。$-1$ 和 $1$ 都在里面，$0$ 在它们之间却不在里面。

```lean
example : ¬ IsPreconnected (Ico (-3 : ℝ) 0 ∪ Ioc 0 3) := by
  rw [isPreconnected_iff_ordConnected]
  intro h
  have hm : (-1 : ℝ) ∈ Ico (-3) 0 ∪ Ioc 0 3 := Or.inl ⟨by norm_num, by norm_num⟩
  have hp : (1 : ℝ) ∈ Ico (-3) 0 ∪ Ioc 0 3 := Or.inr ⟨by norm_num, by norm_num⟩
  have hz : (0 : ℝ) ∈ Icc (-1) 1 := ⟨by norm_num, by norm_num⟩
  have h0 := h.out hm hp hz
  simp [mem_Ico, mem_Ioc] at h0
```

`h.out` 从序连通得到 $[-1,1]$ 整个含在并集里。$0$ 在 $[-1,1]$ 里，于是
$0$ 属于并集。`simp` 把这件事拆成 $0<0$ 或 $0>0$ 。

计算通道用同一个缺口：$-1$ 和 $1$ 在 $[-3,0)\cup(0,3]$ 里，$0$ 不在。

Isabelle 把开区间的“含有中间点”直接写出来。$a,b$ 都在 $(0,1)$ 里，
并且 $a\le x\le b$ ，则 $0<a\le x$ 推出 $0<x$ ，$x\le b<1$ 推出 $x<1$ 。
因此 $(0,1)$ 是区间，而直线上区间就是连通集。带缺口的并集不是区间：
$-1$ 和 $1$ 在里面，$0$ 不在，所以它不连通。

## 13.6 七通道对照

| 主题 | Lean | Isabelle | Coq | Agda | 计算三通道 |
|------|------|----------|-----|------|------------|
| 闭区间不可数 | $(0,1)\subset[0,1]$ | `uncountable_open_interval` | — | — | — |
| 端点是极限点 | $\min(\varepsilon/2,1/2)$ | — | — | — | — |
| 康托尔集 | $0$ 、$1/4$ 在，$1/2$ 不在 | — | $1/3<1/2<2/3$ | $0<1<2$ | $E_1$ 、$E_2$ 的成员 |
| 不含长区间 | 左段 $\le 1/3$ ，右段 $\ge 2/3$ | — | $1/9<1/2$ | $n\le n+n$ | 四段长度为 $1/9$ |
| 分离 | 闭包互不相交 | `closure` 后两边为空 | — | — | — |
| 连通 | `OrdConnected` | `is_interval` $\leftrightarrow$ `connected` | $0$ 夹在中间 | — | $0$ 不在缺口并集里 |

## 13.7 本章验证清单

- `examples/lean/Realanalysis/Ch13Perfect.lean`：闭区间不可数、端点的极限点、
  康托尔集、分离、子集、连通与缺口。
- `examples/isabelle/RA13/PerfectConnected.thy`：不可数、分离、开区间含有中间点、
  缺口不连通。
- `examples/coq/Ch13_perfect.v`：$1/2$ 在被删的三分之一里，长度 $1/2$ 大于 $1/9$ 。
- `examples/agda/Ch13_perfect.agda`：中间的缺口，以及段数不减少。
- `examples/julia/13_perfect.jl`、`examples/python/13_perfect.py`、
  `examples/prolog/13_perfect.pl`：前两步的点和缺口。

复验：`pwsh -NoProfile -Command '& ./build.ps1 -Chapter 13'`。

## 13.8 接下来

拓扑这一部分到这里告一段落。下一章开始看序列：什么叫收敛，范围，以及有界。
