# 第 02 章 集合论

> 对应原书第 3 章《集合论》。集合是数学分析的语言本体：实数集、
> 区间、开集闭集、函数的定义域值域——后面一切概念都要翻译成
> 集合语言。本章讲透子集关系、并与交、补与德摩根律，
> 以及索引族的无限并/无限交，并以原书例 3.14 的三组区间作为
> 全章的压轴实验。

## 2.1 集合与子集：从“属于”开始

集合由其元素完全决定（外延性原则）：$A = B$ 当且仅当它们含有
完全相同的元素。由此推出最常用的基本关系——**子集**：

$$
A \subseteq B \;:\Longleftrightarrow\; \forall x, \; x \in A \Rightarrow x \in B .
$$

注意这个定义把集合间的关系化归为元素间的逻辑蕴涵。证明
$A \subseteq B$ 的标准套路从此固定下来：**任取 $x \in A$，证明
$x \in B$**。这个“任取元素”的动作在 Lean 里就是 `intro x hx`，
在 Isabelle 里是 `fix x assume`，在纸面上是“Let $x \in A$.”。

第一个定理（原书定理 3.7）平凡却深刻：

$$
\emptyset \subseteq A \quad \text{对任何集合 } A \text{ 成立}.
$$

证明是逻辑学里所谓的**虚真**（vacuous truth）：$x \in \emptyset$
恒假，而假命题蕴涵一切，所以定义中的蕴涵自动成立。三个证明
助手各自表达了这一点。Lean（`examples/lean/Realanalysis/Ch02Sets.lean`）
直接引用库定理 `empty_subset`；Coq 的 Ensemble 库里对应
`Included_Empty`；Agda 通道（`examples/agda/Ch02_sets.agda`）最直白——
空集的特征函数恒为 `false`，而 `T false` 就是空类型 $\bot$，

```agda
empty-subset : ∀ {X} (A : Setᶠ X) → ∅ᶠ ⊆ᶠ A
empty-subset A x ()
```

证明项只有一个空模式 `()`：“如果哪个元素属于空集，那它属于任何
集合”——因为根本没有这样的元素需要检查。

## 2.2 并与交：四条基本性质

原书定理 3.12 汇集了并交的基本代数性质，其中前几条是：

1. $A \subseteq A \cup B$，且 $A \cap B \subseteq A$；
2. $A \subseteq B \iff A \cup B = B$；
3. $A \subseteq B \iff A \cap B = A$；
4. $A \cup (B \cap C) = (A \cup B) \cap (A \cup C)$（并对交的分配）；
5. $A \cap (B \cup C) = (A \cap B) \cup (A \cap C)$（交对并的分配）。

Lean 通道逐条对应：

```lean
example : A ⊆ A ∪ B := fun _ hx => Or.inl hx
example : A ∩ B ⊆ A := fun _ hx => hx.1
example : A ⊆ B ↔ A ∪ B = B := (union_eq_right).symm
example : A ⊆ B ↔ A ∩ B = A := (inter_eq_left).symm
example : A ∪ (B ∩ C) = (A ∪ B) ∩ (A ∪ C) := union_inter_distrib_left A B C
example : A ∩ (B ∪ C) = (A ∩ B) ∪ (A ∩ C) := inter_union_distrib_left A B C
```

第一条值得细看：`fun _ hx => Or.inl hx` 把子集证明展开为成员级
推理——对任意元素（`_` 表示不用给它起名）与成员证据
`hx : x ∈ A`，返回 `Or.inl hx : x ∈ A ∨ x ∈ B`。mathlib 把
$x \in A \cup B$ 定义为析取 $x \in A \lor x \in B$，所以集合的并
**就是**逻辑的或，集合的交就是逻辑的与。这不是类比，而是定义。

Coq 通道（`examples/coq/Ch02_sets.v`）把分配律的证明完全展开，
用的是标准库 Ensemble 的外延公理 `Extensionality_Ensembles`：
两个集合相等，当且仅当互相包含。证明把一个等式拆成两个方向的
成员级推理，再用 `Union_inv` / `Intersection_inv` 拆解成员假设、
用构造子 `Union_introl` / `Union_intror` / `Intersection_intro` 重建
目标。全手工，但每一步都看得见。

Agda 通道走的是另一条路：集合被实现为**布尔特征函数**
`X → Bool`，于是子集是命题 `∀ x → T (A x) → T (B x)`，
分配律和德摩根律变成 Bool 上的可判定恒等式，逐点归纳即证：

```agda
compl-union : ∀ {X} (A B : Setᶠ X) (x : X) →
              ∁ᶠ (A ∪ᶠ B) x ≡ (∁ᶠ A ∩ᶠ ∁ᶠ B) x
compl-union A B x = deMorgan∨ (A x) (B x)
```

注意它**不需要函数外延公理**：我们不要求两个集合作为函数相等，
只在每个固定点 $x$ 上比较两个布尔值。这是把抽象集合论“降维”到
可判定世界的标准技巧。

## 2.3 补集与德摩根律

固定论域 $U$（比如后面最常用的 $U = \mathbb{R}$），$A$ 的补集是

$$
A^c = \{ x \in U \mid x \notin A \}.
$$

原书定理 3.17 的德摩根律说补运算交换并与交：

$$
(A \cup B)^c = A^c \cap B^c,
\qquad
(A \cap B)^c = A^c \cup B^c .
$$

Lean 中就是 `compl_union` 与 `compl_inter`。Coq 通道把两条定律的
逻辑含量分开了：第一条构造性可证（$\lnot (P \lor Q)$ 与
$\lnot P \land \lnot Q$ 直觉主义等价），第二条需要经典逻辑——
它的正向“从 $\lnot (P \land Q)$ 推出 $\lnot P \lor \lnot Q$”
本质上是排中律的变形，Coq 证明里的 `apply NNPP`（双重否定消除）
标记了这个逻辑强度。

计算通道在有限论域 $U = \{1, \dots, 9\}$ 上穷举核验。Python
（`examples/python/02_sets.py`）：

```python
U = set(range(1, 10))
A = {1, 3, 5, 7}
B = {2, 3, 4, 7}
comp = lambda S: U - S
assert comp(A | B) == comp(A) & comp(B)
assert comp(A & B) == comp(A) | comp(B)
```

Prolog 通道（`examples/prolog/02_sets.pl`）则把集合实现为无序列表，
`munion`/`minter`/`mcomp` 三个递归谓词各自行事，德摩根律成为关于
列表相等（`mseteq`：双向子集）的断言。这提醒我们：集合运算的定律
与具体表示无关——无论用数学对象、布尔函数还是列表，同一组定律
都成立。

## 2.4 区间：实数集上最常用的集合

原书在这里引入区间记号。开区间
$(a, b) = \{ x \in \mathbb{R} \mid a < x < b \}$，
闭区间 $[a, b]$ 把端点包含进来，半开区间 $[a, b)$、$(a, b]$
各含一端。Lean 中对应 `Set.Ioo`、`Set.Icc`、`Set.Ico`、`Set.Ioc`。

原书强调的一个细节：并集不“缝合”端点处的洞——

$$
(1, 3) \cup (3, 5) \neq (1, 5),
$$

因为点 $3$ 同时被两个开区间排除在外。Lean 通道的证明
（`examples/lean/Realanalysis/Ch02Sets.lean`）：

```lean
example : Set.Ioo (1 : ℝ) 3 ∪ Set.Ioo 3 5 ≠ Set.Ioo 1 5 := by
  intro h
  have h3 : (3 : ℝ) ∈ Set.Ioo (1 : ℝ) 5 := ⟨by norm_num, by norm_num⟩
  rw [←h] at h3
  simp only [mem_union, mem_Ioo] at h3
  rcases h3 with ⟨-, h⟩ | ⟨h, -⟩ <;> linarith
```

假设两集相等，则 $3$（显然属于右边）必须属于左边的并集；于是
$3$ 要么满足 $1 < 3 < 3$ 要么满足 $3 < 3 < 5$，两种情形都被
`linarith` 判为矛盾。对偶地，$(1, 3) \cap (3, 5) = \emptyset$：
任何实数不可能同时严格小于且严格大于 $3$。

Python 通道用有理数网格把这个“洞”可视化：在步长 $\frac{1}{4}$
的格点上枚举两个开区间的成员，断言 $3$ 不在并集里但在大区间里。
浮点区间在这里反而容易骗人（$3.0$ 的表示是精确的，洞看不见），
所以脚本特意用 `Fraction` 做网格——这是第 00 章“精确性”主题的
第一次实战回报。

## 2.5 索引族：无限并与无限交

本章的重头戏。设 $I$ 是索引集（最常见的是 $I = \mathbb{N}$），
对每个 $i \in I$ 有一个集合 $A_i$，则

$$
\bigcup_{i \in I} A_i = \{ x \mid \exists i, \, x \in A_i \},
\qquad
\bigcap_{i \in I} A_i = \{ x \mid \forall i, \, x \in A_i \}.
$$

无限并是“存在某个索引”，无限交是“对所有索引”——并与交恰好
对应存在与全称量词。德摩根律也升到索引族版本：

$$
\left( \bigcup_{i \in I} A_i \right)^c = \bigcap_{i \in I} A_i^c,
\qquad
\left( \bigcap_{i \in I} A_i \right)^c = \bigcup_{i \in I} A_i^c .
$$

Lean 中对应 `compl_iUnion` 与 `compl_iInter`，本教程用显式参数
引用：

```lean
example (I : Type*) (E : I → Set α) : (⋃ i, E i)ᶜ = ⋂ i, (E i)ᶜ :=
  compl_iUnion (s := E)
```

原书例 3.14 给出三组区间族，把“无限并/交可能产生单个集合
给不出的形状”这件事讲得淋漓尽致。我们逐个看。

**族一**：$A_n = \left(-\frac{1}{n+1}, \frac{1}{n+1}\right)$，
$n = 0, 1, 2, \dots$（原书从 $n \ge 1$ 起，Lean 的自然数从 $0$
起，故用 $n + 1$ 对齐）。这是**递减**嵌套族：每个区间都含在
前一个里。所以并集就是最大的那个：

$$
\bigcup_{n=0}^{\infty} A_n = (-1, 1) = A_0 .
$$

Lean 证明（`union_Aseq`）按“互相包含”展开：正向，任何
$A_n$ 的成员都落在 $(-1, 1)$ 里（因为 $\frac{1}{n+1} \le 1$）；
反向，$(-1, 1) = A_0$ 的成员直接落进并集。这里有一个值得记住的
工程细节：$\frac{1}{n+1} \le 1$ 这一步用 `div_le_one` 定理完成，
而源文件里的 $-\frac{1}{n+1}$ 被 Lean 解析为 $\frac{-1}{n+1}$，
与 $\frac{1}{n+1}$ 是两个不同的除法表达式——证明里必须用
`neg_div` 显式建立两者的联系，`linarith` 才能贯通。形式化把我们
在纸上随手跳过的“显然”全部逼了出来。

**族二**：$B_n = \left[0, 2 - \frac{1}{n+1}\right]$。这是**递增**族，
右端点单调逼近 $2$ 但永远到不了 $2$。于是：

$$
\bigcup_{n=0}^{\infty} B_n = [0, 2),
\qquad
\bigcap_{n=0}^{\infty} B_n = B_0 = [0, 1].
$$

并集的证明（`union_Bseq`）是本章最精彩的一段。正向容易：
$B_n$ 的成员满足 $x \le 2 - \frac{1}{n+1} < 2$。反向是分析学的
第一次真功夫：任取 $x \in [0, 2)$，要找到某个 $n$ 使
$x \in B_n$，即 $x \le 2 - \frac{1}{n+1}$，也就是
$\frac{1}{n+1} < 2 - x$。因为 $x < 2$，右端是**正数**——这正是
Archimedean 性质的用武之地（第 00 章预告的
`exists_nat_one_div_lt`）：

```lean
have hε : 0 < 2 - x := by linarith
obtain ⟨n, hn⟩ := exists_nat_one_div_lt hε
refine mem_iUnion.mpr ⟨n, ?_⟩
```

“$2$ 不属于并集”与“每个比 $2$ 小的点都属于并集”合起来，
正是半开区间 $[0, 2)$ 的定义。计算通道在这里展现了它最诚实的
局限：Julia 与 Python 都只能把并截断到 $N = 100$，得到的最大
右端点是 $\frac{201}{101} < 2$——**极限点永远差一步**。
这一差距不是精度问题，而是有限与无限的本质鸿沟；
跨过它的唯一工具是证明。

**族三**（交集方向）：同一个递增族的交集等于最小的 $B_0 = [0, 1]$。
Lean 证明（`inter_Bseq`）里有一个形式化特有的陷阱：对
`mem_iInter` 引入全称量词时如果不标注类型（`intro (n : ℕ)`），
`intro` 会错误地捕获一个 `Set ℝ`——证明助手对 binder 的字面
解读逼我们把纸上的“显然对所有 $n$”写成精确的变量声明。

## 2.6 索引族德摩根律的有限影子

计算通道还能验证索引族德摩根律的有限版本。Julia
（`examples/julia/02_sets.jl`）：

```julia
E = [Set([1, 2]), Set([2, 3]), Set([4, 5])]
@assert comp(union(E...)) == intersect(comp.(E)...)
```

三个有限集合的并的补等于各自补的交。Prolog 用 `foldl` 表达同一
事实。这些有限核验对应 Coq 通道的“有限影子”一节
（`FiniteShadow`）：有限论域 `U9 = {0,...,9}` 上的列表实现集合，
德摩根律变成 `forallb` 逐点比较——抽象证明与有限实验两相对照，
是本教程贯穿全书的方法论。

## 2.7 本章验证清单

- `examples/lean/Realanalysis/Ch02Sets.lean`：子集四条性质、
  分配律、德摩根（二元与索引族）、区间洞、例 3.14 三组区间族。
- `examples/isabelle/RA02/Sets.thy`：同组定理的自动化版本
  （`auto`/`blast` 处理成员级推理）。
- `examples/coq/Ch02_sets.v`：Ensemble 外延公理 + 手工成员推理，
  有限影子（列表布尔集合）。
- `examples/agda/Ch02_sets.agda`：特征函数集合，逐点德摩根，
  有限并的 foldr 德摩根。
- `examples/julia/02_sets.jl`：有限论域穷举、区间洞、截断索引族。
- `examples/python/02_sets.py`：Fraction 网格上的同组实验。
- `examples/prolog/02_sets.pl`：列表集合运算与索引族德摩根。

复验：`pwsh -NoProfile -Command '& ./build.ps1 -Chapter 02'`。

## 2.8 接下来

第一篇（预备知识）到此结束。第二篇开始进入实数本身：
第 03 章（原书第 4 章）讲上确界——为什么 $\mathbb{Q}$ 里
$\{ x : x^2 < 2 \}$ 没有最小上界，而 $\mathbb{R}$ 里有；
那条“最小上界性质”公理将成为整个实数理论的发动机，
也是第 00 章 $\sqrt{2}$ 之谜的最终答案。
