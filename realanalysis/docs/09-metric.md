# 第 09 章 拓扑定义

> 对应原书第 9 章。欧几里得空间不是域：域讲运算，空间讲点与点之间的
> 远近。本章给度量空间立规矩，并在实直线上把邻域、有界、极限点、
> 开集、闭集、稠密和完备集全部写出来。下一章才证明这些集合怎样做
> 并、交和补。

## 9.1 定义 9.1：度量空间

**定义。** 度量空间是集合 $X$ 配上函数 $d:X\times X\to\mathbb{R}$ ，使对
任意 $p,q,r\in X$ ：

1. **距离。** $p\neq q$ 时 $d(p,q)>0$ ，并且 $d(p,p)=0$ 。
2. **对称。** $d(p,q)=d(q,p)$ 。
3. **三角不等式。** $d(p,q)\le d(p,r)+d(r,q)$ 。

$X$ 的元素叫点，$d$ 叫距离或度量。

**例 9.2.** $\mathbb{R}^k$ 配上 $d(p,q)=|p-q|$ 是度量空间。$k=1$ 时
就是实直线：绝对值非负，自己到自己是 $0$ ，对称来自 $|-1|=1$ ，三角
不等式就是第 06 章的 $|a+b|\le|a|+|b|$ 。以后说“度量空间
$\mathbb{R}$ ”，指的就是这个距离。

Lean（`examples/lean/Realanalysis/Ch09Metric.lean`）：

```lean
example (p q : ℝ) : dist p q = |p - q| := Real.dist_eq p q
example (p : ℝ) : dist p p = 0 := dist_self p
example (p q : ℝ) : dist p q = dist q p := dist_comm p q
example (p q r : ℝ) : dist p q ≤ dist p r + dist r q := dist_triangle p r q
```

Isabelle 的 `dist_abs`、`dist_sym`、`dist_tri` 是同一组事实。Coq 不
用库里的度量，直接令 `d p q = Rabs (p - q)`，用 `Rabs_Ropp` 证对称，
用 `Rabs_triang` 证三角不等式。Agda 在两点集 $\{a,b\}$ 上令
$d(a,a)=d(b,b)=0$ 、$d(a,b)=1$ ，把八种组合逐一核对；这是最小的非平凡
度量，用来看清三条公理，而不是实直线。

$X$ 的任意子集 $Y$ ，沿用同一个 $d$ ，仍是度量空间：三条公理只谈论
$Y$ 里的点，而那些点本来就在 $X$ 里。

## 9.2 定义 9.3 与定理 9.5–9.6：有界

**定义 9.3.** $E\subset X$ 有界，若存在 $q\in X$ 和有限的 $M$ ，使每个
$p\in E$ 都满足 $d(p,q)\le M$ 。没有这样的 $q,M$ ，就叫无界。

这和有序域里的“有上界、有下界”不是同一个词。$(-\infty,3]$ 有上界
$3$ ，但沿实直线可以一直向左走，所以按距离它无界。

**例 9.4.** $[-3,3]$ 以 $q=0$ 、$M=3$ 为界，也可以用 $q=3$ 、$M=6$ 。
$M$ 越小越紧，但定义只要求存在一个有限的 $M$ 。$q$ 必须在度量空间里，
不必在 $E$ 里。$\mathbb{Q}$ 作为 $\mathbb{R}$ 的子集是无界的：任何
候选的 $q,M$ 外面都还有更远的有理数。

```lean
example : ∀ p ∈ Icc (-3 : ℝ) 3, dist p 0 ≤ 3 := by
  intro p hp
  rw [Real.dist_eq, abs_le]
  constructor <;> linarith [hp.1, hp.2]
```

Isabelle：`bounded {(-3::real)..3}`，并且
`¬ bounded {..(3::real)}`。证明取范数界 $a$ ，点
$-(|a|+1)$ 仍在 $(-\infty,3]$ 里，它的范数是 $|a|+1$ ，不可能 $\le a$ 。

**定理 9.5.** 有限个有界集的并仍有界。对每个 $A_i$ 取中心 $q_i$ 和
界 $M_i$ ，再把所有点都量到 $q_1$ ：三角不等式给出
$d(p,q_1)\le M_i+d(q_i,q_1)$ ，有限个 $M_i$ 和有限个距离都能取最大值。
无限并没有“最大值”这一步，所以定理只对有限并成立。Lean 写下二元情形
`hs.union ht`。

**定理 9.6.** 在有序域上，距离取绝对值时：度量有界当且仅当既有上界又
有下界。$|p-q|\le M$ 就是 $q-M\le p\le q+M$ 。反过来若
$\beta\le p\le\alpha$ ，取 $q=0$ 、$M\ge\max\{|\alpha|,|\beta|\}$ 即可。

```lean
example {E : Set ℝ} {q M : ℝ} (h : ∀ p ∈ E, dist p q ≤ M) :
    (∀ p ∈ E, q - M ≤ p) ∧ (∀ p ∈ E, p ≤ q + M) := by
  constructor <;> intro p hp <;>
    have := h p hp <;> rw [Real.dist_eq, abs_le] at this <;> linarith
```

## 9.3 定义 9.7：邻域

**定义。** 点 $p$ 、半径 $r>0$ 的邻域是

$$
N_r(p)=\{q\in X\mid d(p,q)<r\}.
$$

在 $\mathbb{R}$ 上这就是开区间 $(p-r,p+r)$ 。$(-3,3)$ 是中心 $0$ 、半径
$3$ 的邻域；$(99,100)$ 是中心 $99.5$ 、半径 $0.5$ 的邻域。$[-3,3]$ 、
$[-3,3)$ 、$(-3,3]$ 都不是邻域：端点到中心的距离等于半径，不满足严格
小于。在 $\mathbb{R}^k$ 里，邻域是开球。

```lean
example : ball (0 : ℝ) 3 = Ioo (-3) 3 := by
  simpa using Real.ball_eq_Ioo (0 : ℝ) 3
example : (3 : ℝ) ∉ ball 0 3 := by
  simp [mem_ball]
```

每个邻域自己有界：界就是半径，中心就是 $p$ 。计算通道核对 $2$ 在
$\mathrm{ball}(0,3)$ 里、$3$ 不在里面，并且 $3-1/n$ 从开区间内部逼近
缺失的端点 $3$ 。

## 9.4 极限点、闭集、稠密

**定义 9.9.** $p$ 是 $E\subset X$ 的极限点（聚点），若每个邻域
$N_r(p)$ 都含有 $E$ 的至少一个异于 $p$ 的点。$E$ 中不是极限点的点叫
孤立点。

**例 9.10.** $[-3,3]$ 和 $(-3,3)$ 的每个点都是该集合的极限点。更强的
是：$-3$ 和 $3$ 也是开区间 $(-3,3)$ 的极限点，尽管它们不在开区间里。
理由是有理数稠密：在 $\max(p-r,-3)$ 与 $\min(p+r,3)$ 之间总能再取一点。

形式化里，“每个邻域都碰到集合”就是 $p$ 属于闭包。

```lean
example : (3 : ℝ) ∈ closure (Ioo (-3) 3) := by
  rw [closure_Ioo (by norm_num : (-3 : ℝ) ≠ 3)]
  simp
```

于是 `closure (Ioo (-3) 3) = Icc (-3) 3`。

**定理 9.11.** 若 $p$ 是极限点，则每个邻域含有 $E$ 的无穷多个点。
逆否：若某个邻域只碰到有限个点 $q_1,\ldots,q_n$ （去掉 $p$ ），取
$h$ 为这些距离的最小值的一半，则 $N_h(p)$ 不再碰到别的点，$p$ 不是
极限点。有限集取不出正的最小距离以外的点，所以：

**推论 9.12.** 有限集没有极限点。

**定义 9.13.** $E$ 是闭集，若它包含自己的全部极限点。这和域的“运算
封闭”不是一回事。

**例 9.14.** $[-3,3]$ 是闭集。区间外的点 $p$ ，取
$r=\min\{|-3-p|,|3-p|\}/2$ ，邻域碰不到区间。$(-3,3)$ 不是闭集，因为
极限点 $\pm 3$ 不在集合里：

```lean
example : IsClosed (Icc (-3 : ℝ) 3) := isClosed_Icc
example : ¬ IsClosed (Ioo (-3 : ℝ) 3) := by
  intro h
  have h3 : (3 : ℝ) ∈ closure (Ioo (-3) 3) := by
    rw [closure_Ioo (by norm_num : (-3 : ℝ) ≠ 3)]
    simp
  rw [h.closure_eq] at h3
  simp at h3
```

**推论 9.15.** 有限集是闭集：没有极限点，所以“包含全部极限点”自动成立。
`{0,1}` 在 Lean 和 Isabelle 里都是闭集。

**定义 9.16.** $E$ 在 $X$ 中稠密，若 $X$ 的每个点要么属于 $E$ ，要么是
$E$ 的极限点。稠密是相对的：必须说明在哪个空间里。每个空间在自身中
稠密。若 $E$ 已是闭集，则“在 $X$ 中稠密”就是 $E=X$ 。

```lean
example {E : Set ℝ} (hE : IsClosed E) : Dense E ↔ E = univ := by
  constructor
  · intro h
    rw [← hE.closure_eq]
    exact h.closure_eq
  · rintro rfl
    exact dense_univ
```

这和第 05 章“有理数在实数中稠密”的用法不同：按新定义，每个集合都在
自身中稠密，而 $\mathbb{N}$ 在 $\mathbb{R}$ 中并不稠密。两个定义在
$\mathbb{Q}\subset\mathbb{R}$ 上碰巧一致。

**定理 9.18.** $\mathbb{Q}$ 在 $\mathbb{R}$ 中稠密。无理数 $p$ 的每个
邻域 $(p-r,p+r)$ 里都有有理数，这正是第 05 章的有理数稠密。

```lean
example : Dense (Set.range ((↑) : ℚ → ℝ)) := by
  rw [dense_iff]
  intro x r hr
  obtain ⟨q, h1, h2⟩ := exists_rat_btwn (show x - r < x + r by linarith)
  refine ⟨(q : ℝ), ?_⟩
  refine ⟨?_, ⟨q, rfl⟩⟩
  rw [mem_ball, Real.dist_eq, abs_lt]
  constructor <;> linarith
```

Isabelle 直接调用 `Rats_dense_in_real`：任意 $x<y$ 之间有有理数。

## 9.5 内点、开集、邻域是开集

**定义 9.19.** $p$ 是 $E$ 的内点，若存在 $r>0$ 使 $N_r(p)\subset E$ 。

$(-3,3)$ 的每个点都是内点：到最近端点的距离就是可用半径。$[-3,3]$ 的
端点不是内点：每个邻域都伸出区间外。于是内部正好是开区间：

```lean
example : interior (Icc (-3 : ℝ) 3) = Ioo (-3) 3 := interior_Icc
example : (3 : ℝ) ∉ interior (Icc (-3) 3) := by
  simp [interior_Icc]
```

**定义 9.21.** $E$ 是开集，若它的每个点都是内点。$(-3,3)$ 开，
$[-3,3]$ 不开。开不等于“不是闭”：空集既开又闭；$(-3,3]$ 既不开也不闭。

```lean
example : IsOpen (Ioo (-3 : ℝ) 3) := isOpen_Ioo
example : IsOpen (∅ : Set ℝ) := isOpen_empty
example : IsClosed (∅ : Set ℝ) := isClosed_empty
```

**定理 9.23.** 每个邻域 $N_r(p)$ 都是开集。设 $q$ 在邻域里，则
$d(p,q)<r$ ，记 $h=r-d(p,q)>0$ 。对 $N_h(q)$ 中的 $s$ ，三角不等式给出

$$
d(p,s)\le d(p,q)+d(q,s)<(r-h)+h=r,
$$

所以 $s$ 仍在原来的邻域里。Lean / Isabelle 引用库定理 `isOpen_ball` /
`open (ball p r)`，证明就是这一段。

## 9.6 定义 9.24：完备集

**定义。** 完备集是闭集，并且它的每个点都是极限点。等价说法：极限点
恰好就是它自己的全部点。没有孤立点的闭集。

$[-3,3]$ 是完备集：闭，而且每个点（含端点）都是极限点。
$[-3,3]\cup\{100\}$ 是闭集，但 $100$ 是孤立点，所以不完备。开区间
$(-3,3)$ 的点都是极限点，但集合不闭，所以也不完备。单点集是闭集，
不是完备集。空集没有点，三条“对所有点……”的条件都真空成立，所以空集
既开、又闭、又完备，并且有界。

| 集合 | 有界 | 闭 | 开 | 完备 |
|------|------|----|----|------|
| $\emptyset$ | 是 | 是 | 是 | 是 |
| $\{p\}$ （在 $\mathbb{R}$ 中） | 是 | 是 | 否 | 否 |
| $[-3,3]$ | 是 | 是 | 否 | 是 |
| $(-3,3)$ | 是 | 否 | 是 | 否 |
| $(-3,3]$ | 是 | 否 | 否 | 否 |

闭包等于自身是“闭”的另一种写法。$[-3,3]$ 满足这一点：

```lean
example : closure (Icc (-3 : ℝ) 3) = Icc (-3) 3 := isClosed_Icc.closure_eq
```

## 9.7 七通道对照

| 主题 | Lean | Isabelle | Coq | Agda | 计算三通道 |
|------|------|----------|-----|------|------------|
| 三公理 | `dist_self/comm/triangle` | `dist_abs` 等 | `Rabs` | 两点度量 | 有限样本 |
| 邻域 | `ball` $=$ `Ioo` | `ball_eq_greaterThanLessThan` | $d(0,2)<3$ | 半径 $0$ 的球 | 端点在球外 |
| 有界 | `isBounded_Icc` | `bounded` / 射线无界 | $[-3,3]$ 的估计 | — | 到 $0$ 的距离 $\le 3$ |
| 开闭 | `IsOpen` / `IsClosed` | `open` / `closed` | — | — | $3-1/n$ 逼近端点 |
| $\mathbb{Q}$ 稠密 | `exists_rat_btwn` | `Rats_dense_in_real` | — | — | 区间中点 |

## 9.8 本章验证清单

- `examples/lean/Realanalysis/Ch09Metric.lean`：距离、有界、开球、开闭区间、
  内部、闭包、有限集、有理数稠密。
- `examples/isabelle/RA09/Metric.thy`：同上，并证明 $(-\infty,3]$ 无界、
  $(-3,3)$ 不闭。
- `examples/coq/Ch09_metric.v`：绝对值距离的三公理与有界估计。
- `examples/agda/Ch09_metric.agda`：两点度量的三公理。
- `examples/julia/09_metric.jl`、`examples/python/09_metric.py`、
  `examples/prolog/09_metric.pl`：样本上的公理、开球与逼近端点。

复验：`pwsh -NoProfile -Command '& ./build.ps1 -Chapter 09'`。

## 9.9 接下来

定义已经齐了。下一章证明开集的补是闭集、任意并与有限交保持开、闭包
是最小的闭超集，并说明“相对某个子空间的开集”和在全空间里的开集不是
一回事。

上一章：[08 可数性](08-countability.md) · 下一章：[10 闭集和开集](10-open-closed.md) · [返回目录](../README.md)
