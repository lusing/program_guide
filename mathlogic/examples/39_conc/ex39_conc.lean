/- ex39 —— 并发程序演绎验证（Ben-Ari 3e §16.1-16.3）Lean 镜像
   交错语义 + 全局不变式（互斥 + 两条辅助：临界者持有轮牌）。
   inv_preserved 六条原子步逐一核对；reach_inv_gen 可达性封口。 -/

structure St where
  pc1 : Nat      -- 进程 1 位置：0=空闲 1=请求 2=临界
  pc2 : Nat
  turn : Nat     -- 轮到谁
  deriving Repr, BEq

def init : St := ⟨0, 0, 1⟩

/- ---------- 六条原子步 ---------- -/

def tryReq1 (s : St) : Option St :=
  if s.pc1 == 0 then some { s with pc1 := 1 } else none

def tryEnter1 (s : St) : Option St :=
  if (s.pc1 == 1) && (s.turn == 1) then some { s with pc1 := 2 } else none

def tryExit1 (s : St) : Option St :=
  if s.pc1 == 2 then some ⟨0, s.pc2, 2⟩ else none

def tryReq2 (s : St) : Option St :=
  if s.pc2 == 0 then some { s with pc2 := 1 } else none

def tryEnter2 (s : St) : Option St :=
  if (s.pc2 == 1) && (s.turn == 2) then some { s with pc2 := 2 } else none

def tryExit2 (s : St) : Option St :=
  if s.pc2 == 2 then some ⟨s.pc1, 0, 1⟩ else none

def asteps : List (St → Option St) :=
  [tryReq1, tryEnter1, tryExit1, tryReq2, tryEnter2, tryExit2]

/- ---------- 不变式 ---------- -/

def inv (s : St) : Prop :=
  ¬ (s.pc1 = 2 ∧ s.pc2 = 2)
  ∧ (s.pc1 = 2 → s.turn = 1)
  ∧ (s.pc2 = 2 → s.turn = 2)

theorem inv_init : inv init := by
  refine ⟨?_, ?_, ?_⟩
  · intro h; exact absurd h.1 (by simp [init])
  · intro h; simp [init] at h
  · intro h; simp [init] at h

theorem inv_preserved (f : St → Option St) (s s' : St)
    (hin : f ∈ asteps) (hstep : f s = some s') (hinv : inv s) : inv s' := by
  obtain ⟨hm, ha, hb⟩ := hinv
  simp only [asteps, List.mem_cons, List.not_mem_nil, or_false] at hin
  rcases hin with rfl | rfl | rfl | rfl | rfl | rfl
  · -- tryReq1
    simp only [tryReq1] at hstep
    split at hstep
    · injection hstep with h2; subst h2
      refine ⟨?_, ?_, ?_⟩
      · intro ⟨h1, _⟩; simp at h1
      · intro h; simp at h
      · intro h; exact hb h
    · exact absurd hstep (by simp)
  · -- tryEnter1
    simp only [tryEnter1] at hstep
    split at hstep
    · injection hstep with h2; subst h2
      rename_i hg
      simp only [Bool.and_eq_true, beq_iff_eq] at hg
      obtain ⟨e1, e2⟩ := hg
      refine ⟨?_, ?_, ?_⟩
      · intro ⟨h1, h2⟩
        have := hb h2
        omega
      · intro _; omega
      · intro h; exact hb h
    · exact absurd hstep (by simp)
  · -- tryExit1
    simp only [tryExit1] at hstep
    split at hstep
    · injection hstep with h2; subst h2
      refine ⟨?_, ?_, ?_⟩
      · intro ⟨h1, _⟩; simp at h1
      · intro h; simp at h
      · intro _; rfl
    · exact absurd hstep (by simp)
  · -- tryReq2
    simp only [tryReq2] at hstep
    split at hstep
    · injection hstep with h2; subst h2
      refine ⟨?_, ?_, ?_⟩
      · intro ⟨_, h2⟩; simp at h2
      · intro h; exact ha h
      · intro h; simp at h
    · exact absurd hstep (by simp)
  · -- tryEnter2
    simp only [tryEnter2] at hstep
    split at hstep
    · injection hstep with h2; subst h2
      rename_i hg
      simp only [Bool.and_eq_true, beq_iff_eq] at hg
      obtain ⟨e1, e2⟩ := hg
      refine ⟨?_, ?_, ?_⟩
      · intro ⟨h1, h2⟩
        have := ha h1
        omega
      · intro h; exact ha h
      · intro _; omega
    · exact absurd hstep (by simp)
  · -- tryExit2
    simp only [tryExit2] at hstep
    split at hstep
    · injection hstep with h2; subst h2
      refine ⟨?_, ?_, ?_⟩
      · intro ⟨_, h2⟩; simp at h2
      · intro _; rfl
      · intro h; simp at h
    · exact absurd hstep (by simp)

/- ---------- 可达性封口 ---------- -/

def reachSet : Nat → St → List St
  | 0, s0 => [s0]
  | k + 1, s0 =>
      s0 :: asteps.flatMap (fun f =>
        match f s0 with
        | some s1 => reachSet k s1
        | none => [])

theorem reach_inv_gen : ∀ (fuel : Nat) (s0 s : St),
    s ∈ reachSet fuel s0 → inv s0 → inv s := by
  intro fuel
  induction fuel with
  | zero =>
    intro s0 s hin hs0
    simp only [reachSet] at hin
    cases hin with
    | head => exact hs0
    | tail _ h => exact absurd h List.not_mem_nil
  | succ fuel ih =>
    intro s0 s hin hs0
    cases hin with
    | head => exact hs0
    | tail _ hin =>
      obtain ⟨f, hf, hout⟩ := List.mem_flatMap.mp hin
      cases hfs : f s0 with
      | some s1 =>
        have hmem : s ∈ reachSet fuel s1 := by
          rw [hfs] at hout
          exact hout
        exact ih s1 s hmem (inv_preserved f s0 s1 hf hfs hs0)
      | none =>
        rw [hfs] at hout
        exact absurd hout (by simp)

/-- 可达性封口：一切从初始出发可达的状态满足不变式 -/
theorem reach_inv (fuel : Nat) (s : St)
    (hin : s ∈ reachSet fuel init) : inv s :=
  reach_inv_gen fuel init s hin inv_init

/-- 临界可达：进程 1 独自进入临界区 -/
example : (reachSet 3 init).contains ⟨2, 0, 1⟩ = true := by
  decide

/-- 双临界不可达：互斥成立 -/
theorem mutual_exclusion (fuel : Nat) :
    ¬ (⟨2, 2, 1⟩ : St) ∈ reachSet fuel init := by
  intro hin
  obtain ⟨hm, _, _⟩ := reach_inv fuel _ hin
  exact hm ⟨rfl, rfl⟩

#print axioms inv_preserved
#print axioms mutual_exclusion
