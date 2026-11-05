# 第 22 章 比值判别法与根值判别法（补充章）

> 原书第 19 章在级数末尾点了两条判别法的名字，没有证明。这一章把它们讲透。
> 两条判别法本质上都是同一件事：把级数和一条几何级数比较。
> 比值看相邻两项之比，根值看第 $n$ 项开 $n$ 次方，两者都在问同一件事——
> 通项是否像 $r^n$ 那样快地衰减。

## 22.1 为什么需要这两条判别法

第 19 章的比较判别说：若 $0\le a_n\le b_n$ 且 $\sum b_n$ 收敛，则 $\sum a_n$ 收敛。但它要求你**已经有一条**可和的 $b_n$ 当标尺。几何级数 $\sum r^n$ （ $|r|<1$ ）和 p 级数 $\sum 1/n^p$ （ $p>1$ ）是最常用的两条标尺。

比值判别和根值判别做的事是：**不用你提供标尺**，只看通项自身的衰减速度，就告诉你它是否被某条几何级数控制。

## 22.2 定理 22.1：比值判别（收敛方向）

设 $\{a_n\}$ 是正项数列。若存在 $0<r<1$ 和 $N$ ，使 $n\ge N$ 时

$$\frac{a_{n+1}}{a_n}\le r,$$

则 $\sum a_n$ 收敛。

证明只有一步：归纳得到 $a_n\le a_N\cdot r^{n-N}$ ，右边是几何级数的常数倍，比较判别收尾。

更常用的极限形式：若

$$\lim_{n\to\infty}\frac{a_{n+1}}{a_n}=l<1,$$

则取 $r=(l+1)/2\in(l,1)$ ，极限定义给出 $N$ 使 $n\ge N$ 时 $a_{n+1}/a_n<r$ ，落回上面的情形。

mathlib 把极限形式写成：

```lean
theorem summable_of_ratio_test_tendsto_lt_one
    {f : ℕ → ℝ} {l : ℝ} (hl : l < 1)
    (hnz : ∀ᶠ n in atTop, f n ≠ 0)
    (h : Tendsto (fun n => ‖f (n + 1)‖ / ‖f n‖) atTop (𝓝 l)) : Summable f
```

`∀ᶠ n in atTop` 是"最终成立"，即存在 $N$ 使 $n\ge N$ 时都成立。`hnz` 要求项最终非零，否则比值没有意义。

Isabelle 的对应定理用不等式形式（不需要极限存在）：

```isabelle
lemma summable_ratio_test:
  assumes "c < 1" "\<And>n. n \<ge> N \<Longrightarrow> norm (f (Suc n)) \<le> c * norm (f n)"
  shows "summable f"
```

证明走的是归纳加比较判别，和上面的思路完全一致。

## 22.3 例：$\sum 2^n/n!$ 收敛

取 $a_n=2^n/n!$ 。相邻项之比是

$$\frac{a_{n+1}}{a_n}=\frac{2^{n+1}/(n+1)!}{2^n/n!}=\frac{2}{n+1}.$$

当 $n\to\infty$ 时这比值趋于 $0<1$ ，所以级数收敛。事实上它的和是 $e^2$ ，第 23 章会把这个和算出来。

在 $n=2$ 处可以直接算出比值：

$$\frac{2^3/3!}{2^2/2!}=\frac{8/6}{4/2}=\frac{4/3}{2}=\frac{2}{3}.$$

Lean 通道验证了这一步：

```lean
theorem factorial_ratio_at_two :
    ((2 : ℝ)^3 / 3! / ((2 : ℝ)^2 / 2!)) = 2 / 3 := by norm_num
```

完整的可和性证明：

```lean
theorem factorial_series_summable :
    Summable (fun n : ℕ => (2 : ℝ) ^ n / n !) := by
  apply summable_of_ratio_test_tendsto_lt_one (by norm_num : (0 : ℝ) < 1)
  · exact .of_forall fun n => ne_of_gt <|
      div_pos (pow_pos (by norm_num) n) (Nat.cast_pos.mpr (Nat.factorial_pos n))
  · have hlim : Tendsto (fun n : ℕ => 2 * (1 / ((n : ℝ) + 1))) atTop (𝓝 0) := by
      simpa using (tendsto_one_div_add_atTop_nhds_zero_nat (𝕜 := ℝ)).const_mul 2
    apply hlim.congr'
    filter_upwards with n
    have hpos : ∀ k : ℕ, (0 : ℝ) < (2 : ℝ) ^ k / k ! := fun k =>
      div_pos (pow_pos (by norm_num) k) (Nat.cast_pos.mpr (Nat.factorial_pos k))
    rw [Real.norm_eq_abs, abs_of_pos (hpos (n + 1)),
      Real.norm_eq_abs, abs_of_pos (hpos n)]
    simp only [Nat.factorial_succ, Nat.cast_mul, Nat.cast_add, Nat.cast_one, pow_succ]
    field_simp
```

`tendsto_one_div_add_atTop_nhds_zero_nat` 是 $1/(n+1)\to 0$ ；`.const_mul 2` 得到 $2/(n+1)\to 0$ 。`congr'` 把目标函数换成 $2/(n+1)$ ，两者在每个 $n$ 处相等——这就是比值恰好等于 $2/(n+1)$ 的代数事实。

Isabelle 通道用不等式形式。这里取 $c=3/4$ 、 $N=2$ ——不能取 $c=1/2$ ，因为 $n=0$ 时 $a_1/a_0=2$ 、 $n=1$ 时 $a_2/a_1=1$ ，比值判别法本来就只要求**最终**满足不等式，前几项可以随便。

```isabelle
lemma ratio_series_summable: "summable (\<lambda>n. (2::real) ^ n / fact n)"
proof (rule summable_ratio_test[where c = "3 / 4" and N = 2])
  show "(3::real) / 4 < 1" by simp
  fix n :: nat
  assume n: "2 \<le> n"
  have pos: "0 < (2::real) ^ n / fact n" by (simp add: fact_gt_zero)
  have "norm ((2::real) ^ Suc n / fact (Suc n)) = 2 ^ Suc n / fact (Suc n)"
    by (simp add: fact_gt_zero)
  also have "... = (2 ^ n / fact n) * (2 / (n + 1))" by (simp add: fact_Suc field_simps)
  also have "... \<le> (2 ^ n / fact n) * (3 / 4)"
  proof -
    have h: "2 / (real n + 1) \<le> (3::real) / 4"
      using n by (simp add: pos_le_divide_eq pos_divide_le_eq)
    from mult_left_mono[OF h, of "2 ^ n / fact n"] pos show ?thesis by simp
  qed
  also have "... = 3 / 4 * norm ((2::real) ^ n / fact n)" using pos by simp
  finally show "norm ((2::real) ^ Suc n / fact (Suc n)) \<le> 3 / 4 * norm (2 ^ n / fact n)" .
qed
```

关键一步是 $2/(n+1)\le 3/4$ 在 $n\ge 2$ 时成立：此时 $n+1\ge 3$ ，所以 $2/(n+1)\le 2/3<3/4$ 。Isabelle 的 `pos_le_divide_eq` 把分式不等式化成整式不等式 $8\le 3(n+1)$ ， `simp` 配合 $n\ge 2$ 即可关掉。

## 22.4 定理 22.2：比值判别（发散方向）

若 $\lim a_{n+1}/a_n=l>1$ ，则 $\sum a_n$ 发散。

证明是收敛方向的镜像：取 $r\in(1,l)$ ，最终 $a_{n+1}\ge r\cdot a_n$ ，归纳得 $a_n\ge a_N\cdot r^{n-N}$ ，而 $r>1$ 时右边趋于 $+\infty$ ，通项不可能趋于 $0$ ，由第 19 章的必要条件知级数发散。

例：$a_n=2^n$ ，比值恒为 $2>1$ ，级数发散。

```lean
theorem geometric_two_diverges :
    ¬Summable (fun n : ℕ => (2 : ℝ) ^ n) := by
  refine not_summable_of_ratio_test_tendsto_gt_one (by norm_num : (1 : ℝ) < 2) ?_
  refine tendsto_const_nhds.congr' ?_
  filter_upwards with n
  have hpos : ∀ k : ℕ, (0 : ℝ) < (2 : ℝ) ^ k := fun k => pow_pos (by norm_num) k
  rw [Real.norm_eq_abs, abs_of_pos (hpos (n + 1)),
    Real.norm_eq_abs, abs_of_pos (hpos n)]
  field_simp [pow_succ]
  ring
```

`not_summable_of_ratio_test_tendsto_gt_one` 是发散方向的库定理；比值恒为 $2$ ，所以极限是常数列的极限，`tendsto_const_nhds` 直接给出。

Isabelle 用几何级数的 iff 更简洁：

```isabelle
lemma geometric_two_diverges: "\<not>summable (\<lambda>n. (2::real) ^ n)"
proof -
  have "\<not>norm (2::real) < 1" by simp
  then show ?thesis using summable_geometric_iff[where c="(2::real)"] by blast
qed
```

`summable_geometric_iff` 说 $\sum c^n$ 可和当且仅当 $|c|<1$ 。 $|2|=2\not<1$ ，所以不可和。

## 22.5 定理 22.3：根值判别

设 $\{a_n\}$ 是数列。若存在 $0\le r<1$ 和 $N$ ，使 $n\ge N$ 时

$$\sqrt[n]{|a_n|}\le r,$$

则 $\sum a_n$ 收敛。

证明同样只有一步：$\sqrt[n]{|a_n|}\le r$ 等价于 $|a_n|\le r^n$ ，右边是几何级数，比较判别收尾。

极限形式：若 $\limsup\sqrt[n]{|a_n|}=l<1$ ，则取 $r\in(l,1)$ ，上极限的定义给出最终 $\sqrt[n]{|a_n|}<r$ 。

发散方向：若 $\limsup\sqrt[n]{|a_n|}>1$ ，则有无穷多个 $n$ 使 $\sqrt[n]{|a_n|}>1$ ，即 $|a_n|>1$ ，通项不趋于 $0$ ，级数发散。

mathlib 没有单独的"根值判别"定理，但比较判别加几何级数就是全部内容：

```lean
theorem summable_of_root_eventually_le {f : ℕ → ℝ} {r : ℝ}
    (hr0 : 0 ≤ r) (hr1 : r < 1)
    (h : ∀ᶠ n in atTop, ‖f n‖ ≤ r ^ n) : Summable f :=
  Summable.of_norm_bounded_eventually_nat (summable_geometric_of_lt_one hr0 hr1) h
```

`Summable.of_norm_bounded_eventually_nat` 是最终版本的比较判别；`summable_geometric_of_lt_one` 是几何级数可和。两行就完成了根值判别的核心。

Isabelle 有专门的根值判别（limsup 形式）：

```isabelle
theorem root_test_convergence':
  fixes f :: "nat \<Rightarrow> 'a :: banach"
  defines "l \<equiv> limsup (\<lambda>n. ereal (root n (norm (f n))))"
  assumes l: "l < 1"
  shows "summable f"
```

以及极限形式：

```isabelle
lemma root_test_convergence:
  fixes f :: "nat \<Rightarrow> 'a::banach"
  assumes "(\<lambda>n. root n (norm (f n))) \<longlonglongrightarrow> x" "x < 1"
  shows "summable f"
```

## 22.6 例：$\sum (n/(2n+1))^n$ 收敛

取 $a_n=(n/(2n+1))^n$ 。开 $n$ 次方就是底数 $n/(2n+1)$ 。当 $n\to\infty$ 时底数趋于 $1/2<1$ ，所以根值判别给出收敛。

但这里不需要极限：底数对所有 $n$ 都不超过 $3/5$ ，因为

$$\frac{n}{2n+1}\le\frac{3}{5}\iff 5n\le 3(2n+1)\iff 0\le n+3,$$

最后一式显然成立。于是 $a_n\le(3/5)^n$ ，直接落入几何界。

Lean 通道的证明：

```lean
theorem root_series_summable :
    Summable (fun n : ℕ => ((n : ℝ) / (2 * n + 1)) ^ n) := by
  refine summable_of_root_eventually_le (r := 3 / 5) (by norm_num) (by norm_num) ?_
  filter_upwards with n
  have hb0 : (0 : ℝ) ≤ (n : ℝ) / (2 * n + 1) := by positivity
  have hdiff : 3 / 5 - (n : ℝ) / (2 * n + 1) =
      ((n : ℝ) + 3) / (5 * (2 * n + 1)) := by
    field_simp
    ring
  have hnonneg : 0 ≤ 3 / 5 - (n : ℝ) / (2 * n + 1) := by
    rw [hdiff]
    positivity
  have hle : (n : ℝ) / (2 * n + 1) ≤ 3 / 5 := by
    calc (n : ℝ) / (2 * n + 1)
        = 3 / 5 - (3 / 5 - (n : ℝ) / (2 * n + 1)) := by ring
      _ ≤ 3 / 5 := sub_le_self _ hnonneg
  have hpow : ((n : ℝ) / (2 * n + 1)) ^ n ≤ (3 / 5 : ℝ) ^ n := by gcongr
  have hg0 : (0 : ℝ) ≤ ((n : ℝ) / (2 * n + 1)) ^ n := by positivity
  rwa [Real.norm_eq_abs, abs_of_nonneg hg0]
```

核心代数是 $3/5-n/(2n+1)=(n+3)/(5(2n+1))$ ，右边显然非负，所以底数不超过 $3/5$ 。`gcongr` 处理幂的单调性：底数非负且 $a\le b$ 时 $a^n\le b^n$ 。

在 $n=2$ 处可以直接看到：$(2/5)^2=4/25\le 9/25=(3/5)^2$ 。

Isabelle 用比较判别加几何级数：

```isabelle
lemma root_series_summable: "summable (\<lambda>n. (real n / (2 * n + 1)) ^ n)"
proof (rule summable_comparison_test')
  show "summable (\<lambda>n. (3 / 5 :: real) ^ n)" by (rule summable_geometric) simp
  fix n :: nat
  assume "n \<ge> 0"
  have "norm ((real n / (2 * n + 1)) ^ n) = (real n / (2 * n + 1)) ^ n"
    by (simp add: power_abs)
  then show "norm ((real n / (2 * n + 1)) ^ n) \<le> (3 / 5 :: real) ^ n"
    using root_base_bound by simp
qed
```

其中 `root_base_bound` 就是底数界的幂版本：

```isabelle
lemma root_base_bound:
  "(real n / (2 * n + 1)) ^ n \<le> (3 / 5 :: real) ^ n"
proof (rule power_mono)
  show "real n / (2 * n + 1) \<le> (3 / 5 :: real)"
  proof -
    have "real n / (2 * n + 1) \<le> (3 / 5 :: real) \<longleftrightarrow> real n * 5 \<le> 3 * (2 * n + 1)"
      by (simp add: pos_divide_le_eq pos_le_divide_eq field_simps)
    then show ?thesis by simp
  qed
  show "0 \<le> real n / (2 * n + 1)" by simp
qed
```

`power_mono` 是幂的单调性：$a\le b$ 且 $a\ge 0$ 时 $a^n\le b^n$ 。中间那行 iff 把分式不等式化成 $5n\le 3(2n+1)$ ，展开即 $0\le n+3$ 。

## 22.7 失效情形：比值极限等于 $1$

两条判别法在 $l=1$ 时都**失效**。这不是定理不够强，而是 $l=1$ 本身就包含收敛和发散两种可能。

调和级数 $\sum 1/n$ 发散（第 19 章），但相邻项之比

$$\frac{1/(n+1)}{1/n}=\frac{n}{n+1}\to 1.$$

平方倒数级数 $\sum 1/n^2$ 收敛（p 级数，$p=2>1$ ），但相邻项之比

$$\frac{1/(n+1)^2}{1/n^2}=\frac{n^2}{(n+1)^2}\to 1.$$

两者的比值极限都是 $1$ ，命运却不同。$l=1$ 时判别法无话可说，必须换工具（比如积分判别或柯西凝聚判别）。

Lean 通道把这两条失效情形都写成了定理：

```lean
theorem harmonic_ratio_tendsto_one :
    Tendsto (fun n : ℕ => (n + 1 : ℝ) / (n + 2)) atTop (𝓝 1) := by
  have h0 := (tendsto_one_div_add_atTop_nhds_zero_nat (𝕜 := ℝ)).comp
      (tendsto_add_atTop_nat 1)
  have h1 : Tendsto (fun n : ℕ => 1 - 1 / ((n : ℝ) + 2)) atTop (𝓝 1) := by
    have h2 := h0.const_sub 1
    convert h2 using 1
    funext _
    simp only [Function.comp_def]
    simp
  have heq : (fun n : ℕ => (n + 1 : ℝ) / (n + 2)) =
      fun (n : ℕ) => 1 - 1 / ((n : ℝ) + 2) := by
    funext n
    field_simp
    ring
  rw [heq]
  exact h1
```

这里用平移下标 $1/(n+1)$ 代替 $1/n$ 来避免 $n=0$ 的除零；可和性不受影响，因为平移只改变有限项。

```lean
theorem shifted_harmonic_diverges :
    ¬Summable (fun n : ℕ => 1 / (↑(n + 1) : ℝ)) :=
  (summable_nat_add_iff (G := ℝ) 1).not.mpr Real.not_summable_one_div_natCast

theorem squares_ratio_tendsto_one :
    Tendsto (fun n : ℕ => ((n + 1 : ℝ) / (n + 2)) ^ 2) atTop (𝓝 1) := by
  have h := (continuous_pow 2).continuousAt.tendsto.comp harmonic_ratio_tendsto_one
  convert h using 1
  funext n
  rfl
  simp

theorem shifted_squares_summable :
    Summable (fun n : ℕ => 1 / (↑(n + 1) : ℝ) ^ (2 : ℝ)) :=
  (summable_nat_add_iff (G := ℝ) 1).mpr <|
    Real.summable_one_div_nat_rpow.mpr (by norm_num : (1 : ℝ) < 2)
```

`summable_nat_add_iff` 说 $f(n+k)$ 可和当且仅当 $f(n)$ 可和；`Real.summable_one_div_nat_rpow` 是 p 级数的 iff。平方倒数级数收敛，调和级数发散，两者的比值极限都是 $1$ ——这就是失效情形的完整陈述。

## 22.8 七通道对照

| 主题 | Lean | Isabelle | Coq | Agda | 计算三通道 |
|------|------|----------|-----|------|------------|
| 比值判别（收敛） | `summable_of_ratio_test_tendsto_lt_one` | `summable_ratio_test` | — | — | — |
| 比值判别（发散） | `not_summable_of_ratio_test_tendsto_gt_one` | `summable_geometric_iff` | — | — | — |
| $2^n/n!$ 可和 | `factorial_series_summable` | `ratio_series_summable` | — | — | — |
| $2^n$ 不可和 | `geometric_two_diverges` | `geometric_two_diverges` | — | — | — |
| 根值判别 | `summable_of_root_eventually_le` | `root_test_convergence` | — | — | — |
| $(n/(2n+1))^n$ 可和 | `root_series_summable` | `root_series_summable` | — | — | — |
| 失效：调和 | `harmonic_ratio_tendsto_one` + `shifted_harmonic_diverges` | 同 | — | — | — |
| 失效：平方倒数 | `squares_ratio_tendsto_one` + `shifted_squares_summable` | 同 | — | — | — |

## 22.9 本章验证清单

- `examples/lean/Realanalysis/Ch22RatioRoot.lean`：根值判别、比值判别（收敛与发散）、$2^n/n!$ 可和、$2^n$ 不可和、$(n/(2n+1))^n$ 可和、调和与平方倒数的失效情形。
- `examples/isabelle/RA22/RatioRoot.thy`：同上，用 Isabelle 的库定理。
- `examples/coq/Ch22_ratio_root.v`：$2/3$ 、 $(2/5)^2\le(3/5)^2$ 、调和比值。
- `examples/agda/Ch22_ratio_root.agda`：交叉相乘的自然数形式。
- `examples/julia/22_ratio_root.jl`、`examples/python/22_ratio_root.py`、`examples/prolog/22_ratio_root.pl`：同一组有理数验证。

复验：`pwsh -NoProfile -Command '& ./build.ps1 -Chapter 22'`。

## 22.10 接下来

比值判别和根值判别都归结为几何级数比较。第 23 章用比值判别证明 $\sum x^n/n!$ 对任意 $x$ 收敛，从而定义指数函数 $e^x$ ，并证明 $e$ 是无理数。

上一章：[21 收官](21-wrapup.md) · 下一章：[23 数 $e$ 与指数函数](23-exp.md) · [返回目录](../README.md)
