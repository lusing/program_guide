/- ex42 —— 图灵度与优先法（Marker ch12）Lean 镜像
   oracle 机+KP 显式击败+König 左极路径+FM 阶段账。 -/

set_option linter.unusedVariables false
set_option linter.unusedSimpArgs false

inductive Inst : Type
  | radd (r a : Nat) | rdel (r a : Nat) | rife (r l1 l2 : Nat)
  | rprint | rhalt | roq (r l1 l2 : Nat)

abbrev Prog := List Inst

structure Cfg where
  pc : Nat
  regs : List Nat
  out : List Nat

def setn : List Nat → Nat → Nat → List Nat
  | [], _, _ => []
  | _ :: t, 0, v => v :: t
  | y :: t, x'+1, v => y :: setn t x' v

def nthd (l : List Nat) (i : Nat) : Nat := l.getD i 0

def halted (p : Prog) (c : Cfg) : Bool :=
  match p.getD c.pc .rhalt with | .rhalt => true | _ => false

def ostep (o : Nat → Bool) (p : Prog) (c : Cfg) : Cfg :=
  match p.getD c.pc .rhalt with
  | .radd r a => ⟨c.pc+1, setn c.regs r (nthd c.regs r + a), c.out⟩
  | .rdel r a => ⟨c.pc+1, setn c.regs r (nthd c.regs r - a), c.out⟩
  | .rife r l1 l2 =>
      if nthd c.regs r == 0 then ⟨l1, c.regs, c.out⟩ else ⟨l2, c.regs, c.out⟩
  | .rprint => ⟨c.pc+1, c.regs, c.out ++ [nthd c.regs 0]⟩
  | .rhalt => c
  | .roq r l1 l2 =>
      if o (nthd c.regs r) then ⟨l1, c.regs, c.out⟩ else ⟨l2, c.regs, c.out⟩

def orun : (Nat → Bool) → Prog → Cfg → Nat → Option Cfg
  | _, _, _, 0 => none
  | o, p, c, fuel+1 =>
      if halted p c then some c else orun o p (ostep o p c) fuel

-- 两个 oracle 归约程序（与 Coq 通道同款）
def PcopyB : Prog := [.roq 0 2 3, .radd 0 1, .rhalt, .rhalt]
def PnegA : Prog := [.roq 0 2 1, .rhalt, .rdel 0 1, .rhalt]

def Abits : List Bool :=
  [true, false, true, true, false, true, false, true,
   true, false, false, true, true, false, true, false]
def Bbits : List Bool :=
  [false, false, false, false, true, false, true, false,
   false, true, true, false, false, true, false, true]

def oA (x : Nat) : Bool := Abits.getD x false
def oB (x : Nat) : Bool := Bbits.getD x false

-- R1：PcopyB^B(0)=0（复制 B(0)=false）≠ A(0)=true
example : ((match orun oB PcopyB ⟨0,[0,0,0],[]⟩ 20 with
     | some c => nthd c.regs 0 == 0
     | none => false) && !oB 0 && oA 0) = true := by native_decide

-- R2：PnegA^A(1)=1（=¬A(1)）≠ B(1)=false
example : ((match orun oA PnegA ⟨0,[1,0,0],[]⟩ 20 with
     | some c => nthd c.regs 0 == 1
     | none => false) && !oB 1) = true := by native_decide

-- ---------- König 左极路径 ----------

def bits : Nat → List (List Bool)
  | 0 => [[]]
  | m+1 => (bits m).map (fun l => false :: l) ++ (bits m).map (fun l => true :: l)

def Tavoid1 (sigma : List Bool) : Bool := !sigma.all (fun b => b)

def subInf (T : List Bool → Bool) (sigma : List Bool) (D : Nat) : Bool :=
  (List.range (D+1)).all (fun d =>
    (bits (d+1)).any (fun ext => T (sigma ++ ext)))

def leftmost (T : List Bool → Bool) : Nat → List Bool
  | 0 => []
  | D+1 =>
      let lft := leftmost T D ++ [false]
      if T lft && subInf T lft D then lft else leftmost T D ++ [true]

example : (Tavoid1 (leftmost Tavoid1 6)
    && ((leftmost Tavoid1 6).length == 6)) = true := by native_decide

-- ---------- FM 阶段账 ----------

structure FmState where
  fA : List Nat
  fB : List Nat
  inj : List Nat
  stage : Nat

def fmStep (s : FmState) : FmState :=
  if s.stage % 2 == 0 then
    { fA := (s.stage+1) :: s.fA, fB := s.fB,
      inj := if s.stage % 4 == 0 && !s.fA.isEmpty
             then (s.inj.getD 0 0 + 1) :: s.inj.drop 1 else s.inj,
      stage := s.stage + 1 }
  else
    { fA := s.fA, fB := (s.stage+1) :: s.fB,
      inj := if s.stage % 4 == 3 && !s.fB.isEmpty
             then (s.inj.getD 0 0 + 1) :: s.inj.drop 1 else s.inj,
      stage := s.stage + 1 }

def fmRun : FmState → Nat → FmState
  | s, 0 => s
  | s, n+1 => fmRun (fmStep s) n

def fm12 : FmState := fmRun ⟨[], [], [0,0], 0⟩ 12

example : (fm12.fA.length == 6 && fm12.fB.length == 6
    && Nat.ble (fm12.inj.getD 0 0) 6) = true := by native_decide

#eval (fm12.fA, fm12.fB, fm12.inj)
