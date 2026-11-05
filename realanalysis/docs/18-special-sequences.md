# 第 18 章 特殊序列

> 后面反复用到的几条序列，都可以先夹住，再送进已经知道的极限。
> $p>0$ 时 $\frac{1}{n^p}\to 0$ ， $p^{1/n}\to 1$ ， $n^{1/n}\to 1$ 。
> $p>0$ 时 $\frac{n^\alpha}{(1+p)^n}\to 0$ 。 $|x|<1$ 时 $x^n\to 0$ 。

## 18.1 定理 18.1：夹逼

$\{a_n\}$ 、 $\{s_n\}$ 、 $\{b_n\}$ 是实序列，并且对每个 $n$ ，

$$
a_n\le s_n\le b_n.
$$

若 $a_n\to s$ 且 $b_n\to s$ ，则 $s_n\to s$ 。

两条边界挤向同一个点，中间那条没有别的地方可去。证明只是把这个意思写成 $\varepsilon$ - $N$ 。

任给 $\varepsilon>0$ 。由 $a_n\to s$ 得到 $N_1$ ，使 $n\ge N_1$ 时 $|a_n-s|<\varepsilon$ 。由 $b_n\to s$ 得到 $N_2$ ，使 $n\ge N_2$ 时 $|b_n-s|<\varepsilon$ 。取 $N=\max\{N_1,N_2\}$ 。当 $n\ge N$ 时，

$$
s_n-s\le b_n-s\le |b_n-s|<\varepsilon,
$$

$$
-(s_n-s)\le -(a_n-s)\le |a_n-s|<\varepsilon.
$$

于是 $|s_n-s|=\max\{s_n-s,\ -(s_n-s)\}<\varepsilon$ 。

把 $\le$ 换成 $<$ 也一样，因为最后一步本来就要严格小于 $\varepsilon$ 。

平方项是一条现成的夹逼。 $0\le \frac{1}{(n+1)^2}\le \frac{1}{n+1}$ ，两边都趋于 $0$ ，所以中间也趋于 $0$ 。右边用的是已经证过的 $\frac{1}{n+1}\to 0$ 。左边是常数 $0$ 。中间不超过右边，是因为 $\frac{1}{n+1}$ 落在 $0$ 和 $1$ 之间，一个不超过 $1$ 的非负数再乘上自己不会变大。

```lean
theorem squeezed_square :
    Tendsto (fun n : ℕ => ((1 : ℝ) / ((n : ℝ) + 1)) ^ 2) atTop (nhds 0) :=
  tendsto_of_tendsto_of_tendsto_of_le_of_le
    (tendsto_const_nhds : Tendsto (fun _ : ℕ => (0 : ℝ)) atTop (nhds 0))
    tendsto_one_div_add_atTop_nhds_zero_nat
    (fun n => by positivity)
    (fun n => by
      have hx : 0 ≤ (1 : ℝ) / ((n : ℝ) + 1) := by positivity
      have h1 : (1 : ℝ) / ((n : ℝ) + 1) ≤ 1 := by
        rw [div_le_one (by positivity : (0 : ℝ) < (n : ℝ) + 1)]
        linarith
      simpa [pow_two] using mul_le_of_le_one_right hx h1)
```

`tendsto_of_tendsto_of_tendsto_of_le_of_le` 就是夹逼：下界和上界趋于同一个点，而且不等式对每个下标都成立，中间项就趋于这个点。 `div_le_one` 把 $\frac{1}{n+1}\le 1$ 换成 $1\le n+1$ 。 `mul_le_of_le_one_right` 得到 $\frac{1}{n+1}\cdot\frac{1}{n+1}\le\frac{1}{n+1}$ ， `pow_two` 把它写回平方。

Isabelle 把调和序列的一半夹在 $0$ 和 $\frac{1}{n+1}$ 之间。一半不超过全体，两边都趋于 $0$ 。

```isabelle
lemma squeezed_half:
  "(\<lambda>n. inverse (real (Suc n)) / 2) \<longlonglongrightarrow> (0::real)"
proof (rule tendsto_sandwich
    [where f="\<lambda>_::nat. 0::real" and h="\<lambda>n. inverse (real (Suc n))"
      and c="0::real" and net=sequentially])
  show "eventually (\<lambda>n. (0::real) \<le> inverse (real (Suc n)) / 2) sequentially"
    by (rule always_eventually) simp
  show "eventually (\<lambda>n. inverse (real (Suc n)) / 2 \<le> inverse (real (Suc n))) sequentially"
    by (rule always_eventually) simp
  show "(\<lambda>_::nat. (0::real)) \<longlonglongrightarrow> 0"
    by (rule tendsto_const)
  show "(\<lambda>n. inverse (real (Suc n))) \<longlonglongrightarrow> 0"
    by (rule LIMSEQ_inverse_real_of_nat)
qed
```

`tendsto_sandwich` 的两个不等式只要求最终成立。这里它们对每个 $n$ 都成立，所以用 `always_eventually` 。上界是 `LIMSEQ_inverse_real_of_nat` ，也就是 $\frac{1}{n+1}\to 0$ 。下界是常数 $0$ 。

数值上， $\frac{1}{11^2}=\frac{1}{121}$ 已经小于 $\frac{1}{10}$ ，并且仍严格小于 $\frac{1}{11}$ 。平方项确实夹在 $0$ 和对应的调和项之间。

```coq
Lemma squeeze_slot : 0 < 1 / 121 /\ 1 / 121 < 1 / 11.
Proof.
  lra.
Qed.
```

## 18.2 定理 18.2： $\frac{1}{n^p}$

若 $p>0$ ，则 $\frac{1}{n^p}\to 0$ 。若 $p<0$ ，则 $n^p\to 0$ 。

先看 $p>0$ 。任给 $\varepsilon>0$ ，要找 $N$ ，使 $n\ge N$ 时 $\left|\frac{1}{n^p}\right|<\varepsilon$ 。正项上这就是 $n^p>\frac{1}{\varepsilon}$ ，也就是

$$
n>\left(\frac{1}{\varepsilon}\right)^{1/p}.
$$

取 $N=\left\lfloor\left(\frac{1}{\varepsilon}\right)^{1/p}\right\rfloor+1$ 。这样的实数存在，是因为正实数有任意正次方根。于是 $n\ge N$ 时 $n$ 严格大于那个方根， $n^p>\frac{1}{\varepsilon}$ ，距离就小于 $\varepsilon$ 。

再看 $p<0$ 。令 $q=-p>0$ 。则 $n^p=\frac{1}{n^q}$ ，上一款已经给出 $\frac{1}{n^q}\to 0$ 。

$p=2$ 不必从 $\varepsilon$ 重做。 $\frac{1}{n+1}\to 0$ ，连续的平方把极限送到 $0^2=0$ 。

```isabelle
lemma inv_square:
  "(\<lambda>n. inverse (real (Suc n)) ^ 2) \<longlonglongrightarrow> (0::real)"
proof -
  have "(\<lambda>n. inverse (real (Suc n)) ^ 2) \<longlonglongrightarrow> (0::real) ^ 2"
    by (rule tendsto_power[OF LIMSEQ_inverse_real_of_nat])
  then show ?thesis by simp
qed
```

`tendsto_power` 把整条序列乘方。极限 $0$ 的平方还是 $0$ ， `simp` 把 $0^2$ 收成 $0$ 。

$n=11$ 时 $\left|\frac{1}{121}\right|<\frac{1}{10}$ 。

```lean
theorem eleven_square : |(1 : ℝ) / 121| < 1 / 10 := by
  norm_num
```

## 18.3 定理 18.3： $p^{1/n}$

若 $p>0$ ，则 $p^{1/n}\to 1$ 。分三种情形。

**情形 $p>1$ 。** 令 $x_n=p^{1/n}-1$ 。因为 $p^{1/n}>1$ ，所以 $x_n>0$ 。二项式定理给出

$$
p=(1+x_n)^n=\sum_{k=0}^{n}\binom{n}{k}x_n^k.
$$

$x_n>0$ 时， $k\ge 2$ 的项都是正的。丢掉它们，剩下

$$
p>1+nx_n,
$$

所以 $0<x_n<\frac{p-1}{n}$ 。右边是常数乘上 $\frac{1}{n}$ ，趋于 $0$ 。夹逼得到 $x_n\to 0$ ，于是

$$
p^{1/n}=1+x_n\to 1+0=1.
$$

$n=2$ 、 $x=\frac{1}{2}$ 时， $(1+x)^n=\left(\frac{3}{2}\right)^2=\frac{9}{4}$ ，而 $1+nx=2$ 。 $\frac{9}{4}>2$ ，丢掉的那个平方项确实是正的。

```lean
theorem binomial_step : (1 : ℝ) + 2 * (1 / 2) < (3 / 2) ^ 2 := by
  norm_num
```

Isabelle 先把两边算成 $2$ 和 $\frac{9}{4}$ 。

```isabelle
lemma binomial_step: "(1::real) + 2 * (1 / 2) < (3 / 2) ^ 2"
proof -
  have left: "(1::real) + 2 * (1 / 2) = 2" by simp
  have "(3 / 2 :: real) ^ 2 = (3 / 2) * (3 / 2)"
    by (rule power2_eq_square)
  also have "... = 9 / 4" by simp
  finally have right: "(3 / 2 :: real) ^ 2 = 9 / 4" .
  show ?thesis by (simp add: left right)
qed
```

`power2_eq_square` 把平方写成两个因子相乘，乘出来是 $\frac{9}{4}$ 。

自然数上同一件事是 $3\cdot 3=9$ 并且 $8<9$ 。 $\frac{9}{4}$ 和 $\frac{8}{4}$ 就是上面那一对。

```agda
three-sq : 3 * 3 ≡ 9
three-sq = refl

eight-lt-nine : 8 < 9
eight-lt-nine = n<1+n 8
```

**情形 $p=1$ 。** $1^{1/n}=1$ ，常数序列趋于 $1$ 。

**情形 $0<p<1$ 。** 这时 $x_n=p^{1/n}-1<0$ 。不能照上一款把二项式从第三项起全部丢掉： $x_n<0$ 时偶次幂是正的，奇次幂才是负的，后面各项并不同号。 $p=\frac{1}{2}$ 、 $n=2$ 可以看出来。 $\sqrt{\frac{1}{2}}\approx 0.707$ ， $x_2\approx -0.293$ ，而

$$
\left(1+x_2\right)^2=\frac{1}{2}>1+2x_2.
$$

不等式方向和 $p>1$ 时相反，所以那一刀切不下来。

换成倒数。 $0<p<1$ 时 $\frac{1}{p}>1$ 。上一款给出 $\left(\frac{1}{p}\right)^{1/n}\to 1$ 。而

$$
p^{1/n}=\frac{1}{\left(\frac{1}{p}\right)^{1/n}}\to\frac{1}{1}=1.
$$

常数的 $n$ 次方根在 Isabelle 里是一条现成的极限， $c>0$ 即可，不必再分 $c>1$ 和 $c<1$ 。

```isabelle
lemma root_two: "(\<lambda>n. root n (2::real)) \<longlonglongrightarrow> 1"
  by (rule LIMSEQ_root_const) simp
```

`root n 2` 是 $2^{1/n}$ 。 `LIMSEQ_root_const` 要求底数为正， `simp` 给出 $0<2$ 。

## 18.4 定理 18.4： $n^{1/n}$

$$
\lim_{n\to\infty}n^{1/n}=1.
$$

这里开方的数就是下标自己，不是一个固定的 $p$ 。前几项大约是

$$
1.00,\ 1.41,\ 1.44,\ 1.41,\ 1.38,\ 1.35,\ \ldots
$$

它先升后降，并不单调，所以不能靠单调有界。

令 $x_n=n^{1/n}-1$ 。 $n^{1/n}\ge 1$ ，所以 $x_n\ge 0$ 。二项式展开后， $k=2$ 那一项已经够用：

$$
n=(1+x_n)^n\ge\binom{n}{2}x_n^2=\frac{n(n-1)}{2}x_n^2.
$$

$n\ge 2$ 时可以除过去，

$$
0\le x_n\le\sqrt{\frac{2}{n-1}}=\sqrt{2}\cdot\frac{1}{\sqrt{n-1}}.
$$

定理 18.2 里取 $p=\frac{1}{2}$ ，得到 $\frac{1}{\sqrt{m}}\to 0$ 。把 $m$ 换成 $n-1$ 仍然趋于 $0$ ，再乘上常数 $\sqrt{2}$ 还是 $0$ 。夹逼给出 $x_n\to 0$ ，所以 $n^{1/n}=1+x_n\to 1$ 。 $n=1$ 只有一项，从哪一项开始夹都不影响极限。

Lean 直接对实变量的 $x^{1/x}$ 取极限，再沿 $n\to\infty$ 复合回来。

```lean
theorem root_n :
    Tendsto (fun n : ℕ => (n : ℝ) ^ ((1 : ℝ) / (n : ℝ))) atTop (nhds 1) :=
  tendsto_rpow_div.comp (tendsto_natCast_atTop_atTop (R := ℝ))
```

`tendsto_rpow_div` 是 $x^{1/x}\to 1$ ，变量跑过正无穷。 `tendsto_natCast_atTop_atTop` 是 $n\to+\infty$ 。复合起来就是 $n^{1/n}\to 1$ 。下标从 $0$ 起时 $n=0$ 的那一项不参与 $n\to\infty$ 的尾部。

Isabelle 的同一定理写在自然数的 $n$ 次方根上。

```isabelle
lemma root_n: "(\<lambda>n. root n n) \<longlonglongrightarrow> 1"
  by (rule LIMSEQ_root)
```

`root n n` 就是 $n^{1/n}$ 。

## 18.5 定理 18.5： $\frac{n^\alpha}{(1+p)^n}$

若 $p>0$ 且 $\alpha$ 是实数，则

$$
\frac{n^\alpha}{(1+p)^n}\to 0.
$$

指数比多项式快。证明仍然靠二项式，这次留下的是 $k$ 次那一项。

$$
\binom{n}{k}=\frac{n(n-1)\cdots(n-k+1)}{k!}\ge\frac{(n-k+1)^k}{k!}.
$$

固定 $k$ ，当 $n>2k$ 时， $n-k+1>\frac{n}{2}$ 。 $k$ 个这样的因子乘起来，

$$
\binom{n}{k}>\frac{n^k}{2^k\,k!}.
$$

于是

$$
(1+p)^n\ge\binom{n}{k}p^k>\frac{n^k p^k}{2^k\,k!},
$$

$$
0<\frac{n^\alpha}{(1+p)^n}<\frac{2^k\,k!}{p^k}\,n^{\alpha-k}.
$$

取整数 $k>\alpha$ ，则 $\alpha-k<0$ 。定理 18.2 说右边这个负幂趋于 $0$ ，常数倍仍趋于 $0$ 。夹逼得到原式趋于 $0$ 。条件 $n>2k$ 只丢掉有限的开头。尾部收敛，整条序列就收敛。

$\alpha=1$ 、 $p=1$ 时，分母是 $2^n$ ，结论是 $\frac{n}{2^n}\to 0$ 。

```lean
theorem linear_over_double :
    Tendsto (fun n : ℕ => (n : ℝ) / (2 : ℝ) ^ n) atTop (nhds 0) := by
  simpa [pow_one] using
    tendsto_pow_const_div_const_pow_of_one_lt 1 (by norm_num : (1 : ℝ) < 2)
```

`tendsto_pow_const_div_const_pow_of_one_lt` 说：底数 $r>1$ 时， $\frac{n^k}{r^n}\to 0$ 。这里 $k=1$ 、 $r=2$ 。 `pow_one` 把 $n^1$ 写成 $n$ 。

## 18.6 定理 18.6： $x^n$

若 $|x|<1$ ，则 $x^n\to 0$ 。

$x=0$ 时序列就是 $0,0,0,\ldots$ 。

$0<x<1$ 时，令 $p=\frac{1}{x}-1$ 。则 $p>0$ ，而且 $x=\frac{1}{1+p}$ 。定理 18.5 里取 $\alpha=0$ ，

$$
x^n=\frac{n^0}{(1+p)^n}\to 0.
$$

$-1<x<0$ 时，不能把 $p=\frac{1}{x}-1$ 直接代进去，因为这时 $p$ 可能是负的。例如 $x=-\frac{1}{2}$ 时 $p=-3$ 。先对绝对值用上一款： $|x|<1$ ，所以 $|x|^n\to 0$ 。乘上 $-1$ 之后 $-|x|^n\to 0$ 。而

$$
-|x|^n\le x^n\le |x|^n,
$$

夹逼得到 $x^n\to 0$ 。

$|x|=1$ 时不一定收敛。 $x=1$ 是常数 $1$ 。 $x=-1$ 是 $(-1)^n$ ，上一章已经看过，它在 $-1$ 和 $1$ 之间跳动。

$x>1$ 时 $x^n\to+\infty$ 。 $x<-1$ 时 $|x|^n\to+\infty$ ，序列无界，所以发散；奇偶项分别跑向两个方向，并不落到单独一个 $+\infty$ 或 $-\infty$ 。

库里的几何项覆盖 $|x|<1$ 的全部情形。取 $x=\frac{1}{2}$ 。

```lean
theorem half_pow : Tendsto (fun n : ℕ => ((1 : ℝ) / 2) ^ n) atTop (nhds 0) :=
  tendsto_pow_atTop_nhds_zero_of_abs_lt_one (by norm_num)
```

`tendsto_pow_atTop_nhds_zero_of_abs_lt_one` 的条件就是 $|r|<1$ 。 `norm_num` 确认 $\left|\frac{1}{2}\right|<1$ 。

```isabelle
lemma half_pow: "(\<lambda>n. ((1::real) / 2) ^ n) \<longlonglongrightarrow> 0"
proof (rule LIMSEQ_power_zero)
  show "norm ((1::real) / 2) < 1" by simp
qed
```

`LIMSEQ_power_zero` 用的是范数： $\|x\|<1$ 时 $x^n\to 0$ 。实数的范数就是绝对值。

第 $10$ 项已经很小： $\left(\frac{1}{2}\right)^{10}=\frac{1}{1024}<\frac{1}{100}$ 。

```coq
Lemma half_ten : 1 / 1024 < 1 / 100.
Proof.
  lra.
Qed.
```

Agda 里同一对整数是 $2^{10}=1024$ ，并且 $100<1024$ 。 $100<4\cdot 32=128=2^7$ ，而 $7<10$ 把指数从 $2^7$ 推到 $2^{10}$ 。

```agda
two-ten : 2 ^ 10 ≡ 1024
two-ten = refl

hundred-lt-1024 : 100 < 1024
hundred-lt-1024 =
  subst (100 <_) two-ten
    (<-trans (subst (100 <_) (sym two-seven) hundred-lt-128) pow-gap)
```

`^-monoʳ-<` 用在 `pow-gap` 上：底数 $2>1$ ，指数 $7<10$ ，所以 $2^7<2^{10}$ 。

$\frac{1}{11^2}$ 的比较也落在自然数上。 $11\cdot 11=121$ ，而 $10<11<11\cdot 11$ ，所以 $10<121$ ，也就是 $\frac{1}{121}<\frac{1}{10}$ 。

```agda
eleven-sq : 11 * 11 ≡ 121
eleven-sq = refl

ten-lt-sq : 10 < 121
ten-lt-sq = subst (10 <_) eleven-sq (<-trans (n<1+n 10) (m<m*n 11 11 one-lt-11))
```

`m<m*n` 在第二个因子大于 $1$ 时给出严格放大。 $1<11$ ，所以 $11<11\cdot 11$ 。

Julia、Python、Prolog 核对同一组分数： $\frac{1}{121}<\frac{1}{10}$ ， $\frac{1}{121}$ 严格落在 $0$ 和 $\frac{1}{11}$ 之间， $\left(\frac{1}{2}\right)^{10}=\frac{1}{1024}<\frac{1}{100}$ ， $\left(\frac{3}{2}\right)^2=\frac{9}{4}>1+2\cdot\frac{1}{2}$ 。Prolog 用 `rdiv` 做有理数，不用浮点除法。

## 18.7 七通道对照

| 主题 | Lean | Isabelle | Coq | Agda | 计算三通道 |
|------|------|----------|-----|------|------------|
| 夹逼 | `tendsto_of_tendsto_of_tendsto_of_le_of_le` | `tendsto_sandwich` | $0<\frac{1}{121}<\frac{1}{11}$ | — | 同一对分数 |
| $\frac{1}{n^2}\to 0$ | 平方夹在 $0$ 与 $\frac{1}{n+1}$ 之间 | `tendsto_power` | $\frac{1}{121}<\frac{1}{10}$ | $10<121$ | $\frac{1}{121}<\frac{1}{10}$ |
| 二项式一步 | $\frac{9}{4}>2$ | `power2_eq_square` | $\frac{3}{2}\cdot\frac{3}{2}$ | $8<9$ | $\frac{9}{4}>2$ |
| $n^{1/n}\to 1$ | `tendsto_rpow_div` | `LIMSEQ_root` | — | — | — |
| $p^{1/n}\to 1$ | — | `LIMSEQ_root_const` | — | — | — |
| $\frac{n}{2^n}\to 0$ | `tendsto_pow_const_div_const_pow_of_one_lt` | — | — | — | — |
| $\left(\frac{1}{2}\right)^n\to 0$ | `tendsto_pow_atTop_nhds_zero_of_abs_lt_one` | `LIMSEQ_power_zero` | $\frac{1}{1024}<\frac{1}{100}$ | $100<1024$ | $\frac{1}{1024}<\frac{1}{100}$ |

## 18.8 本章验证清单

- `examples/lean/Realanalysis/Ch18Special.lean`：平方被夹逼到 $0$ ， $\left(\frac{1}{2}\right)^n\to 0$ ， $n^{1/n}\to 1$ ， $\frac{n}{2^n}\to 0$ ，以及 $\frac{9}{4}>2$ 。
- `examples/isabelle/RA18/Special.thy`： $\frac{1}{(n+1)^2}\to 0$ ，调和序列的一半被夹逼到 $0$ ， $\left(\frac{1}{2}\right)^n\to 0$ ， $n^{1/n}\to 1$ ， $2^{1/n}\to 1$ 。
- `examples/coq/Ch18_special.v`： $\frac{1}{121}$ 的两个不等式， $\frac{1}{1024}<\frac{1}{100}$ ，二项式的一步。
- `examples/agda/Ch18_special.agda`： $10<121$ ， $8<9$ ， $100<1024$ 。
- `examples/julia/18_special.jl`、`examples/python/18_special.py`、`examples/prolog/18_special.pl`：同一组有理数。

复验：`pwsh -NoProfile -Command '& ./build.ps1 -Chapter 18'`。

## 18.9 接下来

这几条极限把“指数压过多项式”和“公比绝对值小于 $1$ 就缩向 $0$ ”固定下来。后面做级数时，部分和本身仍是一条序列，收敛还是按序列的定义来谈。

上一章：[17 子序列极限](17-subseq-limits.md) · 下一章：[19 级数](19-series.md) · [返回目录](../README.md)
