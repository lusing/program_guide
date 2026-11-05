# 第 20 章 总结

> 前面十九章的定理已经够多，新题里“把已知都用上”因此不好下手。
> 这一章不证明新定理。它从要证的结论往回推，并把每一章后来反复用到的那一条技巧收在一处。
> 连续性、导数、积分和函数序列都还没开始。它们站在实数、拓扑和序列上。

## 20.1 从结论往回推

面对一道新题，先写下要证的那句话，再问它立刻能化成哪件更小的事。集合相等化成两个包含，收敛化成一个 $\varepsilon$ ，级数化成部分和。范围缩小到一句能直接检验的话，证明就有了入口。

定理的假设要列出来，并且设法每一条都用上。一条假设从头到尾没出现，多半是证明还没写完，或者那条假设其实可以拿掉。一般情形之前，先做最简单的例子：有限集、正项、公比 $\frac{1}{2}$ 、半径先取成 $\frac{\varepsilon}{2}$ 。图也要画。邻域、嵌套区间和部分和的折线，画出来以后量词的顺序不容易反。

下面按原书的顺序，把每一章留下的那一条写清楚。教程 00 对应原书第 1 章，01 对应第 2 章，02 对应第 3 章，03 对应第 4 章。原书第 5 章在教程里分成 04 和 05。从 06 起，教程章号与原书相同。

## 20.2 阅读、四种证法、集合与实数

原书第 1 章要的是读法。数学要慢慢读，定义和定理旁边做笔记，把量词的顺序用自己的话重写一遍。定义先读懂，后面的 $\varepsilon$ 才知道在约束谁。

原书第 2 章留下四种可以立刻试的证法。结论看起来假，就找一个反例。结论是“ $P$ 则 $Q$ ”，证它的逆否“非 $Q$ 则非 $P$ ”有时更短。假设结论为假能推出矛盾，就用反证。结论对每个自然数成立，就用归纳。直接把定义展开，仍然是默认的第一条路。

原书第 3 章留下集合相等的拆法。要证 $A=B$ ，就证 $A\subseteq B$ 并且 $B\subseteq A$ 。原书写的是 $\subset$ ，意思是这一侧的包含，不要求真子集。一边是“ $A$ 的元素都在 $B$ 里”，另一边是“ $B$ 的元素都在 $A$ 里”。

```lean
theorem set_eq_iff {α : Type*} (A B : Set α) : A = B ↔ A ⊆ B ∧ B ⊆ A :=
  Set.Subset.antisymm_iff
```

`Set.Subset.antisymm_iff` 就是这个等价。左边是集合相等，右边是两个包含同时成立。

同一章还留下德摩根律：并集的补集等于补集的交集。

```lean
theorem de_morgan {α : Type*} (A B : Set α) : (A ∪ B)ᶜ = Aᶜ ∩ Bᶜ := by
  ext x
  simp
```

`ext` 把集合相等化成“对每个元素，两边同时成立或同时不成立”。 `simp` 展开并、交、补的成员关系。

Isabelle 里这两条分开写。相等仍拆成两个包含， `subset_antisym` 把两个包含拼回相等。补集的那一条直接用库里的 `Compl_Un` 。

```isabelle
lemma set_eq_iff:
  fixes A B :: "'a set"
  shows "A = B \<longleftrightarrow> A \<subseteq> B \<and> B \<subseteq> A"
proof
  assume "A = B"
  then show "A \<subseteq> B \<and> B \<subseteq> A" by simp
next
  assume "A \<subseteq> B \<and> B \<subseteq> A"
  then have "A \<subseteq> B" and "B \<subseteq> A" by simp_all
  then show "A = B" by (rule subset_antisym)
qed

lemma de_morgan:
  fixes A B :: "'a set"
  shows "- (A \<union> B) = (- A) \<inter> (- B)"
  by (rule Compl_Un)
```

计算通道在一个有限论域上核对同一句话。论域是 $\{1,2,3\}$ ， $A=\{1\}$ ， $B=\{2\}$ 。 $A\cup B=\{1,2\}$ ，它在论域里的补是 $\{3\}$ 。 $A$ 的补是 $\{2,3\}$ ， $B$ 的补是 $\{1,3\}$ ，两者的交还是 $\{3\}$ 。

```python
U = {1, 2, 3}
A = {1}
B = {2}
assert U - (A | B) == (U - A) & (U - B)
```

Julia 用 `setdiff` 、 `union` 和 `intersect` 做同一组集合。Prolog 这一章没有再写集合，德摩根留在前面的集合那一章。

原书第 4 章留下上确界的两条用法。上确界 $s$ 是上界，所以集合里没有比 $s$ 更大的数。它又是最小的上界，所以任何比 $s$ 小的数都不再是上界：它的右边还能找到集合里的元素。证明“某个数就是上确界”时，这两条要分别写。

原书第 5 章在教程里分成两篇。04 是域公理和有序域里只靠公理推出的算术。05 是完备性推出的三件事，其中第一条就是阿基米德性质： $x>0$ 时，对任意实数 $y$ 都存在自然数 $n$ 使 $nx>y$ 。 $x$ 必须是正的； $x$ 是负数时，把 $n$ 放大只会让 $nx$ 更小。最常用的是 $x=1$ ：任意实数 $y$ 后面都还有自然数。 $y=5$ 时， $6$ 就是一个见证。

```lean
theorem past_five : ∃ n : ℕ, (5 : ℝ) < n :=
  exists_nat_gt 5
```

`exists_nat_gt` 对每个实数都给出一个更大的自然数。这里把实数取成 $5$ 。

```isabelle
lemma past_five: "\<exists>n::nat. (5::real) < of_nat n"
  by (rule reals_Archimedean2)
```

`reals_Archimedean2` 是同一句话在 Isabelle 里的名字。 `of_nat` 把自然数送进实数。

```coq
Lemma past_five : 5 < 6.
Proof.
  lra.
Qed.
```

Coq 不调用那条一般定理，只让 `lra` 承认 $5<6$ 。Agda 用标准库里“每个自然数都小于它的后继”：

```agda
past-five : 5 < 6
past-five = n<1+n 5
```

`n<1+n 5` 就是 $5<6$ 。Python、Julia、Prolog 打印的 `6 is past 5` 是同一次核对。Prolog 每次 `verify` 都用新变量，这里是 `Six` 和 `Five` ，避免名字漏到下一次调用。

## 20.3 范数、双射与可数

原书第 6 章留下三角不等式，以及更一般的柯西–施瓦茨不等式。估计距离时，先用三角不等式把和拆开，再一项一项估计。内积出现时，柯西–施瓦茨把内积的绝对值收成两条范数的积。

```lean
theorem triangle (x y : ℝ) : |x + y| ≤ |x| + |y| :=
  abs_add_le x y
```

`abs_add_le` 是有序群上绝对值的三角不等式，实数是它的一个实例。

```isabelle
lemma triangle: "\<bar>(x::real) + y\<bar> \<le> \<bar>x\<bar> + \<bar>y\<bar>"
  by (rule abs_triangle_ineq)
```

`abs_triangle_ineq` 是同一条不等式。计算通道拿一组具体数字看它： $|3+(-1)|=2$ ， $|3|+|-1|=4$ ，而 $2\le 4$ 。

```python
assert abs(3 + -1) <= abs(3) + abs(-1)
```

Coq 里 `lra` 不消化绝对值，所以先把两边算成整数再交给它。左边是 $2$ ，右边是 $3+1$ 。

```coq
Lemma triangle_numbers : 2 <= 3 + 1.
Proof.
  lra.
Qed.
```

Agda 这一章只用自然数。 $2<4$ 拆成 $2<3$ 和 $3<4$ ，各用一次后继，再用传递性接上。

```agda
two-lt-four : 2 < 4
two-lt-four = <-trans (n<1+n 2) (n<1+n 3)
```

`n<1+n 2` 是 $2<3$ ， `n<1+n 3` 是 $3<4$ ， `<-trans` 得到 $2<4$ 。这比 $2\le 4$ 更强，足够说明左边严格落在右边里面。

原书第 7 章留下双射的三条检验。它首先是一个函数：定义域里每个元素都有一个值，而且不会同时映到两个不同的值。它是单射：不同的元素映到不同的值。它是满射：上域里每个元素都有原像。三条齐了，两个集合才一样大。少写一条，构造出来的往往只是一个单射或一个满射。

原书第 8 章留下可数性的一个修法。为了证明可数，常常先写下一一对应，再发现对应里有重复。重复使它暂时不是单射。把定义域收成去掉重复之后的那个子集，限制在子集上的函数就是双射。有理数的可数性就是这样修出来的。

## 20.4 邻域、开闭、紧与连通

原书第 9 章留下半径的算法。要造一个邻域，使它落在某个集合里，或者使它还含着另一个点，就把结论里的不等式倒着解，解出的那个正数就是半径。先随便写一个 $\delta$ ，再发现它太大，就回到不等式里把它改小。

原书第 10 章留下补集。直接证一个集合是闭的，有时不如证它的补集是开的。补集把开和闭对调：开集的补是闭集，闭集的补是开集。并和交也跟着德摩根律对调。

原书第 11 章留下套娃。一列紧集一个套一个，而且每一个都非空，那么这无穷多个集合的交集仍然非空。实数上的闭区间套是它的特例。用它的时候要先确认每一层都紧，只嵌套、不紧，交集可以是空的。

原书第 12 章留下海涅–博雷尔定理。在 $\mathbb{R}^k$ 里，紧、以及“闭并且有界”，是同一件事。要证紧，可以改证闭和有界。要证一个紧集上的序列有收敛子序列，也可以先用有界。这个等价专属于 $\mathbb{R}^k$ 这类空间，换一个度量空间，闭且有界可以不紧。

原书第 13 章留下分情况。拓扑里问一个点 $p$ 和集合 $A$ 的关系，常常分成 $p\in A$ 和 $p\notin A$ 。在集合里时用内部或成员的定义，不在集合里时用补集或极限点的定义。完备集和连通集的论证都靠这一刀。

## 20.5 序列与级数

原书第 14 章留下误差预算。序列 $p_n$ 收敛到 $p$ 的定义是：对任意 $\varepsilon>0$ ，存在 $N$ ，使

$$n\ge N\implies d(p_n,p)<\varepsilon.$$

中译把这里的“序列”印成了“级数”，公式仍是点到极限的距离。定义对每一个正数都成立，所以 $\varepsilon$ 可以换成任何一个正数，包括 $\frac{\varepsilon}{2}$ 。两半加回去还是原来的 $\varepsilon$ 。

```lean
theorem eps_split (ε : ℝ) : ε / 2 + ε / 2 = ε := by
  ring
```

`ring` 只做算术，把两半拼回 $\varepsilon$ 。这一步与 $\varepsilon$ 的正负无关；用在收敛定义里时，再单独要求 $\varepsilon>0$ ，于是 $\frac{\varepsilon}{2}$ 仍是正数，可以送回定义。

```coq
Lemma eps_split : 1 / 2 + 1 / 2 = 1.
Proof.
  lra.
Qed.
```

这里把 $\varepsilon$ 取成 $1$ 。Agda 用自然数 $1+1=2$ 表示同一件拼接， `refl` 就是定义上相等。

```agda
halves : 1 + 1 ≡ 2
halves = refl
```

Prolog 用有理数，不用浮点除法。 `rdiv(1, 2)` 是 $\frac{1}{2}$ ，两次相加得到 $1$ 。变量 `Half` 和 `Whole` 只在这一次 `verify` 里出现。

原书第 15 章留下子序列的构造法。它和归纳一样：先选定第一项，再假定前面一项已经选好，然后在更后面挑出下一项，使它满足下一步需要的不等式。值域只有有限个点时要先单独处理，因为那样的序列必有一项重复无穷次，那一项自己就做成一条常数子序列。

原书第 16 章留在完备空间里。在 $\mathbb{R}^k$ ，以及任何一个完备度量空间里，序列是柯西的，就已经收敛。极限不用事先猜出来。实数上这条直接调用第 16 章已经证过的话。

```lean
theorem cauchy_is_enough {s : ℕ → ℝ} (h : CauchySeq s) :
    ∃ p, Tendsto s atTop (nhds p) :=
  Realanalysis.Ch16.cauchy_converges h
```

`CauchySeq` 是“项与项的距离最终任意小”。 `cauchy_converges` 在实数上找出极限 $p$ ，并给出 $s$ 沿 $n\to\infty$ 趋于 $p$ 。换一个不完备的空间，例如去掉 $0$ 的实数轴，柯西序列可以没有极限。所以这一条把“空间是完备的”用了进去。

原书第 17 章留下子序列的子序列。一条子序列还可以再抽。证明上极限与下极限相等时，这个动作用来把“最大的极限点”和“最小的极限点”对齐。另一个常用的分叉是：若每条子序列要么还含一条发散的子序列，要么含一条有界的子序列，那么有界那一支在 $\mathbb{R}^k$ 里又有收敛的子序列。发散和收敛因此都被子序列看见。

原书第 18 章留下夹逼，以及二项式展开后丢掉正项。夹逼是：两边都趋于同一个极限，夹在中间的序列也趋于它。处理 $n$ 次幂时，把 $(a+b)^n$ 按二项式展开。要证这个幂大于或大于等于某个更小的量，正项可以丢掉，剩下的部分只要仍然够大，整个幂就够大。 $n=2$ 、 $x=\frac{1}{2}$ 时，展开 $(1+x)^2$ 后只留下 $1+2x$ ，它仍然严格小于原来的平方。

```lean
theorem binomial_drop : (1 : ℝ) + 2 * (1 / 2) < (3 / 2) ^ 2 :=
  Realanalysis.Ch18.binomial_step
```

左边是 $1+2\cdot\frac{1}{2}=2$ 。右边是 $\left(\frac{3}{2}\right)^2=\frac{9}{4}$ 。 $2<\frac{9}{4}$ ，丢掉的那个正项没有把不等号翻过来。

Isabelle 把同一组数先化简再比较。 `power2_eq_square` 把平方写成自己乘自己，然后得到 $\frac{9}{4}$ 。

```isabelle
lemma binomial_drop: "(1::real) + 2 * (1 / 2) < (3 / 2) ^ 2"
proof -
  have left: "(1::real) + 2 * (1 / 2) = 2" by simp
  have "(3 / 2 :: real) ^ 2 = (3 / 2) * (3 / 2)"
    by (rule power2_eq_square)
  also have "... = 9 / 4" by simp
  finally have right: "(3 / 2 :: real) ^ 2 = 9 / 4" .
  show ?thesis by (simp add: left right)
qed
```

`also` 接的是等式。 `finally` 把两步合成 $\left(\frac{3}{2}\right)^2=\frac{9}{4}$ 。最后一步用左边等于 $2$ 、右边等于 $\frac{9}{4}$ ，化简出 $2<\frac{9}{4}$ 。

```coq
Lemma binomial_drop : 1 + 2 * (1 / 2) < (3 / 2) * (3 / 2).
Proof.
  lra.
Qed.
```

平方在这里写成两次相乘，避免再引入一个幂的引理。 `lra` 直接承认 $2<\frac{9}{4}$ 。

原书第 19 章留下级数的身份。级数是部分和组成的序列。 $\sum a_n$ 收敛，就是这条部分和序列收敛。序列的定理因此都能用到部分和上。级数另外还有自己的判别法：比较判别看一项是否最终被一条已知级数控制，柯西凝聚判别把递减的非负项收成子列 $2^k a_{2^k}$ 的级数。

公比 $\frac{1}{2}$ 的几何级数从 $n=0$ 加起，和是 $\frac{1}{1-\frac{1}{2}}=2$ 。这仍是部分和的极限，闭式只是把极限算出来。

```lean
theorem geometric_is_sequence : ∑' n : ℕ, ((1 : ℝ) / 2) ^ n = 2 :=
  Realanalysis.Ch19.half_series
```

`half_series` 用 $|1/2|<1$ 时的几何级数求和，得到 $2$ 。

```isabelle
lemma geometric_is_sequence: "suminf (\<lambda>n. ((1::real) / 2) ^ n) = 2"
proof -
  have "suminf (\<lambda>n. ((1::real) / 2) ^ n) = 1 / (1 - 1 / 2)"
    by (rule suminf_geometric) simp
  then show ?thesis by simp
qed
```

`suminf_geometric` 要求公比的范数小于 $1$ ， `simp` 确认 $\left|\frac{1}{2}\right|<1$ ，并给出和 $\frac{1}{1-\frac{1}{2}}$ 。下一步把这个分式化成 $2$ 。

```python
assert 1 / (1 - Fraction(1, 2)) == 2
```

`Fraction` 保持有理数。 $1-\frac{1}{2}=\frac{1}{2}$ ，再取倒数得到 $2$ 。Julia 用 `1//2` 这种有理数写法。Prolog 写成 `rdiv(1, rdiv(1, 1) - rdiv(1, 2))` ，变量名叫 `Sum` ，和前面的 `Half` 不是同一次 `verify` 。

根值判别、比值判别、 $e$ 、 $\pi$ 和泰勒级数，原书在级数那一章只点了名字。这一章仍然不证明它们。

## 20.6 后面的课站在这三样东西上

课程若还继续，下一件东西会是连续性，然后是导数、积分，以及函数序列。那些定义都要回到实数的完备、开集和邻域的语言，以及序列的极限。这三样熟练之后，后面的定义是在同一套 $\varepsilon$ 上换一个量词的位置。

读和写证明是另一件同样花时间的事。反例、逆否、反证、归纳、两边包含、从结论倒推半径，这些动作已经在前面的章里用过。先把定义读慢，计算和证明才不会各写各的。

## 20.7 七通道对照

| 主题 | Lean | Isabelle | Coq | Agda | 计算三通道 |
|------|------|----------|-----|------|------------|
| 集合相等 | `Set.Subset.antisymm_iff` | `subset_antisym` | — | — | — |
| 德摩根 | `ext` 后 `simp` | `Compl_Un` | — | — | 论域 $\{1,2,3\}$ |
| 超过 $5$ | `exists_nat_gt` | `reals_Archimedean2` | $5<6$ | `n<1+n` | $6>5$ |
| 三角不等式 | `abs_add_le` | `abs_triangle_ineq` | $2\le 3+1$ | $2<4$ | $|3+(-1)|\le 4$ |
| $\frac{\varepsilon}{2}$ 拼回 $\varepsilon$ | `ring` | `simp` | $\frac{1}{2}+\frac{1}{2}=1$ | $1+1=2$ | 有理数相加 |
| 柯西则收敛 | `cauchy_converges` | — | — | — | — |
| 丢掉正项 | `binomial_step` | `power2_eq_square` | `lra` | — | — |
| 公比 $\frac{1}{2}$ | `half_series` | `suminf_geometric` | $\frac{1}{1-\frac{1}{2}}=2$ | — | 同一闭式 |

Julia 和 Python 都做了德摩根的有限核对。Prolog 做了 $6>5$ 、三角不等式的数字、两半相加，以及几何闭式，集合那一条没有放进这一章。

## 20.8 本章验证清单

- `examples/lean/Realanalysis/Ch20Summary.lean`：互相包含、德摩根、超过 $5$ 、三角不等式、两半拼回、柯西则收敛、二项式丢掉正项、公比 $\frac{1}{2}$ 的和。
- `examples/isabelle/RA20/Summary.thy`：同一批里除去“柯西则收敛”。几何和先写成 $\frac{1}{1-\frac{1}{2}}$ ，再化成 $2$ 。
- `examples/coq/Ch20_summary.v`： $5<6$ 、 $2\le 3+1$ 、两半、二项式、几何闭式，全部交给 `lra` 。
- `examples/agda/Ch20_summary.agda`： $5<6$ ， $1+1=2$ ， $2<4$ 。
- `examples/julia/20_summary.jl`、`examples/python/20_summary.py`：有限论域上的德摩根，加上四条数值核对。
- `examples/prolog/20_summary.pl`：四条数值核对，有理数用 `rdiv` 。

复验：`pwsh -NoProfile -Command '& ./build.ps1 -Chapter 20'`。

## 20.9 原书在这里结束

原书正文停在这一章。连续性、导数、积分和函数序列没有在这里展开。下一章是教程自己的收官，给出阅读路线，并沿这条路线再核对一次。

上一章：[19 级数](19-series.md) · 下一章：[21 收官](21-wrapup.md) · [返回目录](../README.md)
