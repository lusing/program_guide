/- ex30_totalcorrect —— 完全正确性（Lean 4 版，H&R §4.4 / §4.3.3）

   与 Coq 版同构：hoareT（终止内建）+ hoareT_while_layered
   （total-while 的分层形态：变体参数化 n）+ countdown_total +
   minsum 的 amin 吸收律构件。 -/
namespace Ex30

abbrev State := Nat → Nat

def upd (s : State) (x v : Nat) : State :=
  fun m => if m = x then v else s m

inductive Cmd where
  | cskip : Cmd
  | cass (x : Nat) (f : State → Nat) : Cmd
  | cseq (c₁ c₂ : Cmd) : Cmd
  | cwhile (b : State → Bool) (c : Cmd) : Cmd

open Cmd

inductive Exec : Cmd → State → State → Prop
  | skip (s) : Exec .cskip s s
  | ass (x) (f) (s) : Exec (cass x f) s (upd s x (f s))
  | seq {c₁ c₂ s₁ s₂ s₃} : Exec c₁ s₁ s₂ → Exec c₂ s₂ s₃ →
      Exec (cseq c₁ c₂) s₁ s₃
  | whileT {b c s₁ s₂ s₃} : b s₁ = true → Exec c s₁ s₂ →
      Exec (cwhile b c) s₂ s₃ → Exec (cwhile b c) s₁ s₃
  | whileF {b c s} : b s = false → Exec (cwhile b c) s s

/-- 完全正确性：终止内建（存在终态且满足后件） -/
def hoareT (P : State → Prop) (c : Cmd) (Q : State → Prop) : Prop :=
  ∀ s₁, P s₁ → ∃ s₂, Exec c s₁ s₂ ∧ Q s₂

/-- 旗舰：total-while（变体版，H&R 式 4.15 的分层形态）。

    体前提参数化 n（本轮变体初值——逻辑变量冻结），后件 V < n：
    每轮严格降；对变体上界强归纳收终止。 -/
theorem hoareT_while_layered {P : State → Prop} {b : State → Bool}
    {c : Cmd} {V : State → Nat}
    (hpos : ∀ s, P s → b s = true → 0 < V s)
    (hbody : ∀ n, hoareT (fun s => P s ∧ b s = true ∧ V s = n)
                      c (fun s => P s ∧ V s < n)) :
    hoareT P (cwhile b c) (fun s => P s ∧ b s = false) := by
  have hmain : ∀ n s₁, P s₁ → V s₁ ≤ n →
      ∃ s₂, Exec (cwhile b c) s₁ s₂ ∧ P s₂ ∧ b s₂ = false := by
    intro n
    induction n with
    | zero =>
      intro s₁ HP HV
      cases hb : b s₁ with
      | true =>
        have hv := hpos s₁ HP hb
        have h0 : V s₁ = 0 := Nat.le_zero.mp HV
        omega
      | false =>
        exact ⟨s₁, Exec.whileF hb, HP, hb⟩
    | succ n ih =>
      intro s₁ HP HV
      cases hb : b s₁ with
      | true =>
        obtain ⟨s₂, hex, HP₂, HV₂⟩ :=
          hbody (V s₁) s₁ ⟨HP, hb, rfl⟩
        obtain ⟨s₃, hex₂, HP₃, hb₃⟩ := ih s₂ HP₂ (by omega)
        exact ⟨s₃, Exec.whileT hb hex hex₂, HP₃, hb₃⟩
      | false =>
        exact ⟨s₁, Exec.whileF hb, HP, hb⟩
  intro s₁ HP
  exact hmain (V s₁) s₁ HP (Nat.le_refl _)

/-- countdown 的完全正确性（变体 = s x；不变式 = s x + s y = C） -/

def countdownC (x y : Nat) : Cmd :=
  cwhile (fun s => decide (s x ≠ 0))
         (cseq (cass x (fun s => s x - 1)) (cass y (fun s => s y + 1)))

theorem countdown_total {x y C : Nat} {s₁ : State}
    (hxy : x ≠ y) (hinv : s₁ x + s₁ y = C) :
    ∃ s₂, Exec (countdownC x y) s₁ s₂ ∧ s₂ x + s₂ y = C ∧ s₂ x = 0 := by
  have hpos : ∀ s : State, s x + s y = C → decide (s x ≠ 0) = true → 0 < s x := by
    intro s HP hb
    have hb2 : s x ≠ 0 := of_decide_eq_true hb
    cases hx : s x with
    | zero => rw [hx] at hb2; simp at hb2
    | succ v => omega
  have hbody : ∀ n, hoareT
      (fun s => s x + s y = C ∧ decide (s x ≠ 0) = true ∧ s x = n)
      (cseq (cass x (fun s => s x - 1)) (cass y (fun s => s y + 1)))
      (fun s => s x + s y = C ∧ s x < n) := by
    intro n s ⟨HP, hb, hn⟩
    have hb2 : s x ≠ 0 := of_decide_eq_true hb
    cases hx : s x with
    | zero => rw [hx] at hb2; simp at hb2
    | succ v =>
      -- 终态：先赋 x；y 的函数在 x 更新后的状态上读
      refine ⟨upd (upd s x (s x - 1)) y (upd s x (s x - 1) y + 1),
              ?_, ?_, ?_⟩
      · exact Exec.seq (Exec.ass ..) (Exec.ass ..)
      · -- 不变式：x-1 与 y+1 守恒（x≠y 防别名）
        have hyx : y ≠ x := fun h => hxy h.symm
        have hxr : upd s x (s x - 1) x = s x - 1 := by simp [upd]
        have hyr : upd s x (s x - 1) y = s y := by simp [upd, hyx]
        have hxf : upd (upd s x (s x - 1)) y
                     (upd s x (s x - 1) y + 1) x = s x - 1 := by
          simp [upd, hxy]
        have hyf : upd (upd s x (s x - 1)) y
                     (upd s x (s x - 1) y + 1) y = s y + 1 := by
          have e1 : ∀ (s' : State) (v : Nat), upd s' y v y = v := by
            intro s' v; simp [upd]
          rw [e1, hyr]
        omega
      · -- 变体严格下降
        have hyx : y ≠ x := fun h => hxy h.symm
        have hxf : upd (upd s x (s x - 1)) y
                     (upd s x (s x - 1) y + 1) x = s x - 1 := by
          simp [upd, hxy]
        omega
  obtain ⟨s₂, hex, HP₂, hb⟩ :=
    hoareT_while_layered (P := fun s => s x + s y = C)
      (b := fun s => decide (s x ≠ 0))
      (c := cseq (cass x (fun s => s x - 1)) (cass y (fun s => s y + 1)))
      (V := fun s => s x) hpos hbody s₁ hinv
  refine ⟨s₂, hex, HP₂, ?_⟩
  cases hsx : s₂ x with
  | zero => rfl
  | succ v =>
    rw [hsx] at hb
    rw [show decide (((v : Nat) + 1) ≠ 0) = true from rfl] at hb
    simp at hb

/-- minsum 构件：Kadane 最小化的 min 吸收律（H&R §4.3.3 教学版） -/

def amin (u v : Nat) : Nat := if u ≤ v then u else v

theorem amin_le_left (u v : Nat) : amin u v ≤ u := by
  unfold amin; split
  · exact Nat.le_refl u
  · rename_i h; omega

theorem amin_le_right (u v : Nat) : amin u v ≤ v := by
  unfold amin; split
  · rename_i h; omega
  · exact Nat.le_refl v

theorem amin_min {u v w : Nat} (h1 : w ≤ u) (h2 : w ≤ v) : w ≤ amin u v := by
  unfold amin; split <;> omega

example : amin (amin 1 1 + 1) 1 = 1 := by rfl

end Ex30
