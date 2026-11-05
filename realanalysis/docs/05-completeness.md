# 第 05 章 实数域（下）：完备性的三大推论

> 对应原书第 5 章的后半。上一章把实数定义成“包含 $\mathbb{Q}$ 的有序域，
> 并且具有最小上界性”。本章从这条性质推出三件事：阿基米德性质、有理数
> （以及无理数）在实数中的稠密、每个正数都有正的 $n$ 次方根。压轴是把
> 第 03 章那个在 $\mathbb{Q}$ 里没有上确界的集合，在 $\mathbb{R}$ 里补上端点
> $\sqrt{2}$ 。

## 5.1 定理 5.5：阿基米德性质

**定理。** 对任意实数 $x, y$ ，若 $x > 0$ ，则存在自然数 $n$ 使

$$
n x > y .
$$

取 $x = 1$ ，得到常用推论：任意实数都被某个自然数超过。

$\mathbb{Q}$ 上这件事几乎是算术。设 $x = a/b$ ，$y = c/d$ ，其中
$a, b, c, d$ 是正整数（$y \le 0$ 时取 $n = 1$ 即可）。令 $n = 2bc$ ，则

$$
n x = 2bc \cdot \frac{a}{b} = 2ac = 2ad \cdot \frac{c}{d} = 2ad\, y > y .
$$

实数没有这种“分子分母”表示。证明要动用最小上界性，而且是反证。

### 思考过程

令 $A = \{ nx \mid n \in \mathbb{N} \}$ 。要证 $A$ 里有大于 $y$ 的元素。
假设没有，则 $y$ 是 $A$ 的上界。$A$ 非空（至少含 $0 \cdot x = 0$ ，或
$1 \cdot x = x$ ，视自然数是否含 $0$ 而定），于是最小上界性给出
$\alpha = \sup A$ 。

上确界的定义说：任何严格小于 $\alpha$ 的数都不是上界。取
$\gamma = \alpha - x$ 。因为 $x > 0$ ，有 $\gamma < \alpha$ ，所以 $\gamma$
不是上界：存在某个 $m$ 使 $\alpha - x < m x$ ，即

$$
\alpha < (m + 1) x .
$$

但 $(m + 1)x \in A$ ，而 $\alpha$ 是 $A$ 的上界，矛盾。因此假设不成立。

### 形式证明

Lean（`examples/lean/Realanalysis/Ch05Completeness.lean`）把这段写成
`archimedean_from_lub` ：

```lean
theorem archimedean_from_lub (x y : ℝ) (hx : 0 < x) :
    ∃ n : ℕ, y < (n : ℝ) * x := by
  by_contra! h
  let A : Set ℝ := range fun n : ℕ => (n : ℝ) * x
  have hne : A.Nonempty := ⟨0, ⟨0, by simp [A]⟩⟩
  have hbdd : BddAbove A := ⟨y, by
    rintro _ ⟨n, rfl⟩
    exact h n⟩
  set α := sSup A
  have hα : IsLUB A α := Real.isLUB_sSup hne hbdd
  ...
```

`by_contra! h` 把否定推到“每个 $n$ 都满足 $n x \le y$ ”。`BddAbove A`
用 $y$ 作证。`Real.isLUB_sSup` 是第 04 章已经用过的完备性定理：非空有上界
集的 `sSup` 就是上确界。接着证明 $\alpha - x$ 不是上界，取出
$\alpha - x < m x$ ，再推出 $\alpha < (m+1)x \in A$ ，与 `hα.1`（上界性）
矛盾。

同一文件里的 `archimedean_mul` 是库定理路线：对 $y/x$ 应用
`exists_nat_gt` ，再乘回 $x$ 。两条定理结论相同；原书强调的是“从最小
上界性推出来”那一条。Isabelle 的 `archimedean_mul` 走库定理
`reals_Archimedean2` ；Coq 从标准库的 `archimed`（上取整）出发，对
$y/x$ 取 `up` ，再分上取整是否非负两种情形。

计算通道给一个有理数上的见证。Python：

```python
def arch_witness(x, y):
    assert x > 0
    n = int(y / x) + 1
    assert n * x > y
    return n

assert arch_witness(Fraction(1, 3), Fraction(10)) == 31
```

$31 \cdot \frac{1}{3} = \frac{31}{3} > 10$ 。这是有理数情形的直接构造，
对应原书用分子分母写出 $n$ 的那一段。

## 5.2 定理 5.6：有理数在实数中稠密

**定理。** 若 $x < y$ 是实数，则存在有理数 $p$ 使 $x < p < y$ 。

先回顾第 04 章的中点：$z = (x + y)/2$ 是夹在中间的实数，所以 $\mathbb{R}$
自己对 $\mathbb{R}$ 稠密。两个有理数的中点仍是有理数，所以 $\mathbb{Q}$
对自己也稠密。自然数不稠密：$2$ 与 $3$ 之间没有自然数。本定理说的是更强
的事：任意两个**实数**之间都有**有理数**。

一旦有了一个 $p$ ，就可以在 $(x, p)$ 里再找一个，如此反复，所以区间里
实际上有无穷多个有理数。开区间、闭区间与有理数的交都是无限集。

### 证明结构

目标是找到整数 $m, n$ （$n > 0$ ）使

$$
x < \frac{m}{n} < y .
$$

分两步，都用阿基米德性质。

**第一步：选足够密的网格。** 分数 $1/n, 2/n, 3/n, \ldots$ 的间距是
$1/n$ 。要让间距小于区间长度，需要 $1/n < y - x$ ，即

$$
n(y - x) > 1 .
$$

$y - x > 0$ ，阿基米德性质给出这样的自然数 $n$ 。顺带得到
$ny > 1 + nx$ ，后面会用到。

**第二步：捕获 $nx$ 。** 要找整数 $m$ 使 $nx < m$ 且 $m$ 尽可能小，
也就是

$$
m - 1 \le nx < m .
$$

这是“把 $nx$ 夹在两个相邻整数之间”。分三种情形。

- 若 $nx > 0$ ，集合 $\{ m_1 \in \mathbb{N} \mid m_1 > nx \}$ 非空
  （再一次阿基米德，取 $x = 1$ ，$y = nx$ ）。良序原理给出最小元 $m$ ，
  于是 $m - 1 \le nx < m$ 。
- 若 $nx = 0$ ，取 $m = 1$ 。
- 若 $nx < 0$ ，对 $-nx$ 用第一种情形，再按端点是否相等调整符号。

合起来：$nx < m \le 1 + nx$ 。与第一步的 $1 + nx < ny$ 串联：

$$
nx < m \le 1 + nx < ny .
$$

$n > 0$ ，两边除以 $n$ 得到 $x < m/n < y$ 。

### Coq 把构造写全了

Coq 通道（`examples/coq/Ch05_completeness.v`）的 `rat_dense` 几乎是
上面两步的逐行翻译。先取 $z = \mathrm{up}(1/(y-x))$ ，验证
$z \cdot (y - x) > 1$ ：

```coq
destruct (archimed (1 / (y - x))) as [hz_gt _].
set (z := up (1 / (y - x))) in *.
...
assert (hzd : 1 < IZR z * (y - x)).
```

再取 $m = \mathrm{up}(z \cdot x)$ ，得到 $zx < m$ 且 $m - zx \le 1$ 。
两边除以 $z$ 后：

```coq
assert (hleft : x < IZR m / IZR z).
assert (hright1 : IZR m / IZR z <= x + 1 / IZR z).
assert (hright2 : 1 / IZR z < y - x).
exists (Qmake m (Z.to_pos z)).
```

`hright1` 与 `hright2` 合起来就是 $m/z < y$ 。有理数用 `Qmake m (Z.to_pos z)`
组装，`Q2R` 嵌进实数。这是本章形式化里最完整的一段“纸上证明 → 机器证明”
对照。

Lean 与 Isabelle 引用库定理 `exists_rat_btwn` / `Rats_dense_in_real` ，
内部就是同一套阿基米德加取整。计算通道给出可运行的构造。Julia：

```julia
function rational_between(x::Float64, y::Float64)
    @assert x < y
    n = ceil(Int, 2 / (y - x))            # 1/n < (y-x)/2
    m = floor(Int, x * n) + 1             # m-1 ≤ nx < m
    r = m // n
    @assert x < r < y
    return r
end
```

这里取 $n$ 时用了更强一点的 $1/n < (y-x)/2$ ，给浮点误差留出余地；
数学上 $1/n < y - x$ 就够。对 $1.4142135 < 1.4142136$ 这样的窄区间，
脚本会打印出夹在中间的那个分数。

## 5.3 推论 5.7：无理数也稠密

**推论。** 若 $x < y$ ，则存在无理数 $p$ 使 $x < p < y$ 。

原书构造：令 $a = x/\sqrt{2}$ ，$b = y/\sqrt{2}$ 。由定理 5.6 存在有理数
$q$ 使 $a < q < b$ 。于是

$$
x < \sqrt{2}\, q < y .
$$

$p = \sqrt{2}\, q$ 是无理数：若它是有理数且 $q \ne 0$ ，则
$\sqrt{2} = p/q$ 是有理数，与第 00 章矛盾；若 $q = 0$ ，则 $p = 0$ 是有理数，
但此时 $a < 0 < b$ ，可以改取别的有理数（例如再稠密一次，避开零），或换
一种构造。

mathlib 的 `exists_irrational_btwn` 用等价但更省事的写法：在
$x - \sqrt{2}$ 与 $y - \sqrt{2}$ 之间取有理数 $q$ ，令 $p = q + \sqrt{2}$ 。
$p$ 无理，因为有理数减有理数仍有理，而 $\sqrt{2}$ 无理。Lean 直接引用：

```lean
example (a b : ℝ) (h : a < b) : ∃ p : ℝ, Irrational p ∧ a < p ∧ p < b :=
  exists_irrational_btwn h
```

两种构造都依赖“$\sqrt{2}$ 已经是一个实数”。这正是下一节要保证的事；
在逻辑顺序上，稠密性的有理数部分只需要阿基米德，无理数部分需要根的
存在性。原书把推论放在根的定理之前，是因为 $\sqrt{2}$ 的存在性可以
先当作第 03 章的预告来用；严格的依赖是：先有定理 5.8（至少平方根），
再有推论 5.7。

## 5.4 定理 5.8：正实数的正 $n$ 次方根

**定理。** 对任意自然数 $n \ge 1$ 与任意正实数 $x$ ，存在唯一的正实数
$y$ 使 $y^n = x$ 。偶次方根在实数里还有一个负的对应 $-y$ ；定理断言的是
**唯一的正根**。

### 唯一性

设 $y_1, y_2 > 0$ ，$y_1^n = y_2^n = x$ ，且 $y_1 \ne y_2$ 。不妨
$y_1 < y_2$ 。正数的幂函数严格递增，故 $y_1^n < y_2^n$ ，即 $x < x$ ，
矛盾。Lean 对平方根写出：

```lean
theorem pos_sqrt_unique (y₁ y₂ : ℝ) (hy₁ : 0 < y₁) (hy₂ : 0 < y₂)
    (h₁ : y₁ ^ 2 = 2) (h₂ : y₂ ^ 2 = 2) : y₁ = y₂ := by
  apply le_antisymm
  · by_contra! hlt
    have : y₁ ^ 2 < y₂ ^ 2 :=
      pow_lt_pow_left₀ hlt hy₁.le (by norm_num : (2 : ℕ) ≠ 0)
    linarith
  ...
```

### 存在性：集合与上确界

令

$$
E = \{ t \in \mathbb{R} \mid t > 0,\ t^n < x \}.
$$

不能用 $\sqrt[n]{x}$ 来定义 $E$ ，因为那正是要造的东西。先验证 $E$
非空且有上界，从而 $\alpha = \sup E$ 存在。

非空：取 $t = x/(x+1)$ 。则 $0 < t < 1$ （因为 $x < x + 1$ ），故
$t^n \le t$ ；又 $t < x$ （因为 $x < x + x^2 = x(x+1)$ ，两边除以
$x+1$ ），所以 $t^n < x$ ，$t \in E$ 。

有上界：取 $u = x + 1$ 。若 $t > u$ ，则 $t > 1$ ，故 $t^n \ge t > u > x$ ，
$t \notin E$ 。因此 $u$ 是上界。

最小上界性给出 $y = \sup E$ 。下面证明 $y^n = x$ ，方法是排除
$y^n < x$ 与 $y^n > x$ 。

### 关键不等式

对 $0 < a < b$ ，

$$
b^n - a^n = (b - a)\sum_{k=1}^{n} b^{n-k} a^{k-1}
< (b - a)\, n\, b^{n-1}.
$$

第二步是因为括号里每一项都 $< b^{n-1}$ （$a/b < 1$ ）。这个估计在两边
情形都会用到。

### 若 $y^n < x$

要找 $h > 0$ 使 $y + h \in E$ ，从而 $y$ 不是上界。取

$$
0 < h < \min\left\{1,\ \frac{x - y^n}{n(y+1)^{n-1}}\right\}.
$$

分母为正，是因为假设 $y^n < x$ 。于是

$$
(y + h)^n - y^n < h\, n\, (y + h)^{n-1} < h\, n\, (y + 1)^{n-1} < x - y^n,
$$

故 $(y + h)^n < x$ ，$y + h \in E$ ，矛盾。所以 $y^n \ge x$ 。

### 若 $y^n > x$

令

$$
k = \frac{y^n - x}{n y^{n-1}}.
$$

则 $0 < k < y$ （分子正，且 $k < y/n \le y$ ）。对任意 $t > y - k$ ，

$$
y^n - t^n < y^n - (y - k)^n < k\, n\, y^{n-1} = y^n - x,
$$

故 $t^n > x$ ，$t \notin E$ 。于是 $y - k$ 是上界，但小于上确界 $y$ ，
矛盾。所以 $y^n \le x$ 。

两边合起来 $y^n = x$ ，且 $y > 0$ （$E$ 里有正元，上确界至少那么大）。

### 平方根的快捷通道

一般 $n$ 的完整形式化很长。本章在证明助手里把存在性收成平方根特例：
mathlib / Isabelle / Coq 的标准库已经用完备性造好了 `sqrt` ，并证明
$(\sqrt{2})^2 = 2$ 。Lean：

```lean
example : ∃ y : ℝ, 0 < y ∧ y ^ 2 = 2 :=
  ⟨Real.sqrt 2, Real.sqrt_pos.mpr (by norm_num), Real.sq_sqrt (by norm_num)⟩
```

Isabelle 的 `sqrt_two_exists` 与 Coq 的 `sqrt_sqrt` 是同一事实。一般 $n$
的论证上面已经自包含地写完；机器验证集中在 $n = 2$ ，以及下一节的
“上确界就是 $\sqrt{2}$ ”。

### 推论 5.9：开方对乘法分配

$(\sqrt[n]{ab}) = \sqrt[n]{a}\,\sqrt[n]{b}$ （$a, b > 0$ ）。这不是域公理
的直接改写：乘法结合只说明 $(ab)^n = a^n b^n$ ，而开方是“找到 $y$ 使
$y^n = x$ ”。证明：令 $y = \sqrt[n]{a}\,\sqrt[n]{b}$ ，则

$$
y^n = (\sqrt[n]{a})^n (\sqrt[n]{b})^n = ab.
$$

正 $n$ 次方根唯一，所以 $y = \sqrt[n]{ab}$ 。

## 5.5 补洞终章：$\sup\{x \ge 0 : x^2 < 2\} = \sqrt{2}$

第 03 章证明了集合

$$
A_{\mathbb{Q}} = \{ p \in \mathbb{Q} \mid p > 0,\ p^2 < 2 \}
$$

在 $\mathbb{Q}$ 里没有上确界。现在把同一个想法放到 $\mathbb{R}$ 里：

$$
A_{\mathbb{R}} = \{ x \in \mathbb{R} \mid x \ge 0,\ x^2 < 2 \}.
$$

（含零与否不影响上确界。）定理 5.8 给出正实数 $\sqrt{2}$ 满足
$(\sqrt{2})^2 = 2$ 。断言：

$$
\sup A_{\mathbb{R}} = \sqrt{2}.
$$

**上界性。** 若 $x \ge 0$ 且 $x^2 < 2 = (\sqrt{2})^2$ ，则 $x < \sqrt{2}$
（正数的平方严格递增）。Lean 用 `Real.le_sqrt` ：

```lean
rintro x ⟨h0, hx2⟩
rw [Real.le_sqrt h0 (by norm_num : (0 : ℝ) ≤ 2)]
linarith
```

**最小性。** 设 $b$ 是上界且 $b < \sqrt{2}$ 。若 $b < 0$ ，则 $0 \in A_{\mathbb{R}}$
已经超过 $b$ 。若 $0 \le b < \sqrt{2}$ ，取中点

$$
m = \frac{b + \sqrt{2}}{2}.
$$

则 $b < m < \sqrt{2}$ ，且 $m \ge 0$ ，故 $m^2 < (\sqrt{2})^2 = 2$ ，
$m \in A_{\mathbb{R}}$ ，与 $b$ 是上界矛盾。

这就是 `sqrt2_is_lub` 。Isabelle 证明算子等式
`Sup {x. 0 ≤ x ∧ x^2 < 2} = sqrt 2` ，反证时同样构造中点，并用
`cSup_upper` 说明中点不能超过上确界。Coq 的 `sqrt2_lub` 对 `is_lub`
谓词做同一件事，平方比较调用 `Rsqr_incrst_1` 。

第 03 章的 `q_trick_gt` / `q_trick_lt` 说明：在 $\mathbb{Q}$ 里，任何
候选上界要么还能再大一点（平方仍小于 $2$ ），要么还能再小一点（仍是
上界），要么平方恰好等于 $2$ ——而这不可能是有理数。现在 $\sqrt{2}$
作为实数站在那个位置上，两难消失了。洞被填上了。

## 5.6 完备性的算法形态：二分法

证明助手给出存在性；计算通道给出逼近。从 $[1, 2]$ 出发（$1^2 < 2 < 2^2$ ），
反复取中点：若中点平方小于 $2$ ，丢掉左半；否则丢掉右半。$k$ 步之后
区间长度恰好是 $2^{-k}$ ，左端点平方始终小于 $2$ ，右端点平方始终
$\ge 2$ 。Python：

```python
def bisect_sqrt2(k):
    a, b = Fraction(1), Fraction(2)
    for _ in range(k):
        assert a * a < 2 <= b * b
        m = (a + b) / 2
        if m * m < 2:
            a = m
        else:
            b = m
    return a, b

a40, b40 = bisect_sqrt2(40)
assert b40 - a40 == Fraction(1, 2 ** 40)
```

四十步后缺口是 $2^{-40}$ ，全程精确分数，没有浮点。阿基米德性质保证：
对任意 $\varepsilon > 0$ ，存在 $k$ 使 $2^{-k} < \varepsilon$ ，于是区间
比 $\varepsilon$ 还窄。存在性定理说极限点就是 $\sqrt{2}$ ；二分法说
我们可以算到任意精度。Julia 用 `Rational{BigInt}` 做同样的事，Prolog
用 `rdiv` 递归 `bisect_step` 。

## 5.7 Agda：最小上界性的离散影子

最小上界性断言某个实数存在，却不给出计算它的程序。构造数学里通常
不把它当作定理。Agda 通道因此证明一个离散类比：自然数上任何在某处
为真的可判定谓词，都有最小的真值点。

```agda
find-min : ∀ (P : ℕ → Bool) (b : ℕ) → P b ≡ true →
           Σ ℕ (λ n → (P n ≡ true) × (∀ m → P m ≡ true → n ≤ m))
```

对界 $b$ 归纳。若 $P\, 0$ 为真，最小点是 $0$ 。否则把谓词左移一位，
在 $b-1$ 上递归，再右移回来（`shift-min`）。实例 `P100 n = (100 ≤ᵇ n*n)`
找出第一个平方达到 $100$ 的自然数——离散世界里的“$\sqrt{100}$ 的上取整”。
这与定理 5.8 里“$E$ 的最小上界”遥相呼应，但完全可计算。

## 5.8 本章验证清单

- `examples/lean/Realanalysis/Ch05Completeness.lean`：从最小上界性推出
  阿基米德、库定理形式、有理数与无理数稠密、正平方根唯一、
  `sqrt2_is_lub` 。
- `examples/isabelle/RA05/Completeness.thy`：阿基米德、有理数稠密、
  `sqrt2_is_sup` 。
- `examples/coq/Ch05_completeness.v`：阿基米德、完整的 `rat_dense` 、
  `sqrt2_lub` 。
- `examples/agda/Ch05_completeness.agda`：可判定谓词的最小真值点。
- `examples/julia/05_completeness.jl`、`examples/python/05_completeness.py`、
  `examples/prolog/05_completeness.pl`：二分法逼近 $\sqrt{2}$ 、有理数
  稠密的构造、阿基米德见证。

复验：`pwsh -NoProfile -Command '& ./build.ps1 -Chapter 05'`。

## 5.9 接下来

实数作为有序完备域已经立住。下一章把它推广到复数与欧几里得空间
$\mathbb{R}^k$ ：内积、范数、Cauchy–Schwarz。后面的拓扑与序列，舞台
将从直线扩展到这些更高维的空间。

上一章：[04 实数域：域公理](04-field.md) · 下一章：[06 复数与欧几里得空间](06-complex.md) · [返回目录](../README.md)
