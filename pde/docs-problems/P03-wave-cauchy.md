# P03 波动方程 Cauchy 问题（沙马耶夫 §3.1）

**对应书习题 3.1-3.9。**

- **d'Alembert 直接应用**：u_tt − 4u_xx = 0、初值 x²、1 ⟹
  u = ½[(x+2t)²+(x−2t)²]+2t（闭式 u(1,¼) = 1.75 逐位核对）；
- **依赖区间**：u(x₀,t₀) 只依赖 [x₀−2t₀, x₀+2t₀] 的初值——数据
  在区间外改动 ⟹ 解不变（数值 10⁻¹²）、穿过 ⟹ 解变；
- **非齐次 Duhamel**：u_tt − u_xx = xt 的三重积分公式残差 10⁻⁸；
- **特征平行四边形**：波方程解满足 u(A)+u(C) = u(B)+u(D)（正弦加
  法恒等式 10⁻¹⁰）。

*本章示例：`examples/p-julia/P03_wave_cauchy.jl`。*

---

[P02 分类](P02-classification.md) · [P04 弦](P04-string-fourier.md) · [返回总目录](../README.md)
