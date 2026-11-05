# 02 传输方程：特征线的第一个样本

**对应书 §2.1（Transport equation：初值问题、弱解、非齐次问题与
Duhamel 公式）。**

---

## 02.1 方程与特征线洞察

常系数**传输方程**是全书最简单的 PDE：

    u_t + b · Du = 0    于 ℝⁿ × (0, ∞)，

其中 b ∈ ℝⁿ 固定，u = u(x, t)。要害观察：方程说的是 **u 沿方向
(b, 1) ∈ ℝⁿ⁺¹ 的方向导数为零**。固定任意点 (x, t)，令

    z(s) := u(x + s b, t + s)    (s ∈ ℝ)，

则链式法则给出 ż(s) = Du·b + u_t = 0。所以 **z 是常数**：u 在过
(x, t)、方向 (b, 1) 的整条直线上取同一个值。这些直线叫**特征线**。
知道每条特征线上一个点的值，就知道 u 处处的值——PDE 被约化为
"沿直线抄数据"。

## 02.2 初值问题与解的表示

给初值 u(x, 0) = g(x)，过 (x, t) 的特征线 (x + sb, t + s) 在
s = −t 触到初始平面，触点是 (x − tb, 0)。于是（书式 (3)）：

    **u(x, t) = g(x − tb)**    (x ∈ ℝⁿ, t ≥ 0)。

反过来直接验证（链式法则两个方向相消）即知 g ∈ C¹ 时它确是解。
这一验证在 Lean 里是完整定理（`examples/lean/Evanspde/
Ch02Transport.lean`）：

```lean
theorem transport_solution (b : ℝ) {g g' : ℝ → ℝ}
    (hg : ∀ x, HasDerivAt g (g' x) x) (x t : ℝ) :
    deriv (fun t => g (x - b * t)) t + b * deriv (fun y => g (y - b * t)) x = 0 := by
  have hxt : HasDerivAt (fun t : ℝ => x - b * t) (0 - b * 1) t :=
    (hasDerivAt_const t x).sub ((hasDerivAt_id t).const_mul b)
  have ht : HasDerivAt (fun t : ℝ => g (x - b * t)) (g' (x - b * t) * (0 - b * 1)) t :=
    (hg (x - b * t)).comp t hxt
  ...
  rw [ht.deriv, hx.deriv]
  ring
```

一维 n = 1 的完整版本：∂ₜ 项由 `comp`（链式）算出 g′(x−bt)·(−b)，
∂ₓ 项算出 g′(x−bt)·1，`ring` 收尾相消。**PDE → ODE 的第一课**：
解 PDE 就是沿特征线积分 ODE——这是第 12 章一般特征线方法的种子。

## 02.3 弱解：广义解概念的第一次亮相

若 g 不 C¹（甚至间断），公式 (3) 当然还是定义了一个函数，而且
**没有任何别的候选**。书在此正式引入"弱解"的声明（informally
declare）：u(x,t) = g(x − tb) 是**弱解**——即使 g 不连续也有意义。
间断沿特征线传播、不增不减。

Julia 通道 `examples/julia/02_transport.jl` 做了两个实验：

**(a) 间断传播**：g = 1（x < 0.3）−1（x ≥ 0.3）的阶梯，b = 0.7，
t = 1.9。时刻 t 的解是同一形状的阶梯，跳点移到 x = 0.3 + t·b
= 1.63：

```julia
xc = 0.3 + t * b
@assert g_step(xc - 1e-9 - t * b) == 1.0 && g_step(xc + 1e-9 - t * b) == -1.0
```

（初版断言忘了减 t·b——写成在 xc 两侧采 g 本身，机器立刻拒绝；
**对"跳点在哪里"的断言必须采特征线足点上的 g**。）

**(b) 整数位移对账**：周期数据 g = sin 2πx、b = 1/2、t = 3/2 使
t·b·N = 48 恰为整格。离散平移与公式逐格一致（舍入级 6×10⁻¹⁶）：

```julia
u_num = [gper(x - t2 * b2) for x in xs]
u_shift = circshift([gper(x) for x in xs], 48)
@assert maximum(abs.(u_num .- u_shift)) < 1e-12
```

（坑账：Julia `circshift(A, s)[i] = A[mod1(i − s, n)]`，方向与
直觉相反——初版 −48 与正确值 +48 差 96 格 = 1.5 个周期，sin 全
体反号，mismatch = 2.0 的**签名**直接暴露相位差 π。）

Python 通道把弱解性质表为逐点恒等：u(·,t) 是 g(·) 的平移，
故 u(x₀ + tb, t) = g(x₀) 对 500 个随机点误差恒零。

## 02.4 非齐次问题与 Duhamel 公式

    u_t + b·Du = f，u(·,0) = g。

同一特征线上 ż(s) = f(x + sb, t + s)，从 s = −t 积分到 s = 0
（书式 (5)）：

    **u(x, t) = g(x − tb) + ∫₀ᵗ f(x + (s − t)b, s) ds**。

前半是齐次解，后半是源项沿特征线的累积——Duhamel 原理的第一个
形态（07 章热方程、10 章波方程的同名原理都从这里抽象）。

### 三通道交叉：闭式推导与 Simpson 对账

取 b = 1、g = sin、f(x,t) = e^{−t}cos x，被积函数沿特征线是
e^{−s}cos(a+s)，a = x − t。原函数

    F(s) = e^{−s}(sin(a+s) − cos(a+s))/2，积分 = F(t) − F(0)。

三路独立计算同一积分：

| 通道 | 方法 | 结果 (x=0.3, t=1) |
|---|---|---|
| Julia | 复化 Simpson（n=1024） | 0.583163515 |
| Julia/Python | 闭式 F(t)−F(0) | 0.583163515（差 1.2×10⁻¹⁴） |
| Python | 和角展开 + 分部（路线 2） | 同值（差 5.6×10⁻¹⁷） |
| Prolog | 复化 Simpson（N=512） | 0.583164（差 1.9×10⁻¹³） |

Python 的路线 2（把 cos(a+s) 拆成 cos a cos s − sin a sin s 分
别积分）与路线 1（合成原函数）逐位一致——**两条推导路径互为审
计**。最后把 u = sin(x−t) + I(x,t) 整体代回方程，数值残差
5.8×10⁻¹²（差分精度）——制造解对表闭环。

> **坑账（本教程第一个被翻案的数学错误）**：闭式初版写成
> F(0) − F(t)——原函数方向反了。Julia 与 Python 的 Simpson 直
> 接积分双双给出相反符号，当场翻案。**解析闭式必须过数值积分
> 的交叉，方向/符号不能靠信心。**

> **坑账（Prolog 递归 Simpson）**：终止子句在 K = N 直接返回，
> **右端点样本从未累加**，误差恰为 (h/3)·f(T)、收敛阶退化到
> O(h)。"N 加倍、误差减半"的收敛表一眼看出这不是 Simpson 该有
> 的 O(h⁴)。修法：终止子句先加右端点（权重 1）再停。

### Prolog：结构规则 + 数值内核

`examples/prolog/02_transport.pl` 把解的**结构**做成规则：

```prolog
foot(X, T, B, X0) :- X0 is X - T * B.                 % 特征足点
homog_solution(g, B, shift(g, mul(-1.0, mul(B, t)))). % 齐次解 = 移位
duhamel_structure(g, B, f, add(shift(...), integral(0, t, ...))).
weak_candidate(g, B) :- homog_solution(g, B, _).      % 弱解声明
```

特征线往返（`on_characteristic` 取 s = −t 回到初始平面）与足点
对账是数值断言；解的项结构是符号断言；`duhamel_value` 则是完整
的 Simpson 内核——一个文件三层：结构、规则、数值。

## 02.5 要点回顾

1. 特征线：方向导数为零 ⟹ 沿 (b,1) 直线为常数；初值问题的解
   u = g(x − tb)，PDE 化为抄数据。
2. g 不光滑时公式仍是唯一合理候选——**弱解**概念第一次出现，
   间断沿特征线平移传播（15 章激波的雏形）。
3. Duhamel：非齐次解 = 齐次解 + 源项沿特征线积分；后面热/波方
   程的 Duhamel 原理由此抽象。
4. 对表纪律三则：跳点断言要采特征足点；circshift 方向看
   `A[mod1(i−s,n)]`；闭式必须过数值积分交叉。

*本章示例：`examples/julia/02_transport.jl`、`examples/python/
02_transport.py`、`examples/prolog/02_transport.pl`、
`examples/lean/Evanspde/Ch02Transport.lean`。*

---

上一章：[01 适定性与 Hadamard 反例](01-wellposed.md) · 下一章：[03 Laplace 方程 I：基本解与平均值公式](03-laplace-fundamental.md) · [返回目录](../README.md)
