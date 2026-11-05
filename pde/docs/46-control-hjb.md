# 46 控制论、动态规划与 HJB

**对应书 §10.3（最优控制、动态规划、Hamilton-Jacobi-Bellman、
Hopf-Lax 的控制解释）。**

值函数 V 满足 **HJB 方程** −V_t = min_α(½|α|² + α·V_x)；动态规划
原理（半群性）是 HJB 的来源。Julia（`46_control_hjb.jl`）：LQR 的
Riccati 解 c(t) = 1/(1+t) 逐位满足 HJB；最优反馈 α* = −V_x；DP
不等式（整体 ≤ 分段）；Hopf-Lax = 自由末端控制的显式（直线轨迹
最优，扫描 vs 闭式 10⁻⁶）。

要点：控制 ⟹ HJB ⟹ 粘性解（45 章）——三段式把最优性原理变成
PDE。

*本章示例：`examples/julia/46_control_hjb.md`。*

---

上一章：[45 粘性解](45-viscosity.md) · 下一章：[47 守恒律组：Riemann 问题](47-riemann-problem.md) · [返回目录](../README.md)
