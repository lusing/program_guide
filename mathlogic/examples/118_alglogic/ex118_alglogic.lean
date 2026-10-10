/- ex118_alglogic.lean —— 代数逻辑（马明辉 7 章）Lean 镜像
   M3 分方向账+DM3 德摩根等式账+权重降权样本。 -/

set_option linter.unusedVariables false

inductive Term where
  | tv (n : Nat)
  | tand (a b : Term)
  | tor (a b : Term)
  | tneg (a : Term)
  deriving DecidableEq

/- ---------- 一、五点菱形 M3 ---------- -/

def m3met (x y : Nat) : Nat :=
  if x == 0 then 0
  else if y == 0 then 0
  else if x == 4 then y
  else if y == 4 then x
  else if x == y then x else 0

def m3jn (x y : Nat) : Nat :=
  if x == 4 then 4
  else if y == 4 then 4
  else if x == y then x
  else if x == 0 then y
  else if y == 0 then x else 4

def m3e (v : Nat → Nat) : Term → Nat
  | .tv n => (match v n with | 0 => 0 | 1 => 1 | 2 => 2 | 3 => 3 | _ => 4)
  | .tand x y => m3met (m3e v x) (m3e v y)
  | .tor x y => m3jn (m3e v x) (m3e v y)
  | .tneg x => m3e v x

def le3 (x y : Nat) : Bool := (m3jn x y == y)

def allA3 (f : (Nat → Nat) → Bool) : Bool :=
  [0,1,2,3,4].all (fun a =>
    [0,1,2,3,4].all (fun b =>
      [0,1,2,3,4].all (fun c =>
        f (fun n => (match n with | 0 => a | 1 => b | _ => c)))))

/-- ≤ 方向 (p∧q)∨(p∧r) ≤ p∧(q∨r)：全 M3 赋值有效（125 组全枚举） -/
example : allA3 (fun v =>
    le3 (m3e v (.tor (.tand (.tv 0) (.tv 1)) (.tand (.tv 0) (.tv 2))))
        (m3e v (.tand (.tv 0) (.tor (.tv 1) (.tv 2))))) = true := by
  native_decide

/-- ≥ 方向：p=1,q=2,r=3 时 左=1（中点）、右=0（底）——M3 反例 -/
example :
    le3 (m3e (fun n => (match n with | 0 => 1 | 1 => 2 | _ => 3))
             (.tand (.tv 0) (.tor (.tv 1) (.tv 2))))
        (m3e (fun n => (match n with | 0 => 1 | 1 => 2 | _ => 3))
             (.tor (.tand (.tv 0) (.tv 1)) (.tand (.tv 0) (.tv 2))))
      = false := by native_decide

/- ---------- 二、三元 Kleene 链 DM3：德摩根代数 ---------- -/

def m3meet (x y : Nat) : Nat := min x y
def m3join (x y : Nat) : Nat := max x y
def m3neg (x : Nat) : Nat := (match x with | 0 => 2 | 2 => 0 | _ => 1)

def m3eval (v : Nat → Nat) : Term → Nat
  | .tv n => (match v n with | 0 => 0 | 1 => 1 | _ => 2)
  | .tand x y => m3meet (m3eval v x) (m3eval v y)
  | .tor x y => m3join (m3eval v x) (m3eval v y)
  | .tneg x => m3neg (m3eval v x)

def allAss2 (f : (Nat → Nat) → Bool) : Bool :=
  [0,1,2].all (fun x =>
    [0,1,2].all (fun y =>
      f (fun n => (match n with | 0 => x | 1 => y | _ => 0))))

/-- DM1：~(α∧β) = ~α∨~β -/
example : allAss2 (fun v =>
    (m3eval v (.tneg (.tand (.tv 0) (.tv 1)))
      == m3eval v (.tor (.tneg (.tv 0)) (.tneg (.tv 1))))) = true := by
  native_decide

/-- DM2：~(α∨β) = ~α∧~β -/
example : allAss2 (fun v =>
    (m3eval v (.tneg (.tor (.tv 0) (.tv 1)))
      == m3eval v (.tand (.tneg (.tv 0)) (.tneg (.tv 1))))) = true := by
  native_decide

/-- DN：~~α = α -/
example : allAss2 (fun v =>
    (m3eval v (.tneg (.tneg (.tv 0))) == m3eval v (.tv 0))) = true := by
  native_decide

/-- 排中律在 DM3 的 1 点失败：1∨~1 = 1 ≠ 2（德摩根/Boole 分界） -/
example : (m3join 1 (m3neg 1) == 2) = false := by native_decide

/-- GDM 推导的语义抽查：~~p ⊢ p（≤ 读法）全赋值有效 -/
example : allAss2 (fun v =>
    (m3join (m3eval v (.tneg (.tneg (.tv 0)))) (m3eval v (.tv 0))
      == m3eval v (.tv 0))) = true := by native_decide

/- ---------- 三、权重 w ---------- -/

def w : Term → Nat
  | .tv _ => 0
  | .tand x y | .tor x y => (w x + w y) + 1
  | .tneg x => w x + 1

example :
    (decide (w (.tv 0) + w (.tneg (.tv 1))
            < w (.tneg (.tand (.tv 0) (.tneg (.tv 1)))))
      && decide (w (.tv 0) < w (.tand (.tv 0) (.tv 1)))) = true := by
  native_decide
