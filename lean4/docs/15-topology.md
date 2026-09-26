# 15 · 拓扑学

> 对应示例：`examples/12_mathlib_topology/topology.lean`

源码坐标：`Mathlib/Topology/Defs/Basic.lean`（TopologicalSpace 类与 interior/closure/frontier 定义）、`Mathlib/Topology/Compactness/Compact.lean`（紧性）、`Mathlib/Topology/MetricSpace/Pseudo/Defs.lean`（度量空间）、`Mathlib/Topology/MetricSpace/Bounded.lean`（Heine-Borel）。

## 15.1 拓扑空间的公理化定义

```lean
import Mathlib.Topology.Defs.Basic

-- TopologicalSpace（Defs/Basic.lean:73）：class 携带 IsOpen 谓词 + 三条公理
-- class TopologicalSpace (X : Type u) where
--   IsOpen : Set X → Prop
--   isOpen_univ : IsOpen univ
--   isOpen_inter : ∀ s t, IsOpen s → IsOpen t → IsOpen (s ∩ t)
--   isOpen_sUnion : ∀ s, (∀ t ∈ s, IsOpen t) → IsOpen (⋃₀ s)

-- 派生概念全是 Defs 层的 def（行号即文档）：
#check @IsOpen        -- Defs/Basic.lean:95
#check @interior      -- :122  开核
#check @closure       -- :126  闭包
#check @frontier      -- :130  边界 = closure \ interior
#check @IsClosed      -- 补集为开

-- 邻域滤子 𝓝（Filters 与拓扑的接口，Mathlib/Topology/Defs/Filter.lean）
#check @𝓝            -- (x : X) → Filter X

-- 开集的基本运算引理（命名规律：isOpen_op）
example [TopologicalSpace X] (s t : Set X) (hs : IsOpen s) (ht : IsOpen t) :
    IsOpen (s ∩ t) := hs.inter ht
example [TopologicalSpace X] : IsOpen (∅ : Set X) := isOpen_empty
```

## 15.2 诱导拓扑与乘积拓扑

```lean
import Mathlib.Topology.Constructions

-- 函数诱导拓扑：TopologicalSpace.induced f _
-- 乘积空间的积拓扑实例（Constructions.lean）：
example [TopologicalSpace X] [TopologicalSpace Y] : TopologicalSpace (X × Y) :=
  inferInstance

-- 投影连续：continuous_fst / continuous_snd
example [TopologicalSpace X] [TopologicalSpace Y] : Continuous (Prod.fst : X × Y → X) :=
  continuous_fst

-- 子空间拓扑：restrict / 嵌入
example [TopologicalSpace X] (s : Set X) : TopologicalSpace s := inferInstance
```

## 15.3 度量空间

```lean
import Mathlib.Topology.MetricSpace.Pseudo.Defs

-- PseudoMetricSpace（Pseudo/Defs.lean:141）：允许 dist x y = 0 但 x ≠ y
-- class PseudoMetricSpace (α : Type u) : Type u extends Dist α where
--   dist_self : ∀ x, dist x x = 0
--   dist_comm : ∀ x y, dist x y = dist y x
--   dist_triangle : ∀ x y z, dist x z ≤ dist x y + dist y z
--   （外加与 UniformSpace/开球拓扑的一致性字段）
-- MetricSpace = PseudoMetricSpace + (dist x y = 0 → x = y)

example [PseudoMetricSpace α] (x : α) : dist x x = 0 := dist_self x
example [PseudoMetricSpace α] (x y : α) : dist x y = dist y x := dist_comm x y
example [PseudoMetricSpace α] (x y z : α) : dist x z ≤ dist x y + dist y z :=
  dist_triangle x y z

-- 开球与邻域的关系（nhds_basis_ball：𝓝 x 由球生成）
#check Metric.ball     -- Metric.ball x ε = {y | dist y x < ε}

-- 标准实例
#check (inferInstance : MetricSpace ℝ)
#eval dist (1 : ℝ) 5    -- 4（Real.dist_eq x y = |x - y|）
```

## 15.4 连续映射

```lean
import Mathlib.Topology.Continuous

-- 开集刻画（Topology/Continuous.lean:35）
example [TopologicalSpace X] [TopologicalSpace Y] {f : X → Y} :
    Continuous f ↔ ∀ s, IsOpen s → IsOpen (f ⁻¹' s) := continuous_def

-- 邻域刻画：ContinuousAt f x ↔ Tendsto f (𝓝 x) (𝓝 (f x))
example [TopologicalSpace X] [TopologicalSpace Y] {f : X → Y} {x : X} :
    ContinuousAt f x ↔ Tendsto f (𝓝 x) (𝓝 (f x)) := Iff.rfl   -- 定义即如此

-- 复合（点号风格）
example [TopologicalSpace X] [TopologicalSpace Y] [TopologicalSpace Z]
    {g : Y → Z} {f : X → Y} (hg : Continuous g) (hf : Continuous f) :
    Continuous (g ∘ f) := hg.comp hf
```

## 15.5 紧性

mathlib 的紧性用**滤子**定义（`IsCompact s ↔ ∀ f [NeBot f], f ≤ 𝓟 s → ∃ a ∈ s, ClusterPt a f`），与"每个开覆盖有有限子覆盖"等价（`isCompact_iff_finite_subcover`）：

```lean
import Mathlib.Topology.Compactness.Compact
import Mathlib.Topology.Order.Compact

-- 紧集在连续映射下的像仍紧（Compactness/Compact.lean:125）
example [TopologicalSpace X] [TopologicalSpace Y] {f : X → Y} {s : Set X}
    (hs : IsCompact s) (hf : Continuous f) : IsCompact (f '' s) := hs.image hf

-- 极值定理（Topology/Order/Compact.lean:246）：
-- 非空紧集上的连续函数达到最大值；结论用 IsMaxOn 包装
example [TopologicalSpace X] {s : Set X} {f : X → ℝ}
    (hs : IsCompact s) (hne : s.Nonempty) (hf : ContinuousOn f s) :
    ∃ x ∈ s, IsMaxOn f s x := hs.exists_isMaxOn hne hf

-- IsMaxOn 的展开（Order/Filter/Extr.lean:130）
example {f : X → ℝ} {s : Set X} {x : X} :
    IsMaxOn f s x ↔ ∀ y ∈ s, f y ≤ f x := isMaxOn_iff
```

## 15.6 Heine–Borel 定理

**旧教程里的写法是错的**（`IsBounded` 缺命名空间、定理缺 `ProperSpace` 条件）。真实版本（`Mathlib/Topology/MetricSpace/Bounded.lean:335`）：

```lean
import Mathlib.Topology.MetricSpace.Bounded

-- ProperSpace（"闭球紧"）+ MetricSpace 下：紧 ⟺ 闭且有界
example {s : Set ℝ} : IsCompact s ↔ IsClosed s ∧ Bornology.IsBounded s :=
  Metric.isCompact_iff_isClosed_bounded

-- 实战派生：闭区间是紧的（Order/IsLUB.lean:243，protected 需写全名）
example (a b : ℝ) : IsCompact (Set.Icc a b) :=
  ConditionallyCompleteLinearOrder.isCompact_Icc a b
```

## 15.7 分离公理与连通性

```lean
import Mathlib.Topology.Separation.Hausdorff
import Mathlib.Topology.Connected.Basic

-- T2 (Hausdorff)：任意两点有可分离邻域（Separation/Hausdorff.lean:85）
example [TopologicalSpace X] [T2Space X] (x y : X) (h : x ≠ y) :
    ∃ u v : Set X, IsOpen u ∧ IsOpen v ∧ x ∈ u ∧ y ∈ v ∧ Disjoint u v :=
  t2_separation h

-- 连通性（Connected/Basic.lean:50/55）
#check @IsPreconnected    -- 不能被两个非空开集分离
#check @IsConnected       -- Preconnected + Nonempty

-- 实区间的连通性（介值定理的拓扑根基）
example (a b : ℝ) (h : a ≤ b) : IsConnected (Set.Icc a b) :=
  ⟨Set.nonempty_Icc.mpr h, isPreconnected_Icc⟩
```

## 15.8 一致空间（进阶速览）

`UniformSpace`（`Mathlib/Topology/UniformSpace/Defs.lean`）抽象"一致连续/柯西/完备"所需的最小结构；每个度量空间诱导一个一致空间，`CompleteSpace` 在其上定义。分析章节（第14章）的完备性定理实际都建立在一致空间层面。

---

> 上一章：[14 · 实分析](14-analysis.md) ｜ 下一章：[16 · 线性代数](16-linear-algebra.md) ｜ 返回：[README](../README.md)
