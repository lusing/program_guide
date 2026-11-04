# 10 线性二阶方程理论：Wronskian 与参数变易

**对应书 §3.4 Linear Second-Order Differential Equations。**

---

## 10.1 线性方程的结构定理

标准形式（最高导数系数归一）：

    y″ + p(x)y′ + q(x)y = g(x)，    g ≡ 0 时称齐次。

四条结构定理是全部计算的骨架（书 §3.4.1，证明都是直接的代入）：

1. **齐次解的叠加**：y₁, y₂ 是齐次解 ⟹ C₁y₁ + C₂y₂ 也是。齐次
   解集是向量空间。
2. **零解唯一性**：y(x₀) = y′(x₀) = 0 的齐次解只有 y ≡ 0（存在唯
   一性定理的直接推论——零函数是解且唯一）。
3. **通解 = 基本解组**：若 y₁, y₂ 线性无关，则齐次通解恰为
   C₁y₁ + C₂y₂；任何解都能这样表出。
4. **非齐次**：通解 = 齐次通解 + 任一特解（第 04 章一阶结构律的
   完整重演）。

线性无关的判定正是 **Wronskian**：

    W(y₁, y₂)(x) = y₁y₂′ − y₂y₁′.

## 10.2 Abel 恒等式：Wronskian 的一生

对齐次方程的两个解，W 满足一阶线性方程（直接微分 + 代入方程）：

    W′ = −p(x)·W    ⟹    **W(x) = W(x₀)·e^(−∫[x₀..x] p dx)**.

三条推论：

- W 在一点为零 ⟹ 处处为零（指数因子不为零）——线性无关与无关
  "点"无关，是整体属性；
- W 处处非零 ⟺ y₁, y₂ 线性无关 ⟺ {y₁, y₂} 是基本解组；
- W 的符号固定，给出解"交错"的几何（第 26 章 Sturm 分离定理的引
  擎）。

**例 A** y″ − y = 0：y₁ = eˣ, y₂ = e⁻ˣ，W = eˣ(−e⁻ˣ) − e⁻ˣ·eˣ
= −2（常数，因 p = 0）✓ Abel。
**例 B** y″ + 2y′ + y = 0：y₁ = e⁻ˣ, y₂ = xe⁻ˣ，
W = e⁻ˣ(e⁻ˣ − xe⁻ˣ) − xe⁻ˣ(−e⁻ˣ) = e⁻²ˣ = e^(−∫2dx) ✓。
**例 C**（上一章例 E）x²y″ + 4xy′ − 4y = 0 标准化 p = 4/x：
W = −5x⁻⁴；Abel 预言 e^(−∫4/x dx) = x⁻⁴ ✓（差常数因子 −5）。

## 10.3 参数变易：特解的通用配方

非齐次方程的特解不必猜——**参数变易**（Lagrange）给万能公式。设

    y = u₁(x)y₁ + u₂(x)y₂，

对 u₁′, u₂′ 加一个自由条件 u₁′y₁ + u₂′y₂ = 0（消去 u 的二阶
项），代入方程解联立方程组（系数矩阵的行列式恰是 W）：

    u₁′ = −g y₂/W，   u₂′ = g y₁/W，

积分并代回：

    ȳ(x) = −y₁∫ g y₂/W dx + y₂∫ g y₁/W dx.

与一阶的参数变易（第 04 章）同源：让常数动起来，用自由条件压住
多余自由度。唯一条件：W ≠ 0（基本解组）。

**例 D**（书 §3.4.3 型）y″ + y = tan x。基本组 y₁ = cos x,
y₂ = sin x，W = 1：u₁′ = −tan x·sin x = −sin²x/cos x，
u₂′ = tan x·cos x = sin x。积分 u₁ = sin x − ln|sec x + tan x|
（部分分式技巧），u₂ = −cos x；特解 ȳ = −cos x·ln|sec x + tan x|。
通解 y = C₁cos x + C₂sin x − cos x·ln|sec x + tan x|。

## 10.4 机器验证

**Julia（`10_wronskian.jl`）/ Python（`10_wronskian.py`）**：
(a) 例 A/B/C 的 W 数值核对——三点求 W 与 Abel 公式 e^(−∫p)·W₀
积分对照（相对误差 < 10⁻¹⁰）；(b) 线性无关实验：随机取 a, b 使
a y₁(x*) + b y₂(x*) = 0 且导数也为零的方程只有零解（2×2 线性
方程组行列式 = W ≠ 0）；(c) 参数变易例 D：特解数值代入 y″ + y =
tan x 残差核对（二阶差商，|残差| < 10⁻⁴ 量纲）；(d) 叠加原理：
非齐次解的组合实验（g₁ + g₂ 的特解 = 特解之和，数值残差验证）。

**Prolog（`10_wronskian.pl`）——Wronskian 符号引擎。**
`wronskian(Y1, Y2, W)`：符号微分 + 交叉乘积化简；`abel_check(Y1,
Y2, P)`：验证 W′ + pW = 0 化简为零。断言：例 A 的 W = −2、例 B
的 W = e⁻²ˣ（符号相等）、例 C 的 W = c·x⁻⁴。

**Lean（`Ode/Ch10Wronskian.lean`）——两个解 + 一个恒等式。**
其一：eˣ 与 e⁻ˣ 都是 y″ − y = 0 的解（HasDerivAt 两层装配）；
其二：W(eˣ, e⁻ˣ) ≡ −2 的逐字计算——乘积求导、减法、`ring`。
其三：Abel 的离散版——W′ = −pW 在 p = 0 时即 W′ = 0，对常数 W
−2 验证（deriv 为 0）。

## 10.5 要点回顾

1. 四条结构定理：叠加、零解唯一、通解 = 基本组、非齐 = 齐 + 特。
2. W = y₁y₂′ − y₂y₁′；Abel：W = W₀e^(−∫p dx)。W 零或非零是
   整体属性，一点定全局。
3. 参数变易公式 u₁′ = −gy₂/W, u₂′ = gy₁/W——非齐次特解的万能
   配方，条件只是基本组。
4. 猜基本组（eˣ、cos/sin、幂）+ 机器核对 W ≠ 0 = 二阶线性问题的
   标准工作流；求不出时第 23 章级数法接管。

*本章示例：`examples/lean/Ode/Ch10Wronskian.lean`、`examples/julia/
10_wronskian.jl`、`examples/python/10_wronskian.py`、`examples/
prolog/10_wronskian.pl`。*

---

上一章：[09 一般理论与降阶法](09-reduction.md) · 下一章：[11 常系数二阶方程](11-constant-coeff.md)
