/-
文件: 12_mathlib_topology/topological_spaces.lean
描述: 拓扑空间，开集闭集，邻域
编译: lake build Lean4Tutorial.Examples.MathlibTopology.TopologicalSpaces
依赖: Mathlib.Topology.Basic
-/

import Mathlib.Topology.Basic
import Mathlib.Data.Real.Basic

namespace Lean4Tutorial.Examples.MathlibTopology.TopologicalSpaces

/-! # 拓扑空间（Topological Spaces） -/

-- 拓扑空间是具有"开集"结构的集合
-- 一个集合 X 上的拓扑是 X 的一族子集（称为开集），满足：
--   1. 空集和全集是开集
--   2. 任意多个开集的并是开集
--   3. 有限个开集的交是开集
--
-- 在 Mathlib 中，TopologicalSpace X 表示 X 上的拓扑结构

/-! ## 开集（Open Sets） -/

-- IsOpen s 表示集合 s 是开集
#check IsOpen

-- 空集是开集
#check isOpen_empty

-- 全集是开集
#check isOpen_univ

-- 开集的任意并是开集
#check isOpen_sUnion

-- 开集的有限交是开集
#check isOpen_inter

-- 开集的性质
section OpenSetExamples
  variable {X : Type*} [TopologicalSpace X]

  -- 两个开集的交是开集
  theorem open_inter {U V : Set X} (hU : IsOpen U) (hV : IsOpen V) : IsOpen (U ∩ V) := by
    exact IsOpen.inter hU hV

  -- 任意一族开集的并是开集
  theorem open_sUnion {S : Set (Set X)} (h : ∀ s ∈ S, IsOpen s) : IsOpen (⋃₀ S) := by
    exact isOpen_sUnion h

end OpenSetExamples

/-! ## 闭集（Closed Sets） -/

-- 闭集是开集的补集
-- IsClosed s 表示集合 s 是闭集
#check IsClosed

-- 闭集的等价定义：s 是闭集当且仅当 s 的补集是开集
theorem isClosed_iff_isOpen_compl {X : Type*} [TopologicalSpace X] {s : Set X} :
    IsClosed s ↔ IsOpen (sᶜ) := by
  exact isClosed_compl_iff

-- 空集是闭集
#check isClosed_empty

-- 全集是闭集
#check isClosed_univ

-- 闭集的任意交是闭集
#check isClosed_sInter

-- 闭集的有限并是闭集
#check isClosed_union

/-! ## 邻域（Neighborhoods） -/

-- 点 x 的邻域是包含 x 的某个开集的集合
-- 在 Mathlib 中，nhds x 表示点 x 的邻域滤子

#check nhds

-- 直观地说，U 是 x 的邻域，如果存在开集 V 使得 x ∈ V ⊆ U

-- 邻域的性质
section NeighborhoodExamples
  variable {X : Type*} [TopologicalSpace X] (x : X)

  -- 如果 U 是开集且 x ∈ U，则 U 是 x 的邻域
  theorem open_mem_nhds {U : Set X} (hU : IsOpen U) (hx : x ∈ U) : U ∈ nhds x := by
    exact IsOpen.mem_nhds hU hx

  -- x 的邻域一定包含 x
  -- （邻域滤子中的每个集合都包含 x）

end NeighborhoodExamples

/-! ## 内部、闭包、边界 -/

-- 集合 s 的内部（interior）：包含于 s 的最大开集
-- 记作 interior s

-- 集合 s 的闭包（closure）：包含 s 的最小闭集
-- 记作 closure s

-- 集合 s 的边界（frontier）：闭包减去内部
-- 记作 frontier s

#check interior
#check closure
#check frontier

-- 内部的性质
section InteriorExamples
  variable {X : Type*} [TopologicalSpace X] {s t : Set X}

  -- 内部是开集
  theorem isOpen_interior : IsOpen (interior s) := by
    exact isOpen_interior

  -- 内部包含于原集合
  theorem interior_subset : interior s ⊆ s := by
    exact interior_subset

  -- s 是开集当且仅当 interior s = s
  theorem isOpen_iff_interior_eq : IsOpen s ↔ interior s = s := by
    exact isOpen_iff_interior_eq

end InteriorExamples

-- 闭包的性质
section ClosureExamples
  variable {X : Type*} [TopologicalSpace X] {s t : Set X}

  -- 闭包是闭集
  theorem isClosed_closure : IsClosed (closure s) := by
    exact isClosed_closure

  -- 原集合包含于闭包
  theorem subset_closure : s ⊆ closure s := by
    exact subset_closure

  -- s 是闭集当且仅当 closure s = s
  theorem isClosed_iff_closure_eq : IsClosed s ↔ closure s = s := by
    exact isClosed_iff_closure_eq

end ClosureExamples

/-! ## 连续函数（拓扑意义下） -/

-- 函数 f : X → Y 连续，当且仅当
-- Y 中每个开集的原像都是 X 中的开集

-- 这是连续性的拓扑定义，与 ε-δ 定义等价（在度量空间中）

#check Continuous

-- 连续函数的等价刻画：
-- 1. 开集的原像是开集
-- 2. 闭集的原像是闭集
-- 3. f(closure(A)) ⊆ closure(f(A))
-- 4. 对每个 x，f 将 x 的邻域映到 f(x) 的邻域

/-! ## 常见的拓扑 -/

-- 1. 离散拓扑（Discrete Topology）
--    所有子集都是开集
--    这是最细的拓扑

-- 2. 平凡拓扑（Trivial/Indiscrete Topology）
--    只有空集和全集是开集
--    这是最粗的拓扑

-- 3. 欧氏拓扑（Euclidean Topology）
--    实数集上的通常拓扑，由开区间生成

-- 4. 子空间拓扑（Subspace Topology）
--    拓扑空间的子集上诱导的拓扑

-- 5. 乘积拓扑（Product Topology）
--    两个拓扑空间的笛卡尔积上的拓扑

-- 6. 商拓扑（Quotient Topology）
--    由等价关系诱导的拓扑

/-! ## 分离公理 -/

-- T₀（Kolmogorov）：任意两个不同的点，至少有一个点有不包含另一个点的邻域
-- T₁（Fréchet）：任意两个不同的点，每个点都有不包含另一个点的邻域
-- T₂（Hausdorff）：任意两个不同的点，有不相交的邻域
-- T₃（Regular）：T₂ + 闭集和其外一点有不相交的邻域
-- T₄（Normal）：T₂ + 两个不相交的闭集有不相交的邻域

-- Hausdorff 空间是最常用的分离性条件
-- 在 Hausdorff 空间中，收敛序列的极限唯一

#check T2Space

/-! ## 实数上的欧氏拓扑 -/

-- 实数集 ℝ 上的标准拓扑由开区间生成
-- 开集是任意多个开区间的并

-- 在这个拓扑下：
--   开区间 (a, b) 是开集
--   闭区间 [a, b] 是闭集
--   半开区间 [a, b) 既不是开集也不是闭集

end Lean4Tutorial.Examples.MathlibTopology.TopologicalSpaces
