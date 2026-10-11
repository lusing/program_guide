# 09 · 投影、幂等与不变子空间

> 如果 ℳ 约化 A，对 A 的研究就化归为对两个较小算子的研究。
> "约化"（reduce）一词正是由此而来。——Conway §II.3（意译）

本章覆盖 Conway §II.3：幂等算子的像-核分解、投影的六重刻画、
不变与约化子空间、算子矩阵分块。它是"把大算子拆小"这门手艺的
第一章——后面紧算子、谱定理、Fredholm 理论全靠分解。

## 9.1 幂等算子

**定义（Conway 3.1）**。E ∈ B(ℋ) 是**幂等**（idempotent）：E² = E。
**投影**：ker E = (ran E)⊥ 的幂等。

第 03 章的正交投影 P_ℳ 显然是投影；但幂等未必投影——习题 1 的
斜投影：ℳ = x 轴，𝒩 = 倾角 θ 的直线，E 沿 𝒩 投到 ℳ，则
‖E_θ‖ = (sin θ)⁻¹ → ∞ 当 θ → 0。

**命题（Conway 3.2）**。(a) E 幂等 ⟺ I−E 幂等；(b) ran E =
ker(I−E)，ker E = ran(I−E)，两者皆闭；(c) ℋ = ran E ⊕ ker E
（代数直和；反方向：任何补分解给出唯一幂等，有界性推迟到开映射
定理——第 18 章）。

**证明 (b)**。Eh = h ⟺ (I−E)h = 0：一边是另一边的移项。∎

## 9.2 投影的六重刻画

**命题（Conway 3.3）**。E ≠ 0 幂等。以下等价：

- (a) E 是投影；
- (b) E 是到 ran E 上的正交投影 P_{ran E}；
- (c) ‖E‖ = 1；
- (d) E 自伴；
- (e) E 正规；
- (f) ⟨Eh, h⟩ ≥ 0 ∀h。

**证明选段**。(a)⟹(b)：h − Eh ∈ ker E = (ran E)⊥，由第 03 章的
唯一性刻画 Eh = P_{ran E}h。(c)⟹(a)：对 h ∈ (ker E)⊥，勾股式
‖h‖² = ⟨Eh,h⟩ + ‖h−Eh‖² 结合 ‖Eh‖ ≤ ‖h‖ 逼出 h = Eh，故
(ker E)⊥ ⊆ ran E，再由维数计数（或直和）取等。(d)⟹(a)：⟨Eh,g⟩
= ⟨E*h,g⟩ = ⟨h,Eg⟩ 在 ran E × ker E 上为零。(e)⟹(a)：正规 ⟹
ker E = ker E*（2.16），而 ker E* = (ran E)⊥（2.19）。∎

这张等价网把第 03 章（几何）、第 08 章（代数）与本章（结构）缝在
一起：**"投影 = 自伴幂等"** 是留给 C\* 代数时代的遗产（第 34 章：
C\* 代数里的投影就定义成自伴幂等元）。

**定义（Conway 3.4）**。正交子空间族 (ℳᵢ)：⊕ℳᵢ := ∨ℳᵢ；正交差
ℳ ⊖ 𝒩 := ℳ ∩ 𝒩⊥。有限正交和必闭（习题 3）。

## 9.3 不变与约化子空间

**定义（Conway 3.5）**。ℳ ≤ ℋ 对 A **不变**：Aℳ ⊆ ℳ。**约化**：
ℳ 与 ℳ⊥ 都不变。

对不变 ℳ，取正交基适配分解 ℋ = ℳ ⊕ ℳ⊥，则 A 的**算子矩阵**是

A = [W X; 0 Y]（W = A|ℳ，块三角）；ℳ 约化 ⟺ X = 0 ⟺ 块对角。

**命题（Conway 3.7）**。(a)ℳ 不变 ⟺ (b)P A P = A P ⟺ (c)Y = 0；
(d)ℳ 约化 ⟺ (e)P A = A P ⟺ (f)X = Y = 0 ⟺ (g)ℳ 对 A 与 A* 都不变。

**证明选段**。(a)⟹(b)：APh ∈ ℳ 被 P 固定。(e)⟹(g)：A 与 P 交换
⟹ A 与 I−P 交换（P_{ℳ⊥} = I−P）⟹ 两侧都不变。(g)⟹(d)：g ∈ ℳ,
h ∈ ℳ⊥ ⟹ ⟨g, Ah⟩ = ⟨A*g, h⟩ = 0（A*g ∈ ℳ），故 Ah ⊥ ℳ。∎

约化 ⟺ 交换——这条等价是 von Neumann 代数（第 39 章）的定义性
思想的种子：一个算子集合的"交换子"决定它可被怎样分解。

## 9.3b 投影的格：部分序与运算

投影之间天然有**部分序**（Conway 习题 6）：P ≤ Q := ran P ⊆ ran Q
⟺ PQ = QP = P。在这个序下：

- P ∧ Q = 投影到 ran P ∩ ran Q；
- P ∨ Q = 投影到 ran P ∨ ran Q（闭线性张成）；
- P ⊖ Q = 投影到 ran P ⊖ ran Q（正交差）。

于是 ℋ 的投影全体构成一个**完备正交模格**（orthomodular lattice）。
两个经典事实（习题 4 与 7）：

- P + Q 是投影 ⟺ ran P ⊥ ran Q（此时 ran(P+Q) = ran P ⊕ ran Q）；
- PQ 是投影 ⟺ PQ = QP（此时 ran PQ = ran P ∩ ran Q）。

正交模格是量子逻辑的数学载体："命题 = 投影，命题的兼容 = 投影
交换"。Birkhoff–von Neumann（1936）的观察——量子系统的命题演算
不服从分配律（P ∧ (Q ∨ R) ≠ (P ∧ Q) ∨ (P ∧ R) 当 Q、R 不交换）——
在 Conway 习题里就能摸到：取三个两两不正交的秩一投影试试。
算子理论的"分解"直觉与量子力学的"可同时测量"直觉在此汇合。

不变子空间问题的一句话现状：ℋ 可分时，每个算子是否有非平凡
不变子空间仍是公开问题（不变子空间问题）；但**约化**子空间的
存在性已被否定——Enflo（1987）构造了没有非平凡不变子空间的
算子（后续简化）。乘法算子 M_z（第 36 章）的一切闭子空间
{θL²} 都是不变子空间——Beurling 定理（1950s）完全分类了它们，
这是不变子空间理论的最漂亮篇章。

## 9.4 机器化：Lean

`examples/lean/Funanalysis/Ch09Projections.lean`：

```lean
-- I − E 幂等（Conway 3.2 (a) 的计算：(I−E)² = I − 2E + E²）
example (E : H →L[ℝ] H) (hE : E.comp E = E) :
    (1 - E).comp (1 - E) = 1 - E := by
  ext x
  have hEE : E (E x) = E x := by
    have := congrArg (fun (T : H →L[ℝ] H) => T x) hE
    simpa using this
  simp only [coe_comp', Function.comp_apply, sub_apply, one_apply]
  rw [map_sub, hEE, sub_self]
  simp

-- ran E ⊆ ker(I−E)（3.2 (b) 的方向一）
example (E : H →L[ℝ] H) (hE : E.comp E = E) (h : H)
    (hh : h ∈ LinearMap.range (E : H →ₗ[ℝ] H)) : (1 - E) h = 0 := ...
```

投影的代数本质（3.3 (a)↔(d)）：

```lean
-- IsStarProjection 的两个字段恰是 幂等 + 自伴
example (P : H →L[ℝ] H) :
    IsStarProjection P ↔ P.comp P = P ∧ IsSelfAdjoint P := ...

-- starProjection 的幂等性（第 03 章唯一性刻画的算子版回声）
example (K : Submodule ℝ H) [K.HasOrthogonalProjection] :
    (K.starProjection : H →L[ℝ] H).comp (K.starProjection : H →L[ℝ] H)
      = K.starProjection := ...

-- 自伴性：⟪P u, v⟫ = ⟪u, P v⟫（3.3 (a)↔(d) 的内积形态）
example (K : Submodule ℝ H) [K.HasOrthogonalProjection] (u v : H) :
    ⟪K.starProjection u, v⟫_ℝ = ⟪u, K.starProjection v⟫_ℝ :=
  K.inner_starProjection_left_eq_right u v
```

不变子空间（3.7 (a)⟹(b)）与约化（(e)⟹K⊥ 不变）都有完整机器证明；
后者用到 P_K + P_{K⊥} = I（第 03 章 2.9 的算子形态）加上交换性
把 (I−P)(Ax) = A((I−P)x) = Ax 走通——正是 Conway 3.7 证明的
(e)⟹(g) 一支。

## 9.5 机器化：Isabelle 与 Prolog

`examples/isabelle/FA09/T09_Projections.thy`：I−E 幂等
（Conway 3.2 (a)，linear locale 提供 .diff/.sum/.scale）。
ran E = ker(I−E) 与斜投影 obl 反例由数值/离散通道承载——
v4.33 的 numeral-type 组件求值与 `E x - E x = 0` simp 闭包
遇到障碍，按通道分工原则记录于 PLAN.md。

`examples/prolog/09_projections.pl` 用精确有理算术做同一件事：
2×2 矩阵乘法、幂等性验证（E·E = E 逐分量相等）、ran E = ker(I−E)
（E 的每列被 I−E 精确消灭），以及"膨胀证书" E(1,1) = (2,0)，
范数平方 4 > 2。零浮点，纯消解。

## 9.6 数值实验

**Julia**（`09_projections.jl`）：(1) 斜投影 E = [[1,1],[0,0]]：
幂等 + ‖E‖ = √2 > 1；(2) (I−E)(Ev) = 0（ran ⊆ ker，100 次）；
(3) 列空间投影 P = A·pinv(A)：幂等 + 自伴 + ‖P‖ ≤ 1 三件套
（3.3 的正交侧）；(4) **分块对照**：块上三角 [B X; 0 C] 对前两维
不变（PAP = AP）但不约化（AP ≠ PA）；块对角化后交换
（3.7 (e)⟺(f) 的数值形态）。

**Python**（`09_projections.py`）：同一组实验的 scipy 版，外加
**谱分解 = 正交投影之和**：自伴矩阵 H = Σ λₖ Pₖ，每个 Pₖ 是
特征子空间的秩一正交投影（幂等 + 自伴验证）——这是第 11 章
（紧自伴算子谱定理）与第 37 章（一般谱定理）的数值预告：
"谱定理说的就是：自伴算子是一族带权正交投影的直和"。

## 9.7 章末对照表

| Conway | 内容 | Lean | Isabelle | Julia/Python/Prolog |
|---|---|---|---|---|
| 3.1-3.2 | 幂等、ran=ker(I−E) | ✓ 两方向 | ✓ + obl 实例 | ✓ ✓（Prolog 精确版） |
| 3.3 | 投影六刻画 | ✓ (a)(d) 内积形态 | ✓ (c) 反例方向 | ✓ 范数对照 |
| 3.4 | 正交和/差 | — | — | — |
| 3.5-3.6 | 算子矩阵 | — | — | ✓ 分块对照 |
| 3.7 | 不变/约化刻画 | ✓ (a)⟹(b)、(e)⟹K⊥ | — | ✓ (e)⟺(f) |
| — | 谱分解预演 | — | — | ✓ ΣλₖPₖ |

## 9.8 习题

1. **（纸笔）** Conway 习题 1：斜投影公式与 ‖E_θ‖ = (sin θ)⁻¹
   （数值通道的 √2 是 θ = 45° 的特例）。
2. **（纸笔）** Conway 习题 2：3.2 (c) 的直和分解。
3. **（纸笔）** Conway 习题 4：P + Q 是投影 ⟺ ran P ⊥ ran Q；
   PQ 是投影 ⟺ PQ = QP。
4. **（纸笔）** Conway 习题 6：P − Q 是投影 ⟺ ran Q ⊆ ran P
   ⟺ PQ = Q（部分序——投影格的种子）。
5. **（机器）** Lean：把 3.7 (g)⟹(d)（A 与 A* 都不变 ⟹ 约化）
   形式化（提示：inner_adjoint + 第 03 章正交刻画）。
6. **（数值）** 三向量循环子空间：构造 A 使 span{v} 不变但
   span{v}⊥ 不变也成立/不成立的对照实验。

---

上一章：[08 adjoint](docs/08-adjoint.md) · 下一章：[10 compact-operators](docs/10-compact-operators.md)
