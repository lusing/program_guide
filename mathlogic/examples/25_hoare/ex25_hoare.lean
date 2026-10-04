/- ex25 —— 霍尔逻辑（Lean 4 版）：赋值公理、while 规则与倒数程序
   对书：Huth&Ryan ch4 / Ben-Ari 3e ch15

   本章的通道对照最有戏：while 规则的证明三个系统给出三种反应——
   Coq 需 remember+inversion；Lean 的 induction 直接拒绝构造子头
   索引（"consider using the cases tactic instead"），须把命令泛化
   成变量并让方程 w = cwhile b c 进动机。 -/
namespace Ex25

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

/-- 部分正确性三元组 -/
def hoare (P : State → Prop) (c : Cmd) (Q : State → Prop) : Prop :=
  ∀ s₁ s₂, P s₁ → Exec c s₁ s₂ → Q s₂

/-- 旗舰一：skip 规则 -/
theorem hoare_skip (P : State → Prop) : hoare P .cskip P := by
  intro s₁ s₂ HP He
  cases He; exact HP

/-- 旗舰二：赋值公理（后推前件） -/
theorem hoare_ass (Q : State → Prop) (x : Nat) (f : State → Nat) :
    hoare (fun s => Q (upd s x (f s))) (cass x f) Q := by
  intro s₁ s₂ HP He
  cases He; exact HP

/-- 旗舰三：顺序规则 -/
theorem hoare_seq {P Q R : State → Prop} {c₁ c₂ : Cmd}
    (h₁ : hoare P c₁ Q) (h₂ : hoare Q c₂ R) : hoare P (cseq c₁ c₂) R := by
  intro s₁ s₃ HP He
  cases He with
  | seq h1 h2 => exact h₂ _ _ (h₁ _ _ HP h1) h2

/-- 旗舰四：while 规则（不变式）。

    直接 induction He 会被拒（索引是构造子头 cwhile b c）。
    配方 = Coq remember 的翻译：命令泛化为变量 w，方程
    w = cwhile b c 携带进动机，不可能分支由 noConfusion 灭。 -/
theorem hoare_while {P : State → Prop} {b : State → Bool} {c : Cmd}
    (hbody : hoare (fun s => P s ∧ b s = true) c P) :
    hoare P (cwhile b c) (fun s => P s ∧ b s = false) := by
  have key : ∀ (w : Cmd) s₁ s₂, w = cwhile b c → P s₁ → Exec w s₁ s₂ →
      P s₂ ∧ b s₂ = false := by
    intro w s₁ s₂ hw HP He
    revert hw HP
    induction He with
    | skip s => intro hw _; exact Cmd.noConfusion hw
    | ass x f s => intro hw _; exact Cmd.noConfusion hw
    | seq h1 _ih1 h2 _ih2 => intro hw _; exact Cmd.noConfusion hw
    | whileT hb hstep _ihstep hloop ihloop =>
      intro hw HP
      injection hw with hbc hcc; subst hbc; subst hcc
      exact ihloop rfl (hbody _ _ ⟨HP, hb⟩ hstep)
    | whileF hb =>
      intro hw HP
      injection hw with hbc hcc; subst hbc; subst hcc
      exact ⟨HP, hb⟩
  intro s₁' s₂' hP hE
  exact key _ s₁' s₂' rfl hP hE

/- ---------- 现场演示：倒数程序 ---------- -/

/-- countdown(x,y) := while (x ≠ 0) do (x := x-1; y := y+1)
    不变式：s x + s y = C。别名警告同 Coq 版：x = y 须排除。 -/
def countdown (x y : Nat) : Cmd :=
  cwhile (fun s => decide (s x ≠ 0))
         (cseq (cass x (fun s => s x - 1)) (cass y (fun s => s y + 1)))

def inv (x y C : Nat) : State → Prop :=
  fun s => s x + s y = C

theorem upd_read (s : State) (x : Nat) : upd s x (s x - 1) x = s x - 1 := by
  simp [upd]

theorem upd_other (s : State) (x m : Nat) (h : m ≠ x) :
    upd s x (s x - 1) m = s m := by
  simp [upd, h]

/-- 守卫的 Bool→Prop 转换 -/
theorem guard_true {s : State} {x : Nat} (h : decide (s x ≠ 0) = true) :
    s x ≠ 0 :=
  of_decide_eq_true h

theorem guard_false {s : State} {x : Nat} (h : decide (s x ≠ 0) = false) :
    s x = 0 := by
  cases Nat.eq_zero_or_pos (s x) with
  | inl hz => exact hz
  | inr hpos =>
    have hne : s x ≠ 0 := Nat.ne_of_gt hpos
    rw [decide_eq_true hne] at h
    simp at h

/-- 完全组装：部分正确性 + 出口守卫 = x 归零 -/
theorem countdown_correct (x y C : Nat) (s₁ s₂ : State) (hne : x ≠ y)
    (hinv : inv x y C s₁) (he : Exec (countdown x y) s₁ s₂) :
    inv x y C s₂ ∧ s₂ x = 0 := by
  have hbody :
      hoare (fun s => inv x y C s ∧ decide (s x ≠ 0) = true)
            (cseq (cass x (fun s => s x - 1)) (cass y (fun s => s y + 1)))
            (inv x y C) := by
    refine hoare_seq (P := fun s => inv x y C s ∧ decide (s x ≠ 0) = true)
      (Q := fun t => t x + t y + 1 = C) ?_ ?_
    · intro s t HP Hx
      cases Hx
      have hpos : s x ≠ 0 := guard_true HP.2
      have hin := HP.1
      simp only [inv] at hin
      show (upd s x (s x - 1)) x + (upd s x (s x - 1)) y + 1 = C
      rw [upd_read, upd_other s x y (fun e => hne e.symm)]
      omega
    · intro t u HQ Hx
      cases Hx
      simp only [inv]
      have h1 : upd t y (t y + 1) x = t x := by
        unfold upd
        split
        · next e => exact absurd e hne
        · rfl
      have h2 : upd t y (t y + 1) y = t y + 1 := by simp [upd]
      show (upd t y (t y + 1)) x + (upd t y (t y + 1)) y = C
      rw [h1, h2]; omega
  obtain ⟨hinv2, hb⟩ := hoare_while hbody s₁ s₂ hinv he
  exact ⟨hinv2, guard_false hb⟩

end Ex25

/- 坑位速记（Lean 侧）：
   - `while` 是保留字（do 记法）——构造子必须叫 cwhile；
   - induction 拒绝构造子头索引（"consider using the cases
     tactic instead"）——cases 又不能递归；正解 = 命令泛化为
     变量 w + 方程 w = cwhile b c 进动机（Coq remember 的直译），
     不可能分支 Cmd.noConfusion hw 三连灭，b'=b 用 injection；
   - cases 的 with 模式只数构造子的显式前提（implicits 隐藏），
     `| seq h1 h2 =>`——按字段数会报 "Too many variable names"；
   - Bool 守卫的桥：Nat.ne_of_beq_eq_false / Nat.eq_of_beq_eq_true，
     `simpa using h` 把 !(s x == 0) = true 反解成 beq = false；
   - omega 吃截断减法（s x - 1 + 1 = s x 须 s x ≠ 0 在场）。 -/
