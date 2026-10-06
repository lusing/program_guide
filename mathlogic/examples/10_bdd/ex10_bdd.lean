/- ex10 —— BDD（Lean 4 版：规模爆炸现场与 DAG 距离）
   Coq 通道承担 apply/mkvar/mk 三条零公理旗舰；
   本文件现场演示树形 BDD 的规模爆炸，以及为什么真正的 ROBDD
   必须是 DAG（共享子树）——这是教学版到工业实现（CUDD）的距离。 -/

namespace Ex10

inductive DTree where
  | dleaf (c : Bool) : DTree
  | dnode (lo hi : DTree) : DTree

open DTree

def eshift (e : Nat → Bool) : Nat → Bool := fun m => e (m + 1)

def teval (e : Nat → Bool) : DTree → Bool
  | dleaf c => c
  | dnode lo hi => if e 0 then teval (eshift e) hi else teval (eshift e) lo

def bsize : DTree → Nat
  | dleaf _ => 1
  | dnode lo hi => 1 + bsize lo + bsize hi

/-- 未化简单变量树：满树 -/
def mkvaru : Nat → DTree
  | 0 => dnode (dleaf false) (dleaf true)
  | v + 1 => dnode (mkvaru v) (mkvaru v)

/-- 手工链：变量 v 的最简树——每层一个节点（语义与 mkvaru 相同） -/
def chain : Nat → DTree
  | 0 => dnode (dleaf false) (dleaf true)
  | v + 1 => dnode (chain v) (chain v)

theorem teval_mkvaru : ∀ (v : Nat) (e : Nat → Bool), teval e (mkvaru v) = e v := by
  intro v
  induction v with
  | zero =>
      intro e
      cases h : e 0 <;> simp [mkvaru, teval, h]
  | succ v' ih =>
      intro e
      simp only [mkvaru, teval]
      cases h : e 0 <;> rw [ih (eshift e)] <;> rfl

/- ---------- 规模爆炸现场 ---------- -)

- 满树：mkvaru 5 = 127 节点 -/
example : bsize (mkvaru 5) = 127 := by rfl

/- 树形的徒劳：「手工链」chain 与 mkvaru 逐节点相同——
   共享在树形表示里无从表达（chain v ≡ mkvaru v，定义相等） -/
example : (chain 5 : DTree) = mkvaru 5 := by rfl

/- 20 个变量时满树 4194303 节点——ROBDD 的 DAG 共享才是正解 -/
#eval bsize (mkvaru 20)

/- 坑位速记（Lean 侧）：
   - 树形 bsize (dnode b b) = 1 + 2*bsize b——两支共享在树形计数里
     不可见，这是 ROBDD 必须做成 DAG（节点表+唯一表）的根本原因；
   - cases h : e 0 <;> … 的跨分支 rw 用 show … from by rw 面向目标
     手工桥接（eshift 与 fun m => e (m+1) 的定义差异）。 -/


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
      show teval e (mapleaf (fun c => op c c2) (dnode l1 h1))
         = op (teval e (dnode l1 h1)) (teval e (dleaf c2))
      rw [teval_mapleaf]
      cases e 0 <;> rfl
    | dnode l2 h2 =>
      rw [applyd]
      simp only [teval]
      cases e 0 <;> rw [ihl, ihh] <;> rfl

/- ---------- restrict / exists：H&R §6.2.3-6.2.4 ---------- -/

def upd (e : Nat → Bool) (v : Nat) (b : Bool) : Nat → Bool :=
  fun n => if Nat.beq n v then b else e n

theorem teval_ext : ∀ (t : DTree) (e1 e2 : Nat → Bool),
    (∀ n, e1 n = e2 n) → teval e1 t = teval e2 t := by
  intro t
  induction t with
  | dleaf c => intro _ _ _; rfl
  | dnode lo hi ihlo ihhi =>
    intro e1 e2 h
    simp only [teval]
    cases h0 : e1 0 with
    | true =>
      have h0' : e2 0 = true := by rw [← h 0, h0]
      rw [h0']
      exact ihhi _ _ (fun n => h (n + 1))
    | false =>
      have h0' : e2 0 = false := by rw [← h 0, h0]
      rw [h0']
      exact ihlo _ _ (fun n => h (n + 1))

/-- lift：垫回一层，保持变量绝对编号；顶节点测试结果无关紧要 -/
def lift (t : DTree) : DTree := dnode t t

theorem teval_lift (t : DTree) (e : Nat → Bool) :
    teval e (lift t) = teval (eshift e) t := by
  simp only [lift, teval]
  cases e 0 <;> rfl

/-- restrict v b t：变元 v 钉为 b；v=0 剪枝后必须 lift 垫回（防变量错位，
    与 Coq 版同款「保语义不缩尺寸」树形实现） -/
def restrict (v : Nat) (b : Bool) : DTree → DTree
  | dleaf c => dleaf c
  | dnode lo hi =>
      match v with
      | 0 => lift (if b then hi else lo)
      | v' + 1 => dnode (restrict v' b lo) (restrict v' b hi)

theorem upd_head_S (e : Nat → Bool) (v : Nat) (b : Bool) :
    upd e (v + 1) b 0 = e 0 := rfl

theorem beq_succ_succ (n m : Nat) :
    Nat.beq (n + 1) (m + 1) = Nat.beq n m := by
  cases n <;> cases m <;> rfl

theorem eshift_upd_S (e : Nat → Bool) (v : Nat) (b : Bool) (n : Nat) :
    eshift (upd e (v + 1) b) n = upd (eshift e) v b n := by
  simp only [eshift, upd, beq_succ_succ]

theorem restrict_eq_leaf (c : Bool) : ∀ (v : Nat) (b : Bool),
    restrict v b (dleaf c) = dleaf c := by
  intro v b; cases v <;> rfl

theorem restrict_eq_zero (lo hi : DTree) (b : Bool) :
    restrict 0 b (dnode lo hi) = lift (if b then hi else lo) := rfl

theorem restrict_eq_succ (lo hi : DTree) (v : Nat) (b : Bool) :
    restrict (v + 1) b (dnode lo hi) =
      dnode (restrict v b lo) (restrict v b hi) := rfl

theorem restrict_correct : ∀ (t : DTree) (v : Nat) (b : Bool) (e : Nat → Bool),
    teval e (restrict v b t) = teval (upd e v b) t := by
  intro t
  induction t with
  | dleaf c => intro v b e; rw [restrict_eq_leaf]; rfl
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
        exact teval_ext hi _ _ (fun n => rfl)
      | false =>
        exact teval_ext lo _ _ (fun n => rfl)
    | succ v' =>
      rw [restrict_eq_succ]
      simp only [teval]
      rw [upd_head_S]
      cases h0 : e 0 with
      | true =>
        rw [ihhi v' b (eshift e)]
        exact teval_ext hi _ _ (fun n => (eshift_upd_S e v' b n).symm)
      | false =>
        rw [ihlo v' b (eshift e)]
        exact teval_ext lo _ _ (fun n => (eshift_upd_S e v' b n).symm)

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
  rfl

example : ∀ e,
    teval e (restrict 1 true (applyd (· && ·) (mkvaru 0) (mkvaru 1))) = e 0 := by
  intro e
  rw [restrict_correct, applyd_correct]
  rw [teval_mkvaru 0 (upd e 1 true), teval_mkvaru 1 (upd e 1 true)]
  have h0 : upd e 1 true 0 = e 0 := rfl
  have h1 : upd e 1 true 1 = true := rfl
  rw [h0, h1]
  cases e 0 <;> rfl

#print axioms restrict_correct
#print axioms exb_correct

end Ex10
