# 47 守恒律组：行波与 Riemann 问题

**对应书 §11.1（积分解、行波、双曲性）与 §11.2（简单波、稀疏波、
激波与接触间断、Riemann 解）。**

双曲性（实特征）+ 特征场线性退化/真非线性 ⟹ Riemann 解为激波/
稀疏/接触间断的组合。Julia（`47_riemann_problem.jl`）：p-系统的
Jacobian 特征 ±1（双曲判据）；**Riemann 不变量** R± = v ± ln u
沿特征常数；简单波（一个不变量恒定）的连接；**RH 相容性**——两
分量跳跃的激波速度不一致 ⟹ 需要复合波（稀疏+激波），标量理论
（15 章）在系统情形的门槛显现。

要点：系统 Riemann 解 = 左态到中间态到右态的两族波；RH 相容性
是约束而非自动。

*本章示例：`examples/julia/47_riemann_problem.jl`。*

---

上一章：[46 HJB](46-control-hjb.md) · 下一章：[48 Riemann 不变量与熵](48-entropy-systems.md) · [返回目录](../README.md)
