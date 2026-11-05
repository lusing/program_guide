# 01 预备：典型方程、定解问题与适定性

**对应书第 1 章 §2"关于偏微分方程的一些基本概念"（例 2.1–例 2.12、
定解问题、二阶方程分类、一阶方程组）。**

---

## 1.1 典型方程谱

含未知函数偏导数的方程称为偏微分方程；未知函数不止一个时是方程
组。原书第 1 章用十个例子（例 2.1–2.10）铺出全书要打交道的方程
谱。逐个认识（记 Δ = ∂²/∂x₁² + … + ∂²/∂xₙ² 为 Laplace 算子）：

**Laplace 方程**（例 2.1）：Δu = 0，解称为调和函数。力学、电学中
的势函数满足它。这是椭圆型方程的原型，第 21–29 章的主角。

**Cauchy–Riemann 方程组**（例 2.2）：n = 2 时 u_x = v_y, u_y = −v_x。
调和函数的共轭对给出解析函数 f(z) = u + iv；(u, −v) 也可解释为无旋
不可压缩流的速度场。它是一阶**方程组**分类的椭圆样例。

**Poisson 方程**（例 2.3）：Δu = f；更一般的散度形式
∇·(k(x)∇u) = F，k(x) > 0。变系数、间断系数的情形正是有限元方法
（第 18、29 章）的用武之地。

**波动方程**（例 2.4）：u_tt = a²Δu + F。n = 1 是弦振动或一维声波；
n = 2 是膜振动。信息以有限速度 a 传播——第 08 章 CFL 条件的物理
来源。

**扩散（传热）方程**（例 2.5）：u_t = ∇·(k∇u) + F，u 是浓度或温度。
扰动**即时**传遍全域（虽按指数衰减），解随时间变光滑——与波动
方程性格相反。

**对流扩散方程**（例 2.6）与**对流方程**（例 2.7）：u_t + a·∇u = kΔu + F；
k = 0 时退化为对流方程 u_t + a u_x = 0。对流项与扩散项的强度比
（网格 Péclet 数）会在第 17 章制造著名的数值振荡问题。

**双调和（重调和）方程**（例 2.8）：Δ²u = 0，四阶。流体力学（ Stokes
流）与弹性力学（板）中出场；第 23 章会看它的 13 点差分格式。

**非线性例子**：二维位势流方程（例 2.9）与 **Navier–Stokes 方程组**
（例 2.10）——三维不可压缩流动，速度、压力耦合，对流项非线性。
数值天气预报、数值风洞、油井燃烧模拟的最终对象都是这类方程组；
本教程把它们留在非线性专章（第 13、20 章）的入口处。

阶：方程中出现的最高偏导数阶数。例 2.2 是一阶方程组，其余是二阶
（双调和是四阶）。

## 1.2 定解问题与适定性

偏微分方程一般**没有通解**——不像 n 阶常微分方程那样有含 n 个任意
常数的通解。我们总是在附加条件下求解：

- **边界条件**：在区域边界 ∂Ω 上给出。三类经典形式（以椭圆方程为例）：
  - 第一类（Dirichlet）：u|∂Ω = g；
  - 第二类（Neumann）：∂u/∂n|∂Ω = g（n 为外法向）；
  - 第三类（Robin）：∂u/∂n + σu = g。
- **初始条件**：含时间 t 的问题在超平面 t = 0 上给出 u(x, 0) = g(x)，
  波动方程还要 u_t(x, 0) = h(x)。

方程 + 定解条件 = **定解问题**。三类典型定解问题：

    椭圆边值问题        Δu = F 于 Ω 内,  u|∂Ω = g
    扩散初边值问题      u_t = a²u_xx,  u(0,t)=u(l,t)=0, u(x,0)=g(x)
    波动初边值问题      u_tt = a²u_xx, 边界同上, u(x,0)=g, u_t(x,0)=h

**适定性**：若定解问题在某个函数集合中解存在、唯一，且定解资料
（或自由项 F）微小变化时解也仅有微小变化，则称问题是适定的。本书
（与本教程）讨论的定解问题都适定；不适定问题（反演、某些地质/
石油问题）是另一门学科。

## 1.3 二阶方程的分类：主部矩阵说话

二阶拟线性方程指对最高阶导数线性的方程。其**主部**（最高阶项）
在一点处由一个 n×n 对称矩阵 A = [aᵢⱼ] 决定：

    Σ aᵢⱼ u_{xᵢxⱼ} + (低阶项) = 0.

分类完全由 A 的特征值符号决定（原书 §2.3）：

- A 正定或负定（特征值全同号）→ **椭圆型**；
- A 的特征值至少一个为零 → **抛物型**；
- A 的特征值皆非零且恰 n−1 个同号 → **双曲型**。

两个自变量的情形（x 可以是时间 t）最常用，方程写为

    a u_xx + 2b u_xy + c u_yy + (低阶项) = 0，

判别式一目了然：**ac − b² > 0 椭圆；< 0 双曲；= 0 抛物**。验证三个
原型：Laplace（a=c=1, b=0）得 1 > 0 椭圆；波动 u_tt − a²u_xx = 0
（a=−a², c=1, b=0）得 −a² < 0 双曲；扩散 u_t = a²u_xx（c=0）得
0 抛物。✓

**特征曲线与特征方向**。平面上曲线 x = φ(s), y = ψ(s) 若满足

    a φ'(s)² − 2b φ'(s)ψ'(s) + c ψ'(s)² = 0，

称为方程的特征曲线；向量 (β₁, β₂) 满足 aβ₂² − 2bβ₁β₂ + cβ₁² = 0
称为特征方向（特征曲线的切向）。写成 y = y(x) 时特征线满足常微分
方程

    dy/dx = (b ± √(b² − ac)) / a.

于是：**双曲型方程有两族实特征曲线**（过每点两条），**抛物型一
族**，**椭圆型没有实特征曲线**。这个三分法不是分类学游戏——第 08
章会看到，双曲方程差分格式的稳定性条件（CFL）说的正是"差分的
依赖域必须包含微分方程的依赖域"，而依赖域正是由特征线围出来的。

## 1.4 特征线上的解：对流方程与 d'Alembert 公式

**一维对流方程** u_t + a u_x = 0（a > 0）是全书最简单的双曲模型，
值得完全解掉。它的特征方程 dx/dt = a，特征线是直线族 x − at =
const。沿特征线

    d/dt u(x(t), t) = u_t + a u_x = 0，

所以**解沿特征线是常数**，初值问题的解就是

    u(x, t) = g(x − at)

——初始波形以速度 a **刚性平移**，既不衰减也不变形。数值格式能
多好地复现这个平移（不振荡、不过份耗散、不过份色散），是第 07、
08 章的永恒考题。

过点 (x₀, t₀) 的特征线回到初值线于 x₀ − a t₀：解 u(x₀, t₀) 只依赖
初值在**这一个点**上的值。改变初值线其它点的值，完全不影
响 (x₀, t₀) 处的解。这就是**依赖区间**的最简形态。

**波动方程的 d'Alembert 公式**。一维波动 u_tt = c²u_xx 的两族特征
线是 x ± ct = const。初值问题 u(x,0)=g(x), u_t(x,0)=h(x) 的解：

    u(x, t) = ½[g(x+ct) + g(x−ct)] + (1/2c) ∫_{x−ct}^{x+ct} h(ξ) dξ.

两点值得注意（第 08 章 CFL 讨论的直接素材）：

1. 解在 (x₀, t₀) 只依赖初位移 g 在**区间端点** x₀ ± ct₀ 两点的值，
   以及初速度 h 在**整个依赖区间** [x₀−ct₀, x₀+ct₀] 上的积分。
2. 改变 g 在区间外的值不影响解；改变 h 在区间内的值即刻影响解。

## 1.5 一阶方程组的分类

两个自变量的一阶拟线性方程组

    ∂u/∂y = A(x, y, u) ∂u/∂x + h(x, y, u),   u ∈ ℝᵖ,

分类看矩阵 A 的特征结构（原书 §2.4）：

- A（在每点）有 p 个线性无关的**实**特征向量 → **双曲型**；
  特征值两两相异时是**严格双曲型**。
- 没有足够实特征向量 → 椭圆型。

两个对照例子：Cauchy–Riemann 方程组的 A = [[0, −1], [1, 0]] 特征值
±i，无实特征向量——椭圆型。一维对流方程（p = 1）的 A = (−a) 总有
实特征向量——双曲型，特征线 x − at = const。特征曲线的方程组形式：
φ'(s) + λ ψ'(s) = 0，其中 λ 取遍 A 的特征值。

## 1.6 机器验证

### Lean：三个模型方程的解核对

Lean 通道（`examples/lean/Pdenum/Ch01Prelim.lean`）把 0.3 节的三个
对表函数用 `HasDerivAt` 逐字核对。对流方程部分：

```lean
/-- 对流方程解的时间片：`t ↦ sin (x - a*t)` 的导数是 `cos (x - a*t) * (-a)`。 -/
lemma hasDerivAt_advection_t (x a t : ℝ) :
    HasDerivAt (fun t => sin (x - a * t)) (cos (x - a * t) * (-a)) t := by
  have h1 : HasDerivAt (fun _ => x) 0 t := hasDerivAt_const t x
  have h2 : HasDerivAt (fun s => a * s) a t := by
    simpa [mul_one] using HasDerivAt.const_mul a (hasDerivAt_id t)
  have hsub : HasDerivAt ((fun _ : ℝ => x) - (fun s => a * s)) (0 - a) t :=
    HasDerivAt.sub h1 h2
  have heq : (fun s => x - a * s) = ((fun _ : ℝ => x) - (fun s => a * s)) := by
    funext s; rfl
  rw [← heq] at hsub
  have hsin := HasDerivAt.sin hsub
  simpa using hsin

/-- **对流方程核对**：`u_t + a * u_x = 0`——两项相消。 -/
theorem advection_solution (x a t : ℝ) :
    cos (x - a * t) * (-a) + a * cos (x - a * t) = 0 := by ring
```

讲清楚这段代码。`HasDerivAt f f' x` 是 mathlib 对"f 在 x 可导且导数
为 f′"的**原始表述**——不借助任何求导法则，就是差商极限存在且等于
该值。时间片导数的证明分三步：常函数 `x` 的导数是 0（`hasDerivAt_const`）；
线性函数 `a·s` 的导数是 a；和差法则（`HasDerivAt.sub`）装配出
内层函数 `s ↦ x − a·s` 的导数 `−a`；再用链式法则的正弦版
（`HasDerivAt.sin`）包一层。`heq` 一行是 mathlib 的形态桥
接——`HasDerivAt.sub` 产出的是 Π 类型层面的函数差 `(f − g)`，与
手写的 λ 表达式 `fun s => x − a*s` 定义相等，`funext; rfl` 让改写
合法。**收尾定理 `advection_solution` 是纯 ring**：时间片导数
cos·(−a) 加上 a 倍空间片导数 a·cos 恰好相消——方程被逐字验证。

扩散方程部分核对分离变量解 u = e^{−π²t} sin(πx)：

```lean
/-- 扩散方程解的时间片导数：`sin (πx) * (exp (-π²t) * (-π²))`。 -/
lemma hasDerivAt_heat_t (x t : ℝ) :
    HasDerivAt (fun s => sin (π * x) * exp (-(π : ℝ) ^ 2 * s))
      (sin (π * x) * (exp (-(π : ℝ) ^ 2 * t) * -(π : ℝ) ^ 2)) t := by
  have h1 : HasDerivAt (fun s => -(π : ℝ) ^ 2 * s) (-(π : ℝ) ^ 2) t := by
    simpa [mul_one] using HasDerivAt.const_mul (-(π : ℝ) ^ 2) (hasDerivAt_id t)
  exact HasDerivAt.const_mul (sin (π * x)) (HasDerivAt.exp h1)

/-- **扩散方程核对**：`u_t` 与 `u_xx` 是同一个数。 -/
theorem heat_solution (x t : ℝ) :
    sin (π * x) * (exp (-(π : ℝ) ^ 2 * t) * -(π : ℝ) ^ 2)
      = exp (-(π : ℝ) ^ 2 * t) * (π * (-sin (π * x) * π)) := by
  have hπ : (π : ℝ) ^ 2 = π * π := by ring
  rw [hπ]
  ring
```

这里出现一个值得记下的技巧：**引理按组合子的"产出一形式"陈述**
（`sin (πx) * (exp (−π²t) * (−π²))` 是 `const_mul` 与 `HasDerivAt.exp`
组合的自然产物），而"人写形式"与"产出形式"之间的换算（两边都
等于 −π²·u）集中放进纯 `ring` 的收尾定理。证明义务分成了"每一步
求导法则都对"与"代数恒等"两层，每层都能自动闭核。

波动方程取 d'Alembert 解在 g = s² 的特例 u = x² + (at)²：两条一阶
导数引理后，收尾 `wave_solution : a*a + a*a = a*a*(1+1)`（u_tt = 2a²
= a²·u_xx = a²·2）同样是 ring。

### Julia/Python：分类引擎、d'Alembert 与依赖区间

数值双通道（`examples/julia/01_prelim.jl` 与 `examples/python/
01_prelim.py`）做四件事。分类引擎就是判别式：

```julia
function classify(a, b, c)
    d = a * c - b * b
    if d > 0
        return "elliptic"
    elseif d < 0
        return "hyperbolic"
    else
        return "parabolic"
    end
end

@assert classify(1.0, 0.0, 1.0) == "elliptic"     # Laplace
@assert classify(1.0, 0.0, 0.0) == "parabolic"    # 扩散（y 充当 t）
@assert classify(1.0, 0.0, -1.0) == "hyperbolic"  # 波动
```

d'Alembert 公式的初速度积分项用复合 Simpson 公式数值计算，与
h = sin x 的闭式原函数对账：

```julia
function simpson(f, a, b, n)
    hh = (b - a) / n
    s = f(a) + f(b)
    for i in 1:n-1
        s += (i % 2 == 1 ? 4 : 2) * f(a + i * hh)
    end
    s * hh / 3
end

function dalembert(x, t; c=cwave, n=2000)
    base = 0.5 * (gfun(x + c * t) + gfun(x - c * t))
    base + simpson(hfun, x - c * t, x + c * t, n) / (2 * c)
end
```

在 (x,t) ∈ {(0.7,0.3), (1.2,0.5), (0,0.4)} 三点，Simpson 值与闭式
值之差小于 1e−10（Simpson 的 O(h⁴) 误差在 n = 2000 时到机器精度）。
再对公式给出的 u 做中心差分残差，测得 h → h/2 收缩比 4.000——
**d'Alembert 公式确实是波动方程的解**。

依赖区间的数值实证最有教学味。取 (x₀, t₀) = (0.6, 0.25)，c = 2，
依赖区间 [0.1, 1.1]。构造初值 g₂：在区间左端外某处加上一个大小为
100 的二次"重锤"，区间内与 g 完全一致：

```julia
lo, hi = x0 - cwave * t0, x0 + cwave * t0
g2(x) = exp(-(x - 1.0)^2) + (x < lo - 0.05 ? 100.0 * (x - (lo - 0.05))^2 : 0.0)
u1 = dalembert_g(gfun, x0, t0)
u2 = dalembert_g(g2, x0, t0)
@assert abs(u1 - u2) < 1.0e-14 "依赖区间外的初值改动不应影响解"
```

u(x₀, t₀) 纹丝不动（差 < 1e−14，纯舍入）。反过来，把扰动加在
**端点** x₀ + ct₀ 上，解精确改变 0.5（公式里 g 在端点的权重恰是
½）；把扰动加进**区间内部**的初速度 h 上，解改变约 0.05（扰动
宽度 0.2 除以 2c = 4）。三个数字把 1.4 节的两点注意完整落到机器上。

## 1.7 要点回顾

1. 十个典型方程覆盖全书的战场：三原型（Laplace/扩散/波动）加上
   对流扩散、双调和与非线性组。
2. 定解问题 = 方程 + 初/边值条件；适定性 = 存在 + 唯一 + 连续依赖。
3. 二阶方程分类看主部矩阵特征值：全同号椭圆、有零抛物、n−1 同号
   双曲；两变量判别式 ac − b²。特征曲线：双曲两族、抛物一族、
   椭圆无实特征。
4. 对流方程解 u = g(x − at) 沿特征线平移；d'Alembert 公式里 g 读
   端点、h 积分整个依赖区间——依赖域概念是 CFL 条件的前奏。
5. 一阶方程组分类看 A 的实特征向量个数：CR 组椭圆、对流方程双曲。

*本章示例：`examples/lean/Pdenum/Ch01Prelim.lean`、`examples/julia/
01_prelim.jl`、`examples/python/01_prelim.py`。*

---

上一章：[00 导言](00-intro.md) · 下一章：[02 Fourier 变换与复矩阵](02-fourier.md)
