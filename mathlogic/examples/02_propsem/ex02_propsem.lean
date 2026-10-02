/- ex02 —— 命题逻辑：语法、语义与蛮力判定器（Lean 4 版）
   与 Coq 版同构：eval / vars / 一致性引理 / 蛮力判定器双向可靠。 -/

namespace Ex02

inductive Form where
  | var (n : Nat) : Form
  | imp (a b : Form) : Form
  | conj (a b : Form) : Form
  | disj (a b : Form) : Form
  | neg (a : Form) : Form
  | fals : Form

open Form

def eval (e : Nat → Bool) : Form → Bool
  | var n => e n
  | imp a b => !(eval e a) || eval e b
  | conj a b => eval e a && eval e b
  | disj a b => eval e a || eval e b
  | neg a => !(eval e a)
  | fals => false

def vars : Form → List Nat
  | var n => [n]
  | imp a b => vars a ++ vars b
  | conj a b => vars a ++ vars b
  | disj a b => vars a ++ vars b
  | neg a => vars a
  | fals => []

/- ---------- 一致性引理 ---------- -/

theorem agree_eval : ∀ (f : Form) (e₁ e₂ : Nat → Bool),
    (∀ x ∈ vars f, e₁ x = e₂ x) → eval e₁ f = eval e₂ f := by
  intro f
  induction f with
  | var n =>
      intro e₁ e₂ h
      exact h n (show n ∈ vars (var n) from List.Mem.head _)
  | imp a b iha ihb =>
      intro e₁ e₂ h
      simp only [eval]
      rw [iha e₁ e₂ (fun x hx => h x (show x ∈ vars (imp a b) from
             List.mem_append_left _ hx)),
          ihb e₁ e₂ (fun x hx => h x (show x ∈ vars (imp a b) from
             List.mem_append_right _ hx))]
  | conj a b iha ihb =>
      intro e₁ e₂ h
      simp only [eval]
      rw [iha e₁ e₂ (fun x hx => h x (show x ∈ vars (conj a b) from
             List.mem_append_left _ hx)),
          ihb e₁ e₂ (fun x hx => h x (show x ∈ vars (conj a b) from
             List.mem_append_right _ hx))]
  | disj a b iha ihb =>
      intro e₁ e₂ h
      simp only [eval]
      rw [iha e₁ e₂ (fun x hx => h x (show x ∈ vars (disj a b) from
             List.mem_append_left _ hx)),
          ihb e₁ e₂ (fun x hx => h x (show x ∈ vars (disj a b) from
             List.mem_append_right _ hx))]
  | neg a iha =>
      intro e₁ e₂ h
      simp only [eval]
      rw [iha e₁ e₂ (fun x hx => h x hx)]
  | fals => intro _ _ _; rfl

/- ---------- 蛮力判定器 ---------- -/

def lookup (n : Nat) : List (Nat × Bool) → Bool
  | [] => false
  | (x, b) :: r => if n = x then b else lookup n r

def assignOf (vs : List Nat) (v : List Bool) : Nat → Bool :=
  fun n => lookup n (vs.zip v)

def allVectors : List Nat → List (List Bool)
  | [] => [[]]
  | _ :: xs => (allVectors xs).map (fun l => false :: l) ++ (allVectors xs).map (fun l => true :: l)

def check (f : Form) : Bool :=
  (allVectors (vars f)).all (fun v => eval (assignOf (vars f) v) f)

/- ---------- 三条辅助引理 ---------- -/

theorem lookup_zip_map (vs : List Nat) (e : Nat → Bool) (x : Nat) (hx : x ∈ vs) :
    lookup x (vs.zip (vs.map e)) = e x := by
  induction vs with
  | nil => cases hx
  | cons y ys ih =>
      cases hx with
      | head =>
          show (if x = x then e x else lookup x (ys.zip (ys.map e))) = e x
          simp
      | tail _ hx' =>
          show (if x = y then e y else lookup x (ys.zip (ys.map e))) = e x
          by_cases h : x = y
          · rw [if_pos h, h]
          · rw [if_neg h]
            exact ih hx'

theorem map_mem_allVectors (vs : List Nat) (e : Nat → Bool) :
    vs.map e ∈ allVectors vs := by
  induction vs with
  | nil => exact List.Mem.head _
  | cons x xs ih =>
      show e x :: xs.map e ∈ allVectors (x :: xs)
      simp only [allVectors]
      cases h : e x with
      | true =>
          exact List.mem_append_right _ (List.mem_map.2 ⟨xs.map e, ih, rfl⟩)
      | false =>
          exact List.mem_append_left _ (List.mem_map.2 ⟨xs.map e, ih, rfl⟩)

theorem all_false_witness : ∀ (p : List Bool → Bool) (l : List (List Bool)),
    l.all p = false → ∃ v, v ∈ l ∧ p v = false := by
  intro p l
  induction l with
  | nil => intro h; simp at h
  | cons a as ih =>
      intro h
      simp only [List.all_cons] at h
      cases hp : p a with
      | false => exact ⟨a, List.Mem.head _, hp⟩
      | true =>
          rw [hp] at h
          obtain ⟨v, hv1, hv2⟩ := ih h
          exact ⟨v, List.Mem.tail _ hv1, hv2⟩

/- ---------- 旗舰：双向可靠 ---------- -/

theorem check_true_valid (f : Form) (h : check f = true) (e : Nat → Bool) :
    eval e f = true := by
  have key : eval e f = eval (assignOf (vars f) ((vars f).map e)) f :=
    agree_eval f e _ (fun x hx => (lookup_zip_map _ e x hx).symm)
  rw [key]
  exact (List.all_eq_true).mp h _ (map_mem_allVectors (vars f) e)

theorem check_false_counter (f : Form) (h : check f = false) :
    ∃ e, eval e f = false := by
  obtain ⟨v, _, hv2⟩ := all_false_witness _ _ h
  exact ⟨assignOf (vars f) v, hv2⟩

/- ---------- 现场 ---------- -/

example : check (disj (var 0) (neg (var 0))) = true := by decide

example : check (imp (imp (imp (var 0) (var 1)) (var 0)) (var 0)) = true := by decide

example : check (conj (var 0) (neg (var 0))) = false := by decide

/- 坑位速记（Lean 侧）：
   - Form.and 与 Bool.and 在 open 后撞名——构造子改名 conj/disj 最省心；
   - show ... from e 桥接定义展开（vars/zip/map 的 iota 折叠都吃 defeq）；
   - simp only [eval/lookup] 只暴露一层方程；if_pos/if_neg 精确消 if；
   - rw 自动尝试 rfl 收尾——链条最后一格常被白送。 -/

end Ex02
