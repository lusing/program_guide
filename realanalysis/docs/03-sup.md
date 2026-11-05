# 第 03 章 上确界

> 对应原书第 4 章《上确界》。自然数用来计数，整数补上相反数与零，
> 有理数是整数做除法得到的。实数呢？“不是有理数”只是一句否定，
> 还没有说明这些数是什么。本章把这件事说清楚：有理数直线上有洞，
> 洞的名字叫“没有上确界”。实数要成为有理数的超集，并且把每个
> 有上界的非空子集都补上最小上界。这一章只建立上确界的语言和
> 两条等价性；域的运算留到下一章。

## 3.1 先把“洞”说具体

第 00 章已经核对过 $\sqrt{2}$ 不是有理数。这里把要用到的那一句话
重新证一遍，因为后面的三分律会直接撞上它。

设 $m, n$ 是自然数，$n \ne 0$ ，并且 $\gcd(m, n) = 1$ 。假如
$\sqrt{2} = m/n$ ，两边平方得到

$$m^2 = 2 n^2 .$$

右边是偶数，所以 $m^2$ 是偶数，从而 $m$ 是偶数（平方为偶则自身为偶：
奇数的平方仍是奇数）。写 $m = 2k$ ，代入得 $4k^2 = 2n^2$ ，即
$n^2 = 2k^2$ 。于是 $n$ 也是偶数。$m$ 与 $n$ 都是偶数，它们的最大公因数
至少是 $2$ ，与互素矛盾。所以没有这样的分数，$\sqrt{2} \notin \mathbb{Q}$ 。

Isabelle 通道把这段下降写在 `examples/isabelle/RA03/Sup.thy` 的
`sqrt_2_not_rat` 里。关键的一步是把实数等式收回到自然数：

```isabelle
from n0 eq0 have "real m = sqrt 2 * real n"
  by (simp add: abs_of_nonneg field_simps)
then have "(real m)\<^sup>2 = (sqrt 2)\<^sup>2 * (real n)\<^sup>2"
  by (simp add: power_mult_distrib power2_eq_square)
also have "(sqrt 2)\<^sup>2 = 2" by simp
also have "2 * (real n)\<^sup>2 = real (2 * n\<^sup>2)"
  by (simp add: of_nat_mult of_nat_power)
finally have "real (m\<^sup>2) = real (2 * n\<^sup>2)"
  by (simp add: of_nat_power)
then have eq: "m\<^sup>2 = 2 * n\<^sup>2" by (simp only: of_nat_eq_iff)
```

`real` 是自然数嵌进实数的强制转换。计算链在实数里做乘法，最后用
`of_nat_eq_iff`（嵌入是单射）回到 $m^2 = 2n^2$ 。后面的偶数性是
`even (m^2)` 推出 `even m` ，再取出 $k$ ，对 $n$ 重复一次，最后
`2 dvd gcd m n` 与 `coprime` 矛盾。

由此立刻得到有理数版本：不存在 $q \in \mathbb{Q}$ 使 $q^2 = 2$ 。
若有，则 $\sqrt{2} = |q|$ ，与上一段矛盾。Lean
（`examples/lean/Realanalysis/Ch03Sup.lean`）把这句写成

```lean
theorem rat_sq_ne_two (q : ℚ) : q ^ 2 ≠ 2 := by
  intro h
  apply irrational_sqrt_two
  ...
  exact ⟨(|q| : ℚ), hsqrt.symm⟩
```

`irrational_sqrt_two` 就是第 00 章用过的库定理。这里多做的一步是
把 $q^2 = 2$ 翻译成 $\sqrt{2} = |q|$ ：先用 `sq_abs` 把 $|q|^2$
换成 $q^2$ ，再用 `Real.sqrt_eq_iff_eq_sq`（非负实数由自己的平方
唯一决定）。Isabelle 的 `rat_sq_ne_two` 走同一条路，只是嵌入写成
`of_rat`。

有了这句话，就可以指出洞在哪里。令

$$A = \{ p \in \mathbb{Q} \mid p > 0,\ p^2 < 2 \}, \qquad B = \{ p \in \mathbb{Q} \mid p > 0,\ p^2 > 2 \}.$$

$A$ 里全是平方还没到 $2$ 的正有理数，$B$ 里全是已经超过的。
$\sqrt{2}$ 本身不在 $\mathbb{Q}$ 里，所以它既不在 $A$ 也不在 $B$ 。
把有理数想象成一条直线，$A$ 是这条直线上 $0$ 右侧、尚未到达那个缺席点
的部分，$B$ 是缺席点右侧的部分。原书因此写成

$$A = (0, \sqrt{2}) \cap \mathbb{Q}, \qquad B = (\sqrt{2}, \infty) \cap \mathbb{Q}.$$

这只是事后的图画。在 $\sqrt{2}$ 还没有被构造出来之前，$A$ 和 $B$
的正式定义就是上面那两个集合描述。

## 3.2 定理 4.1：$A$ 没有最大元，$B$ 没有最小元

定理说的是：存在没有最大数的有理数子集，也存在没有最小数的有理数子集。
举出 $A$ 和 $B$ 就够了。

**$A$ 没有最大元。** 任取 $p \in A$ ，要在 $A$ 里找到严格更大的 $q$ 。
取

$$q = \frac{2p + 2}{p + 2}.$$

先把差写清楚。通分：

$$q - p = \frac{2p + 2}{p + 2} - p = \frac{2p + 2 - p(p + 2)}{p + 2} = \frac{2p + 2 - p^2 - 2p}{p + 2} = \frac{2 - p^2}{p + 2}.$$

因为 $p^2 < 2$ ，分子 $2 - p^2 > 0$ ；因为 $p > 0$ ，分母 $p + 2 > 0$ 。
所以 $q - p > 0$ ，即 $q > p$ 。

还要确认 $q$ 仍在 $A$ 里，也就是 $q > 0$ （已由 $q > p > 0$ 得到）并且
$q^2 < 2$ 。直接算

$$q^2 - 2 = \frac{(2p + 2)^2}{(p + 2)^2} - 2 = \frac{(2p + 2)^2 - 2(p + 2)^2}{(p + 2)^2}.$$

分子展开：$(2p + 2)^2 = 4p^2 + 8p + 4$ ，
$2(p + 2)^2 = 2(p^2 + 4p + 4) = 2p^2 + 8p + 8$ ，两者相减得
$2p^2 - 4 = 2(p^2 - 2)$ 。因此

$$q^2 - 2 = \frac{2(p^2 - 2)}{(p + 2)^2}.$$

$p^2 - 2 < 0$ ，分母是正数的平方，所以 $q^2 - 2 < 0$ 。
$q \in A$ 且 $q > p$ 。$A$ 的任何一个元素都不是最大的。

**$B$ 没有最小元。** 原书把这一半留成填空，同一个 $q$ 就能填上。
仍取 $q = (2p + 2)/(p + 2)$ ，其中现在 $p \in B$ ，即 $p > 0$ 且
$p^2 > 2$ 。上面的差公式不变：

$$q = p - \frac{p^2 - 2}{p + 2}.$$

这次 $p^2 - 2 > 0$ 且 $p + 2 > 0$ ，所以减去的是正数，$q < p$ 。
平方差公式也不变：

$$q^2 - 2 = \frac{2(p^2 - 2)}{(p + 2)^2} > 0,$$

故 $q^2 > 2$ 。又因分子分母都正，$q > 0$ 。于是 $q \in B$ 且 $q < p$ 。
$B$ 的任何一个元素都不是最小的。

两条恒等式是整个构造的发动机。Python 通道
（`examples/python/03_sup.py`）用精确分数把它们逐项核验，不靠浮点：

```python
def qstep(p):
    return (2 * p + 2) / (p + 2)

def check_identities(p):
    q = qstep(p)
    assert q - p == (2 - p * p) / (p + 2)
    assert q * q - 2 == 2 * (p * p - 2) / (p + 2) ** 2
    return q
```

`Fraction` 的除法是精确的，所以这两条 `assert` 核对的是恒等式本身，
每一步分数都没有舍入。从 $1$ 出发迭代八步，每步都要求 $q > p$ 且 $q^2 < 2$ ：

```python
p = Fraction(1)
for _ in range(8):
    q = check_identities(p)
    assert q > p and q * q < 2
    p = q
```

第八步得到 $p_8 = 1393/985$ ，而

$$2 - p_8^2 = \frac{1}{970225}.$$

差距是一个正的单位分数，永远不是零。从 $2$ 出发的对偶迭代
（$2^2 = 4 > 2$ ）每步变小、平方仍大于 $2$ ，八步后是 $1970/1393$ ，
差距 $p_8^2 - 2 = 2/1940449$ 。Julia 用有理数 `//` 做同一组断言，
Prolog 把恒等式写成可执行的算术目标：

```prolog
identities(P) :-
    qstep(P, Q),
    Q - P =:= (2 - P * P) rdiv (P + 2),
    Q * Q - 2 =:= (2 * (P * P - 2)) rdiv ((P + 2) * (P + 2)).
```

`rdiv` 是 SWI-Prolog 的精确有理除法。`qstep_down` 再要求
$0 < q < p$ 且 $q^2 > 2$ ，对应 $B$ 没有最小元。

形式证明不靠迭代，一次就对任意正数成立。Lean 的 `q_trick_gt`
在有理数上：

```lean
theorem q_trick_gt (p : ℚ) (h0 : 0 < p) (h2 : p ^ 2 < 2) :
    ∃ q : ℚ, p < q ∧ q ^ 2 < 2 := by
  use (2 * p + 2) / (p + 2)
  have hpos : (0 : ℚ) < p + 2 := by linarith
  constructor
  · rw [lt_div_iff₀ hpos]
    nlinarith [h2]
  · rw [div_pow, div_lt_iff₀ (pow_pos hpos 2)]
    nlinarith [h2]
```

`lt_div_iff₀` 说：分母为正时，$p < (2p+2)/(p+2)$ 等价于
$p(p+2) < 2p+2$ 。`nlinarith` 再把这个多项式不等式化成 $p^2 < 2$ ，
而这正是假设。第二支对 $q^2 < 2$ 做同样的去分母。`q_trick_lt`
把不等号全部反过来，并多证一句 $q > 0$ 。

Isabelle 把类型放宽到任意有序域 `'a::linordered_field`，因为这段代数
只用到加减乘除和保序，用不到完备性。它把平方展开写在明处，对应我们
手上的多项式：

```isabelle
have e1: "(2*p+2)^2 = 4*p^2 + 8*p + 4"
have e2: "2*(p+2)^2 = 2*p^2 + 8*p + 8"
have key: "(2*p+2)^2 < 2*(p+2)^2"
```

`key` 就是 $4p^2 + 8p + 4 < 2p^2 + 8p + 8$ ，两边消掉 $8p + 4$ 之后
剩下 $2p^2 < 4$ ，即 $p^2 < 2$ 。然后 `pos_divide_less_eq` 把
“分子的平方小于分母的平方的两倍”翻译回“商的平方小于 $2$ ”。

Coq 通道（`examples/coq/Ch03_sup.v`）在实数上做同样的事，去分母写得
更碎。比较 $p < (2p+2)/(p+2)$ 时，先得到无除法的不等式
$p(p+2) < 2p+2$ ，再调用

```coq
apply (Rmult_lt_reg_r (p + 2)); [exact hpos |].
unfold Rdiv. rewrite Rmult_assoc, (Rinv_l _ hnz), Rmult_1_r.
```

`Rmult_lt_reg_r` 允许两边同乘一个正数而不改变不等号方向；
`Rinv_l` 说非零数乘自己的倒数得 $1$ 。平方那一支则是两边同乘
$1/(p+2)^2$ 这个正数。三条通道的差别只在自动化的粒度：Lean 把
多项式比较交给 `nlinarith` ，Isabelle 展开系数后再交给 `linarith` ，
Coq 把每一次乘倒数都写成单独的改写。数学内容是同一对恒等式。

## 3.3 有序集

上面的证明一直在说“更大”“更小”。这需要一个正式的顺序。

**定义 4.2.** 集合 $S$ 上的顺序是一个关系 $<$ ，满足两条：

1. **三分律。** 对任意 $x, y \in S$ ，下列三句恰好一句成立：
   $x < y$ ，或 $x = y$ ，或 $y < x$ 。
2. **传递性。** 若 $x < y$ 且 $y < z$ ，则 $x < z$ 。

带有这样一个顺序的集合叫有序集。$y > x$ 只是 $x < y$ 的另一种写法。
非严格的 $\le$ 定义为严格顺序的否定：

$$x \le y \;\Longleftrightarrow\; \lnot (y < x), \qquad x \ge y \;\Longleftrightarrow\; \lnot (x < y).$$

由三分律，这等价于“$x < y$ 或 $x = y$ ”。实数上这两条就是库里的
`lt_trichotomy` 与 `lt_trans`：

```lean
example (x y : ℝ) : x < y ∨ x = y ∨ y < x := lt_trichotomy x y
example (x y z : ℝ) (hxy : x < y) (hyz : y < z) : x < z := lt_trans hxy hyz
```

有理数、整数、自然数都是有序集。没有顺序就谈不上最小元，定理 4.1
的陈述本身就依赖这一节。

## 3.4 最小值与最大值

**定义 4.3.** 有序集 $A$ 的最小值是 $A$ 中的最小元素，最大值是
$A$ 中的最大元素。记作 $\min A$ 与 $\max A$ 。

例如 $\min\{1, 2, 100\} = 1$ ，$\max\{1, 2, 100\} = 100$ 。

有限的非空有序集总有最小值和最大值：元素只有有限个，可以两两比较
取出最小的那个。无限集则不一定。开区间 $(-3, 3)$ 没有最小数：
假如 $a$ 是候选，三分律和开区间的定义给出某个 $b$ 满足
$-3 < b < a$ ，$b$ 仍在区间里。闭区间 $[-3, 3]$ 虽然也是无限集，
但端点在集合里，$\min[-3, 3] = -3$ ，$\max[-3, 3] = 3$ 。
规则是：有限非空有序集一定取得最值；无限有序集可能取得，也可能取不到。

原书例 4.4 还记了一条单调性。若 $A \subseteq B$ ，并且两边的最小值都存在，
则 $\min A \ge \min B$ 。理由：$b = \min B$ 比 $B$ 的每个元素都小，
而 $A$ 的元素都是 $B$ 的元素，所以 $b$ 也比 $A$ 的每个元素都小。
$a = \min A$ 是 $A$ 的一个元素，因此 $b \le a$ 。若 $b$ 碰巧落在
$A$ 里，则两边的最小值相等；若 $b \notin A$ ，则 $A$ 的最小值严格更大。
对偶地，$A \subseteq B$ 时 $\max A \le \max B$ 。Lean 把 $\le$ 这一侧写成

```lean
example {A B : Set ℝ} {a b : ℝ}
    (hA : IsLeast A a) (hB : IsLeast B b) (hAB : A ⊆ B) : b ≤ a := by
  rcases hA with ⟨ha, -⟩
  rcases hB with ⟨-, hb⟩
  exact hb (hAB ha)
```

`IsLeast B b` 拆开是两句话：$b \in B$ ，以及 $b$ 是 $B$ 的下界
（$B$ 的每个元素都 $\ge b$ ）。证明只用了第二句，作用在
$a \in A \subseteq B$ 上。

空集没有最小值，也没有最大值：最值必须是集合的元素，空集没有元素。
后面谈上确界时会再碰到这个约定——空集的上界集是整个宇宙，
“最小上界”会退化成宇宙的最小元，通常不把空集放进上确界的定理里。

原书还举了一个索引族的例子，用来说明“最大值不存在”可以发生在
一串有限数上。对每个实数 $\alpha$ 令
$A_\alpha = \{ n \in \mathbb{N} \mid n \le \alpha \}$ 。
每个 $A_\alpha$ 都是有限集，基数 $|A_\alpha|$ 是一个自然数。
这些基数里最小的是 $0$ ：例如 $\alpha = 1/2$ 时，没有自然数
$\le 1/2$ （若自然数从 $1$ 起算；若从 $0$ 起算则改取负数 $\alpha$ ），
$A_\alpha$ 是空集，基数为 $0$ 。最大的基数则不存在：无论 $\alpha$
多大，$A_{\alpha+1}$ 都至少比 $A_\alpha$ 多一个元素。一串自然数可以
没有最大元，这和 $A$ 没有最大有理数是同一类现象。

## 3.5 上界与下界：边界住在哪个宇宙里

最值必须属于集合。边界不必。

**定义 4.5.** 设 $E$ 是有序集 $S$ 的子集。若存在 $\alpha \in S$ ，
使得 $E$ 的每个元素都 $\le \alpha$ ，则称 $\alpha$ 是 $E$ 的一个上界，
并说 $E$ 在 $S$ 中有上界。用符号写：

$$\exists\, \alpha \in S,\ \forall x \in E,\ x \le \alpha .$$

下界对称：存在 $\beta \in S$ 使每个 $x \in E$ 都满足 $x \ge \beta$ 。

两件事先钉死。第一，上界只要住在 $S$ 里，不必住在 $E$ 里。
第二，同一批元素，换一个更小的宇宙 $S$ ，上界可能消失。
原书的例子把这件事摊开。

取 $E = (-\infty, 3) \cap \mathbb{Q}$ ，宇宙 $S = \mathbb{Q}$ 。
$E$ 没有下界：任何有理数 $\beta$ 的左边还有更小的有理数，那个数仍在
$E$ 里。$E$ 有上界：任何一个 $\ge 3$ 的有理数都是上界，$3$ 自己就是。
$3$ 并不属于 $E$ ，这不影响它当上界。

再看 $E = (0, 3)$ ，三个不同的宇宙：

- $S_1 = \mathbb{R}$ 。任何 $\ge 3$ 的实数是上界，任何 $\le 0$ 的实数是下界。
- $S_2 = (-3, 3)$ 。$\ge 3$ 的数全被排除在宇宙之外，所以上界不存在；
  $(-3, 0]$ 里的数仍然是下界。
- $S_3 = E$ 自己。上界必须落在 $(0, 3)$ 内部。这不可能：若
  $\alpha \in (0, 3)$ ，中点 $m = (\alpha + 3)/2$ 满足
  $\alpha < m < 3$ ，所以 $m \in E$ 且 $m > \alpha$ ，$\alpha$ 不是上界。
  下界同样不存在。

Lean 把 $S_1$ 和 $S_3$ 写成

```lean
example : BddAbove (Ioo (0 : ℝ) 3) := by
  use 3
  intro x hx
  exact hx.2.le

example : ¬ ∃ α, α ∈ Ioo (0 : ℝ) 3 ∧ α ∈ upperBounds (Ioo (0 : ℝ) 3) := by
  rintro ⟨α, ⟨h0, h3⟩, hub⟩
  have hm : (α + 3) / 2 ∈ Ioo (0 : ℝ) 3 := by constructor <;> linarith
  have : (α + 3) / 2 ≤ α := hub hm
  linarith
```

`Ioo` 是开区间。第一条说 $3$ 是上界：区间里的 $x$ 满足 $x < 3$ ，
因而 $x \le 3$ 。第二条假设有一个上界同时是区间的元素，推出中点既在
区间里又不超过 $\alpha$ ，与中点的构造矛盾。`3 ∉ Ioo 0 3` 是
`simp [mem_Ioo]` 的一行，提醒上界可以站在集合外面。

回到 $A$ 与 $B$ 。若把它们看成 $\mathbb{R}$ 的子集（预先承认
$\sqrt{2}$ 是一个实数），则 $\sqrt{2}$ 是 $A$ 的上界，任何更大的实数
也是；$B$ 的每个元素同样是 $A$ 的上界。对偶地，$A$ 的每个元素都是
$B$ 的下界。若宇宙只许是 $\mathbb{Q}$ ，则 $\sqrt{2}$ 根本不是这个
宇宙的居民，不能当边界；$A$ 与 $B$ 仍然以对方的元素为边界，但那个
“刚好卡在中间”的数不在场。这就是下一节要命名的缺口。

## 3.6 上确界：最小的那个上界

上界通常有很多个。$E = (-\infty, 3) \cap \mathbb{Q}$ 的上界是全部
$\ge 3$ 的有理数。其中最小的一个是 $3$ 。把它单独命名。

**定义 4.7.** 设 $E$ 是有序集 $S$ 的子集。若 $\alpha \in S$ 是 $E$
的上界，并且 $S$ 中任何严格小于 $\alpha$ 的元素都不是 $E$ 的上界，
则称 $\alpha$ 是 $E$ 的最小上界，或上确界，记 $\alpha = \sup E$ 。
三条合在一起：

$$\alpha \in S, \qquad x \in E \Rightarrow x \le \alpha, \qquad \gamma \in S,\ \gamma < \alpha \Rightarrow \gamma \text{ 不是 } E \text{ 的上界}.$$

下确界 $\inf E$ 是最大的下界：$\beta$ 是下界，并且任何
$\gamma > \beta$ 都不是下界。

第三条有一个等价说法，证明里常常更好用：$\alpha$ 不超过 $E$ 的
任何一个上界。也就是说，若 $\beta$ 是上界，则 $\alpha \le \beta$ 。
两个说法的等价用到三分律。若有上界 $\beta < \alpha$ ，则第三条直接
被违反。反过来，若有 $\gamma < \alpha$ 竟然是上界，则这个 $\gamma$
就是一个比 $\alpha$ 小的上界。所以“没有更小的上界”和“$\alpha$ 是
上界集里的最小元”是同一句话。Isabelle 采用第二种写法，定义本身就是
书上的两段：

```isabelle
definition is_lub :: "'a::order set \<Rightarrow> 'a \<Rightarrow> bool" where
  "is_lub S a \<equiv> (\<forall>x \<in> S. x \<le> a) \<and> (\<forall>b. (\<forall>x \<in> S. x \<le> b) \<longrightarrow> a \<le> b)"
```

第一段：$a$ 是上界。第二段：任何上界 $b$ 都满足 $a \le b$ 。
`is_glb` 把不等号反过来。定义写成多态的 `'a::order` ，所以同一对
谓词既能谈论实数集，也能谈论有理数集。这正是例 4.11 需要的：
失败发生在 $\mathbb{Q}$ 上，成功（下一章以后）发生在 $\mathbb{R}$ 上。

**唯一性。** 最小上界若存在就只有一个。设 $\alpha$ 与 $\alpha'$
都是上确界。$\alpha'$ 是上界，而 $\alpha$ 不超过任何上界，故
$\alpha \le \alpha'$ 。对调后 $\alpha' \le \alpha$ 。有序集里互相
不超过就是相等。Coq 把这个反对称写得很短：

```coq
Lemma is_lub_unique (E : R -> Prop) (x y : R) :
  is_lub E x -> is_lub E y -> x = y.
Proof.
  intros [hx_ub hx_least] [hy_ub hy_least].
  apply Rle_antisym.
  - apply hx_least. exact hy_ub.
  - apply hy_least. exact hx_ub.
Qed.
```

`Rle_antisym` 是 $x \le y \land y \le x \Rightarrow x = y$ 。
Lean 的同一事实是库定理 `IsLUB.unique` ，本章直接引用
`ha.unique hb` 。Isabelle 的 `sup_unique` 用 `order.antisym` ，
`metis` 从定义里把两个方向的 $\le$ 搜出来。

和下界一样，上确界不必属于 $E$ 。$(-3, 3)$ 没有最小值和最大值，
但在 $\mathbb{Q}$ 里（也在 $\mathbb{R}$ 里）有下确界 $-3$ 和上确界 $3$ 。
开区间的一般事实是：若 $a < b$ ，则

$$\inf (a, b) = a, \qquad \sup (a, b) = b.$$

右端点是上界，因为区间里每个点都 $< b$ 。它是最小的，因为任何
$\gamma < b$ 的右侧、仍然小于 $b$ 的位置都能放进区间的一个点
（例如 $\gamma$ 与 $b$ 的中点，只要它也大于 $a$ ；若 $\gamma \le a$ ，
区间里任何一个点都已经超过 $\gamma$ ）。Lean 引用库定理

```lean
example (a b : ℝ) (h : a < b) : sSup (Ioo a b) = b := csSup_Ioo h
example (a b : ℝ) (h : a < b) : sInf (Ioo a b) = a := csInf_Ioo h
```

Isabelle 的 `sup_Ioo` 是同一条，`{a<..<b}` 是开区间的语法，
`Sup` 在条件完备格上就是上确界算子，`a < b` 时它被 `simp` 化成 $b$ 。

## 3.7 定理 4.9：上界若在集合里，它就是上确界

这是使用定义时最省事的一条。

**定理 4.9.** 设 $E$ 是有序集 $S$ 的子集。若 $\alpha$ 是 $E$ 的上界
并且 $\alpha \in E$ ，则 $\alpha = \sup E$ 。若 $\beta$ 是 $E$ 的下界
并且 $\beta \in E$ ，则 $\beta = \inf E$ 。

证明。$\alpha$ 已经是上界。任取 $\gamma < \alpha$ 。$\alpha$ 自己是 $E$
的元素并且 $\alpha > \gamma$ ，所以 $\gamma$ 没有把 $E$ 的全部元素压在
下面，$\gamma$ 不是上界。因此 $\alpha$ 是最小上界。下界的一半把
不等号反过来：任何 $\gamma > \beta$ 都被集合里的 $\beta$ 从下面戳穿。

Coq 把“已经是上界、又是元素”直接拼成 `is_lub` ：

```coq
Lemma upper_bound_in_set_is_lub (E : R -> Prop) (a : R) :
  is_upper_bound E a -> E a -> is_lub E a.
Proof.
  intros hub hmem. split.
  - exact hub.
  - intros b hb. apply hb. exact hmem.
Qed.
```

第二支说：别的上界 $b$ 必须满足 $a \le b$ ，因为 $a$ 是 $E$ 的元素，
而上界的定义就是“压住每一个元素”。Lean 的 `upper_bound_mem_is_lub`
是同一段，类型放宽到任意预序，所以它不依赖实数的构造。

逆方向也很有用：上确界若属于集合，它就是最大值。Coq 的
`lub_member_is_max` 从 `is_lub` 里只取出上界那一半，作用在集合的
任意元素上。最大元就是“属于集合的上确界”，上确界是“未必属于集合的
最大元”。两者在元素恰好被取到时重合。

## 3.8 例 4.8：把定义用在三个集合上

**第一个集合。** $E = (-\infty, 3) \cap \mathbb{Q}$ ，宇宙是 $\mathbb{Q}$ 。
$3$ 是上界。要证明它是上确界，取任意有理数 $\gamma < 3$ ，证明 $\gamma$
不是上界。中点

$$m = \frac{\gamma + 3}{2}$$

仍是有理数，并且 $\gamma < m < 3$ ，所以 $m \in E$ 且 $m > \gamma$ 。
Lean 把“中点还在 $\gamma$ 与 $3$ 之间”单独列成存在性：

```lean
example (γ : ℚ) (h : γ < 3) : ∃ x : ℚ, γ < x ∧ x < 3 :=
  ⟨(γ + 3) / 2, by constructor <;> linarith⟩
```

Python、Julia、Prolog 用 $\gamma = 5/2$ 做了同一次数值核对：
$5/2 < (5/2 + 3)/2 < 3$ 。这个集合没有下界，所以没有下确界。
上确界是 $3$ ，而 $3 \notin E$ 。

**第二个集合：原书的填空。** 在 $\mathbb{Q}$ 中令

$$E = \left\{ \frac{1}{n} \mid n \in \mathbb{N},\ n \ge 1 \right\}.$$

上确界是 $1$ 。首先 $1 = 1/1$ 属于 $E$ ，而且每个 $1/n \le 1$ ，
所以 $1$ 是属于集合的上界。定理 4.9 直接给出 $\sup E = 1$ 。
任何 $\gamma < 1$ 都不是上界，因为 $1$ 自己就在集合里并且比 $\gamma$ 大。
Lean 的自然数从 $0$ 起，用 $n + 1$ 对齐书上的正整数，值域是同一个集合：

```lean
theorem one_div_sup :
    IsLUB (Set.range fun n : ℕ => (1 : ℝ) / (n + 1)) 1 := by
  refine upper_bound_mem_is_lub ?_ ?_
  · rintro _ ⟨n, rfl⟩
    have hpos : (0 : ℝ) < (n : ℝ) + 1 := by positivity
    rw [div_le_one hpos]
    linarith
  · exact ⟨0, by simp⟩
```

`⟨0, by simp⟩` 说 $n = 0$ 时通项等于 $1$ ，所以 $1$ 在值域里。
第一支证明 $1$ 是上界：`div_le_one` 把 $1/(n+1) \le 1$ 化成
$1 \le n + 1$ 。Isabelle 的 `one_div_sup` 同样先找 $n = 0$ 这个见证，
再调用 `upper_bound_mem_is_lub`。

下确界是 $0$ 。$0$ 属于 $\mathbb{Q}$ ，而且每个 $1/n > 0$ ，所以 $0$
是下界。$0$ 不属于 $E$ ，定理 4.9 用不上，第二段必须亲手做。
任取 $\gamma > 0$ ，要找一个 $1/n < \gamma$ 。这就是 $n > 1/\gamma$ 。
$1/\gamma$ 未必是自然数，把它向上取整再加一：令

$$n = 1 + \left\lceil \frac{1}{\gamma} \right\rceil .$$

则 $n$ 是自然数，并且 $n > 1/\gamma$ ，从而 $0 < 1/n < \gamma$ 。
这个 $1/n$ 属于 $E$ ，所以 $\gamma$ 不是下界。因此 $\inf E = 0$ 。

向上取整的存在性就是阿基米德性质的一个形式：每个正实数下面都有
一个足够小的单位分数。Lean 的 `one_div_inf` 用库定理
`exists_nat_one_div_lt` 取出这个 $n$ ：

```lean
theorem one_div_inf :
    IsGLB (Set.range fun n : ℕ => (1 : ℝ) / (n + 1)) 0 := by
  refine ⟨?_, ?_⟩
  · rintro _ ⟨n, rfl⟩
    positivity
  · intro b hb
    by_contra hlt
    push Not at hlt
    obtain ⟨n, hn⟩ := exists_nat_one_div_lt hlt
    have hmem := hb (Set.mem_range_self n)
    linarith
```

第一支：每一项都 $\ge 0$ （`positivity` 认识分母 $n+1 > 0$ ）。
第二支是下确界的“最大”：假设有一个下界 $b \not\le 0$ ，三分律给出
$b > 0$ ，然后某个 $1/(n+1) < b$ 。但 $b$ 是下界，又必须
$\le$ 这一项。两句不等式不能同时成立。Isabelle 的 `one_div_inf`
用 `ex_inverse_of_nat_less` 取 $n$ ，并把 $1/n$ 写成值域里的
$1/((n-1)+1)$ ，避免自然数从 $0$ 起算时下标错一位。

计算通道只能看有限截断。Python 对 $N = 10, 1000, 100000$ 断言
最大值是 $g(0) = 1$ ，最小值是 $g(N) = 1/(N+1) > 0$ 。截断的下确界
随着 $N$ 下降，但任何有限 $N$ 都还停在正数上。$0$ 是整个无限集合的
下确界。任何有限截断的最小值仍是正的末项。

**第三个集合：上确界不被取到。** 考虑

$$\left\{ 1 - \frac{1}{n+1} \mid n \in \mathbb{N} \right\} = \left\{ 0,\ \frac{1}{2},\ \frac{2}{3},\ \frac{3}{4},\ \ldots \right\}.$$

每一项都 $< 1$ ，所以 $1$ 是上界。$1$ 不属于值域：通项等于 $1$
将要求 $1/(n+1) = 0$ ，不可能。定理 4.9 再次用不上。最小性靠反证。
若有上界 $b < 1$ ，则 $1 - b > 0$ ，阿基米德性质给出 $n$ 使
$1/(n+1) < 1 - b$ ，于是

$$1 - \frac{1}{n+1} > b,$$

第 $n$ 项越过了所谓的上界。Lean 的 `one_sub_div_lub` 就是这段：

```lean
obtain ⟨n, hn⟩ := exists_nat_one_div_lt hε
have hmem := hb (Set.mem_range_self n)
linarith
```

`hε` 是 $1 - b > 0$ ，`hn` 是 $1/(n+1) < 1 - b$ ，`hmem` 是
“第 $n$ 项 $\le b$ ”（因为 $b$ 被假设为上界）。`linarith` 把这两句
加在一起得到矛盾。Isabelle 的 `range_sup_one` 结论更强一点：它证明
算子等式 `Sup (range ...) = 1` ，反证时用 `cSup_upper`（集合里的元素
不超过上确界）对阵那个被钻穿的项。

Python 对这个集合做截断：在 $0 \le n \le N$ 上最大值是末项
$f(N) = 1 - 1/(N+1) < 1$ ，缺口精确等于 $1/(N+1)$ 。另外给一个
正的 $\varepsilon$ ，取 $n = \lfloor 1/\varepsilon \rfloor + 1$ ，
断言 $f(n) > 1 - \varepsilon$ 。这是阿基米德性质的有限见证，
和证明里的 `exists_nat_one_div_lt` 是同一句话。

把这两个例子放在一起记：

| 集合 | 上确界 | 上确界是否属于集合 |
|------|--------|--------------------|
| $\{1/(n+1)\}$ | $1$ | 属于，就是最大值 |
| $\{1 - 1/(n+1)\}$ | $1$ | 不属于 |
| $(a, b)$ | $b$ | 不属于 |

上确界是“最紧的上界”。它落不落在集合里，是另外一个问题。

**关于 $A$ 与 $B$ 在实数里的上确界。** 若把 $A$ 看成 $\mathbb{R}$
的子集，并且承认存在正实数 $\sqrt{2}$ 满足 $(\sqrt{2})^2 = 2$ ，
则 $\sup A = \sqrt{2}$ 。上界性：若 $x \ge 0$ 且 $x^2 < 2 = (\sqrt{2})^2$ ，
则 $x < \sqrt{2}$ 。最小性：任何 $p < \sqrt{2}$ 都不是上界。
$p \le 0$ 时，$1 \in A$ 已经超过它；$0 < p$ 且 $p^2 < 2$ 时，
定理 4.1 的 $q$ 属于 $A$ 并且 $q > p$ 。$B$ 的下确界同样是 $\sqrt{2}$ ：
任何更大的正数都可以用 $q$ 再缩小，并且缩小后的平方仍然大于 $2$ 。

这一段使用了“$\sqrt{2}$ 作为一个实数已经存在”。那是实数完备性的
推论，正式的存在性证明放在第 05 章（`sqrt2_is_lub` 证明同一个集合
在 $\mathbb{R}$ 里的上确界就是 `Real.sqrt 2` ）。本章要建立的是
反面：把宇宙限制回 $\mathbb{Q}$ 时，这个上确界不存在。

## 3.9 例 4.11：$\mathbb{Q}$ 没有最小上界性

**定义 4.10.** 有序集 $S$ 具有最小上界性，是指：$S$ 的每一个非空
且在 $S$ 中有上界的子集 $E$ ，都在 $S$ 中存在 $\sup E$ 。

$\mathbb{Q}$ 不满足这条。$A$ 非空（$1 \in A$ ，因为 $1^2 = 1 < 2$ ），
并且有上界（$2$ 就是一个：$p > 0$ 且 $p^2 < 2 < 4$ 迫使 $p < 2$ ）。
但是 $A$ 在 $\mathbb{Q}$ 里没有上确界。证明按候选上确界 $a$ 的平方
与 $2$ 做三分律。先由 $1 \in A$ 得到 $a \ge 1 > 0$ 。

- 若 $a^2 < 2$ ，则 $a$ 自己满足 $q$ 构造的前提，`q_trick_gt`
  给出 $q > a$ 且 $q^2 < 2$ 。$q \in A$ ，所以 $a$ 连上界都不是。
- 若 $a^2 = 2$ ，则与 `rat_sq_ne_two` 矛盾。这一支就是洞的位置：
  唯一“刚好”的候选不是有理数。
- 若 $a^2 > 2$ ，则 `q_trick_lt` 给出 $0 < q < a$ 且 $q^2 > 2$ 。
  这个 $q$ 仍是 $A$ 的上界：任何 $p \in A$ 都满足 $p > 0$ 且
  $p^2 < 2 < q^2$ ，正数的平方比较保持顺序，所以 $p < q$ 。
  于是存在比 $a$ 更小的上界，$a$ 不是最小的。

三支都不可能，所以没有这样的 $a$ 。Lean 的 `hole_no_lub` 是这段的
逐字翻译，`hole` 就是集合 $A$ ：

```lean
abbrev hole : Set ℚ := {p : ℚ | 0 < p ∧ p ^ 2 < 2}

theorem hole_no_lub : ¬ ∃ a : ℚ, IsLUB hole a := by
  rintro ⟨a, ha⟩
  rcases ha with ⟨ha_ub, ha_least⟩
  ...
  rcases lt_trichotomy (a ^ 2) 2 with hlt | heq | hgt
```

`ha_ub` 是“$a$ 为上界”，`ha_least` 是“$a$ 不超过任何上界”。
小于 $2$ 的一支用 `lt_irrefl` ：$q > a$ 与 $q \le a$ 不能并存。
等于 $2$ 的一支调用 `rat_sq_ne_two` 。大于 $2$ 的一支先证明 $q$
属于 `upperBounds hole` （`nlinarith` 从 $p^2 < q^2$ 与双方为正
得到 $p \le q$ ），再与 $q < a$ 一起违反最小性。

`hole_nonempty` 与 `hole_bddAbove` 补上定义 4.10 的两个前提，
于是整句否定可以一次写出：

```lean
theorem rat_lacks_lub_property :
    ¬ ∀ s : Set ℚ, s.Nonempty → BddAbove s → ∃ a, IsLUB s a := by
  intro h
  exact hole_no_lub (h hole hole_nonempty hole_bddAbove)
```

Isabelle 的 `hole_no_lub` 用 `linorder_cases` 做同一个三分，
大于 $2$ 的一支调用 `power2_less_imp_less`：由 $p^2 < q^2$ 且
$q \ge 0$ 得到 $p < q$ 。这一支不需要 $\sqrt{2}$ ，只需要有序域
上的平方保序。等于 $2$ 的一支才用到本节开头的下降。

这就是定义实数的主要动机。我们要一个包含 $\mathbb{Q}$ 的有序集，
让每一个非空有上界的子集都在其中取得上确界。$A$ 的上确界将是
那个缺席的点。域运算（加法、乘法及其公理）是下一章的事；
最小上界性是本章留下的那条公理级要求。

## 3.10 定理 4.12：最小上界性推出最大下界性

有了最小上界性，要不要再单独要求“每个非空有下界的子集都有下确界”？
不必。两条性质等价，而且下确界有一个具体的造法：它是全体下界的上确界。

**定理 4.12.** 设 $S$ 具有最小上界性。则 $S$ 也具有最大下界性：
每个在 $S$ 中有下界的非空子集 $B$ 都在 $S$ 中有下确界。
若 $L$ 是 $B$ 的全体下界组成的集合，则 $\inf B = \sup L$ 。

证明分两段。第一段说明 $\sup L$ 存在，第二段说明它就是 $\inf B$ 。

$L$ 非空，因为 $B$ 有下界，那个下界就是 $L$ 的元素。$L$ 有上界：
取 $B$ 的任意一个元素 $b_0$ （$B$ 非空），则 $L$ 的每个元素都
$\le b_0$ ，因为下界的定义就是“不超过 $B$ 的每一个元素”。
于是 $L$ 是 $S$ 的非空有上界子集。最小上界性给出 $\alpha = \sup L$ 。

现在证明 $\alpha = \inf B$ 。先证明 $\alpha$ 是 $B$ 的下界，即每个
$x \in B$ 都满足 $\alpha \le x$ 。书上用反证的说法：若 $\gamma < \alpha$ ，
则 $\gamma$ 不是 $L$ 的上界，所以存在某个下界 $\ell \in L$ 使
$\gamma < \ell$ 。下界 $\ell$ 不超过 $B$ 的任何元素，因此 $\gamma$
也不能是 $B$ 的元素。每个小于 $\alpha$ 的数都落在 $B$ 外面，
所以 $B$ 的元素全都 $\ge \alpha$ 。

形式证明用等价的直接说法，少绕一圈。$x \in B$ 时，$x$ 自己就是
$L$ 的一个上界（每个下界都 $\le x$ ）。而 $\alpha$ 是 $L$ 的最小上界，
所以 $\alpha \le x$ 。Lean 的这一行就是这句话：

```lean
have hlow : β ∈ lowerBounds B := by
  intro x hx
  exact hβ_least (fun ℓ hℓ => hℓ hx)
```

`hβ_least` 说 $\beta$ 不超过 $L$ 的任何上界；括号里的函数证明
$x$ 是这样一个上界。

再证明 $\alpha$ 是最大的下界。$\alpha$ 已经是 $L$ 的上界，所以
$L$ 的每个元素都 $\le \alpha$ 。也就是说，任何 $\beta > \alpha$ 都不在
$L$ 里，即任何 $\beta > \alpha$ 都不是 $B$ 的下界。这正是下确界定义
的第二段。

Coq 把同一证明放在实数上，存在性来自标准库引理 `completeness` ：
非空且有上界的实数子集有上确界。在 Rocq 9.1 里这条引理是从柯西实数
的构造证出来的，内容与定义 4.10 一致。把它用在“$B$ 的下界”这个谓词上：

```coq
Lemma glb_from_lub (B : R -> Prop) :
  (exists x, B x) ->
  (exists m, is_lower_bound B m) ->
  exists alpha,
    is_lub (is_lower_bound B) alpha /\ is_glb B alpha.
Proof.
  intros [b0 Hb0] [m0 Hm0].
  assert (HL : bound (is_lower_bound B)).
  { exists b0. intros y Hy. apply Hy. exact Hb0. }
  destruct (completeness (is_lower_bound B) HL HLne) as [alpha Halpha].
  exists alpha. split.
  - exact Halpha.
  - destruct Halpha as [Hub Hleast]. split.
    + intros x Hx. apply Hleast. intros y Hy. apply Hy. exact Hx.
    + intros gamma Hgamma. apply Hub. exact Hgamma.
Qed.
```

`bound` 是“有上界”。`b0` 是 $B$ 的一个元素，它压住每一个下界，
所以下界集有上界。`HLne` 是下界集非空。`destruct completeness`
取出下界集的上确界 `alpha` 。最后的两支：`Hleast` 证明 $\alpha$
不超过下界集的任何上界，而 $B$ 的元素都是这样的上界，所以 $\alpha$
是 $B$ 的下界；`Hub` 证明每个下界都 $\le \alpha$ ，所以 $\alpha$ 是
最大下界。`is_glb` 的定义与书上一致：是下界，并且任何别的下界都
不超过它。

Lean 把存在性留成假设 `hcomplete` ，因此定理对任何线性序都成立，
不绑定实数：

```lean
theorem glb_from_lub {α : Type*} [LinearOrder α]
    (hcomplete : ∀ s : Set α, s.Nonempty → BddAbove s → ∃ a, IsLUB s a)
    {B : Set α} (hne : B.Nonempty) (hbd : BddBelow B) :
    ∃ β, IsLUB (lowerBounds B) β ∧ IsGLB B β
```

实数满足这个假设：`Real.isLUB_sSup` 说非空有上界集的 `sSup` 就是
它的上确界。代进去就得到“$\mathbb{R}$ 的每个非空有下界子集都有下确界”。
Isabelle 的 `glb_from_lub` 同样把完备性留成假设，`real_glb_exists`
再用 `cSup_upper`（元素不超过 `Sup` ）和 `cSup_least`（`Sup` 不超过
任何上界）证明实数满足假设。图 4.1 里 $L$ 画在左边、$B$ 画在右边、
$\alpha$ 夹在中间：比 $\alpha$ 小的 $\gamma$ 掉进 $L$ 的左侧因而进不了
$B$ ，比 $\alpha$ 大的点则不再是下界。形式证明没有画这张图，
`hlow` 与 `hβ_ub` 两行就是图上的两段。

## 3.11 定理 4.13：把书上的空填完

反过来也成立。原书把证明留成与 4.12 对称的填空，这里补全。

**定理 4.13.** 设 $S$ 具有最大下界性。则 $S$ 具有最小上界性。
若 $U$ 是 $B$ 的全体上界，$B$ 非空且有上界，则 $\sup B = \inf U$ 。

$U$ 非空，因为 $B$ 有上界。$U$ 的每个元素都 $\ge B$ 的每个元素，
所以 $B$ 的每个元素都是 $U$ 的下界。$B$ 非空，故 $U$ 至少有一个下界。
最大下界性给出 $\alpha = \inf U$ 。

若 $\gamma > \alpha$ ，则 $\gamma$ 不是 $U$ 的下界，所以有某个上界
$u \in U$ 满足 $u < \gamma$ 。这个 $u$ 已经把 $B$ 全部压在下面，
因此 $\gamma \notin B$ 。每个大于 $\alpha$ 的数都在 $B$ 外面，
所以 $\alpha$ 是 $B$ 的上界，即 $\alpha \in U$ 。又因为 $\alpha$ 是
$U$ 的下界，$U$ 的元素全都 $\ge \alpha$ 。于是任何 $\beta < \alpha$
都不在 $U$ 里，也就是说任何 $\beta < \alpha$ 都不是 $B$ 的上界。
因此 $\alpha = \sup B$ 。

直接写法与 4.12 对称。$x \in B$ 时，$x$ 是 $U$ 的一个下界
（每个上界都 $\ge x$ ），而 $\alpha$ 是 $U$ 的最大下界，所以
$x \le \alpha$ 。Lean 的 `lub_from_glb` 就是这对称的一段：

```lean
have hup : β ∈ upperBounds B := by
  intro x hx
  exact hβ_great (fun u hu => hu hx)
exact ⟨β, ⟨hβ_lb, hβ_great⟩, ⟨hup, hβ_lb⟩⟩
```

`hβ_great` 说 $\beta$ 把 $U$ 的每个下界都压在上面；括号里证明
$x \in B$ 是 $U$ 的下界。返回值的两半分别是“$\beta$ 是上界集的下确界”
和“$\beta$ 是 $B$ 的上确界”。

两条定理合起来：在一个有序集里，最小上界性与最大下界性是同一件事。
只把其中一条当作对实数的要求就够了。习惯上要求的是最小上界性，
下确界用定理 4.12 免费得到。原书把 $\sup E$ 读作 “soupy”，只是帮助
记忆；定义的用法是上面这两段，不依赖这个绰号。

## 3.12 Agda：有限集上，上确界就是最大值

无限集的上确界依赖最小上界性，而最小上界性在构造数学里不是免费的：
它断言某个数存在，却不给出计算它的程序。Agda 通道因此不去假装证明
$\mathbb{R}$ 的完备性。它证明的是定理 4.9 在有限集上的构造版本：
非空有限集的最大值就是它的上确界，而且这个最大值是算得出来的。

自然数列表的最大值是右折叠取 $\sqcup$ ，空列表约定为 $0$ ：

```agda
maxl : List ℕ → ℕ
maxl = foldr _⊔_ 0
```

上界性对成员关系做归纳。成员在表头时，`m≤m⊔n` 说头不超过
“头与尾部最大值的较大者”。成员在表尾时，归纳假设给出它不超过
尾部的最大值，再由 `m≤n⊔m` 知道尾部最大值不超过全体的最大值，
`≤-trans` 把两步接上：

```agda
maxl-upper : ∀ {x xs} → x ∈ xs → x ≤ maxl xs
maxl-upper (here refl) = m≤m⊔n _ _
maxl-upper (there p)  = ≤-trans (maxl-upper p) (m≤n⊔m _ _)
```

最大值自己也是成员，但要排除空列表。空列表的 `maxl` 是 $0$ ，
而 $0$ 并不属于空列表——这就是 3.4 节的空集陷阱。前提
$0 < \mathrm{maxl}\ xs$ 把空列表挡在外面。证明按最大值落在头还是
落在尾分叉，`⊔-sel` 说 $x \sqcup \mathrm{maxl}\ xs$ 要么等于 $x$ ，
要么等于尾部最大值：

```agda
maxl-mem : ∀ xs → 0 < maxl xs → maxl xs ∈ xs
maxl-mem (x ∷ xs) h with x ⊔ maxl xs | ⊔-sel x (maxl xs)
... | .x         | inj₁ refl = here refl
... | .(maxl xs) | inj₂ refl = there (maxl-mem xs h)
```

`with` 同时抽象目标和前提 `h` 的类型。第一支里最大值等于表头，
成员证据就是 `here` 。第二支里最大值等于尾部的最大值，归纳假设
给出它属于尾部，再套一层 `there` 。两支合起来，`maxl-is-sup`
说：只要最大值不是那个空列表的占位 $0$ ，它就同时是上界又是元素。
按定理 4.9，它就是这个有限集的上确界。

计算通道里的 `max(traj)` 与 Prolog 的 `rmax` 是同一事实的有限核验：
从 $1$ 出发的八步轨迹单调递增，最大值等于末项，并且末项压住每一项。
有限集的上确界总在集合内部。无限集的上确界可以站在外面，那一步
超出了构造性的列表折叠，也超出了任何有限循环。

## 3.13 本章验证清单

- `examples/lean/Realanalysis/Ch03Sup.lean`：两条 $q$ 恒等式、
  上确界唯一、开区间、定理 4.9、例 4.8 的 $\{1/(n+1)\}$ 与
  $\{1 - 1/(n+1)\}$ 、$\mathbb{Q}$ 没有最小上界性、定理 4.12 与 4.13。
- `examples/isabelle/RA03/Sup.thy`：有序域上的 $q$ 构造、$\sqrt{2}$
  的下降证明、`hole_no_lub` 、自定义的 `is_lub` / `is_glb` 、
  定理 4.12 以及实数满足其假设。
- `examples/coq/Ch03_sup.v`：实数上的去分母证明、`is_lub` 的唯一性、
  定理 4.9 的两个方向、用 `completeness` 证明定理 4.12。
- `examples/agda/Ch03_sup.agda`：有限列表的最大值是上确界。
- `examples/julia/03_sup.jl`、`examples/python/03_sup.py`、
  `examples/prolog/03_sup.pl`：双向 $q$ 迭代的精确有理轨迹、
  有限最大值、两个序列值域的截断上确界、中点论证的数值核对。

复验：`pwsh -NoProfile -Command '& ./build.ps1 -Chapter 03'`。

## 3.14 接下来

最小上界性回答了“实数比有理数多了什么”。它还没有回答“这些数如何
做加减乘除”。下一章把实数看成一个域：加法与乘法各有单位元和逆元，
分配律把两者连起来，序与运算要互相配合（正数之和、正数之积仍是正数）。
有了域，才能从最小上界性推出阿基米德性质、有理数的稠密，以及
每个正数都有平方根——第 3.8 节末尾借用的那个 $\sqrt{2}$ ，到那时
才被正式造出来。

上一章：[02 集合论](02-sets.md) · 下一章：[04 实数域：域公理](04-field.md) · [返回目录](../README.md)
