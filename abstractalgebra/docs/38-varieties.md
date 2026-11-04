# 38 簇

**对应原书 §7.4（pp. 538-555）。**

---

## 38.1 零点集与理想：一对伽罗瓦式的映射

多项式方程组的**解集**（几何）与**理想**（代数）之间有一对
天然映射——本节的全部结构由它们的往返决定：

> **定义** F ⊆ ℂ[X] = ℂ[x₁,…,xₙ]。**代数集**
> Var(F) = {a ∈ ℂⁿ : f(a) = 0 对所有 f ∈ F}。
> 反向，S ⊆ ℂⁿ 的**消没理想** Id(S) = {f : f|_S = 0}。

基本性质（命题 7.35/7.40，全部机器通道可复演）：

- Var(F) = Var((F))——零点集只看生成的理想；
- **V(IJ) = V(I) ∪ V(J)**、**V(I+J) = V(I) ∩ V(J)**——代数集
  对并、交封闭，构成 **Zariski 拓扑**（命题 7.36）的闭集；
- Id(V(I)) ⊇ √I（根理想 √I = {f : f^m ∈ I 对某 m}）；命题 7.39：
  Id(S) 恒为根理想。

> **定义** 代数集 V **不可约**，若 V = V₁ ∪ V₂ ⟹ V = V₁ 或
> V = V₂；不可约代数集叫**簇（variety）**。
> 命题 7.38：V 是簇 ⟺ Id(V) 是素理想。

## 38.2 零点定理：三个等价形态

代数闭域上（ℂ），零点集与理想的关系被彻底钉死：

> **定理 7.42（弱零点定理）** I ⊊ ℂ[X] ⟹ Var(I) ≠ ∅。
> **推论 7.43** I 真理想 ⟹ 存在 a ∈ ℂⁿ 使 f(a) = 0 ∀f ∈ I。

> **定理 7.44（希尔伯特零点定理，Nullstellensatz）**
> Id(Var(I)) = √I。

> **定理 7.45** ℂ[X] 的极大理想恰为 (x₁−a₁, …, xₙ−aₙ)。

三者等价（原书明确指出证明路径的循环）：7.42 + **Rabinowitsch
技巧** ⟹ 7.44：要证 f ∈ Id(Var(I))（即 f^m ∈ I），引入新变元 t，
考察理想 I + (1 − t·f)。它在 ℂ^{n+1} 中无零点（若 f 在 I 的零点
处为 0，则 1 − t·f = 1 ≠ 0；否则 f ≠ 0 处 I 已无公共零点），
由弱定理含 1，代值 t = 1/f 整理即得 f ∈ √I。7.44 ⟹ 7.45：
极大理想 M 素 ⟹ √M = M ⟹ Id(Var(M)) = M，取 Var(M) 的一点 a
即有 M ⊆ (X − a) ⊊ ℂ[X]，极大性逼 M = (X − a)。∎

7.45 是"代数-词典"：ℂⁿ 的**点** ↔ ℂ[X] 的**极大理想**——
这是代数几何的第一块基石。命题 7.46-7.48 继续给出字典的完整
对应：根理想 ↔ 代数集（V 与 Id 互逆的双射，保反包含）、
素理想 ↔ 簇。原书随后证明（命题 7.49/7.51，用希尔伯特基定理）
**每个代数集是有限多个簇的不冗长并**、**每个根理想是素理想的
不冗长交**——分解存在且唯一（素理想的交分解）。

## 38.3 幂零：根理想的意义

√I 把 I 的"高阶零点"抹平：I = (x²) 与 (x) 有同一个零点集
{0}（重根不增零点），Id(V) 把 (x²) 送回 (x)。几何看不见重数，
代数要显式开根——定理 7.44 说开根恰好是几何能看见的全部。
数值面例：√(y², xy) = (y)——y² ∈ I、xy ∈ I ⟹ y = "y²/y" 在
根中，而 x 不在（x 轴上 x 自由）。

## 38.4 机器验证一：Lean——成员面的证明

**文件：`examples/lean/Abstractalgebra/Ch38Varieties.lean`**。
拓扑等式的**成员面**证明（V(IJ) = V(I)∪V(J) 的一侧）：

```lean
example : ∀ a b : ℚ, a * a - 1 = 0 → (a * a - 1) * (b * b - 1) = 0 := by
  intro a b h; rw [h, zero_mul]
```

幂零判别（平方为零 ⟹ 本身为零）走 `mul_eq_zero`：

```lean
example : ∀ a : ℚ, a * a = 0 → a = 0 := by
  intro a h
  exact (mul_eq_zero.mp h).elim id id
```

弱零点定理的数值案：{x, x−1} 无公共零点（x = 0 与 x = 1 不相容，
`False` 的证明）+ 1 = x − (x−1) 的理想证书；V(xy) = V(x) ∪ V(y)
的域上无零因子论证。

## 38.5 机器验证二：Julia——格点零点集

**文件：`examples/julia/38_varieties.jl`**。多项式存
`Dict{(i,j) → 有理系数}`，`peval` 求值，零点集在 7×7 格点上
枚举：

```julia
vi = Set(p for p in grid if peval(I, p...) == 0)     # V(x²−1)：两列
vij = Set(p for p in grid if peval(IJ, p...) == 0)   # V(乘积) = 并
@assert vij == union(vi, vj)
```

断言组：V(IJ) = V(I) ∪ V(J)（(x²−1)(y²−1) 的乘积展开在格点上
取并）；V(I+J) = 交（四点 {(±1,±1)}）；弱零点定理数值案
（{x, x−1} 格点零点空 + 1 = x−(x−1) 的恒等式）；根理想
（xy 的平方 = y·(x²y) ∈ (x²y, xy²) ⟹ xy ∈ √I）；簇分解
V(xy) = 两条坐标轴。

## 38.6 机器验证三：Python 与 Prolog

**文件：`examples/python/38_varieties.py`**。sympy 三件套：
`solve`（V(I) 的符号解）、`groebner`（弱零点定理的机器形态——
无解系统 `{x, x−1}` 的基为 [1]）、以及本章的招牌——**Rabinowitsch
技巧的机器化**：

```python
# f ∈ √I ⟺ I + (1 − t·f) 无解 ⟺ 其 groebner 基含 1
Gr = sp.groebner([y**2, x * y, 1 - t * y], x, y, t, order="lex")
assert any(g.as_expr() == 1 for g in Gr.polys)     # y ∈ √(y², xy)
Gr2 = sp.groebner([y**2, x * y, 1 - t * x], x, y, t, order="lex")
assert not any(g.as_expr() == 1 for g in Gr2.polys)  # x ∉
```

理想成员判定用 `groebner.reduce`（余式为零 ⟺ 在理想中）：
y ∉ (y², xy) 但 y² ∈——根理想与理想的差就在这两行之间。

**文件：`examples/prolog/38_varieties.pl`**。多项式为
`i-j-c` 项表，`peval/4` 求值；49 格点枚举 V(IJ) 并、V(I+J) 交
（四点序恰为 [(-1,-1),(-1,1),(1,-1),(1,1)]——标准序的产物）；
V(x²) = V(x) = 直线 x = 0 的 7 个格点（**重根不增零点**——
开发时误写成单点 {(0,0)}，二维里 x² 的零点集是整条线，机器
抓出）；弱零点定理案、V(xy) 轴分解。

## 38.7 要点回顾

1. Var/Id 是一对反包含的伽罗瓦式映射；代数集 = Zariski 闭集，
   对并（V(IJ)）与交（V(I+J)）封闭。
2. 弱零点定理（7.42）：真理想在 ℂⁿ 中有公共零点；
   Rabinowitsch 技巧把它升级为 7.44：Id(Var(I)) = √I。
3. 7.45：ℂ[X] 的极大理想 = 点理想 (X−a)——点 ↔ 极大理想的
   代数-几何词典。
4. 根理想 ↔ 代数集、素理想 ↔ 簇（V 与 Id 在两个局部世界互逆，
   定理 7.48）；代数集 = 有限个簇的不冗长并（7.49/7.51，
   希尔伯特基定理的用武之地）。
5. 幂零元是几何的盲区：√ 把重数抹平，Nullstellensatz 说
   这正是全部盲区。

*对应示例：`examples/lean/Abstractalgebra/Ch38Varieties.lean`、
`examples/julia/38_varieties.jl`、`examples/python/38_varieties.py`、
`examples/prolog/38_varieties.pl`。*

---

上一章：[37 诺特环](37-noetherian.md) · 下一章：[39 广义的除法算式](39-division.md)
