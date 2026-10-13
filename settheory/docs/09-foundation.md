# 09 · 正则公理、秩层级 V=⋃Vα 与 BG 类理论

> 正则公理排除的不是矛盾，而是我们不想要的集合——宇宙从此
> 分层。——累积层级的世界观

本章覆盖 Jech §9 与附录（Bernays-Gödel 类理论）：正则公理的
三重等价面貌、累积层级 V_α、rank 函数（引理 9.3：V = ⋃V_α）、
收集原则、∈-归纳与 ∈-递归（定理 25）、BG 的类与集合两层世界。

## 9.1 正则公理：三重面貌

**正则公理**：每个非空集 S 有 ∈-极小元（x ∈ S 且 x ∩ S = ∅）。
它的三个等价推论：

1. **无 x ∈ x**（单点集的极小元条件）；
2. **无 ∈-循环**（x₀ ∈ x₁ ∈ … ∈ x₀）；
3. **无 ∈-下降链**（x₀ ∋ x₁ ∋ x₂ ∋ …）——由 {x₀,x₁,…} 的
   极小元（引理 5.2 的反方向需要 DC）。

正则公理"不矛盾"（与 ZF 其余公理相容——V_ω 或任何 V_κ 都是
模型）且"不影响日常数学"（数系、序数、基数的理论与它无关），
但它是**元数学的引擎**：秩分层让"每个集合有出生地"。

Lean 通道（`examples/lean/Settheory/Ch09Foundation.lean`）展示
正则性在构造性秩理论中的降格——**公理变定理**：

```lean
/-- 在 PSet 世界里 x ∈ x 不可能：rank x < rank x 是矛盾。 -/
example {x : PSet} (h : x ∈ x) : False :=
  lt_irrefl (rank x) (PSet.rank_lt_of_mem h)
```

官方秩函数四锚点：`rank_lt_of_mem`（成员秩严格小）、
`rank_le_iff`（≤ 的刻画）、`rank_congr`（外延性兼容）、
`rank_mono`（子集单调）。

Isabelle/ZF 侧（`ST09/Foundation.thy`）锚定 **Vfrom** 理论
（Univ.thy——ZF 库的累积层级官方开发）：

```isabelle
thm Vfrom            (* Vfrom(A,i) = A ∪ ⋃j∈i. Pow(Vfrom(A,j)) *)
thm Vfrom_0          (* Vfrom(A,0) = A *)
thm Vfrom_mono       (* 层级单调 *)
thm Vfrom_rank_eq    (* Vfrom(A, rank(x)) = Vfrom(A, x) *)
```

`Vfrom_rank_eq` 是引理 9.3 的语义核心：**秩决定层级归属**。

## 9.2 累积层级与秩

    V₀ = ∅；V_{α+1} = P(V_α)；V_λ = ⋃_{α<λ} V_α

**引理 9.3** V = ⋃_{α∈Ord} V_α：反证取不属于任何 V_α 的
∈-极小元 x——x 的每个成员都在某 V_{α(z)}，替换给上确界 γ，
x ⊆ V_γ ⟹ x ∈ V_{γ+1}。∎

**秩**：rank(x) = 最小的 α 使 x ∈ V_{α+1}。基本性质：
x ∈ y ⟹ rank(x) < rank(y)；**rank(α) = α**（von Neumann 序数
的秩恰为自身）；rank(x) = sup{rank(z)+1 : z ∈ x}（习题 9.1）。
|V_{ω+α}| = ℶ_α（beth 层级——第 08 章的搭档）。

计算通道的数值实验。Julia（`09_rank.jl`）：|V_n| 的计数
0, 1, 2, 4, 16, 65536, 2^65536——超指数起飞，V_ω = ⋃V_n = HF
（可数）；嵌套数组的 rank 计算验证 von Neumann 数的秩。Python
（`09_rank.py`）：嵌套 frozenset 的 rank 递归 + V_n 的实际
枚举（powerset 迭代）：

```python
def rank(x):
    """rank(x) = sup{rank(y) + 1 : y ∈ x}；空集为 0。"""
    if not x:
        return 0
    return max(rank(y) for y in x) + 1
```

Agda（`Ch09_rank.agda`）构造性版：HF 上的 rank 函数 + 成员秩
严格下降（`rank-mem<`，用 `m≤m⊔n` 一行）+ rank(n) = n 的
refl 验证。Coq（`Ch09_rank.v`）给出**ε-归纳的完整证明**：

```coq
Lemma epsilon_induction_shadow :
  forall (P : ST -> Prop),
    (forall x, (forall y, rank y < rank x -> P y) -> P x) ->
    forall x, P x.
```

（对秩强归纳——定理 25A 的有限影子，零公理。）**实测坑入册**：
对 list 嵌套的 HF 定义 rank 被 Coq 的 guard checker 拒绝
（嵌套归纳的子项不跨构造子传递）——解法是二叉编码
（`SE`/`SP`），与 funanalysis 的嵌套归纳 guard 五撞同族。

Prolog（`09_rank.pl`）的 rank 递归 + 下降链检测——外加一个
**意外教学点**：查询 `member_st(X, X)` 在 Prolog 中**有解**
（循环项 X = s(X, o)，rational tree）——Prolog 的合一允许
非良基集合（Aczel 反基础公理 AFA 的模型）！正则公理在 ZF
中排除的正是它们：**公理的选择=宇宙的选择**。

## 9.3 收集原则与 ∈-归纳

**收集原则**（(9.4)）：对每个公式 φ，∀X ∃Y ∀u∈X
(∃v φ → ∃v∈Y φ)——类的族在集合上取值时可以被一个集合"扫中"。
证明用秩技巧：Y = 每个类 Cu 中秩最小的元素（(9.3) 的选择）。
收集原则**蕴含替换**（F ↾X = F ∩ (X×Y) 由分离切除）——
公理之间又一次身份流转。

**定理 25（∈-归纳与 ∈-递归）**：传递类 T 上，
(A) 若性质从"成员全真"推"自身真"，则全体真；
(B) F(x) = G(F↾x) 的唯一解存在。——超穷递归（定理 4）在
任意传递类的推广，秩函数自己是它的实例。

**秩的杀手锏应用**（等价类代表元，(9.3)）：对真类上的等价
关系，"秩最小代表元"让商成为集合可处理的操作——**无 AC 的
基数定义**（|X| = 与 X 等势的秩最小集合）由此可行。序型、
同构类型的定义全部受益。

## 9.4 BG 类理论（附录）

Bernays-Gödel：**类**与**集合**两种对象。类 = 一阶公式的化身
（X ∈ Y 只在 X 是集合时有意义）；**集合 = 属于某个类的类**。
类量词只对集合量化（类不被量化）——BG 的公理化保持与 ZF 的
等协调性，且**有穷公理化**。教学要点：

- Russell 类 {x : x ∉ x} 在 BG 中是**真类**（不属于任何类），
  悖论变成"分层说明"；
- 第 12-13 章的 L 构造在 BG 中可以用类函数一次性写出
  （Jech 后续章节的记号便利）。

## 9.5 习题精选

1. **（纸笔）** 习题 9.1：rank(x) = sup{rank(z)+1 : z ∈ x}。
2. **（纸笔）** 习题 9.3：|V_κ| = ℶ_κ 型 κ（强极限）时
   |V_κ| = κ。
3. **（纸笔）** 习题 9.4：κ 不可达 ⟹ |V_κ| = κ（不可达 =
   V_κ 成为 ZFC 模型的刻画——大基数的第一次亮相）。
4. **（机器）** rank 计算器扩展：对 Julia 的嵌套数组计算
   rank 与 |V_rank| 的对照。
5. **（纸笔）** 定理 25B 的唯一性（∈-归纳双向）。

---

上一章：[08 奇异基数](docs/08-singular.md) · 下一篇（第二篇）：[10 模型、相对一致性与绝对性](docs/10-models.md)
