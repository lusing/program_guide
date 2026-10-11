# 24 · Stone-Čech 紧化

本章覆盖 Conway §V.6*：Stone-Čech 紧化 βX——每个 Tychonoff 空间的"最大"紧化。

## 核心内容

**定理**。X Tychonoff 空间。存在紧 Hausdorff 空间 βX 和稠密嵌入
ι: X → βX，使得每个有界连续函数 f: X → ℝ 唯一延拓为 βX → ℝ。

**关键性质**。
- βX 是"最大"紧化：任何其他紧化 K 是 βX 的商。
- |βℕ| = 2^2^ℵ₀（比连续统还大）。
- C_b(X) ≅ C(βX)（等距同构）。

## 机器化

mathlib 的 `StoneCech` 在 `Topology.Compactification.StoneCech`。

## 数值实验

Stone-Čech 是纯拓扑构造，数值实验有限；Julia/Python 通道仅作概念确认。

## 习题

1. **（纸笔）** 证明 βℕ 的基数是 2^2^ℵ₀。

---

上一章：[23 weak-topology](docs/23-weak-topology.md) · 下一章：[25 krein-milman](docs/25-krein-milman.md)
