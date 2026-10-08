/- ex32 —— 寄存器机与可计算性（EFT ch X）Lean 镜像
   五指令 RM 解释器+P_0 奇偶对账+加法程序+停机/不停机对。 -/

set_option linter.unusedVariables false
set_option linter.unusedSimpArgs false

inductive inst : Type
  | radd (r a : Nat)
  | rdel (r a : Nat)
  | rife (r l1 l2 : Nat)
  | rprint
  | rhalt

abbrev Prog := List inst
abbrev Word := Nat

structure Cfg where
  pc : Nat
  regs : List Nat
  out : List Word

def nthd (l : List Nat) (i : Nat) : Nat := l.getD i 0

def setn (l : List Nat) (i v : Nat) : List Nat :=
  l.take i ++ [v] ++ l.drop (i + 1)

def deln (n a : Nat) : Nat := n - a

def step (p : Prog) (c : Cfg) : Cfg :=
  match p.getD c.pc .rhalt with
  | .radd r a => ⟨c.pc + 1, setn c.regs r (nthd c.regs r + a), c.out⟩
  | .rdel r a => ⟨c.pc + 1, setn c.regs r (deln (nthd c.regs r) a), c.out⟩
  | .rife r l1 l2 =>
      if nthd c.regs r == 0 then ⟨l1, c.regs, c.out⟩
      else ⟨l2, c.regs, c.out⟩
  | .rprint => ⟨c.pc + 1, c.regs, c.out ++ [nthd c.regs 0]⟩
  | .rhalt => c

def run : Prog → Cfg → Nat → Option Cfg
  | _, _, 0 => none
  | p, c, fuel + 1 =>
      let c' := step p c
      if c'.pc == c.pc then some c'
      else run p c' fuel

def start (n : Word) : Cfg := ⟨0, [n, 0, 0], []⟩

-- ---------- 书例 P_0：奇偶判定 ----------

def P0 : Prog :=
  [ .rife 0 6 1,
    .rdel 0 1,
    .rife 0 5 3,
    .rdel 0 1,
    .rife 0 6 1,
    .radd 0 1,
    .rhalt ]

def p0_result (n : Word) : Nat :=
  match run P0 (start n) (3 * n + 20) with
  | some c => nthd c.regs 0
  | none => 999

example : (List.range 10).map p0_result
    = [0, 1, 0, 1, 0, 1, 0, 1, 0, 1] := by native_decide

-- ---------- 加法程序 ----------

def Padd : Prog :=
  [ .rife 1 4 1,
    .rdel 1 1,
    .radd 0 1,
    .rife 1 0 0,
    .rhalt ]

def add_result (x y : Word) : Nat :=
  match run Padd ⟨0, [x, y], []⟩ (3 * (x + y) + 20) with
  | some c => nthd c.regs 0
  | none => 999

example : [(0, 0), (1, 0), (0, 1), (2, 3), (3, 4), (5, 5)].map
      (fun p => add_result p.1 p.2) = [0, 1, 1, 5, 7, 10] := by native_decide

-- ---------- 停机与不停机 ----------

def Ploop : Prog :=
  [ .radd 0 1,
    .rife 0 1 0 ]

example : ((List.range 5).all fun n =>
    (run Ploop (start n) 50).isNone) = true := by native_decide

-- 冒烟
#eval (List.range 8).map p0_result    -- [0,1,0,1,0,1,0,1]
#eval add_result 3 4                  -- 7
