# P05 抛物方程（沙马耶夫 §4.1-4.2）

**对应书习题 4.1-4.43。**

- **半直线 erfc 解**：u(0,t)=u₀ ⟹ u = u₀·erfc(x/2√t)（残差
  10⁻⁶，边界逐位 u₀）；
- **周期初值**：g = 1+½sin(3x) ⟹ u = 1+½e^{−9t}sin(3x)（模式
  衰减）；
- **逆问题**：反推初值放大 e^{k²T}（k=5、T=0.1 时 12 倍——不适
  定的习题面）；
- **非齐次 Cauchy**：f = e^{−t}cos x 的解 u = t·e^{−t}cos x
  （A′+A = e^{−t} 的特解 A = te^{−t}——不是 Ae^{−t}，那是齐次
  解！残差 10⁻⁷）。

*本章示例：`examples/p-julia/P05_heat.jl`。*

---

[P04 弦](P04-string-fourier.md) · [P06 椭圆](P06-elliptic.md) · [返回总目录](../README.md)
