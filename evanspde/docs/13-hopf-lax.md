# 13 Hamilton-Jacobi I：变分、Legendre 变换与 Hopf-Lax

**对应书 §3.3.1-3.3.2（变分问题与 Hamilton ODE、Legendre 变换、
Hopf-Lax 公式）。**

---

## 13.1 从特征线到变分

HJ 方程 u_t + H(Du) = 0（H 凸）可以用特征线解（12 章），但书给
出更深刻的**变分视角**：u(x,t) 是作用量泛函的最小值。Lagrange
量 L 是 H 的 **Legendre 对偶**：

    L(v) = max_p [p·v − H(p)]（凸对偶）。

对 H(p) = p²/2：配方恒等式 pv − v²/2 = p²/2 − (v−p)²/2 给出
L(v) = v²/2（自对偶），一般 H 则未必。

## 13.2 Hopf-Lax 公式

**定理（书式 (18)）**：H 凸、H(0) = 0 时

    **u(x,t) = min_y [t·L((y−x)/t) + g(y)]**

是 HJ 方程的粘性解（光滑范围内是经典解）。H = p²/2 时即
min_y [(y−x)²/2t + g(y)]。

## 13.3 机器验证

**Lean**（`Ch13HopfLax.lean`）——Legendre 对偶的代数核：

```lean
theorem legendre_square (p v : ℝ) : p * v - v ^ 2 / 2 = p ^ 2 / 2 - (v - p) ^ 2 / 2 := by
  ring
theorem legendre_le (p v : ℝ) : p * v - v ^ 2 / 2 ≤ p ^ 2 / 2
```

配方 + 非负平方 = 对偶关系与取等点 v = p 的全部内容——Hopf-Lax
中对 y 求最小能显式解出的原因。

**Julia**（`13_hopf_lax.jl`）四段：

- (a) 配方恒等式逐位对账（Lean 的数值面）；
- (b) **Hopf-Lax = 特征线解**：g = y²/4 时两者**逐位相同**（0.0e+00，
  三点）——光滑范围内两种方法给出同一解；

> 坑账：重写 12 章闭式时把 (ξ/2)²/2·t 的括号抄错成 ξ²/4·t——
> Hopf-Lax 数值当场对出差 2×10⁻²。**公式搬运必须过数值对账。**

- (c) Hamilton 流：p 常数、x 线性（辛结构的数值面，38 章半群
  理论回声）；
- (d) **kink 初值** g = |y|：Hopf-Lax 与两支闭式（y ≥ 0/y ≤ 0 分
  别最小再取 min）对账 10⁻⁴——特征线在角点失效而 Hopf-Lax 继续，
  预演 14 章弱解。

## 13.4 要点回顾

1. Legendre 对偶 = 凹/凸族的切包络（11 章几何 + 本章代数）。
2. Hopf-Lax：HJ 解 = 作用量最小——特征线解在爆破前的光滑段与
   之逐位一致，爆破后它继续给出（粘性）解。
3. kink 初值的两支闭式：min 结构自动选择"来自哪边的特征"。

*本章示例：`examples/julia/13_hopf_lax.jl`、`examples/lean/
Evanspde/Ch13HopfLax.lean`。*

---

上一章：[12 特征线](12-characteristics.md) · 下一章：[14 Hamilton-Jacobi II](14-hj-weak.md) · [返回目录](../README.md)
