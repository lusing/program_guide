/-
文件: 12_mathlib_topology/compactness.lean
描述: 紧性，海涅-博雷尔定理
编译: lake build Lean4Tutorial.Examples.MathlibTopology.Compactness
依赖: Mathlib.Topology.Compact.Basic
-/

import Mathlib.Topology.Compact.Basic
import Mathlib.Data.Real.Basic

namespace Lean4Tutorial.Examples.MathlibTopology.Compactness

/-! # 紧性（Compactness） -/

-- 紧性是拓扑学中的重要概念
-- 直观上说，紧集是"有限大小"的集合
-- 紧集上的连续函数有很多好的性质

/-! ## 紧集的定义 -/

-- 集合 K 是紧的，如果它的每个开覆盖都有有限子覆盖
--
-- 开覆盖：一族开集 {U_i}_{i∈I}，满足 K ⊆ ⋃ U_i
-- 有限子覆盖：存在有限个 U_i 仍然覆盖 K
--
-- 在 Mathlib 中，IsCompact K 表示 K 是紧集

#check IsCompact

/-! ## 紧集的基本性质 -/

variable {X : Type*} [TopologicalSpace X]

-- 有限集是紧的
theorem isCompact_finite (s : Set X) (h : Set.Finite s) : IsCompact s := by
  exact Set.Finite.isCompact h

-- 紧集的闭子集是紧的
theorem isCompact_of_isClosed_subset {K F : Set X}
    (hK : IsCompact K) (hF : IsClosed F) (h : F ⊆ K) : IsCompact F := by
  exact IsCompact.of_isClosed_subset hK hF h

-- 紧集在 Hausdorff 空间中是闭的
theorem isClosed_of_isCompact [T2Space X] {K : Set X} (hK : IsCompact K) :
    IsClosed K := by
  exact IsCompact.isClosed hK

/-! ## 紧集与连续函数 -/

-- 紧集在连续映射下的像仍是紧集
theorem image_isCompact {Y : Type*} [TopologicalSpace Y] {f : X → Y}
    (hf : Continuous f) {K : Set X} (hK : IsCompact K) :
    IsCompact (f '' K) := by
  exact IsCompact.image hK hf

-- 极值定理：紧集上的实值连续函数取得最大值和最小值
-- 这是分析中的重要定理

/-! ## 序列紧性 -/

-- 集合 K 是序列紧的，如果 K 中的每个序列都有收敛子列，
-- 且极限在 K 中

-- 在度量空间中，紧性等价于序列紧性
-- 这是波尔查诺-魏尔斯特拉斯定理的推广

/-! ## 有限交性质 -/

-- 紧性的另一种刻画：有限交性质
--
-- 如果一族闭集的任意有限个的交非空，
-- 则整族闭集的交非空

-- 这与开覆盖定义是对偶的

/-! # 海涅-博雷尔定理（Heine-Borel Theorem） -/

-- 海涅-博雷尔定理：
-- 在 ℝⁿ 中，集合是紧的当且仅当它是有界闭集
--
-- 这是欧氏空间中紧集的重要刻画

-- 实数中的情况：
-- 闭区间 [a, b] 是紧的
-- 这是实数完备性的推论

/-! ## 海涅-博雷尔定理的推论 -/

-- 波尔查诺-魏尔斯特拉斯定理：
-- 有界数列必有收敛子列

-- 极值定理：
-- 有界闭区间上的连续函数取得最大值和最小值

-- 一致连续性定理：
-- 有界闭区间上的连续函数一致连续

/-! ## 紧性的应用 -/

-- 1. 极值问题
--    紧集上的连续函数一定能取到最大值和最小值

-- 2. 微分方程
--    紧性是证明解存在性的重要工具

-- 3. 泛函分析
--    弱紧性、弱*紧性（Alaoglu 定理）

-- 4. 代数拓扑
--    紧支撑上同调、紧开拓扑

/-! ## 局部紧性 -/

-- 拓扑空间是局部紧的，如果每一点都有一个紧邻域
-- ℝⁿ 是局部紧的（但不是紧的）

-- 局部紧 Hausdorff 空间有很多好性质
-- 例如可以做一点紧化（Alexandroff 紧化）

/-! ## 紧化 -/

-- 紧化是将一个拓扑空间嵌入紧空间的过程
-- 常见的紧化：
--   1. 一点紧化（Alexandroff）：添加一个"无穷远点"
--   2. Stone-Čech 紧化：万有紧化

-- 例如：实数的一点紧化同胚于圆周 S¹

/-! ## 各种紧性概念的关系 -/

-- 在一般拓扑空间中：
--   紧 ⇒ 序列紧  （不一定成立）
--   序列紧 ⇒ 紧  （不一定成立）
--
-- 在度量空间中：
--   紧 ⇔ 序列紧 ⇔ 完全有界 + 完备

-- 在 ℝⁿ 中：
--   紧 ⇔ 有界闭 ⇔ 序列紧

end Lean4Tutorial.Examples.MathlibTopology.Compactness
