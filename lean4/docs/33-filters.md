# 33 · 滤子

> 对应示例：`examples/20_mathlib_filters/filters.lean`

**对标**: *Mathematics in Lean* 第11章（Topology · Filters）。

滤子（Filter）是 Mathlib 分析和拓扑的**统一极限语言**。它的洞见是：极限、收敛、连续、
"趋于无穷"、"几乎处处"这些概念，本质上都在说"某类足够大的集合"。把这些"大集合"抽象成
一个满足三条公理的族，就得到滤子——于是 `n → ∞`、`x → a`、"几乎所有点"都能用同一套
`Tendsto` 机器处理。这是 Bourbaki 学派的核心设计，也是 Mathlib 区别于其他证明库的招牌。

## 33.1 Filter：刻画"足够大"的集合族

```lean
import Mathlib.Order.Filter.Basic
import Mathlib.Order.Filter.AtTopBot.Basic
import Mathlib.Topology.Basic
import Mathlib.Topology.Order.OrderClosed
import Mathlib.Topology.Instances.Real.Lemmas
import Mathlib.Topology.MetricSpace.Basic
import Mathlib.Tactic

open Filter Topology

#check (Filter Nat)             -- Filter ℕ : Type
#check (atTop : Filter Nat)     -- atTop : Filter ℕ（趋于无穷）
#check (atBot : Filter Int)     -- atBot : Filter ℤ（趋于负无穷）
example : Filter Nat := ⊤
example : Filter Nat := ⊥
#check (pure : α → Filter α)    -- pure : α → Filter α（a 处的点滤子）
#check (Filter.principal : Set Nat → Filter Nat)   -- 𝓟 : Set ℕ → Filter ℕ
```

一个 `Filter α` 是 `Set α` 的一个子族（"大集合们"），满足：含全集、对上封闭（大集合的超集也大）、
对有限交封闭。**滤子之间的序是反向包含**：`l₁ ≤ l₂` 表示 `l₂` 的大集合都是 `l₁` 的大集合，
即 `l₁` 比 `l₂` "更细/更大"。所以 `⊤` 是最粗的滤子（只含 `univ` 一类），`⊥` 是最细的（含一切集合）。

几个标准滤子：
- `principal s`（记 `𝓟 s`）：所有包含 `s` 的集合——"以 `s` 为大"。
- `pure a = 𝓟 {a}`：`a` 处的点滤子。
- `atTop`（在有序类型上）：所有" cofinal 向上无界"的集合，刻画 `x → ∞`。
- `𝓝 a`（邻域滤子，需拓扑）：`a` 的所有邻域，刻画 `x → a`。

> **版本陷阱**：`𝓝`（nhds）和 `𝓟`（principal）这类花体记号是 **scoped notation**，必须
> `open Topology`（或 `open scoped Topology`）才生效；只 `open Filter` 会报 `𝓝` unknown identifier。
> `Filter.principal` 的 `#check` 会显示成它的记号 `𝓟`。另外 `Mathlib.Topology.Instances.Real`
> 已拆分为 `Mathlib.Topology.Instances.Real.Lemmas`（旧路径的 olean 不存在）。

## 33.2 最终性 ∀ᶠ：eventually

`∀ᶠ x in l, p x` 读作"对 `l`-几乎所有 `x`，`p x` 成立"，定义就是 `{x | p x} ∈ l`。
在 `atTop` 上，它意为"从某点往后最终都成立"：

```lean
#check (∀ᶠ (n : Nat) in atTop, 0 < n)   -- ∀ᶠ (n : ℕ) in atTop, 0 < n : Prop
example : ∀ᶠ n : Nat in atTop, 0 < n := eventually_gt_atTop 0
example : ∀ᶠ n : Nat in atTop, n ≥ 100 := eventually_ge_atTop 100

-- filter_upwards：把已知的 eventually 事实"向上"组合成新的事实
example : ∀ᶠ n : Nat in atTop, n ≠ 0 := by
  filter_upwards [eventually_gt_atTop 0] with n hn
  omega
```

`eventually_gt_atTop a : ∀ᶠ x in atTop, a < x`（最终大于任何固定界）是 `atTop` 的招牌引理。
`filter_upwards [h₁, h₂] with x hx₁ hx₂` 是处理 eventually 的主力战术：它取出若干已知"大集合"，
在它们的交（仍是大集合）上逐点证明目标，自动组装成新的 eventually。

## 33.3 Tendsto：滤子意义的极限

`Tendsto f l₁ l₂` 是整个理论的枢纽，定义极简：

```lean
-- Tendsto f l₁ l₂ 的定义就是 map f l₁ ≤ l₂
example (f : α → β) (l₁ : Filter α) (l₂ : Filter β) :
    Tendsto f l₁ l₂ ↔ map f l₁ ≤ l₂ := Iff.rfl

#check @Filter.map     -- @map : (α → β) → Filter α → Filter β
#check @Filter.comap   -- @comap : (α → β) → Filter β → Filter α
#check @tendsto_atTop_atTop
-- Tendsto f atTop atTop ↔ ∀ b, ∃ i, ∀ a, i ≤ a → b ≤ f a
```

`map f l`（沿 `f` 推前滤子）和 `comap f l`（沿 `f` 拉回滤子）是一对伴随。`Tendsto f l₁ l₂`
即"把 `l₁` 沿 `f` 推前后，仍细于 `l₂`"。这一个定义就统一了：

- `Tendsto f atTop atTop`：`f(n) → ∞`（数列趋于无穷）
- `Tendsto f atTop (𝓝 x)`：`f(n) → x`（数列收敛到 `x`）
- `Tendsto f (𝓝 a) (𝓝 b)`：`f` 在 `a` 处连续（`x → a` 时 `f x → b`）

`tendsto_atTop_atTop` 把抽象定义翻译成熟悉的 ε-N 式刻画：`f → ∞` 当且仅当
"对任何界 `b`，都存在起点 `i`，使得 `i` 之后 `f` 都 `≥ b`"。

```lean
-- fun n => n + 1 把 atTop 映到 atTop
example : Tendsto (fun n : Nat => n + 1) atTop atTop := by
  rw [tendsto_atTop_atTop]
  intro b
  use b
  intro a ha
  show b ≤ a + 1
  omega

-- 常值序列收敛到该常数
example : Tendsto (fun _ : Nat => (0 : Real)) atTop (𝓝 0) := tendsto_const_nhds
```

> 同样注意 `omega` 不 beta-归约 lambda：`show b ≤ a + 1` 先把 `(fun n => n+1) a` 显式还原成 `a + 1`。

## 33.4 𝓝：邻域滤子与序列收敛

`𝓝 x` 是 `x` 的邻域滤子：`s ∈ 𝓝 x` 当且仅当 `s` 包含一个含 `x` 的开集。它把"拓扑"接入滤子机器，
于是收敛/连续都变成 `Tendsto`。

```lean
#check (𝓝 : Real → Filter Real)   -- 𝓝 : ℝ → Filter ℝ
-- 开区间 (0, ∞) 是 1 的邻域
example : Set.Ioi (0 : Real) ∈ 𝓝 (1 : Real) :=
  Ioi_mem_nhds (by norm_num : (0 : Real) < 1)

-- 序列 u 收敛到 x，定义即 Tendsto u atTop (𝓝 x)；ℝ 上的 ε-N 刻画：
example (u : Nat → Real) (x : Real) :
    Tendsto u atTop (𝓝 x) ↔ ∀ ε > 0, ∃ N, ∀ n ≥ N, dist (u n) x < ε :=
  Metric.tendsto_atTop
```

`Ioi_mem_nhds : a < b → Ioi a ∈ 𝓝 b`（"`b` 右边的开区间是 `b` 的邻域"）需要 ℝ 的 `OrderTopology` 实例。
最后一条 `Metric.tendsto_atTop` 把抽象的 `Tendsto u atTop (𝓝 x)` 精确翻译成数学分析课本里的
ε-N 定义——这正是滤子设计的价值：**一个 `Tendsto` 概念，落到不同滤子上自动给出数列极限、
函数极限、连续性的标准定义**，无需各证一遍。

第14章（实分析）、第15章（拓扑）里的 `Tendsto`、`Continuous` 都建立在本章的滤子基础上；
回头看会发现它们只是 `Filter` 的不同实例化。

---

> 上一章：[32 · 序与格](32-order-lattices.md) ｜ 下一章：[34 · 逻辑深入与经典推理](34-logic-classical.md) ｜ 返回：[README](../README.md)
