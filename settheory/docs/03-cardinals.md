# 03 · 基数：Hartogs、Cantor、Schröder-Bernstein

> 大部分集合论实际上是无穷基数的研究。——Jech §3 开篇

本章覆盖 Jech §3：等势与基数、Cantor 定理、Schröder-Bernstein
定理（区间套证明）、基数算术、aleph 阶梯、Hartogs 数、
ℵα·ℵα = ℵα、共尾性与正则/奇异、König 前奏（定理 9）。

## 3.1 等势：无穷的算术登场

|X| = |Y| 当且仅当存在 X 到 Y 的一一对应。这是全域上的等价关系，
但"基数"作为等价类的代表需要公理支持：本章对**可良序化**的集合
定义 |W| = 与 W 等势的最小序数（它显然是基数：不是更小序数的像）。
每个自然数是基数；ω 是最小无穷基数。没有选择公理时"每个集合
可良序化"不成立——基数理论的完整版要等到第 05 章。

**定理 6（Cantor）** 对每个 X：|P(X)| ≠ |X|。

*证明*：对任何 f : X → P(X)，对角集 Y = {x ∈ X : x ∉ f(x)}
不在 f 的像里——若 f(z) = Y，则 z ∈ Y ⟺ z ∉ Y。∎

对角集的构造性本质在各机器通道反复出现（第 00 章 Coq/Agda、
本章 Agda 的 `clash` 引擎、Prolog 的幂集枚举）。

**引理 3.1** |A| = κ ⟹ |P(A)| = 2^κ（特征函数对应）。
于是 Cantor 定理写成 κ < 2^κ。

## 3.2 Schröder-Bernstein：双向单射推出等势

**定理 7（Cantor-Bernstein）** |A| ≤ |B| 且 |B| ≤ |A| ⟹ |A| = |B|。

*证明*（Jech 的区间套版）：f₁ : A → B、f₂ : B → A 单。令 B' = f₂[B]、
A₁ = f₂[f₁[A]]，则 A₁ ⊆ B' ⊆ A 且 |A₁| = |A|——**化归**为：A₁ ⊆ B ⊆ A
且 f : A → A₁ 双射，要证 |A| = |B|。定义

    A₀ = A，B₀ = B，A_{n+1} = f[A_n]，B_{n+1} = f[B_n]

（注意化归后 f 的像自动落回 A 内，序列良定义）。拼接映射：

    h(x) = f(x)   若 x ∈ A_n − B_n 对某个 n
    h(x) = f⁻¹(x) 否则

读者将高兴地验证 h 是 A 到 B 的双射（Jech 原文的幽默用词）。∎

机器化分工：**Lean** 用官方 `Function.Embedding.antisymm`
（`examples/lean/Settheory/Ch03Cardinals.lean`）：

```lean
example {α β : Type} (f : α → β) (g : β → α)
    (hf : Function.Injective f) (hg : Function.Injective g) : Nonempty (α ≃ β) :=
  Function.Embedding.antisymm ⟨f, hf⟩ ⟨g, hg⟩
```

**Python** 把区间套做成算法（`examples/python/03_cardinals.py`）——
逐层计算 A_n − B_n，在层内用 f、其余用 g⁻¹：

```python
def sb_bijection(A, B, f, g):
    """给定 f: A→B、g: B→A 双单射，返回双射 h: A→B 的字典。"""
    A_set, B_set = set(A), set(B)
    B_img = {g(b) for b in B_set}          # g[B_0]
    layers = []                            # ⋃(A_n - B_n) 的成员
    An, Bn = set(A_set), set(B_img)
    for _ in range(len(A_set) + 1):
        layer = An - Bn
        layers.append(layer)
        if not layer:
            break
        An = {f(x) for x in An}            # A_{n+1} = f[A_n]
        Bn = {f(x) for x in Bn}            # B_{n+1} = f[B_n]
    ...
```

运行结果：8 点集与 4×2 网格、素数集与偶数集两组双向嵌入都拼出
了显式双射——**SB 不只是存在性定理，它是一台构造机器**。

**Coq** 侧把区间套的装备（`in_chain` 序列与嵌套引理）做成数据
结构（`examples/coq/Ch03_cardinals.v`）：

```coq
Fixpoint in_chain (n : nat) (x : A) : Prop :=
  match n with
  | O => True                          (* A_0 = A *)
  | S k => exists y, in_chain k y /\ f y = x
  end.                                  (* A_{n+1} = f[A_n] *)
```

值得记录的数学细节：嵌套引理 `A_{n+1} ⊆ A_n` 对任意 f : A → A
就可以证（x ∈ A_{n+2} 给出 x = f(y)、y ∈ A_{n+1}，归纳假设把 y
送进 A_n，于是 x ∈ f[A_n] = A_{n+1}）：

```coq
Lemma chain_nested :
  forall n x, in_chain (S n) x -> in_chain n x.
Proof.
  induction n as [|n IH]; intros x Hx.
  - exact I.
  - destruct Hx as [y [Hy Hfy]].
    exists y. split.
    + exact (IH y Hy).
    + exact Hfy.
Qed.
```

而 Jech 证明的化归步骤（把一般 f₁/f₂ 变形为单一 f）是让 g⁻¹
良定义的关键——完整拼装见 Lean 通道。

**Agda** 侧给出对角线的命题核心与具体实例
（`examples/agda/Ch03_cardinals.agda`）。这里有一个值得强调的
逻辑细节：命题引擎必须是**等式版**而非函数版：

```agda
clash : {P : Set} → ((P → ⊥) ≡ P) → ⊥
clash {P} E = fix (castF fix)
  where
   castF : (P → ⊥) → P
   castF = subst (λ X → X) E
   castB : P → (P → ⊥)
   castB = subst (λ X → X) (sym E)
   fix : P → ⊥
   fix p = castB p p
```

纯函数版 `P ↔ ¬P → ⊥` **直觉主义不可证**——没有相等提供的
transport 通道，自指造不出来（Agda 的终止检查会拒绝递归定义的
见证）。这与第 00 章 Coq 版 `nprp` 用 `match E in _ = T return T`
的 transport 是同一模式的两种语法。随后是两点域上的具体对角
构造：F(t₀) = {t₀}、F(t₁) = {t₁}，D(t₀) = {t₁}、D(t₁) = {t₀}，
每点的成员性证据（`t0-in-F : t0 ∈ℓ F t0 t0` 与 `t0-notin-D`）
显式给出。

**Prolog** 侧是有限域判定机（`examples/prolog/03_cardinals.pl`）：
回溯搜索即单射存在性——

```prolog
assign_all([], _, _, []).
assign_all([X|Xs], B, Used, [X-Y|R]) :-
    member(Y, B),
    \+ member(Y, Used),
    assign_all(Xs, B, [Y|Used], R).

equipollent(A, B) :- injective(A, B, F), surjective(A, B, F).
```

验证了 3↔3 等势、3↔2 不等势、2 嵌入 3、以及 2 元集与它的
4 元幂集无双射（Cantor 的有限影子）。

## 3.3 aleph 阶梯与 Hartogs 数

**引理 3.2** (a) 每个序数之上有更大的基数；(b) 基数集的上确界
是基数。证明的引擎是 **Hartogs 数**：

    h(X) = 最小的 α 使得没有单射 α → X

h(X) 存在（X 的子集的良序只有集合多个），且 h(α) 恰是 α⁺。
于是定义 aleph 阶梯：

    ℵ₀ = ω，ℵ_{α+1} = (ℵ_α)⁺，ℵ_λ = sup{ℵ_β : β < λ}（λ 极限）

Lean 的官方锚点（Ch03Cardinals.lean）：

```lean
example {o₁ o₂ : Ordinal} : ℵ_ o₁ < ℵ_ o₂ ↔ o₁ < o₂ :=
  Cardinal.aleph_lt_aleph

example (o : Ordinal) : Order.succ (ℵ_ o) = ℵ_ (o + 1) :=
  Cardinal.succ_aleph o
```

（`ℵ_` 记号需要 `open scoped Cardinal`；基数后继在本版 mathlib
由 `SuccOrder` 实例给出，写作 `Order.succ`。）

Julia 通道验证 Hartogs 的有限侧影（`examples/julia/03_cardinals.jl`）：

```julia
function injections_count(n::Int, alpha::Int)
    alpha > n && return 0
    return factorial(n) ÷ factorial(n - alpha)
end
```

3 元集合的单射计数：α = 0..3 时为 1, 3, 6, 6（排列数
P(3,α)），α = 4 时骤降为 0——"满了"的序数形态。有限情形
h(n) = n+1，无穷情形 h(ω) = ω₁（第一个不可数序数）。

## 3.4 ℵα · ℵα = ℵα：配对函数的胜利

**定理 8** 对每个 α：ℵα · ℵα = ℵα。

*证明*用的正是第 02 章的典范良序 γ：ωα × ωα 在 γ 下的序型
是 ωα。反证取最小反例 α，取 (β,γ) 使 γ(β,γ) ≥ ωα；更大
的 δ = max(β,γ)+1 < ωα 满足 δ×δ ⊇ 前段，于是 ωα ≤ |δ×δ| =
|δ|·|δ| = |δ| < ℵα，矛盾。∎

Julia 通道实现了 γ 配对函数并验证双射性：

```julia
function gamma_pair(i::Int, j::Int)
    m = max(i, j)
    before = m * m                       # 层 0..m-1 的总数：1+3+...+(2m-1) = m²
    if j == m
        return before + i                # (0,m)...(m,m)
    else
        return before + m + (m - j)      # (m,m-1)...(m,0)
    end
end
```

N = 3, 6, 10 的网格上断言通过：γ 是 (N+1)×(N+1) 网格到
[0, (N+1)²−1] 的**双射**——"|ω×ω| = ω"的有限影子。推论
（Jech (3.11)）：无穷基数的加法与乘法是平凡的（κ+λ =
κ·λ = max(κ,λ)），**一切戏剧性都在幂运算 2^κ**——这正是连续
统假设的位置。

## 3.5 共尾性：regular 与 singular

极限序数 α 的共尾数 cf α = 趋于 α 的最短递增序列的长度。
基本事实（引理 3.3-3.5）：cf(cf α) = cf α；cf α 总是正则基数；
ω₁、每个 ℵ_{α+1} 都正则（后者需要 AC）；ℵ_ω 是奇异的
（cf ℵ_ω = ω，由序列 ℵ₀, ℵ₁, … 趋近）。奇异基数的典例：
对每个 α，ℵ_{α+ω} 的共尾数是 ω。

**定理 9** κ < κ^cf κ。证明是对角线+共尾序列的组合：给定
κ 个函数 f : cf κ → κ，用趋于 κ 的序列 (κ_ξ) 逐点避让——
每个坐标 ξ 处避开前 κ_ξ 个函数的取值。这预告了 König 定理
（第 06 章）与不可达基数的定义：**弱不可达** = 正则极限基数
（其存在性不被 ZFC 证明；Jech 在此写下著名注释：ℵ 的不动点
序列 κ₀ = ω, κ_{n+1} = ω^{κ_n} 的极限有 cf = ω——正则不动点
需要"不可达"）。

Lean 的共尾性锚点在本版 mathlib 中是 `Order.cof`（预序的
共尾集基数下确界）：

```lean
example : Order.cof ℕ = ℵ₀ :=
  Order.cof_nat
```

ℕ（序型 ω）的共尾数是 ω——"ℵ₀ 正则"的库形态。Dedekind 有限
（D-finite）集的讨论（习题 3.11-3.13）展示了没有 AC 时基数
理论的裂缝：D-finite ≠ finite 不可证，这是第 05 章的前菜。

## 3.6 习题精选

1. **（纸笔）** 习题 3.1：有限集的封闭性（子集/并/幂集/像）。
2. **（机器）** 定理 7 的区间套算法：任取两组双向嵌入跑
   `sb_bijection`，验证值域恰为目标集（Python 通道）。
3. **（纸笔）** 习题 3.7：ω_{α+1} 是 P(ωα) 的投影
   （良序的序型投影）——定理 8 与 Cantor 的组合。
4. **（纸笔）** 习题 3.9：ℵ_α（α 极限）的 cf = cf α。
5. **（机器）** γ 配对函数的层结构：验证层 m 恰有 2m+1 个
   元素、层前总数 = m²（Julia 通道 `gamma_pair`）。

---

上一章：[02 序数](docs/02-ordinals.md) · 下一章：[04 实数的集合论构造](docs/04-reals.md)
