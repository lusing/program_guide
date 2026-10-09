/- ex40 —— 通用性与不可判定性（Marker ch10）Lean 镜像
   程序表宇宙+通用机+停机阶段+对角现场+Rice 影子+s-m-n 影子。 -/

set_option linter.unusedVariables false
set_option linter.unusedSimpArgs false

inductive Inst : Type
  | radd (r a : Nat)
  | rdel (r a : Nat)
  | rife (r l1 l2 : Nat)
  | rprint
  | rhalt

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
  match p.getD c.pc .rhalt with
  | .rhalt => true
  | _ => false

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

-- ---------- 1. 程序表宇宙 ----------

def U : List Prog :=
  [ [.radd 0 1, .rhalt]                    -- 0: +1
  , [.radd 0 2, .rhalt]                    -- 1: +2
  , [.radd 0 0, .rhalt]                    -- 2: 恒等 Pid1
  , [.radd 0 1, .rdel 0 1, .rhalt]         -- 3: 恒等 Pid2
  , [.radd 0 1, .rife 0 0 1]               -- 4: 自转不停
  , [.rhalt]                               -- 5: 立即停
  , [.radd 0 3, .radd 0 3, .rhalt]         -- 6: +6
  , [.rdel 0 1, .rife 0 5 0]               -- 7
  , [.rife 1 9 9]                          -- 8: 跳自身
  , [.rprint, .rhalt]                      -- 9
  , [.radd 0 1, .radd 0 1, .radd 0 1, .rhalt]  -- 10: +3
  , [.radd 1 1, .rhalt]                    -- 11
  , [.rdel 0 1, .rhalt]                    -- 12
  , [.rife 0 14 14]                        -- 13
  , [.radd 0 0, .rprint, .rhalt]           -- 14
  , [.radd 0 5, .rhalt]                    -- 15: +5
  , [.rdel 0 5, .rhalt]                    -- 16
  , [.radd 0 1, .radd 0 1, .rhalt]         -- 17: +2（与 1 同语义）
  , [.rife 0 19 20, .rhalt]                -- 18
  , [.rhalt]                               -- 19
  , [.radd 0 1, .rdel 0 2, .rhalt]         -- 20
  , [.rprint, .rprint, .rhalt]             -- 21
  , [.radd 0 9, .rhalt]                    -- 22: +9
  , [.rife 1 5 5]                          -- 23
  ]

def decP (e : Nat) : Prog := U.getD e [.rhalt]

-- ---------- 2. 通用机 ----------

def urun (e x fuel : Nat) : Option Cfg :=
  run (decP e) ⟨0, [x,0,0], []⟩ fuel

def halts (e x : Nat) : Bool := (urun e x 40).isSome

def implb (a b : Bool) : Bool := !a || b

def Kstage (s : Nat) : List Nat :=
  (List.range 24).filter (fun e => (urun e e s).isSome)

-- 4 号（自转）对自身不停；K 单调
example : (List.range 60).all (fun s => (urun 4 4 s).isNone) = true := by
  native_decide

example : (List.range 24).all (fun e =>
    implb (halts e e) ((urun e e 80).isSome)) = true := by native_decide

-- K_40 恰排除 4（与 Coq 通道 Kstage 30 的账本同型）
example : Kstage 40 == [0,1,2,3,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23] := by
  native_decide

-- ---------- 3. 对角现场 ----------

example : (List.range 60).all (fun s => (urun 4 7 s).isNone) = true := by
  native_decide

example : (urun 5 5 10).isSome = true := by native_decide

-- ---------- 4. Rice 影子 ----------

example : (List.range 12).all (fun x =>
    (urun 2 x 30).map (fun c => nthd c.regs 0)
    == (urun 3 x 30).map (fun c => nthd c.regs 0)) = true := by
  native_decide

example : (List.range 12).all (fun x =>
    (urun 1 x 30).map (fun c => nthd c.regs 0)
    == (urun 17 x 30).map (fun c => nthd c.regs 0)) = true := by
  native_decide

-- ---------- 5. s-m-n 影子 ----------

def Fspec (x y : Nat) : Nat := 2 * x + y

example : (List.range 12).all (fun y =>
    match urun 6 y 30 with
    | some c => nthd c.regs 0 == Fspec 3 y
    | none => false) = true := by native_decide

#eval Kstage 40    -- 4 号被排除
