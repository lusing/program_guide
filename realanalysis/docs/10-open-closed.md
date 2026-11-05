# 第 10 章 闭集和开集

> 对应原书第 10 章。上一章把开集、闭集、极限点和闭包的定义摆上桌面。
> 这一章证明它们怎样做补、并、交，闭包为什么是最小的闭超集，以及
> “开”和“闭”都要相对于所在的度量空间来说。

## 10.1 定理 10.1–10.2：开集的补是闭集

**定理 10.1.** 度量空间 $X$ 的子集 $E$ 是开集，当且仅当补集 $E^c$ 是闭集。

**推论 10.2.** $F$ 是闭集，当且仅当 $F^c$ 是开集。把上一个定理里的 $E$
换成 $F^c$ ，再用一次 $(F^c)^c=F$ 即可。

图画是：开集的边界画成虚线，边界点落在集合外面，于是那些边界点正好
属于补集，而且补集把它们收了进来，所以补集是闭的。这只是直觉。证明
要把“内点”和“极限点”对上。

一个方向：假设 $E^c$ 是闭集，取 $x\in E$ 。$x$ 既不是 $E^c$ 的点，也不是
$E^c$ 的极限点（闭集已经把极限点全部收进去了）。极限点的定义失败，说明
存在 $r>0$ 使邻域 $N_r(x)$ 与 $E^c$ 不相交。这个邻域整个落在 $E$ 里，
所以 $x$ 是内点。$x$ 任意，因此 $E$ 开。

另一个方向：假设 $E$ 开，$x$ 是 $E^c$ 的极限点。那么 $x$ 的每个邻域都
碰到 $E^c$ ，不可能整个落在 $E$ 里，所以 $x$ 不是 $E$ 的内点。开集的点
全是内点，于是 $x\notin E$ ，也就是 $x\in E^c$ 。极限点都属于 $E^c$ ，
所以补集是闭集。

空集既开又闭，所以它的补集——整个空间——也既开又闭。开和闭不是一对
反义词：集合可以两个都是，也可以两个都不是。$(-3,3]$ 就是后者。

Lean（`examples/lean/Realanalysis/Ch10OpenClosed.lean`）把这两条写成补集上的
等价：

```lean
example {E : Set ℝ} : IsOpen E ↔ IsClosed Eᶜ := isClosed_compl_iff.symm
example {F : Set ℝ} : IsClosed F ↔ IsOpen Fᶜ := isOpen_compl_iff.symm
```

`IsClosed E` 在库里就是“补集是开集”。Isabelle 的定义写得更直白：
`closed S` 就是 `open (- S)`，所以 `open_closed` 给出
`open E ⟷ closed (- E)`。

Coq 不建拓扑，只把同一件事放在命题上。并的补是补的交，这一向不需要
排中律：若 $\neg(P\lor Q)$ ，则 $\neg P$ 并且 $\neg Q$ 。交的补是补的并，
从左到右要用一次“$P$ 或者 $\neg P$ ”：

```coq
Lemma demorgan_and (P Q : Prop) : ~ (P /\ Q) <-> ~ P \/ ~ Q.
```

证明里 `destruct (classic P)` 就是这一次排中律。补两次回到原命题，用的是
`NNPP`：$\neg\neg P\to P$ 。Agda 在布尔值上把德摩根律的四种组合逐一
`refl`，那是构造性的等式，不谈排中律。

## 10.2 定理 10.3：任意并保持开，任意交保持闭

**定理.** 任意一组开集的并仍是开集。任意一组闭集的交仍是闭集。指标可以
无限，也可以不可数。

设 $x$ 落在 $\bigcup_\alpha G_\alpha$ 里，则存在某个 $\alpha$ 使 $x\in G_\alpha$ 。
$G_\alpha$ 开，所以有邻域 $N_r(x)\subset G_\alpha$ 。这个邻域当然也落在并集里。
$x$ 任意，并集的每个点都是内点。

闭集的任意交可以照样写一遍极限点，也可以抄近路：每个 $F_\alpha$ 闭，
则 $F_\alpha^c$ 开，它们的并开，再用德摩根律
$\bigl(\bigcap_\alpha F_\alpha\bigr)^c=\bigcup_\alpha F_\alpha^c$ 。

```lean
example {ι : Type*} {G : ι → Set ℝ} (h : ∀ i, IsOpen (G i)) : IsOpen (⋃ i, G i) :=
  isOpen_iUnion h
example {ι : Type*} {F : ι → Set ℝ} (h : ∀ i, IsClosed (F i)) : IsClosed (⋂ i, F i) :=
  isClosed_iInter h
```

Isabelle 的 `open_Union`、`closed_Inter` 是同一对事实，假设写成
$\forall S\in K.\;\mathrm{open}\,S$ 。

## 10.3 定理 10.4：有限才能交开集、并闭集

**定理.** 有限个开集的交仍是开集。有限个闭集的并仍是闭集。

有限在这里是实质假设，不是写法上的方便。设 $x$ 同时属于 $G_1,\ldots,G_n$ ，
每个 $G_i$ 给出半径 $r_i>0$ 。令 $r=\min\{r_1,\ldots,r_n\}$ 。因为只有有限个
数，最小值存在，而且 $r\le r_i$ ，所以 $N_r(x)\subset N_{r_i}(x)\subset G_i$ 。
一个邻域落进每一个 $G_i$ ，就落进交集。无限个正数不一定有正的下界：
$1,1/2,1/3,\ldots$ 的下确界是 $0$ ，而半径 $0$ 的“邻域”不是邻域。

Coq 把“比最小半径还近，就同时落进两个邻域”单独写出来。`Rmin_l` 说
$\min(r_1,r_2)\le r_1$ ，再套一次小于等于的传递：

```coq
Lemma min_radius (r1 r2 x : R) :
  Rabs x < Rmin r1 r2 -> Rabs x < r1 /\ Rabs x < r2.
```

Agda 用自然数的 $\sqcap$ ：`m⊓n≤m` 与 `m⊓n≤n` 就是“最小半径不超过每一个半径”。

两个开集的交、两个闭集的并是二元情形。指标类型有限时，Lean 用
`isOpen_iInter_of_finite`。闭集的有限并不必重证：对补集用开集的有限交，
再写一次德摩根律。

**反例：无限交可以不开。** 令 $A_n=(-1/n,1/n)$ ，$n=1,2,3,\ldots$ 。每个
$A_n$ 是开区间。它们的交是 $\{0\}$ ：

- $0$ 在每一个 $A_n$ 里。
- 若 $x\neq 0$ ，则 $|x|>0$ 。阿基米德性质给出 $n$ ，使 $1/(n+1)<|x|$ ，
  于是 $x\notin A_{n+1}$ 。

单点在 $\mathbb{R}$ 里不是开集。任意 $\varepsilon>0$ ，邻域里还有 $\varepsilon/2\neq 0$ 。

```lean
theorem nestedIooInter :
    ⋂ n : ℕ, Ioo (-(1 / ((n : ℝ) + 1))) (1 / ((n : ℝ) + 1)) = {(0 : ℝ)} := by
  ext x
  simp only [mem_iInter, mem_Ioo, mem_singleton_iff]
  constructor
  · intro hx
    by_contra h
    have habs : 0 < |x| := abs_pos.mpr h
    obtain ⟨n, hn⟩ := exists_nat_one_div_lt habs
    have hlt : |x| < 1 / ((n : ℝ) + 1) := abs_lt.mpr (hx n)
    linarith
  · rintro rfl n
    have : 0 < 1 / ((n : ℝ) + 1) := by positivity
    constructor <;> linarith
```

自然数从 $0$ 起算，所以半径写成 $1/(n+1)$ ，避免除以 $0$ 。这和从 $n=1$
起写 $1/n$ 是同一族区间。Isabelle 用开球
$\bigcap_n B\bigl(0,\,1/(n+1)\bigr)=\{0\}$ ，再单独证明 $\{0\}$ 不开：
从开集定义取出 $\varepsilon$ ，点 $\varepsilon/2$ 落在球里，却不等于 $0$ 。

不是说开集的无限交永远不开。每个 $A_n$ 都取 $(-3,3)$ ，交还是 $(-3,3)$ 。
定理拒绝的是“总是开”，不是“有时开”。

**反例：无限并可以不闭。** 令 $A_n=[0,\,2-1/n]$ 。每个 $A_n$ 是闭区间。
并集是 $[0,2)$ ：

- 若 $0\le x<2$ ，空隙 $2-x>0$ ，取 $n$ 使 $1/(n+1)<2-x$ ，则
  $x\le 2-1/(n+1)$ ，所以 $x$ 落进第 $n$ 项。
- $2$ 不属于任何一项，因为 $2>2-1/(n+1)$ 。

$2$ 是这个并集的极限点（右端点 $2-1/(n+1)$ 从左边逼近它），却不在并集里，
所以并集不闭。

```lean
theorem nestedIccUnion :
    ⋃ n : ℕ, Icc (0 : ℝ) (2 - 1 / ((n : ℝ) + 1)) = Ico 0 2 := by
  ext x
  simp only [mem_iUnion, mem_Icc, mem_Ico]
  constructor
  · rintro ⟨n, hx0, hx2⟩
    have : 0 < 1 / ((n : ℝ) + 1) := by positivity
    exact ⟨hx0, by linarith⟩
  · rintro ⟨hx0, hx2⟩
    obtain ⟨n, hn⟩ := exists_nat_one_div_lt (show 0 < 2 - x by linarith)
    exact ⟨n, hx0, by linarith⟩
```

不闭的那一步把等式代进 $[0,2)$ ，再用 `closure_Ico`：$0\neq 2$ 时
$[0,2)$ 的闭包是 $[0,2]$ ，$2$ 在闭包里，不在 $[0,2)$ 里。

Julia、Python、Prolog 在有限样本上看到同一现象。分母从 $1$ 到 $40$ ，
十分位网格 $-2,-1.9,\ldots,2$ 里能留在所有 $(-1/n,1/n)$ 中的只有 $0$ ；
$1/10$ 在 $n>10$ 之后掉出去。并集 $[0,2-1/n]$ 吃得进 $3/2$ ，吃不进 $2$ 。

## 10.4 定义 10.5 与定理 10.7–10.9：闭包

**定义.** $E'$ 表示 $E$ 的全部极限点。$E$ 的闭包是 $\overline{E}=E\cup E'$ 。

**例.** $E=(-3,3)$ 。端点 $\pm 3$ 是极限点，开区间里的点也都是极限点，
所以 $E'=[-3,3]$ ，闭包还是 $[-3,3]$ 。

```lean
example : closure (Ioo (-3 : ℝ) 3) = Icc (-3) 3 :=
  closure_Ioo (by norm_num : (-3 : ℝ) ≠ 3)
```

Isabelle 直接化简 `closure {-3<..<3} = {-3..3}`。计算通道用序列
$3-1/n$ ：每一项都在 $(-3,3)$ 里，第 $20$ 项到 $3$ 的距离小于 $1/10$ 。
$3$ 自己不在开区间里，它是被闭包补上的那个点。

**定理 10.7.** $\overline{E}$ 总是闭集。

证明补集是开集。取 $p\notin\overline{E}$ ，则 $p$ 不是 $E$ 的点，也不是
极限点，所以有邻域 $N_r(p)$ 与 $E$ 不相交。这个邻域也不能碰到 $E'$ ：
否则里面有一个极限点 $q$ ，再取更小的半径 $k<r-d(p,q)$ ，
$N_k(q)\subset N_r(p)$ 里至少有 $E$ 的一个点，矛盾。于是整个邻域落在
闭包的补集里。

库里的 `isClosed_closure` / `closed_closure` 就是这条定理。

**推论 10.8.** $\overline{E}=E$ 当且仅当 $E$ 是闭集。

若相等，左边是闭集，右边也是。若 $E$ 已经是闭集，则 $E'\subset E$ ，
所以 $E\cup E'=E$ 。

```lean
example {E : Set ℝ} : closure E = E ↔ IsClosed E := closure_eq_iff_isClosed
```

**推论 10.9.** 若 $F$ 是闭集而且 $E\subset F$ ，则 $\overline{E}\subset F$ 。

闭包是包含 $E$ 的最小闭集：任何闭超集都把它装进去。极限点不能丢，
否则超集自己就不闭。$E\subset F$ 推出 $E'\subset F'$ ；若 $F$ 闭，则
$F'\subset F$ ，于是 $E\cup E'\subset F$ 。

```lean
example {E F : Set ℝ} (hEF : E ⊆ F) (hF : IsClosed F) : closure E ⊆ F :=
  closure_minimal hEF hF
```

## 10.5 定理 10.10–10.11：上确界在闭包里

**定理 10.10.** $E\subset\mathbb{R}$ 非空且有上界，则 $\sup E\in\overline{E}$ 。
有下界时 $\inf E\in\overline{E}$ 。

这是有序域和第 09 章度量之间的桥。多数度量空间没有序，例如 $\mathbb{R}^2$ ，
所以定理只在实直线上说。

令 $y=\sup E$ 。若 $y\in E$ ，则 $y$ 已经在闭包里。若 $y\notin E$ ，
小于 $y$ 的数都不是上界：对任意 $h>0$ ，存在 $x\in E$ 使 $y-h<x\le y$ 。
$x\neq y$ （否则 $y\in E$ ），所以 $x\in N_h(y)\cap E$ 。$h$ 任意，$y$ 是极限点，
因此 $y\in\overline{E}$ 。下确界把不等号反过来，论证相同。

```lean
example {E : Set ℝ} (hne : E.Nonempty) (hb : BddAbove E) : sSup E ∈ closure E :=
  csSup_mem_closure hne hb
example {E : Set ℝ} (hc : IsClosed E) (hne : E.Nonempty) (hb : BddAbove E) :
    sSup E ∈ E :=
  hc.csSup_mem hne hb
```

Isabelle 调用 `closure_contains_Sup`。闭的时候再用推论 10.8 把
$\mathrm{Sup}\,E\in\mathrm{closure}\,E$ 收成 $\mathrm{Sup}\,E\in E$ 。

**推论 10.11.** 非空、有上界、而且是闭集，则上确界属于集合本身。下确界同样。

逆命题不成立。$E=[-3,0)\cup(0,3]$ 含有下端 $-3$ 和上端 $3$ ，但 $0$ 是极限点
却不在 $E$ 里，所以 $E$ 不闭。$(0,3)$ 的闭包是 $[0,3]$ ，而 $(0,3)$ 是 $E$
的子集，闭包保持包含，于是 $0$ 也在 $E$ 的闭包里。

```lean
example : ¬ IsClosed (Ico (-3 : ℝ) 0 ∪ Ioc 0 3) := by
  intro h
  have hsub : Ioo (0 : ℝ) 3 ⊆ Ico (-3) 0 ∪ Ioc 0 3 := by
    intro x hx
    exact Or.inr ⟨hx.1, hx.2.le⟩
  have h0 : (0 : ℝ) ∈ closure (Ioo 0 3) := by
    rw [closure_Ioo (by norm_num : (0 : ℝ) ≠ 3)]
    simp
  have : (0 : ℝ) ∈ closure (Ico (-3) 0 ∪ Ioc 0 3) := closure_mono hsub h0
  rw [h.closure_eq] at this
  simp at this
```

`Or.inr` 把 $(0,3)$ 的点放进右边那个 $(0,3]$ 。若 $E$ 闭，闭包等于 $E$ ，
$0$ 就得属于 $E$ ，而 `simp` 知道 $0$ 既不满足 $-3\le 0<0$ ，也不满足
$0<0\le 3$ 。

有限样本看不到真正的上确界。$(-3,3)$ 里步长 $1/5$ 的点，最大的仍严格小于 $3$ 。
$3$ 是上确界，它在闭包里，不在开区间里。

## 10.6 定义 10.12–10.16：相对开集与相对闭集

一个集合开不开，取决于它坐在哪个度量空间里。$(-3,3)$ 在 $\mathbb{R}$ 里开。
把它看成 $\mathbb{R}^2$ 里 $x$ 轴上的线段，平面上的邻域是圆盘，任何圆盘都
含有 $y\neq 0$ 的点，那些点不在线段上，所以它在平面里不开。

**定义 10.12.** $E$ 相对于 $Y$ 是开集，若每个 $p\in E$ 都有 $r>0$ ，使
$N_r(p)\cap Y\subset E$ 。全空间上的邻域可以伸出 $Y$ ，只要伸出的部分不算。

当 $Y=X$ 时，$N_r(p)\cap X=N_r(p)$ ，相对开就是第 09 章的开。

**定理 10.14.** $Y\subset X$ ，$E\subset Y$ 。$E$ 相对于 $Y$ 开，当且仅当存在
$X$ 的开集 $G$ ，使 $E=Y\cap G$ 。

容易的方向：若 $E=Y\cap G$ 且 $G$ 在 $X$ 里开，则每个 $p\in E$ 在 $G$ 里
有一个邻域 $V_p$ 。交上 $Y$ 得到 $V_p\cap Y\subset E$ 。

反过来：对每个 $p\in E$ 取相对邻域的半径 $r_p$ ，把这个邻域在 $X$ 里扩成
整颗球 $V_p=\{q\in X:d(p,q)<r_p\}$ 。令 $G=\bigcup_{p\in E}V_p$ 。每颗球都开，
任意并仍开，所以 $G$ 在 $X$ 里开。$p\in V_p$ 而且 $p\in Y$ ，所以
$E\subset Y\cap G$ 。另一边，$V_p\cap Y$ 本来就装在 $E$ 里，并起来仍在 $E$ 里。

Lean 里子空间的拓扑就是由含入映射诱导的拓扑，所以这条定理就是
`isOpen_induced_iff`：

```lean
example {Y : Set ℝ} {E : Set Y} :
    IsOpen E ↔ ∃ G : Set ℝ, IsOpen G ∧ Subtype.val ⁻¹' G = E :=
  isOpen_induced_iff
```

`Subtype.val ⁻¹' G` 是 $G$ 里那些本来就属于 $Y$ 的点，也就是 $Y\cap G$
被看成 $Y$ 的子集。Isabelle 写成
`openin (top_of_set Y) E ⟷ (∃G. open G ∧ E = Y ∩ G)`。

具体例子：$[0,1)$ 在子空间 $[0,2)$ 里开，因为它是开区间 $(-1,1)$ 的原像。
同一个集合在 $\mathbb{R}$ 里不开。$[0,1)$ 的内部是 $(0,1)$ ，左端点 $0$
不在内部里：每个邻域都含有负数。

```lean
example : IsOpen (Subtype.val ⁻¹' (Ioo (-1 : ℝ) 1) : Set (Ico (0 : ℝ) 2)) :=
  isOpen_Ioo.preimage continuous_subtype_val
example : ¬ IsOpen (Ico (0 : ℝ) 1) := by
  intro h
  have hinter : interior (Ico (0 : ℝ) 1) = Ico 0 1 := h.interior_eq
  rw [interior_Ico] at hinter
  have : (0 : ℝ) ∈ Ioo 0 1 := by
    rw [hinter]
    simp [mem_Ico]
  simp [mem_Ioo] at this
```

若 $[0,1)$ 在全直线上开，内部就等于它自己。`interior_Ico` 却说内部是
$(0,1)$ 。把 $0$ 放进 $[0,1)$ ，等式会要求 $0\in(0,1)$ ，也就是 $0<0$ 。

闭集同样是相对的。

**定义 10.15.** $E$ 相对于 $Y$ 是闭集，若 $Y$ 中每一个“从 $Y$ 里看是 $E$
的极限点”的点都属于 $E$ 。$Y$ 外面的极限点不参加检查。

**例 10.16.** $X=\mathbb{R}$ ，$Y=[0,2)$ ，$E=[1,2)$ 。$E$ 在 $Y$ 里闭，在
$X$ 里不闭。$2$ 显然是 $E$ 在直线上的极限点，但 $2\notin Y$ ，所以相对
于 $Y$ 不必要求 $2\in E$ 。

在子空间里，$[1,2)$ 是闭射线 $[1,\infty)$ 的原像。在全直线上，$[1,2)$ 的
闭包是 $[1,2]$ ，$2$ 在闭包里，不在集合里。

```lean
example : IsClosed (Subtype.val ⁻¹' (Ici (1 : ℝ)) : Set (Ico (0 : ℝ) 2)) :=
  isClosed_Ici.preimage continuous_subtype_val
example : ¬ IsClosed (Ico (1 : ℝ) 2) := by
  intro h
  have h2 : (2 : ℝ) ∈ closure (Ico 1 2) := by
    rw [closure_Ico (by norm_num : (1 : ℝ) ≠ 2)]
    simp
  rw [h.closure_eq] at h2
  simp [mem_Ico] at h2
```

Agda 把这条缩成三个点 $p_0,p_1,p_2$ ，当作 $0,1,2$ 。$Y=\{p_0,p_1\}$ 不含
端点 $p_2$ ，$E$ 只含 $p_1$ 。`missing-endpoint` 是 `inY p2 ≡ false`：
缺掉的端点不在子空间里，相对闭的检查到此为止。$p_0$ 在 $Y$ 里却不在
$E$ 里，它是被隔在外面的那个点。

| 集合 | 在哪里看 | 开 | 闭 |
|------|----------|----|----|
| $[0,1)$ | $[0,2)$ | 是 | 否 |
| $[0,1)$ | $\mathbb{R}$ | 否 | 否 |
| $[1,2)$ | $[0,2)$ | 否 | 是 |
| $[1,2)$ | $\mathbb{R}$ | 否 | 否 |
| $(-3,3)$ | $\mathbb{R}$ | 是 | 否 |
| $\{0\}$ | $\mathbb{R}$ | 否 | 是 |

## 10.7 七通道对照

| 主题 | Lean | Isabelle | Coq | Agda | 计算三通道 |
|------|------|----------|-----|------|------------|
| 补集 | `isClosed_compl_iff` | `open_closed` | 德摩根律 | 布尔值四种情形 | — |
| 任意并 / 交 | `isOpen_iUnion` | `open_Union` | — | — | — |
| 有限交 | `IsOpen.inter` | `open_Int` | `Rmin` | `m⊓n≤m` | — |
| 无限交反例 | $\bigcap(-1/(n+1),1/(n+1))=\{0\}$ | 开球的交 | $1\not<1$ | — | 十分位只留下 $0$ |
| 无限并反例 | 并成 $[0,2)$ | $2$ 在闭包外 | $2\not\le 1$ | — | $3/2$ 在，$2$ 不在 |
| 闭包 | `closure_minimal` | `closure_eq` | $3-2$ 的距离 | — | $3-1/n$ |
| 上确界 | `csSup_mem_closure` | `closure_contains_Sup` | — | — | 样本最大值 $<3$ |
| 相对开闭 | 子类型的原像 | `openin` / `closedin` | — | 三点 $p_0,p_1,p_2$ | $2\notin[0,2)$ |

## 10.8 本章验证清单

- `examples/lean/Realanalysis/Ch10OpenClosed.lean`：补集、任意并与任意交、
  有限交、两族区间的等式、闭包、上确界、相对开闭。
- `examples/isabelle/RA10/OpenClosed.thy`：同上，并把 $\{0\}$ 不开、
  $\bigcup[0,\,2-1/(n+1)]$ 不闭写成直接证明。
- `examples/coq/Ch10_openclosed.v`：德摩根律、最小半径、端点的数值不等式。
- `examples/agda/Ch10_openclosed.agda`：布尔值德摩根律、最小半径、三点上的相对端点。
- `examples/julia/10_openclosed.jl`、`examples/python/10_openclosed.py`、
  `examples/prolog/10_openclosed.pl`：有限样本上的无限交、无限并、逼近端点。

复验：`pwsh -NoProfile -Command '& ./build.ps1 -Chapter 10'`。

## 10.9 接下来

开集和闭集的运算到这里齐了。下一章定义紧集：每个开覆盖都有有限子覆盖。
有限集是紧的，开区间 $(a,b)$ 不是，紧集一定是闭集，也一定有界。
