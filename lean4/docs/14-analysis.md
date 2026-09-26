# 14 · 实分析

> 对应示例：`examples/11_mathlib_analysis/analysis.lean`

源码坐标：`Mathlib/Basic/Real/Basic.lean`（Real 构造与域结构，2026-08 起新位置）、`Mathlib/Topology/MetricSpace/Pseudo/Defs.lean`（ε-δ 语言）、`Mathlib/Analysis/Calculus/Deriv/`（导数）、`Mathlib/Topology/Order/IntermediateValue.lean`（介值定理）。

## 14.1 实数的构造与性质

ℝ 在 mathlib 中定义为**有理数柯西列对零化子的商**（`CauSeq.Completion.Cauchy`），随后逐步挂载 `Field → LinearOrderedField → CompleteLinearOrderedField` 实例：

```lean
import Mathlib.Basic.Real.Basic

-- 2026 年的 mathlib 把 LinearOrderedField 拆成了可组合的 mixin：
-- Field、LinearOrder、IsStrictOrderedRing 分开携带（Basic/Real/Basic.lean 各实例）
#check (inferInstance : Field ℝ)
#check (inferInstance : LinearOrder ℝ)
#check (inferInstance : IsStrictOrderedRing ℝ)

-- 完备性（确界原理）：ConditionallyCompleteLinearOrder
-- （实例在 Mathlib/Algebra/Order/Archimedean/Real/Basic.lean:136）
#check (inferInstance : ConditionallyCompleteLinearOrder ℝ)

-- 实数的代数与序
example (x y z : ℝ) : (x + y) * z = x * z + y * z := by ring
example (x y : ℝ) : x ≤ y ∨ y ≤ x := le_total x y

-- 确界原理：非空有上界的集合有上确界
#check @csSup_le    -- s.Nonempty → (∀ b ∈ s, b ≤ a) → sSup s ≤ a
```

## 14.2 绝对值

绝对值是**序理论**层面的定义（`Mathlib/Algebra/Order/AbsoluteValue/...` 与 `Mathlib/Algebra/Order/AbsValue.lean`），所有线性序加法交换群共享同一套 API：

```lean
import Mathlib.Algebra.Order.Group.Abs   -- abs 的序群引理

example (x : ℝ) : 0 ≤ |x| := abs_nonneg x
example (x : ℝ) : |x| = max x (-x) := rfl            -- 定义即如此
example (x y : ℝ) : |x + y| ≤ |x| + |y| := abs_add_le x y
example (x y : ℝ) : |x * y| = |x| * |y| := abs_mul x y
example (x : ℝ) : abs (abs x) = abs x := abs_abs x

-- 反三角不等式（嵌套的 |·| 记号解析不便时用 abs 函数形式）
example (x y : ℝ) : abs (abs x - abs y) ≤ abs (x - y) := abs_abs_sub_abs_le_abs_sub x y

-- ℝ 上 dist 与绝对值的关系（MetricSpace/Pseudo/Defs.lean:1118）
example (x y : ℝ) : dist x y = |x - y| := Real.dist_eq x y
```

## 14.3 Filter：mathlib 极限的统一语言

mathlib **不用** "数列极限""函数极限"分别定义——一切极限都是 `Filter.Tendsto f l₁ l₂`（`Mathlib/Order/Filter/Basic.lean`）：

```lean
import Mathlib.Topology.MetricSpace.Pseudo.Defs

-- 读法：Tendsto f l₁ l₂ 表示"f 把滤子 l₁ 映到不超过 l₂"
-- 数列收敛：Tendsto u atTop (𝓝 a)
-- 函数极限：Tendsto f (𝓝 a) (𝓝 L)
-- 连续性：  Tendsto f (𝓝 a) (𝓝 (f a))（即 ContinuousAt）

-- ε-N 定义 ↔ Filter 定义（Pseudo/Defs.lean:911，注意用 dist）
example {u : ℕ → ℝ} {a : ℝ} :
    Tendsto u atTop (𝓝 a) ↔ ∀ ε > 0, ∃ N, ∀ n ≥ N, dist (u n) a < ε :=
  Metric.tendsto_atTop

-- 常用滤子
#check (𝓝 0 : Filter ℝ)            -- 0 的邻域滤子
#check (atTop : Filter ℕ)          -- 趋于无穷
#check (𝓝[>] (0 : ℝ))             -- 0 的右邻域（𝓝 within Set.Ioi 0）
```

**Filter 的组合子是证明极限定理的主力**：

```lean
import Mathlib.Topology.Algebra.Order.LiminfLimsup

-- 极限四则运算：命名规律 Tendsto.op
example {u v : ℕ → ℝ} {a b : ℝ}
    (hu : Tendsto u atTop (𝓝 a)) (hv : Tendsto v atTop (𝓝 b)) :
    Tendsto (fun n => u n + v n) atTop (𝓝 (a + b)) :=
  hu.add hv

example {u v : ℕ → ℝ} {a b : ℝ}
    (hu : Tendsto u atTop (𝓝 a)) (hv : Tendsto v atTop (𝓝 b)) :
    Tendsto (fun n => u n * v n) atTop (𝓝 (a * b)) :=
  hu.mul hv

-- 常数列与恒等
example (c : ℝ) : Tendsto (fun _ : ℕ => c) atTop (𝓝 c) := tendsto_const_nhds
```

## 14.4 连续性

`Continuous f` = 每点连续 = 开集原像开，三者在 mathlib 里互相 rewrite：

```lean
import Mathlib.Topology.Continuous   -- Continuous/ContinuousAt（2026 起在根文件）

-- 三等价刻画（Continuous.lean:35/154）
example {f : ℝ → ℝ} : Continuous f ↔ ∀ x, ContinuousAt f x :=
  continuous_iff_continuousAt
example {f : ℝ → ℝ} :
    Continuous f ↔ ∀ s, IsOpen s → IsOpen (f ⁻¹' s) := continuous_def

-- ε-δ 形式（Metric 语境）
example {f : ℝ → ℝ} {a : ℝ} :
    ContinuousAt f a ↔ ∀ ε > 0, ∃ δ > 0, ∀ x, dist x a < δ → dist (f x) (f a) < ε :=
  Metric.continuousAt_iff

-- 连续性的封闭性定理（命名规律 Continuous.op / hf.op）
example {f g : ℝ → ℝ} (hf : Continuous f) (hg : Continuous g) :
    Continuous (f + g) := hf.add hg
example {f g : ℝ → ℝ} (hf : Continuous f) (hg : Continuous g) :
    Continuous (g ∘ f) := hg.comp hf

-- fun_prop 战术：自动组装"这个具体函数连续/可测/可微"的证明
example : Continuous (fun x : ℝ => x^2 + 2*x + 1) := by fun_prop
```

## 14.5 导数

`HasDerivAt f f' x` = "f 在 x 可导且导数为 f′"（`Mathlib/Analysis/Calculus/Deriv/Basic.lean:130`）；`deriv f x` 是取出来的导函数值（不可导时定义为 0——mathlib 的"垃圾值"惯例，见 14.7）。

```lean
import Mathlib.Analysis.Calculus.Deriv.Pow
import Mathlib.Analysis.Calculus.Deriv.Add
import Mathlib.Analysis.Calculus.Deriv.Mul    -- HasDerivAt.mul 在这里

-- 幂函数求导（Deriv/Pow.lean:137）
example (n : ℕ) (x : ℝ) : HasDerivAt (fun x : ℝ => x ^ n) ((n : ℝ) * x ^ (n - 1)) x :=
  hasDerivAt_pow n x

-- 求导法则（点号记法链：hf.add hg、hf.mul hg）
example {f f' g g' : ℝ → ℝ} {x : ℝ}
    (hf : HasDerivAt f (f' x) x) (hg : HasDerivAt g (g' x) x) :
    HasDerivAt (fun x => f x + g x) (f' x + g' x) x :=
  hf.add hg

example {f f' g g' : ℝ → ℝ} {x : ℝ}
    (hf : HasDerivAt f (f' x) x) (hg : HasDerivAt g (g' x) x) :
    HasDerivAt (fun x => f x * g x) (f' x * g x + f x * g' x) x :=
  hf.mul hg

-- 具体函数求导：HasDerivAt.deriv 把"可导且导数为…"转成 deriv 的等式
example : deriv (fun x : ℝ => x^2) 3 = 6 := by
  rw [(hasDerivAt_pow 2 3).deriv]    -- deriv (fun x => x^2) 3 = 2 * 3^(2-1)
  norm_num
```

## 14.6 经典证明案例三：介值定理（IVT）

源码：`Mathlib/Topology/Order/IntermediateValue.lean:558`——注意它在**拓扑**目录下，因为证明只用序拓扑，完全不需要度量！

```lean
import Mathlib.Topology.Order.IntermediateValue

-- 定理（IntermediateValue.lean:558，根命名空间，不是点号形式）：
-- Icc (f a) (f b) ⊆ f '' Icc a b（像集包含整个区间）
theorem ivt_demo {f : ℝ → ℝ} {a b y : ℝ} (h : a ≤ b)
    (hf : ContinuousOn f (Set.Icc a b)) (hy : f a ≤ y ∧ y ≤ f b) :
    ∃ x ∈ Set.Icc a b, f x = y := by
  have hmem : y ∈ Set.Icc (f a) (f b) := ⟨hy.1, hy.2⟩
  obtain ⟨x, hx, hfx⟩ := intermediate_value_Icc h hf hmem
  exact ⟨x, hx, hfx⟩

-- 实战用法：证明 √2 存在（f(x)=x²-2 在 [1,2] 变号）
theorem sqrt2_exists : ∃ x : ℝ, 1 ≤ x ∧ x ≤ 2 ∧ x^2 = 2 := by
  have hcont : ContinuousOn (fun x : ℝ => x^2) (Set.Icc 1 2) := by fun_prop
  have hmem : (2 : ℝ) ∈ Set.Icc ((1 : ℝ)^2) ((2 : ℝ)^2) := by norm_num
  obtain ⟨x, hx, hfx⟩ :=
    intermediate_value_Icc (show (1 : ℝ) ≤ 2 by norm_num) hcont hmem
  exact ⟨x, hx.1, hx.2, hfx⟩
```

**风格观察**：证明完全由"库定理 + 点号记法 + fun_prop/norm_num 自动化"组装而成，没有一行手动 ε-δ——这就是 mathlib 式分析证明的标准形态。

## 14.7 mathlib 的"垃圾值"惯例

`deriv f x` 在 f 不可导时**返回 0**（不是报错）；`1/0 = 0`；`(0 : ℝ)⁻¹ = 0`。这是全库的约定：**函数全定义，性质单独成定理**。好处是 `deriv (f + g) = deriv f + deriv g` 这类公式无需前提就能陈述，使用时再用 `DifferentiableAt` 条件解锁正确性定理：

```lean
import Mathlib.Analysis.Calculus.Deriv.Basic

-- 无条件的式子（垃圾值约定让它总成立）：
-- deriv (f + g) x = deriv f x + deriv g x   -- 需要可导条件才是数学定理
example {f g : ℝ → ℝ} {x : ℝ} (hf : DifferentiableAt ℝ f x)
    (hg : DifferentiableAt ℝ g x) :
    deriv (f + g) x = deriv f x + deriv g x :=
  deriv_add hf hg
```

---

> 上一章：[13 · 数论](13-number-theory.md) ｜ 下一章：[15 · 拓扑学](15-topology.md) ｜ 返回：[README](../README.md)
