import io
p = 'examples/24_temporal/ex24_label.lean'
f = open(p, 'r', encoding='utf-8')
t = f.read()
f.close()

t = t.replace(r'''theorem memList_mem {S : List Nat} {s : Nat} : memList S s = true ↔ s ∈ S := by
  unfold memList; rw [List.any_eq_true]
  constructor
  · rintro ⟨x, hx, hxn⟩
    rw [beq_iff_eq] at hxn; rwa [hxn]
  · intro h; exact ⟨s, h, beq_iff_eq.mpr rfl⟩''', r'''theorem memList_mem {S : List Nat} {s : Nat} : memList S s = true ↔ s ∈ S := by
  unfold memList; rw [List.any_eq_true]
  constructor
  · rintro ⟨x, hx, hxn⟩
    rw [beq_iff_eq] at hxn; rw [← hxn]; exact hx
  · intro h; exact ⟨s, h, beq_iff_eq.mpr rfl⟩''')

t = t.replace(r'''    s ∈ satEX m S ↔ (∃ s', s' ∈ m.ftrans s ∧ s' ∈ S) := by
  constructor
  · intro h
    rw [List.mem_filter] at h
    obtain ⟨_, hany⟩ := h
    rw [List.any_eq_true] at hany
    obtain ⟨s', htr', hmem⟩ := hany
    exact ⟨s', htr', (memList_mem).mp hmem⟩
  · rintro ⟨s', htr', hmem⟩
    rw [List.mem_filter]
    refine ⟨htr _ s' htr', ?_⟩
    rw [List.any_eq_true]
    exact ⟨s', htr', memList_mem.mpr hmem⟩''', r'''    s ∈ satEX m S ↔ (∃ s', s' ∈ m.ftrans s ∧ s' ∈ S) := by
  simp only [satEX, List.mem_filter]
  constructor
  · intro h
    obtain ⟨_, hany⟩ := h
    rw [List.any_eq_true] at hany
    obtain ⟨s', htr', hmem⟩ := hany
    exact ⟨s', htr', memList_mem.mp hmem⟩
  · rintro ⟨s', htr', hmem⟩
    refine ⟨htr _ s' htr', ?_⟩
    rw [List.any_eq_true]
    exact ⟨s', htr', memList_mem.mpr hmem⟩''')

f = open(p, 'w', encoding='utf-8')
f.write(t)
f.close()
print('ok')
