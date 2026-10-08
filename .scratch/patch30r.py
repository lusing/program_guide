import io
p = 'examples/30_totalcorrect/ex30_totalcorrect.lean'
f = open(p, 'r', encoding='utf-8')
t = f.read()
f.close()
t = t.replace(r'''        have hxr : upd s x (s x - 1) x = s x - 1 := by
          simp only [upd]; rw [if_pos rfl]
        have hyr : upd s x (s x - 1) y = s y := by
          simp only [upd]
          rw [if_neg (fun h => hxy h.symm)]
        have hxf : upd (upd s x (s x - 1)) y
                     (upd s x (s x - 1) y + 1) x = s x - 1 := by
          simp only [upd]
          rw [if_pos rfl, if_neg (fun h => hxy h)]
        have hyf : upd (upd s x (s x - 1)) y
                     (upd s x (s x - 1) y + 1) y = s y + 1 := by
          simp only [upd]
          rw [if_pos rfl, hyr]
        omega''', r'''        have hxr : upd s x (s x - 1) x = s x - 1 := by simp [upd]
        have hyr : upd s x (s x - 1) y = s y := by
          have hyx : y ≠ x := fun h => hxy h.symm
          simp [upd, hyx]
        have hxf : upd (upd s x (s x - 1)) y
                     (upd s x (s x - 1) y + 1) x = s x - 1 := by
          simp [upd]
        have hyf : upd (upd s x (s x - 1)) y
                     (upd s x (s x - 1) y + 1) y = s y + 1 := by
          simp [upd, hyr]
        omega''')
t = t.replace(r'''      · -- 变体严格下降
        have hxf : upd (upd s x (s x - 1)) y
                     (upd s x (s x - 1) y + 1) x = s x - 1 := by
          simp only [upd]
          rw [if_pos rfl, if_neg (fun h => hxy h)]
        omega''', r'''      · -- 变体严格下降
        have hxf : upd (upd s x (s x - 1)) y
                     (upd s x (s x - 1) y + 1) x = s x - 1 := by
          simp [upd]
        omega''')
f = open(p, 'w', encoding='utf-8')
f.write(t)
f.close()
print('ok')
