# 27 Γ 函数与 Bessel 函数

**对应书 §10.1 Gamma Function、§10.2 Bessel Functions（J/Y/修
改/Airy/球 Bessel/Fourier–Bessel 级数）。**

---

## 27.1 Γ 函数：阶乘的解析延拓

Γ(z) = ∫₀^∞ t^{z−1}e^{−t} dt（Re z > 0）满足 **Γ(z+1) = zΓ(z)**
（分部积分），Γ(n) = (n−1)!。关键值：Γ(1/2) = √π（平方换序积
分）。递推 + 反射公式 Γ(z)Γ(1−z) = π/sin πz 把 Γ 延拓到除非正整
数外的全平面；Γ 在 0, −1, −2, … 有单极点（留数 (−1)ⁿ/n!）。
Γ 是"积分表里的常客"——Bessel 系数的 1/(k!Γ(k+ν+1)) 就是它。

## 27.2 Bessel 方程与 J_ν

柱坐标 Laplace 分离变量产出 **Bessel 方程**（书 §10.2.1）：

    x²y″ + xy′ + (x² − ν²)y = 0。

x = 0 是正则奇点，指标 ±ν。**Frobenius（第 23 章的兑现）**给第
一类解

    **J_ν(x) = Σₖ (−1)ᵏ (x/2)^{2k+ν} / [k! Γ(k+ν+1)]**。

性质（全部由级数直接读出）：
- J_{−n} = (−1)ⁿ J_n（整数阶两支不独立）；
- 生成函数 e^{(x/2)(t−1/t)} = Σ tⁿ J_n(x)；
- J_ν 有无穷多正零点 j_{ν,n}，相邻差 → π（大 x 渐近
  J_ν ~ √(2/πx)cos(x − νπ/2 − π/4)）；
- 第二类解 **Y_ν**（Neumann，x = 0 对数奇异）补齐基本组。

**修改 Bessel** I_ν, K_ν：方程 x²y″ + xy′ − (x²+ν²)y = 0（去掉
振荡变单调），热传导/扩散的柱对称解。

## 27.3 Fourier–Bessel 级数与 Airy

**Fourier–Bessel 展开**（书 §10.2.7）：固定边界 j_{ν,n} 处为零
的 SL 问题（Bessel 方程是 SL 型，权 r(x) = x）给正交基
{J_ν(j_{ν,n}x/R)}——圆膜的振动模式，第 26 章框架的柱版。

**Airy 函数**（书 §10.2.9）：y″ − xy = 0 的解 Ai、Bi（第 23 章
的级数在这里获得名字）；Ai(x) → 0（x → +∞ 指数衰减）——量子
隧穿转折点外的波函数衰减就是它。**球 Bessel** j_n：三维球坐标
分离变量产出 ½π 半奇数阶 Bessel（j₀(x) = sin x/x）。

## 27.4 机器验证

**Python（`27_bessel.py`）——scipy.special 主场**：
(a) Γ 函数：Γ(n+1) = n!（n = 1..8 精确）、Γ(1/2) = √π、反射
公式数值核对；(b) J_ν 级数 vs scipy.special.jv：ν = 0, 1, 2.5
在 5 点对照（< 1e-12）；(c) J₀ 前五个正零点（scipy.special.jn_
zeros 或 brentq）与相邻差 → π 渐近；(d) 大 x 渐近公式拟合；
(e) 递推 J_{ν−1} + J_{ν+1} = (2ν/x)J_ν 数值核对；(f) 修改
Bessel I/K 单调性；Airy：Ai(2) 与级数 20 项对照、Ai(+∞) 衰减；
(g) 球 Bessel j₀ = sin x/x。

**Julia（`27_bessel.jl`）**：SpecialFunctions.besselj 同款对照
+ Fourier–Bessel 系数数值积分（f = 1 − x² 在 J₀ 基上的展开前
3 项）。

**Fortran（`27_bessel.f90`）**：J₀ 级数截断（20 项）在 x ∈
[0, 10] 与内建 bessel_j0 对照。

**Prolog（`27_bessel.pl`）**：Γ 递推账（Γ(n) = (n−1)! rational）、
J₀ 级数前 8 项系数（rational）、零点相邻差表。

## 27.5 要点回顾

1. Γ = 阶乘延拓：Γ(z+1) = zΓ(z)、Γ(½) = √π、反射公式、非正整
   数极点。
2. Bessel = 柱对称的 sin/cos：Frobenius 给 J_ν；J/Y 基本组；零
   点近似等距（渐近 √(2/πx)cos 相位）。
3. Fourier–Bessel = SL 理论的柱版（权 x，边界在 j_{ν,n}）；
   圆膜振动模式。
4. I/K 是去振荡的 Bessel；Airy 是"线性势"的转折点函数。

*本章示例：`examples/julia/27_bessel.jl`、`examples/python/
27_bessel.py`、`examples/prolog/27_bessel.pl`、`examples/fortran/
27_bessel.f90`。*

---

上一章：[26 Sturm–Liouville 与 Green 函数](26-sturm-liouville.md) · 下一章：[28 Legendre、Hermite 与椭圆积分](28-legendre.md)
