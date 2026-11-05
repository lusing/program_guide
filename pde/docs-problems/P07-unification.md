# P07 三线合一总对账（习题篇收官）

**把三部书的共同问题装进同一张对账表。**

| 问题 | 习题篇（沙马耶夫） | 数值篇（陆金甫） | 理论篇（Evans） |
|---|---|---|---|
| −u″ = sin πx | 闭式 sin(πx)/π² | FEM（28 章） | 能量恒等式（29 章） |
| 热传导 sin πx | e^{−π²t} 模式 | FTCS（14 章） | Galerkin 谱（34 章） |
| 波动 sin πx | cos(πt) 闭式 | 蛙跳（10 章） | Galerkin（36 章） |
| 圆域 Dirichlet | r²cos2θ | 五点差分（21 章） | Poisson 核（04 章） |

数值对账（`examples/p-julia/P07_unification.jl`）：FEM vs 闭式
2×10⁻⁶；FTCS vs e^{−π²t} 5×10⁻⁵；蛙跳 vs cos(πt) 5×10⁻³（时
间离散）；Poisson 积分 vs r²cos2θ 10⁻¹⁰——**四问题三方一致**，
三部书在同一个数学上汇合。

> 收官坑账重演：Poisson 段的自由度又把边界点算进去（误差
> 10⁻¹），29 章的教训直接复用即修复。

*本章示例：`examples/p-julia/P07_unification.jl`。*

---

[P06 椭圆](P06-elliptic.md) · [返回总目录](../README.md)
