/- ex11 —— 直觉主义与 Glivenko 现象（Lean 4 版） -/

namespace Ex11

/-- 构件一：三重否定坍缩 -/
theorem n3 {A : Prop} (h : ¬¬¬A) : ¬A :=
  fun a => h (fun na => na a)

/-- 构件二：¬¬ 单调 -/
theorem nnMono {A B : Prop} (f : A → B) (ha : ¬¬A) : ¬¬B :=
  fun hb => ha (fun a => hb (f a))

theorem nnLem {A : Prop} : ¬¬(A ∨ ¬A) :=
  fun h => h (Or.inr (fun a => h (Or.inl a)))

theorem nnDne {A : Prop} : ¬¬(¬¬A → A) :=
  fun h => h (fun hnn => absurd (fun a => h (fun _ => a)) hnn)

theorem nnDemorgan {A B : Prop} (h : ¬(A ∧ B)) : ¬¬(¬A ∨ ¬B) :=
  fun hn =>
    (fun na => hn (Or.inl na))
      (fun a => (fun nb => hn (Or.inr nb)) (fun b => h ⟨a, b⟩))

#print axioms n3
#print axioms nnLem
#print axioms nnDne
#print axioms nnDemorgan

/- 坑位速记（Lean 侧）：
   - nnDne 用 absurd 直收：¬A := fun a => h (fun _ => a)，
     喂给 hnn : ¬¬A 得 False；
   - nnDemorgan 的点式嵌套就是 Coq 版 assert 链的 λ 化。 -/

end Ex11
