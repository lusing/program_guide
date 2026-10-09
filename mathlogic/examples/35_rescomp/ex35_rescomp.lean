/- ex41 —— 归结完备性与 SAT 难例（Ben-Ari 3e §4.4-4.5 + §6.2）Lean 镜像
   resproof 证明对象 + PHP(3,1) 两步反驳 + 枚举对照 + resolvent_sound。 -/

abbrev Lit := Bool × Nat        -- (true,p)=p  (false,p)=¬p
abbrev Clause := List Lit
abbrev Cnf := List Clause

def litSat (e : Nat → Bool) : Lit → Bool
  | (true, p) => e p
  | (false, p) => !e p

def clauseSat (e : Nat → Bool) (c : Clause) : Bool := c.any (litSat e)
def cnfSat (e : Nat → Bool) (S : Cnf) : Bool := S.all (clauseSat e)

def eqlL : Lit → Lit → Bool
  | (s1, p1), (s2, p2) => (if s1 then s2 else !s2) && (p1 == p2)

def removeLit (l : Lit) (c : Clause) : Clause :=
  c.filter (fun x => !(eqlL x l))

def oppl : Lit → Lit
  | (s, p) => (!s, p)

theorem eqlL_true : ∀ {l1 l2 : Lit}, eqlL l1 l2 = true → l1 = l2 := by
  intro l1 l2 h
  rcases l1 with ⟨s1, p1⟩ <;> rcases l2 with ⟨s2, p2⟩
  cases s1 <;> cases s2 <;> simp_all [eqlL]

def resolvent (l : Lit) (C1 C2 : Clause) : Clause :=
  removeLit l C1 ++ removeLit (oppl l) C2

/-- 归结式可靠性：满足两前提的赋值满足归结式 -/
theorem resolvent_sound (e : Nat → Bool) (l : Lit) (C1 C2 : Clause)
    (h1 : clauseSat e C1 = true) (h2 : clauseSat e C2 = true) :
    clauseSat e (resolvent l C1 C2) = true := by
  simp only [clauseSat, resolvent, removeLit, List.any_append] at h1 h2 ⊢
  rw [Bool.or_eq_true]
  rcases List.any_eq_true.mp h1 with ⟨x1, hin1, hs1⟩
  rcases List.any_eq_true.mp h2 with ⟨x2, hin2, hs2⟩
  cases E1 : eqlL x1 l <;> cases E2 : eqlL x2 (oppl l)
  · -- 都不是被消文字：x1 存活于 C1 段
    left
    apply List.any_eq_true.mpr
    have hx : x1 ∈ removeLit l C1 := by
      simp only [removeLit, List.mem_filter]
      exact ⟨hin1, by simp [E1]⟩
    exact ⟨x1, hx, hs1⟩
  · -- x2 = ¬l 被消：x1 存活于 C1 段
    left
    apply List.any_eq_true.mpr
    have hx : x1 ∈ removeLit l C1 := by
      simp only [removeLit, List.mem_filter]
      exact ⟨hin1, by simp [E1]⟩
    exact ⟨x1, hx, hs1⟩
  · -- x1 = l 被消：x2 存活于 C2 段
    right
    apply List.any_eq_true.mpr
    have hx : x2 ∈ removeLit (oppl l) C2 := by
      simp only [removeLit, List.mem_filter]
      exact ⟨hin2, by simp [E2]⟩
    exact ⟨x2, hx, hs2⟩
  · -- 见证文字对撞：矛盾
    exfalso
    have e1 : l = x1 := (eqlL_true E1).symm
    have e2 : oppl l = x2 := (eqlL_true E2).symm
    subst e1; subst e2
    rcases l with ⟨s, p⟩
    simp only [oppl, litSat] at hs1 hs2
    cases s <;> simp_all

/- ---------- 归结反驳证明对象 ---------- -/

inductive ResProof : Type where
  | leaf (c : Clause) : ResProof
  | res (r1 r2 : ResProof) (l : Lit) : ResProof

def concl : ResProof → Clause
  | .leaf c => c
  | .res r1 r2 l => resolvent l (concl r1) (concl r2)

def memL (c : Clause) (l : Lit) : Bool := c.any (eqlL l)

/-- 良构：每步两臂含被消文字的正负两侧 -/
def rp_wf : ResProof → Bool
  | .leaf _ => true
  | .res r1 r2 ⟨s, p⟩ =>
      rp_wf r1 && rp_wf r2 && memL (concl r1) (s, p) && memL (concl r2) (!s, p)

/- ---------- 鸽笼难例现场 ---------- -/

def pos (p : Nat) : Lit := (true, p)
def negp (p : Nat) : Lit := (false, p)

/-- PHP(2,2)（双鸽双洞）可满足——DP 消元正例 -/
def php22 : Cnf :=
  [[pos 0, pos 1], [pos 2, pos 3], [negp 0, negp 2], [negp 1, negp 3]]

/-- PHP(3,1)（三鸽一洞）不可满足——两步显式反驳 -/
def php31 : Cnf :=
  [[pos 0], [pos 1], [pos 2],
   [negp 0, negp 1], [negp 0, negp 2], [negp 1, negp 2]]

def php31_refute : ResProof :=
  .res (.res (.leaf [pos 2]) (.leaf [negp 0, negp 2]) (pos 2))
       (.leaf [pos 0]) (negp 0)

example : rp_wf php31_refute = true := by rfl
example : concl php31_refute = [] := by rfl

/- ---------- 枚举对照：短证书 vs 穷举 ---------- -/

def boolLists : Nat → List (List Bool)
  | 0 => [[]]
  | k + 1 => (boolLists k).map (true :: ·) ++ (boolLists k).map (false :: ·)

def envOf (bits : List Bool) (p : Nat) : Bool := bits.getD p false

def satByEnum (S : Cnf) (nvars : Nat) : Bool :=
  (boolLists nvars).any (fun bits => cnfSat (envOf bits) S)

example : satByEnum php22 4 = true := by rfl    -- 有模型（双鸽分居）
example : satByEnum php31 3 = false := by rfl   -- 8 赋值全败（反驳仅 2 步）

/- ---------- Davis-Putnam 变量消元一步（演示级） ---------- -/

def dpElim (p : Nat) (S : Cnf) : Cnf :=
  let posC := S.filter (fun c => memL c (true, p))
  let negC := S.filter (fun c => memL c (false, p))
  let news := posC.flatMap fun C1 =>
    negC.flatMap fun C2 => [resolvent (true, p) C1 C2]
  S.filter (fun c => !(memL c (true, p)) && !(memL c (false, p))) ++ news

example : dpElim 0 php22 = [[pos 2, pos 3], [negp 1, negp 3], [pos 1, negp 2]] := by
  rfl

#print axioms resolvent_sound
