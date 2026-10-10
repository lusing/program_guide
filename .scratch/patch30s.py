import io
p = 'examples/30_totalcorrect/ex30_totalcorrect.lean'
f = open(p, 'r', encoding='utf-8')
t = f.read()
f.close()

t = t.replace(r'''def countdownC (x y : Nat) : Cmd :=
  cwhile (fun s => (s x == 0) = false)
         (cseq (cass x (fun s => s x - 1)) (cass y (fun s => s y + 1)))''',
r'''def countdownC (x y : Nat) : Cmd :=
  cwhile (fun s => decide (s x ≠ 0))
         (cseq (cass x (fun s => s x - 1)) (cass y (fun s => s y + 1)))''')

t = t.replace(r'''  have hpos : ∀ s : State, s x + s y = C → (s x == 0) = false → 0 < s x := by
    intro s HP hb
    cases hx : s x with
    | zero =>
      rw [hx] at hb
      rw [show ((0 : Nat) == 0) = true from rfl] at hb
      simp at hb
    | succ v => omega''',
r'''  have hpos : ∀ s : State, s x + s y = C → decide (s x ≠ 0) = true → 0 < s x := by
    intro s HP hb
    rw [of_decide_eq_true] at hb
    cases hx : s x with
    | zero => rw [hx] at hb; simp at hb
    | succ v => omega''')

t = t.replace(r'''  have hbody : ∀ n, hoareT
      (fun s => s x + s y = C ∧ (s x == 0) = false ∧ s x = n)''',
r'''  have hbody : ∀ n, hoareT
      (fun s => s x + s y = C ∧ decide (s x ≠ 0) = true ∧ s x = n)''')

t = t.replace(r'''    intro n s ⟨HP, hb, hn⟩
    cases hx : s x with
    | zero =>
      rw [hx] at hb
      rw [show ((0 : Nat) == 0) = true from rfl] at hb
      simp at hb''',
r'''    intro n s ⟨HP, hb, hn⟩
    rw [of_decide_eq_true] at hb
    cases hx : s x with
    | zero => rw [hx] at hb; simp at hb''')

t = t.replace(r'''      (b := fun s => (s x == 0) = false)''',
r'''      (b := fun s => decide (s x ≠ 0))''')

t = t.replace(r'''  cases hsx : s₂ x with
  | zero => rfl
  | succ v =>
    rw [show ((v : Nat) + 1 == 0) = true from rfl] at hb
    simp at hb''',
r'''  cases hsx : s₂ x with
  | zero => rfl
  | succ v =>
    rw [show decide (((v : Nat) + 1) ≠ 0) = true from rfl] at hb
    simp at hb''')

f = open(p, 'w', encoding='utf-8')
f.write(t)
f.close()
print('ok')
