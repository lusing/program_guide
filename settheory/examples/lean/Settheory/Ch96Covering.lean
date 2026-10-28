import Mathlib.SetTheory.Cardinal.Basic
import Mathlib.SetTheory.Cardinal.Regular

/-!
# 第 96 章 · Jensen 覆盖引理

登记两条官方锚点：并集计数不等式（推论 1.8(3) 的 |A| ≤ κ⁺ 账的
骨架）与共尾度正则性（事实 1.1.1(iii) 的骨架）。覆盖引理本体是关于
L 层级的超穷归纳，不在机器范围内。
-/

namespace Settheory.Ch96

open scoped Cardinal

/-- 推论 1.8(3) 的计数骨架：并集的势 ≤ 指标势 × 片势上确界。
覆盖引理把 [κ]^cf(κ) 的每个元素塞进一个 L-小片后，正是这条不等式
给出 κ^cf(κ) ≤ κ⁺（SCH）。 -/
theorem union_bound {α ι : Type u} (f : ι → Set α) :
    #(⋃ i, f i) ≤ #ι * ⨆ i, #(f i) :=
  Cardinal.mk_iUnion_le f

/-- 事实 1.1.1(iii) 的骨架：任何后继极限序数的共尾度是正则基数
（ν = |X| · cf(τ) 中的 cf(τ) 取正则）。 -/
example (o : Ordinal) (h : Order.IsSuccLimit o) : (o.cof).IsRegular :=
  Cardinal.isRegular_cof h

/-- 正则基数等于自身的共尾度（推论 1.8(1) 中
「cf(λ) = |λ|」的形式）。 -/
example (c : Cardinal) (h : c.IsRegular) : c.ord.cof = c :=
  h.cof_ord

end Settheory.Ch96
