/- ex20 —— Herbrand 与 SLD 构件（Lean 4 版）：T_P 单调与头原子 -/
namespace Ex20

inductive HClause where
  | hfact (a : Nat) : HClause
  | hrule (a : Nat) (body : List Nat) : HClause

open HClause

abbrev HProg := List HClause
abbrev Inter := Nat → Bool

/-- T_P 算子：直接结论 -/
def TP (P : HProg) (I : Inter) : Inter :=
  fun a => P.any fun c =>
    match c with
    | hfact b => b == a
    | hrule b body => (b == a) && body.all I

/-- 旗舰一：T_P 单调 -/
theorem TPMono (P : HProg) (I J : Inter)
    (hsub : ∀ a, I a = true → J a = true) :
    ∀ a, TP P I a = true → TP P J a = true := by
  intro a h
  simp only [TP, List.any_eq_true] at h ⊢
  obtain ⟨c, hc, hval⟩ := h
  refine ⟨c, hc, ?_⟩
  cases c with
  | hfact b => exact hval
  | hrule b body =>
      rw [Bool.and_eq_true] at hval ⊢
      obtain ⟨hab, hbody⟩ := hval
      exact ⟨hab, by
        simp only [List.all_eq_true] at hbody ⊢
        intro x hx
        exact hsub x (hbody x hx)⟩

/-- 旗舰二：事实头 -/
theorem factHead (P : HProg) (a : Nat) (hin : hfact a ∈ P) :
    TP P (fun _ => false) a = true := by
  simp only [TP, List.any_eq_true]
  exact ⟨hfact a, hin, by simp⟩

/-- 旗舰三：规则头 -/
theorem ruleHead (P : HProg) (a : Nat) (body : List Nat) (I : Inter)
    (hin : hrule a body ∈ P) (hbody : body.all I = true) :
    TP P I a = true := by
  simp only [TP, List.any_eq_true]
  refine ⟨hrule a body, hin, ?_⟩
  rw [Bool.and_eq_true]
  exact ⟨by simp, hbody⟩

/-- 现场演示 -/
example : TP [hfact 0, hrule 1 [0]] (fun a => a == 0) 1 = true := by
  apply ruleHead (P := [hfact 0, hrule 1 [0]]) (a := 1) (body := [0])
    (I := fun a => a == 0)
  · simp
  · simp only [List.all_cons, List.all_nil]
    simp

end Ex20
