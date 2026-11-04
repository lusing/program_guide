# 第 00 章 导言：为什么数学分析需要严格性

> 对应原书第 1 章（引言）。本章把原书的动机部分提炼完整：
> 为什么微积分的“直觉版本”不够用，为什么一切要从实数集的定义开始，
> 以及我们将用什么工具（七个独立的机器验证通道）来保证本教程里
> 每一个结论都不是“看上去对”，而是“机器确认过对”。

## 0.1 一个让人不安的计算

先来看一个每个会写程序的人都见过、但很少深想的现象。打开任意一门
语言的解释器，计算 $0.1 + 0.2$。Python 通道（`examples/python/00_intro.py`）
里我们做的第一件事就是把这个现象钉在墙上：

```python
print("float: 0.1 + 0.2 =", 0.1 + 0.2)
assert 0.1 + 0.2 != 0.3
print("float epsilon =", math.ulp(1.0), " (gap between adjacent floats)")
```

输出是 `0.30000000000000004`，而不是 $0.3$。这不是 Python 的 bug，
而是 IEEE 754 双精度浮点的本质：机器里的“实数”只是 $2^{64}$ 个有限
二进制分数的采样，`math.ulp(1.0)` 告诉我们 $1$ 附近相邻两个浮点数的
间隔是 $2^{-52} \approx 2.22 \times 10^{-16}$。任何落不进这个网格的
实数都只能被**舍入**到最近的网格点。

数学里的实数完全不同。同一个文件里紧接着的对照实验：

```python
r = Fraction(1, 3)
assert r + r + r == 1
```

`fractions.Fraction` 是精确有理数：分子分母各是一个任意精度的整数，
$\frac{1}{3} + \frac{1}{3} + \frac{1}{3}$ 严格等于 $1$，没有任何舍入。
Julia 通道（`examples/julia/00_intro.jl`）走得更远，展示了三种精度
的并存：

```julia
println("Float64: 0.1 + 0.2 = ", 0.1 + 0.2)      # 0.30000000000000004
println("Rational: 1//3 + 1//3 + 1//3 = ", 1//3 + 1//3 + 1//3)  # 1//1
setprecision(256) do
    println("BigFloat(256 bit) sqrt2 = ", sqrt(big(2)))
end
```

`Rational` 是精确分数；`BigFloat` 可以把有效位数从 53 位提到 256 位，
打印出 $\sqrt{2}$ 的八十位小数——但它仍然是**有限**精度。无论把精度
开到多高，机器浮点都在回答一个近似的问题；而数学分析要回答的是
精确的问题：**实数到底是什么**。

这就是原书第一章的核心讯息：微积分的所有概念——极限、连续、导数、
积分——都建立在实数集的性质上。如果对实数的理解停留在“数轴上的点”
这种直觉层面，那么 $\lim$、$\varepsilon$-$\delta$ 这些定义就无处安放。
原书的路线是：先集合与逻辑（第一篇），再用公理定义实数（第二篇），
然后研究实数集的拓扑（第三篇），最后在这个地基上重建序列与级数
（第四篇）。本教程沿同一条路线走，但每一步都有机器验证兜底。

## 0.2 机器里的“数学实数”

上面的实验说明计算语言能精确处理**有理数**，却不能精确处理**实数**
（实数集包含无理数，而任何有限表示都写不下无理数的完整信息）。
证明助手走的是另一条路：不计算实数，而是把实数作为**公理化的
数学对象**来推理。

Lean 通道（`examples/lean/Realanalysis/Ch00Intro.lean`）的开场白是：

```lean
example : (1 : ℝ) / 3 + 1 / 3 + 1 / 3 = 1 := by norm_num
```

这里的 `ℝ` 是 mathlib 里完整的数学实数域，`norm_num` 是算术判定
过程：它把这个等式当作关于抽象域运算的命题来证明，而不是当作
浮点计算来求值。结果不是“约等于 1”，而是一个**定理**。

同一个文件里紧接着是一个更有分量的热身：

```lean
theorem sqrt_two_mul_self : Real.sqrt 2 * Real.sqrt 2 = 2 := by
  have h : Real.sqrt 2 ^ 2 = 2 := Real.sq_sqrt (by norm_num)
  rw [← sq]
  exact h
```

mathlib 的 `Real.sqrt` 是由完备性定义的数学平方根函数；
`Real.sq_sqrt` 说对非负 $x$ 有 $(\sqrt{x})^2 = x$。证明的三行分别说：
$s(\sqrt{2})^2 = 2$ 是库里的定理；把目标里的 $\sqrt{2} \cdot \sqrt{2}$
改写成 $(\sqrt{2})^2$（`sq` 就是平方的定义）；于是目标与已知定理
完全一致。

注意这个证明里**没有小数**。$\sqrt{2}$ 从头到尾是一个抽象实数，
它的全部性质都由公理和定理刻画。这就是“严格性”在机器里的样子。

## 0.3 第一个非平凡定理：$\sqrt{2}$ 不是有理数

原书在引言里就宣布了实数理论的第一个惊人事实：单位正方形的对角线
长度 $\sqrt{2}$ 不能写成任何整数之比 $\frac{p}{q}$。这个结论在公元前
五世纪就震惊过毕达哥拉斯学派，它也是“为什么有理数不够用”的
最直接证据。完整的证明我们会在第 01 章作为“反证法”的范例细讲
（原书例 2.3），这里先看它在两个通道里的形态。

Lean 通道直接引用 mathlib 的现成定理：

```lean
example : Irrational (Real.sqrt 2) := irrational_sqrt_two
```

`Irrational x` 的定义是：不存在有理数 $r$ 使 $r = x$。一行引用
的背后是 mathlib 里完整的奇偶性论证。

Coq 通道（`examples/coq/Ch00_intro.v`）则把这个定理**从头证明了一遍**
——Rocq 9.1 的标准库在改版时删掉了现成的 `irrational_sqrt_2`，
这反而给了我们一次亲手组装经典证明的机会。证明分三层，每层对应
一个引理，正好预演了下一章要系统讲的“反证法”：

第一层在自然数上，核心引理是：

```coq
Lemma no_double_square : forall n m : nat, n * n = 2 * (m * m) -> m = 0.
```

读法：如果两个自然数的平方满足 $n^2 = 2m^2$，那么 $m$ 只能是 $0$。
证明用的是**无限下降**（强归纳）：若 $m > 0$，由 $n^2$ 是偶数推出
$n$ 是偶数（引理 `even_square_even`：平方为偶则自身为偶，用
`Nat.even_mul` 把乘积的奇偶归约为因子的布尔或），写 $n = 2n'$ 代回
得 $m^2 = 2n'^2$；同理 $m$ 也是偶数，写 $m = 2m_0$ 又得
$n'^2 = 2m_0^2$，而 $n' < n$——同一个方程在严格更小的数上再次成立，
强归纳假设迫使 $m_0 = 0$，于是 $m = 0$，与 $m > 0$ 矛盾。

第二层把结论搬到整数（`z_no_double_square`）：对 $p, q \in \mathbb{Z}$，
取绝对值 `Z.abs_nat` 退化为自然数方程，于是 $p^2 = 2q^2$ 蕴含 $q = 0$。

第三层才是实数上的定理：

```coq
Theorem sqrt2_irrational (p q : Z) (hq : q <> 0%Z) :
  IZR p / IZR q <> sqrt 2.
```

`IZR` 是整数到实数的标准嵌入。证明假设 $\frac{p}{q} = \sqrt{2}$，
两边平方得 $\left(\frac{p}{q}\right)^2 = 2$，交叉相乘并借助 `IZR` 的
环同态性质（`mult_IZR`）把等式反射回整数世界：$p^2 = 2q^2$，
第二层引理立刻给出 $q = 0$，与前提 $q \neq 0$ 矛盾。

三层结构本身值得记住：**实数上的命题，常常要先翻译成整数算术，
再翻译成自然数上的归纳**。这条“实数 → 整数 → 自然数”的下降路线
在后面章节还会反复出现。

计算通道只能给出有限证据，但也有教学价值。Python 的
`search_pythagoras(5000)` 在 $m, n \le 5000$ 的整数网格里搜索
$m^2 = 2n^2$ 的解——当然一无所获；并且指出连高精度有理逼近
$\frac{665857}{470832}$ 的平方与 $2$ 之差仍是 $\frac{1}{221682772224}$，
**不等于零**：

```python
approx = Fraction(665857, 470832)
assert approx * approx != 2
print("665857/470832 squared minus 2 =", approx * approx - 2)
```

Prolog 通道（`examples/prolog/00_intro.pl`）做了同样的事，但用的是
SWI-Prolog 的精确有理数算术 `rdiv`：

```prolog
pyth_solution(N, M) :-
    between(1, 5000, N),
    M0 is round(sqrt(2) * N),
    Lo is M0 - 1, Hi is M0 + 1,
    between(Lo, Hi, M),
    M > 0,
    M * M =:= 2 * N * N.
```

`verify_not(pyth_solution(_, _))` 断言这个目标无解。Prolog 的版本
展示了逻辑编程的独特视角：**定理是一个无法满足的查询**。

## 0.4 Archimedean 性质：实数没有无穷大

原书引言里预告的第二个关键性质是 Archimedean 性质：对任何实数
$x$，总存在自然数 $n > x$。换句话说，实数轴上没有“无穷大元素”。
这个性质看上去显然，但它其实是实数完备性的深刻推论，并且在后面
（第 05 章）会成为“有理数在实数中稠密”的跳板。

Lean 通道给出库里的形式：

```lean
example (x : ℝ) : ∃ n : ℕ, x < (n : ℝ) := exists_nat_gt x
```

并且示范了它的一次实际使用（这正是第 02 章证明区间族并集时
需要的那一步）：

```lean
example (ε : ℝ) (hε : 0 < ε) : ∃ n : ℕ, 1 / ((n : ℝ) + 1) < ε :=
  exists_nat_one_div_lt hε
```

对任意小的正数 $\varepsilon$，总能找到分母足够大的单位分数
$\frac{1}{n+1} < \varepsilon$。这就是“任意小”这个词在数学里的精确含义。

Agda 通道（`examples/agda/Ch00_intro.agda`）给出了构造主义的对应物。
在自然数上，Archimedean 性质不需要任何公理，它就是后继函数本身：

```agda
archimedean-nat : ∀ (n : ℕ) → Σ ℕ (λ m → m > n)
archimedean-nat n = suc n , n<1+n n
```

读法：对任意 $n$，我们能**构造出**一个有序对 $(m, \text{证据})$，
其中 $m = n + 1$，证据是标准库引理 `n<1+n`。Σ 类型是构造主义里的
“存在”：一个存在性证明就是 witness 加证明的序对，是可以运行的程序。
文件末尾的 `repeat-suc` 与 `repeat-grows` 进一步说明构造主义如何看待
“无限”：不是一把完成的无穷集合，而是一台可以一直按下去的机器——

```agda
repeat-suc : ℕ → ℕ → ℕ
repeat-suc n zero    = n
repeat-suc n (suc k) = suc (repeat-suc n k)
```

连按 $k$ 次后继得到 $n + k$，`repeat-grows` 证明每一次迭代都严格变大。

计算通道里，Archimedean 性质就是一个取整函数。Python：

```python
def archimedean(x):
    n = math.floor(x) + 1
    assert n > x
    return n
```

这个平凡的函数其实是一个证明的“计算影子”：对任意（机器可表示的）
$x$，$\lfloor x \rfloor + 1$ 就是那个保证存在的自然数。

## 0.5 七个通道的分工

到这里，七个通道的角色已经可以看清了：

| 通道 | 本章演示了什么 |
|------|----------------|
| Lean | mathlib 的实数库：现成定理直接引用（无理性、Archimedean） |
| Isabelle | HOL-Analysis 里的同组事实，自动化更强 |
| Coq | 从标准库基础引理亲手组装 √2 无理性的完整三层证明 |
| Agda | 构造主义：存在性 = 可运行的 witness，无限 = 迭代机器 |
| Julia | Float64 / Rational / BigFloat 三种精度的对照实验 |
| Python | 精确分数、整数扫描、有限证据 |
| Prolog | 定理即查询：√2 无理性 = 无解的整数方程搜索 |

Isabelle 通道（`examples/isabelle/RA00/Intro.thy`）本章的内容与 Lean
平行：用 `simp`（借助库里的 simp 规则 `real_sqrt_mult_self`）与
`field_simps` 验证同样的热身事实，Archimedean 性质写作

```isabelle
lemma archimedean_teaser: "\<forall>(x::real). \<exists>n::nat. x < real n"
  using reals_Archimedean2 by blast
```

这里有两个 Isabelle2026 特有的细节值得一提：其一，`Main` 会话从这一
版开始明确**不包含实数**（`real` 类型在 Cauchy 序列商类型 `Real` 理论
中定义），所以本章的理论文件导入的是 `HOL-Analysis.Analysis`；
其二，Isabelle 源文件不接受裸 Unicode 数学符号，`∀`、`∃` 要写成
实体形式 `\<forall>`、`\<exists>`。

后面每一章都是同样的模式：正文把数学讲透，七个通道各自用本通道
最自然的方式把同一个结论钉死。

## 0.6 本章验证清单

- `examples/lean/Realanalysis/Ch00Intro.lean`：精确分数、$\sqrt{2}^2 = 2$、
  $\sqrt{2}$ 无理性（引用与展开证明两版）、Archimedean 性质。
- `examples/isabelle/RA00/Intro.thy`：同组事实的 Isabelle 版本。
- `examples/coq/Ch00_intro.v`：无理性的三层手工证明（无限下降）。
- `examples/agda/Ch00_intro.agda`：定义级相等、Σ 类型的 Archimedean。
- `examples/julia/00_intro.jl`：三种精度对照、整数扫描、取整函数。
- `examples/python/00_intro.py`：Fraction 精确性、Decimal 高精度、扫描。
- `examples/prolog/00_intro.pl`：rdiv 精确有理数、无解查询。

运行 `pwsh -NoProfile -Command '& ./build.ps1 -Chapter 00'` 可单独
复验本章的全部七个单元。

## 0.7 接下来

第 01 章进入原书第 2 章：数学语言本身。命题、量词、逆否命题，
以及五种证明技巧——每一种都会配上一个在本章已经见过的定理
（比如 √2 的无理性将在那里作为反证法的范例被重新证明一次，
这次我们放慢速度，看清每一步逻辑动作）。
