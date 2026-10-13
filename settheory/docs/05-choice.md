# 05 · 选择公理：Zorn 与良序定理

> 选择公理的独特之处：它断言集合的存在，却不给出定义。
> ——Jech §5 开篇的观察

本章覆盖 Jech §5：良序定理、Zorn 引理与 AC 的等价团、AC 在
数学中的四大应用、可数选择与依赖选择、引理 5.2（良序与下降
序列）。AC 是本书的"主角公理"：第 13 章将证明它与 GCH 的相对
一致性（在 L 中成立），第 22 章将构造它失败的模型。

## 5.1 良序定理：选择驱动的超穷枚举

**定理 15（Zermelo）** 每个集合可良序化。

*证明*：对集合 A，取其非空子集族上的选择函数 F，超穷递归定义

    a_α = F(A − {a_ξ : ξ < α})    （若剩余非空）

到某序数 θ 时 A = {a_α : α < θ}——枚举 (a_α : α < θ) 就是良序。∎

这个证明的**引擎可执行**：Julia 通道（`examples/julia/05_choice.jl`）
把 transfinite 枚举跑在有限集上：

```julia
function zermelo_enum(A::Set{Int}, F::Function)
    rest = collect(A)
    out = Int[]
    while !isempty(rest)
        a = F(Set(rest))             # 选择函数在剩余集上取元素
        push!(out, a)
        setdiff!(rest, [a])
    end
    return out, length(out)
end
```

选择函数取 `minimum` 时，{5,3,8,1,9,2} 的枚举恰为升序
[1,2,3,5,8,9]——"每个集合可良序化"的可计算影子。反方向（良序
⟹ AC）：良序化集族 S，每集取最小元即选择函数。于是 **AC ⟺
良序定理**，实数也可良序化——因此 2^ℵ₀ 是某个 aleph（2^ℵ₀ ≥
ℵ₁）。Vitali 的不可测集与"无完美子集的 2^ℵ₀ 点集"（习题 5.1）
都是良序化实数的"不愉快"后果——它们预告了第 44 章 Solovay
模型的动机。

**引理 5.1** |⋃S| ≤ |S| · sup{|X| : X ∈ S}。证明为每个 X 选定
枚举表后 ℕ 型投影 (α,β) ↦ a_αβ。推论：**每个 ℵ_{α+1} 正则**
（否则 ℵ_{α+1} 是 ≤ ℵα 个 ≤ ℵα 集的并）。这是第 03 章"正则性"
在 AC 下的兑现。可数选择的经典应用"可数并可数 = 可数"
（(5.3)）由 Julia 通道做了数值影子（20 = 4×5 的投影计数）。

## 5.2 Zorn 引理：极大元的超穷攀登

**定理 16（Kuratowski-Zorn）** 非空偏序集若每条链有上界，
则有极大元。

*证明*：选择函数逐级攀升 a_α > a_ξ (ξ<α)；极限步取链上界；
最终停在某个 θ——a_θ 无严格上邻，即极大元。∎

**反向（习题 5.3）**：Zorn ⟹ AC——对"部分选择函数"的偏序
(P, ⊆)（f 是某子族 Z ⊆ S 上的选择函数）用 Zorn：链的并是
选择函数（上界），极大元必须定义在整个 S 上（否则可再扩张）。

mathlib 的机器形态（`examples/lean/Settheory/Ch05Choice.lean`）：

```lean
example (α : Type) [PartialOrder α]
    (h : ∀ c : Set α, IsChain (· ≤ ·) c → BddAbove c) : ∃ m : α, IsMax m :=
  zorn_le h

example (α : Type) (S : Set (Set α))
    (h : ∀ c ⊆ S, IsChain (· ⊆ ·) c → ∃ lb ∈ S, ∀ s ∈ c, lb ⊆ s) :
    ∃ m, Minimal (· ∈ S) m :=
  zorn_superset S h
```

Isabelle/ZF 有更深的历史资产（`examples/isabelle/ST05/Choice.thy`）：
Paulson 团队形式化了 Rubin 夫妇《Equivalents of the Axiom of
Choice, II》的大批等价形式（**ZF-AC 会话**：WO1-WO7、AC1-AC19
等 16 个理论文件），Zorn 引理在 `ZF/Zorn.thy`：

```isabelle
thm Zorn            (* 链并封闭的族有极大成员 *)
thm WO1_WO7         (* 良序定理的等价团 *)
thm DC0_imp_DC_nat  (* 依赖选择的等价链 *)
```

Julia 的 Zorn 爬山程序在菱形格（1<2<4, 1<3<4）与双峰偏序上
演示贪心链延伸——双峰例子显示 **Zorn 只保证"某个"极大元**，
到达哪一个取决于选择函数。

## 5.3 AC 的公理记账：各通道的身份

AC 在四个证明通道里身份迥异——这是本章机器化的主菜。

**Lean**：`Classical.choice` 是类型论的三大经典公理之一
（choice / propext / excludedMiddle）。它是"全局选择"——比 ZFC
的 AC 更强一档（选择任何非空类型的元素，包括真类尺度的）。
mathlib 的一切经典推理都在它的荫蔽下。

**Coq**：标准库把 AC 包装成可记账的定理（`examples/coq/Ch05_choice.v`）：

```coq
Require Import ClassicalChoice.

Theorem selector_exists :
  exists f : A -> A, forall x, R x (f x).
Proof.
  apply (choice (A := A) (B := A) R R_total).
Qed.

Print Assumptions selector_exists.
```

运行 `Print Assumptions` 报告 `Axioms: relational_choice,
dependent_unique_choice ...`——**选择公理作为假设显式入账**。
Coq 的 AC 体系（ChoiceFacts.v）是一整座"等价形式群"：
FunctionalChoice、RelationalChoice、DependentChoice 之间的
推导图全部形式化。

**Agda**：构造性世界拒绝全局 AC，但**有限选择是免费的**
（`examples/agda/Ch05_choice.agda`）：

```agda
record Family (n : ℕ) : Set₁ where
  field
    Carrier : ℕ → Set
    elem : (i : ℕ) → (i < n) → Carrier i

finiteChoice : (n : ℕ) (F : Family n) → (i : ℕ) → (i < n) → Carrier F i
finiteChoice n F i i<n = elem F i i<n
```

`finiteChoice` 平凡到近乎无聊——但正中要害：**有限家庭把选择
做进了数据结构**（Σ 类型的编码已经包含选择）。无穷家庭要求
`elem : ∀ i, Carrier i` 一次性给出——"接受 Σ 家族"与"已经
选择"在构造性世界里是一回事。AC 的非构造性精确落在有限/
无穷的分界上。

**Prolog**：有限域上 AC 免费兑现（`examples/prolog/05_choice.pl`）——
回溯即选择：

```prolog
choice_function([], []).
choice_function([Name-Elems|Rest], [Name-X|CRest]) :-
    member(X, Elems),
    choice_function(Rest, CRest).
```

三成员族（大小 2,1,3）的选择函数恰有 2×1×3 = 6 个——乘积
结构就是"选择空间"的形状。

## 5.4 可数选择与依赖选择

**可数选择**（AC_ω）：可数族的非空集有选择函数。它足够推出
"可数并可数 = 可数"、ℵ₁ 正则、每个无穷集有可数子集，但推不出
实数可良序化。**依赖选择**（DC）：关系 R 处处有后继 ⟹ 存在
无穷 R-链。DC 强于 AC_ω（习题 5.7），它精确刻画良基性：

**引理 5.2**（需要 DC）：
(a) 线性序是良序 ⟺ 无无穷下降序列；
(b) 关系良基 ⟺ 无无穷下降序列（bₙ₊₁ E bₙ 型）。

Isabelle/ZF 通道机器化了不需要 DC 的方向（下降序列破坏良序，
`ST05/Choice.thy` 的 `descending_breaks_wellorder`）：

```isabelle
lemma descending_breaks_wellorder:
  assumes wo: "∀A. A ≠ 0 ⟶ (∃m ∈ A. ∀x ∈ A. ⟨x, m⟩ ∉ r)"
    and seq: "f: nat → field(r)"
    and desc: "∀n ∈ nat. ⟨f`succ(n), f`n⟩ ∈ r"
  shows "False"
proof -
  let ?A = "{f`n . n ∈ nat}"
  have Ane: "?A ≠ 0" by blast
  from wo Ane obtain m where "m ∈ ?A"
    and min: "∀x ∈ ?A. ⟨x, m⟩ ⟩ ∉ r" by blast
  then obtain n where m: "m = f`n" and "n ∈ nat" by blast
  ...
qed
```

值域 {f`n : n ∈ nat} 的极小元 m = f`n，但下降步给 f`n₊₁ 更小
——矛盾。Python 通道（`examples/python/05_choice.py`）做数值
对照：ℕ 上从 n0 下降恰 n0 步终止；ℤ 上构造任意长的下降序列
（`list(range(0, -10, -1))` 型）；外加 Vitali 式构造的影子——
[0,1) 网格模 1/6 的等价类有 10 个（每类 6 点），**最小元选择
函数存在是因为类是良序的有限集**；ℚ-等价类在 ℝ 中稠密、无
最小元——最小元策略失效，代表的存在必须诉诸 AC。这就是
Vitali 构造的"选择点"。

## 5.5 AC 在数学中的四大应用

Jech 列出的经典：**(a)** 每个向量空间有基（对线性无关族用
Zorn）；**(b)** 代数闭包的存在唯一；**(c)** Hahn-Banach 延拓；
**(d)** Tychonoff 紧性。四个证明的骨架都是"Zorn 式超穷构造 +
唯一性验证"。泛函分析教程（本仓库 funanalysis）已把 (c) 完整
机器化——两个教程在此握手。

## 5.6 习题精选

1. **（纸笔+机器）** 习题 5.1：存在无完美子集的 2^ℵ₀ 点集
   （良序化实数后对完美集族双递归选点——Julia 的 zermelo_enum
   是其引擎的有限版）。
2. **（纸笔）** 习题 5.2：无穷集的有限子集族与原集等势。
3. **（纸笔）** 习题 5.3：Zorn ⟹ AC（部分选择函数的链并论证）。
4. **（纸笔）** 习题 5.7：DC ⟹ 可数 AC（选择函数前段的链论证）。
5. **（机器）** 引理 5.2 的两个方向：Prolog 的 `desc_seq` 生成
   无底序的下降链；Python 的 ℤ 对照实验。

---

上一章：[04 实数](docs/04-reals.md) · 下一章：[06 基数算术：κ^λ、连续统假设与 König](docs/06-cardinal-arith.md)
