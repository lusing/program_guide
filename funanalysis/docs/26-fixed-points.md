# 26 · 不变子空间与不动点定理

> 凸性 + 紧性 = 不动点。

本章覆盖 Conway §V.9–§V.13*：Schauder 不动点定理、Ryll-Nardzewski、
Haar 测度、Krein-Šmulian 定理、弱紧致性。

## 26.1 Schauder 不动点定理

**定理（Conway V.9）**。K 是 Banach 空间中的非空紧凸集，
T: K → K 连续。则 T 有不动点。

**证明思路**。有限维逼近：取有限 ε-网，投影到有限维子空间，
用 Brouwer 不动点定理，然后 ε → 0。∎

（有限维情形 = **Brouwer 不动点定理**。）

## 26.2 Markov-Kakutani 定理

**定理**。K 紧凸，{Tᵢ} 是交换的连续仿射自映射族。则
存在公共不动点。

**证明思路**。对有限个映射取平均值迭代，用紧性取极限。∎

**应用**：不变测度的存在性（遍历论的 Markov-Kakutani）。

## 26.3 Ryll-Nardzewski 定理

**定理**。K 弱紧凸，G 是一群仿射等距自映射。则存在公共不动点。

（比 Markov-Kakutani 弱的紧性假设 + 更强的映射结构。）

## 26.4 Haar 测度

**定理（Conway V.11）**。G 紧 Hausdorff 群。则 G 上存在唯一的
左不变正则 Borel 概率测度 μ（Haar 测度），满足：
- μ(gA) = μ(A) ∀g ∈ G（左不变）；
- μ(G) = 1（概率）；
- ∫f(g⁻¹x)dμ(x) = ∫f(x)dμ(x)（不变积分）。

**证明思路**。用 Markov-Kakutani 或 Ryll-Nardzewski：
不变测度集是 C(G)* 的弱*紧凸集，平移作用是仿射等距。∎

## 26.5 Krein-Šmulian 定理

**定理（Conway V.12）**。X Banach，M ⊆ X* 是**线性子空间**。
M 弱*闭 ⟺ M ∩ (n·ball X*) 弱*闭 ∀n。

（只需在球上检查闭性——全局闭性的局部化判据。）

## 26.6 弱紧致性

**定理（Conway V.13）**。K ⊆ X 弱闭凸。K 弱紧 ⟺
K 与 X* 的每个球之交弱*紧。

（结合 Alaoglu + 自反性判据。）

## 26.7 数值实验

**Julia**（`26_fixed_points.jl`）：归一化映射迭代收敛到不动点
（Brouwer 有限维原型）；圆周均匀采样 mean ≈ 0.5（Haar 测度）。

**Python**（`26_fixed_points.py`）：同组实验。

## 26.8 习题

1. **（纸笔）** Schauder 不动点的有限维逼近证明。
2. **（纸笔）** Haar 测度的唯一性。
3. **（数值）** 实现圆周上的 Haar 积分数值验证。

---

上一章：[25 krein-milman](docs/25-krein-milman.md) · 下一章：[27 adjoint-banach](docs/27-adjoint-banach.md)
