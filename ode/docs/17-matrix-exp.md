# 17 矩阵指数 e^{At}：常系数组的万能钥匙

**对应书 §4.6 Matrix Approach。**

---

## 17.1 把解法折叠成一个记号

标量方程 x′ = ax 的解是 e^{at}x₀。矩阵方程 **x′ = Ax** 有没有同样
优雅的答案？有——把指数的级数定义搬到矩阵上：

    e^{At} = I + At + A²t²/2! + A³t³/3! + … 

级数对一切矩阵、一切 t 绝对收敛（‖Aᵏ‖‖t‖ᵏ/k! 可被 e^{|t|‖A‖} 支
配），逐项求导合法，且 (e^{At})′ = Ae^{At} = e^{At}A（A 与自己的
幂交换——这是唯一的"幸运"）。于是

    **x(t) = e^{At}·x₀**    ——初值问题的闭式解！

非齐次 x′ = Ax + f(t) 用**常数变易**（积分因子法的矩阵版）：

    x(t) = e^{At}x₀ + ∫₀ᵗ e^{A(t−s)}f(s) ds。

基本矩阵 X(t) = e^{At}（X(0) = I）。e^{At} 的性质：e^{A(t+s)} =
e^{At}e^{As}；e^{At} 可逆，逆 = e^{−At}；det e^{At} = e^{(tr A)t}
（Abel 的另一副面孔）。**陷阱**：一般 e^{A+B} ≠ e^{A}e^{B}（除非
AB = BA）——级数交叉项 a₁b₂ ≠ b₂a₁。

## 17.2 怎么算 e^{At}：三条路线

**路线一：特征值分解**（可对角化 A = VDV⁻¹）：e^{At} =
V·diag(e^{λᵢt})·V⁻¹。复特征值取实虚部；Jordan 块 λI + N（N 幂零）
给 e^{λt}·e^{Nt} = e^{λt}(I + Nt + …)，N² 起全零——重根升次的自
动来源。

**路线二：Putzer 算法**（书 §4.6 的系统化流程）：利用 Cayley–
Hamilton 定理（A 满足自己的特征多项式：Aⁿ 可降次为低次幂），把
e^{At} 写成 I, A, …, A^{n−1} 的以特征值为系数的指数组合——不需要
特征向量，只解一串一阶标量方程。2×2 显式公式（tr A = τ,
det A = Δ，判别式 κ² = τ²/4 − Δ）：

    e^{At} = e^{τt/2}[cosh(κt)I + (sinh(κt)/κ)(A − τI/2)]（κ 实）
    κ = 0 时取极限；κ 虚时 cosh/sinh 变 cos/sin（Lagrange 级数）。

**路线三：直接级数**（数值万能但慢收敛）：数值通道用它做独立核
对——级数截断 vs 特征值分解的两条路必须咬合。

## 17.3 机器验证

**Julia（`17_matexp.jl`）**：(a) 级数 vs 特征分解：三个矩阵（实
异根、复根、重根 Jordan）的 e^{At} 双算对照（< 10⁻¹²）；(b)
Putzer 2×2 公式核对：cosh/sinh 公式与 exp(A*t)（Julia 内建）一致；
(c) 解方程验证：x(t) = e^{At}x₀ 数值积分 vs 矩阵指数乘初值；
(d) 性质实验：det e^{At} = e^{tr(A)t}（数值）；e^{A(t+s)} =
e^{At}e^{As}；反例：取不可交换的 A, B，量出 ‖e^{A+B} − e^A e^B‖ >
0.1。

**Python（`17_matexp.py`）**：scipy.linalg.expm 交叉验证 + 常数变
易公式核对非齐次解（数值积分 ∫e^{A(t−s)}f(s)ds vs solve_ivp）。

**Fortran（`17_matexp.f90`）**：级数法 e^{At} 的经典实现（截断到
‖·‖ < ε，20 项封顶），对 Jordan 块 [[1,1],[0,1]] 与旋转矩阵核对
（含 t·e^{λt} 项）。

**Prolog（`17_putzer.pl`）**：Putzer 2×2 的系数账——特征多项式、
κ² 判别、cosh/sinh（或 cos/sin）形态选择，输出公式形态并数值点
核对。

## 17.4 要点回顾

1. e^{At} 级数收敛、可求导、与 A 交换；x = e^{At}x₀ 是 x′ = Ax 的
   闭式解；非齐次靠常数变易积分。
2. 计算三路线：特征分解（理论清楚）、Putzer/Cayley–Hamilton（不
   要特征向量）、级数（数值兜底）——多路线互证是本章机器纪律。
3. det e^{At} = e^{(tr A)t}；e^{A+B} = e^Ae^B 需要 AB = BA（交换
   性陷阱）。
4. e^{At} 把第 11 章的"三情形"折叠进一个记号——重根升次 = 幂零
   部分 e^{Nt} = I + Nt。

*本章示例：`examples/julia/17_matexp.jl`、`examples/python/
17_matexp.py`、`examples/prolog/17_putzer.pl`、`examples/fortran/
17_matexp.f90`。*

---

上一章：[16 特征值方法](16-systems-eigen.md) · 下一章：[18 方程组应用](18-systems-apps.md)
