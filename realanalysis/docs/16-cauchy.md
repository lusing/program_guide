# 第 16 章 柯西序列与单调序列

> 收敛要拿项去靠近空间里的某个点，所以换一个空间，同一条序列可能不再收敛。
> 柯西条件只比较项与项的距离，不提到极限，因此不依赖空间里有没有那个点。
> 收敛序列一定是柯西序列。反过来，在紧度量空间和 $\mathbb{R}^k$ 里，柯西序列一定收敛。
> 这样的空间叫做完备的。有最小上界性的有序域里，有界单调序列也收敛。

## 16.1 定义 16.1：柯西序列

设 $\{p_n\}$ 是度量空间 $X$ 中的序列。若对任意 $\varepsilon>0$ ，存在自然数 $N$ ，使

$$n,m\ge N\implies d(p_n,p_m)<\varepsilon,$$

则 $\{p_n\}$ 是柯西序列。

收敛性问的是 $d(p_n,p)<\varepsilon$ ，点 $p$ 必须已经在 $X$ 里。柯西条件问的是尾部任意两项有多近，定义里不出现极限。给定 $\varepsilon>0$ ，要找的是一个下标，从那里往后，项与项彼此的距离都小于 $\varepsilon$ 。

## 16.2 例 16.2：柯西，但在所在空间里不收敛

令 $p_n=1/n$ ，把空间改成 $X=\mathbb{R}\setminus\{0\}$ 。 $0$ 不在 $X$ 里，所以这条序列在 $X$ 中不收敛。它仍然是柯西序列。若 $n,m\ge N\ge 1$ ，

$$\left|\frac{1}{n}-\frac{1}{m}\right|\le\max\left\{\frac{1}{n},\frac{1}{m}\right\}\le\frac{1}{N}.$$

要使 $1/N<\varepsilon$ ，取 $N=\lceil 1/\varepsilon\rceil+1$ 即可。 $\varepsilon=1/10$ 时这个下标是 $11$ 。第 $11$ 项和第 $12$ 项的距离是 $1/132$ ，已经小于 $1/10$ 。

```lean
theorem harmonic_gap : |(1 : ℝ) / 11 - 1 / 12| < 1 / 10 := by
  norm_num
```

`norm_num` 直接算出这个分数不等式。它只核对书上估计的一个数值，一般的 $N$ 仍由上面的 $\lceil 1/\varepsilon\rceil+1$ 给出。

再看有理数。令 $s_n$ 是 $\sqrt{2}$ 保留前 $n$ 位小数的截断：$1.4$ ， $1.41$ ， $1.414$ ，也就是 $14/10$ ， $141/100$ ， $1414/1000$ 。每一项都是有理数。在 $\mathbb{R}$ 里这条序列收敛到 $\sqrt{2}$ ，所以它是柯西序列： $n,m\ge N$ 时距离不超过 $10^{-N}$ 。 $\sqrt{2}$ 不是有理数，所以同一条序列在 $\mathbb{Q}$ 里不收敛。

两位和三位截断的距离是 $4/1000=1/250$ ，小于 $10^{-2}$ 。

```lean
theorem sqrt_two_truncations : |(141 : ℝ) / 100 - 1414 / 1000| < 1 / 100 := by
  norm_num
```

左边是 $|1.41-1.414|$ ，右边是两位小数所允许的尾部直径。计算通道用同样的两个分数。

这两例说明：项与项靠拢，并不保证它们在所在空间里有一个落脚点。缺的是最小上界性，空间里可以有“洞”。 $\mathbb{R}$ 没有这种洞，下一节之后会把它叫做完备。

## 16.3 定理 16.3：收敛推出柯西

设 $p_n\to p$ ， $p\in X$ 。任给 $\varepsilon>0$ ，把收敛定义用在 $\varepsilon/2$ 上，得到 $N$ ，使 $n\ge N$ 时 $d(p_n,p)<\varepsilon/2$ ， $m\ge N$ 时同样 $d(p_m,p)<\varepsilon/2$ 。三角不等式给出

$$d(p_n,p_m)\le d(p_n,p)+d(p,p_m)<\frac{\varepsilon}{2}+\frac{\varepsilon}{2}=\varepsilon.$$

所以收敛序列是柯西序列。上一节已经说明反过来不必成立。

```lean
theorem convergent_is_cauchy {s : ℕ → ℝ} {p : ℝ} (h : Tendsto s atTop (nhds p)) :
    CauchySeq s :=
  h.cauchySeq
```

`Tendsto.cauchySeq` 把“靠近一个点”收成“尾部彼此靠近”。Isabelle 的对应事实是 `LIMSEQ_imp_Cauchy` 。库里的调和序列从 $1$ 起写，也就是 $1/(n+1)\to 0$ ，所以它是柯西序列：

```isabelle
lemma harmonic_cauchy: "Cauchy (\<lambda>n. inverse (real (Suc n)))"
  by (rule conv_imp_cauchy[OF LIMSEQ_inverse_real_of_nat])
```

`conv_imp_cauchy` 就是 `LIMSEQ_imp_Cauchy` 用在一条实序列上。 `Suc n` 把从 $0$ 起的下标挪成 $1,2,3,\ldots$ ，和 `LIMSEQ_inverse_real_of_nat` 的写法一致。

## 16.4 定义 16.4：直径

$E$ 是度量空间的非空子集时，

$$\operatorname{diam} E=\sup\{d(p,q):p,q\in E\}.$$

距离是实数，所以上确界也在 $\mathbb{R}$ 里谈，不必是 $E$ 或 $X$ 的元素。距离集合无上界时，不说 $E$ 有直径。

## 16.5 例 16.5：几个直径

1. $E=\{1,2,3\}$ 。三个距离是 $1$ ， $1$ ， $2$ ，上确界是 $2$ 。
2. $E=[-3,3]$ 的直径是 $6$ ，就是两端的距离。
3. $E=[-3,3)$ 的直径仍是 $6$ 。 $\{-3\}$ 到区间内点的距离组成 $[0,6)$ ，最小上界是 $6$ ，虽然 $6$ 不是其中任何一个距离。
4. $E=[0,\sqrt{2})$ 的直径是 $\sqrt{2}$ 。把 $E$ 看成 $\mathbb{Q}$ 的子集时直径不变，因为直径是一集实数距离的上确界。
5. $E=[0,\infty)$ 中的距离无上界，没有直径。
6. $A_n=[0,1/n)$ 的直径是 $1/n$ ，这条直径序列收敛到 $0$ 。

形式化记下两个端点距离。三点集里最远的是 $1$ 和 $3$ ，区间两端是 $-3$ 和 $3$ 。

```lean
theorem three_point_span : dist (1 : ℝ) 3 = 2 := by
  rw [Real.dist_eq]
  norm_num

theorem interval_span : dist (-3 : ℝ) 3 = 6 := by
  rw [Real.dist_eq]
  norm_num
```

`Real.dist_eq` 把距离展开成绝对值，`norm_num` 再算出 $2$ 和 $6$ 。Isabelle 用 `dist_real_def` 做同一步。Agda 没有实数距离，只记下跨度本身：$1+2=3$ ，并且 $1<3$ ，中间经过 $2$ 。

```agda
span : 1 + 2 ≡ 3
span = refl

span-strict : 1 < 3
span-strict = <-trans (n<1+n 1) (n<1+n 2)
```

`refl` 说明 $1+2$ 按定义就是 $3$ 。 `<-trans` 把 $1<2$ 和 $2<3$ 接成 $1<3$ 。

## 16.6 定理 16.6：柯西序列当且仅当尾部直径趋于 $0$

令 $E_N=\{p_N,p_{N+1},p_{N+2},\ldots\}$ 。 $\{p_n\}$ 是柯西序列，当且仅当 $\operatorname{diam} E_N\to 0$ 。

若序列是柯西的，对 $\varepsilon>0$ 先取到 $d(p_n,p_m)<\varepsilon/2$ 。于是 $\varepsilon/2$ 是这些距离的上界，$\operatorname{diam} E_N\le\varepsilon/2<\varepsilon$ 。后面的尾部更小：$n\ge N$ 时 $E_n\subset E_N$ ，所以 $\operatorname{diam} E_n\le\operatorname{diam} E_N<\varepsilon$ 。直径非负，这就得到 $\operatorname{diam} E_n\to 0$ 。先用 $\varepsilon/2$ ，是为了把上确界处的 $\le$ 收成定义里要求的 $<$ 。

反过来，若直径趋于 $0$ ，则有 $N$ 使 $\operatorname{diam} E_N<\varepsilon$ 。尾部任意两点的距离不超过这个上确界，序列是柯西的。

收敛也能推出尾部直径趋于 $0$ ： $n\ge N$ 时项都落在 $p$ 的 $\varepsilon/2$ 邻域里，任意两项距离小于 $\varepsilon$ 。只靠收敛才有这句话；柯西序列用上面的定理，不必先有极限。

## 16.7 定理 16.7：闭包不改变直径

对任意 $E\subset X$ ， $\operatorname{diam}\overline{E}=\operatorname{diam} E$ 。

$E\subset\overline{E}$ 立刻给出 $\operatorname{diam} E\le\operatorname{diam}\overline{E}$ 。

另一边：只要每个 $\varepsilon>0$ 都有 $\operatorname{diam}\overline{E}\le\operatorname{diam} E+\varepsilon$ ，就有 $\operatorname{diam}\overline{E}\le\operatorname{diam} E$ 。否则差值是某个正数 $c$ ，取 $\varepsilon=c/2$ 就会矛盾。

任取 $\overline{E}$ 中的 $p,q$ 。 $p$ 若已在 $E$ 里，令 $p'=p$ 。若 $p$ 只是极限点，半径 $\varepsilon/2$ 的邻域里有 $E$ 的一点 $p'$ 。 $q$ 同样配一个 $q'\in E$ 。两次三角不等式：

$$d(p,q)\le d(p,p')+d(p',q')+d(q',q)<\frac{\varepsilon}{2}+d(p',q')+\frac{\varepsilon}{2}\le\operatorname{diam} E+\varepsilon.$$

$p,q$ 任意，所以 $\operatorname{diam}\overline{E}\le\operatorname{diam} E+\varepsilon$ 。

## 16.8 定理 16.8：直径趋于 $0$ 的嵌套紧集

设 $\{K_n\}$ 是非空紧集，$K_n\supset K_{n+1}$ ，并且 $\operatorname{diam} K_n\to 0$ 。则 $\bigcap_{n=1}^{\infty} K_n$ 恰好是一个点。

非空紧集一套套一套，交至少有一个点。这是紧性那一章的嵌套交：若交是空的，开集 $X\setminus K_n$ 会盖住 $K_1$ ，有限子覆盖里最大的那个 $K_N$ 就和自己不相交。

交不能有两个点。若 $p,q$ 都在交里，令 $r=d(p,q)>0$ 。交含在每一个 $K_m$ 里，所以

$$\operatorname{diam} K_m\ge\operatorname{diam}\bigcap_{n=1}^{\infty} K_n\ge r.$$

直径序列的每一项都 $\ge r$ ，就不能趋于 $0$ 。因此交里只有一个点。

## 16.9 定理 16.9：紧空间里，柯西序列收敛

$X$ 紧，$\{p_n\}$ 是 $X$ 中的柯西序列。令 $E_N$ 为从第 $N$ 项起的尾部。定理 16.6 给出 $\operatorname{diam} E_N\to 0$ 。

每个 $E_N$ 是紧集的子集，它的闭包 $\overline{E_N}$ 是闭的，因而是紧的。 $E_N\supset E_{N+1}$ 推出 $\overline{E_N}\supset\overline{E_{N+1}}$ 。定理 16.7 把直径换成闭包的直径，极限仍是 $0$ 。定理 16.8 说 $\bigcap_N\overline{E_N}$ 恰好有一个点 $p$ 。

这个 $p$ 就是极限。对 $\varepsilon>0$ ，取 $N$ 使 $\operatorname{diam}\overline{E_N}<\varepsilon$ 。 $p$ 在这个闭包里，尾部的点也在，所以 $n\ge N$ 时 $d(p,p_n)<\varepsilon$ 。

另一条路不必把交收成单点集。嵌套非空紧集的交至少有一个点 $p$ ，上面的距离估计仍说明 $p_n\to p$ 。若交里还有 $p'$ ，同一估计给出 $p_n\to p'$ ，极限唯一，所以 $p'=p$ 。

## 16.10 定理 16.10：$\mathbb{R}^k$ 里，柯西序列收敛

柯西序列先是有界的。由定理 16.6，存在 $N$ 使 $\operatorname{diam} E_N<1$ ，尾部有界。前 $N-1$ 项是有限集，也有界。有界集的并有界，所以整条序列有界。

有界序列的值域落在某个 $k$ 维格子里。格子紧，序列落在紧集中，定理 16.9 给出收敛，极限在格子里，因而在 $\mathbb{R}^k$ 里。

一维的情形可以一次写完： $\mathbb{R}$ 完备，柯西序列必有极限。

```lean
theorem cauchy_converges {s : ℕ → ℝ} (h : CauchySeq s) : ∃ p, Tendsto s atTop (nhds p) :=
  cauchySeq_tendsto_of_complete h
```

`cauchySeq_tendsto_of_complete` 用的就是 $\mathbb{R}$ 的完备性。Isabelle 把两个方向合成一句：实序列是柯西序列，当且仅当它收敛。

```isabelle
lemma real_cauchy_iff_convergent:
  fixes X :: "nat \<Rightarrow> real"
  shows "Cauchy X \<longleftrightarrow> convergent X"
  by (rule Cauchy_convergent_iff)
```

`Cauchy_convergent_iff` 只对完备空间成立。 $\mathbb{R}$ 是完备的，所以等价。 $\mathbb{Q}$ 不是，上一节的截断序列是反例。

## 16.11 定义 16.11：完备

度量空间 $X$ 完备，是说 $X$ 中每条柯西序列都收敛到 $X$ 的某个点。

## 16.12 例 16.12：谁完备，谁不完备

定理 16.9 说紧度量空间完备。定理 16.10 说每个 $\mathbb{R}^k$ 完备。 $\mathbb{Q}$ 不完备，例 16.2 的截断序列是有理柯西序列，极限却不在 $\mathbb{Q}$ 里。

对有序域 $F$ ，下面两句等价： $F$ 有最小上界性； $F$ 完备并且有阿基米德性质。距离用 $d(p,q)=|p-q|$ 。证明很长，这里只用到方向本身： $\mathbb{R}$ 有最小上界性，所以 $\mathbb{R}$ 完备。

## 16.13 定理 16.13：完备空间的闭子集完备

$E$ 是完备空间 $X$ 的闭子集，$\{p_n\}$ 是 $E$ 中的柯西序列。它也是 $X$ 中的柯西序列，所以收敛到某个 $p\in X$ 。

若从某项起 $p_n=p$ ，则 $p$ 自己就是 $E$ 的一项。否则 $p$ 的每个邻域都含有 $E$ 的无穷多个点，$p$ 是 $E$ 的极限点。闭集包含自己的极限点，所以 $p\in E$ ，序列在 $E$ 中收敛。

在 $\mathbb{R}$ 上，闭集本身就是完备子集：

```lean
theorem closed_subset_complete {E : Set ℝ} (hE : IsClosed E) {s : ℕ → ℝ}
    (hs : ∀ n, s n ∈ E) (hc : CauchySeq s) : ∃ p ∈ E, Tendsto s atTop (nhds p) :=
  cauchySeq_tendsto_of_isComplete hE.isComplete hs hc
```

`IsClosed.isComplete` 把闭集收成完备子集， `cauchySeq_tendsto_of_isComplete` 再把落在里面的柯西序列收到这个集合的一点。Isabelle 分开写后半句：序列已经在 $\mathbb{R}$ 里收敛，并且项都在闭集 $E$ 中，则极限也在 $E$ 中。

```isabelle
lemma closed_keeps_limit:
  fixes s :: "nat \<Rightarrow> real" and E :: "real set" and p :: real
  assumes "closed E" and "\<And>n. s n \<in> E" and "s \<longlonglongrightarrow> p"
  shows "p \<in> E"
  by (rule closed_sequentially[OF assms(1) assms(2) assms(3)])
```

`closed_sequentially` 就是“闭集对序列极限封闭”。前面的 `real_cauchy_iff_convergent` 负责把柯西序列先变成收敛序列。

## 16.14 定义 16.14：单调序列

$\{s_n\}$ 在有序域里。若每个 $n$ 都有 $s_n\le s_{n+1}$ ，序列单调递增。若每个 $n$ 都有 $s_n\ge s_{n+1}$ ，序列单调递减。二者之一成立，就叫单调序列。

## 16.15 例 16.15：三条单调序列

$1,2,3,\ldots$ 递增。 $s_n=1/n$ 递减。常数序列两项都满足，既递增又递减。

收敛序列有界，反过来不对： $(-1)^n$ 有界，既不单调也不收敛。有最小上界性时，单调可以把“有界”补成“收敛”。

$1/(n+1)$ 递减，因为下标变大时分母变大，正数的倒数变小。

```lean
theorem harmonic_antitone : Antitone (fun n : ℕ => (1 : ℝ) / ((n : ℝ) + 1)) := by
  intro a b hab
  have ha : (0 : ℝ) < (a : ℝ) + 1 := by positivity
  have habN : a + 1 ≤ b + 1 := Nat.add_le_add_right hab 1
  have hle : (a : ℝ) + 1 ≤ (b : ℝ) + 1 := by exact_mod_cast habN
  exact one_div_le_one_div_of_le ha hle
```

$a\le b$ 先变成 $a+1\le b+1$ ，再嵌进实数。 `one_div_le_one_div_of_le` 要求分母为正，然后把不等号反过来： $1/(b+1)\le 1/(a+1)$ 。这就是反序，也就是 `Antitone` 。

Isabelle 只检查相邻两项，再用 `decseq_SucI` 推到整个序列。相邻比较是 `le_imp_inverse_le`：正数变大，倒数变小。

```isabelle
lemma harmonic_step:
  "inverse (real (Suc (Suc n))) \<le> inverse (real (Suc n) :: real)"
proof -
  have le: "real (Suc n) \<le> real (Suc (Suc n))" by simp
  have pos: "0 < real (Suc n)" by simp
  show ?thesis by (rule le_imp_inverse_le[OF le pos])
qed
```

计算通道核对相邻的两个值： $1/12<1/11$ 。

## 16.16 定理 16.16：有界单调序列收敛

$\{s_n\}$ 是有最小上界性的有序域 $F$ 中的单调序列。它在 $F$ 中收敛，当且仅当它有界。

收敛推出有界，这是序列那一章已经证明的事实。

反过来先看递增。值域 $E$ 有上界，最小上界性给出 $s=\sup E$ ，而且 $s\in F$ 。任取 $\varepsilon>0$ 。 $s-\varepsilon$ 不是上界，所以有某项 $s-\varepsilon<s_N\le s$ 。递增使 $n\ge N$ 时 $s_N\le s_n\le s$ ，于是

$$s-\varepsilon<s_n<s+\varepsilon,$$

即 $d(s_n,s)<\varepsilon$ 。所以 $s_n\to s$ 。

递减时用最大下界。最小上界性推出最大下界性：一集下界的最小上界，取负号就是原来那集数的最大下界。令 $s=\inf E$ 。 $s+\varepsilon$ 不是下界，所以有某项 $s\le s_N<s+\varepsilon$ 。递减使 $n\ge N$ 时 $s\le s_n\le s_N$ ，于是 $s-\varepsilon<s_n<s+\varepsilon$ 。

具体的递增例子是 $1-1/(n+1)$ 。倒数递减，减去它就递增；每一项都不超过 $1$ ，因为减去的是正数。

```lean
theorem approach_one_mono : Monotone (fun n : ℕ => (1 : ℝ) - 1 / ((n : ℝ) + 1)) := by
  intro a b hab
  have h := harmonic_antitone hab
  linarith

theorem approach_one_bounded :
    BddAbove (range fun n : ℕ => (1 : ℝ) - 1 / ((n : ℝ) + 1)) := by
  refine ⟨1, ?_⟩
  rintro y ⟨n, rfl⟩
  have : (0 : ℝ) ≤ 1 / ((n : ℝ) + 1) := by positivity
  linarith
```

`harmonic_antitone hab` 是 $1/(b+1)\le 1/(a+1)$ 。两边用 $1$ 去减，不等号再翻一次，得到递增。 `BddAbove` 的上界取 $1$ ： $1/(n+1)\ge 0$ ，所以 $1-1/(n+1)\le 1$ 。

有界递增序列收敛到值域的上确界：

```lean
theorem approach_one_to_sup :
    Tendsto (fun n : ℕ => (1 : ℝ) - 1 / ((n : ℝ) + 1)) atTop
      (nhds (⨆ n : ℕ, (1 : ℝ) - 1 / ((n : ℝ) + 1))) :=
  tendsto_atTop_ciSup approach_one_mono approach_one_bounded
```

`tendsto_atTop_ciSup` 就是定理 16.16 的递增方向。上确界的变元要写成 `n : ℕ` ，否则 `(n : ℝ)` 会把上确界收成对全体实数取。同一条序列也是常数 $1$ 减去趋于 $0$ 的调和序列，所以极限是 $1$ 。极限只有一个，上确界就是 $1$ 。

```lean
theorem approach_one_to_one :
    Tendsto (fun n : ℕ => (1 : ℝ) - 1 / ((n : ℝ) + 1)) atTop (nhds 1) := by
  simpa using
    (tendsto_const_nhds : Tendsto (fun _ : ℕ => (1 : ℝ)) atTop (nhds 1)).sub
      tendsto_one_div_add_atTop_nhds_zero_nat

theorem approach_one_sup_eq : (⨆ n : ℕ, (1 : ℝ) - 1 / ((n : ℝ) + 1)) = 1 :=
  tendsto_nhds_unique approach_one_to_sup approach_one_to_one
```

常数极限先标成 `(1 : ℝ)` ， `sub` 才知道是实数相减。减完的中心是 $1-0$ ， `simpa` 把它收成 $1$ 。 `tendsto_nhds_unique` 比较的是同一个极限的两种写法。

Isabelle 的递增方向是 `LIMSEQ_incseq_SUP` ，前提按“有上界、然后递增”的顺序送进去：

```isabelle
lemma approach_to_sup:
  "(\<lambda>n. (1::real) - inverse (real (Suc n))) \<longlonglongrightarrow>
     (SUP i. (1::real) - inverse (real (Suc i)))"
  by (rule LIMSEQ_incseq_SUP[OF approach_bdd approach_inc])
```

`approach_bdd` 证明每一项 $\le 1$ ， `approach_inc` 用相邻的倒数比较推出递增。同一条序列也直接趋于 $1$ ：常数 $1$ 减去 $1/(n+1)\to 0$ ，先得到趋于 $1-0$ ，再化成 $1$ 。

```isabelle
lemma approach_to_one:
  "(\<lambda>n. (1::real) - inverse (real (Suc n))) \<longlonglongrightarrow> 1"
proof -
  have "(\<lambda>n. (1::real) - inverse (real (Suc n))) \<longlonglongrightarrow> 1 - 0"
    by (rule tendsto_diff[OF tendsto_const LIMSEQ_inverse_real_of_nat])
  then show ?thesis by simp
qed
```

计算通道看相邻两项： $1-1/11<1-1/12$ ，并且 $1-1/11$ 到 $1$ 的距离正好是 $1/11$ 。

## 16.17 七通道对照

| 主题 | Lean | Isabelle | Coq | Agda | 计算三通道 |
|------|------|----------|-----|------|------------|
| 尾部两项 | `harmonic_gap` | `eleven_twelve` | `Rabs` 后 $1/132<1/10$ | $10<11<12$ | 同样两个分数 |
| $\sqrt{2}$ 截断 | `sqrt_two_truncations` | `trunc_gap` | 距离 $<1/100$ | — | $141/100$ 与 $1414/1000$ |
| 收敛推出柯西 | `Tendsto.cauchySeq` | `LIMSEQ_imp_Cauchy` | — | — | — |
| $\mathbb{R}$ 完备 | `cauchySeq_tendsto_of_complete` | `Cauchy_convergent_iff` | — | — | — |
| 闭子集 | `IsClosed.isComplete` | `closed_sequentially` | — | — | — |
| 直径的端点 | `dist 1 3 = 2` | `dist_real_def` | `Rabs (3-1)=2` | $1+2=3$ | 同样两个距离 |
| 递减 | `Antitone` | `decseq_SucI` | $1/12<1/11$ | — | 同样两个分数 |
| 有界递增 | `tendsto_atTop_ciSup` | `LIMSEQ_incseq_SUP` | $1-1/11$ 到 $1$ 的距离 | — | 距离等于 $1/11$ |

## 16.18 本章验证清单

- `examples/lean/Realanalysis/Ch16Cauchy.lean`：尾部距离、截断、收敛推出柯西、 $\mathbb{R}$ 完备、闭子集、端点距离、递减、有界递增序列的上确界等于 $1$ 。
- `examples/isabelle/RA16/CauchyMono.thy`：同一批事实，递增序列收敛到 `(SUP i. X i)` 。
- `examples/coq/Ch16_cauchy.v`：具体的距离、跨度和相邻项。
- `examples/agda/Ch16_cauchy.agda`：下标还能往后走，$1$ 到 $3$ 跨两步。
- `examples/julia/16_cauchy.jl`、`examples/python/16_cauchy.py`、`examples/prolog/16_cauchy.pl`：同一组有理数。

复验：`pwsh -NoProfile -Command '& ./build.ps1 -Chapter 16'`。

## 16.19 接下来

本章的结论是：紧度量空间和 $\mathbb{R}^k$ 完备，里面每条柯西序列都收敛；有最小上界性的有序域里，每条有界单调序列都收敛。

子序列极限的上确界和下确界，以及“发散”和“发散到无穷”的差别，留到下一章。

上一章：[15 极限与子序列](15-subsequences.md) · 下一章：[17 子序列极限](17-subseq-limits.md) · [返回目录](../README.md)
