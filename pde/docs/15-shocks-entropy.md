# 15 守恒律：激波、Rankine-Hugoniot 与熵条件

**对应书 §3.4.1（积分形式、激波、RH 条件、熵条件、Riemann 问题）。**

---

## 15.1 从 HJ 到守恒律

u_t + f(u)_x = 0（守恒律）是 HJ 方程的"导数版"：势 w 满足
w_t + f(w_x) = 0。Burgers f(u) = u²/2 是全部直觉的来源。

**积分形式**：u_t + f(u)_x = 0 对任意区间的积分形式

    d/dt ∫_a^b u dx = f(u(a)) − f(u(b))

是物理守恒的表述，**间断解**（弱解）天然被允许——积分形式对分
段光滑函数成立，只要跳跃满足 **Rankine-Hugoniot 条件**：

    **激波速度 s = [f]/[u]**（通量跳跃 / 状态跳跃）。

## 15.2 熵条件：物理挑出一个弱解

弱解不唯一。书给出旅行解判据：u(x,t) = U(x/t) 代入得 ODE，Burgers
的解 U 满足 U′ = (U − s)/(...)，**单调性要求**（从旅行解连续依赖）
等价于 **Lax 熵条件**：

    f′(u_L) > s > f′(u_R)（特征线从两侧进入激波）。

Burgers：u_L > u_R（压缩产生激波）；反向数据 u_L < u_R 产生**稀
疏波**（连续自相似解 u = x/t 截断）。

## 15.3 机器验证（三面夹击）

**Lean**（`Ch15ShocksEntropy.lean`）——RH 与熵的代数核：

```lean
theorem rh_burgers (uL uR : ℝ) (h : uL ≠ uR) :
    ((uL^2 / 2) - (uR^2 / 2)) / (uL - uR) = (uL + uR) / 2 := by
  field_simp; ring
theorem lax_entropy_burgers (uL uR : ℝ) (h : uL > uR) :
    uL > (uL + uR) / 2 ∧ (uL + uR) / 2 > uR
```

**Julia**（`15_shocks_entropy.jl`）：

- (a) **弱形式环量**：绕激波的矩形回路上 ∮(u dx − f dt) = 0 精确
  成立（0 误差）⟺ RH——守恒律的散度定理直接可算；

> 坑账：环量侧边的符号初版推反（逆时针回路左边 +f(uL)dt、右边
> −f(uR)dt）——−0.8 ≠ 0 一眼锁定；手推回路方向时逆时针两项侧边
> 符号相反，**不是同号**。

- (b) **Godunov 方法**：凸标量通量要按段落取

> 坑账（本章最有教学价值）：Godunov 通量对凸流是 u_L > u_R（激波
> 段）取 **max**(f(uL), f(uR))、u_L ≤ u_R（稀疏段）取 **min**——
> 初版统一用 min，激波通量算成 0，数值激波**原地不动**（0.0 vs
> 0.5 立即暴露）。修正后数值激波位置 0.5000 与 RH 预测**四位精
> 确**；

- (c) 熵条件的两面：uL=1 > s=0.5 > uR=0（合法激波）与反例数据
  f′(uL)=0 < s < f′(uR)=1（熵违反 ⟹ 稀疏波）；
- (d) 稀疏波数值解与 u = x/t 对照（最大误差 0.067 = O(h) 抹平）。

> 坑账：周期边界下初始间断在 x = ±8 各有一个周期像（副激波），
> 统计窗口要避开——否则误差统计把物理正确的副激波当错误。

## 15.4 要点回顾

1. 积分形式允许间断；RH 条件 s = [f]/[u] 是间断沿特征传播的
   量子化（Lean 完整证明 Burgers 版 s = (uL+uR)/2）。
2. 弱解不唯一；Lax 熵条件（特征进入激波）挑出物理解：压缩 →
   激波，膨胀 → 稀疏波。
3. Godunov 通量的 max/min 分段是凸流 Riemann 求解器的全部。

*本章示例：`examples/julia/15_shocks_entropy.jl`、`examples/lean/
Evanspde/Ch15ShocksEntropy.lean`。*

---

上一章：[14 Hamilton-Jacobi II](14-hj-weak.md) · 下一章：[16 Lax-Oleinik 与长时行为](16-lax-oleinik.md) · [返回目录](../README.md)
