# 08 · 奇异基数、共尾性与不可达

> 奇异基数的幂运算是最深的算术：除非大基数存在，否则一切由
> 正则值决定。——Jech §8 的主旨

本章覆盖 Jech §8：奇异基数假设（SCH）、引理 8.1（SCH 下幂运算
的完全确定）、Silver 定理、Galvin-Hajnal 定理、几乎不交族技术
（引理 8.4-8.7）、范数 ‖φ‖。

## 8.1 SCH：奇异处的算术假设

**SCH**：对每个奇异 κ，若 2^cf κ < κ，则 κ^cf κ = κ⁺。

GCH ⟹ SCH（直接）。SCH 的含义：奇异处的幂取**最小可能值**
（κ^cf κ ≥ κ 因 cf 序列的覆盖；≥ κ⁺ 由 König）。**引理 8.1**：
SCH 下幂运算被"正则值 + 共尾函数"完全决定——(8.2) 的三分支
表格：κ^λ = κ（当 2^λ ≤ κ 且 λ < cf κ）；κ⁺（当 2^λ < κ 且
λ ≥ cf κ）；2^λ（当 2^λ > κ）。

**Jensen 覆盖引理的推论**（第 33 章正题）：SCH 失败 ⟹ 0# 存在。
反之在大基数下 SCH 可失败（Magidor：2^ℵ_n = ℵ_{n+1} 而
2^ℵ_ω = ℵ_{ω+2} 一致）。**奇异基数的算术是大基数的探针。**

## 8.2 Silver 定理：GCH 的传染

**定理 23（Silver）** (a) cf κ > ω 的奇异 κ，若 GCH 在 κ 下方
成立，则在 κ 成立；(b) SCH 对共尾 ω 的奇异成立 ⟹ 对一切奇异
成立。

**定理 24（Galvin-Hajnal）**：强极限奇异 κ（cf κ > ω）满足
κ < ℵ_α ⟹ 2^κ < ℵ_α。

证明链的**组合核**是几乎不交函数族：f, g ∈ Π A_α **几乎不交**
（除有界多处外 f(α) ≠ g(α)）。Prolog 通道（`examples/prolog/08_adf.pl`）
把判定做成可执行：

```prolog
almost_disjoint(F, G) :-
    length(F, N), length(G, N),
    N1 is N - 1,
    between(0, N1, B),          % 至少检查一位（排除 B=N 的平凡真）
    tail_distinct(F, G, B, N), !.
```

（实测坑：`between(0, N, B)` 允许 B=N——"空尾部平凡真"会让
f 与自身"几乎不交"；必须 B ≤ N−1 保证至少检查一位。）

Coq 通道（`Ch08_sch.v`）给出几乎不交的公理化定义与常值族验证：

```coq
Definition almost_disjoint (f g : nat -> nat) : Prop :=
  exists B, forall i, B <= i -> f i <> g i.

Lemma const_family_ad :
  forall (u v : nat -> nat),
    (forall i, u i <> v i) -> almost_disjoint u v.
```

**引理链的骨架**（ℵ_ω₁ 特例）：
- **引理 8.5**（基线）：|A_α| ≤ ℵ_α 且 {|A_α| ≤ ℵ_{α+1}} 平稳
  ⟹ |F| ≤ ℵ_{ω₁}——Fodor 把 f 的值域压到有界层；
- **引理 8.4**：{|A_α| ≤ ℵ_{α+1}} 平稳 ⟹ |F| ≤ ℵ_{ω₁+1}
  ——逐层剥壳的贪心序列；
- **引理 8.7**（统一形态）：|A_α| ≤ ℵ_{α+φ(α)} ⟹
  |F| ≤ ℵ_{ω₁+‖φ‖}——**范数** ‖φ‖ 按 club-模支配关系
  φ < ψ ⟺ {α : φ(α) ≤ ψ(α)} thin 的良基 rank。

范数的可计算侧影（Python `08_norm.py` / Julia `08_silver.jl` /
Prolog `norm_chain`）：有限域用**最终支配**（eventual dominance）
做代理——`[2,6,7,8,4]` 从某位起逐点大 `[1,5,2,9,3]`；降链长度
（逐点 −1 到零的步数 = max+1）是 rank 的离散化身。范数分箱
（‖φ‖ = max(φ) 的箱）演示"每层一箱、箱有上界"的归纳结构。

## 8.3 beth 阶梯与强极限：Lean 侧

mathlib 的 beth 函数是官方资产（`Ch08Singular.lean`）：

```lean
example (o : Ordinal) :
    Cardinal.IsStrongLimit (ℶ_ o) ↔ Order.IsSuccPrelimit o :=
  Cardinal.isStrongLimit_beth

example (o : Ordinal) : ℶ_ o < ℶ_ (o + 1) :=
  Cardinal.beth_lt_beth.2 (by simp)

example (ho : Order.IsSuccLimit ω) : ℵ_ ω = ⨆ a : Set.Iio ω, ℵ_ a :=
  Cardinal.aleph_limit ho
```

beth_zero/succ/limit 三条款与 aleph 的镜像平行（GCH ⟺ ℶ_α =
ℵ_α）。实测坑两条入册：`IsSuccPrelimit`/`IsSuccLimit` 在
**Order 命名空间**（Order.SuccPred.Limit）；`open scoped Cardinal`
会把 ω 劫持为 aleph0——与 Ordinal.omega0 混用时直接撞类型。
Isabelle/ZF 侧（`ST08/Singular.thy`）锚定 **csucc**（后继基数的
官方构造：csucc_basic + csucc_le）——ℵ 链的一步步攀升：

```isabelle
thm csucc_basic    (* Card(csucc(K)) ∧ K < csucc(K) *)

lemma csucc_iterates_grow:
  assumes "Ord(K)" shows "K < csucc(K)"
  by (rule csucc_basic [OF assms, THEN conjunct2])
```

Silver 链条在计算通道的完整对应：Julia 的 beth 表 + 传染表格
（ℵ_α | 2^ℵ_α = ℵ_{α+1} | ✓ 一路打勾到 κ = ℵ_{ω₁} 处 Silver
强制成立）+ Magidor 反例的注释（cf κ = ω 时传染失败）。

## 8.4 习题精选

1. **（纸笔）** 习题 8.1：平稳集上 2^ℵ_α ≤ ℵ_{α+β} ⟹
   2^ℵ_{ω₁} ≤ ℵ_{ω₁+β}（对 β 归纳——范数 ‖φ‖ ≤ β）。
2. **（纸笔）** 习题 8.3：共尾 ω 的 SCH 蕴含一切奇异。
3. **（机器）** almost_disjoint 判定器的边界：构造三组函数
   分别命中"几乎不交 / 有限交 / 自撞"三态（Prolog）。
4. **（纸笔）** 习题 8.8-8.9：Galvin-Hajnal 型上界的 ℵ_γ 形式。

---

上一章：[07 滤子与 club](docs/07-filters.md) · 下一章：[09 正则公理、秩层级与 BG 类理论](docs/09-foundation.md)
