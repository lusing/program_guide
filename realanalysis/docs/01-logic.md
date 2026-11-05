# 第 01 章 数学语言与证明技巧

> 对应原书第 2 章《基础数学与逻辑》。本章把原书的逻辑工具箱完整
> 提炼：命题与连接词、量词及其顺序、蕴涵的三种亲属命题，以及
> 全书反复使用的五种证明技巧。每一种技巧都配一个能在机器里
> 跑起来的实例。

## 1.1 命题、连接词与真值表

数学陈述的最小单位是**命题**（proposition）：一个非真即假的陈述。
命题之间用连接词组合：与（$\land$ ）、或（$\lor$ ）、非（$\lnot$ ）、
蕴涵（$\Rightarrow$ ）。其中蕴涵最容易被误用：$A \Rightarrow B$ 只在
$A$ 真而 $B$ 假时为假，其余三种情况都为真。特别地，“假命题蕴涵
任何命题”——这在日常语言里反直觉，但在数学里是唯一自洽的选择。

两条德摩根律给出了否定的分配规则：

$$
\lnot (A \lor B) \iff \lnot A \land \lnot B,
\qquad
\lnot (A \land B) \iff \lnot A \lor \lnot B .
$$

这两条定律在有限真值表上可以直接穷举验证。Python 通道
（`examples/python/01_logic.py`）的做法：

```python
for a, b in itertools.product((True, False), repeat=2):
    assert (not (a or b)) == ((not a) and (not b))
    assert (not (a and b)) == ((not a) or (not b))
    assert ((not a) or b) == (b or (not a))   # A→B 与其逆否 ¬B→¬A 同值
```

（最后一行中 $A \Rightarrow B$ 用 $\lnot A \lor B$ 表示——这正是蕴涵
在经典逻辑里的展开式，而 $\lnot B \Rightarrow \lnot A$ 展开为
$B \lor \lnot A$ ，两者逐项相同。）Prolog 通道
（`examples/prolog/01_logic.pl`）用谓词实现了同一张真值表，
布尔连接词被显式编码为数值函数：

```prolog
tor(VA, VB, R) :- R is max(VA, VB).
tand(VA, VB, R) :- R is min(VA, VB).
tnot(1, 0). tnot(0, 1).
timpl(1, 0, 0) :- !. timpl(_, _, 1).
```

然后用 `forall(member(A, [true,false]), ...)` 对全部四种赋值核验
德摩根律与逆否等价。把真值表写成程序，是为了强调一个事实：
**命题逻辑的这些定律是可判定的**——四行就能穷举完。

## 1.2 量词：顺序决定一切

全称量词 $\forall$ 与存在量词 $\exists$ 把命题升格为关于整个论域的
陈述。原书特别强调：**量词的顺序不能随意交换**。
$\forall x \, \exists y, \; y > x$ 和 $\exists y \, \forall x, \; y > x$
是截然不同的两个命题——前者为真（每个实数都有比它大的数），
后者为假（没有实数比所有实数都大）。

Lean 通道（`examples/lean/Realanalysis/Ch01Logic.lean`）把这对命题
并排证明：

```lean
example : ∀ x : ℝ, ∃ y : ℝ, y > x := fun x => ⟨x + 1, by linarith⟩

example : ¬ (∃ y : ℝ, ∀ x : ℝ, y > x) := by
  rintro ⟨y, hy⟩
  have := hy (y + 1)
  linarith
```

第一个证明是一个**函数**：给定 $x$ ，返回见证 $y = x + 1$ 和证明
$x + 1 > x$ 。第二个证明把假设解构出 $y$ 和它的“压过一切”性质
`hy`，然后把 `hy` 应用到 $y + 1$ 上——得到 $y > y + 1$ ，`linarith`
立刻发现这与实数序的公理矛盾。注意这个反证的核心动作就是
“用假设自己的结论攻击假设”，第 00 章 Coq 通道里 Cantor 式的
自指论证与此一脉相承。

量词的否定规则是德摩根律的量词版：

$$
\lnot (\forall x, \, P(x)) \iff \exists x, \, \lnot P(x),
\qquad
\lnot (\exists x, \, P(x)) \iff \forall x, \, \lnot P(x) .
$$

Lean 中它们就是 `not_forall` 与 `not_exists` 两个定理。Coq 通道
（`examples/coq/Ch01_logic.v`）多讲了一层逻辑学区分：第一条的
正向需要经典逻辑（`not_all_ex_not` 来自 `Classical` 模块），反向与
第二条的两个方向都是构造性有效的。Agda 通道
（`examples/agda/Ch01_logic.agda`）则干脆只证明构造性部分，
并在 Bool（可判定世界）里用模式匹配给出完整的德摩根律：

```agda
deMorgan-or : ∀ a b → not (a ∨ b) ≡ not a ∧ not b
deMorgan-or false _ = refl
deMorgan-or true  _ = refl
```

模式匹配就是真值表：四种情形各归约为 `refl`。

计算通道把量词顺序的差异变成可观察的事实。Python：

```python
assert all((lambda x: x + 1)(x) > x for x in range(-1000, 1000))
grid = list(range(-5, 5))
assert not any(all(y > x for x in grid) for y in grid)
```

第一行在整数上验证“每个 $x$ 都有后继 $x + 1$ ”；第二行验证有限
网格里不存在“压过所有元素的元素”——最大值就是反例。

## 1.3 蕴涵的三种亲属：逆命题、否命题、逆否命题

给定 $A \Rightarrow B$ ，可以造出三个亲属：

- **逆命题**（converse）：$B \Rightarrow A$ —— 不被原命题保证；
- **否命题**（inverse）：$\lnot A \Rightarrow \lnot B$ —— 同样不被保证；
- **逆否命题**（contrapositive）：$\lnot B \Rightarrow \lnot A$ ——
  与原命题**逻辑等价**。

原书用的例子：若 $n = 5$ 则 $n$ 是自然数（真）；反过来“若 $n$ 是
自然数则 $n = 5$ ”显然是假的，$n = 42$ 就是反例。Lean 通道把这个
反例写成存在性证明：

```lean
example : ∃ n : ℕ, n ≠ 5 := ⟨246734, by norm_num⟩
```

Coq 通道（`examples/coq/Ch01_logic.v`）则证明了逆否等价的完整
iff：

```coq
Example contrapositive_iff : (A -> B) <-> (~ B -> ~ A).
Proof.
  split.
  - intros h hnB hA. exact (hnB (h hA)).
  - intros h hA. apply NNPP. intro hnB. exact (h hnB hA).
Qed.
```

正向是构造性的：有 $A \to B$ 和 $\lnot B$ ，对任何 $a : A$ 都有
$B$ ，与 $\lnot B$ 矛盾。反向必须借助经典逻辑：NNPP（双重否定
消除）说 $\lnot \lnot B \to B$ ，于是我们证明 $\lnot \lnot B$ 就够了——
这正是“逆否证明”在构造主义里不合法、在经典数学里合法的精确分界。
Agda 通道只写了构造性的那一半，并诚实地把它命名为
`contraposition : (A → B) → ¬ B → ¬ A`——在 Agda 的世界里，
另一半根本写不出来，这不是疏忽，而是**逻辑强度的事实**。

## 1.4 五种证明技巧

原书第 2 章的核心是五种证明模板。我们逐个过一遍，每个都配一个
机器实例。

### 技巧一：反例（Counterexample）

要推翻一个全称命题，只需一个反例。上面的 `∃ n : ℕ, n ≠ 5` 就是。
反例在机器里是最便宜的证明：给出见证，剩下的交给计算。

### 技巧二：逆否证明（Contrapositive）

要证 $A \Rightarrow B$ ，改证 $\lnot B \Rightarrow \lnot A$ 。原书例 2.2
是它的经典应用：

> $x = y$ 当且仅当对任意 $\varepsilon > 0$ 都有 $|x - y| < \varepsilon$ 。

Lean 通道的完整证明：

```lean
example (x y : ℝ) : x = y ↔ ∀ ε : ℝ, 0 < ε → |x - y| < ε := by
  constructor
  · intro h ε hε
    rw [h]
    simpa using hε
  · intro h
    by_cases hxy : x = y
    · exact hxy
    · have hpos : 0 < |x - y| := abs_pos.mpr (sub_ne_zero.mpr hxy)
      have hcont := h (|x - y|) hpos
      exact False.elim (lt_irrefl _ hcont)
```

正向是直接的：代入 $x = y$ 后 $|x - y| = 0 < \varepsilon$ 。反向正是
逆否思路：设 $x \neq y$ ，则 $|x - y| > 0$ ，把这个正数**自己**作为
$\varepsilon$ 代回假设，得到 $|x - y| < |x - y|$ ——一个数严格小于
自己，`lt_irrefl` 给出矛盾。这个“任意接近即相等”的原理是分析学
最常用的工具之一：要证两个量相等，只需证它们的差比任何正数都小。

Python 通道给出它的有限网格核验（对一串递减的 $\varepsilon$ 检查
$|x - y| < \varepsilon$ 恒成立）：

```python
x = y = 2.0 ** 0.5
assert all(abs(x - y) < eps for eps in (1.0, 1e-6, 1e-12, 1e-15))
```

### 技巧三：反证法（Contradiction）

要证 $P$ ，假设 $\lnot P$ 并推出矛盾。第 00 章已经完整演示过：
$\sqrt{2}$ 无理性的三层证明（Coq 通道 `no_double_square` →
`z_no_double_square` → `sqrt2_irrational`）就是原书例 2.3 的
机器版。值得回顾的是证明的发动机：**偶数性在平方下封闭**
（$n^2$ 偶 $\Rightarrow$ $n$ 偶），Lean 通道里对应的库定理是
`Even.pow_iff` 一族，而 Coq 通道从 `Nat.even_mul` 手工推出了它。

### 技巧四：归纳法（Induction）

要证对所有自然数成立的命题 $P(n)$ ：证 $P(0)$ （基例），再证
$P(n) \Rightarrow P(n+1)$ （归纳步）。原书例 2.4 是求和公式：

$$
1 + 2 + \cdots + n = \frac{n(n+1)}{2}.
$$

Lean 通道的证明分两步——先证无除法版本（避免在归纳中处理
整除），再取一半：

```lean
theorem sum_formula_double :
    ∀ n : ℕ, 2 * (∑ i ∈ Finset.range n, (i + 1)) = n * (n + 1) := by
  intro n
  induction n with
  | zero => rfl
  | succ n ih =>
    rw [Finset.sum_range_succ, mul_add, ih]
    ring

theorem sum_formula :
    ∀ n : ℕ, ∑ i ∈ Finset.range n, (i + 1) = n * (n + 1) / 2 := by
  intro n
  let S := ∑ i ∈ Finset.range n, (i + 1)
  have h := sum_formula_double n
  exact (calc n * (n + 1) / 2
      = (2 * S) / 2 := by rw [h.symm]
    _ = S := Nat.mul_div_cancel_left S (by norm_num : 0 < 2)).symm
```

归纳步里，`Finset.sum_range_succ` 把 $n+1$ 项的和拆成 $n$ 项的和
加末项，`ring` 完成代数整理。Coq 通道结构相同（`sum_n_double` +
`sum_n_formula`，消因子用 `Nat.div2_double`）。Agda 通道则展示了
归纳证明在纯构造环境下的形态——一条显式的等式推理链：

```agda
sum-double (suc n) = begin
  2 * (sum n + suc n)   ≡⟨ *-distribˡ-+ 2 (sum n) (suc n) ⟩
  2 * sum n + 2 * suc n ≡⟨ cong (_+ (2 * suc n)) (sum-double n) ⟩
  n * suc n + 2 * suc n ≡⟨ cong (n * suc n +_) (*-comm 2 (suc n)) ⟩
  ...
```

每一步都标注了所用定理的名字，没有自动化，全部可手工检查。
文件末尾的 `InductionSkeleton` 模块把归纳法本身写成了一个
高阶函数：给定基例 `base : P 0` 和归纳步
`step : ∀ n → P n → P (suc n)`，就得到 `∀ n → P n`——
**归纳原理就是一个递归程序**。

计算通道对归纳的态度是“核验兜底”：机器不会归纳，但可以对前
一百个 $n$ 逐一验证（Julia 与 Python 都做了这件事），让归纳证明
不至于在低 $n$ 处就出错。

### 技巧五：直接证明（ε-δ 的第一次登场）

直接证明从定义出发正面构造。原书例 2.5 是微积分里最常见的一类
命题的第一次严格化：

$$
\lim_{x \to 2} (3x + 1) = 7.
$$

按定义，要证：对任意 $\varepsilon > 0$ ，存在 $\delta > 0$ ，使得
$|x - 2| < \delta$ 蕴含 $|(3x + 1) - 7| < \varepsilon$ 。关键观察是

$$
|(3x + 1) - 7| = |3x - 6| = 3|x - 2|,
$$

所以取 $\delta = \varepsilon / 3$ 即可。Lean 通道的形式化
（`examples/lean/Realanalysis/Ch01Logic.lean`）：

```lean
example : ∀ ε : ℝ, 0 < ε →
    ∃ δ : ℝ, 0 < δ ∧ ∀ x : ℝ, |x - 2| < δ → |(3 * x + 1) - 7| < ε := by
  intro ε hε
  refine ⟨ε / 3, by linarith, fun x hx => ?_⟩
  have h3 : (3 * x + 1) - 7 = 3 * (x - 2) := by ring
  rw [h3]
  have h4 : |3 * (x - 2)| = 3 * |x - 2| := by
    rw [abs_mul, abs_of_pos (by norm_num : (0 : ℝ) < 3)]
  rw [h4]
  linarith
```

注意这个证明的结构与纸上证明逐行对应：报出 $\delta$ 的取值，
验证 $\delta > 0$ ，然后对任意满足 $|x - 2| < \delta$ 的 $x$ 展开
代数恒等式，最后用线性算术收尾。Coq 通道用 `replace ... by ring`
做同样的恒等变形，Isabelle 通道（`examples/isabelle/RA01/Logic.thy`）
则展示了结构化证明语言 Isar 的版本——`fix`/`assume`/`show` 关键词
让证明读起来就像自然语言。

计算通道给这个证明配了两个数值影子。Julia（`examples/julia/01_logic.jl`）
对一串 $\varepsilon$ 验证 $\delta = \varepsilon/3$ 确实有效：

```julia
for eps in (0.1, 0.01, 0.001, 1e-6)
    delta = eps / 3
    for t in (-0.9, -0.5, 0.0, 0.3, 0.89)
        x = 2 + t * delta
        if abs(x - 2) < delta
            @assert abs((3x + 1) - 7) < eps
        end
    end
end
```

然后做了一个更有教益的反面实验：故意取过大的 $\delta = \varepsilon$ ，
在网格上能找到违反结论的 $x$ ——

```julia
found = false
eps = 0.1
for k in 0:1000
    x = 2 - eps + 2 * eps * k / 1000
    if abs(x - 2) < eps && abs((3x + 1) - 7) >= eps
        found = true; break
    end
end
@assert found
```

这说明 $\delta = \varepsilon/3$ 中的因子 $1/3$ 不是随手取的，
而是**尖锐的**：它恰好是函数斜率的倒数。数值实验不能代替证明，
但能检查证明里的常数是否最优——这是计算通道的独特价值。

## 1.5 本章验证清单

- `examples/lean/Realanalysis/Ch01Logic.lean`：逆否等价、反例、
  量词顺序、量词德摩根、归纳求和、ε-δ 直接证明、任意接近原理。
- `examples/isabelle/RA01/Logic.thy`：同组定理的 Isar 结构化版本。
- `examples/coq/Ch01_logic.v`：构造/经典逻辑的分层演示。
- `examples/agda/Ch01_logic.agda`：纯构造证明，归纳原理即递归。
- `examples/julia/01_logic.jl`：真值表、量词网格、ε-δ 尖锐性实验。
- `examples/python/01_logic.py`：有限论域上的同组核验。
- `examples/prolog/01_logic.pl`：真值表谓词与 ε-δ 的有理数版本。

复验：`pwsh -NoProfile -Command '& ./build.ps1 -Chapter 01'`。

## 1.6 接下来

第 02 章进入集合论（原书第 3 章）：子集、并交补、德摩根律，
以及本教程第一个真正“无限”的对象——索引族的无限并与无限交。
届时我们将第一次看到：有限截断永远够不到的极限点，
正是证明助手必须登场的地方。

上一章：[00 导言](00-intro.md) · 下一章：[02 集合论](02-sets.md) · [返回目录](../README.md)
