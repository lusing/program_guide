/- ex41 —— 可枚举集与算术层级（Marker ch11）Lean 镜像
   层级归属见证+多一归约+层级分离影子+Kolmogorov 表宇宙版。 -/

set_option linter.unusedVariables false
set_option linter.unusedSimpArgs false

inductive Inst : Type
  | radd (r a : Nat) | rdel (r a : Nat) | rife (r l1 l2 : Nat)
  | rprint | rhalt

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

def step (p : Prog) (c : Cfg) : Cfg :=
  match p.getD c.pc .rhalt with
  | .radd r a => ⟨c.pc + 1, setn c.regs r (nthd c.regs r + a), c.out⟩
  | .rdel r a => ⟨c.pc + 1, setn c.regs r (nthd c.regs r - a), c.out⟩
  | .rife r l1 l2 =>
      if nthd c.regs r == 0 then ⟨l1, c.regs, c.out⟩ else ⟨l2, c.regs, c.out⟩
  | .rprint => ⟨c.pc + 1, c.regs, c.out ++ [nthd c.regs 0]⟩
  | .rhalt => c

def run : Prog → Cfg → Nat → Option Cfg
  | _, _, 0 => none
  | p, c, fuel+1 => if halted p c then some c else run p (step p c) fuel

def U : List Prog :=
  [ [.radd 0 1, .rhalt], [.radd 0 2, .rhalt], [.radd 0 0, .rhalt],
    [.radd 0 1, .rdel 0 1, .rhalt], [.radd 0 1, .rife 0 0 1], [.rhalt],
    [.radd 0 3, .radd 0 3, .rhalt], [.rdel 0 1, .rife 0 5 0],
    [.rife 1 9 9], [.rprint, .rhalt],
    [.radd 0 1, .radd 0 1, .radd 0 1, .rhalt], [.radd 1 1, .rhalt],
    [.rdel 0 1, .rhalt], [.rife 0 14 14], [.radd 0 0, .rprint, .rhalt],
    [.radd 0 5, .rhalt], [.rdel 0 5, .rhalt], [.radd 0 1, .radd 0 1, .rhalt],
    [.rife 0 19 20, .rhalt], [.rhalt], [.radd 0 1, .rdel 0 2, .rhalt],
    [.rprint, .rprint, .rhalt], [.radd 0 9, .rhalt], [.rife 1 5 5] ]

def urun (e x fuel : Nat) : Option Cfg :=
  run (U.getD e [.rhalt]) ⟨0, [x,0,0], []⟩ fuel

def Wout (e s : Nat) : List Nat :=
  match urun e 0 s with | some c => c.out | none => []

def kStage (e s : Nat) : Bool := (urun e e s).isSome

-- ---------- 1. 层级归属见证 ----------

-- K ∈ Σ₁：阶段枚举与成员一致
example : (List.range 24).all (fun e =>
    (List.range 40).any (fun s => kStage e s) == (urun e e 40).isSome)
    = true := by native_decide

def totWit (e n s : Nat) : Bool := (urun e n s).isSome

-- 0 号全停（Tot 的正样本）；4 号全不停（负样本）
example : ((List.range 10).all (fun n => (List.range 40).any (fun s => totWit 0 n s))
    && (List.range 10).all (fun n => !(List.range 40).any (fun s => totWit 4 n s)))
    = true := by native_decide

-- Fin ∈ Σ₂：打印型程序输出集封顶
example : [9,14,21].all (fun e =>
    [0,1].any (fun m => (List.range (20-(m+1))).all (fun k =>
      let x := m+1+k
      (List.range 40).all (fun s => !(Wout e s).any (fun y => y == x)))))
    = true := by native_decide

-- ---------- 2. 偶性 ≤ₘ K ----------

def redEven (x : Nat) : Nat := if x % 2 == 0 then 5 else 4

example : (List.range 16).all (fun x =>
    (x % 2 == 0) == (urun (redEven x) (redEven x) 40).isSome) = true := by
  native_decide

-- ---------- 3. 层级分离影子 ----------

example : (List.range 40).all (fun s =>
    !(kStage 4 s) && (urun 4 4 s).isNone) = true := by native_decide

-- ---------- 4. Kolmogorov 表宇宙版 ----------

def outputOf (e : Nat) : Nat :=
  match urun e 0 40 with
  | some c => nthd c.regs 0
  | none => 999

def kOf (x : Nat) : Nat :=
  match (List.range 24).filter (fun e => outputOf e == x) with
  | e :: _ => e
  | [] => 24

-- 短描述比串少：8..15 中必有 K_U ≥ 4 的随机数
example : (List.range 8).any (fun k =>
    let x := 8 + k
    kOf x ≤ 23 && 4 ≤ kOf x) = true := by native_decide

#eval (List.range 16).map kOf   -- kOf(4)=24：无描述即随机
