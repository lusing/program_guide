import Mathlib.ModelTheory.Satisfiability

/-!
# 第 99 章 · 强紧基数

锚点：一阶逻辑紧致性定理的官方形态（isSatisfiable_iff_
isFinitelySatisfiable）。定理 1.26(3) 的强紧版本是 L_{κ,ω}
的紧致性——mathlib 无此设施；正文完整讲解。有限滤基扩展的
骨架在其余六通道。
-/

namespace Settheory.Ch99

open FirstOrder

/-- 一阶逻辑紧致性定理（定理 1.26(3) 在 κ=ω 处的官方形态）：
理论可满足当且仅当每个有限子理论可满足。 -/
example {L : Language} {T : L.Theory} :
    T.IsSatisfiable ↔ T.IsFinitelySatisfiable :=
  FirstOrder.Language.Theory.isSatisfiable_iff_isFinitelySatisfiable

/-- 可满足性对理论的放大单调（滤子向上封闭的影子）。 -/
example {L : Language} {T T' : L.Theory} (h : T'.IsSatisfiable)
    (hs : T ⊆ T') : T.IsSatisfiable :=
  FirstOrder.Language.Theory.IsSatisfiable.mono h hs

/-- 空理论可满足（滤子非空的影子）。 -/
example (L : Language) :
    FirstOrder.Language.Theory.IsSatisfiable (∅ : L.Theory) :=
  FirstOrder.Language.Theory.isSatisfiable_empty L

end Settheory.Ch99
