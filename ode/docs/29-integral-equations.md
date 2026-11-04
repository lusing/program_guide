# 29 积分方程

**对应书 §11 Integral Equations：Fredholm、逐次逼近、Volterra、差
核与 Laplace 变换、应用。**

---

## 29.1 从微分到积分：同一件事的另一副面孔

第 01 章埋下的种子在此发芽：IVP y′ = f(x, y)、y(x₀) = y₀ 等价于
**积分方程**

    y(x) = y₀ + ∫_{x₀}^x f(t, y(t)) dt，

把未知函数搬到积分号下。一般地：

    **Fredholm 第二类**：y(x) = f(x) + λ∫_a^b K(x, t)y(t) dt；
    **Volterra 第二类**：y(x) = f(x) + λ∫_a^x K(x, t)y(t) dt。

区别在上限：Fredholm 的区间固定 [a, b]（全局耦合），Volterra 的
上限是 x（因果/三角结构）。核 K 是"权重函数"，描述 x 处的解如何
被 t 处的值影响。第一类（y 只出现在积分号下）是不适定问题的雷
区，本书聚焦第二类。

## 29.2 逐次逼近：Picard 的直接推广

    y₀ = f，yₙ₊₁ = f + λK[yₙ]    （K 是积分算子）

误差账：‖Kⁿ‖ ≤ Mⁿ(b−a)ⁿ/n!（Volterra 三角结构给出 n! 压缩——
**对一切 λ 收敛**）；Fredholm 的界是 (M(b−a))ⁿ（几何收敛，只在
|λ| 小时收敛，或 K 足够小）。收敛的极限满足方程——存在性证明与
算法二合一（第 01 章 Picard 迭代的直接推广）。

解可以展开成 **Neumann 级数** y = Σ λⁿKⁿf——与线性代数的
(I − λK)⁻¹ = Σ λⁿKⁿ 逐字对应：**积分算子谱理论**的入口。共振
（λ 是特征值）时级数发散——Fredholm 择一重现。

## 29.3 差核的 Laplace 变换

Volterra 方程的核**只依赖差** K(x − t)（卷积核）时：

    y = f + λK ∗ y    ⟹（取变换）Y = F/(1 − λK̂(s))，

代数化！反变换即解。书 §11.5 的例子：K = e^{−(x−t)} 型（RLC 电
路的记忆核）、abel 方程（K = 1/√(x−t)，tautochrone 等时曲线的
反演）。应用三例（书 §11.6）：落体（m(t)v′ = mg 化成的积分方
程）、种群动力学（遗传效应核）、黏弹性（Boltzmann 叠加原理：
应变是应力的卷积历史）。

## 29.4 机器验证

**Julia（`29_fredholm.jl`）/ Python（`29_fredholm.py`）**：
(a) Neumann 级数数值：K = 1（退化核）的 Fredholm，精确解
y = f/(1 − λ(b−a)) 对照迭代（收敛几何率 |λ(b−a)|）；
(b) Volterra 收敛：K(x,t) = x − t、f = 1、λ = 1，逐次逼近 6 轮
与 RK4 解 IVP y′ = 1 + ∫...（转导数形式数值解）对照；
(c) 差核 Laplace：K = e^{−(x−t)}、f = 1：Y = 1/[s(1 − λ/(s+1))]，
反变换（部分分式）数值对照迭代解；(d) 收缩率账：Fredholm 大 λ
发散演示（λ(b−a) = 2 时迭代振荡放大）vs Volterra 任意 λ 收敛。

**Prolog（`29_fredholm.pl`）**：Neumann 迭代计数器（|λK| 判据）、
差核代数（变换域乘法的有理式）、迭代收敛判定表。

## 29.5 要点回顾

1. IVP ⟺ Volterra 积分方程；Fredholm/Volterra 第二类是主战场。
2. 逐次逼近 = Neumann 级数 = (I − λK)⁻¹ 的算子级数；Volterra 的
   三角结构给 n! 压缩（永远收敛），Fredholm 需 |λ| 小。
3. 差核（卷积）⟹ Laplace 变换代数化 Y = F/(1 − λK̂)。
4. 共振/特征值时 Fredholm 择一重现；第一类方程是不适定雷区。

*本章示例：`examples/julia/29_fredholm.jl`、`examples/python/
29_fredholm.py`、`examples/prolog/29_fredholm.pl`。*

---

上一章：[28 Legendre、Hermite 与椭圆积分](28-legendre.md) · 下一章：[30 变分法](30-calculus-of-variations.md)
