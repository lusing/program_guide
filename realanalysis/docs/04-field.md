# 第 04 章 实数域（上）：域公理

> 对应原书第 5 章的前半：域公理、哪些常见集合是域、只靠公理就能推出
> 的算术，以及有序域。上一章回答了“比有理数多出来的顺序结构是什么”。
> 这一章回答“这些数如何做加减乘除”。阿基米德性质、有理数稠密和
> 根的存在性要用到最小上界性，它们是下一章的内容；本章在定义实数
> 时把那条性质写进定义，但还不去展开它的三个推论。

## 4.1 十一条域公理

**定义 5.1.** 设 $F$ 带有两种运算：加法与乘法。若下列十一条成立，
则 $F$ 是一个域。

加法五条：

1. **A1 封闭。** $x, y \in F$ 蕴含 $x + y \in F$ 。
2. **A2 交换。** $x + y = y + x$ 。
3. **A3 结合。** $(x + y) + z = x + (y + z)$ 。
4. **A4 零元。** 存在 $0 \in F$ ，使每个 $x$ 都满足 $x + 0 = x$ 。
5. **A5 加法逆元。** 每个 $x$ 都有 $-x \in F$ ，使 $x + (-x) = 0$ 。

乘法五条：

1. **M1 封闭。** $x, y \in F$ 蕴含 $xy \in F$ 。
2. **M2 交换。** $xy = yx$ 。
3. **M3 结合。** $(xy)z = x(yz)$ 。
4. **M4 单位元。** 存在 $1 \in F$ ，$1 \ne 0$ ，使每个 $x$ 都满足 $1 \cdot x = x$ 。
5. **M5 乘法逆元。** 若 $x \ne 0$ ，则存在 $x^{-1} \in F$ 使 $x \cdot x^{-1} = 1$ 。

最后一条把两种运算焊在一起：

1. **D 分配律。** $x(y + z) = xy + xz$ 。

$1 \ne 0$ 不是装饰。若零元等于单位元，分配律会把整个集合压成一个点：
对任意 $x$ ，$x = 1 \cdot x = 0 \cdot x = 0$ （最后一步是 4.4 节要证的
$0 \cdot x = 0$ ）。所以“至少有两个元素”被写进公理，而不是事后发现。

对普通的数，交换、结合、单位元、逆元和分配律用惯了，会显得像同义反复。
封闭性往往才是需要检查的那一条：两个元素做完运算，结果还在不在这个
集合里。证明“某集合配上某两种运算构成域”，工作量通常就花在封闭性、
以及那些看起来不那么像普通数的逆元上。抽象地研究这种结构是代数学的事；
分析学只要把实数、有理数和少数几个对照物认清楚。

## 4.2 例 5.2：四个集合，三种命运

### 有理数是域

$\mathbb{Q}$ 配上通常的加法和乘法是域。交换、结合、单位元、逆元和
分配律与整数的相应定律一致，要单独写清楚的是封闭性。任意
$x, y \in \mathbb{Q}$ 都是整数之比：存在 $a, b, c, d \in \mathbb{Z}$ ，
$b \ne 0$ ，$d \ne 0$ ，使 $x = a/b$ ，$y = c/d$ 。于是

$$
x + y = \frac{a}{b} + \frac{c}{d} = \frac{ad + bc}{bd},
\qquad
xy = \frac{ac}{bd}.
$$

$bd \ne 0$ ，分子分母都是整数，所以和与积仍是有理数。加法逆元
$-a/b$ 与乘法逆元 $b/a$ （$a \ne 0$ 时）也是整数之比。

Lean（`examples/lean/Realanalysis/Ch04Field.lean`）把“每个有理数都有
这样的写法”和两条公式分开核对。代表元取约分后的分子分母：

```lean
example (x : ℚ) : ∃ a b : ℤ, b ≠ 0 ∧ x = (a : ℚ) / b :=
  ⟨x.num, x.den, by exact_mod_cast x.den_nz, (Rat.num_div_den x).symm⟩
```

`x.den_nz` 是分母不为零，`Rat.num_div_den` 说 $x$ 等于自己的分子除以分母。
通分公式是

```lean
theorem rat_add (a b c d : ℤ) (hb : b ≠ 0) (hd : d ≠ 0) :
    (a : ℚ) / b + (c : ℚ) / d = ((a * d + b * c : ℤ) : ℚ) / (b * d) := by
  field_simp
  ring
```

`field_simp` 在分母非零的前提下通分，`ring` 把剩下的多项式收成
$ad + bc$ 。乘法公式 `rat_mul` 同样两步，右边是 $(ac)/(bd)$ 。
Isabelle 的 `rat_add_formula` 与 `rat_mul_formula` 用 `field_simps`
得到同一对等式；`rat_quotient` 再用 `quotient_of` 证明任意有理数都等于
一对整数之商，分母由 `quotient_of_denom_pos` 保证为正。

计算通道在一组具体分数上把十一条里能用等式写出的那些全部跑一遍。
Python（`examples/python/04_field.py`）的样本是
$\frac{1}{2}, -\frac{3}{7}, \frac{22}{7}, 0, \frac{355}{113}$ ：

```python
assert (a + b) + c == a + (b + c)
assert (a * b) * c == a * (b * c)
assert a + b == b + a and a * b == b * a
assert a * (b + c) == a * b + a * c
assert a + 0 == a and a * 1 == a and a + (-a) == 0
if a != 0:
    assert a * (1 / a) == 1
```

`Fraction` 的运算是精确的，所以这些断言就是公理的有限实例，没有舍入。
Julia 对 `Rational{BigInt}` 做同一组检查，Prolog 的 `field_ok` 用
`rdiv` 表达结合律、交换律和分配律。样本不能代替证明——五个数的组合
盖不住所有有理数——但它们把“公理是可执行的等式”这件事钉死了。一般证明
是上面的通分。

### 自然数不是域，整数也不是域

$\mathbb{N}$ 没有负元。$1$ 的加法逆元应满足 $1 + n = 0$ ，自然数里
没有这样的 $n$ 。Lean 用整型线性算术一次判掉：

```lean
example : ¬ ∃ n : ℕ, 1 + n = 0 := by omega
```

$\mathbb{Z}$ 有加法逆元，乘法逆元却几乎都缺。原书写成“每个整数都没有
乘法逆元”，编者注把这句话收紧了：除了 $\pm 1$ ，其余整数都没有。
$1 \cdot 1 = 1$ ，$(-1) \cdot (-1) = 1$ ，所以 $\pm 1$ 是自己的逆元。
除此之外都不行。若 $z \cdot w = 1$ ，则 $|z| \cdot |w| = 1$ 。两个正整数
之积为 $1$ ，只可能都是 $1$ ，所以 $|z| = 1$ ，即 $z = 1$ 或 $z = -1$ 。
Lean 的 `int_unit_iff` 就是这个充要条件：先由 `isUnit_of_mul_eq_one`
得到 $z$ 是单位，再用 `Int.isUnit_iff_abs_eq` 化成 $|z| = 1$ ，然后按
符号拆开。Isabelle 直接调用库里的 `zmult_eq_1_iff` ：

```isabelle
lemma int_units: "(∃w::int. z * w = 1) ⟷ (z = 1 ∨ z = -1)"
  by (auto simp: zmult_eq_1_iff)
```

特别地，$2$ 没有整数逆元。这是原书用来否定“$\mathbb{Z}$ 是域”的那一个
反例，三条证明通道各写了一句：Lean 的 `omega` 、Isabelle 的 `presburger` 、
Coq 的 `lia` 。它们都是整数线性算术的决策过程，看见 $2z = 1$ 就知道
没有整数解。计算通道则在 $-1000$ 到 $1000$ 里枚举，确认这段区间内没有
候选；枚举当然盖不住全部整数，上面的决策过程才是完整的否定。

### 模 $5$ 的剩余是域

集合 $S = \{0, 1, 2, 3, 4\}$ 配上普通加法不是域：$2 + 3 = 5 \notin S$ ，
$2 \cdot 3 = 6 \notin S$ 。把运算改成“先按普通办法算，再取除以 $5$ 的
余数”，封闭性就回来了。这个结构记作 $\mathbb{Z}_5$ 。此时

$$
2 + 3 = 5 \equiv 0, \qquad 2 \cdot 3 = 6 \equiv 1 \pmod{5}.
$$

第二式说 $2$ 的乘法逆元是 $3$ ，尽管 $2$ 和 $3$ 在整数里都不可逆。
其余非零元：$1 \cdot 1 = 1$ ，$3 \cdot 2 = 1$ ，$4 \cdot 4 = 16 \equiv 1$ 。
$4 \equiv -1$ ，所以 $4$ 和 $-1$ 是同一个剩余，它的平方是 $1$ ，与整数
里 $(-1)^2 = 1$ 是同一件事。零仍然没有乘法逆元：任何剩余乘 $0$ 都是 $0$ ，
到不了 $1$ 。这与 M5 的前提“$x \ne 0$ ”一致。

五个元素的全部三元组只有 $5^3 = 125$ 个，结合律、交换律和分配律可以
穷尽，不必抽样。Python 的循环就是这个穷举，并单独记下书上的两个等式：

```python
assert z5add(2, 3) == 0 and z5mul(2, 3) == 1
for a in range(1, 5):
    assert any(z5mul(a, b) == 1 for b in range(1, 5))
```

Julia 与 Prolog 的 `z5_laws` / `z5_inverses` 做同一张加法表和乘法表。
Lean 不枚举三元组，而是让类型 `ZMod 5` 上的可判定等式一次判完：

```lean
example : (2 + 3 : ZMod 5) = 0 := by decide
example : (2 * 3 : ZMod 5) = 1 := by decide
example : ∀ x : ZMod 5, x ≠ 0 → ∃ y : ZMod 5, x * y = 1 := by decide
```

`decide` 在有限类型上把命题化成计算。这里它同时核对了“$2$ 的逆元是 $3$ ”
和“每个非零剩余都有逆元”。$\mathbb{Z}_5$ 看起来怪，只是因为它的加法
把 $5$ 卷回 $0$ ；十一条公理它都满足，所以它是域。域不必是无限的，
也不必是实数的子集。

## 4.3 浮点连结合律都没有

机器上的 `Float64` 常被误当成实数。它连 A3 都不满足。取 $1$ 与 $10^{100}$ ：

```python
left = (1.0 + -1e100) + 1e100
right = 1.0 + (-1e100 + 1e100)
assert left != right
```

左边先算 $1 + (-10^{100})$ 。$10^{100}$ 的数量级远大于 $1$ ，双精度在
这个量级上的间距已经比 $1$ 大，加 $1$ 不改变那个浮点数，结果仍是
$-10^{100}$ ；再加回 $10^{100}$ 得到 $0$ 。右边先把相反数抵消，得到 $0$ ，
再加上 $1$ 得到 $1$ 。同三个数，两种加括号，两个结果。Julia 打印的就是
这对 $0$ 与 $1$ ；Prolog 用 `verify_not` 断言两个浮点表达式不相等。

所以浮点加法不是结合的，浮点数不是域。第 00 章用 $0.1 + 0.2$ 展示过
舍入；这里的反例更厉害，它破坏的是公理本身，不是某一位小数。精确分数
与 $\mathbb{Z}_5$ 把同一组公理保住了，浮点没有。

## 4.4 只用公理能推出的几条

原书列了三条，并说“多使用几次域公理就可以证明”，把步骤留给读者。
下面全部写出来。Agda 通道（`examples/agda/Ch04_fieldaxioms.agda`）
不引用任何代数库：它只假设一个类型、两种运算、零元、取负，以及
加法交换群的定律和右分配律，然后手工推出 $0 \cdot x = 0$ 与 $-(-x) = x$ 。

先记一条以后反复用的事实：加法逆元唯一。若 $x + y = 0$ 且
$x + (-x) = 0$ ，则

$$
y = y + 0 = y + \bigl(x + (-x)\bigr) = (y + x) + (-x) = 0 + (-x) = -x.
$$

中间用了单位元、结合律和交换律（把 $y + x$ 换成 $x + y$ ）。因此“满足
$x + y = 0$ 的 $y$ ”只有 $-x$ 一个。

**$0 \cdot x = 0$ 。** 想法是把 $0 \cdot x$ 写成它自己加上零，再把这个零
拆成 $(0 \cdot x) + \bigl(-(0 \cdot x)\bigr)$ ，用结合律把两个 $0 \cdot x$
凑到一起，分配律把它们收成 $(0 + 0) \cdot x$ ，而 $0 + 0 = 0$ ，于是
剩下的就是一个元素加上它自己的逆元。Agda 的等式链与这个顺序一致，
每一行的引理都写在 $\equiv\langle\;\rangle$ 里。引理的方向往往和
我们要走的方向相反，所以大量使用 `sym` ：

```agda
zero-absorbs : ∀ a → 0f * a ≡ 0f
zero-absorbs a = begin
  0f * a
    ≡⟨ sym (+-identityʳ _) ⟩
  (0f * a) + 0f
    ≡⟨ cong ((0f * a) +_) (sym (+-inverseʳ _)) ⟩
  (0f * a) + ((0f * a) + neg (0f * a))
    ≡⟨ sym (+-assoc _ _ _) ⟩
  ((0f * a) + (0f * a)) + neg (0f * a)
    ≡⟨ cong (_+ neg (0f * a)) (sym (*-distribʳ 0f 0f a)) ⟩
  ((0f + 0f) * a) + neg (0f * a)
    ≡⟨ cong (λ t → (t * a) + neg (0f * a)) (+-identityˡ 0f) ⟩
  (0f * a) + neg (0f * a)
    ≡⟨ +-inverseʳ _ ⟩
  0f
  ∎
```

逐行对应：

1. 右单位元的反向：在右边加上 $0$ 。右单位元本身不是假设，它由左单位元
   加交换律得到，即上面的 `+-identityʳ` 。
2. 把这个 $0$ 换成 $(0 \cdot a) + \bigl(-(0 \cdot a)\bigr)$ 。`cong` 表示
   只改写加法的右半边。
3. 结合律的反向，把括号从右边移到左边。
4. 右分配律的反向：$(0 \cdot a) + (0 \cdot a) = (0 + 0) \cdot a$ 。
   模块只假设了右分配 $(a + b) \cdot c = a \cdot c + b \cdot c$ 。左分配
   可以由交换律转出来，这一条证明用不到。
5. $0 + 0 = 0$ ，左单位元。
6. 一个元素加上自己的逆元是 $0$ 。

Lean、Isabelle、Coq 里的同一事实是库定理或 `ring` 决策过程：
`zero_mul x` 、`by simp` 、`ring` 。`ring` 把域公理编排成一条改写序列，
结论与上面六步相同，只是步骤被决策过程折叠了。Agda 把折叠打开，
是这一节要看的证明。

**$-(-x) = x$ 。** $-x$ 的逆元按定义满足 $(-x) + \bigl(-(-x)\bigr) = 0$ 。
但 $x$ 也满足 $(-x) + x = 0$ （这是左逆元，由右逆元加交换律得到）。
逆元唯一，所以 $-(-x) = x$ 。Agda 不引用唯一性，而是把这段计算展开：

```agda
neg-invol : ∀ a → neg (neg a) ≡ a
neg-invol a = begin
  neg (neg a)
    ≡⟨ sym (+-identityʳ _) ⟩
  neg (neg a) + 0f
    ≡⟨ cong (neg (neg a) +_) (sym (+-inverseˡ a)) ⟩
  neg (neg a) + (neg a + a)
    ≡⟨ sym (+-assoc _ _ _) ⟩
  (neg (neg a) + neg a) + a
    ≡⟨ cong (_+ a) (+-inverseˡ (neg a)) ⟩
  0f + a
    ≡⟨ +-identityˡ a ⟩
  a
  ∎
```

第二步把 $0$ 换成 $(-a) + a$ ，用的是左逆元 `+-inverseˡ` 。第四步
$\bigl(-(-a)\bigr) + (-a) = 0$ ，又是左逆元，作用在 $-a$ 上。最后
左单位元把 $0 + a$ 收成 $a$ 。Lean 的 `neg_neg` 、Coq 的 `ring` 、
Isabelle 的 `simp` 是同一结论的打包形式。

**$(-1) \cdot x = -x$ 。** 计算

$$
(-1) \cdot x + x = (-1) \cdot x + 1 \cdot x = \bigl((-1) + 1\bigr) \cdot x = 0 \cdot x = 0.
$$

这里用了右分配（或交换后的左分配）、$1$ 是单位元、$(-1) + 1 = 0$ ，
以及刚刚证过的 $0 \cdot x = 0$ 。于是 $(-1) \cdot x$ 是 $x$ 的一个加法
逆元。逆元唯一，它等于 $-x$ 。Coq 把这句交给 `ring` ：

```coq
Example neg_one_mul : forall x : R, (-1) * x = - x.
Proof. intro x. ring. Qed.
```

**乘法逆元唯一。** 若 $x \ne 0$ 且 $xy = 1$ ，则 $y = x^{-1}$ 。
两边同乘 $x^{-1}$ ，或直接写

$$
y = \frac{x y}{x} = \frac{1}{x}.
$$

第一段因为 $x \ne 0$ ，第二段代入 $xy = 1$ 。Isabelle 把这两段写明：

```isabelle
have "y = (x * y) / x" using assms(1) by (simp add: field_simps)
also have "... = 1 / x" using assms(2) by simp
```

Coq 用 `field` 做第一段，分母非零的副作用由 `hx` 解除，再用 `rewrite h`
代入：

```coq
Example inv_unique (x y : R) (hx : x <> 0) (h : x * y = 1) : y = 1 / x.
Proof.
  replace y with (x * y / x) by (field; exact hx).
  rewrite h. reflexivity.
Qed.
```

Lean 的版本是 `field_simp` 之后 `linarith` ：通分把目标化成
$x y = 1$ ，这正是假设。三条通道是同一次除法，自动化的粒度不同。

## 4.5 有序域

**定义 5.3.** 有序域是一个域，它同时是有序集，并且运算与顺序相容：

- **O1.** 若 $y < z$ ，则对每个 $x$ 都有 $x + y < x + z$ 。加法保持严格顺序。
- **O2.** 若 $x > 0$ 且 $y > 0$ ，则 $xy > 0$ 。正元的积仍是正元。

有序集的含义沿用上一章：三分律（$x < y$ 、$x = y$ 、$y < x$ 恰有一个成立）
和传递性。$\le$ 仍是 $<$ 的否定加等号。O1 和 O2 是新的，它们把第 03 章
的顺序和第 4.1 节的运算接上。

$\mathbb{Q}$ 与 $\mathbb{R}$ 都满足这两条。$\mathbb{Z}_5$ 是域，但做不成
有序域：它是有限的，而有序域里 $0 < 1 < 1 + 1 < 1 + 1 + 1 < \cdots$
会得到无穷多个不同元素（4.6 节证明 $0 < 1$ 之后，O1 可以不停地加 $1$ ）。
所以有限域一定不是有序域。分析学用的是有序域，不是任意的域。

## 4.6 原书留在笔记本上的证明

原书在定义 5.3 之后列举了几条推论，并建议读者自己写。这里补全。
每一步只引用域公理、O1、O2，以及 4.4 节已经证过的事实。

**平方非负。** 对任意 $x$ ，$0 \le x^2$ 。按三分律分三种情形。

- 若 $x > 0$ ，O2 直接给出 $x \cdot x > 0$ 。
- 若 $x = 0$ ，则 $x^2 = 0 \cdot 0 = 0$ 。
- 若 $x < 0$ ，则 $-x > 0$ （把 $x < 0$ 的两边加上 $-x$ ，用 O1）。
  于是 $(-x)(-x) > 0$ 。而

  $$
  (-x)(-x) = \bigl((-1) \cdot x\bigr) \bigl((-1) \cdot x\bigr)
  = \bigl((-1) \cdot (-1)\bigr) \cdot x^2.
  $$

  又 $(-1) \cdot (-1) = 1$ ：因为 4.4 节有 $(-1) \cdot x = -x$ ，取
  $x = -1$ 得 $(-1) \cdot (-1) = -(-1) = 1$ 。所以 $(-x)(-x) = x^2 > 0$ 。

三种情形都有 $x^2 \ge 0$ 。Lean 把它收成 `sq_nonneg` ，Coq 用 `nra`
一次判定 $0 \le x \cdot x$ ，Isabelle 是 `simp` 。这三个名字下面都是
上面的分情形，只是库已经做过了。

**$0 < 1$ 。** $1 = 1^2$ ，上一条给出 $1 \ge 0$ 。M4 又规定 $1 \ne 0$ ，
所以 $1 > 0$ 。Lean 的 `zero_lt_one` 与 Coq 的 `lra` 是这一句。

**正数乘进去保持不等号。** 若 $x > 0$ 且 $y < z$ ，则 $xy < xz$ 。
先把 $y < z$ 的两边加上 $-y$ ：O1 给出 $0 < z - y$ 。再对两个正数
$x$ 与 $z - y$ 用 O2：$x(z - y) > 0$ 。分配律把它写成 $xz - xy > 0$ ，
两边加上 $xy$ 得到 $xy < xz$ 。

这就是“不等式两边同乘正数，方向不变”。同乘负数会反向，因为乘上
$-1$ 相当于取相反数，而 $a < b$ 加上适当的项可以化成 $-b < -a$ 。
本章的证明只用到正数这一侧。Lean 的

```lean
example (x y z : ℝ) (hx : 0 < x) (h : y < z) : x * y < x * z :=
  mul_lt_mul_of_pos_left h hx
```

就是这条推论，`mul_lt_mul_of_pos_left` 的两个参数依次是原来的不等号
和那个正的乘数。Isabelle 的 `pos_mult_mono` 用
`mult_less_cancel_left_pos` ，名字里的 cancel 指的是同一件事的逆：
正数乘上去的不等号可以消回来。

**正数的倒数是正数，并且取倒数反转顺序。** 先证明 $x > 0$ 蕴含
$x^{-1} > 0$ 。$x^{-1} = 0$ 会给出 $x \cdot 0 = 0 = 1$ ，与 $1 \ne 0$
矛盾。若 $x^{-1} < 0$ ，则 $-x^{-1} > 0$ ，从而
$x \cdot (-x^{-1}) > 0$ ，即 $-1 > 0$ ，与 $0 < 1$ 矛盾。所以
$x^{-1} > 0$ 。

再设 $0 < x < y$ 。则 $x^{-1} > 0$ 且 $y^{-1} > 0$ ，乘积
$x^{-1} y^{-1} > 0$ 。用上一段的保序，把 $x < y$ 的两边乘上这个正数：

$$
x \cdot x^{-1} \cdot y^{-1} < y \cdot x^{-1} \cdot y^{-1},
$$

即 $y^{-1} < x^{-1}$ 。这就是 $0 < x < y$ 蕴含 $0 < 1/y < 1/x$ 。

Coq 把最后这一步写成“两边同乘正数 $xy$ ，目标变回 $x < y$ ”：

```coq
Example inv_antitone (x y : R) (hx : 0 < x) (h : x < y) : 1 / y < 1 / x.
Proof.
  assert (hy : 0 < y) by lra.
  assert (hp : 0 < x * y) by nra.
  apply (Rmult_lt_reg_r (x * y)); [exact hp |].
  replace (1 / y * (x * y)) with x by (field; assumption).
  replace (1 / x * (x * y)) with y by (field; assumption).
  exact h.
Qed.
```

`Rmult_lt_reg_r` 说两边同乘一个正数，不等号方向不变，而且这是等价
变形：要证 $1/y < 1/x$ ，只要证乘完以后的不等式。`field` 把
$(1/y) \cdot (xy)$ 收成 $x$ ，把 $(1/x) \cdot (xy)$ 收成 $y$ 。剩下的
就是假设 $x < y$ 。Lean 的 `one_div_lt_one_div_of_lt` 与 Isabelle 的
`frac_less2` 是同一条定理的库名。

**中点。** 若 $a < b$ ，令 $m = (a + b)/2$ ，则 $a < m < b$ 。
由 O1，$a < b$ 的两边加上 $a$ 得 $2a < a + b$ 。$2 = 1 + 1 > 0$ ，
所以 $1/2 > 0$ ，两边同乘 $1/2$ 得 $a < (a + b)/2$ 。另一侧把 $b$
加到 $a < b$ 的两边，再乘 $1/2$ 。Lean 与 Isabelle、Coq 都把两半交给
线性算术：

```lean
example (a b : ℝ) (h : a < b) : a < (a + b) / 2 ∧ (a + b) / 2 < b :=
  ⟨by linarith, by linarith⟩
```

原书在讨论稠密性之前先用这个中点说明：实数自己是“稠密”的，任意两个
实数之间至少还有一个实数。有理数同样如此，因为两个有理数的中点仍是
有理数（分母 $2 \ne 0$ ，4.2 节的封闭性）。自然数则不是：$2$ 与 $3$
之间没有自然数。任意两个实数之间都有有理数，是比中点更强的陈述，
它要用阿基米德性质，留到下一章。

## 4.7 定义 5.4：实数是什么

现在可以把上一章和这一章拼起来。

**定义 5.4.** 实数集 $\mathbb{R}$ 是一个有序域，它包含 $\mathbb{Q}$ ，
并且具有最小上界性：每个非空、有上界的子集都在 $\mathbb{R}$ 中有上确界。

包含 $\mathbb{Q}$ 是说每个有理数都是一个实数。最小上界性就是第 03 章
的定义 4.10。Lean 把定义的两半写成存在性：

```lean
example (q : ℚ) : ∃ x : ℝ, x = (q : ℝ) := ⟨(q : ℝ), rfl⟩

example (s : Set ℝ) (hne : s.Nonempty) (hb : BddAbove s) :
    ∃ a, IsLUB s a :=
  ⟨sSup s, Real.isLUB_sSup hne hb⟩
```

第一句是嵌入 $q \mapsto (q : \mathbb{R})$ 。第二句说 `sSup` 在集合非空
且有上界时确实给出上确界，这是 mathlib 里实数构造的定理，不是额外假设。

$\mathbb{Q}$ 本身已经是有序域：4.2 节验证了域公理，顺序与 O1、O2
由有理数的大小关系满足。它缺的只有最小上界性。第 03 章证明了
$A = \{ p \in \mathbb{Q} \mid p > 0,\ p^2 < 2 \}$ 非空、有上界，
但在 $\mathbb{Q}$ 里没有上确界。所以“有序域”四个字还不是实数；
实数是把这些洞补上之后的那个有序域。

定义写出来，并不自动说明这样的集合存在。教材有两种态度。一种把存在性
当成公理，叫做完备性公理，内容就是最小上界性。另一种在承认 $\mathbb{Q}$
之后把 $\mathbb{R}$ 构造出来。戴德金分割是其中一条路线：一个分割把
$\mathbb{Q}$ 分成左右两段 $L$ 与 $U$ ，$L$ 里每个数都小于 $U$ 里每个数，
$L$ 没有最大元，$L \cup U = \mathbb{Q}$ 。每个分割当作一个“实数”。
有理数 $r$ 对应分割 $L = \{ q \mid q < r \}$ ；没有端点的那种分割，
例如 $L = \{ q \mid q \le 0 \} \cup \{ q \mid q > 0,\ q^2 < 2 \}$ ，
就是上一章那个洞。可以验证分割之间能定义加法、乘法和顺序，并且每个
有上界的分割集都有最小上界（把下集并起来）。这条构造能做完，只是很长。
mathlib 的实数走的是另一条等价路线：有理数的柯西列模去零列。无论哪一条，
构造结束之后 `Real.isLUB_sSup` 都成为定理。本教程把这个定理当作实数
已经具备的性质来用，不再重做分割。

定义 5.4 立刻说明下一章要证的三件事为什么是定理而不是公理：阿基米德
性质（正数的整数倍可以超过任何实数）、有理数在实数中稠密（任意两个
实数之间有有理数）、每个正数都有唯一的正 $n$ 次方根。它们都从最小上界性
推出来，而不是从域公理单独推出来。$\mathbb{Q}$ 满足域公理和 O1、O2，
也满足阿基米德性质（有理数的情形可以用分子分母直接写出倍数），
但它没有平方根 $\sqrt{2}$ 。根的存在性才是最小上界性真正新添的东西。

## 4.8 扩张的实数系

原书在三定理之后用一个附注结束这一章：$\pm \infty$ 可以当作符号使用，
但它们不是实数。这段不依赖三定理，放在这里正好用来对照“什么不是域”。

**定义 5.10.** 扩张的实数系是 $\mathbb{R} \cup \{+\infty, -\infty\}$ 。
顺序在实数上与原来相同，并且对每个实数 $x$ 规定 $-\infty < x < +\infty$ 。
运算按下面的约定延伸，其中 $x \in \mathbb{R}$ ：

$$
x + (+\infty) = +\infty, \qquad x + (-\infty) = -\infty,
$$

$$
\frac{x}{+\infty} = \frac{x}{-\infty} = 0.
$$

$x > 0$ 时，$x \cdot (+\infty) = +\infty$ ，$x \cdot (-\infty) = -\infty$ ；
$x < 0$ 时两个符号对调。下面这些式子没有约定，一律无定义：

$$
\infty - \infty,\quad \frac{\infty}{\infty},\quad 0 \cdot \infty,\quad
\frac{\infty}{0},\quad \infty \cdot \infty.
$$

（$x / \infty = 0$ 是约定，不要和 $0 \cdot \infty$ 混成一件事。）

这个系统不是域。$+\infty$ 没有乘法逆元：没有任何元素与它相乘得到 $1$ ，
而且若干运算根本没有定义，封闭性也无从谈起。它偶尔有用，是因为每个
子集都有上界：实数里没有上界的集合，在扩张系里以 $+\infty$ 为上界，
并且这个上界就是上确界；没有下界的集合以 $-\infty$ 为下确界。第 03 章
反复强调的“上确界可以不存在”，在扩张系里被 $+\infty$ 这个符号接住了。
接住它的代价是失去域结构。分析学的主舞台仍然是定义 5.4 里的 $\mathbb{R}$ 。

## 4.9 本章验证清单

- `examples/lean/Realanalysis/Ch04Field.lean`：有理数的代表元与通分、
  整数单位只有 $\pm 1$ 、自然数没有加法逆元、$\mathbb{Z}_5$ 、
  $0 \cdot x = 0$ 与 $-(-x) = x$ 、逆元唯一、有序域的四条推论、中点、
  定义 5.4 的嵌入与最小上界性。
- `examples/isabelle/RA04/FieldAxioms.thy`：通分公式、`zmult_eq_1_iff` 、
  逆元唯一的两步除法、正数保序与取倒数反序。
- `examples/coq/Ch04_field.v`：`ring` 折叠的三条域推论、`field` 做的
  逆元唯一、把取倒数反序还原成 $x < y$ 的去分母证明。
- `examples/agda/Ch04_fieldaxioms.agda`：只从加法群与右分配律推出
  $0 \cdot x = 0$ 和 $-(-x) = x$ 。
- `examples/python/04_field.py`、`examples/julia/04_field.jl`、
  `examples/prolog/04_field.pl`：浮点结合律的反例、有理数样本上的公理、
  $\mathbb{Z}_5$ 的全枚举、整数区间里 $2z = 1$ 无解。

复验：`pwsh -NoProfile -Command '& ./build.ps1 -Chapter 04'`。

## 4.10 接下来

域公理和有序域公理都是等式或不等式的有限操作。最小上界性是第一条
真正谈论无限集合的公理。下一章用它证明三件事：自然数在实数里无界
（阿基米德性质）、任意两个实数之间有有理数、每个正数都有正的 $n$ 次方根。
最后一条把第 03 章那个没有端点的集合 $A$ 补上端点：它在 $\mathbb{R}$
里的上确界就是 $\sqrt{2}$ 。
