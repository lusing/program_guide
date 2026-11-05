# 39 Euler-Lagrange 方程与二阶变分

**对应书 §8.1（变分法：一阶变分/E-L 方程、二阶变分、系统）。**

泛函 I[w] = ∫L(∇w,w,x) 的一阶变分消失给出 **Euler-Lagrange 方程**；
二阶变分的符号（Legendre 条件）判定极小/鞍点。Julia
（`39_euler_lagrange.jl`）：I = ∫(½u′² − u³/3) 的 E-L 方程 −u″ = u²
牛顿求解（残差 3×10⁻²⁶），扰动能量的导数在解处为 0（数值 E-L，
10⁻¹³），二阶变分 +4.93 > 0（小解分支是局部极小）。

要点：变分问题 ⟺ 弱解方程（一阶条件）；二阶变分是稳定性判据。

*本章示例：`examples/julia/39_euler_lagrange.jl`。*

---

上一章：[38 半群](38-semigroups.md) · 下一章：[40 直接方法](40-direct-method.md) · [返回目录](../README.md)
