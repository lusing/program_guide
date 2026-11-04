# 13 高阶线性方程与 Euler 方程

**对应书 §3.7 Linear Equations of Order n > 2、§3.8 常系数高阶、
§3.9 Euler Equation。**

---

## 13.1 n 阶线性方程：二阶理论的完整推广

    y⁽ⁿ⁾ + p₁(x)y⁽ⁿ⁻¹⁾ + … + p_{n−1}(x)y′ + pₙ(x)y = g(x)

整个第 10 章的结构定理逐字推广：齐次解空间是 **n 维向量空间**；
基本解组 y₁, …, yₙ 线性无关（Wronskian n 阶行列式非零，Abel 推
广为 W = W₀e^(−∫p₁dx)）；非齐通解 = 齐通解 + 特解。参数变易变成
n×n 线性方程组（Cramer 法则，行列式都是 W），形态不变、规模变
大。**一切第 10 章的直觉照搬。**

## 13.2 常系数高阶：特征多项式

y⁽ⁿ⁾ + a₁y⁽ⁿ⁻¹⁾ + … + aₙy = 0 的特征方程是 n 次多项式

    P(k) = kⁿ + a₁kⁿ⁻¹ + + … + aₙ = 0.

通解按根的情形装配：

- 每个实单根 k 贡献 Ce^{kx}；
- 每个实 r 重根 k 贡献 (C₁ + C₂x + … + C_r x^{r−1})e^{kx}；
- 每对共轭复单根 α ± iβ 贡献 e^{αx}(C₁cos βx + C₂sin βx)；重
  复同理升次。

**算子观点**：记 D = d/dx，方程即 P(D)y = g；P(D) 可以像多项式
一样**因式分解**：(D − k₁)(D − k₂)…(D − kₙ)y = g，每个因子是
一阶线性算子，逐个求解（每步一次积分 + 一阶线性方程）——高阶方
程被拆成一串一阶方程。待定系数法与共振升次规则与二阶完全相同
（r = 右端频率作根的重数）。

**例 A**（书 §3.8 型）y⁽⁴⁾ − y = 0：k⁴ = 1 ⟹ k = 1, −1, ±i，
通解 y = C₁eˣ + C₂e⁻ˣ + C₃cos x + C₄sin x。
**例 B** y‴ − 3y″ + 3y′ − y = 0：P(k) = (k−1)³ 三重根，
y = (C₁ + C₂x + C₃x²)eˣ。

## 13.3 Euler 方程：x^k 型的几何

**Euler（柯西–欧拉）方程**：

    xⁿy⁽ⁿ⁾ + a₁xⁿ⁻¹y⁽ⁿ⁻¹⁾ + … + aₙy = 0，x > 0，

系数是 x 的幂且幂次与导数阶数"配套"。猜**幂解** y = xᵏ：x·d/dx
作用在 xᵏ 上是乘 k（幂函数是"对数导数算子" θ = xD 的特征向量），
代入得**指标方程**（indicial equation）

    k(k−1)…(k−n+1) + a₁k(k−1)… + … + aₙ = 0.

每个根 k 给解 xᵏ；重根 k 升次（xᵏ, xᵏln x, xᵏln²x, …）；复根
α ± iβ 给 x^α cos(β ln x), x^α sin(β ln x)。另一条路：代换
x = eᵗ 把 Euler 方程变成**常系数**方程（dx/dt = x ⟹ xD = D_t），
两条路殊途同归——"对数尺上等距"的几何。

**例 C**（第 09 章例 E 的复算）x²y″ + 4xy′ − 4y = 0：指标方程
k(k−1) + 4k − 4 = k² + 3k − 4 = (k−1)(k+4) ⟹ y = C₁x + C₂x⁻⁴ ✓
与降阶法答案一致。

## 13.4 机器验证

**Julia（`13_higher.jl`）/ Python（`13_higher.py`）**：
(a) 例 A 四个基解代入 y⁽⁴⁾ − y = 0 残差核对（四阶解析导数）；
(b) 例 B 三重根解族代入核对；(c) **算子因式分解实验**：把
y‴ − 3y″ + 3y′ − y = 0 写成 (D−1)³y = 0，逐层一阶线性求解
（数值：三层积分嵌套），与直接特征解对照；(d) Euler 方程例 C
与 y = x³（方程 x²y″ − 2xy′ + 2y = 0，指标 k(k−1)−2k+2 = 0 给
k = 1, 2？核算：k² −3k + 2 = 0 ⟹ k = 1, 2 ⟹ 通解 C₁x + C₂x²）
代入核对；(e) 复根 Euler 例：x²y″ + xy′ + y = 0 指标
k² + 1 = 0 ⟹ y = C₁cos(ln x) + C₂sin(ln x)，在 x ∈ [1, e^{4π}]
上与 RK4 数值解对照（换元 t = ln x 化常系数后积分）。

**Prolog（`13_euler.pl`）——指标方程引擎。** `indicial(Coeffs,
Poly)`：Euler 方程系数 ⟹ 指标多项式（用二项式展开 k(k−1)…）；
`roots_int(Rational)`：有理根搜索；`euler_general(Roots, Form)`：
装配通解形态（幂/重根 ln 升次/复根 cos ln）。断言：例 C 指标
(k−1)(k+4)；复根例 k² + 1。

**Lean（`Ode/Ch13Higher.lean`）**：y = eˣ 满足 y⁽⁴⁾ − y = 0 的
逐字四阶账（HasDerivAt 四层链）；y = x³ 满足 x²y″ − 2xy′ + 2y = 0
（x > 0）——两条乘积/幂导数链 + 环等式。

## 13.5 要点回顾

1. n 阶线性 = 二阶理论的维度推广：n 维解空间、Wronskian 行列式、
   Abel、参数变易（Cramer）。
2. 常系数：特征多项式因式分解 ⟹ 通解装配表；算子观点 P(D) 把高
   阶拆成一串一阶。
3. Euler 方程：幂解 xᵏ ⟹ 指标方程；重根配 ln x；换元 x = eᵗ 化
   常系数——"对数尺上等距"。
4. 共振升次与待定系数规则在高阶不变。

*本章示例：`examples/lean/Ode/Ch13Higher.lean`、`examples/julia/
13_higher.jl`、`examples/python/13_higher.py`、`examples/prolog/
13_euler.pl`。*

---

上一章：[12 周期系数：Hill 与 Mathieu](12-mathieu.md) · 下一章：[14 振动应用](14-oscillations.md)
