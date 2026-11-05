# 第 19 章 级数

> 级数不是“无穷多个数加在一起”这句口号，它是部分和组成的序列。
> 部分和收敛，级数就收敛。通项趋于 $0$ 只是必要条件。
> 几何级数、比较判别、柯西凝聚判别，再加上 p 级数，是这一章的工具。

## 19.1 定义 19.1：部分和

$\{a_n\}$ 是实数列。第 $n$ 个部分和是有限和

$$
s_n=\sum_{k=1}^{n}a_k=a_1+a_2+\cdots+a_n.
$$

序列 $\{s_n\}$ 叫做级数，通常写成 $\sum_{n=1}^{\infty}a_n$ 。若 $s_n\to s$ ，就说级数收敛到 $s$ ，并把它的和也写成这个符号。没有这样的 $s$ ，级数就发散。 $a_n$ 叫做项。

记号上有一件容易混的事。 $\sum_{n=1}^{\infty}a_n$ 写出来像一个和，它实际指的是 $\lim_{n\to\infty}s_n$ 。看到“级数收敛到 $s$ ”，要读成

$$
s=\lim_{n\to\infty}\sum_{k=1}^{n}a_k.
$$

和式也可以从 $n=0$ 写起。那只是把序列的第一项叫做 $a_0$ ，部分和照旧。起点终点都很清楚时，简写成 $\sum a_n$ 。

级数就是一条序列，所以序列的定理都能用到部分和上。另外有一批定理只对级数有意义，比较判别就是这种。

## 19.2 定理 19.2：级数的柯西准则

$\sum a_n$ 收敛，当且仅当对任意 $\varepsilon>0$ ，存在 $N$ ，使

$$
m\ge n\ge N\implies\left|\sum_{k=n}^{m}a_k\right|\le\varepsilon.
$$

绝对值里面是有限和。它等于 $s_m-s_{n-1}$ 。所以这条准则就是在说部分和是柯西序列。实数和复数上，柯西序列正好是收敛序列，因此级数收敛当且仅当部分和是柯西的。

一个方向：部分和收敛，于是它是柯西的。给定 $\varepsilon>0$ ，有 $N$ 使 $m\ge n\ge N$ 时 $|s_m-s_{n-1}|<\varepsilon$ ，从而那段有限和的绝对值 $\le\varepsilon$ 。另一个方向把 $\varepsilon$ 换成 $\frac{\varepsilon}{2}$ ，再把 $m=n$ 的距离 $0$ 和 $m>n$ 的 $|s_m-s_n|$ 分开，就得到部分和是柯西的。

库里的写法用严格小于，并且和式跑在半开区间上。 $n\le m$ 时这个和是空的，范数是 $0$ ，和“ $m\ge n$ ”的写法等价。

```isabelle
lemma series_cauchy:
  "summable (f :: nat \<Rightarrow> real) \<longleftrightarrow>
    (\<forall>e>0. \<exists>N. \<forall>m\<ge>N. \<forall>n. norm (sum f {m..<n}) < e)"
  by (rule summable_Cauchy)
```

`summable` 就是“部分和收敛”。 `sum f {m..<n}` 是从 $m$ 加到 $n-1$ 。 `summable_Cauchy` 把收敛换成这段范数最终小于任意正数。

## 19.3 推论 19.3：通项必须趋于 $0$

级数收敛，则 $a_n\to 0$ 。

证明是把准则里的 $m$ 取成 $n$ 。 $|s_n-s_{n-1}|=|a_n|$ ，所以 $|a_n|$ 最终小于任意 $\varepsilon$ 。

```isabelle
lemma terms_to_zero:
  fixes f :: "nat \<Rightarrow> real"
  assumes "summable f"
  shows "f \<longlonglongrightarrow> 0"
  by (rule summable_LIMSEQ_zero[OF assms])
```

`summable_LIMSEQ_zero` 就是这句推论。逆否命题更常用：通项不趋于 $0$ ，级数一定发散。

逆命题不成立。 $\frac{1}{n}\to 0$ ，但调和级数 $\sum\frac{1}{n}$ 发散。这要等 p 级数做完才有完整证明。眼下先看一条假证明，错在哪里。

假证明说： $a_n\to 0$ 时，取 $N$ 使 $n\ge N$ 就有 $|a_n|<\varepsilon$ 。令 $s=\left|\sum_{n=1}^{N}a_n\right|$ ，然后写成

$$
\left|\sum_{n=1}^{\infty}a_n\right|\le s+\left|\sum_{n=N}^{\infty}a_n\right|<s+\varepsilon,
$$

于是无穷和的绝对值被 $s$ 控制，再让 $\varepsilon$ 任意小。

第一处错：收敛之前， $\sum_{n=N}^{\infty}a_n$ 不是一个数。 $\sum a_n$ 只是部分和序列的记号，不能先把它拆成“有限和加一个无穷和”。第二处更离谱：每一项绝对值小于 $\varepsilon$ ，推不出无穷多项的和小于 $\varepsilon$ 。 $\varepsilon+\varepsilon+\varepsilon+\cdots$ 不会小于 $\varepsilon$ 。

常数 $1$ 连必要条件都不满足。 $|1|$ 并不小于 $\frac{1}{2}$ ，所以 $\sum 1$ 发散。它也是公比 $x=1$ 的几何级数。

```lean
theorem const_one_diverges : ¬Summable (fun n : ℕ => (1 : ℝ) ^ n) := by
  rw [summable_geometric_iff_norm_lt_one]
  norm_num
```

`summable_geometric_iff_norm_lt_one` 说 $\sum x^n$ 可和当且仅当 $|x|<1$ 。 $x=1$ 时右边不成立。

```coq
Lemma one_not_small : 1 > 1 / 2.
Proof.
  lra.
Qed.
```

## 19.4 定理 19.4：非负项

若每个 $a_n\ge 0$ ，则 $\sum a_n$ 收敛当且仅当部分和 $\{s_n\}$ 有界。

$a_n\ge 0$ 使 $s_{n+1}=s_n+a_{n+1}\ge s_n$ ，部分和单调递增。单调序列收敛当且仅当有界。这一句只用实数：复数没有正负，谈不上单调。

开头有限项改不了敛散。从某一项之后非负，和全部非负是一回事。

调和级数的前四项已经能看出部分和在往上走，而且跨过了 $2$ 。把 $\frac{1}{3}$ 换成更小的 $\frac{1}{4}$ ，

$$
1+\frac{1}{2}+\frac{1}{4}+\frac{1}{4}=2,
$$

原式更大。这还不是“无界”的证明，只是同一套分组的第一段。完整的发散放在 p 级数里。

```lean
theorem harmonic_group : (1 : ℝ) + 1 / 2 + 1 / 4 + 1 / 4 = 2 := by
  norm_num

theorem harmonic_four : (1 : ℝ) + 1 / 2 + 1 / 3 + 1 / 4 > 2 := by
  norm_num
```

## 19.5 定理 19.5：收敛的比较判别

若存在 $N_0$ ，使 $n\ge N_0$ 时 $|a_n|\le c_n$ ，并且 $\sum c_n$ 收敛，则 $\sum a_n$ 收敛。

$\sum c_n$ 收敛，所以它的有限段最终小于 $\varepsilon$ 。三角不等式给出

$$
\left|\sum_{k=n}^{m}a_k\right|\le\sum_{k=n}^{m}|a_k|\le\sum_{k=n}^{m}c_k.
$$

$n\ge N_0$ 时 $c_k\ge |a_k|\ge 0$ ，右边的和就是它自己的绝对值。于是 $\sum a_n$ 满足柯西准则。

取 $a_n=\left(-\frac{1}{2}\right)^n$ ， $c_n=\left(\frac{1}{2}\right)^n$ 。绝对值正好相等，右边是公比小于 $1$ 的几何级数。

```lean
theorem alt_half_summable : Summable (fun n : ℕ => (-(1 : ℝ) / 2) ^ n) := by
  apply Summable.of_norm
  simpa [norm_pow, abs_div, abs_neg, abs_one] using
    summable_geometric_of_abs_lt_one (by norm_num : |(1 / 2 : ℝ)| < 1)
```

`Summable.of_norm` 说：绝对值组成的级数可和，原级数就可和。 `norm_pow` 把范数拆到公比上， `abs_neg` 和 `abs_div` 把 $\left|-\frac{1}{2}\right|$ 收成 $\frac{1}{2}$ 。 `summable_geometric_of_abs_lt_one` 用的就是 $|x|<1$ 。

## 19.6 定理 19.6：发散的比较判别

若存在 $N_0$ ，使 $n\ge N_0$ 时 $a_n\ge d_n\ge 0$ ，并且 $\sum d_n$ 发散，则 $\sum a_n$ 发散。

只适用于非负项。如果只知道每一项 $\ge -1$ ，而 $\sum(-1)$ 发散，什么也推不出来。

证明走逆否。设 $\sum a_n$ 收敛。 $d_n\ge 0$ 时 $|d_n|=d_n\le a_n$ ，收敛的比较判别给出 $\sum d_n$ 收敛。也可以用有界性： $\sum a_n$ 的部分和有上界，更小的非负部分和也有同一个上界，于是 $\sum d_n$ 收敛。 $d_n\ge 0$ 只在 $n\ge N_0$ 之后成立也够，因为前面是有限和。

## 19.7 定理 19.7：几何级数

$|x|<1$ 时

$$
\sum_{n=0}^{\infty}x^n=\frac{1}{1-x}.
$$

$|x|\ge 1$ 时这个级数发散。项是公比的方幂，就叫几何级数。

$x\ge 1$ 时 $x^n\ge 1$ 。常数级数 $1+1+1+\cdots$ 发散，比较判别把 $\sum x^n$ 也判成发散。 $x\le -1$ 时 $|x^n|\ge 1$ ，通项不趋于 $0$ ，用推论 19.3 的逆否命题。

$|x|<1$ 时先算部分和。令

$$
s_n=\sum_{k=0}^{n}x^k=1+x+\cdots+x^n.
$$

乘上 $1-x$ ：

$$
(1-x)s_n=(1+x+\cdots+x^n)-(x+x^2+\cdots+x^{n+1})=1-x^{n+1}.
$$

$x\neq 1$ ，所以

$$
s_n=\frac{1-x^{n+1}}{1-x}.
$$

$|x|<1$ 时 $x^{n+1}\to 0$ ，于是 $s_n\to\frac{1}{1-x}$ 。

从 $n=1$ 算起要扣掉 $x^0=1$ ：

$$
\sum_{n=1}^{\infty}x^n=\frac{1}{1-x}-1=\frac{x}{1-x}.
$$

$x=\frac{1}{2}$ 时，加到 $x^2$ 的部分和是 $\frac{7}{4}$ ，闭式 $\frac{1-\left(\frac{1}{2}\right)^3}{1-\frac{1}{2}}$ 也是 $\frac{7}{4}$ 。从 $n=0$ 加到无穷是 $\frac{1}{1-\frac{1}{2}}=2$ 。

```lean
theorem half_partial : (1 : ℝ) + 1 / 2 + 1 / 4 = 7 / 4 := by
  norm_num

theorem half_closed : (1 - ((1 : ℝ) / 2) ^ 3) / (1 - 1 / 2) = 7 / 4 := by
  norm_num

theorem half_series : ∑' n : ℕ, ((1 : ℝ) / 2) ^ n = 2 := by
  rw [tsum_geometric_of_abs_lt_one (by norm_num : |(1 / 2 : ℝ)| < 1)]
  norm_num
```

`tsum_geometric_of_abs_lt_one` 的结论是 $\sum_{n=0}^{\infty}r^n=(1-r)^{-1}$ 。 $r=\frac{1}{2}$ 时 `norm_num` 把右边收成 $2$ 。下标从 $0$ 起，和书上从 $n=0$ 写的公式一致。

Isabelle 用部分和公式先得到 $\frac{x^n-1}{x-1}$ ，再把分子分母同时变号，写成 $\frac{1-x^n}{1-x}$ 。这里 $n=3$ ，加的是 $x^0$ 到 $x^2$ 。

```isabelle
lemma half_partial:
  "(\<Sum>i<3. ((1::real) / 2) ^ i) = (1 - ((1::real) / 2) ^ 3) / (1 - 1 / 2)"
proof -
  have "(\<Sum>i<3. ((1::real) / 2) ^ i) = (((1::real) / 2) ^ 3 - 1) / (1 / 2 - 1)"
    by (rule geometric_sum) simp
  also have "... = (1 - ((1::real) / 2) ^ 3) / (1 - 1 / 2)"
    by simp
  finally show ?thesis .
qed

lemma half_sum: "suminf (\<lambda>n. ((1::real) / 2) ^ n) = 2"
proof -
  have "suminf (\<lambda>n. ((1::real) / 2) ^ n) = 1 / (1 - 1 / 2)"
    by (rule suminf_geometric) simp
  then show ?thesis by simp
qed
```

`geometric_sum` 要求公比不是 $1$ ， `simp` 确认 $\frac{1}{2}\neq 1$ 。 `suminf_geometric` 就是无穷和 $\frac{1}{1-x}$ 。

## 19.8 例 19.8：用几何级数填矩形

从 $n=1$ 起，

$$
\sum_{n=1}^{\infty}\left(\frac{2}{3}\right)^n=\frac{\frac{2}{3}}{1-\frac{2}{3}}=2.
$$

一块面积为 $2$ 的 $1\times 2$ 矩形可以这样填。先放进 $\frac{2}{3}$ ，剩下 $2-\frac{2}{3}=\frac{4}{3}$ 。再放进 $\left(\frac{2}{3}\right)^2=\frac{4}{9}$ ，它正好是剩下面积的三分之一，还剩 $\frac{4}{3}-\frac{4}{9}=\frac{8}{9}$ 。下一步放进 $\frac{8}{27}$ ，又是剩下的三分之一。每一步都填掉剩余面积的三分之一，无穷步之后整块面积 $2$ 被填满。

全和从 $n=0$ 算是 $\frac{1}{1-\frac{2}{3}}=3$ ，扣掉首项 $1$ ，剩下 $2$ 。

```lean
theorem two_thirds : ∑' n : ℕ, ((2 : ℝ) / 3) ^ n - 1 = 2 := by
  rw [tsum_geometric_of_abs_lt_one (by norm_num : |(2 / 3 : ℝ)| < 1)]
  norm_num
```

公分母换成整数，剩下的两步是 $6-2=4$ 和 $12-4=8$ 。前一个是三分母上的 $6-2$ ，后一个是九分母上的 $12-4$ 。

```agda
remain : 6 ∸ 2 ≡ 4
remain = refl

next-remain : 12 ∸ 4 ≡ 8
next-remain = refl
```

`∸` 是截断减法。这两步就是矩形里剩下的面积，只是把分母乘进去了。

部分和 $1+\frac{1}{2}+\frac{1}{4}$ 在四分母上是 $4+2+1=7$ ，而无穷和 $2=\frac{8}{4}$ 。 $7<8$ ，有限和还没填满。

```agda
partial : 4 + 2 + 1 ≡ 7
partial = refl

seven-lt-eight : 7 < 8
seven-lt-eight = n<1+n 7
```

## 19.9 定理 19.9：柯西凝聚判别

设 $a_1\ge a_2\ge a_3\ge\cdots\ge 0$ 。则 $\sum_{n=1}^{\infty}a_n$ 收敛当且仅当 $\sum_{k=0}^{\infty}2^k a_{2^k}$ 收敛。

两项都非负，所以收敛等价于部分和有界。记

$$
s_n=a_1+\cdots+a_n,\qquad t_k=a_1+2a_2+4a_4+\cdots+2^k a_{2^k}.
$$

只要证明 $\{s_n\}$ 有界当且仅当 $\{t_k\}$ 有界。两边的下界都是 $0$ ，看上界即可。

若每个 $t_k\le M$ ，固定 $n$ ，取 $k$ 使 $n<2^k$ 。单调性把 $s_n$ 放进按二的方幂切开的块里：

$$
\begin{aligned}
s_n
&\le a_1+(a_2+a_3)+(a_4+\cdots+a_7)+\cdots+(a_{2^k}+\cdots+a_{2^{k+1}-1})\\
&\le a_1+2a_2+4a_4+\cdots+2^k a_{2^k}=t_k\le M.
\end{aligned}
$$

每一块里的项都不超过块首，块的长度正好是 $2^k$ 这种二的方幂。

反过来，若 $\{t_k\}$ 无界，取 $n>2^k$ 。把 $s_n$ 从下界估：

$$
\begin{aligned}
s_n
&\ge a_1+a_2+(a_3+a_4)+\cdots+(a_{2^{k-1}+1}+\cdots+a_{2^k})\\
&\ge\frac{1}{2}a_1+a_2+2a_4+\cdots+2^{k-1}a_{2^k}
=\frac{1}{2}t_k.
\end{aligned}
$$

$a_1\ge 0$ ，所以 $a_1+a_2\ge\frac{1}{2}a_1+a_2$ 。后面每一块都有 $2^{j-1}$ 个不小于 $a_{2^j}$ 的项。于是 $t_k$ 可以任意大时， $s_{2^k}$ 也任意大。

调和前四项就是这个下界估计的第一段： $\frac{1}{3}\ge\frac{1}{4}$ ，所以

$$
1+\frac{1}{2}+\frac{1}{3}+\frac{1}{4}>1+\frac{1}{2}+\frac{1}{4}+\frac{1}{4}=2.
$$

库里的等价是 `summable_condensed_iff_of_nonneg` ：非负而且最终递减时， $\sum 2^k f(2^k)$ 可和当且仅当 $\sum f$ 可和。

## 19.10 定理 19.10：p 级数

$p>1$ 时 $\sum_{n=1}^{\infty}\frac{1}{n^p}$ 收敛。 $p\le 1$ 时发散。调和级数是 $p=1$ 的情形，所以发散。

$p<0$ 时 $\{n^{-p}\}$ 无界，通项不趋于 $0$ ，级数发散。

$p\ge 0$ 时 $\frac{1}{n^p}$ 递减而且非负，用凝聚判别。

$$
\sum_{k=0}^{\infty}2^k\cdot\frac{1}{(2^k)^p}=\sum_{k=0}^{\infty}\left(2^{1-p}\right)^k.
$$

这是公比 $x=2^{1-p}$ 的几何级数。 $2^{1-p}<1$ 正好是 $p>1$ ，几何级数收敛，原级数收敛。 $2^{1-p}\ge 1$ 正好是 $p\le 1$ ，几何级数发散，原级数发散。 $p=1$ 时公比是 $1$ ，凝聚之后就是 $1+1+1+\cdots$ 。

```lean
theorem p_series {p : ℝ} : Summable (fun n : ℕ => 1 / (n : ℝ) ^ p) ↔ 1 < p :=
  Real.summable_one_div_nat_rpow

theorem squares_converge : Summable (fun n : ℕ => 1 / (n : ℝ) ^ (2 : ℝ)) :=
  p_series.mpr (by norm_num)

theorem harmonic_diverges : ¬Summable (fun n : ℕ => 1 / (n : ℝ)) :=
  Real.not_summable_one_div_natCast
```

`Real.summable_one_div_nat_rpow` 就是这条 iff，证明走的也是凝聚判别加几何级数。 $p=2>1$ ，平方倒数可和。 `not_summable_one_div_natCast` 是调和级数发散。下标从 $0$ 起时， $n=0$ 的除法按实数约定写成 $0$ ，不改变敛散；书上的和从 $n=1$ 写起。指数这里要标成实数， $2$ 才是实幂，而不是自然数幂。

公分母 $12$ 上，前四项是 $12+6+4+3=25$ ，而 $2\cdot 12=24$ 。 $24<25$ ，所以这四项已经大于 $2$ 。

```agda
harmonic-parts : 12 + 6 + 4 + 3 ≡ 25
harmonic-parts = refl

two-as-twelfths : 2 * 12 ≡ 24
two-as-twelfths = refl

twentyfour-lt : 24 < 25
twentyfour-lt = n<1+n 24
```

Julia、Python、Prolog 核对同一组有理数：部分和等于闭式 $\frac{7}{4}$ ， $\frac{\frac{2}{3}}{1-\frac{2}{3}}=2$ ，把 $\frac{1}{3}$ 换成 $\frac{1}{4}$ 得到 $2$ 而调和前四项更大，常数 $1$ 不小于 $\frac{1}{2}$ 。Prolog 用 `rdiv` 。

## 19.11 七通道对照

| 主题 | Lean | Isabelle | Coq | Agda | 计算三通道 |
|------|------|----------|-----|------|------------|
| 柯西准则 | — | `summable_Cauchy` | — | — | — |
| 通项趋于 $0$ | $\|1\|\not<\frac{1}{2}$ | `summable_LIMSEQ_zero` | $1>\frac{1}{2}$ | — | 常数 $1$ |
| 几何部分和 | $\frac{7}{4}$ | `geometric_sum` | 同一等式 | $4+2+1=7<8$ | $\frac{7}{4}$ |
| $\sum\left(\frac{1}{2}\right)^n=2$ | `tsum_geometric_of_abs_lt_one` | `suminf_geometric` | — | — | — |
| $\sum_{n\ge 1}\left(\frac{2}{3}\right)^n=2$ | 全和减去 $1$ | 同一做法 | $\frac{\frac{2}{3}}{1-\frac{2}{3}}=2$ | $6-2=4$ ， $12-4=8$ | 等于 $2$ |
| 比较判别 | `Summable.of_norm` | — | — | — | — |
| 调和前四项 | 大于 $2$ | 同一不等式 | 同一不等式 | $25>24$ | 大于分组后的 $2$ |
| p 级数 | `summable_one_div_nat_rpow` | — | — | — | — |

## 19.12 本章验证清单

- `examples/lean/Realanalysis/Ch19Series.lean`：几何和、 $\left(-\frac{1}{2}\right)^n$ 的比较、p 级数的 iff、调和级数发散、前四项大于 $2$ 。
- `examples/isabelle/RA19/SeriesBasics.thy`：柯西准则、通项趋于 $0$ 、几何部分和与无穷和、矩形那一条从 $n=1$ 起的和。
- `examples/coq/Ch19_series.v`： $\frac{7}{4}$ 、矩形和 $2$ 、调和前四项、常数 $1$ 。
- `examples/agda/Ch19_series.agda`： $7<8$ ， $25>24$ ，矩形剩下的 $4$ 和 $8$ 。
- `examples/julia/19_series.jl`、`examples/python/19_series.py`、`examples/prolog/19_series.pl`：同一组有理数。

复验：`pwsh -NoProfile -Command '& ./build.ps1 -Chapter 19'`。

## 19.13 接下来

比较判别通常拿几何级数或 p 级数当标尺，凝聚判别则把递减的正项级数收成一条几何级数。根值判别和比值判别也是级数的判别法，这一章只点出名字，没有展开。数 $e$ 的定义、 $\pi$ 的复分析定义、泰勒级数，都还在这套语言外面。

下一章不再加新的判别法，而是把从实数公理到级数的这条主线收回来看一遍。

上一章：[18 特殊序列](18-special-sequences.md) · 下一章：[20 总结](20-summary.md) · [返回目录](../README.md)
