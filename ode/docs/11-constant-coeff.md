# 11 常系数二阶方程：特征方程与待定系数

**对应书 §3.5 Linear Second-Order Equations with Constant
Coefficients。**

---

## 11.1 特征方程：把 ODE 变成代数

对 y″ + py′ + qy = 0（p, q 常数），**猜指数解** y = e^{kx}：代
入得 (k² + pk + q)e^{kx} = 0，指数不为零 ⟹

    k² + pk + q = 0    （特征方程），k = (−p ± √(p²−4q))/2.

三种情形（判别式 D = p² − 4q）：

- **D > 0**（实单根 k₁ ≠ k₂）：通解 y = C₁e^{k₁x} + C₂e^{k₂x}；
- **D = 0**（重根 k）：通解 y = (C₁ + C₂x)e^{kx}——第二解 xe^{kx}
  由降阶法（10.3 公式）自动给出；
- **D < 0**（复根 α ± iβ）：实通解 y = e^{αx}(C₁cos βx + C₂sin βx)
  （Euler 公式 e^{iθ} = cos θ + i sin θ 取实虚部，叠加原理允许）。

**为什么猜 e^{kx} 会成功**：指数函数是导数算子的特征向量——
d/dx e^{kx} = k·e^{kx}，求导变成乘数，ODE 整个坍缩成代数方程。
这是"线性常系数 ⟹ 代数化"的深层机关，第 13/16 章推广到高阶与
方程组（特征多项式、矩阵特征值）。

## 11.2 待定系数法：右端的"配对"协议

非齐次 y″ + py′ + qy = g(x)，当 g 是**多项式 × 指数 × 三角**的
组合时，特解有固定形态可猜（**待定系数法**）。核心规则是**共振
升次**：设 γ + iδ 是 g 的"频率"，r = 特征方程中根 γ+iδ 的重数
（0、1 或 2），特解形态 = x^r ×（与 g 同形态的待定组合）：

| g(x) 形态 | 试探 ȳ 形态 |
|---|---|
| Pₙ(x)（多项式） | x^r·Qₙ(x) |
| e^{γx}Pₙ(x) | x^r·e^{γx}Qₙ(x) |
| e^{γx}cos δx·Pₙ 或 sin 版 | x^r·e^{γx}(Qₙcos δx + Rₙsin δx) |

**例 A** y″ − 2y′ + y = eˣ。特征 (k−1)² = 0 重根 1；右端频率
γ = 1 与根重合（r = 1... 实际 r = 2 因是二重根）：ȳ = Ax²eˣ，
代入解出 A = 1/2。共振时必须升两次——不升次的试探 ȳ = Aeˣ 代
入后左端恒零，方程病态。
**例 B**（书例 3.23）y″ + y = sin x + x：sin x 共振（±i 是根，
r = 1）⟹ ȳ₁ = −(x/2)cos x；x 不共振 ⟹ ȳ₂ = Ax + B，A = 1。
叠加：通解 y = C₁cos x + C₂sin x − (x/2)cos x + x。
**例 C**（书例 3.22）y″ − 2y′ + 5y = eˣ(cos 2x − 3sin 2x)：根
1 ± 2i 与右端频率共振（r = 1），ȳ = xeˣ(Acos2x + Bsin2x)，
A = 3/4, B = 1/4。

## 11.3 机器验证

**Julia（`11_constcoeff.jl`）/ Python（`11_constcoeff.py`）**：
(a) 三情形通解代入残差核对（e^{kx} 支、(C₁+C₂x)e^{kx} 支、
e^{αx}(C₁cos+C₂sin) 支各选一组常数，解析导数精确核对）；
(b) **共振解的形态**：y″ + y = sin x 的解 y = −(x/2)cos x 线性
增长——数值积分 IVP y(0)=0, y′(0)=0 到 x = 20π，振幅应 ≈ 10π
（无阻尼受迫共振的能量累积）；(c) 待定系数三例的特解代入残差；
(d) **稳定性速查**：两根实部 < 0 ⟹ 解 → 0——数值实验 p = 5,
q = 6（根 −2, −3）：任一初值的解在 x = 5 时 |y| < 1e⁻⁸；
(e) IVP 全流程：例 B 的初值 y(0)=1, y′(0)=0 定 C₁ = 1, C₂ =
−1/2，RK4 对照。

**Prolog（`11_constcoeff.pl`）——特征方程求解器。**
`char_roots(P, Q, Roots)`：二次公式 + 判别式三情形（rational
系数时精确）；`general_form(Roots, Form)`：输出通解形态（distinct/
double/complex）；`resonance(Roots, Gamma, Delta, R)`：待定系数
的 r 判定；`trial_form(G, Form)`：右端 → 试探形态表。断言例：

```prolog
?- char_roots(0, 1, Roots).
Roots = complex(0, 1).           % y'' + y = 0：cos/sin
?- resonance(complex(0,1), 0, 1, R).
R = 1.                            % sin x 共振 ⟹ 升次
```

**Lean（`Ode/Ch11ConstCoeff.lean`）**：
- e^{2x} 与 e^{−3x} 都是 y″ + y′ − 6y = 0 的解（特征根 2, −3），
  两份 HasDerivAt 装配；
- W(e^{2x}, e^{−3x}) = −5e^{−x}（Abel：p = 1 ⟹ e^{−x} ✓）；
- 共振特解 y = −(x/2)cos x 满足 y″ + y = sin x（乘积 + 链式两层）。

## 11.4 要点回顾

1. 常系数 ⟹ 特征方程；三情形（实异根/重根/复根）各有固定通解形
   态；e^{kx} 成功因为指数是求导算子的特征向量。
2. 待定系数协议：试探 = x^r × 同形态，r = 右端频率在特征根中的
   重数；共振必升次，不共振 r = 0。
3. 叠加原理允许把 g 拆开逐个配特解。
4. 数值通道的两大验证位：共振振幅线性增长（物理：能量累积）、
   根实部符号 ⟹ 稳定性（第 20 章预告）。

*本章示例：`examples/lean/Ode/Ch11ConstCoeff.lean`、`examples/julia/
11_constcoeff.jl`、`examples/python/11_constcoeff.py`、`examples/
prolog/11_constcoeff.pl`。*

---

上一章：[10 线性二阶理论](10-linear-theory.md) · 下一章：[12 周期系数：Hill 与 Mathieu](12-mathieu.md)
