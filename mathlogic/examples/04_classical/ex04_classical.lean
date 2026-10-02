/- ex04 —— 经典加成（Lean 4 版）：矩阵零公理 + Classical 账单 -/

namespace Ex04

/- ---------- 矩阵（全部零公理） ---------- -/

theorem lemToDne (LEM : ∀ p : Prop, p ∨ ¬p) : ∀ p, ¬¬p → p := by
  intro p hnn
  cases LEM p with
  | inl hp => exact hp
  | inr hnp => exact absurd hnp hnn

theorem dneToLem (DNE : ∀ p : Prop, ¬¬p → p) : ∀ p, p ∨ ¬p :=
  fun p => DNE (p ∨ ¬p) (fun hnp => hnp (Or.inr (fun hp => hnp (Or.inl hp))))

theorem lemToPeirce (LEM : ∀ p : Prop, p ∨ ¬p) {p q : Prop}
    (h : (p → q) → p) : p := by
  cases LEM p with
  | inl hp => exact hp
  | inr hnp => exact absurd (h (fun hp => absurd hp hnp)) hnp

theorem peirceToDne (Peirce : ∀ p q : Prop, ((p → q) → p) → p) :
    ∀ p, ¬¬p → p :=
  fun p hnn => Peirce p False (fun hpq => absurd (fun hp => hpq hp) hnn)

theorem clavius (DNE : ∀ p : Prop, ¬¬p → p) {p : Prop} (h : ¬p → p) : p :=
  DNE p (fun hnp => hnp (h hnp))

#print axioms lemToDne
#print axioms dneToLem
#print axioms peirceToDne

/- ---------- 原理本体：Classical.em 是定理，账单随之 ---------- -/

theorem classicalDne {p : Prop} (h : ¬¬p) : p := by
  by_cases hp : p
  · exact hp
  · exact absurd hp h

theorem classicalDeMorganDual {p q : Prop} (h : ¬(p ∧ q)) : ¬p ∨ ¬q := by
  by_cases hp : p
  · by_cases hq : q
    · exact absurd ⟨hp, hq⟩ h
    · exact Or.inr hq
  · exact Or.inl hp

#print axioms classicalDne          -- Classical.choice, propext, Quot.sound
#print axioms classicalDeMorganDual

/- 坑位速记（Lean 侧）：
   - 矩阵定理的「原理参数」放第一名——Lean 的隐式 {p q} 在后面的参数里；
   - by_cases 一步做 LEM 分派（背后 Classical.em）；
   - absurd (x : a) (h : ¬a) : b 是矛盾出口的标准件。 -/

end Ex04
