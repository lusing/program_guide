import Mathlib.SetTheory.Cardinal.Aleph
import Mathlib.SetTheory.Cardinal.Continuum
import Mathlib.Order.SuccPred.Limit

/-!
# 第 08 章 · 奇异基数：SCH、Silver 定理与几乎不交族

mathlib 的 beth 函数（ℶ_）与强极限基数概念是本章的官方锚点；
Silver 定理的证明链（几乎不交族 + 范数归纳）由计算通道承载。
-/

open scoped Cardinal

/-! ## 一、beth 阶梯：强极限的发动机 -/

-- beth 的严格递增与后继条款是官方锚点（GCH ⟺ ℶ_α = ℵ_α）。
example (o : Ordinal) : ℶ_ o < ℶ_ (o + 1) :=
  Cardinal.beth_lt_beth.2 (by simp)

-- 强极限基数的 beth 刻画（mathlib 官方，simp 引理）。
example (o : Ordinal) :
    Cardinal.IsStrongLimit (ℶ_ o) ↔ Order.IsSuccPrelimit o :=
  Cardinal.isStrongLimit_beth

/-! ## 二、奇异基数的形态 -/

/-- ℵ_ω 的构造形态：极限 aleph 是下方全体 aleph 的 sup。 -/
example (ho : Order.IsSuccLimit ω) : ℵ_ ω = ⨆ a : Set.Iio ω, ℵ_ a :=
  Cardinal.aleph_limit ho

-- ℵ_ω 是 {ℵ_n : n < ω} 的上界（cf ℵ_ω = ω 的奇异形态）；
-- mathlib 对 aleph 共尾性的官方计算暂缺，见讲义与计算通道。
