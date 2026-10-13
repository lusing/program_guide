# 12 · 可构造层级：Gödel 的 L

> L 是最瘦的内模型：只用"可定义"这一把刀，从序数里雕刻出
> 全部集合论。——V=L 的世界观

本章覆盖 Jech §12：Gödel 闭包与 def(U)、可构造层级 L_α、
定理 32（L ⊨ ZF + V=L + 最小性）、绝对性理论（引理 12.1 的
Δ₀ 大表与非绝对概念清单）、绝对运算。

## 12.1 def(U)：可定义子集

**Gödel 闭包** cl(X)：对 X 施行十个 Gödel 运算 F₁-F₁₀
（配对、投影、并、差、交、笛卡尔积、dom、ran、限制……）的
有限复合。定义

    def(U) = cl(U ∪ {U}) ∩ P(U)

——闭包落回 U 的子集族。**习题 12.2**（正规形式定理的推论）：
对传递 U，每个公式 φ 给出 Gödel 运算 γ 使 {u ∈ U : φ} =
γ(U, x's)；反之（习题 12.4）Gödel 运算可由受限公式刻画。
于是 **def(U) = U 上可定义的子集族**（习题 12.3/12.5 的桥）。

**习题 12.6**：有限传递 U 上 def(U) = P(U)——布尔组合已经
够用。计算通道把这一点做成了**可执行验证**。Julia
（`examples/julia/12_constructible.jl`）先实现 Gödel 运算
的代表（F₁ 配对、⋃、−、∩，配合规范化字符串集合）：

```julia
g_pair(x, y) = norm_set([x, y])
g_union(x) = norm_set(vcat([members(m) for m in members(x)]...))
g_diff(x, y) = norm_set(setdiff(members(x), members(y)))
```

Python（`12_constructible.py`）实现 def 的**受限公式枚举**：

```python
def def_finite(U):
    n = len(U)
    atoms = []
    for a in U:
        amem = set(parse_members(a))
        atoms.append([U[i] in amem for i in range(n)])   # u ∈ a
        atoms.append([U[i] == a for i in range(n)])      # u = a
    combos = list(atoms)
    for p in atoms:
        combos.append([not x for x in p])
        for q in atoms:
            combos.append([p[i] and q[i] for i in range(n)])
            ...
```

V₂ = {∅, {∅}} 上 def(V₂) 给出全部非空子集——有限层 def = P
的数值印证。Coq（`Ch12_def.v`）做受限公式的**可判定语义**：
atom/rform 深嵌入 + eval2 + `defined_subset`，三个 reflexivity
断言（u=1、u∈1 的单点集）。Prolog（`12_def.pl`）同构检查器
——实测坑：Prolog 的 `(A ; B) -> C` 在 A、B 皆真时**双解**，
findall 双计；nand 要写成函数式三条款。Agda（`Ch12_def.agda`）
的 FiniteU record + Δ 公式代数，`eval-eq1 : ... ≡ true` 的
refl 验证。

## 12.2 可构造层级

    L₀ = ∅；L_{α+1} = def(L_α)；L_λ = ⋃_{β<λ} L_β；L = ⋃ L_α

L_α ⊆ V_α（归纳）；α ⊆ L_α 且 **L_α ∩ Ord = α**（序数绝对性
(11.28) 的应用）。元素 of L 称**可构造集**；**公理 V=L**：每
个集合可构造。

**Isabelle/ZF 的官方形态**（`ST12/Constructible.thy`）——
Formula.thy 的 **Lset 与 DPow**：

```isabelle
thm Lset          (* Lset(i) = ⋃j∈i. DPow(Lset(j)) *)
thm LsetI         (* A ∈ DPow(Lset(y)) ⟹ A ∈ Lset(x) *)
thm LsetD         (* A ∈ Lset(x) ⟹ ∃y∈x. A ∈ DPow(Lset(y)) *)
thm Lset_mono     (* 层级的累积性 *)
thm DPow_def      (* def 的语义 *)
thm Ord_in_Lset   (* 序数进层：L_α ∩ Ord = α 的基线 *)
```

**Lset 的递归方程 = (12.2) 的逐字机器化**（DPow 即 def）——
这是 Paulson 为 AC+GCH 相对一致性准备的核心资产（第 13 章
直接使用）。

## 12.3 定理 32：L 的三重身份

**(i) L ⊨ ZF**：L 传递（累积层级）；封闭（极限层的闭包
验证）；几乎通用（L 的任何子集被某 L_α 收纳）。**(ii)
L ⊨ V=L**：L 的层级对 L 自身自描述（可定义性在 L 内部可
定义——第 14 章 Σₙ 理论的精细工作）。**(iii) 最小性**：
任何含全序数的传递 ZF 模型 𝔐 ⊇ L（对层级归纳：L_α 的
构造材料 𝔐 全有）。

于是 **Con(ZF) ⟹ Con(ZF + V=L)**——第一条内模型定理。

## 12.4 绝对性：L 的通行证

**引理 12.1**（Δ₀ 大表）：以下概念可写成受限公式，对一切
传递类绝对：配对/有序对/空集/⊆/传递/序数/极限序数/自然数/
ω；F₁-F₁₀ 的运算；关系/函数/dom/ran/限制/像。

**非绝对清单**（关键反例）：Y = P(X)、|X| = |Y|、"α 是基数"、
cf(α) = β、"α 正则"。原因：幂集与双射** witnessing 逃逸**
——L 内的 P^L(X) 可以严格小于 P(X)（L 缺"外部"子集）。

**习题 12.10**（向下绝对性的限度）：𝔐 ⊨ |X| ≤ |Y| ⟹
真 |X| ≤ |Y|（ witnessing 双射绝对）；α 是基数时 𝔐 ⊨ "α
是基数"；但**逆不真**——𝔐 内的"基数"外部可能是双射猎物。

绝对性理论是第 13 章（AC+GCH 在 L）的引擎：L_α 的每层只加
可定义子集 → GCH 的基数控制（|L_α| = |α| 的归纳链）→ CH
在 L 中成立的组合学。

## 12.5 L 的增长叙事（数值对照）

Julia 的对照表：L_n = V_n 直到 ω 层（|·| 都 0,1,2,4）；ω 层
两者 = HF（可数）；**ω+1 层戏剧性分歧**：|V_{ω+1}| = 2^ℵ₀
vs |L_{ω+1}| = ℵ₀（HF 上只有可数个**可定义**子集！）。L 从
此永久变瘦：|L_{ω₁}| = ℵ₁。这条"瘦化"曲线正是 GCH 在 L
成立的几何直觉——L 的每层由下方层的**可定义**图像构成，
增长被公式数（|α| 个）封顶。

## 12.6 习题精选

1. **（纸笔）** 习题 12.2：正规形式定理 ⟹ 公式→Gödel 运算。
2. **（机器）** def 计算器扩展到 V₃（4 元传递集）：验证
   def(V₃) = P(V₃)（习题 12.6 的 4 元版——Julia/Python）。
3. **（纸笔）** 习题 12.7：L_ω = V_ω（HF 层重合）。
4. **（纸笔）** 习题 12.10：向下绝对的 witnessing 论证。
5. **（纸笔）** 定理 32(iii) 的最小性归纳。

---

上一章：[11 传递模型](docs/11-transitive.md) · 下一章：[13 L 是 ZFC 的模型：AC 与 GCH 在 L 中](docs/13-L-model.md)
