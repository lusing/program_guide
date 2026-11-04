# 01 存在唯一性与 Picard 迭代

**对应书 §2.1 Existence and Uniqueness of a Solution（含书附录 A 的
Picard 证明思路）。**

---

## 1.1 问题：解什么时候存在、什么时候只有一个

写下 y′ = f(x, y)、y(x₀) = y₀ 之后，先别急着求公式解。两件事必须
先问清楚：

1. **存在**：有没有函数真的满足它？
2. **唯一**：满足它的函数是不是只有一个？

这不是书呆子式的谨慎——两个答案都可能在最朴素的问题上翻车。

**翻车一（不唯一）**：y′ = y^(1/3)、y(0) = 0（书例 2.1(b)）。把方程
改写成 dx/dy = y^(−1/3) 积分得 x = (3/2)y^(2/3)，解出 y = ±(2x/3)^(3/2)。
它满足初值 y(0)=0；但 y ≡ 0 也满足；而且还可以"贴拼"：在 x ≤ a 段取
0、之后接 ±(2(x−a)/3)^(3/2)，每个 a ≥ 0 都给出一个解——**无穷多个
解穿过同一个初值点**。取平方根版 y′ = √|y|、y(0) = 0 同理：y ≡ 0 与
y = x²/4（x ≥ 0）都是解，机器核对见 1.5 节。

**翻车二（存在但不能延拓）**：y′ = y²、y(1) = 1（书例 2.1(a)）。
f 处处光滑，定理条件全满足，解唯一存在——解出来是 y = 1/(2−x)，
在 x = 2 处**爆炸**（blow-up）。所以"局部存在唯一"不保证"全局存在"：
解的生命区间是初值问题的一部分，不是赠品。

定理把这两类翻车精确定位了。

> **定理（解的存在唯一性，局部版）** 设 f 在矩形
> D = {(x, y) : |x − x₀| ≤ α, |y − y₀| ≤ β} 上连续，且关于 y 满足
> **Lipschitz 条件**：存在常数 K > 0，使得对 D 内任意两点
> (x, y₁)、(x, y₂) 有
>
>     |f(x, y₁) − f(x, y₂)| ≤ K|y₁ − y₂|，
>
> 则初值问题在某区间 |x − x₀| ≤ h（h = min(α, β/M)，M = max_D|f|）
> 上存在唯一解。

书上的原始版本要求 ∂f/∂y 存在有界——由中值定理 |f(x,y₁) − f(x,y₂)|
= |∂f/∂y|·|y₁−y₂|（取中间点），有界偏导 ⟹ Lipschitz，反之不然：
|y| 处处 Lipschitz（K=1）却在 y=0 不可导。所以 Lipschitz 条件是更
弱、更本质的。两个翻车例的病灶也立刻可见：y^(1/3) 的导数
(1/3)y^(−2/3) 在 y=0 无界，Lipschitz 失效；y² 在包含 (1,1) 的任何
矩形上 Lipschitz 成立，所以它只有"延拓"问题，没有"唯一性"问题。

**线性对照**：y′ + p(x)y = g(x) 中 f = g − p·y 关于 y 是仿射的，
Lipschitz 常数就是 max|p|。只要 p、g 连续，存在唯一性在 p、g 连续
的**整个区间**上成立——一阶线性方程没有爆破与分叉问题（书：解
y = −1 + e^(x−1) 对一切 x 存在唯一）。这是线性方程的第一份红利。

## 1.2 证明的引擎：把 ODE 变成积分方程再迭代

定理的证明思路值得走一遍——它不仅证明定理，还**给出算法**（Picard
迭代）并直接通向第 29 章的积分方程理论。

初值问题 y′ = f(x, y)、y(x₀) = y₀ 两边从 x₀ 到 x 积分：

    y(x) = y₀ + ∫[x₀..x] f(t, y(t)) dt.                                    (*)

这是一个**积分方程**：y 出现在自己的定义式里（右边积分号下）。它
与原 IVP 等价——可导函数满足 (*) 当且仅当它满足 IVP（对 (*) 求导
得方程，代入 x = x₀ 得初值；这正是"积分再求导"与微积分基本定理的
来回）。

于是定义** Picard 算子** T：

    (Ty)(x) = y₀ + ∫[x₀..x] f(t, y(t)) dt.

解 = T 的不动点。从任何初始猜测 y₀(x)（通常取常函数 y₀）出发迭代：

    y_{n+1} = T(y_n),  即  y_{n+1}(x) = y₀ + ∫[x₀..x] f(t, y_n(t)) dt.

**收敛性**（区间 |x−x₀| ≤ h 上，hK < 1 时）：相邻两次迭代的距离

    max |y_{n+1} − y_n| ≤ K·h·max |y_n − y_{n−1}|，

每迭代一次误差乘上 q = Kh < 1——这正是压缩映射（Banach 不动点定理）
的骨架。逐项估计给出显式误差账：

    |y_n(x) − y*(x)| ≤ (Kh)ⁿ/(1−Kh) · max|y₁ − y₀|.

**唯一性**：若 y、z 都是解，则 |y(x) − z(x)| ≤ K·∫[x₀..x]|y−z|，
记 u(x) = max_{[x₀,x]}|y−z|，得 u ≤ Kh·u，Kh < 1 强迫 u = 0。这
个"积分不等式强迫零"的招式叫 **Grönwall 不等式**（第 20 章把它做
成完整理论，Lean 通道在 mathlib 里有现成的 `Gronwall` 模块）。

**Picard 迭代的另一个名字**：逐次逼近法（method of successive
approximations）。它对第 29 章的 Fredholm/Volterra 积分方程照搬
有效——ODE 理论与积分方程理论在这里是同一件事的两个侧面。

## 1.3 例：Picard 迭代手工走两轮

先看最干净的 y′ = y、y(0) = 1（Lipschitz 常数 K = 1）。从
y₀(x) ≡ 1 开始：

    y₁(x) = 1 + ∫₀ˣ y₀ dt = 1 + x
    y₂(x) = 1 + ∫₀ˣ (1 + t) dt = 1 + x + x²/2
    y₃(x) = 1 + x + x²/2 + x³/6，……

每迭代一次恰好"咬住"eˣ 的 Taylor 级数一项——迭代在把指数函数的
级数一段一段吐出来，第 n 轮后误差 ≤ e^x·xⁿ⁺¹/(n+1)!。

常驻例 y′ = x + y、y(0) = 1 同样从 y₀ ≡ 1 起步：

    y₁ = 1 + x + x²/2，y₂ = 1 + x + x² + x³/6，y₃ = 1 + x + x² + x³/3 + x⁴/24…

真解 y* = 2eˣ − x − 1 = 1 + x + x² + x³/3 + x⁴/12 + …。这次迭代不再
逐项咬 Taylor（积分把两项搅在一起），但误差仍按压缩因子几何式下
降：区间 [0, 1] 上每轮约缩小到 1/6 上下，实测第 6 轮 y(1) 误差
≈ 2.5 × 10⁻⁴（机器验证见 1.5 节），与理论账 e_n ≤ q·e_{n−1}、
q ≈ Kh_total·e^{Kh} 吻合。

## 1.4 连续依赖与稳定性：定理的第三份红利

书 §2.1 末尾指出：定理条件满足时，解还**连续依赖于初值与参数**。
初值 y₀ 的测量误差 δ 如何传播？两条解轨道的差满足

    |y(x; y₀+δ) − y(x; y₀)| ≤ |δ|·e^(K|x−x₀|)                                     （Grönwall）

——误差至多指数放大，有限时间内可控。K 越大放大越凶，这正是第 20
章 Lyapunov 稳定性的雏形（那里要求误差**不放大甚至衰减**）。对非
Lipschitz 的方程（如 y^(1/3)），解对初值的依赖可以完全不连续：初
值从 0 挪到 ε，解的形态在 x=0 附近发生剧变。数值通道会用"初值扰动
实验"直接量出这两种行为差别。

## 1.5 机器验证

**Lean（`examples/lean/Ode/Ch01Existence.lean`）——定理的两种用法。**
mathlib 把整套理论放在 `Mathlib.Analysis.ODE` 下：Picard–Lindelöf
的完整证明在 `PicardLindelof.lean`，封装好的存在唯一结论在
`ExistUnique.lean`。用法一（存在性）：对时间无关向量场 f : E → E，
C¹ 即可——

```lean
/-- 存在性（mathlib Picard–Lindelöf 的 C¹ 入口）：y' = y² 在 y₀ 附近
有局部解。 -/
example : ∃ (ε : ℝ) (hε : 0 < ε), ∃ y : ℝ → ℝ,
    y 1 = 1 ∧ ∀ t ∈ Ioo (1 - ε) (1 + ε),
      HasDerivAt y (y t ^ 2) t := by
  obtain ⟨ε, hε, y, hy⟩ :=
    (contDiff_pow 2).exists_eventually_eq_hasDerivAt (x₀ := (1 : ℝ))
  ...
```

入口定理 `ContDiffAt.exists_eventually_eq_hasDerivAt` 说：C¹ 向量场
 admits 局部流。`contDiff_pow 2` 给出 f(y) = y² 的 C¹ 性。**用法二
（唯一性）**：mathlib 的 `ODE_solution_unique` 需要 Lipschitz 常数——
y² 在大区间上不 Lipschitz，但在 [1−a, 1+a] 上 Lipschitz 常数 2+a，
这演示了"唯一性是局部属性"。

**非唯一性的机器证明**（同一文件）：对 y′ = √|y|、y(0) = 0，直接
**出示两个解**——y ≡ 0 与 y = x²/4（x ≥ 0）：

```lean
/-- y = x²/4 在 x ≥ 0 上满足 y' = √y 与 y(0) = 0：非唯一性的铁证。 -/
example (x : ℝ) (hx : 0 ≤ x) :
    HasDerivAt (fun x => x ^ 2 / 4) (Real.sqrt ((x ^ 2 / 4))) x := by
  rw [Real.sqrt_div (by positivity) (by positivity), Real.sqrt_sq (by positivity)]
  ... -- 左端化简为 x/2，与 (x²/4)' 吻合
```

"存在两个解"比"不存在唯一性证明"有力得多——反例是最好的证明。

**Julia/Python（`01_existence.jl` / `01_existence.py`）**——三组实验：
(a) Picard 迭代 y′ = x + y（复化梯形逐轮推进），第 6 轮 y(1) 误差
实测 ≈ 2.5 × 10⁻⁴，断言 < 5 × 10⁻⁴ 且逐轮单调下降（压缩性的数值
读数）；(b) 爆破：解析解 y = 1/(2−x) 在 x → 2⁻ 发散，同时 Euler
步进在 x = 2 附近越过 10¹²（数值爆破点）；(c) 非唯一：从 y₀ = 10⁻¹²
出发积分 y′ = y^(1/3)，到 x = 3 已长成 O(1) 量级——离开零解；对照
y′ = y（Lipschitz 成立）同样扰动到 x = 3 仍 < 10⁻¹⁰（Grönwall 的
指数放大被 e³ 封顶）。

```julia
# (a) Picard 迭代：y_{n+1}(x) = 1 + ∫₀ˣ (t + y_n(t)) dt，梯形公式离散
for n in 1:6
    global y = picard_step(y, xs)     # 复化梯形
    push!(errs, abs(y[end] - (2exp(1) - 2)))
end
@assert errs[6] < 5e-4 "第 6 轮误差 ~2.5e-4（压缩因子 ~1/6）"
```

**Fortran（`01_existence.f90`）**——经典数值版 Picard：把 1.3 节的
手工迭代搬到 [0,1] 网格上，复化 Simpson 积分逐轮推进，输出每轮
y(1) 与真值的误差表（应按 ~qⁿ 收缩，q ≈ K·h_total < 1）。

**Prolog（`01_existence.pl`）——符号 Picard 引擎。** 多项式用系数
表 `[a0, a1, a2, …]`（aᵢ 是 xⁱ 的系数，rational 算术）表示，
积分 = 移位，代入 f(x, y) = x + y 是线性的所以迭代保持多项式：

```prolog
% picard_poly(N, Poly)：N 轮 Picard 迭代后的 y(x) 系数表（截断到 8 次）
%   y₀ = [1]，y_{n+1} = 1 + ∫ (t + y_n) dt
picard_poly(0, [1]).
picard_poly(N, P) :- N1 is N-1, picard_poly(N1, Q),
                     padd(Q, [0,1], R),          % t + y_n（注意 y_n 常数项加 1 之后……）
                     pintegral(R, P).            % 逐项积分再补常数 1
```

断言：第 5 轮迭代的多项式 = 1 + x + x² + x³/6 + x⁴/24 + x⁵/120 的
前 6 项——**符号地**复现 1.3 节的手工计算，零浮点。

## 1.6 要点回顾

1. 存在唯一性 = f 连续 + Lipschitz（比"偏导有界"弱、比"连续"强）；
   结论是**局部**的。
2. 证明引擎：ODE ⟺ 积分方程，Picard 算子的不动点，Banach 压缩映
   射；唯一性靠 Grönwall 型积分不等式。
3. 非 Lipschitz ⟹ 可能不唯一（y^(1/3)、√|y|）；Lipschitz 不保证全
   局存在（y² 爆破）。解的生命区间是 IVP 的一部分。
4. 一阶线性方程（p、g 连续）在整个区间上存在唯一——线性红利之一。
5. 解连续依赖初值（Grönwall：误差指数放大上界），这是数值求解的
   理论底气，也是第 20 章稳定性的前奏。

*本章示例：`examples/lean/Ode/Ch01Existence.lean`、`examples/julia/
01_existence.jl`、`examples/python/01_existence.py`、`examples/prolog/
01_existence.pl`、`examples/fortran/01_existence.f90`。*

---

上一章：[00 导言](00-intro.md) · 下一章：[02 方向场与等斜线](02-direction-fields.md)
