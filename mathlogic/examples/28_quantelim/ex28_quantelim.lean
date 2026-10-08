/- ex28 —— 量词消去（Marker ch7）Lean 镜像
   DLO 区间推理消去+相邻性反例+F_3 暴根表+F_9 扩域见证+强极小性表。
   完备方向定理 qe_complete_dir 的完整证明见 Coq 通道（零公理）。 -/

set_option linter.unusedVariables false
set_option linter.unusedSimpArgs false

-- ---------- 1. DLO 量词消去 ----------

inductive Zlit : Type
  | zGt (p : Nat)
  | zLt (p : Nat)
  | zEq (p : Nat)

def pv2 (a b : Nat) : Nat → Nat :=
  fun k => if k == 0 then a else b

def evZ : Zlit → Nat → (Nat → Nat) → Bool
  | .zGt p, z, P => P p < z
  | .zLt p, z, P => z < P p
  | .zEq p, z, P => z == P p

def evEx (fs : List Zlit) (P : Nat → Nat) : Bool :=
  (List.range 21).any (fun z => fs.all (fun l => evZ l z P))

def allGts : List Zlit → List Nat
  | [] => []
  | .zGt p :: t => p :: allGts t
  | _ :: t => allGts t

def allLts : List Zlit → List Nat
  | [] => []
  | .zLt p :: t => p :: allLts t
  | _ :: t => allLts t

def lmax (d : Nat) : List Nat → Nat
  | [] => d
  | x :: t => max x (lmax d t)

def lmin1 (x0 : Nat) : List Nat → Nat
  | [] => x0
  | x :: t => min x (lmin1 x0 t)

def qfcond (fs : List Zlit) (P : Nat → Nat) : Bool :=
  match allGts fs, allLts fs with
  | [], _ => true
  | _, [] => true
  | _, u :: rest => lmax 0 (allGts fs |>.map P) < lmin1 (P u) (rest.map P)

-- 经典恒等式 ∃z(x<z ∧ z<y) ↔ x<y：非相邻赋值上的双向对账
example : List.all
      ((List.range 8).flatMap (fun a =>
        (List.range 8).map (fun b =>
          if a < b && 2 ≤ b - a then
            (evEx [.zGt 0, .zLt 1] (pv2 a b)) ==
            (qfcond [.zGt 0, .zLt 1] (pv2 a b))
          else true)) : List Bool)
      (fun x => x) = true := by native_decide

-- 相邻性反例：x=2,y=3——序条件真、样本链无中介（密度公理在说话）
example : qfcond [.zGt 0, .zLt 1] (pv2 2 3) = true
    && !(evEx [.zGt 0, .zLt 1] (pv2 2 3)) := by native_decide

def qfcondEq (a b : Nat) : Bool := b < a

-- 等词文字：∃z(z=x ∧ z>y) ↔ x>y
example : List.all
      ((List.range 8).flatMap (fun a =>
        (List.range 8).map (fun b =>
          (evEx [.zEq 0, .zGt 1] (pv2 a b)) == qfcondEq a b)) : List Bool)
      (fun x => x) = true := by native_decide

-- ---------- 2. F_p 求值与暴根表 ----------

def pevalc (p : Nat) : List Nat → Nat → Nat
  | [], _ => 0
  | c :: rest, x => (c + x * pevalc p rest x) % p

def rootsFp (p : Nat) (f : List Nat) : List Nat :=
  (List.range p).filter (fun x => pevalc p f x == 0)

def hasRootFp (p : Nat) (f : List Nat) : Bool :=
  (List.range p).any (fun x => pevalc p f x == 0)

example : [[1,0,1], [2,0,1], [0,0,1]].map
    (fun f => (rootsFp 3 f).length) = [0, 2, 1] := by native_decide

-- ---------- 3. F_9 = F_3[t]/(t²+1) ----------

def f9add (a b : Nat × Nat) : Nat × Nat :=
  ((a.1 + b.1) % 3, (a.2 + b.2) % 3)
def f9mul (a b : Nat × Nat) : Nat × Nat :=
  ((a.1 * b.1 + 2 * a.2 * b.2) % 3, (a.1 * b.2 + a.2 * b.1) % 3)

def pevalF9 : List Nat → Nat × Nat → Nat × Nat
  | [], _ => (0, 0)
  | c :: rest, x => f9add (c % 3, 0) (f9mul x (pevalF9 rest x))

def F9 : List (Nat × Nat) :=
  (List.range 3).flatMap (fun a => (List.range 3).map (fun b => (a, b)))

def rootsF9 (f : List Nat) : List (Nat × Nat) :=
  F9.filter (fun e => pevalF9 f e == (0, 0))

-- x²+1：F_3 无根、F_9 有根 (0,1)——「F_p 无根变 F_{p²} 有根」
example : !hasRootFp 3 [1,0,1] = true := by native_decide
example : pevalF9 [1,0,1] (0,1) = (0,0) := by native_decide
example : (rootsF9 [1,0,1]).length = 2 := by native_decide

-- ---------- 4. 强极小性影子 ----------

def monicQuads : List (List Nat) :=
  (List.range 3).flatMap (fun a =>
    (List.range 3).map (fun b => [b, a, 1]))

example : monicQuads.map (fun f => (rootsFp 3 f).length)
    = [1,0,2,2,1,0,2,1,0] := by native_decide
-- 每行 ≤ 2 = deg，域大小 3——「一维可定义集有限或余有限」的数值影子

#eval (rootsFp 3 [2,0,1], rootsF9 [1,0,1])   -- ([1,2], [(0,1),(0,2)])
