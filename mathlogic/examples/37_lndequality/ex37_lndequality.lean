/- ex37_lndequality —— 标号演绎与相等（Lean 4 版）
   与 ex37_lndequality.v 同构：群论项+定向重写、带证书的改写理由
   AST、双向重放引擎（σ 翻转、τ 逆向倒序）、标签正规化+端点保持、
   内延性现场（两条不同理由 vs 范式塌缩）。 -/

namespace Ex37

inductive Gt where
  | ge
  | gvar (n : Nat)
  | ginv (a : Gt)
  | gmul (a b : Gt)

def gtEq : Gt → Gt → Bool
  | .ge, .ge => true
  | .gvar n, .gvar m => n == m
  | .ginv a, .ginv b => gtEq a b
  | .gmul a1 a2, .gmul b1 b2 => gtEq a1 b1 && gtEq a2 b2
  | _, _ => false

/-- 规则库：0=左单位 e·x→x；1=左逆 x⁻¹·x→e；2=结合 (x·y)·z→x·(y·z)。 -/
def step1 (rid : Nat) : Gt → Option Gt
  | .gmul a b =>
      match rid with
      | 0 => match a with
             | .ge => some b
             | _ => none
      | 1 => match a with
             | .ginv c => if gtEq c b then some .ge else none
             | _ => none
      | 2 => match a with
             | .gmul x y => some (.gmul x (.gmul y b))
             | _ => none
      | _ => none
  | _ => none

/-- 最左最外恰一步（先顶、后参数）。Lean 对「先试顶步再下钻」的
    写法认不出结构降参——燃料版下钻。 -/
def stepAnyF : Nat → Nat → Gt → Option Gt
  | 0, _, _ => none
  | fuel + 1, rid, t =>
      match step1 rid t with
      | some u => some u
      | none =>
          match t with
          | .gmul a b =>
              match stepAnyF fuel rid a with
              | some a' => some (.gmul a' b)
              | none =>
                  match stepAnyF fuel rid b with
                  | some b' => some (.gmul a b')
                  | none => none
          | .ginv a =>
              match stepAnyF fuel rid a with
              | some a' => some (.ginv a')
              | none => none
          | _ => none

def stepAny (rid : Nat) (t : Gt) : Option Gt := stepAnyF 100 rid t

/-- 改写理由：原子步带证书（合法性=step1 rid src = dst）。 -/
inductive Reason where
  | rStep (rid : Nat) (src dst : Gt)
  | rRefl
  | rSym (s : Reason)
  | rTrans (s t : Reason)
  | rCongArg (i : Nat) (s : Reason)

def validStep : Reason → Bool
  | .rStep rid src dst =>
      match step1 rid src with
      | some u => gtEq u dst
      | none => false
  | _ => false

def reasonOK : Reason → Bool
  | r@(.rStep _ _ _) => validStep r
  | .rRefl => true
  | .rSym s => reasonOK s
  | .rTrans s t => reasonOK s && reasonOK t
  | .rCongArg _ s => reasonOK s

def stepGetArg (i : Nat) (t : Gt) : Option Gt :=
  match t with
  | .gmul a b => if i == 0 then some a else some b
  | .ginv a => some a
  | _ => none

def stepSetArg (i : Nat) (t a : Gt) : Gt :=
  match t with
  | .gmul u v => if i == 0 then .gmul a v else .gmul u a
  | .ginv _ => .ginv a
  | x => x

/-- 双向重放：σ 翻转方向、τ 逆向倒序、合同下钻、原子步核对证书。 -/
def replayOpt (fwd : Bool) (t : Gt) : Reason → Option Gt
  | .rStep _ src dst =>
      if fwd
      then if gtEq t src then some dst else none
      else if gtEq t dst then some src else none
  | .rRefl => some t
  | .rSym s => replayOpt (!fwd) t s
  | .rTrans s u =>
      if fwd
      then do
        let m ← replayOpt true t s
        replayOpt true m u
      else do
        let m ← replayOpt false t u
        replayOpt false m s
  | .rCongArg i s =>
      match stepGetArg i t with
      | some a =>
          match replayOpt fwd a s with
          | some a' => some (stepSetArg i t a')
          | none => none
      | none => none

def replayOK (a b : Gt) (r : Reason) : Bool :=
  match replayOpt true a r with
  | some m => gtEq m b && reasonOK r
  | none => false

def reasonEqb : Reason → Reason → Bool
  | .rStep r1 a1 b1, .rStep r2 a2 b2 =>
      r1 == r2 && gtEq a1 a2 && gtEq b1 b2
  | .rRefl, .rRefl => true
  | .rSym s1, .rSym t1 => reasonEqb s1 t1
  | .rTrans s1 s2, .rTrans t1 t2 => reasonEqb s1 t1 && reasonEqb s2 t2
  | .rCongArg i1 s1, .rCongArg i2 t2 => i1 == i2 && reasonEqb s1 t2
  | _, _ => false

/-- 标签正规化：ρ∘s→s、s∘ρ→s、σσ→ρ、合同ρ→ρ、σs∘s→ρ。 -/
def nrm : Reason → Reason
  | .rSym (.rSym _) => .rRefl
  | .rSym s => .rSym (nrm s)
  | .rTrans .rRefl t => nrm t
  | .rTrans s .rRefl => nrm s
  | .rTrans (.rSym s) t =>
      if reasonEqb s t then .rRefl else .rTrans (.rSym (nrm s)) (nrm t)
  | .rTrans s t => .rTrans (nrm s) (nrm t)
  | .rCongArg _ .rRefl => .rRefl
  | .rCongArg i s => .rCongArg i (nrm s)
  | r@(.rStep _ _ _) => r
  | .rRefl => .rRefl

def rsize : Reason → Nat
  | .rStep _ _ _ => 1
  | .rRefl => 0
  | .rSym s => rsize s + 1
  | .rTrans s t => rsize s + rsize t + 1
  | .rCongArg _ s => rsize s + 1

def oneStep (t : Gt) : Option Gt :=
  match stepAny 0 t with
  | some u => some u
  | none =>
      match stepAny 1 t with
      | some u => some u
      | none => stepAny 2 t

def nfF : Nat → Gt → Gt
  | 0, t => t
  | n + 1, t =>
      match oneStep t with
      | some u => nfF n u
      | none => t

def nf (t : Gt) : Gt := nfF 60 t

def extEq (a b : Gt) : Bool := gtEq (nf a) (nf b)

/- ---------- 断言电池 ---------- -/

def x : Gt := .gvar 0

def a1 : Gt := .gmul (.ginv x) (.gmul .ge x)

def step_id : Reason := .rCongArg 1 (.rStep 0 (.gmul .ge x) x)
def step_inv : Reason := .rStep 1 (.gmul (.ginv x) x) .ge
def chain1 : Reason := .rTrans step_id step_inv

/-- 电一：左逆链重放。 -/
example : replayOK a1 .ge chain1 = true := by decide

/-- 电二：σ/τ 导出规则；σσ=ρ。 -/
def symchain : Reason := .rSym chain1

example : replayOK .ge a1 symchain = true := by decide

example : (reasonEqb (nrm (.rSym symchain)) .rRefl
          && (rsize (nrm (.rSym symchain)) == 0)) = true := by decide

/-- 电三：正规化保持端点。 -/
def chain1' : Reason :=
  .rTrans (.rTrans .rRefl step_id) (.rTrans step_inv .rRefl)

example : reasonEqb (nrm chain1') chain1
          && replayOK a1 .ge (nrm chain1') = true := by decide

/-- 电四：内延性现场——同一等式的两条不同理由 vs 范式塌缩。 -/
def a2 : Gt := .gmul .ge x
def direct_id : Reason := .rStep 0 a2 x
def chainC : Reason := .rTrans direct_id .rRefl

example : replayOK a2 x chainC
          && !reasonEqb chainC direct_id
          && extEq (.gmul .ge x) x = true := by decide

end Ex37
