# 25 欧氏作图

**对应原书 §4.2（pp. 354-366）。**

---

## 25.1 两千年的悬案

尺规作图只能两种动作：**过两点作直线**、**以已知点为圆心过已知点作圆**；
交点产生新点。古希腊三大作图问题——化圆为方、倍立方、三等分任意角——
悬置两千年，直到 19 世纪用**域论**一举解决：三个全都不可能。

解法的关键转换：**几何 → 代数**。

> **定义** 从单位长 1 出发，可作图的实数集 K 是包含 1 且对
> "+, −, ×, ÷（非零）"封闭、并对"开平方"（正数）封闭的最小集合的
> 子域链的终点。准确地说：P₀ = ℚ；P_{n+1} = P_n(√c : c ∈ P_n, c > 0)
> 中可作出的数。**可作图数** = 出现在某个 P_n 中的数。

每一步尺规作图的交点坐标，都是已有点坐标的**二次方程的根**——所以
每一步至多把域扩张 2 次。这是全部不可能性证明的引擎：

> **定理（次数判别）** 可作图数 α 的次数 [ℚ(α) : ℚ] 是 2 的幂。

**证明** α ∈ P_n，而 [P_n : ℚ] ≤ 2^n（每步至多二次），且
[ℚ(α) : ℚ] ∣ [P_n : ℚ]（塔定律 + 拉格朗日式的整除）。∎

## 25.2 三大不可能性

> **倍立方不可能**：作 2^{1/3}。x³ − 2 在 ℚ 上不可约（Eisenstein
> p = 2，第 21 章的工具箱），[ℚ(2^{1/3}) : ℚ] = 3——不是 2 的幂。∎

> **三等分任意角不可能**：只需一个反例角 60°。若可三等分，则
> cos 20° 可作图。三倍角公式 4cos³20° − 3cos 20° = cos 60° = 1/2 给出
> 8x³ − 6x − 1 = 0（x = 2cos 20°），它在 ℚ 上不可约（有理根候选
> ±1, ±1/2, ±1/4, ±1/8 全落空——有理根定理），次数 3。∎

> **化圆为方不可能**：作 π（或 √π）。π 是超越数（Lindemann 1882，
> 超出本教程工具）⟹ [ℚ(π) : ℚ] = ∞，连代数都不是。∎

**正 n 边形可作图**（Gauss）：正 n 边形可作 ⟺ n = 2^k p₁⋯p_s，其中
pᵢ 是互异的**费马素数** F_i = 2^{2^i} + 1。n = 17（Gauss 1796，18 岁）
可作；n = 7 不可作（φ(7) = 6 不是 2 的幂；更准确：[ℚ(ζ₇) : ℚ] = 6）。
费马素数已知仅 F₀..F₄ = 3, 5, 17, 257, 65537（F₅ 可分解）。

## 25.3 可作图数域的机器化

"作图"的代数本质是**嵌套二次扩张**。可作图数 = 从 1 出发经有限次
四则与开平方得到的数——这个集合对四则封闭但**不是域的有限扩张**
（开平方可无限嵌套）。验证工具：给定具体数 α，算 [ℚ(α):ℚ]：
- α 是有理系数多项式的根，分解出极小多项式；
- 次数是 2 的幂 ⟹ **不排除**可作图（还需正性/嵌套结构）；
- 次数有奇因子或 ≥ 3 ⟹ **不可作图**（不可能性的充分判据）。

## 25.4 机器验证一：Lean——次数与不可作图

**文件：`examples/lean/Abstractalgebra/Ch25Constructions.lean`。**

```lean
-- x³ − 2 不可约（Eisenstein p = 2 的实例）
example : Irreducible (Polynomial.X ^ 3 - 2 : Polynomial ℚ) :=
  Polynomial.irreducible_of_irreducible_map ... -- 以实际引理编译为准

-- 次数判据的数值版：3 ∣ 8 但 3 不是 2 的幂
example : ¬ ∃ k : ℕ, (2 : ℕ) ^ k = 3 := by decide
```

（文件以 ℚ(2^{1/3}) 的次数 3 为核心断言；三等分角的多项式
8x³−6x−1 的有理根落空以枚举 decide 呈现；费马素数 F₀..F₄ 与
F₅ = 641·6700417 的分解核对。）

## 25.5 机器验证二：Julia——嵌套平方根的作图模拟

**文件：`examples/julia/25_constructions.jl`** 把"可作图数"实现为
**嵌套平方根表达式树**：

```julia
"""可作图数：有理数 | sqrt(正可作图数) | 四则组合。"""
abstract type Constructible end
struct RatC <: Constructible; q::Rational{BigInt}; end
struct SqrtC <: Constructible; inner::Constructible; end
struct AddC <: Constructible; l::Constructible; r::Constructible; end
struct MulC <: Constructible; l::Constructible; r::Constructible; end
# ... SubC、DivC

evaluate(c::RatC) = c.q
evaluate(c::SqrtC) = sqrt(big(evaluate(c.inner)))   # 数值侧写
```

断言组：(1) **可作图的经典数**：√2、√(2+√3)、黄金比 (1+√5)/2（正
五边形！）都能构造并数值对拍；(2) **每次开方次数翻倍**：对嵌套深度
k 的表达式，其极小多项式次数 ≤ 2^k（具体案：√(2+√3) 满足 x⁴−10x²+1，
次数恰 4）；(3) **不可作图判据**：sympy `minimal_polynomial` 对
2^{1/3}、cos 20°（以 8x³−6x−1 验证）、cos(2π/7) 算出次数 3，全部
有奇因子 ⟹ 不可作图；(4) **正 17 边形可作**：cos(2π/17) 的极小
多项式次数 16 = 2⁴（sympy 或手算分解链），不排除；给出 Gauss 构造
的嵌套表达式的数值验证；(5) 费马数表 F₀..F₅ 与素性判定。

## 25.6 机器验证三：Python 与 Prolog

**文件：`examples/python/25_constructions.py`**：sympy 主场——
`minimal_polynomials`（nsimplify + minpoly）对 2^{1/3}、cos(20°)、
cos(2π/7)、cos(2π/17)、√(2+√3) 全套极小多项式与次数表；可作图性
判定函数 `constructible(α)` = 次数是 2 的幂；黄金比与正五边形对角线
比的对拍。

**文件：`examples/prolog/25_constructions.pl`**：

```prolog
% 有理根定理穷举：8x³−6x−1 无有理根（p|1、q|8）
no_rational_root_8x3 :-
    \+ (divisor_pair(1, 8, P, Q), 8 * P ^ 3 - 6 * P * Q ^ 2 - Q ^ 3 =:= 0).

divisor_pair(P0, Q0, P, Q) :- ...  % ±p/q 枚举
```

（整数化判定 q³f(p/q) = 0。）文件断言：三等分角多项式的 8 个有理
候选全落空、费马数 F₅ = 641 × 6700417 分解核对、2 的幂谱
{1,2,4,8,16} 中不含 3/6/7。

## 25.7 要点回顾

1. 尺规作图 = 四则 + 开平方的嵌套；每步交点坐标是二次方程的根，
   域扩张次数每步 ×2。
2. **次数判据**：可作图 ⟹ [ℚ(α):ℚ] 是 2 的幂；逆命题需嵌套结构
   （实二次塔），本教程用"不排除"口径。
3. 倍立方（x³−2 不可约，次数 3）与三等分 60° 角（8x³−6x−1，
   次数 3）不可能；化圆为方归 Lindemann 超越性。
4. 正 n 边形可作 ⟺ n = 2^k × 互异费马素数积；17 边形是 Gauss 的
   成名作（次数 16）。
5. "不可能性证明"是代数超越几何的典范：问题翻译成域的塔，
   次数守恒一票否决。

*对应示例：`examples/lean/Abstractalgebra/Ch25Constructions.lean`、
`examples/julia/25_constructions.jl`、`examples/python/25_constructions.py`、
`examples/prolog/25_constructions.pl`。*

---

上一章：[24 向量空间](24-vector-spaces.md) · 下一章：[26 线性变换](26-linear-maps.md)
