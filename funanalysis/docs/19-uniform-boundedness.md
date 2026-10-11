# 19 · 一致有界原理

> 逐点有界的一致化——Baire 纲定理的又一结晶。

本章覆盖 Conway §III.14：**Banach-Steinhaus 定理**（一致有界原理），
三大原理的最后一块。

## 19.1 一致有界原理

**定理（Conway III.14）**。X Banach，Y 赋范。{Tᵢ} ⊆ B(X,Y)
是一族有界线性算子。如果对每个 x ∈ X，supᵢ‖Tᵢx‖ < ∞
（**逐点有界**），则 supᵢ‖Tᵢ‖ < ∞（**一致有界**）。

**证明（Baire 纲）**。
令 Aₙ = {x : supᵢ‖Tᵢx‖ ≤ n}。每个 Aₙ 是**闭**集
（上确界保持闭性）。X = ⋃ₙ Aₙ。Baire ⟹ 某 A_N 有内点。

A_N 有内点 + 凸性 + 对称性 ⟹ A_N 包含 δ·B_X。
于是对 ‖x‖ ≤ δ：‖Tᵢx‖ ≤ N ∀i ⟹ ‖Tᵢ‖ ≤ N/δ ∀i。∎

## 19.2 推论

**推论 1（共振定理）**。X Banach，{Tₙ} ⊆ B(X,Y)，
Tₙx → Tx 逐点收敛。则 supₙ‖Tₙ‖ < ∞ 且 T 有界。

**推论 2（发散点存在）**。supₙ‖Tₙ‖ = ∞ ⟹ 存在 x₀ 使
supₙ‖Tₙx₀‖ = ∞。而且这样的 x₀ 是**剩余集**（可数个稠密开集
之交的元素）。

**应用（Fourier 级数的发散）**。取 Tₙf = Sₙf(0)（Fourier 部分
和在 0 处的值）。可以证明 ‖Tₙ‖ = O(log n) → ∞。由推论 2，
存在连续函数 f，其 Fourier 级数在 0 处发散！这是 Banach-Steinhaus
最震撼的应用之一。

## 19.3 三大原理的统一图景

| 定理 | 核心 | 前提 |
|---|---|---|
| Hahn-Banach | 延拓 | 子空间 + 保范（**不需要完备**） |
| 开映射 | 满射开 | X, Y 完备 |
| 一致有界 | 逐点→一致 | X 完备 |

后两个都依赖 **Baire 纲定理**——完备性的力量。
Hahn-Banach 独立于完备性，它的力量来自**选择公理**（Zorn 引理）。

## 19.4 机器化

`examples/lean/Funanalysis/Ch19UniformBoundedness.lean`：
mathlib 的 `banach_steinhaus`——与 Conway III.14 精确对应。

`examples/lean/Funanalysis/Ch18OpenMapping.lean`：
mathlib 的 `ContinuousLinearMap.isOpenMap`——开映射定理的机器形态。

## 19.5 数值实验

**Julia**（`19_uniform_boundedness.jl`）：100 个随机矩阵在 100 个
单位向量上的逐点 sup ≤ 一致 sup（算子范数）。有限维中平凡成立
（定理的价值在无穷维），但数值确认了逻辑关系。

**Python**（`19_uniform_boundedness.py`）：同组实验。

## 19.6 习题

1. **（纸笔）** 证明推论 2（发散点是剩余集）。
2. **（纸笔）** Fourier 部分和算子的范数计算（‖Sₙ‖ = O(log n)）。
3. **（数值）** 构造一族范数递增的算子，验证在某点上逐点发散。
4. **（机器）** Lean：证明推论 1（共振定理）。

---

上一章：[18 open-mapping](docs/18-open-mapping.md) · 下一章：[20 locally-convex](docs/20-locally-convex.md)
