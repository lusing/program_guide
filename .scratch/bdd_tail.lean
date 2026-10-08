
/- ---------- apply/mapleaf：补齐双树组合子（与 Coq 版同构） ---------- -/

def mapleaf (f : Bool → Bool) : DTree → DTree
  | dleaf c => dleaf (f c)
  | dnode lo hi => dnode (mapleaf f lo) (mapleaf f hi)

theorem teval_mapleaf : ∀ (b : DTree) (e : Nat → Bool) (f : Bool → Bool),
    teval e (mapleaf f b) = f (teval e b) := by
  intro b
  induction b with
  | dleaf c => intro _ _; rfl
  | dnode lo hi ihlo ihhi =>
    intro e f
    simp only [teval, mapleaf]
    cases e 0 <;> rw [ihlo, ihhi] <;> rfl

def applyd (op : Bool → Bool → Bool) : DTree → DTree → DTree
  | dleaf c1, b2 => mapleaf (fun c => op c1 c) b2
  | b1, dleaf c2 => mapleaf (fun c => op c c2) b1
  | dnode l1 h1, dnode l2 h2 => dnode (applyd op l1 l2) (applyd op h1 h2)

theorem applyd_correct : ∀ (op : Bool → Bool → Bool) (b1 b2 : DTree) (e : Nat → Bool),
    teval e (applyd op b1 b2) = op (teval e b1) (teval e b2) := by
  intro op b1
  induction b1 with
  | dleaf c1 =>
    intro b2 e
    cases b2 with
    | dleaf c2 => rfl
    | dnode l2 h2 =>
      rw [applyd, teval_mapleaf]
      cases e 0 <;> rfl
  | dnode l1 h1 ihl ihh =>
    intro b2 e
    cases b2 with
    | dleaf c2 =>
      rw [applyd, teval_mapleaf]
      cases e 0 <;> rfl
    | dnode l2 h2 =>
      rw [applyd]
      simp only [teval]
      cases e 0 <;> rw [ihl, ihh] <;> rfl

/- ---------- restrict / exists：H&R §6.2.3-6.2.4 ---------- -/

def upd (e : Nat → Bool) (v : Nat) (b : Bool) : Nat → Bool :=
  fun n => if n == v then b else e n

theorem teval_ext (t : DTree) (e1 e2 : Nat → Bool) (h : ∀ n, e1 n = e2 n) :
    teval e1 t = teval e2 t := by
  induction t with
  | dleaf c => rfl
  | dnode lo hi ihlo ihhi =>
    simp only [teval]
    cases h0 : e1 0 with
    | true =>
      have h0' : e2 0 = true := by rw [← h 0, h0]
      rw [h0']
      exact ihhi h
    | false =>
      have h0' : e2 0 = false := by rw [← h 0, h0]
      rw [h0']
      exact ihlo h

/-- lift：垫回一层，保持变量绝对编号；顶节点测试结果无关紧要 -/
def lift (t : DTree) : DTree := dnode t t

theorem teval_lift (t : DTree) (e : Nat → Bool) :
    teval e (lift t) = teval (eshift e) t := by
  simp only [lift, teval]
  cases e 0 <;> rfl

/-- restrict v b t：变元 v 钉为 b；v=0 剪枝后必须 lift 垫回（防变量错位，
    与 Coq 版同款「保语义不缩尺寸」树形实现） -/
def restrict : Nat → Bool → DTree → DTree
  | _, _, dleaf c => dleaf c
  | 0, b, dnode lo hi => lift (if b then hi else lo)
  | v + 1, b, dnode lo hi => dnode (restrict v b lo) (restrict v b hi)

theorem restrict_eq_zero (lo hi : DTree) (b : Bool) :
    restrict 0 b (dnode lo hi) = lift (if b then hi else lo) := rfl

theorem restrict_eq_succ (lo hi : DTree) (v : Nat) (b : Bool) :
    restrict (v + 1) b (dnode lo hi) =
      dnode (restrict v b lo) (restrict v b hi) := rfl

theorem restrict_correct : ∀ (t : DTree) (v : Nat) (b : Bool) (e : Nat → Bool),
    teval e (restrict v b t) = teval (upd e v b) t := by
  intro t
  induction t with
  | dleaf c => intro _ _ _; rfl
  | dnode lo hi ihlo ihhi =>
    intro v b e
    cases v with
    | zero =>
      rw [restrict_eq_zero, teval_lift]
      have htop : teval (upd e 0 b) (dnode lo hi) =
          teval (eshift (upd e 0 b)) (if b then hi else lo) := by
        simp only [teval, upd]
        cases b <;> rfl
      rw [htop]
      cases b with
      | true =>
        exact teval_ext hi _ _ (fun n => by simp only [eshift, upd])
      | false =>
        exact teval_ext lo _ _ (fun n => by simp only [eshift, upd])
    | succ v' =>
      rw [restrict_eq_succ]
      have htop : teval (upd e (v' + 1) b) (dnode lo hi) =
          if e 0 then teval (upd (eshift e) v' b) hi
          else teval (upd (eshift e) v' b) lo := by
        simp only [teval, upd, eshift, Nat.beq_succ_succ]
      rw [htop]
      simp only [teval]
      cases h0 : e 0 with
      | true =>
        rw [h0]
        rw [ihhi v' b (eshift e)]
        exact teval_ext hi _ _ (fun n => by simp only [eshift, upd, Nat.beq_succ_succ])
      | false =>
        rw [h0]
        rw [ihlo v' b (eshift e)]
        exact teval_ext lo _ _ (fun n => by simp only [eshift, upd, Nat.beq_succ_succ])

/-- exists（H&R 式 6.3）：∃x. f := f[0/x] + f[1/x] -/
def exb (v : Nat) (t : DTree) : DTree :=
  applyd (· || ·) (restrict v false t) (restrict v true t)

theorem exb_correct (t : DTree) (v : Nat) (e : Nat → Bool) :
    teval e (exb v t) =
    (teval (upd e v false) t || teval (upd e v true) t) := by
  rw [exb, applyd_correct, restrict_correct, restrict_correct]

/- 现场两枚（与 Coq 版同款断言） -/

example : ∀ e, teval e (exb 0 (mkvaru 0)) = true := by
  intro e
  rw [exb_correct]
  simp only [upd, teval, eshift]
  cases e 1 <;> rfl

example : ∀ e,
    teval e (restrict 1 true (applyd (· && ·) (mkvaru 0) (mkvaru 1))) = e 0 := by
  intro e
  rw [restrict_correct, applyd_correct, teval_mkvaru, teval_mkvaru]
  simp only [upd]
  cases e 0 <;> rfl

#print axioms restrict_correct
#print axioms exb_correct
