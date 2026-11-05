# 43 单调性方法与不动点定理

**对应书 §9.1（单调算子、Minty-Browder）与 §9.2（Banach、
Schauder、Schaefer 不动点）。**

- **Banach 压缩**：Picard 迭代线性收敛，速率 = Lipschitz 常数；
- **Schauder**：紧连续映射 + 不变球 ⟹ 不动点（存在，无唯一）；
- **单调算子**：⟨Tu−Tv, u−v⟩ ≥ 0 + 强制 ⟹ 唯一弱解
 （Minty-Browder，p-拉普拉斯类）。

Julia（`43_fixed_points.jl`）：Picard 比率逐对 0.5（压缩签名）；
Newton 二次收敛对照；Green 核积分算子的 Schauder 迭代（不动点残
差 0.00e+00）；s ↦ |s|s 的单调性抽样（⟨·⟩ ≥ 0）。

要点：不动点三定理按"压缩/紧/单调"分类；每一类都有可计算的收敛
或存在签名。

*本章示例：`examples/julia/43_fixed_points.jl`。*

---

上一章：[42 山路定理](42-mountain-pass.md) · 下一章：[44 上下解、非存在与梯度流](44-subsupersolutions.md) · [返回目录](../README.md)
