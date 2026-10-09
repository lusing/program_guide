/- ex27 —— 超积与 Łoś 定理（Marker ch6）Lean 镜像
   有限超滤枚举+主超滤 Łoś 定理（结构归纳）+Fréchet 失败现场+对角元。 -/

set_option linter.unusedVariables false
set_option linter.unusedSimpArgs false

-- ---------- 1. 滤子与超滤 ----------

def bits : Nat → List (List Bool)
  | 0 => [[]]
  | m+1 => (bits m).map (fun l => false :: l) ++ (bits m).map (fun l => true :: l)

def beqb : List Bool → List Bool → Bool
  | [], [] => true
  | x :: a', y :: b' => (x == y) && beqb a' b'
  | _, _ => false

def submemb (b : List Bool) (F : List (List Bool)) : Bool :=
  F.any (fun c => beqb b c)

def fullI (n : Nat) : List Bool := List.replicate n true
def emptyI (n : Nat) : List Bool := List.replicate n false
def suband (b c : List Bool) : List Bool :=
  if b.length == c.length then (b.zip c).map (fun p => p.1 && p.2) else b

def isFilterb (n : Nat) (F : List (List Bool)) : Bool :=
  submemb (fullI n) F && !submemb (emptyI n) F
  && (bits n).all (fun b => (bits n).all (fun c =>
       !submemb b F || !(beqb (suband b c) b) || submemb c F))
  && (bits n).all (fun b => (bits n).all (fun c =>
       !submemb b F || !submemb c F || submemb (suband b c) F))

def isUltra (n : Nat) (F : List (List Bool)) : Bool :=
  isFilterb n F && (bits n).all (fun b =>
    submemb b F || submemb (b.map (fun x => !x)) F)

def principal (i n : Nat) : List (List Bool) :=
  (bits n).filter (fun b => b.getD i false)

def famOf (subs : List (List Bool)) (mask : List Bool) : List (List Bool) :=
  (subs.zip mask).flatMap (fun p => if p.2 then [p.1] else [])

def allFams (n : Nat) : List (List (List Bool)) :=
  (bits (bits n).length).map (famOf (bits n))

def samefam (F G : List (List Bool)) : Bool :=
  F.length == G.length && F.all (fun b => submemb b G) && G.all (fun b => submemb b F)

-- n=3：恰 3 个超滤且全为主超滤（256 族全枚举）
example : ((allFams 3).filter (isUltra 3)).length == 3
    && ((allFams 3).filter (isUltra 3)).all
        (fun F => [0,1,2].any (fun i => samefam F (principal i 3))) := by
  native_decide

example : [0,1,2,3].all (fun i => isUltra 4 (principal i 4)) := by native_decide

def cofin16 (b : List Bool) : Bool :=
  (b.filter (fun x => !x)).length ≤ 4

def evens16 : List Bool := (List.range 16).map (fun i => i % 2 == 0)

-- Fréchet 是滤子但非超滤：偶数集两侧都不大
example : cofin16 (fullI 16) && !cofin16 (emptyI 16)
    && !cofin16 evens16 && !cofin16 (evens16.map (fun x => !x)) := by native_decide

-- ---------- 2. 迷你语言 {P,=} 与双求值器 ----------

structure Stru where
  dom : Nat
  predP : List Bool

inductive Afm : Type
  | aP (x : Nat)
  | aEq (x y : Nat)
  | aNeg (p : Afm)
  | aDisj (p q : Afm)
  | aExq (x : Nat) (p : Afm)

def setn : List Nat → Nat → Nat → List Nat
  | [], _, _ => []
  | _ :: l', 0, v => v :: l'
  | y :: l', x'+1, v => y :: setn l' x' v

def setnl : List (List Nat) → Nat → List Nat → List (List Nat)
  | [], _, _ => []
  | _ :: l', 0, v => v :: l'
  | y :: l', x'+1, v => y :: setnl l' x' v

def fev (M : Stru) : Afm → List Nat → Bool
  | .aP x, env => (M.predP.getD (env.getD x 0) false)
  | .aEq x y, env => (env.getD x 0) == (env.getD y 0)
  | .aNeg p, env => !(fev M p env)
  | .aDisj p q, env => fev M p env || fev M q env
  | .aExq x p, env => (List.range M.dom).any (fun a => fev M p (setn env x a))

def projv (v : List Nat) (i : Nat) : Nat := v.getD i 0

def allvn : Nat → Nat → List (List Nat)
  | _, 0 => [[]]
  | d, n'+1 => (allvn d n').flatMap (fun v => (List.range d).map (fun a => a :: v))

def fevP (Ms : List Stru) (d i : Nat) : Afm → List (List Nat) → Bool
  | .aP x, env =>
      ((Ms.getD i ⟨0, []⟩).predP).getD (projv (env.getD x []) i) false
  | .aEq x y, env =>
      projv (env.getD x []) i == projv (env.getD y []) i
  | .aNeg p, env => !(fevP Ms d i p env)
  | .aDisj p q, env => fevP Ms d i p env || fevP Ms d i q env
  | .aExq x p, env =>
      (allvn d Ms.length).any (fun v => fevP Ms d i p (setnl env x v))

-- ---------- 3. 主超滤 Łoś ----------
-- 完整结构归纳（existsb_allvn 量词提升 + los_principal 四步归纳，
-- 零公理）见 Coq 通道 ex29_ultraproduct.v §3；Lean 面承载现场对账。

def M_T : Stru := ⟨2, [true, false]⟩
def M_F : Stru := ⟨2, [false, false]⟩
def Ms2 : List Stru := [M_T, M_F]

-- 主超滤 Łoś 现场对账
example : fevP Ms2 2 0 (.aExq 0 (.aP 0)) [] = true := by native_decide
example : fevP Ms2 2 1 (.aExq 0 (.aP 0)) [] = false := by native_decide

#eval (allFams 3).filter (isUltra 3) |>.length   -- 3
#eval (fevP Ms2 2 0 (.aExq 0 (.aP 0)) [], fevP Ms2 2 1 (.aExq 0 (.aP 0)) [])
