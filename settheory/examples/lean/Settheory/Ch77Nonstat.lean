import Mathlib.SetTheory.Cardinal.Cofinality.Club
import Mathlib.Tactic

open scoped Cardinal
open Cardinal Order Set

/-!
# 第 77 章 · 滤子、非荟萃集理想与广义无界闭子集（冯琦 §2.3）

钉版 mathlib（4.33.1）在 `Mathlib.SetTheory.Cardinal.Cofinality.Club`
里已经把 club / 平稳集开发成一套完整理论：`IsClub` 把「闭」拆成
`DirSupClosed`、把「无界」拆成 `IsCofinal`；`IsStationary` 定义为与每个
club 相交。本文件把正文 77.1–77.3 的定理逐条挂到官方锚点上，并显式记账
两处 mathlib 与冯琦定义的缝隙：`IsClub.nonempty` 需要 `Nonempty α`（否则
`α = PEmpty` 时 `∅` 也是 club，结论 `s.Nonempty` 会假），`isNormal_enum`
需要额外的 `WellFoundedLT α`（`IsRegularCardinalOrder` 只把它当参数、不自动
供给实例）。对角线交与 Fodor 引理 mathlib 没有，交给 Coq / Agda / Prolog /
Isabelle 通道分担。
-/

namespace Settheory.Ch77

universe u v

variable {α : Type v} [LinearOrder α] {s t : Set α}

/-- 定义 2.18 的成员资格：club 就是无界闭集。mathlib 的 `IsClub` 拆成
`DirSupClosed` + `IsCofinal` 两个字段；这里额外取出 `nonempty`（非空型上的
club 一定非空）作为「无界」的可读形态。注意 `IsClub.nonempty` 需要
`Nonempty α`：否则 `α = PEmpty` 时 `∅` 也满足 club 的两条而结论为假。 -/
theorem isClub_iff_unbounded_closed [Nonempty α] [WellFoundedLT α]
    (hs : IsClub s) : s.Nonempty ∧ IsCofinal s :=
  ⟨hs.nonempty, hs.isCofinal⟩

/-- 定理 2.23 的可数片段：`cof α ≠ ℵ₀` 时可数个 club 之交仍是 club。
mathlib 甚至有任意少于 `cof α` 个的版本 `IsClub.sInter`。 -/
theorem countable_inter_isClub [WellFoundedLT α] {f : ℕ → Set α}
    (hα : cof α ≠ ℵ₀) (hf : ∀ n, IsClub (f n)) : IsClub (⋂ n, f n) :=
  IsClub.iInter_of_countable hα hf

/-- 71 章定理 1.73 的官方形态：正规函数（单调连续）的像是 club。 -/
theorem club_range_of_isNormal [WellFoundedLT α] {f : α → α}
    (hf : IsNormal f) : IsClub (.range f) :=
  Order.IsNormal.isClub_range hf

/-- 77.6 节「事实」(3) 的官方形态：`cof α ≠ ℵ₀` 时正规函数的不动点集
是 club。 -/
theorem club_fixedPoints [WellFoundedLT α] {f : α → α}
    (hα : cof α ≠ ℵ₀) (hf : IsNormal f) : IsClub f.fixedPoints :=
  Order.IsNormal.isClub_fixedPoints hα hf

/-- 逆方向：club 集的枚举函数是正规函数——「C 是 club ⟺ C 是连续递增
函数的像」的 mathlib 形态（要求 α 是正则基数序，且 `<` 良基）。 -/
theorem isNormal_enum_of_isClub [WellFoundedLT α] [IsRegularCardinalOrder α] {s : Set α}
    (hs : IsClub s) : IsNormal (Subtype.val ∘ enum s hs.isCofinal) :=
  IsClub.isNormal_enum hs

/-- 定理 2.25 的对偶：club 是荟萃集。 -/
theorem club_isStationary [Nonempty α] [WellFoundedLT α]
    (hα : cof α ≠ ℵ₀) (hs : IsClub s) : IsStationary s :=
  IsClub.isStationary hα hs

/-- 非荟萃 = 被某个 club 躲开：定义 2.19 的对偶刻画。 -/
theorem not_isStationary_iff_disjoint (s : Set α) :
    ¬ IsStationary s ↔ ∃ t, IsClub t ∧ Disjoint s t :=
  not_isStationary_iff

/-- 推论 2.3(1) 的对偶：少于 `cof α` 个集合之并荟萃 ⟺ 有一个荟萃。
取补即「NS 是 κ-可加理想」。指标类型 `ι` 与底空间 `α` 可能住在不同
宇宙，故势的比较要经 `Cardinal.lift` 抬到同一宇宙——这正是 mathlib
`isStationary_iUnion_iff` 的记账方式。 -/
theorem isStationary_iUnion_iff' [WellFoundedLT α] {ι : Type u}
    {f : ι → Set α} (hα : cof α ≠ ℵ₀) (hι : lift.{v} #(ι) < lift.{u} (cof α)) :
    IsStationary (⋃ i, f i) ↔ ∃ i, IsStationary (f i) :=
  isStationary_iUnion_iff hα hι

end Settheory.Ch77
