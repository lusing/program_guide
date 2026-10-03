/- ex16 —— FOL 自然演绎（Lean 4 版）：量词规则与 Drinker 悖论 -/
namespace Ex16

open Classical

/-- (1) 量词 de Morgan 构造方向（零公理） -/
theorem allToNotExNot (P : Nat → Prop) (h : ∀ x, P x) :
    ¬ ∃ x, ¬ P x := by
  rintro ⟨x, hnx⟩
  exact absurd (h x) hnx

theorem exNotToNotAll (P : Nat → Prop) : (∃ x, ¬ P x) → ¬ ∀ x, P x := by
  rintro ⟨x, hnx⟩ hall
  exact absurd (hall x) hnx

/-- (2) Drinker 悖论（经典） -/
theorem drinker (P : Nat → Prop) :
    ∃ x, P x → ∀ y, P y := by
  by_cases hall : ∀ y, P y
  · exact ⟨0, fun _ y => hall y⟩
  · obtain ⟨x, hnx⟩ := not_forall.mp hall
    exact ⟨x, fun hpx => absurd hpx hnx⟩

/-- (3) Drinker 的 ¬¬ 版 -/
theorem drinkerNN (P : Nat → Prop) :
    ¬¬ (∃ x, P x → ∀ y, P y) := by
  intro h
  have hall : ∀ x, P x := by
    intro x
    by_cases hp : P x
    · exact hp
    · exact (h ⟨x, fun hpx => absurd hpx hp⟩).elim
  exact h ⟨0, fun _ => hall⟩

/-- 量词 de Morgan 完整版（经典） -/
theorem deMorganExists (P : Nat → Prop) :
    (∃ x, ¬ P x) ↔ ¬ ∀ x, P x := by
  constructor
  · exact exNotToNotAll P
  · intro hnall
    by_cases he : ∃ x, ¬ P x
    · exact he
    · exfalso
      refine hnall ?_
      intro x
      by_cases hp : P x
      · exact hp
      · exact absurd ⟨x, hp⟩ he

#print axioms allToNotExNot
#print axioms drinker
#print axioms drinkerNN

/- 坑位速记（Lean 侧）：
   - not_forall.mp 是经典拆解 ¬∀ 的标准件（背后 Classical.choice）；
   - rintro ⟨x, h⟩ 的匿名构造模式一步完成 ∃E；
   - drinker 的 HnAll 分支：不喝的人 x 使蕴含空真——前提假。 -/

end Ex16
