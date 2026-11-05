# 09 波方程 I：球面均值、d'Alembert 与 Huygens

**对应书 §2.4.1（Solution by spherical means：一维 d'Alembert、
三维 Kirchhoff 公式、二维降维、Huygens 原理）。**

---

## 09.1 球面均值法

波方程 u_tt − Δu = 0 的解法（书 §2.4.1 的主线）：定义球面平均

    u(x,t) → U(x,r,t) := ⨍_{∂B(x,r)} u(y,t) dS(y)，

对 (r,t) 的二维波方程 U_rt 满足 Euler–Poisson–Darboux 方程，巧解
后令 r → 0 得各种维数的显式公式：

- **n = 1（d'Alembert）**：u(x,t) = ½[g(x+t) + g(x−t)] +
  ½∫_{x−t}^{x+t}h——两个方向的行波叠加（§2.1 传输方程×2）；
- **n = 3（Kirchhoff）**：u(x,t) = ∂_t[t⨍_{∂B(x,t)}g dS] +
  t⨍_{∂B(x,t)}h dS——**球面**平均（波前是球面）；
- **n = 2（降维）**：把 2D 初值看成 3D 的（与 x₃ 无关），Kirchhoff
  的球面平均化为圆盘平均——**盘**（波后有尾）。

## 09.2 机器验证（Julia + Lean + Fortran）

**(a) d'Alembert**（Julia）：公式数值积分（h 项 Simpson）+ 二阶
差分残差 u_tt − u_xx < 10⁻⁴（差分精度）。Lean 侧是**行波完整证明**
（`Ch09WaveKirchhoff.lean`）：

```lean
theorem right_wave_solves (g g' g'' : ℝ → ℝ) (x t : ℝ) ... :
    deriv (fun t => deriv (fun s => g (x - s)) t) t
      - deriv (fun y => deriv (fun z => g (z - t)) y) x = 0
```

两个方向的二层导数各带因子 (−1)² 与 (1−1·0)²——**内层导数 ±1 的
平方消去符号**，这正是"波可向两个方向传播"的代数痕迹。叠加
（Ch00 superposition）给出 d'Alembert。

**(b) Kirchhoff**（Julia）：球面积分用 Fibonacci 格点（40000 点，
均匀格点准）。线性函数的球面平均闭式 ⨍sin y₁ = sin x₁·sin t/t 数
值对到 8×10⁻⁸；Kirchhoff 公式 ∂_t[t·avg] 复原解析解 sin x₁cos t
（1.5×10⁻⁷）。

**(c) Huygens 原理的对照实验**（本章最鲜明的一张图）：紧支初值
（|y| < 0.5 帐篷）在原点观察：

| 维数 | t = 0.3（波前到达） | t = 2.0（波过后） |
|---|---|---|
| 3D 球面平均 | 0.4000（= 1−2t，|y|=t 上帐篷恒值） | **精确 0** |
| 2D 圆盘平均 | 非零 | **0.0208 ≠ 0（有尾）** |

三维波通过后**严格归零**（球面与支集不交则积分严格为零）——波的
内部干净；二维波留下无限尾巴（盘与支集总有交）——奇数维与偶数维
的本质差别，降维公式的直接后果。

> 坑账：初版期望"t = 0.6 时 3D 球面平均非零"——对中心对称帐篷，
> 球面 |y| = t 上帐篷值恒为 max(0, 1−2t)，穿越窗口是 t < 0.5 而
> 非"球面与支集投影相交"。**Huygens 的判据要按球面方程逐点核**，
> 不能凭几何直觉写窗口。

**(Fortran）能量近似守恒**（`09_wave_energy.f90`）：蛙跳格式 +
周期边界，单模式 sin 2πx。朴素离散能量（速度半层差分 + 整层梯
度）漂移 4.9×10⁻³；CFL 减半漂移精确减半（固定终点时间下 ratio
= 2.00）——**守恒近似 + 漂移的减半律**双断言。严格的辛不变量要
交错梯度；连续能量守恒（书 §2.4.3）由离散近似逼近。

> 坑账：初版断言"leapfrog 能量漂移 O(dt²)、ratio = 4"——实测
> ratio = 2（O(dt²) 振荡叠加 secular 项的混合行为）。**离散格式
> 的守恒律以实测渐近为准，连续定理的 O(dt²) 不自动继承到朴素
> 离散能量。**

## 09.3 要点回顾

1. 球面均值法：EPD 方程的巧解把 n 维波方程化为一族一维公式。
2. d'Alembert = 右行波 + 左行波 + 速度项积分；Lean 证明行波核。
3. Kirchhoff：3D 解只依赖球面平均——Huygens：波前球面、波后干净。
4. 2D 降维成盘平均——有尾；奇偶维数的物理差别在公式里一目了然。

*本章示例：`examples/julia/09_wave_kirchhoff.jl`、`examples/
fortran/09_wave_energy.f90`、`examples/lean/Evanspde/
Ch09WaveKirchhoff.lean`。*

---

上一章：[08 热方程 III](08-heat-energy.md) · 下一章：[10 波方程 II：Duhamel 与有限传播](10-wave-duhamel.md) · [返回目录](../README.md)
