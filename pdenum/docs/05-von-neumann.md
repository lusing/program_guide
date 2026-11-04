# 05 von Neumann 稳定性分析

**对应书第 2 章 §3"研究有限差分格式稳定性的 Fourier 方法"（式
(3.1)–(3.9)、定理 3.1–3.7、例 3.1–3.4）。**

---

## 5.1 Fourier 方法：把格式送到波型空间

对**线性常系数**差分格式，稳定性有系统判据。把网格函数延拓到全
实轴，对差分方程两边做 Fourier 变换：求导 → 乘 ik，平移 → 乘
e^{ik h}，于是每个波数 k 上的方程解耦为纯代数关系（书 (3.3)）：

    Û(k, t_{n+1}) = G(τ, k)·û(k, t_n)，

因子 G(τ,k) 称为**增长因子**。重复应用：û(k, t_n) = G(τ,k)ⁿ·û(k,t₀)。
两次使用 Parseval 关系（02 章备好的工具），立即得到核心结论：

> **常系数差分格式稳定 ⟺ 增长因子的任意次幂一致有界**
> （存在常数 K 使 |G(τ,k)|ⁿ ≤ K 对一切 nτ ≤ T、k ∈ ℝ 成立，(3.4)）。

实际操作比这个抽象判据简单得多：**把 u_jⁿ = vⁿ·e^{ijθ}（θ = kh
为网格波数）代入差分方程、消去公因子**，立得 G(θ)。这是本章所有
例子共用的一步。

对**方程组**（未知量 p 个），同样的推导给出增长**矩阵** G(τ,k) ∈
ℂ^{p×p}，稳定性 ⟺ ‖Gⁿ‖ ≤ K 一致有界（(3.8)）。

## 5.2 判别准则：从必要到充要

**von Neumann 条件**（定理 3.1，(3.9)）：稳定的**必要条件**是增长
矩阵的每个特征值满足

    |μ_j(G)| ≤ 1 + Mτ   (j = 1..p，M 与 τ,k 无关)。

"1 + Mτ"而不是"1"：允许与 τ 成线性关系的小超界——它经 n = T/τ 步
累积后仍被常数控制（书图 2.12 的几何解释）。什么时候必要条件升级
为充要？

- **定理 3.2**：G 是**正规矩阵**（酉/Hermite/实对称都是）时，von
  Neumann 条件 ⟺ 稳定。理由是 02 章定理 3.1 的等号情形：‖Gⁿ‖ =
  ρ(G)ⁿ，谱半径决定一切。
- **定理 3.3**：‖G‖ ≤ 1 + Kτ 直接保证稳定（充分）。
- **定理 3.4**：特征值 |μ_j| ≤ 1 + Mτ 且 **G·Gᴴ 一致有界** ⟹ 稳定。
- **定理 3.5**：若存在一致有界的相似变换 S 把 G 对角化（‖S‖·‖S⁻¹‖
  ≤ C 与 τ,k 无关），von Neumann 条件是充分的。
- **定理 3.6/3.7**：两个常用充分条件——G 的元素有界且除一个特征值
  外其余满足 |μ_j| ≤ 1 − Mτ? / G 依赖 σ = kh 时有 p 个不同特征值等
  形态条件。

单未知量（p = 1）时 G 是一个数，正规性自动成立，von Neumann 条件
就是充要条件（推论 2）——本章大多数例子都在这个情形。

## 5.3 四个判例

**例 3.1：对流方程中心格式（FTCS-advection）——无条件不稳定。**
代入 u_jⁿ = vⁿe^{ijθ}：

    G(θ) = 1 − iλ·sinθ，   |G|² = 1 + λ²sin²θ > 1 (θ ≠ 0, π)。

对任何 λ > 0 都有超界波型——恒不稳定。**例 3.2：迎风格式——条件
稳定。** G = 1 − λ(1 − cosθ) − iλsinθ，展开取模：

    |G|² = 1 − 4λ(1−λ)sin²(θ/2)，

故 |G| ≤ 1 ⟺ **0 ≤ λ ≤ 1**（用 2sin²(θ/2) = 1 − cosθ）。**例 3.3：
扩散方程隐式格式（BTCS）——无条件稳定。**

    G = 1/(1 + 4r·sin²(θ/2)) < 1   对一切 r > 0。

**例 3.4：Richardson 格式——三层格式的死刑。** 三层格式先化为等价
二层方程组（令 wⁿ = u^{n−1}）：增长矩阵

    G = [[−8r·s, 1], [1, 0]]   (s = sin²(θ/2))，

特征值 μ± = −4rs ± √(16r²s² + 1)，取减号的一支 |μ₋| = 4rs + √(16r²s²+1)
> 1 对一切 r,s > 0 成立——**无条件不稳定**。Richardson 格式截断误差
O(τ²) + O(h²)（比 FTCS 高一阶）却毫无实用价值；替代品是第 15 章
的 DuFort–Frankel 与跳点格式。

## 5.4 机器验证

### 数值扫描：判据与实测逐一对账

Julia 通道（`examples/julia/05_vonneumann.jl`）对四类格式做 θ 全
扫描（500 个网格点），max|G| 与解析判据对账：

```julia
thetas = range(1.0e-3, pi - 1.0e-3, length = 500)
s2(th) = sin(th / 2)^2   # sin^2(theta/2)

maxG(mu) = maximum(abs(1 - 1im * mu * sin(th)) for th in thetas)                     # FTCS-adv
maxG_upwind(mu) = maximum(sqrt(1 - 4 * mu * (1 - mu) * s2(th)) for th in thetas)     # 迎风
maxG_ftcs_heat(r) = maximum(abs(1 - 4 * r * s2(th)) for th in thetas)                # FTCS heat
maxG_btcs_heat(r) = maximum(1 / (1 + 4 * r * s2(th)) for th in thetas)               # BTCS heat

for mu in (0.3, 0.8, 1.0)
    @assert maxG(mu) > 1.0 + 1.0e-6 "FTCS-advection 应恒不稳定"
end
```

结论矩阵全部落实：FTCS-advection 在 μ = 0.3/0.8/1.0 都超界；迎风
μ ≤ 1 时 max|G| = 1（θ→0 处）、μ = 1.5 时 max|G| = 2.0 = |1−2μ|；
FTCS 热传导 r = 0.6 时 max|G| = 4r−1 = 1.4；BTCS 在 r = 50 依旧
< 1。Richardson 部分：

```julia
worst = maximum(abs(-4 * r * s2(th) - sqrt(16 * r^2 * s2(th)^2 + 1))
                for r in 0.1:0.1:1.0 for th in thetas)
@assert worst > 4.9 "Richardson 特征值模应远超 1"
```

扫描 r × θ 全组合得 max|μ₋| = 8.123；数值迭代版（r = 0.5，起步用
FTCS）60 步内 max|u| = 2.85×10⁸——理论与实践同判。

### Parseval 闭环：端到端验证整个理论

本章理论链条是"格式 → 增长因子 → |G|ⁿ → Parseval → ℓ² 稳定"。
可以做**闭环实验**：初值取两个波型的叠加（k = 3 幅 1、k = 7 幅
0.5），直接迭代 60 步测 ℓ² 增长，与"逐波型 |G|ⁿ 加权和"的预测
对账：

```julia
meas = l2_growth(scheme, lam, h, nst)
pred = predicted_growth(scheme, lam, h, nst)
@assert rel < 1.0e-8 "Parseval 闭环应吻合"
```

三组对照（迎风 λ=0.8 衰减到 0.774652；LF λ=0.9 衰减到 0.748202；
迎风 λ=1.1 增长到 1.305250）——**实测与预测在六位有效数字上逐位
一致**。增长因子的每一个数字都真实出现在迭代的范数里。

### Lean：三条代数内核

Lean 通道（`examples/lean/Pdenum/Ch05VonNeumann.lean`）把判据的
代数内核做成定理。迎风恒等式一步闭核：

```lean
/-- 迎风格式的增长因子满足 `|G|² = 1 − 2μ(1−μ)(1−cosθ)`。
两式之差恰为 `μ²·(C² + S² − 1)`，`linear_combination` 一步。 -/
theorem upwind_G_sq_identity (μ C S : ℝ) (h : C * C + S * S = 1) :
    (1 - μ + μ * C) ^ 2 + (μ * S) ^ 2 = 1 - 2 * μ * (1 - μ) * (1 - C) := by
  linear_combination μ ^ 2 * h
```

`μ` 是 Lean 里可用的希腊字母（`λ` 是保留字——第 06 章的坑账）。"
|G|² ≤ 1 ⟺ 0 ≤ μ ≤ 1"的两个方向分别成为 `upwind_stable`（不等式
方向）与 FTCS 热传导的配对定理：

```lean
/-- 不稳定方向：`r > 1/2` 时取 `C = −1`（即 θ = π 的最高波型）得
`|G| = 4r − 1 > 1`——条件不可省。 -/
theorem ftcs_heat_unstable (r : ℝ) (hr : 1 / 2 < r) :
    1 < |1 - 2 * r * (1 - (-1))| := by
```

Richardson 的出界特征值则完整走了一遍分情况讨论（4s ≤ 1 时
√(16s²+1) > 1 ≥ 1−4s；4s > 1 时 1−4s < 0 < √(...)），结论
`-4s − √(16s²+1) < -1`——**无条件不稳定**有了逐字证明。

### Prolog：增长因子规则引擎

Prolog 通道（`examples/prolog/05_vonneumann.pl`）把六个格式（含
第 07 章将正式登场的 LF、LW）的增长因子写成复数规则：

```prolog
% 迎风 FTBS: G = 1 - mu(1 - cos) - i mu sin
growth(upwind, Mu, T, c(R, I)) :-
    R is 1 - Mu * (1 - cos(T)), I is -Mu * sin(T).
% Lax-Wendroff: G = 1 - mu^2 (1-cos) - i mu sin
growth(lw, Mu, T, c(R, I)) :-
    R is 1 - Mu * Mu * (1 - cos(T)), I is -Mu * sin(T).
```

15 点 θ 网格扫描 max|G| 后的裁决与书一致：ftcs_advection 恒不稳；
upwind/lf/lw 在 μ ≤ 1 稳、μ > 1 不稳；ftcs_heat 当且仅当
r ≤ 1/2；btcs_heat 全稳；Richardson 闭式规则 `richardson_mu2` 对
r ∈ {0.1..1.0} × s ∈ {0.05..1.0} 全部出界。

## 5.5 要点回顾

1. Fourier 方法三步：代入 u_jⁿ = vⁿe^{ijθ} → 消公因子得 G(θ) →
   判 |G| ≤ 1（+Mτ 修正）。
2. von Neumann 条件是必要条件；G 正规（酉/Hermite/对称）时充要；
   单未知量永远充要。非正规 G 的危险在 02 章 Jordan 块已预演。
3. 四判例：FTCS-advection 恒不稳；迎风 λ ≤ 1；BTCS 无条件稳；
   Richardson 三层格式无条件不稳（二阶精度也无济于事）。
4. Parseval 闭环实验：ℓ² 增长的实测与逐波型预测六位吻合——
   增长因子的每个数字都是真的。
5. 增长因子扫描是"参数-判据"对账的范式；容差按 θ 网格分辨率
   （端点余量 1e-3 → |G| 偏差 ~2r×10⁻³）设定。

*本章示例：`examples/julia/05_vonneumann.jl`、`examples/python/
05_vonneumann.py`、`examples/prolog/05_vonneumann.pl`、`examples/
lean/Pdenum/Ch05VonNeumann.lean`。*

---

上一章：[04 相容性、收敛性与稳定性](04-ccs.md) · 下一章：[06 其他稳定性分析方法](06-other-methods.md)
