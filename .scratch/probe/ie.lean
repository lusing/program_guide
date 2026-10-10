example (P Q : Nat → Bool) (a : Nat) (l' : List Nat) :
    (l'.filter P).length + 1 = (l'.filter P).length + 1 := by omega
example (P Q : Nat → Bool) (a : Nat) (l' : List Nat)
    (ih : (l'.filter (fun x => P x || Q x)).length
        + (l'.filter (fun x => P x && Q x)).length
        = (l'.filter P).length + (l'.filter Q).length)
    (h : (a :: l'.filter (fun x => P x || Q x)).length
        + (l'.filter (fun x => P x && Q x)).length
        = (a :: l'.filter P).length + (l'.filter Q).length) : False := by
  simp only [List.length_cons] at *
  omega
