# 25 · Krein-Milman 定理与 Stone-Weierstrass 定理

> 紧凸集由其极点完全确定；紧空间上的连续函数由分离子代数逼近。

本章覆盖 Conway §V.7–§V.8。

## 25.1 极点

**定义**。K 凸集，x ∈ K 是**极点**（extreme point），若
x = ty + (1−t)z（0 < t < 1, y,z ∈ K）⟹ y = z = x。

**例子**。
- 闭单位球 in ℓ²：极点 = 整个球面。
- 闭单位球 in ℓ¹：极点 = {±eₙ}（可数）。
- 闭单位球 in c₀：**没有极点**！（Krein-Milman ⟹ c₀ 球不紧 in 弱拓扑——c₀ 不自反）

## 25.2 Krein-Milman 定理

**定理（Conway V.7）**。K 是局部凸空间中的非空**紧**凸集。
则 K 有极点，且 K = **cl(conv(ext K))**（极点集的闭凸包）。

**证明思路**。
1. 用 Zorn 引理找极小紧凸子集。
2. 极小紧凸子集只有一个点（用分离定理分裂）。
3. 该点就是极点。
4. cl(conv(ext K)) ⊇ K 由极大性。∎

**应用**。
- **对偶球的面结构**：X* 的弱*紧球由极点生成。
- **三角不等式的极点刻画**。
- **遍历论**：不变测度集是紧凸集，其极点是"极小遍历测度"。

## 25.3 Stone-Weierstrass 定理

**定理（Conway V.8，实形式）**。X 紧 Hausdorff，A ⊆ C(X,ℝ)
是**子代数**（含常数，分离点）。则 A 在 C(X,ℝ) 中**稠密**。

**证明思路**。
1. 首先逼近 |x|（Weierstrass 多项式逼近 t ↦ |t|）。
2. 由 |·| 得 max/min：sup(f,g) = (f+g+|f−g|)/2。
3. 格运算封闭 ⟹ 可逼近阶梯函数 ⟹ 稠密。∎

**复形式**：需要 A 对共轭封闭（否则 ℂ 中全纯函数代数是反例）。

**应用**：Fourier 级数的稠密性、多项式逼近、神经网络万有逼近定理。

## 25.4 机器化

mathlib 的 `closure_convexHull_extremePoints`（Krein-Milman 完整形式）+
`ContinuousMap.subalgebra_topologicalClosure_eq_top_of_separatesPoints`（Stone-Weierstrass）。

## 25.5 数值实验

**Julia**（`25_krein_milman.jl`）：三角形极点 = 3 顶点，
凸组合 = 内点，验证"三角形 = conv(3 极点的闭包)"。

**Python**（`25_krein_milman.py`）：同组实验。

## 25.6 习题

1. **（纸笔）** 证明 c₀ 的球没有极点。
2. **（纸笔）** Stone-Weierstrass 的复形式反例（全纯函数）。
3. **（数值）** Weierstrass 逼近 |x| 的多项式实验。

---

上一章：[24 stone-cech](docs/24-stone-cech.md) · 下一章：[26 fixed-points](docs/26-fixed-points.md)
