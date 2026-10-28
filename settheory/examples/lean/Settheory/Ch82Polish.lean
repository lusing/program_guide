import Mathlib.Topology.MetricSpace.Perfect
import Mathlib.Topology.Baire.CompleteMetrizable
import Mathlib.Topology.Baire.Lemmas

/-!
# 第 82 章 · 贝尔空间、波兰空间、投影集与博弈

登记 mathlib 的波兰空间类与两条官方定理：康托尔-本狄克森分解、
不可数闭集的康托尔空间连续单射。贝尔空间 ℕ→ℕ 在 mathlib 中无现成
PolishSpace 实例，其距离 d(f,g)=2^{-Δ(f,g)} 的构造留在正文（命题 3.5）。
-/

namespace Settheory.Ch82

open Set

/-- 实数轴是波兰空间（定义 3.27、例 3.5）。 -/
example : PolishSpace ℝ := inferInstance

/-- 康托尔-本狄克森（定理 3.23 的拓扑内核）：第二可数空间中的闭集
分解为可数集与完备集之并。 -/
theorem cantor_bendixson {X : Type*} [TopologicalSpace X]
    [SecondCountableTopology X] {C : Set X} (hC : IsClosed C) :
    ∃ V D : Set X, V.Countable ∧ Perfect D ∧ C = V ∪ D :=
  exists_countable_union_perfect_of_isClosed hC

/-- 不可数闭集含非空完备子集（树求导引理 3.13 的官方形态）。 -/
theorem uncountable_closed_perfect {X : Type*} [TopologicalSpace X]
    [SecondCountableTopology X] {C : Set X}
    (hC : IsClosed C) (h : ¬ C.Countable) :
    ∃ D, Perfect D ∧ D.Nonempty ∧ D ⊆ C :=
  exists_perfect_nonempty_of_isClosed_of_not_countable hC h

/-- 不可数闭集上有从康托尔空间 ℕ→Bool 出发的连续单射，
于是 |C| ≥ 2^{ℵ₀}（定理 3.22 + 推论 3.7(2) 的机器版）。 -/
theorem cantor_injection {C : Set ℝ}
    (hC : IsClosed C) (h : ¬ C.Countable) :
    ∃ f : (ℕ → Bool) → ℝ, Set.range f ⊆ C ∧ Continuous f ∧
      Function.Injective f :=
  IsClosed.exists_nat_bool_injection_of_not_countable hC h

/-- 贝尔空间版贝尔纲（定理 3.25）在 ℝ 上的锚点（同第 81 章接口）。 -/
example {ι : Type*} [Countable ι] {U : ι → Set ℝ}
    (ho : ∀ i, IsOpen (U i)) (hd : ∀ i, Dense (U i)) :
    Dense (⋂ i, U i) :=
  dense_iInter_of_isOpen ho hd

end Settheory.Ch82
