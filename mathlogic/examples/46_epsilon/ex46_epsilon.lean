/- ex46 —— PA 与 ε₀（Marker ch15）Lean 镜像
   CNF 序数树+hereditary 基展开+Goodstein 小值跑通+影子下降网格
   （native GMP 让数值面比 Coq 走得更远）。 -/

set_option linter.unusedVariables false
set_option linter.unusedSimpArgs false

-- ---------- 1. CNF 序数树 ----------

inductive Onf : Type
  | cnf : List (Onf × Nat) → Onf

def oz : Onf := .cnf []
def ofin (n : Nat) : Onf := .cnf [(oz, n)]
def oomega : Onf := .cnf [(ofin 1, 1)]

def sizeOF : Nat → Onf → Nat
  | 0, _ => 0
  | _+1, .cnf [] => 0
  | f+1, .cnf (p :: t) => 1 + sizeOF f p.1 + sizeOF f (.cnf t)

def sizeO (a : Onf) : Nat := sizeOF 1000 a

def pairEqWith (eqf : Onf → Onf → Bool) : List (Onf × Nat) → List (Onf × Nat) → Bool
  | [], [] => true
  | (ga, ca) :: t1, (gb, cb) :: t2 =>
      eqf ga gb && (ca == cb) && pairEqWith eqf t1 t2
  | _, _ => false

def oeqF : Nat → Onf → Onf → Bool
  | 0, _, _ => true
  | f+1, .cnf la, .cnf lb =>
      la.length == lb.length && pairEqWith (oeqF f) la lb

def oeq (a b : Onf) : Bool := oeqF (sizeO a + sizeO b + 1) a b

def oltF : Nat → Onf → Onf → Bool
  | 0, _, _ => false
  | _+1, .cnf [], .cnf [] => false
  | _+1, .cnf [], _ => true
  | _+1, _, .cnf [] => false
  | f+1, .cnf ((ga, ca) :: ra), .cnf ((gb, cb) :: rb) =>
      if oeq ga gb then
        (if ca < cb then true else if cb < ca then false
         else oltF f (.cnf ra) (.cnf rb))
      else oltF f ga gb

def olt (a b : Onf) : Bool := oltF (sizeO a + sizeO b + 1) a b

example : (olt oz (ofin 1), olt (ofin 5) oomega,
           olt oomega (.cnf [(ofin 1, 1), (oz, 3)])) = (true, true, true) := by
  native_decide

-- ---------- 2. hereditary 基展开 ----------

def pow : Nat → Nat → Nat
  | _, 0 => 1
  | b, e+1 => b * pow b e

def expoUp (b e fuel n : Nat) : Nat :=
  match fuel with
  | 0 => 0
  | f+1 => if pow b (e+1) ≤ n then expoUp b (e+1) f n else e

def expo (n b : Nat) : Nat := expoUp b 0 n n

def terms : Onf → List (Onf × Nat)
  | .cnf l => l

def herbF : Nat → Nat → Nat → Onf
  | 0, _, _ => oz
  | _+1, 0, _ => oz
  | f+1, n+1, b =>
      let e := expo (n+1) b
      let c := (n+1) / pow b e
      let r := (n+1) - c * pow b e
      match r with
      | 0 => .cnf [(herbF f e b, c)]
      | _ => .cnf ((herbF f e b, c) :: terms (herbF f r b))

def herb (n b : Nat) : Onf := herbF (n+1) n b

def evalbF : Nat → Onf → Nat → Nat
  | 0, _, _ => 0
  | _+1, .cnf [], _ => 0
  | f+1, .cnf ((g, c) :: rest), b =>
      c * pow b (evalbF f g b) + evalbF f (.cnf rest) b

def evalb (o : Onf) (b : Nat) : Nat := evalbF (sizeO o + 1) o b

-- roundtrip 全表：n ≤ 40、b ∈ {2,3,4}（native GMP 快速通过）
example : ((List.range 41).flatMap (fun n =>
    [2,3,4].map (fun b => (n, b)))).all (fun nb =>
    evalb (herb nb.1 nb.2) nb.2 == nb.1) = true := by native_decide

-- ---------- 3. Goodstein ----------

def gstep (n b : Nat) : Nat := evalb (herb n b) (b+1) - 1

def goodRun : Nat → Nat → Nat → Nat
  | 0, n, _ => n
  | _+1, 0, _ => 0
  | f+1, n+1, base => goodRun f (gstep (n+1) base) (base+1)

example : [1,2,3].map (fun n => goodRun 50 n 2) = [0,0,0] := by
  native_decide

-- G(4) 前几步（native 能走到更远：43 步后数值开始爆炸性增长）
example : [0,1,2,3,4].map (fun k => goodRun k 4 2) = [4,26,41,60,83] := by
  native_decide

-- 影子下降网格：n ≤ 15（n=16 起 gstep=3^27−1，nat 增长爆炸；
-- native GMP 下实测可到 n=18）
example : ((List.range 14).flatMap (fun k =>
    [2,3].map (fun b => (k+2, b)))).all (fun nb =>
    olt (herb (gstep nb.1 nb.2) (nb.2+1)) (herb nb.1 nb.2)) = true := by
  native_decide

#eval herb 4 2        -- ω^ω
#eval [0,1,2,3,4,5].map (fun k => goodRun k 4 2)
