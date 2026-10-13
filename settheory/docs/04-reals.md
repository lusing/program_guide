# 04 · 实数的集合论构造

> 是实线的完备性造就了实数的不可数性。——Jech §4 的精神

本章覆盖 Jech §4：Cantor 的不可数性定理（嵌套区间版）、可数
稠密序的唯一性（定理 11 的 back-and-forth 思想）、Dedekind 完备
化（定理 12）、康托集与 |ℝ| = 2^ℵ₀、连续统假设的表述、Suslin
问题、Baire 纲定理、完美集定理与 Cantor-Bendixson 分析、Baire
空间与树表示。

## 4.1 不可数性：三种对角线

**定理 10（Cantor）** 实数集不可数。Jech 的证明是**嵌套区间**：
给定实数名单 (cₙ)，逐次收缩区间 [aₙ, bₙ] 避开 c₀, c₁, …, cₙ
（每步选名单中第一个落进当前区间的元素，然后在它两侧取新区
间端点），极限点 a = sup aₙ 不同于名单中一切元素。

这个证明与第 00/03 章的对角线证明不同：它用了实数的**完备
性**（有界递增序列有上确界）——这正是标题的断言。Coq 通道
（`examples/coq/Ch04_reals.v`）把对角线的通用骨架完整给出：

```coq
Definition diagonal_g (F : nat -> nat -> nat) : nat -> nat :=
  fun n => S (F n n).

Lemma diagonal_differs :
  forall (F : nat -> nat -> nat) (n : nat),
    diagonal_g F n <> F n n.
Proof.
  intros F n.
  unfold diagonal_g.
  intros E.
  lia.
Qed.
```

`S k ≠ k` 由 `lia` 关闭——ω→ω 版（Baire 空间不可数）与它完全
同构。Isabelle/ZF 通道（`ST04/Reals.thy`）在 ZF 内核做同一件事，
序数的 succ 性质替换 lia：

```isabelle
definition diag_of :: "[i, i] \<Rightarrow> i" where
  "diag_of(F, n) \<equiv> succ(F`n`n)"

lemma diag_differs:
  assumes "F: \<omega> \<rightarrow> (\<omega> \<rightarrow> \<omega>)"
  shows "\<forall>n \<in> \<omega> . diag_of(F, n) \<noteq> (F`n)`n"
proof (intro ballI notI)
  fix n
  assume "n \<in> \<omega>"
  assume eq: "diag_of(F, n) = (F`n)`n"
  then have s: "succ((F`n)`n) = (F`n)`n" unfolding diag_of_def .
  have "(F`n)`n \<in> succ((F`n)`n)" by (rule succI1)
  then have "(F`n)`n \<in> (F`n)`n" by (simp only: s)
  then show False by (rule mem_irrefl)
qed
```

注意这个通道的**记号警示**：ωω 在 Jech 里同时表示序数幂
（第 02 章的可数序数 ω^ω）与函数空间（Baire 空间，基数 𝔠 侧）
——ZF 里两者是完全不同的对象，ST04 的正文专门讨论这一点。

## 4.2 唯一性与完备化

**定理 11** ℚ（带通常序）是唯一的可数稠密无界线性序——任何
两个这样的序同构。证明的**back-and-forth** 思想（往返构造同构）
是模型论的通用引擎，第 23 章 Martin 公理与第 42 章投影层级都
会再见它。

**定理 12（完备化）** 每个稠密无界线性序 P 有唯一完备化 C：
P 稠密嵌入 C，C 完备。构造：**Dedekind 分割** (A, B)——
A ∪ B = P、A 的元素 < B 的元素、B 无最大元。实直线 ℝ 定义为
ℚ 的完备化。Coq 通道把分割做成 Record（`Ch04_reals.v`）：

```coq
Record is_cut (A : Q -> Prop) : Prop := BuildCut
  {
    cut_nontriv : (exists q, A q) /\ (exists r, ~ A r) ;
    cut_down : forall q r, (q < r)%Q -> A r -> A q ;
    cut_no_max : forall q, A q -> exists r, A r /\ (q < r)%Q
  }.

Definition cut_sqrt2 : Q -> Prop :=
  fun r => (0 <= r)%Q /\ (r * r < 2)%Q.
```

`cut_sqrt2` 是第一个"新"实数——ℚ 的完备化真正补进来的东西
（√2 ∉ ℚ，但它的割是合法的：下封闭由平方的单调性保持，
无最大元由"任何 r²<2 的 r 附近都能再推进一点"保证）。

## 4.3 连续统：康托集与 CH

康托集 C = {Σₙ aₙ/3ⁿ : aₙ ∈ {0,2}}——中三分构造的遗留物。
两个面貌：测度 (2/3)ⁿ → 0（"几乎被挖光"）；基数 2^ℵ₀（三进制
地址只用 0 与 2 的点，与 {0,2}^ℕ 一一对应）。**测度小 ≠ 元素少**
是本章最大的教训。

mathlib 有完整的官方理论（`examples/lean/Settheory/Ch04Reals.lean`）：

```lean
/-- 康托集是 preCantor 集的交（逐步挖去中段）。 -/
example : (0 : ℝ) ∈ cantorSet := zero_mem_cantorSet

example : (1 / 4 : ℝ) ∈ cantorSet := quarter_mem_cantorSet

/-- 自相似方程：C = (C/3) ∪ ((2+C)/3)。 -/
example : cantorSet = (· / 3) '' cantorSet ∪ (fun x ↦ (2 + x) / 3) '' cantorSet :=
  cantorSet_eq_union_halves
```

1/4 ∈ C 是著名非平凡事实（三进制地址 0.020202… 循环只用 0/2；
端点双地址现象见第 00 章 Python 通道）。连续统记号：

```lean
example : 2 ^ ℵ₀ = 𝔠 := rfl
example : ℵ₀ < 𝔠 := by simpa using Cardinal.cantor ℵ₀
```

**连续统假设** CH 即 𝔠 = ℵ₁。Jech 在此陈述：CH 与 ¬CH 都不在
ZFC 中可证（Gödel 1938 / Cohen 1963）——这是第 13、20 两章的正
题。**Suslin 问题**紧随其后：把"可分"（有可数稠密集） weaken 成
"ccc"（两两不交开区间族至多可数），实线的特征序还唯一吗？
答案同样独立于 ZFC（第 23 章正题）。

## 4.4 Baire 纲定理

**定理 13** 可数个稠密开集的交仍稠密。

*证明*：给定区间 I，逐次取有理端点闭区间 J_{n+1} ⊆ J_n ∩ D_n
（D_n 稠密开），嵌套闭区间的交点在所有 D_n 里。∎

推论：ℚ 不是可数个开集的交（把 ℚ 的枚举点从稠密开集族中逐个
挖掉后交非空，但交与 ℚ 不交）。**"小集"的两套度量**（测度与
纲）从此并行——第 44 章 Solovay 模型会让"一切集可测"，而纲
论证永远幸存。

Julia 通道数值体验（`examples/julia/04_reals.jl`）：

```julia
function baire_intersection(depth::Int)
    holes = [(k // (depth + 1), 1 // (4 * (depth + 1)^2)) for k in 1:depth]
    survivors = [x for x in grid
                 if all(abs(x - c) >= r for (c, r) in holes)]
    return survivors
end
```

挖 3/10/50/200 个小洞后网格幸存者始终非空——有限网格上洞的
半径缩小快于数量增长，这正是"稠密开集交掉可数个洞仍剩一个
点"的数值影子（网格离散化的伪影在 docs 如实标注：幸存数随
洞数回升是有限分辨率造成的）。

## 4.5 完美集与 Cantor-Bendixson

**引理 4.2** 每个完美集（非空闭、无孤立点）有基数 2^ℵ₀——
证明是在 P 内长一棵二叉树（每个节点附近选两个分离的后继），
叶子路径与 {0,1}^ℕ 一一对应。

**定理 14（Cantor-Bendixson）** 不可数闭集 F = P ∪ S：P 完美
（非空），S 至多可数。**求导算子** A' = 极限点集迭代：

    F₀ = F，F_{α+1} = F_α'，F_λ = ⋂_{α<λ} F_α

到某可数序数 θ 稳定，P = F_θ。Python 通道把求导迭代跑了起来
（`examples/python/04_reals.py`）：

```python
def derivative(pts, eps):
    """返回 pts 中是自身极限点的那些（ε-尺度近似）"""
    out = []
    for x in pts:
        neighbors = [y for y in pts if y != x and abs(x - y) < eps]
        if neighbors:
            out.append(x)
    return sorted(out)
```

实验一：1000 点稠密块 + 5 个孤立装饰——一步求导剥掉全部装饰
（块内每点的 ε-邻域都有同伴）。实验二：康托 depth-4 网格 +
三个远处装饰点——剥壳层显示孤立点一步全剥、**完美核原封不动**
（有限影子验证 F = P ∪ S）。一个实测教训：ε 的选取必须在
"核内最小间距"（实测 2/81 而非想当然的 1/81——被挖掉的段宽
是 1/81，保留点间距 ≥ 2/81）与"装饰点到核的距离"之间，第一版
取错直接把核剥光——数值逼近的定义域敏感性的活例子。

## 4.6 Baire 空间与树

Baire 空间 𝒩 = ω^ω（自然数序列全体），基开集 U_s = {f : s ⊑ f}
（延伸有限序列 s 的全体）。**闭集 = 树的路径集**：

    树 T ⊆ Seq 对初始段封闭；[T] = {f : f 的每个初始段 ∈ T}

**引理 4.5** F 闭且完美 ⟺ T_F 完美（每个节点有两条不相容延伸）。
导树 T'（剥掉单干道节点）迭代给出 Baire 空间版的 Cantor-
Bendixson 分析。

Agda 通道（`examples/agda/Ch04_reals.agda`）构造性实现骨架：

```agda
Baire : Set
Baire = ℕ → ℕ

prefix : ℕ → Baire → List ℕ
prefix zero    f = []
prefix (suc k) f = f zero ∷ prefix k (λ n → f (suc n))

_≺_ : Baire → List ℕ → Set
f ≺ s = prefix (length s) f ≡ s

T-der : (List ℕ → Set) → List ℕ → Set
T-der T t = ∃ λ s₁ → ∃ λ s₂ →
              (T s₁) × (T s₂) × (t ⊑ s₁) × (t ⊑ s₂) × incompatible s₁ s₂
```

全树处处分叉的证明（`T-full-derived`）需要两条辅助引理：首项
不同的延伸不相容（对公共前缀归纳）、t 是 t++(a∷[]) 的初始段——
两条都是干净的构造性归纳。Prolog 通道（`04_reals.pl`）做**可执行
版**：树封闭性检查（有限域）、[T] 路径搜索（全树有任意深路径、
有限树在深度 3 断流）、导树的分叉节点查询。两个实测坑值得记：
未绑定变量的列表枚举会无限膨胀（栈溢出），必须用 `between` +
`maplist(seq_elem, S)` 把搜索限制在有限 0/1 序列域内。

## 4.7 习题精选

1. **（纸笔）** 习题 4.1：可数线性序可嵌入 ℚ（back-and-forth 的
   单向版）。
2. **（纸笔）** 习题 4.4：代数数可数 ⟹ 超越数有 2^ℵ₀ 个
   （引理 4.1 的推论）。
3. **（机器）** Baire 纲推论：ℚ ≠ G_δ（Julia 通道挖洞实验）。
4. **（纸笔）** 习题 4.8：P₂ ⊇ P₁ 完美集，则 P₂ − P₁ 有 2^ℵ₀
   个点（用习题 4.7 的区间交性质）。
5. **（机器）** Cantor-Bendixson 迭代：对自己构造的点集跑
   `cb_iterate`，观察剥壳层结构（Python 通道）。
6. **（纸笔）** 习题 4.13-4.14：连分数与无理数的一一对应
   （Baire 空间与无理数的同胚）。

---

上一章：[03 基数](docs/03-cardinals.md) · 下一章：[05 选择公理：Zorn 与良序定理](docs/05-choice.md)
