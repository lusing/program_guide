# 07 · 有界算子与 B(ℋ)

> Hilbert 空间上的线性算子有一套优雅而发达的一般理论。这种二分
> （Hilbert 光明 / Banach 黑暗）的原因，恰恰与几何的相反状态
> 有关。——Conway 第 II 章开篇（意译）

从本章起进入算子理论。覆盖 Conway §II.1：有界性与范数、B(ℋ,K)
的赋范代数结构（次乘性！）、有限维的矩阵表示、乘法算子与积分
算子两大实例。

## 7.1 有界性与算子范数

**命题（Conway 1.1）**。A: ℋ → K 线性。连续 ⟺ 在 0 连续 ⟺ 在某点
连续 ⟺ ∃c: ‖Ah‖ ≤ c‖h‖。（与第 04 章 Riesz 前的 3.1 完全平行，
证明也平行。）

**定义**。满足最后一条的 A 称**有界算子**，全体记 B(ℋ, K)；B(ℋ) :=
B(ℋ,ℋ)。范数：

‖A‖ = sup{‖Ah‖ : ‖h‖ = 1} = sup_{h≠0} ‖Ah‖/‖h‖ = inf{c : ‖Ah‖ ≤ c‖h‖}。

## 7.2 B(ℋ) 是赋范代数

**命题（Conway 1.2）**。(a) ‖A+B‖ ≤ ‖A‖+‖B‖；(b) ‖αA‖ = |α|‖A‖；
(c) **‖BA‖ ≤ ‖B‖·‖A‖**（次乘性）。

**证明 (c)**。‖BAh‖ ≤ ‖B‖‖Ah‖ ≤ ‖B‖‖A‖‖h‖，对单位球取 sup。∎

次乘性使 B(ℋ) 成为**赋范代数**——第 29 章 Banach 代数的一切
（谱理论、泛函演算、C* 结构）都种在这一行不等式里。另外：

**定理（完备性）**。K 完备 ⟹ B(ℋ,K) 完备。（逐点极限 + 一致
Cauchy；这是第 10 章紧算子极限刻画的门票。）

**例（Conway 1.3-1.4）**。dim < ∞ 时线性 ⟹ 有界（每个算子 = 矩阵）；
ℓ² 上的算子对应无穷矩阵，但**范数没有元素公式**——4 次以上多项式
根不可解，n×n 矩阵范数无闭式（Conway 的著名注记）。

## 7.3 两大实例

**乘法算子（Conway 1.5）**。σ-有限测度空间，φ ∈ L^∞，M_φ f = φf。
则 M_φ ∈ B(L²)，**‖M_φ‖ = ‖φ‖_∞**。证明的"≤"方向是一行 CBS；
"≥"方向在 σ-有限时取集中在 |φ| ≈ ‖φ‖∞ 处的单位向量。非 σ-有限
时等号可失效（Conway 给出带无穷原子的反例：M_φ = 0 但 ‖φ‖∞ = 1）。

**积分算子（Conway 1.6）**。k 可测，若
∫|k(x,y)|dμ(y) ≤ c₁ a.e.、∫|k(x,y)|dμ(x) ≤ c₂ a.e.（Schur 条件），
则 (Kf)(x) = ∫k(x,y)f(y)dμ(y) 有界且 **‖K‖ ≤ (c₁c₂)^{1/2}**。

**证明**（Schur 的双重 CBS）。先证 Kf 有意义且逐点有界：

|Kf(x)| ≤ ∫|k|^{1/2}|k|^{1/2}|f| ≤ (∫|k(x,y)|dy)^{1/2}
(∫|k(x,y)||f(y)|²dy)^{1/2} ≤ c₁^{1/2}(∫|k(x,y)||f(y)|²dy)^{1/2}。

平方再积分（Fubini）：

∫|Kf(x)|²dx ≤ c₁∫∫|k(x,y)||f(y)|²dydx = c₁∫|f(y)|²(∫|k(x,y)|dx)dy
≤ c₁c₂‖f‖²。∎

这是 CBS 的漂亮二次使用：把 |k| 拆成 |k|^{1/2}·|k|^{1/2}，一次
CBS 给逐点界，再一次 CBS（平方和积分）给 L² 界。这两个常数
c₁, c₂ 在第 12 章 Sturm-Liouville 会再次出现（Green 核的 Schur 界
恰好给出紧性需要的范数控制）。

**反例警示**（Conway 1.5 之后的注）：非 σ-有限测度空间上乘法
算子的范数等式可以失效。取 Ω = [0,1] 的 Borel 集加上"含 0 则测度
∞"的测度：每个 L² 函数在 0 处取值 0，于是 M_{χ{0}} = 0 但
‖χ{0}‖_∞ = 1。σ-有限不是技术装饰，是定理的一部分。

## 7.3b 算子范数为什么没有元素公式

Conway 1.4 的注值得展开：n×n 矩阵 A 的算子范数 = A*A 的最大
特征值的平方根（第 08 章 C* 恒等式 + 第 11 章紧谱定理将证明这一点）。
而特征值是 n 次多项式的根——n ≥ 5 时没有根式解（Galois 理论）。
所以"从矩阵元素算出范数"注定没有有限次加减乘除开方的公式。
这不是我们不会算，是代数学说不能算。数值通道的奇异值分解
（SVD）是迭代算法，不是闭式——数学结构与计算复杂性在此交汇。

顺带的正论：**上界**倒是有便宜的好公式——行和、列和、Frobenius
范数都控制算子范数（Schur 界是积分版的"行列和控制"）。
"估计范数"是实用技艺，"精确计算范数"是解代数方程。

## 7.4 机器化：Lean

`examples/lean/Funanalysis/Ch07BoundedOperators.lean`：

```lean
-- 次乘性（Conway 1.2 (c)）
example (A B : E →L[ℝ] E) : ‖B.comp A‖ ≤ ‖B‖ * ‖A‖ :=
  ContinuousLinearMap.opNorm_comp_le B A

-- 由此 E →L[ℝ] E 是赋范环（mathlib 实例）
noncomputable example : NormedRing (E →L[ℝ] E) := by infer_instance

-- 完备性：B(ℋ,K) 是 Banach 空间
example : CompleteSpace (E →L[ℝ] F) := by infer_instance
```

有限维的"线性 ⟹ 连续"：

```lean
example [FiniteDimensional ℝ E] (A : E →ₗ[ℝ] F) : Continuous A :=
  LinearMap.continuous_of_finiteDimensional A
```

乘法算子的"≤"方向给了一个完整的有限维手工证明（对角缩放
x ↦ (dᵢxᵢ) 满足 ‖dx‖ ≤ max|dᵢ|·‖x‖）：`EuclideanSpace.norm_sq_eq`
把范数平方化成坐标平方和，然后逐项 `|dᵢ| ≤ s` 控制再开方。这正是
Conway 1.5 证明的"≤"半边；"≥"半边（等号）由测试向量达到，数值
通道的实验 3 从两侧验证。

## 7.5 机器化：Isabelle

`examples/isabelle/FA07/T07_BoundedOperators.thy` 干两件事：

1. **一般次乘性**：`onorm (f ∘ g) ≤ onorm f * onorm g`，对任意
   赋范空间间的有界线性映射（`onorm_bound` 命题 + `onorm` 上界两次）。
2. **对角算子的范数上界**：定义 diag2 a b（axis 分解式），证明
   `‖diag2 a b x‖ ≤ max |a| |b|·‖x‖`（`norm_diag2_le`，Bessel 式
   逐项平方估计）并由此得有界性。精确等号 `onorm = max |a| |b|`
   由 Lean（乘法算子 ≤ 方向）与数值通道（两侧逼近等号）承载——
   v4.33 的 `onorm_le` 引理存在前提序/unification 怪癖（`onorm_bound`
   命题形式可用），按通道分工原则裁撤等号版。

范数平方展开靠 `inner_axis_axis` 的 delta 条件 + 勾股——FA00 风格
的复用。

## 7.6 数值实验

**Julia**（`07_bounded_operators.jl`）：(1) 次乘性 500 次随机验证；
(2) **opnorm(A) = 最大奇异值**（谱定理的前奏——这一事实第 11 章
正式化为紧自伴算子定理）；(3) diag 的范数 = max|d|（1.5 等号，
两侧）+ 一般矩阵 max|entry| 只是下界（1.4 的"无元素公式"现象）；
(4) 有限维随机矩阵范数恒有限（1.3）。

**Python**（`07_bounded_operators.py`）：(1) **随机方向逼近 sup**：
20000 个随机单位方向的 ‖Ax‖ 最大值从下方逼近 σ_max（覆盖 ≥ 97%）
——"sup 的数值本质"；(2) **Schur 界的验证**：对称核
k(x,y) = 1/(1.1−xy) 的积分算子，幂法迭代数值范数 1.449 ≤
√(c₁c₂) = 2.398（Conway 1.6 的"≤"）；(3) 乘法算子范数 = max|φ|
（100 次随机向量上界紧）。

## 7.7 章末对照表

| Conway | 内容 | Lean | Isabelle | Julia/Python |
|---|---|---|---|---|
| 1.1 | 有界⟺连续、范数 | `E →L` 类型即有界 | `bounded_linear`+`onorm` | — |
| 1.2 (c) | 次乘性 | `opNorm_comp_le` + `NormedRing` | ✓ 一般版 | ✓ 500 次 |
| — | 完备性 | `infer_instance` | — | — |
| 1.3 | 有限维全有界 | `continuous_of_finiteDimensional` | — | ✓ |
| 1.4 | 矩阵=算子 | `Matrix.toEuclideanLin` | — | ✓ 无闭式现象 |
| 1.5 | 乘法算子 | ✓ ≤ 方向手工 | ✓ 等号（diag2） | ✓ 两侧 |
| 1.6 | 积分算子 Schur 界 | — | — | ✓ 幂法+界 |

## 7.8 习题

1. **（纸笔）** 证明 B(ℋ,K) 的完备性（当 K 完备）。
2. **（纸笔）** Conway 1.5 的"≥"半边：σ-有限时构造单位向量 f 使
   ‖M_φ f‖ 逼近 ‖φ‖∞。
3. **（纸笔）** 验证 Conway 的非 σ-有限反例（无穷原子测度）中
   ‖M_φ‖ < ‖φ‖∞。
4. **（机器）** Lean：把次乘性推广为严格不等式可以取等的刻画
   （等号 ⟺ 存在共同达范向量链）。
5. **（数值）** Volterra 算子 (Vf)(x) = ∫₀ˣ f：数值估计 ‖V‖，
   与上界 2/π 对照（第 12 章 Sturm-Liouville 的伏笔）。

---

上一章：[06 fourier-sums](docs/06-fourier-sums.md) · 下一章：[08 adjoint](docs/08-adjoint.md)
