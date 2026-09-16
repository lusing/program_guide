/-
文件: 12_mathlib_topology/topology.lean
描述: 第15章 拓扑学（与教程同步，Mathlib4 master@2026-09 验证）
编译: lake build Lean4Tutorial.Examples.MathlibTopology.Topology
-/

import Mathlib.Topology.Defs.Basic
import Mathlib.Topology.Constructions
import Mathlib.Topology.MetricSpace.Pseudo.Defs
import Mathlib.Topology.Continuous
import Mathlib.Topology.Compactness.Compact
import Mathlib.Topology.Order.Compact
import Mathlib.Topology.Order.IsLUB
import Mathlib.Topology.MetricSpace.Bounded
import Mathlib.Topology.Separation.Hausdorff
import Mathlib.Topology.Connected.Basic
import Mathlib.Topology.Instances.Real.Lemmas   -- ℝ 的拓扑实例（2026 起是目录模块）

open Topology

namespace Lean4Tutorial.Examples.MathlibTopology.Ch15

/-! # 15.1 拓扑空间 -/

#check @IsOpen
#check @interior
#check @closure
#check @frontier
#check @IsClosed
#check @𝓝

example [TopologicalSpace X] (s t : Set X) (hs : IsOpen s) (ht : IsOpen t) :
    IsOpen (s ∩ t) := hs.inter ht
example [TopologicalSpace X] : IsOpen (∅ : Set X) := isOpen_empty

/-! # 15.2 诱导与乘积拓扑 -/

example [TopologicalSpace X] [TopologicalSpace Y] : TopologicalSpace (X × Y) :=
  inferInstance

example [TopologicalSpace X] [TopologicalSpace Y] : Continuous (Prod.fst : X × Y → X) :=
  continuous_fst

example [TopologicalSpace X] (s : Set X) : TopologicalSpace s := inferInstance

/-! # 15.3 度量空间 -/

example [PseudoMetricSpace α] (x : α) : dist x x = 0 := dist_self x
example [PseudoMetricSpace α] (x y : α) : dist x y = dist y x := dist_comm x y
example [PseudoMetricSpace α] (x y z : α) : dist x z ≤ dist x y + dist y z :=
  dist_triangle x y z

#check Metric.ball
#check (inferInstance : MetricSpace ℝ)
#eval dist (1 : ℝ) 5

/-! # 15.4 连续映射 -/

example [TopologicalSpace X] [TopologicalSpace Y] {f : X → Y} :
    Continuous f ↔ ∀ s, IsOpen s → IsOpen (f ⁻¹' s) := continuous_def

example [TopologicalSpace X] [TopologicalSpace Y] {f : X → Y} {x : X} :
    ContinuousAt f x ↔ Filter.Tendsto f (𝓝 x) (𝓝 (f x)) := Iff.rfl

example [TopologicalSpace X] [TopologicalSpace Y] [TopologicalSpace Z]
    {g : Y → Z} {f : X → Y} (hg : Continuous g) (hf : Continuous f) :
    Continuous (g ∘ f) := hg.comp hf

/-! # 15.5 紧性 -/

example [TopologicalSpace X] [TopologicalSpace Y] {f : X → Y} {s : Set X}
    (hs : IsCompact s) (hf : Continuous f) : IsCompact (f '' s) := hs.image hf

-- 极值定理
example [TopologicalSpace X] {s : Set X} {f : X → ℝ}
    (hs : IsCompact s) (hne : s.Nonempty) (hf : ContinuousOn f s) :
    ∃ x ∈ s, IsMaxOn f s x := hs.exists_isMaxOn hne hf

example {f : X → ℝ} {s : Set X} {x : X} :
    IsMaxOn f s x ↔ ∀ y ∈ s, f y ≤ f x := isMaxOn_iff

/-! # 15.6 Heine–Borel -/

example {s : Set ℝ} : IsCompact s ↔ IsClosed s ∧ Bornology.IsBounded s :=
  Metric.isCompact_iff_isClosed_bounded

example (a b : ℝ) : IsCompact (Set.Icc a b) :=
  ConditionallyCompleteLinearOrder.isCompact_Icc a b

/-! # 15.7 分离公理与连通性 -/

example [TopologicalSpace X] [T2Space X] (x y : X) (h : x ≠ y) :
    ∃ u v : Set X, IsOpen u ∧ IsOpen v ∧ x ∈ u ∧ y ∈ v ∧ Disjoint u v :=
  t2_separation h

#check @IsPreconnected
#check @IsConnected

example (a b : ℝ) (h : a ≤ b) : IsConnected (Set.Icc a b) :=
  ⟨Set.nonempty_Icc.mpr h, isPreconnected_Icc⟩

end Lean4Tutorial.Examples.MathlibTopology.Ch15
