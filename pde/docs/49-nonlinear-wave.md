# 49 非线性波：能量守恒与存在性

**对应书 §12.1（能量守恒、有限传播）与 §12.2（Lipschitz 非线性、
短时存在）。**

能量守恒 E = ½‖(u_t,∇u)‖² + ∫F(u) 是非线性波的全部分析起点：
Lipschitz/次线性增长 ⟹ 全局；负势能轨道可爆破。Julia
（`49_nonlinear_wave.jl`）：谱截断 Duffing 振子的 Verlet 能量漂移
~10⁻⁵（守恒签名）；有界非线性的全局轨道；**负能量爆破** u″ = u³
的有限时间 t = 0.87（书 §12.5 的 ODE 核）；有限传播锥同线性。

要点：能量是存在与爆破的分水岭；非线性波保留光锥（因果不变）。

*本章示例：`examples/julia/49_nonlinear_wave.jl`。*

---

上一章：[48 熵准则](48-entropy-systems.md) · 下一章：[50 半线性波与临界指标](50-critical-power.md) · [返回目录](../README.md)
