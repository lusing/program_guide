# 15 · 线性泛函与 Hahn-Banach 定理

> Hahn-Banach 定理是泛函分析的四大支柱之一。
> 它说：子空间上的有界线性泛函可以保范地延拓到全空间。

本章覆盖 Conway §III.5–§III.6：有界线性泛函的基本理论，
以及 **Hahn-Banach 延拓定理**——整个泛函分析使用最频繁的工具。

## 15.1 有界线性泛函

**命题（Conway 3.1 的赋范版）**。L: X → 𝔽 线性。以下等价：
- L 连续；
- L 在 0 连续；
- ∃c > 0：|L(x)| ≤ c‖x‖ ∀x。

有界线性泛函的全体 B(X, 𝔽) = X*（**对偶空间**）。

**范数**：‖L‖ = sup{|Lx| : ‖x‖ = 1} = sup{|Lx|/‖x‖ : x ≠ 0}。

X 完备 ⟹ X* 是 Banach 空间（𝔽 完备，B(X,𝔽) 完备）。

## 15.2 Hahn-Banach 延拓定理

**定理（Conway III.6，解析形式）**。X 是实（或复）赋范空间，
M ⊆ X 子空间。f: M → 𝔽 有界线性泛函，‖f‖_M = c。
则存在 F: X → 𝔽 有界线性泛函，使：

1. F|M = f（延拓）；
2. **‖F‖ = ‖f‖_M**（保范）。

**证明（实情形，归纳法）**。
关键一步：从 M 延拓到 M ⊕ span{x₀}（一维扩张）。
定义 F(m + tx₀) = f(m) + tα，其中 α 由不等式组约束：

sup{f(m) − c‖m + x₀‖ : m ∈ M} ≤ α ≤ inf{c‖m + x₀‖ − f(m) : m ∈ M}

（这个区间非空：Helly 的经典观察。）

然后 Zorn 引理将一维扩张推到极大。∎

**复情形**：先对实部用实 Hahn-Banach，再恢复虚部。

## 15.3 推论

**推论 1（分离点）**。x₀ ≠ 0。则存在 F ∈ X*，‖F‖ = 1，F(x₀) = ‖x₀‖。

**证明**。M = span{x₀}，f(αx₀) = α‖x₀‖，‖f‖ = 1。延拓。∎

**推论 2（范数的对偶公式）**。
‖x‖ = sup{|F(x)| : F ∈ X*, ‖F‖ ≤ 1}。

**推论 3（子空间距离的达成）**。M 闭子空间，x ∉ M。
则存在 F ∈ X*，‖F‖ = 1，F|M = 0，F(x) = dist(x, M)。

**推论 4（对偶空间足够多）**。x ≠ y ⟹ 存在 F ∈ X* 使 F(x) ≠ F(y)。

这些推论说明：**赋范空间有足够多的连续线性泛函来"看清"每个向量**。
没有 Hahn-Banach，对偶理论就会崩塌。

## 15.4 Hahn-Banach 的几何形式（第 21 章预告）

**分离定理**。A, B 是赋范空间中的不相交凸集，A 有内点。
则存在超平面分离 A 和 B（∃F ∈ X*, c，使 F(a) ≤ c ≤ F(b)）。

这是第 21 章（几何 Hahn-Banach）的主题。

## 15.5 机器化

`examples/lean/Funanalysis/Ch15HahnBanach.lean`：
mathlib 的 `exists_extension_of_le_sublinear`（Hahn-Banach 的
次线性形式，最一般版本）。

## 15.6 数值实验

**Julia**（`15_hahn_banach.jl`）：
(1) **保范延拓**：M = span{e₁,e₂} ⊂ ℝ⁵ 上的 f = (3,4)，
延拓到 ℝ⁵（取零正交补分量），‖ext‖ = 5 = ‖f|_M‖；(2) **分离
超平面**：单位球与球外点 x₀ = (3,0)，分离方向 x₀/‖x₀‖。

**Python**（`15_hahn_banach.py`）：同组实验。

## 15.7 章末对照表

| Conway | 内容 | Lean | Julia/Python |
|---|---|---|---|
| III.5 | 有界泛函 | `ContinuousLinearMap` | ✓ |
| III.6 | Hahn-Banach | `exists_extension_of_le_sublinear` | ✓ 保范延拓 |
| — | 推论 | — | ✓ 分离 |

## 15.8 习题

1. **（纸笔）** 证明复情形从实情形恢复（f = g + ih 的技巧）。
2. **纸笔）** 推论 3 的完整证明。
3. **（数值）** 实现一般子空间 M 上的 Hahn-Banach 延拓数值程序。
4. **（机器）** Lean：证明推论 1（分离点）。

---

上一章：[14 banach-spaces](docs/14-banach-spaces.md) · 下一章：[16 applications](docs/16-applications.md)
