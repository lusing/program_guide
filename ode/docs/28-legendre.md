# 28 Legendre 多项式、Hermite 多项式与椭圆积分

**对应书 §10.3 Legendre Functions（含连带 Legendre 与 Fourier–
Legendre 级数）、§10.4 Elliptic Integrals、§10.5 Hermite
Polynomials。**

---

## 28.1 Legendre：球坐标的正交基

球坐标 Laplace 分离变量（极角方向）产出 **Legendre 方程**：

    (1 − x²)y″ − 2xy′ + ν(ν+1)y = 0，x ∈ [−1, 1]。

x = ±1 是正则奇点。**多项式解存在的条件**：ν = n 整数——
**Legendre 多项式 Pₙ**，最高次系数 (2n)!/(2ⁿn!)²：

    P₀ = 1, P₁ = x, P₂ = (3x²−1)/2, P₃ = (5x³−3x)/4, …

**Rodrigues 公式** Pₙ = [1/(2ⁿn!)]dⁿ/dxⁿ(x²−1)ⁿ——n 次求导直
接生成。正交性（SL 理论，权 1）：∫_{−1}^1 PₘPₙ = 2/(2n+1)·δₘₙ。
**Fourier–Legendre 级数**：f(x) = Σ aₙPₙ，aₙ = (n+½)∫f Pₙ——
球面上的函数展开（量子力学角向、引力势展开）。

**连带 Legendre** Pₙᵐ（m 阶角向调制）：Pₙᵐ = (−1)ᵐ(1−x²)^{m/2}
dᵐPₙ/dxᵐ；球谐函数 Yₙᵐ ∝ Pₙᵐ(cos θ)e^{imφ}——L²(S²) 的正交基。

## 28.2 Hermite：量子谐振子

**Hermite 方程** y″ − 2xy′ + λy = 0；多项式解条件 λ = 2n——
**Hermite 多项式** Hₙ（物理学家约定）：H₀ = 1, H₁ = 2x,
H₂ = 4x²−2, …。正交性（权 e^{−x²}，SL 理论）：
∫e^{−x²}HₘHₙ = √π 2ⁿn! δₘₙ。量子谐振子的波函数 ψₙ ∝
e^{−x²/2}Hₙ(x)，能级 Eₙ = ℏω(n+½)——多项式解条件 = 能级量子化
（第 30 章 Ritz 法的对照答案）。

## 28.3 椭圆积分：单摆周期的真身

单摆方程 θ″ + (g/L)sin θ = 0 的**大幅周期**是椭圆积分（书
§10.4）：

    **T(θ₀) = 4√(L/g)·K(k)**，k = sin(θ₀/2)，
    K(k) = ∫₀^{π/2} dφ/√(1 − k²sin²φ)（第一类完全椭圆积分）。

小振幅展开 K(k) = (π/2)[1 + k²/4 + 9k⁴/64 + …]：T ≈ 2π√(L/g)
(1 + θ₀²/16 + 11θ₀⁴/3072 + …)。k → 1（θ₀ → π）时 K → ∞ 对数
发散——倒立摆"永远不回来"。椭圆积分在复分析里统一于椭圆函数
（sn/cn/dn，单摆方程的显式解 sn(ωt, k)）。

## 28.4 机器验证

**Python（`28_legendre.py`）——scipy.special 全家桶**：
(a) Rodrigues：数值 n 次导数（中心差商高阶或 autograd 式递推）
vs scipy.special.eval_legendre（n = 0..4）；(b) 正交性 ∫PₘPₙ
数值积分 = 2/(2n+1)δₘₙ；(c) 连带 Pₙᵐ（lpmv）与导数公式核对；
(d) Hermite：递推 Hₙ₊₁ = 2xHₙ − 2nHₙ₋₁ 生成 vs eval_hermite +
加权正交；(e) 椭圆积分：scipy.special.ellipk 与数值积分对照、
单摆周期大幅修正（θ₀ = 90°：T/T₀ = 2K(√½/2·...) = 1.1803）；
(f) 单摆数值周期 vs 椭圆积分预言（θ₀ = 30°/90°/150°）。

**Julia（`28_legendre.jl`）**：Legendre 三项递推 (n+1)Pₙ₊₁ =
(2n+1)xPₙ − nPₙ₋₁ 生成 P₀..P₆ + 正交性 + 单摆周期 quadgk 与
ellipk（PolynomialRoots？——不引包：直接数值积分 K 的定义）。

**Prolog（`28_legendre.pl`）**：P₀..P₄ 系数表（rational）、三项
递推核对、Hermite 递推前 4 个、椭圆积分小 k 展开系数。

## 28.5 要点回顾

1. Legendre = 球坐标角向 SL：多项式条件 ν = n；Rodrigues、正交
   权 1、模 2/(2n+1)；连带 Pₙᵐ → 球谐基。
2. Hermite = 谐振子：λ = 2n 量子化能级；权 e^{−x²} 正交。
3. 椭圆积分：单摆大幅周期 T = 4√(L/g)K(sin(θ₀/2))；k→1 对数
   发散；小 k 展开给 1 + θ₀²/16 + … 修正。
4. 三大多项式系统都是 SL 理论的具体化——权函数换（1, x,
   e^{−x²}），机制不变。

*本章示例：`examples/julia/28_legendre.jl`、`examples/python/
28_legendre.py`、`examples/prolog/28_legendre.pl`。*

---

上一章：[27 Γ 函数与 Bessel 函数](27-bessel.md) · 下一章：[29 积分方程](29-integral-equations.md)
