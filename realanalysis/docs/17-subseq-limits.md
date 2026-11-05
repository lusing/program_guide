# 第 17 章 子序列极限

> 一条序列可以发散，同时仍有很清楚的子序列极限。
> $(-1)^n$ 在 $1$ 和 $-1$ 之间来回，它并不趋于 $+\infty$ 或 $-\infty$ 。
> 上极限是全体子序列极限的上确界，下极限是下确界。
> 两者相等而且有限，当且仅当序列收敛到这个数。

## 17.1 定义 17.1：发散到无穷

$\{s_n\}$ 是 $\mathbb{R}$ 中的序列。若对任意实数 $M$ ，存在自然数 $N$ ，使

$$n\ge N\implies s_n\ge M,$$

则记 $\lim_{n\to\infty}s_n=+\infty$ ，或 $s_n\to+\infty$ 。

若对任意实数 $M$ ，存在 $N$ ，使 $n\ge N$ 时 $s_n\le M$ ，则记 $s_n\to-\infty$ 。

箭头在这里是记号上的借用。序列并没有收敛。它发散，而且最终会越过任意一条水平线。把 $+\infty$ 和 $-\infty$ 写进同一个记号，是为了后面把它们放进子序列极限的集合。讨论的范围是扩张的实数系 $\mathbb{R}\cup\{+\infty,-\infty\}$ 。没有上界的集合，上确界写成 $+\infty$ ；没有下界的集合，下确界写成 $-\infty$ 。

## 17.2 例 17.2：四条序列

1. $s_n=n^2$ 发散到 $+\infty$ 。给定 $M$ ，取 $N$ 大于 $\sqrt{|M|}$ 即可。 $n=4$ 时 $4^2=16$ ，已经大于 $10$ 。

```lean
theorem squares_to_top : Tendsto (fun n : ℕ => (n : ℝ) ^ 2) atTop atTop := by
  simpa [pow_two] using
    (tendsto_natCast_atTop_atTop (R := ℝ)).atTop_mul_atTop₀
      (tendsto_natCast_atTop_atTop (R := ℝ))
```

`tendsto_natCast_atTop_atTop` 是 $n\to+\infty$ 。平方就是这项和自己相乘，`pow_two` 把 $n\cdot n$ 写成 $n^2$ 。 `atTop_mul_atTop₀` 用的是有序环：两个都趋于正无穷的序列，乘积仍趋于正无穷。Isabelle 用 `filterlim_pow_at_top` ，底数是 `filterlim_real_sequentially` 。

2. $s_n=-5n$ 发散到 $-\infty$ 。负数乘上趋于正无穷的序列，方向反过来。 $n=4$ 时 $-5\cdot 4=-20$ ，已经小于 $-10$ 。

```lean
theorem neg_five_to_bot : Tendsto (fun n : ℕ => (-5 : ℝ) * n) atTop atBot :=
  tendsto_natCast_atTop_atTop.const_mul_atTop_of_neg (by norm_num : (-5 : ℝ) < 0)
```

`const_mul_atTop_of_neg` 把负的常数放在左边，结论是 `atBot` ，也就是 $-\infty$ 。

3. $s_n=(-1)^n$ 发散，但不发散到无穷。它只取 $1$ 和 $-1$ 。给定 $M=0$ ，不能让后面每一项都 $\ge 0$ ，因为奇数项是 $-1$ 。也不能让后面每一项都 $\le 0$ ，因为偶数项是 $1$ 。

奇数下标 $2k+1$ 严格递增，而且

$$(-1)^{2k+1}=-1.$$

假如整条序列趋于 $+\infty$ ，这条子序列也趋于 $+\infty$ 。可是它是常数 $-1$ 。常数 $-1$ 最终不会 $\ge 0$ 。

```lean
theorem odd_pow (k : ℕ) : (-1 : ℝ) ^ (2 * k + 1) = -1 := by
  rw [pow_add, pow_one, pow_mul]
  norm_num

theorem alt_not_top : ¬ Tendsto (fun n : ℕ => (-1 : ℝ) ^ n) atTop atTop := by
  intro h
  have heq : (fun k : ℕ => (-1 : ℝ) ^ (2 * k + 1)) = fun _ => (-1 : ℝ) := by
    ext k
    exact odd_pow k
  have hconst : Tendsto (fun _ : ℕ => (-1 : ℝ)) atTop atTop := by
    rw [← heq]
    exact h.comp odd_strictMono.tendsto_atTop
  have h0 : ∀ᶠ _ : ℕ in atTop, (0 : ℝ) ≤ -1 := hconst (mem_atTop 0)
  obtain ⟨_, hn⟩ := h0.exists
  linarith
```

`odd_strictMono` 是第 15 章的奇数下标。 `comp` 把“整条序列趋于正无穷”传到子序列上。 `heq` 把奇数次幂收成常数 $-1$ ， `rw [← heq]` 把目标里的常数换回这条子序列。 `mem_atTop 0` 是“最终 $\ge 0$ ”这件事。常数 $-1$ 做不到， `linarith` 得到矛盾。

每一项的绝对值都是 $1$ ：

```lean
theorem alt_abs : ∀ n : ℕ, |(-1 : ℝ) ^ n| = 1 :=
  abs_neg_one_pow
```

所以序列有界。计算通道核对偶次方是 $1$ 、奇次方是 $-1$ ，绝对值小于 $10$ 。

4. $s_n=(-1)^n n$ 也发散，而且也不发散到无穷。偶数项是大正数，奇数项是大负数。给定 $M$ ，下一项会跳到另一侧，不能让尾部全部 $\ge M$ ，也不能全部 $\le M$ 。它的偶数子序列趋于 $+\infty$ ，奇数子序列趋于 $-\infty$ 。

## 17.3 定理 17.3：无界当且仅当有子序列发散到无穷

$\{s_n\}$ 无界，当且仅当它有一条子序列发散到 $+\infty$ 或 $-\infty$ 。

若无界，则对任意 $M$ 都有一项的绝对值大于 $M$ 。这些大项不能只出现有限次，否则去掉它们之后序列有界。于是可以挑出一条子序列，各项依次超过 $M$ ， $M+1$ ， $M+2$ ， $\ldots$ 。它发散到 $+\infty$ 或 $-\infty$ 。

反过来，若子序列 $s_{n_k}\to+\infty$ ，则对任意 $M$ 和任意参考点 $q$ ，尾部有一项 $s_{n_k}\ge M+|q|+1$ ，于是 $|s_{n_k}-q|>M$ 。序列无界。负无穷的情形把不等号反过来。

$(-1)^n$ 有界，所以它没有发散到无穷的子序列。 $n^2$ 无界，它自己就是一条发散到 $+\infty$ 的子序列。

## 17.4 定义 17.4：上极限与下极限

设 $E$ 是扩张实数系里这样的 $x$ ：有一条子序列 $s_{n_k}\to x$ 。这里的箭头包括 $+\infty$ 和 $-\infty$ 。若某条子序列发散到正无穷，就把 $+\infty$ 放进 $E$ ；发散到负无穷，就把 $-\infty$ 放进 $E$ 。

$$s^*=\sup E,\qquad s_*=\inf E.$$

$s^*$ 是上极限，$s_*$ 是下极限，记作

$$\limsup_{n\to\infty}s_n=s^*,\qquad\liminf_{n\to\infty}s_n=s_*.$$

第 15 章的 $E^*$ 只收真正的极限。这里的 $E$ 多了可能出现的无穷。上极限不是“上确界序列的极限”，而是全体子序列极限的上确界。符号容易让人读反，证明时按这个意思用。

## 17.5 例 17.5：四组上极限和下极限

1. $s_n=\bigl[(-1)^n+1\bigr]n$ 。奇数项是 $0$ ，偶数项是 $2n$ 。 $n=1,3,5$ 给出 $0$ ； $n=2,4,6$ 给出 $4,8,12$ 。任何子序列要么最终贴着 $0$ ，要么沿着偶数项跑到 $+\infty$ 。像 $12$ 这样的单个值不是子序列极限：以 $4,8,12$ 开头之后还必须有无穷多项。于是 $E=\{0,+\infty\}$ ，

$$\limsup_{n\to\infty}s_n=+\infty,\qquad\liminf_{n\to\infty}s_n=0.$$

$n=6$ 的偶数项已经大于 $10$ 。Agda 只记偶数下标还在前进： $2<4$ 并且 $4<6$ 。

2. $s_n=1$ 。每条子序列都收敛到 $1$ ，所以 $E=\{1\}$ ，上极限和下极限都是 $1$ 。

```lean
theorem const_limsup : limsup (fun _ : ℕ => (1 : ℝ)) atTop = 1 :=
  tendsto_const_nhds.limsup_eq

theorem const_liminf : liminf (fun _ : ℕ => (1 : ℝ)) atTop = 1 :=
  tendsto_const_nhds.liminf_eq
```

常数序列收敛到 $1$ 。 `limsup_eq` 和 `liminf_eq` 把这个极限分别写成上极限和下极限。Isabelle 在扩张实数上调用 `Limsup_const` 和 `Liminf_const` ，滤子不是平凡的，用 `sequentially_bot` 送进去。

3. 把 $\mathbb{Q}$ 排成一条序列。任意实数 $x$ 附近都有无穷多个有理数，所以可以造一条子序列趋于 $x$ ：先找到足够近的一项，再往更后面找更近的一项。有理数既无上界也无下界，所以也有子序列趋于 $+\infty$ 和 $-\infty$ 。于是 $E$ 是整个扩张实数系，上极限是 $+\infty$ ，下极限是 $-\infty$ 。这里没有一条现成的枚举可以拿来计算，构造留在叙述里。

4. $p_n=(-1)^n$ 。偶数子序列恒为 $1$ ，奇数子序列恒为 $-1$ 。没有别的子序列极限，也不出现无穷。所以 $E=\{-1,1\}$ ，

$$\limsup_{n\to\infty}p_n=1,\qquad\liminf_{n\to\infty}p_n=-1.$$

只说“它发散”会漏掉这两点。上极限和下极限把它们记下来。

每一项满足 $-1\le(-1)^n\le 1$ 。偶子序列的上极限是 $1$ ，而子序列的上极限不会超过原序列的上极限，所以原序列的上极限至少是 $1$ 。它又不可能更大。下极限用奇数子序列，理由相同。

```lean
theorem alt_le_one : ∀ n : ℕ, (-1 : ℝ) ^ n ≤ 1 := by
  intro n
  calc
    (-1 : ℝ) ^ n ≤ |(-1 : ℝ) ^ n| := le_abs_self _
    _ = 1 := abs_neg_one_pow n

theorem alt_ge_neg_one : ∀ n : ℕ, (-1 : ℝ) ≤ (-1 : ℝ) ^ n := by
  intro n
  calc
    (-1 : ℝ) = -|(-1 : ℝ) ^ n| := by rw [abs_neg_one_pow]
    _ ≤ (-1 : ℝ) ^ n := neg_abs_le _

theorem alt_limsup : limsup (fun n : ℕ => (-1 : ℝ) ^ n) atTop = 1 := by
  have hsub : limsup (fun k : ℕ => (-1 : ℝ) ^ (2 * k)) atTop = 1 := even_alt.limsup_eq
  have hcomp :
      limsup ((fun n : ℕ => (-1 : ℝ) ^ n) ∘ fun k : ℕ => 2 * k) atTop ≤
        limsup (fun n : ℕ => (-1 : ℝ) ^ n) atTop :=
    even_strictMono.tendsto_atTop.limsup_comp_le_limsup
      (hvf := even_cobounded_above) (hg := alt_bounded_above)
  have hle : limsup (fun k : ℕ => (-1 : ℝ) ^ (2 * k)) atTop ≤
      limsup (fun n : ℕ => (-1 : ℝ) ^ n) atTop := by
    simpa [Function.comp_def] using hcomp
  have hge : (1 : ℝ) ≤ limsup (fun n : ℕ => (-1 : ℝ) ^ n) atTop := by
    calc
      (1 : ℝ) = limsup (fun k : ℕ => (-1 : ℝ) ^ (2 * k)) atTop := hsub.symm
      _ ≤ limsup (fun n : ℕ => (-1 : ℝ) ^ n) atTop := hle
  have hup : limsup (fun n : ℕ => (-1 : ℝ) ^ n) atTop ≤ 1 :=
    limsup_le_of_le (hf := alt_cobounded_above) (h := Eventually.of_forall alt_le_one)
  exact le_antisymm hup hge
```

绝对值是 $1$ ，所以 $-|(-1)^n|=-1$ 。实数上的上极限还要有界性：每一项 $\le 1$ ，这是 `alt_bounded_above` 。若尾部最终不超过某个 $a$ ，偶数项 `even_pow` 等于 $1$ ，于是 $a\ge 1$ ，这是 `alt_cobounded_above` ，序列没有往 $+\infty$ 逃。

`even_alt.limsup_eq` 把偶数子序列的上极限算成 $1$ 。 `limsup_comp_le_limsup` 用上面的有界性，得到子序列的上极限不超过原序列。 `Function.comp_def` 把复合写成 $\lambda k.\,(-1)^{2k}$ 。 `calc` 先把 $1$ 换成这条上极限，再放进原序列。不用替换去改写数字 $1$ ，是因为 $(-1)^n$ 里面也有它。 `limsup_le_of_le` 再用“每一项 $\le 1$ ”把上极限压回 $1$ 。

下极限把偶数换成奇数。 `alt_bounded_below` 是每一项 $\ge -1$ 。 `odd_cobounded_below` 用奇数项等于 $-1$ ，保证序列没有往 $-\infty$ 逃。

```lean
theorem alt_liminf : liminf (fun n : ℕ => (-1 : ℝ) ^ n) atTop = -1 := by
  have hsub : liminf (fun k : ℕ => (-1 : ℝ) ^ (2 * k + 1)) atTop = -1 := odd_alt.liminf_eq
  have hcomp :
      liminf (fun n : ℕ => (-1 : ℝ) ^ n) atTop ≤
        liminf ((fun n : ℕ => (-1 : ℝ) ^ n) ∘ fun k : ℕ => 2 * k + 1) atTop :=
    odd_strictMono.tendsto_atTop.liminf_le_liminf_comp
      (hvf := odd_cobounded_below) (hg := alt_bounded_below)
  have hle : liminf (fun n : ℕ => (-1 : ℝ) ^ n) atTop ≤
      liminf (fun k : ℕ => (-1 : ℝ) ^ (2 * k + 1)) atTop := by
    simpa [Function.comp_def] using hcomp
  have hle' : liminf (fun n : ℕ => (-1 : ℝ) ^ n) atTop ≤ -1 := by
    calc
      liminf (fun n : ℕ => (-1 : ℝ) ^ n) atTop ≤
          liminf (fun k : ℕ => (-1 : ℝ) ^ (2 * k + 1)) atTop := hle
      _ = -1 := hsub
  have hge : (-1 : ℝ) ≤ liminf (fun n : ℕ => (-1 : ℝ) ^ n) atTop :=
    le_liminf_of_le (hf := alt_cobounded_below) (h := Eventually.of_forall alt_ge_neg_one)
  exact le_antisymm hle' hge
```

`liminf_le_liminf_comp` 的方向和上极限相反：原序列的下极限不超过子序列的下极限。奇数子序列的下极限是 $-1$ 。每一项又 $\ge -1$ ， `le_liminf_of_le` 给出另一边。

## 17.6 定理 17.6：收敛当且仅当上极限等于下极限

$\{s_n\}$ 收敛到有限数 $s$ ，当且仅当

$$\limsup_{n\to\infty}s_n=\liminf_{n\to\infty}s_n=s.$$

若 $s_n\to s$ ，则每条子序列都收敛到 $s$ 。子序列也不能发散到无穷，否则上极限或下极限会变成无穷。于是 $E=\{s\}$ ，上确界和下确界都是 $s$ 。

```lean
theorem limsup_liminf_of_tendsto {s : ℕ → ℝ} {a : ℝ} (h : Tendsto s atTop (nhds a)) :
    limsup s atTop = a ∧ liminf s atTop = a :=
  ⟨h.limsup_eq, h.liminf_eq⟩
```

`limsup_eq` 与 `liminf_eq` 就是这个方向，对任意收敛序列都成立。常数序列是它的特例。

反过来，设上极限和下极限都是同一个有限数 $s$ 。则 $E=\{s\}$ ：没有别的子序列极限，也没有发散到无穷的子序列。定理 17.3 因此说序列有界。若它不收敛到 $s$ ，则存在 $\varepsilon>0$ ，使无穷多项落在 $s+\varepsilon$ 的右侧，或落在 $s-\varepsilon$ 的左侧。这些项组成一条有界子序列。波尔查诺–魏尔斯特拉斯定理给它一条收敛的子序列，极限 $y$ 满足 $y\ge s+\varepsilon$ 或 $y\le s-\varepsilon$ 。于是 $y\in E$ 并且 $y\neq s$ ，矛盾。

$(-1)^n$ 的上极限是 $1$ 、下极限是 $-1$ ，两者不相等，所以它不收敛。这和上一章已经看到的偶、奇子序列一致。

## 17.7 定理 17.7：上极限和下极限自己也是子序列极限

$s^*=\limsup s_n$ 属于 $E$ ， $s_*=\liminf s_n$ 也属于 $E$ 。也就是说，各有一条子序列趋于它们，无穷也算。

上极限分三种情形。

1. $s^*=+\infty$ 。此时 $E$ 在 $\mathbb{R}$ 中无上界。对任意 $M$ ，都有子序列极限 $\ge M$ ，因而有无穷多项 $\ge M$ 。这些项拼成一条发散到 $+\infty$ 的子序列，所以 $+\infty\in E$ 。
2. $s^*$ 是有限实数。第 15 章已经证明，真正的子序列极限组成的集合是闭的。去掉无穷之后，有上界的闭集包含自己的上确界，所以 $s^*\in E$ 。
3. $s^*=-\infty$ 。此时 $E$ 里没有比 $-\infty$ 更大的元素，所以 $E=\{-\infty\}$ ，上极限当然在里面。

下极限也是三种情形。

1. $s_*=+\infty$ 。 $E$ 里没有比 $+\infty$ 更小的元素，所以 $E=\{+\infty\}$ ，下极限在里面。
2. $s_*$ 是有限实数。 $E$ 有下界，而且是闭集。有下界的闭集包含自己的下确界，所以 $s_*\in E$ 。
3. $s_*=-\infty$ 。 $E$ 在 $\mathbb{R}$ 中无下界。对任意 $M$ ，有无穷多项 $\le M$ ，它们拼成一条发散到 $-\infty$ 的子序列，所以 $-\infty\in E$ 。

$(-1)^n$ 的情形是第二种： $1$ 和 $-1$ 都已经由偶、奇子序列达到。

## 17.8 定理 17.8：上极限是尾部的上界

设 $s^*=\limsup s_n$ 。对任意 $x>s^*$ ，存在 $N$ ，使 $n\ge N$ 时 $s_n<x$ 。

设 $s_*=\liminf s_n$ 。对任意 $x<s_*$ ，存在 $N$ ，使 $n\ge N$ 时 $s_n>x$ 。

$s^*=+\infty$ 时没有更大的 $x$ ； $s_*=-\infty$ 时没有更小的 $x$ 。

证明用反证。若某个 $x>s^*$ 使得任意远的地方仍有 $s_n\ge x$ ，这些项组成子序列 $s_{n_k}\ge x$ 。若它无界，定理 17.3 给它一条发散到 $+\infty$ 的子序列，于是 $+\infty\in E$ ，可是 $+\infty>x>s^*$ ，与 $s^*=\sup E$ 矛盾。若它有界，波尔查诺–魏尔斯特拉斯定理给它一条收敛子序列，极限 $y\ge x>s^*$ ，又与上确界矛盾。

等号不够用。若只断言尾部 $s_n\le s^*$ ，反证只能找到极限 $y\ge s^*$ 。 $y$ 可以等于 $s^*$ ，并不矛盾。所以界必须严格大于上极限。

Isabelle 把这件事写成扩张实数上的等价条件：

```isabelle
lemma limsup_bound:
  fixes X :: "nat \<Rightarrow> ereal" and C :: ereal
  shows "C \<ge> Limsup sequentially X \<longleftrightarrow>
    (\<forall>y. C < y \<longrightarrow> eventually (\<lambda>n. X n < y) sequentially)"
  by (rule Limsup_le_iff)
```

`Limsup_le_iff` 说：$C$ 是上极限的一个上界，当且仅当每个严格更大的 $y$ 最终都压住序列。这就是定理 17.8 。下极限是对称的说法。

## 17.9 定理 17.9：存在且唯一

在扩张实数系里，上极限存在且唯一，下极限也存在且唯一。

存在性就是 $E$ 非空。序列无界时，定理 17.3 把 $+\infty$ 或 $-\infty$ 放进 $E$ 。序列有界时，波尔查诺–魏尔斯特拉斯定理给一条收敛子序列，极限是 $E$ 的一个有限元素。 $E$ 若无上界，上确界是 $+\infty$ ；否则最小上界性给出有限的上确界。下确界同样。

唯一性用定理 17.8 。若 $p<q$ 都是上极限，取 $p<x<q$ 。则从某项起 $s_n<x$ ，任何子序列的极限都 $\le x$ ，不能等于 $q$ 。于是 $q\notin E$ ，与定理 17.7 矛盾。下极限的两个候选 $p<q$ 之间取 $x$ ，尾部会 $s_n>x$ ，较小的那个候选就进不了 $E$ 。

## 17.10 定理 17.10：比较

若从某个 $N$ 起恒有 $s_n\le t_n$ ，则

$$\limsup s_n\le\limsup t_n,\qquad\liminf s_n\le\liminf t_n.$$

同一条下标抽出的两条子序列保持不等号。子序列极限因此也保持不等号：一边趋于 $+\infty$ 时另一边也趋于 $+\infty$ ，一边趋于 $-\infty$ 时另一边已经先到了 $-\infty$ 。于是 $E$ 的每个元素都不大于 $F$ 里对应的元素，上确界和下确界一起保持次序。

```lean
theorem limsup_mono {s t : ℕ → ℝ} (h : ∀ n, s n ≤ t n)
    (hs : IsCoboundedUnder (· ≤ ·) atTop s) (ht : IsBoundedUnder (· ≤ ·) atTop t) :
    limsup s atTop ≤ limsup t atTop :=
  limsup_le_limsup (Eventually.of_forall h) hs ht

theorem liminf_mono {s t : ℕ → ℝ} (h : ∀ n, s n ≤ t n)
    (hs : IsBoundedUnder (· ≥ ·) atTop s) (ht : IsCoboundedUnder (· ≥ ·) atTop t) :
    liminf s atTop ≤ liminf t atTop :=
  liminf_le_liminf (Eventually.of_forall h) hs ht
```

`Eventually.of_forall` 把“每一项都 $\le$ ”收成“最终 $\le$ ”。实数还没有把 $\pm\infty$ 收进值里，所以比较多要两个条件：左边的上极限不能靠“逃到正无穷”撑起来，右边要有上界。下极限换成下界。扩张实数把无穷直接写成上确界和下确界，Isabelle 的 `Limsup_mono` 和 `Liminf_mono` 就只需要 `eventually` 。

$(-1)^n$ 夹在常数 $-1$ 和常数 $1$ 之间，所以它的上极限夹在 $-1$ 和 $1$ 之间。上一节已经把它算成 $1$ ，下极限算成 $-1$ ，和这个比较相符。

后面常用的三件事可以收在一起。无穷多项有某种共性，就可以抽出一条子序列。子序列或原序列无界，则 $E$ 含有 $+\infty$ 或 $-\infty$ 。有界，则 $E$ 含有一个有限的子序列极限。

## 17.11 七通道对照

| 主题 | Lean | Isabelle | Coq | Agda | 计算三通道 |
|------|------|----------|-----|------|------------|
| $n^2\to+\infty$ | `atTop_mul_atTop₀` | `filterlim_pow_at_top` | $4\cdot 4>10$ | $4\cdot 4=16$ ， $10<16$ | $4^2>10$ |
| $-5n\to-\infty$ | `const_mul_atTop_of_neg` | `filterlim_cmult_at_bot_at_top` | $-5\cdot 4<-10$ | — | 同一对整数 |
| $(-1)^n$ 不趋于 $+\infty$ | 奇子序列是 $-1$ | `filterlim_compose` | 绝对值 $<10$ | — | 偶次 $1$ 、奇次 $-1$ |
| 常数的上下极限 | `limsup_eq` 、 `liminf_eq` | `Limsup_const` 、 `Liminf_const` | — | — | — |
| 交替序列 | 上极限 $1$ 、下极限 $-1$ | — | — | 偶数下标 $2<4<6$ | 尖峰的偶数项 $4,8,12$ |
| 尾部上界 | — | `Limsup_le_iff` | — | — | — |
| 比较 | `limsup_le_limsup` | `Limsup_mono` | — | — | — |

## 17.12 本章验证清单

- `examples/lean/Realanalysis/Ch17SubseqLimits.lean`：平方与 $-5n$ 、交替序列不趋于正无穷、常数与交替序列的上下极限、比较。
- `examples/isabelle/RA17/SubseqLimits.thy`：同样的发散、常数的上下极限、尾部上界、比较。
- `examples/coq/Ch17_subseq_limits.v`：越过 $10$ 的平方、降到 $-10$ 以下的线性项、符号和尖峰。
- `examples/agda/Ch17_subseq_limits.agda`： $10<16$ ，偶数下标 $2<4$ 并且 $4<6$ 。
- `examples/julia/17_subseq_limits.jl`、`examples/python/17_subseq_limits.py`、`examples/prolog/17_subseq_limits.pl`：同一组整数。

复验：`pwsh -NoProfile -Command '& ./build.ps1 -Chapter 17'`。

## 17.13 接下来

上极限和下极限把“发散”和“发散到无穷”分开，也把一条序列的全部子序列极限收成两个数。

下一章用夹逼定理看几条反复出现的具体序列： $\frac{1}{n^p}$ 、 $p^{1/n}$ 、 $n^{1/n}$ ，以及 $|x|<1$ 时的 $x^n$ 。

上一章：[16 柯西序列与单调序列](16-cauchy.md) · 下一章：[18 特殊序列](18-special-sequences.md) · [返回目录](../README.md)
