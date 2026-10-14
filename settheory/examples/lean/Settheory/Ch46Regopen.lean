import Mathlib.Topology.Closure

/-!
# 第 46 章 · Viale 路线第一站：正则开集

Viale Ch2：`Reg(A) = interior (closure A)`，⊥ 运算五律中的
三条通用恒等式（De Morgan 并律、幂等律、双 ⊥ 回归律）。
mathlib 无 RegularOpen 文件——本文件自建定义（PLAN 第八篇锚点备忘）。
-/

namespace Settheory.Ch46

variable {X : Type*} [TopologicalSpace X]

/-- 正则开集：A 的正则化不动点（Viale Def 2.1.9 语境） -/
def IsRegularOpen (s : Set X) : Prop := interior (closure s) = s

/-! ## 一、De Morgan 并律（Viale Fact 2.1.10 (2)） -/

/-- (U ∪ V)⊥ = U⊥ ∩ V⊥：闭包并律 `closure_union` 之后
    `compl_union_eq_inter_compl`（De Morgan）即分配。 -/
theorem perp_union (U V : Set X) :
    (closure (U ∪ V))ᶜ = (closure U)ᶜ ∩ (closure V)ᶜ := by
  rw [closure_union, Set.compl_union]

/-! ## 二、幂等律（Viale Fact 2.1.10 (A)） -/

/-- 开 U 上 `closure (interior (closure U)) = closure U`。

    * `⊆`：interior ⊆ 全集 → closure 单调 → closure 幂等；
    * `⊇`：开 U ⊆ interior (closure U) → closure 单调。 -/
theorem closure_interior_closure (U : Set X) (hU : IsOpen U) :
    closure (interior (closure U)) = closure U := by
  apply le_antisymm
  · calc closure (interior (closure U))
        ≤ closure (closure U) := closure_mono interior_subset
      _ = closure U := closure_closure
  · have h2 : U ⊆ interior (closure U) :=
      calc U = interior U := (hU.interior_eq).symm
        _ ⊆ interior (closure U) := interior_mono subset_closure
    exact closure_mono h2

/-- Reg(Reg(U)) = Reg(U)：正则化是幂等算子，
    RO(X) 恰为其不动点集。 -/
theorem reg_reg (U : Set X) (hU : IsOpen U) :
    IsRegularOpen (interior (closure U)) := by
  unfold IsRegularOpen
  rw [closure_interior_closure U hU]

/-! ## 三、双 ⊥ 回归律（Viale Fact 2.1.10 (3)） -/

/-- U⊥⊥ = Reg(U)：`closure_compl`（closure 的余对偶）+ 双补即得。 -/
theorem perp_perp_eq_reg (U : Set X) :
    (closure ((closure U)ᶜ))ᶜ = interior (closure U) := by
  rw [closure_compl, compl_compl]

end Settheory.Ch46
