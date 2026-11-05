# 第 08 章 可数性

> 对应原书第 8 章。上一章把“一样大”定义成存在双射。本章把这个
> 关系叫做势：它是等价关系；有限集的势就是元素个数；无限集则分成
> 可数与不可数。主线例子是 $\mathbb{Z}$ 可数、$(0,1)$ 与
> $\mathbb{R}$ 不可数、$\mathbb{Q}$ 可数、无理数不可数。

## 8.1 定义 8.1–8.3：等价关系与势

**定义 8.1.** 关系 $\equiv$ 是等价关系，若它自反、对称、传递：
$a\equiv a$ ；由 $a\equiv b$ 得 $b\equiv a$ ；由 $a\equiv b$ 且
$b\equiv c$ 得 $a\equiv c$ 。相等 $=$ 是等价关系，但不是唯一的一种。

**定义 8.3.** 对集合 $A,B$ ，

$$
A\sim B \quad:\Longleftrightarrow\quad \text{存在双射 } f:A\to B.
$$

这时称 $A$ 与 $B$ 一一对应，并说它们有相同的势（基数）。
注意：“一一对应”是既单又满的双射；单射（一对一）本身不够。

**定理 8.4.** $\sim$ 是等价关系。

1. $A\sim A$ ：恒等 $x\mapsto x$ 是双射。
2. $A\sim B\Rightarrow B\sim A$ ：双射的逆仍是双射（定理 7.16）。
3. $A\sim B$ 且 $B\sim C\Rightarrow A\sim C$ ：两个双射的复合仍是双射
   （两边都单则复合单，两边都满则复合满）。

等势不等于相等。相等要求元素完全相同；$\sim$ 只要求能配对。
Lean（`examples/lean/Realanalysis/Ch08Countability.lean`）用
`Equiv` 写出这三条：

```lean
example : ℕ ≃ ℕ := Equiv.refl ℕ
example : ℕ ≃ ℤ := Equiv.intEquivNat.symm
example : ℤ ≃ ℤ := Equiv.intEquivNat.trans Equiv.intEquivNat.symm
```

Isabelle 的 `id_bij`、`bij_converse`、`bij_comp_trans` 是同一组事实。

## 8.2 定理 8.5：有限集的势就是个数

**定理。** 有限集 $A,B$ 满足 $A\sim B$ ，当且仅当它们的元素个数相同。

若存在双射，则每个 $A$ 的元素恰好对应一个 $B$ 的元素，个数相同。
反过来，把两边都写成 $\{a_1,\ldots,a_n\}$ 与 $\{b_1,\ldots,b_n\}$ ，
$a_i\mapsto b_i$ 就是双射。

因此有限集不可能与自己的真子集等势：真子集的元素更少。
Lean 用 `Fin n`：

```lean
example : Fintype.card (Fin 3) ≠ Fintype.card (Fin 4) := by decide
example : Fintype.card (Fin 3) = Fintype.card (Fin 4) → Nonempty (Fin 3 ≃ Fin 4) := by
  intro h
  exact ⟨Fintype.equivOfCardEq h⟩
```

计算通道只核对列表长度：三个元素的表与两个元素的表长度不同。

## 8.3 定义 8.6 与例 8.8：可数，以及 $\mathbb{Z}$

**定义 8.6.** $A$ 可数，若 $A\sim\mathbb{N}$ 。有限或可数，称为至多可数。
无限且不可数，称为不可数。有限集也可以说成与 $\{1,\ldots,n\}$ 等势。

命名要和库对齐，否则后面会对不上：

| 原书 | mathlib | Isabelle |
|------|---------|----------|
| 可数（与 $\mathbb{N}$ 等势） | `Denumerable` | 无限且 `countable` |
| 至多可数 | `Countable`（存在单射进 $\mathbb{N}$ ） | `countable` |

**定理 8.7.** 若 $A\sim B$ ，则二者同为“元素个数相同的有限集”，或同为可数，
或同为不可数。两个可数集彼此等势（都与 $\mathbb{N}$ 等势，再用传递性）。
两个不可数集不一定等势——本章用不到更大的势，只记住这句话。

**例 8.8.** $\mathbb{Z}$ 可数。不能把每个自然数同时送到 $n$ 和 $-n$ ：
那不是函数。改成交错：

$$
f(n)=
\begin{cases}
n/2 & n\text{ 偶},\\
-(n-1)/2 & n\text{ 奇}.
\end{cases}
$$

下标从 $1$ 起时：$1\mapsto 0$ ，$2\mapsto 1$ ，$3\mapsto -1$ ，$4\mapsto 2$ ，$5\mapsto -2$ 。
每个整数恰好出现一次，所以 $f:\mathbb{N}\to\mathbb{Z}$ 是双射。

Lean 按这个公式定义 `bookF`，并给出逆：正数 $k\mapsto 2k$ ，负数
$-k\mapsto 2k+1$ ，$0\mapsto 1$ 。

```lean
def bookF (n : ℕ) : ℤ :=
  if n % 2 = 0 then (n / 2 : ℤ) else -(((n - 1) / 2 : ℕ) : ℤ)

example : bookF 1 = 0 := by decide
example : bookF 2 = 1 := by decide
example : bookF 3 = -1 := by decide

theorem bookF_bookInv (z : ℤ) : bookF (bookInv z) = z := by
  cases z with
  | ofNat n =>
    cases n with
    | zero => decide
    | succ k =>
      simp [bookInv, bookF, Nat.mul_mod_right]
  | negSucc k =>
    simp [bookInv, bookF, Int.negSucc_eq]
```

右逆说明满射。mathlib 另有现成的 `Equiv.intEquivNat`，于是
`Denumerable ℤ`。Isabelle 把下标改成从 $0$ 起（偶数 $n/2$ ，奇数
$-(n+1)/2$ ），用 `unzig` 证明 `bij zig`。Julia / Python / Prolog
在 $-20..20$ 上核对 `zig(unzig(z))=z` 与 `unzig(zig(n))=n`。

由此出现无限集特有的现象：$\mathbb{N}$ 是 $\mathbb{Z}$ 的真子集，
却有 $\mathbb{N}\sim\mathbb{Z}$ 。

**定义 8.9.** 无限集就是与自己某个真子集等势的集合。在相等 $=$ 之下，
任何集合都不会等于自己的真子集；等势 $\sim$ 才允许这件事。

## 8.4 例 8.10：$(0,1)$ 不可数（对角线）

设 $S=(0,1)$ 。每个 $s\in S$ 写成无限小数 $0.d_1 d_2 d_3\cdots$ （有限小数
在末尾补无穷个 $0$ ）。任取可数子集 $E=\{e_1,e_2,\ldots\}\subset S$ ，
把它们排成表，第 $i$ 行是 $e_i$ 的小数位。定义

$$
s_i=
\begin{cases}
1 & \text{若 } e_i\text{ 的第 }i\text{ 位是 }0,\\
0 & \text{否则}.
\end{cases}
$$

则 $s=0.s_1 s_2\cdots$ 与每个 $e_i$ 至少在第 $i$ 位不同，所以
$s\in S\setminus E$ 。每个可数子集都是真子集。若 $S$ 自己可数，
它就会是自己的真子集，矛盾。故 $S$ 不可数。

被改掉的那些位正好落在表的对角线上，所以叫康托尔对角线法。
不可数的意思是：无论怎么把元素排成一列，总会漏掉一些。

证明通道把小数位收成布尔序列，避开“$0.1999\cdots=0.2000\cdots$ ”
这种表示不唯一。对任意 $f:\mathbb{N}\to(\mathbb{N}\to\mathrm{Bool})$ ，
令 $d(n)=\neg f(n)(n)$ ，则 $d$ 不在 $f$ 的值域里：

```lean
theorem cantor (f : ℕ → ℕ → Bool) : ¬ Surjective f := by
  intro hf
  let d : ℕ → Bool := fun n => !(f n n)
  rcases hf d with ⟨n, hn⟩
  have := congrFun hn n
  cases h : f n n <;> simp [d, h] at this
```

Isabelle `cantor_bool`、Coq `cantor`、Agda `cantor` 是同一句话：
假设某行等于 $d$ ，看第 $n$ 位就会得到 $b=\neg b$ 。计算通道用四行
$0/1$ 表造出一条与每行对角位都不同的序列。

**推论 8.12.** $\mathbb{R}$ 不可数。$(0,1)\subset\mathbb{R}$ ，
而不可数集的超集不可数（定理 8.11 的逆否）。

```lean
example : Uncountable ℝ := inferInstance
example : ¬ (Set.Ioo (0 : ℝ) 1).Countable := by simp
```

Isabelle 用 `uncountable_UNIV_real` 与 `uncountable_open_interval`：
开区间 $(a,b)$ 不可数当且仅当 $a<b$ 。库证明把 $(0,1)$ 双射到
$(-\pi/2,\pi/2)$ ，再经 $\tan$ 双射到 $\mathbb{R}$ ，与“子集不可数则
整体不可数”是同一结论的两条路。

## 8.5 定理 8.11–8.15：子集、可数并、有限元组

**定理 8.11.** $E\subset A$ 。若 $A$ 至多可数，则 $E$ 至多可数；若 $E$
不可数，则 $A$ 不可数。

关键是 $A$ 可数而 $E$ 无限：把 $A$ 排成 $x_1,x_2,\ldots$ ，依次挑出落在
$E$ 里的那些下标 $n_1<n_2<\cdots$ ，复合得到 $\mathbb{N}\to E$ 的双射。

```lean
example {α : Type*} {s t : Set α} (ht : t.Countable) (hs : s ⊆ t) : s.Countable :=
  ht.mono hs
```

**定理 8.13.** 可数个可数集的并仍可数。把 $E_n=\{x_n^{(1)},x_n^{(2)},\ldots\}$
排成网格，按 $i+j=2,3,4,\ldots$ 的对角线数过去。重复元素会破坏单射，
所以跳过已经出现过的项；定义域变成 $\mathbb{N}$ 的子集，仍至多可数，
而并集无限，故可数。

可数个的假设不能拿掉：$\bigcup_{\alpha\in\mathbb{R}}\{\alpha\}=\mathbb{R}$
是不可数指标集上的并。

**推论 8.14.** 指标集至多可数、每个 $E_\alpha$ 也至多可数，则并仍至多可数。
有限的那些先并上 $\{1,2,3,\ldots\}$ 变成可数，再套定理 8.13，最后用
定理 8.11 把多加的元素收回去。

```lean
example {α : Type*} (s : ℕ → Set α) (h : ∀ n, (s n).Countable) :
    (⋃ n, s n).Countable :=
  Set.countable_iUnion h
```

Isabelle 的 `countable_union_nat` 调用 `countable_UN`。

**定理 8.15.** 可数集的 $n$ 元组之集 $A^n$ 仍可数。对 $n$ 归纳：
$A^1=A$ ；$A^n$ 是 $|A^{n-1}|$ 个 $A$ 的副本之并，由推论 8.14 仍可数。
特别地 $\mathbb{Z}\times\mathbb{N}$ 可数。

## 8.6 定理 8.16–8.17：$\mathbb{Q}$ 可数，无理数不可数

**定理 8.16.** $\mathbb{Q}$ 可数。每个有理数都是 $a/b$ ，
$a\in\mathbb{Z}$ ，$b\in\mathbb{N}$ ，于是

$$
f:\mathbb{Z}\times\mathbb{N}\to\mathbb{Q},\qquad (a,b)\mapsto a/b
$$

是满射，但不是单射：$(1,2)$ 与 $(3,6)$ 是同一个数。只保留
$\gcd(z,n)=1$ 的数对，得到子集 $T$ 上的双射。$T$ 是可数集
$\mathbb{Z}^2$ 的子集，故可数，于是 $\mathbb{Q}$ 可数。

```lean
example : Countable ℚ := inferInstance
example : Infinite ℚ := inferInstance
```

计算通道按 $|a|+b$ 递增列举互素分数，并检查前若干个互异、且包含
$0,\pm 1,1/2$ 。

**推论 8.17.** 无理数集不可数。记 $I=\mathbb{R}\setminus\mathbb{Q}$ 。
若 $I$ 至多可数，则 $\mathbb{R}=\mathbb{Q}\cup I$ 是两个至多可数集的
有限并，由推论 8.14 可数，与推论 8.12 矛盾。

```lean
example : ¬ (Set.range ((↑) : ℚ → ℝ))ᶜ.Countable := by
  intro h
  have hQ : (Set.range ((↑) : ℚ → ℝ)).Countable := countable_range _
  have hU : (Set.univ : Set ℝ).Countable := by
    rw [← Set.union_compl_self (Set.range ((↑) : ℚ → ℝ))]
    exact hQ.union h
  exact Cardinal.not_countable_real hU
```

## 8.7 七通道对照

| 主题 | Lean | Isabelle | Coq | Agda | 计算三通道 |
|------|------|----------|-----|------|------------|
| 势是等价 | `Equiv.refl/symm/trans` | `bij` 的逆与复合 | — | `id` | — |
| $\mathbb{Z}$ 交错 | `bookF` + `Denumerable` | `zig`/`unzig`/`bij` | 数值往返 | 前几项 | 双边逆抽样 |
| 对角线 | `cantor` | `cantor_bool` | `cantor` | `cantor` | 四行 $0/1$ 表 |
| $\mathbb{R}$ 、$(0,1)$ | `Uncountable`、`Ioo` | `uncountable_open_interval` | — | — | — |
| $\mathbb{Q}$ 、无理数 | `Countable ℚ`、补集 | `countable` 的 `rat` | — | — | 约分对角线 |

## 8.8 本章验证清单

- `examples/lean/Realanalysis/Ch08Countability.lean`：势、有限基数、
  $\mathbb{Z}$ 枚举、对角线、$\mathbb{R}$ 与 $(0,1)$ 、可数并、
  $\mathbb{Q}$ 与无理数。
- `examples/isabelle/RA08/Countability.thy`：双射三条、`zig` 双射、
  对角线、$\mathbb{R}$ 与 $(0,1)$ 、$\mathbb{Q}$ 、可数并。
- `examples/coq/Ch08_countability.v`：枚举表、有限区间往返、对角线。
- `examples/agda/Ch08_countability.agda`：对角线与交错表的前几项。
- `examples/julia/08_countability.jl`、`examples/python/08_countability.py`、
  `examples/prolog/08_countability.pl`：双边逆、对角逃逸、约分有理数。

复验：`pwsh -NoProfile -Command '& ./build.ps1 -Chapter 08'`。

## 8.9 接下来

可数性告诉哪些集合能排成一列。下一章进入拓扑：先给度量、邻域、
极限点、开集和闭集下定义。

上一章：[07 双射](07-bijections.md) · 下一章：[09 拓扑定义](09-metric.md) · [返回目录](../README.md)
