/- ex28_mcalgo —— 模型检查算法与公平性（Lean 4 版，H&R §3.3.1 / §3.6.2）

   与 Coq 版同构：九态互斥模型（π₁π₂last 三元组）+ 安全性可达集
   不动点 + 饥饿路径（p2 自转）+ 公平性微观模型。Nat.beq 直连
   （10 章教训：== 不定义性归约）。 -/

namespace Ex28

/- ---------- 状态与迁移 ---------- -/

abbrev St := Nat × Nat × Nat   -- (p1, p2, last)

def p1 (s : St) : Nat := s.1
def p2 (s : St) : Nat := s.2.1
def lastm (s : St) : Nat := s.2.2

/-- t→c 守卫：对方在 c 则禁（H&R 图 3.7 的实际协议） -/
def move1 (s : St) : List St :=
  match p1 s with
  | 0 => [(1, p2 s, 0)]
  | 1 => if Nat.beq (p2 s) 2 then [] else [(2, p2 s, 0)]
  | _ => [(0, p2 s, 0)]

def move2 (s : St) : List St :=
  match p2 s with
  | 0 => [(p1 s, 1, 1)]
  | 1 => if Nat.beq (p1 s) 2 then [] else [(p1 s, 2, 1)]
  | _ => [(p1 s, 0, 1)]

def trans (s : St) : List St := move1 s ++ move2 s

/- ---------- 可达集不动点 ---------- -/

def eqSt (t s : St) : Bool :=
  Nat.beq (p1 t) (p1 s) && Nat.beq (p2 t) (p2 s) && Nat.beq (lastm t) (lastm s)

def memSt (S : List St) (s : St) : Bool := S.any (fun t => eqSt t s)

def closureStep (S : List St) : List St :=
  S ++ (S.flatMap trans).filter (fun s => !(memSt S s))

def reach : Nat → List St → List St
  | 0, S => S
  | k + 1, S =>
      let S' := closureStep S
      if Nat.beq S'.length S.length then S' else reach k S'

def bad (s : St) : Bool := Nat.beq (p1 s) 2 && Nat.beq (p2 s) 2

def agSafety (fuel : Nat) (s0 : St) : Bool :=
  (reach fuel [s0]).all (fun s => !(bad s))

example : agSafety 200 (0, 0, 2) = true := by native_decide

example : memSt (reach 200 [(0,0,2)]) (1, 1, 1) = true := by native_decide

/- ---------- 活性失败：饥饿路径 ---------- -/

/-- π₀ 的状态机：p2 自转（p1 卡 t） -/
def cyc : St → St
  | (_, 0, _) => (1, 1, 1)
  | (_, 1, _) => (1, 2, 1)
  | (_, _, _) => (1, 0, 1)

def starve : Nat → St
  | 0 => (1, 0, 2)
  | k + 1 => cyc (starve k)

theorem starve_p1 : ∀ n, p1 (starve n) = 1 := by
  intro n
  induction n with
  | zero => rfl
  | succ k _ =>
    show p1 (cyc (starve k)) = 1
    cases h : starve k with
    | mk a bl =>
      cases bl with | mk b l =>
      cases b with
      | zero => rfl
      | succ b' => cases b' with
        | zero => rfl
        | succ _ => rfl

theorem starve_last : ∀ n, lastm (starve (n + 1)) = 1 := by
  intro n
  show lastm (cyc (starve n)) = 1
  cases h : starve n with
  | mk a bl =>
    cases bl with | mk b l =>
    cases b with
    | zero => rfl
    | succ b' => cases b' with
      | zero => rfl
      | succ _ => rfl

theorem starve_step : ∀ n, starve (n + 1) ∈ trans (starve n) := by
  intro n
  generalize hs : starve n = s
  have hred : starve (n + 1) = cyc s := by rw [← hs]; rfl
  rw [hred]
  have h1 : p1 s = 1 := by rw [← hs]; exact starve_p1 n
  cases s with | mk a bl =>
  cases bl with | mk b l =>
  have h1' : a = 1 := h1
  subst a
  cases b with
  | zero => simp [cyc, trans, move1, move2, p1, p2]
  | succ b' =>
    cases b' with
    | zero => simp [cyc, trans, move1, move2, p1, p2]
    | succ b'' =>
      have hc : cyc (1, b'' + 2, l) = (1, 0, 1) := rfl
      rw [hc]
      apply List.mem_append_right
      simp [move2, p1, p2]

/-- c1 永不出现（活性失败的证据核心） -/
theorem starve_no_c1 : ∀ n, p1 (starve n) ≠ 2 := by
  intro n
  rw [starve_p1 n]
  decide

/- ---------- 公平性 ---------- -/

/-- 公平约束 F₁ = 「p1 动过」（last = 0） -/
def F1 (s : St) : Bool := Nat.beq (lastm s) 0

def fairPath (F : St → Bool) (π : Nat → St) : Prop :=
  ∀ i, ∃ j, i ≤ j ∧ F (π j) = true

/-- 饥饿路径不公平 -/
theorem starve_unfair : ¬ fairPath F1 starve := by
  intro h
  obtain ⟨j, _, hf⟩ := h 1
  have hl : lastm (starve j) ≠ 0 := by
    cases j with
    | zero => decide
    | succ j' =>
      have := starve_last j'
      show lastm (starve (j' + 1)) ≠ 0
      rw [this]; decide
  have : F1 (starve j) = true := hf
  unfold F1 at this
  rw [Nat.beq_eq] at this
  exact hl this

/- ---------- 公平性的微观模型（两状态） ---------- -/

def F2 (s : Bool) : Bool := s

def fairPathB (F : Bool → Bool) (π : Nat → Bool) : Prop :=
  ∀ i, ∃ j, i ≤ j ∧ F (π j) = true

/-- 不公平路径：永驻 a -/
theorem unfair_micro : ¬ fairPathB F2 (fun _ => false) := by
  intro h
  obtain ⟨j, _, hf⟩ := h 0
  exact Bool.noConfusion hf

/-- 公平路径：第一步进 b 后长住——F 无限经常 -/
theorem fair_micro : fairPathB F2 (fun n => !(Nat.beq n 0)) := by
  intro i
  cases i with
  | zero => exact ⟨1, by omega, rfl⟩
  | succ i' => exact ⟨i' + 1, by omega, rfl⟩

end Ex28
