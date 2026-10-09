/- ex42_turing.lean —— 图灵机：四元组与纸带（Mendelson §5.1-5.2）Lean 镜像
   四元组三型+纸带双向表+停机=无匹配；书例 Terase/Tsucc/Tzero/Tadd（连擦两笔版）；
   tsucc 常数深度 rfl + tzero 循环不变式归纳 + 5x5 加法网格 native_decide。 -/

set_option linter.unusedVariables false
set_option linter.unusedSimpArgs false

-- ============ 一、四元组、纸带与解释器 ============

inductive Act : Type where
  | wr (b : Nat)
  | mL
  | mR

inductive Quad : Type where
  | qd (qs rd : Nat) (a : Act) (qs' : Nat)

structure Tape where
  lft : List Nat
  cur : Nat
  rgt : List Nat

structure Cfg where
  st : Nat
  tp : Tape

-- 首匹配；none = 无匹配四元组 = 停机
def findq : List Quad → Nat → Nat → Option (Act × Nat)
  | [], _, _ => none
  | Quad.qd qs rd ac qs' :: p', s, a =>
      if (qs == s) && (rd == a) then some (ac, qs') else findq p' s a

def step (p : List Quad) (c : Cfg) : Option Cfg :=
  match findq p c.st c.tp.cur with
  | none => none
  | some (Act.wr b, qs') =>
      some ⟨qs', ⟨c.tp.lft, b, c.tp.rgt⟩⟩
  | some (Act.mL, qs') =>
      match c.tp.lft with
      | [] => some ⟨qs', ⟨[], 0, c.tp.cur :: c.tp.rgt⟩⟩
      | l :: ls => some ⟨qs', ⟨ls, l, c.tp.cur :: c.tp.rgt⟩⟩
  | some (Act.mR, qs') =>
      match c.tp.rgt with
      | [] => some ⟨qs', ⟨c.tp.cur :: c.tp.lft, 0, []⟩⟩
      | r :: rs => some ⟨qs', ⟨c.tp.cur :: c.tp.lft, r, rs⟩⟩

def run : List Quad → Cfg → Nat → Option Cfg
  | _, _, 0 => none
  | p, c, fuel + 1 =>
      match step p c with
      | none => some c
      | some c' => run p c' fuel

theorem run_mono (p : List Quad) (f k : Nat) (c' : Cfg) (c : Cfg)
    (h : run p c f = some c') : run p c (f + k) = some c' := by
  induction f generalizing c with
  | zero => simp [run] at h
  | succ f ih =>
    rw [show f + 1 + k = (f + k) + 1 by omega]
    simp only [run] at h ⊢
    cases E : step p c with
    | some c2 => rw [E] at h; exact ih c2 h
    | none => rw [E] at h; exact h

-- ============ 二、一元编码与四台书例机器 ============

def start1 (n : Nat) : Cfg := ⟨0, ⟨[], 1, List.replicate n 1⟩⟩
def start2 (m n : Nat) : Cfg :=
  ⟨0, ⟨[], 1, List.replicate m 1 ++ [0] ++ List.replicate (n + 1) 1⟩⟩

-- 书例 0（二元字母表版）：q0 B R q0, q0 | B q1
def Terase : List Quad := [Quad.qd 0 0 Act.mR 0, Quad.qd 0 1 (Act.wr 0) 1]

-- 书例 1：q0 | L q1, q1 B | q2
def Tsucc : List Quad := [Quad.qd 0 1 Act.mL 1, Quad.qd 1 0 (Act.wr 1) 2]

-- 书例 2：q0 | B q1, q1 B R q0, q0 B | q2
def Tzero : List Quad :=
  [Quad.qd 0 1 (Act.wr 0) 1, Quad.qd 1 0 Act.mR 0, Quad.qd 0 0 (Act.wr 1) 2]

-- 加法（自构，行为同书例 3）：隔板改笔连擦两笔
def Tadd : List Quad :=
  [Quad.qd 0 1 Act.mR 0, Quad.qd 0 0 (Act.wr 1) 1, Quad.qd 1 1 Act.mR 1,
   Quad.qd 1 0 Act.mL 2, Quad.qd 2 1 (Act.wr 0) 3, Quad.qd 3 0 Act.mL 4,
   Quad.qd 4 1 (Act.wr 0) 5]

-- ============ 三、Tsucc：常数深度全正确 ============

theorem tsucc_correct (n : Nat) :
    run Tsucc (start1 n) 4 = some ⟨2, ⟨[], 1, List.replicate (n + 1) 1⟩⟩ := rfl

-- ============ 四、Tzero：循环不变式归纳全正确 ============

-- 构造子递归的燃料预算（2*m+4 的可转换形态）
def tfuel : Nat → Nat
  | 0 => 4
  | m + 1 => (tfuel m).succ.succ

theorem tfuel_eq (m : Nat) : tfuel m = 2 * m + 4 := by
  induction m with
  | zero => rfl
  | succ m ih => rw [tfuel, ih]; omega

def Cz (k m : Nat) : Cfg := ⟨0, ⟨List.replicate k 0, 1, List.replicate m 1⟩⟩

theorem tzero_loop : ∀ (m k : Nat),
    run Tzero (Cz k m) (tfuel m)
    = some ⟨2, ⟨List.replicate (k + m + 1) 0, 1, []⟩⟩ := by
  intro m
  induction m with
  | zero =>
    intro k
    rw [Nat.add_zero]
    rfl
  | succ m ih =>
    intro k
    rw [show k + (m + 1) + 1 = (k + 1) + m + 1 by omega]
    exact ih (k + 1)

theorem tzero_correct (n : Nat) :
    run Tzero (start1 n) (2 * n + 5) = some ⟨2, ⟨List.replicate (n + 1) 0, 1, []⟩⟩ := by
  have h := tzero_loop n 0
  rw [tfuel_eq, Nat.zero_add] at h
  rw [show 2 * n + 5 = (2 * n + 4) + 1 by omega]
  exact run_mono Tzero (2 * n + 4) 1 _ _ h

-- ============ 五、对账表 ============

def cnt1 : List Nat → Nat
  | [] => 0
  | 1 :: l => cnt1 l + 1
  | _ :: l => cnt1 l

def outbars (c : Cfg) : Nat :=
  cnt1 c.tp.lft + (if c.tp.cur == 1 then 1 else 0) + cnt1 c.tp.rgt

example :
    (List.range 10).map (fun n =>
      match run Tsucc (start1 n) 10 with
      | some c => outbars c
      | none => 999) = (List.range 10).map (fun n => n + 2) := by native_decide

example :
    (List.range 10).map (fun n =>
      match run Tzero (start1 n) 30 with
      | some c => outbars c
      | none => 999) = (List.range 10).map (fun _ => 1) := by native_decide

-- 加法 5x5 网格：输出笔数 = m+n+1
example :
    ((List.range 5).map fun m =>
      (List.range 5).map fun n =>
        match run Tadd (start2 m n) 40 with
        | some c => outbars c
        | none => 999)
    = ((List.range 5).map fun m =>
        (List.range 5).map fun n => m + n + 1) := by native_decide

example :
    (List.range 10).map (fun n =>
      match run Terase (start1 n) 10 with
      | some c => outbars c
      | none => 999) = (List.range 10).map (fun n => n) := by native_decide

-- 全空纸带：q0BRq0 永不匹配停机
example : (run Terase ⟨0, ⟨[], 0, []⟩⟩ 50).isNone = true := by native_decide

-- ============ 账本 ============

#print axioms tsucc_correct
#print axioms tzero_correct

/- ---------- 张寅生轮深化：表格式五元组 TM（书 11.2 例 11.2） ---------- -/

inductive TSym where
  | blank | one
deriving Repr, DecidableEq

abbrev TTab := List (Nat × TSym × TSym × Bool × Nat)

def ttab : TTab :=
  [ (1, .one, .one, true, 1)          -- q1 扫过左段的 1
  , (1, .blank, .one, true, 2)        -- q1 间隔 B → 写 1 右移 q2
  , (2, .one, .one, true, 2)          -- q2 扫过右段的 1
  , (2, .blank, .blank, false, 3)     -- q2 读尾 B → 左移 q3
  , (3, .one, .blank, false, 4) ]     -- q3 抹最后一个 1 → q4 停

def symEq : TSym → TSym → Bool
  | .blank, .blank | .one, .one => true
  | _, _ => false

def tstep : TTab → Nat → TSym → Option (TSym × Bool × Nat)
  | [], _, _ => none
  | (q, r, w, mv, q2) :: t, st, s =>
      if st == q && symEq s r then some (w, mv, q2)
      else tstep t st s

def doStep (tp : List TSym × Nat) (st : Nat) : Option ((List TSym × Nat) × Nat) :=
  let (lst, pos) := tp
  match lst[pos]? with
  | none => none
  | some cur =>
      match tstep ttab st cur with
      | none => none
      | some (w, mv, q2) =>
          let lst2 := (lst.take pos) ++ [w] ++ (lst.drop (pos + 1))
          let pos2 := if mv then pos + 1 else max 0 (pos - 1)
          some ((lst2, pos2), q2)

def tRun : (List TSym × Nat) → Nat → Nat → Option ((List TSym × Nat) × Nat)
  | tp, 0, st => some (tp, st)
  | tp, n + 1, st =>
      match doStep tp st with
      | none => some (tp, st)
      | some (tp2, st2) => tRun tp2 n st2

def t0 : List TSym × Nat :=
  ([.blank, .one, .one, .one, .blank, .one, .one, .one, .blank], 1)

/-- B111B111B（3+3）→ 6 个 1：表格式加法器（例 11.2 对账） -/
def countOnes : Option ((List TSym × Nat) × Nat) → Bool
  | some ((lst, _), _) =>
      (lst.filter (fun s => match s with | .one => true | .blank => false)).length == 6
  | none => false

example : countOnes (tRun t0 40 1) = true := by native_decide
